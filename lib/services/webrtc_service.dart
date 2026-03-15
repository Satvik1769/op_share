import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

/// One entry per remote peer
class PeerConnection {
  final String peerId;
  RTCPeerConnection pc;
  RTCDataChannel? dataChannel;

  PeerConnection({required this.peerId, required this.pc});
}

class WebRTCService {
  final String roomCode;
  final String peerId; // this device's JWT token / userId
  final String signalingUrl; // ws://host/ws-native
  final String authToken;

  WebRTCService({
    required this.roomCode,
    required this.peerId,
    required this.signalingUrl,
    required this.authToken,
  });

  StompClient? _stomp;
  final Map<String, PeerConnection> _peers = {};

  // Callbacks for the UI
  void Function(String peerId)? onPeerJoined;
  void Function(String peerId)? onPeerLeft;
  void Function(String fromPeerId, Uint8List chunk, bool isLast)? onDataReceived;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // ── Connect to signaling server ──────────────────────────────────────
  void connect() {
    _stomp = StompClient(
      config: StompConfig(
        url: signalingUrl,
        stompConnectHeaders: {
          'Authorization': 'Bearer $authToken',
        },
        onConnect: _onStompConnected,
        onDisconnect: (_) => _onDisconnected(),
        onWebSocketError: (_) => _onDisconnected(),
        onWebSocketDone: _onDisconnected,
        onStompError: (_) => _onDisconnected(),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stomp!.activate();
  }

  void _onStompConnected(StompFrame frame) {
    // Subscribe to user-specific signal queue
    _stomp!.subscribe(
      destination: '/user/queue/signal',
      callback: (frame) {
        if (frame.body != null) _onSignalMessage(frame.body!);
      },
    );
    // Announce join so existing peers initiate offers to us
    _send({'type': 'join', 'peerId': peerId});
  }

  void _onDisconnected() {
    for (final p in _peers.values) {
      p.pc.close();
    }
    _peers.clear();
  }

  // ── Handle incoming signaling messages ──────────────────────────────
  void _onSignalMessage(String raw) async {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    final type = msg['type'] as String;
    // Server sets 'from' server-side; fall back to 'peerId' for join broadcasts
    final from = msg['from'] as String? ?? msg['peerId'] as String? ?? '';

    if (from == peerId) return; // ignore echoed own messages

    switch (type) {
      case 'join':
        // A new peer joined — we initiate the offer
        await _createOffer(from);
        onPeerJoined?.call(from);

      case 'offer':
        await _handleOffer(from, msg['sdp'] as String);

      case 'answer':
        await _peers[from]?.pc.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String, 'answer'),
        );

      case 'ice-candidate':
        await _peers[from]?.pc.addCandidate(RTCIceCandidate(
          msg['candidate'] as String,
          msg['sdpMid'] as String?,
          msg['sdpMLineIndex'] as int?,
        ));

      case 'leave':
        _peers[from]?.pc.close();
        _peers.remove(from);
        onPeerLeft?.call(from);
    }
  }

  // ── Create peer connection ───────────────────────────────────────────
  Future<RTCPeerConnection> _createPc(String remotePeerId) async {
    final pc = await createPeerConnection(_iceServers);

    pc.onIceCandidate = (candidate) {
      _send({
        'type': 'ice-candidate',
        'to': remotePeerId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    pc.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _peers.remove(remotePeerId);
        onPeerLeft?.call(remotePeerId);
      }
    };

    return pc;
  }

  // ── Initiator: create offer ──────────────────────────────────────────
  Future<void> _createOffer(String remotePeerId) async {
    final pc = await _createPc(remotePeerId);

    // Create data channel before offer so it's included in SDP
    final dc = await pc.createDataChannel(
      'fileTransfer',
      RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 30,
    );
    final peer = PeerConnection(peerId: remotePeerId, pc: pc)
      ..dataChannel = dc;
    _peers[remotePeerId] = peer;
    _setupDataChannel(dc, remotePeerId);

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _send({'type': 'offer', 'to': remotePeerId, 'sdp': offer.sdp});
  }

  // ── Receiver: handle offer, send answer ─────────────────────────────
  Future<void> _handleOffer(String remotePeerId, String sdp) async {
    final pc = await _createPc(remotePeerId);
    final peer = PeerConnection(peerId: remotePeerId, pc: pc);
    _peers[remotePeerId] = peer;

    // Data channel created by initiator arrives here
    pc.onDataChannel = (dc) {
      peer.dataChannel = dc;
      _setupDataChannel(dc, remotePeerId);
    };

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _send({'type': 'answer', 'to': remotePeerId, 'sdp': answer.sdp});

    onPeerJoined?.call(remotePeerId);
  }

  // ── DataChannel: receive chunks ──────────────────────────────────────
  void _setupDataChannel(RTCDataChannel dc, String remotePeerId) {
    dc.onMessage = (msg) {
      if (msg.isBinary) {
        final bytes = msg.binary;
        final isLast = bytes.length < 64 * 1024;
        onDataReceived?.call(remotePeerId, bytes, isLast);
      }
    };
  }

  // ── Send file to a specific peer ─────────────────────────────────────
  Future<void> sendFile(String remotePeerId, Uint8List bytes) async {
    final dc = _peers[remotePeerId]?.dataChannel;
    if (dc == null || dc.state != RTCDataChannelState.RTCDataChannelOpen) return;

    const chunkSize = 64 * 1024;
    for (int i = 0; i < bytes.length; i += chunkSize) {
      final chunk = bytes.sublist(i, min(i + chunkSize, bytes.length));
      await dc.send(RTCDataChannelMessage.fromBinary(chunk));
    }
  }

  // ── Broadcast file to all connected peers ────────────────────────────
  Future<void> broadcastFile(Uint8List bytes) async {
    for (final id in _peers.keys) {
      await sendFile(id, bytes);
    }
  }

  List<String> get connectedPeerIds => _peers.keys.toList();

  void _send(Map<String, dynamic> msg) {
    if (_stomp == null || !_stomp!.connected) return;
    _stomp!.send(
      destination: '/app/signal/$roomCode',
      body: jsonEncode(msg),
    );
  }

  void dispose() {
    _send({'type': 'leave', 'peerId': peerId});
    for (final p in _peers.values) {
      p.dataChannel?.close();
      p.pc.close();
    }
    _peers.clear();
    _stomp?.deactivate();
  }
}