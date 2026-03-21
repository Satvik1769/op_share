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
  bool remoteDescriptionSet = false;
  final List<RTCIceCandidate> pendingCandidates = [];

  PeerConnection({required this.peerId, required this.pc});
}

class WebRTCService {
  final String roomCode;
  final String peerId;
  final String signalingUrl;
  final String authToken;

  WebRTCService({
    required this.roomCode,
    required this.peerId,
    required this.signalingUrl,
    required this.authToken,
  });

  StompClient? _stomp;
  final Map<String, PeerConnection> _peers = {};

  /// Tracks peers already announced to UI — prevents duplicate onPeerJoined calls.
  final Set<String> _announcedPeers = {};

  // Callbacks for the UI
  void Function(String peerId)? onPeerJoined;
  void Function(String peerId)? onPeerLeft;
  void Function(String fromPeerId, Uint8List chunk, bool isLast)? onDataReceived;

  /// Called once STOMP is connected and subscribed — use this to fetch
  /// existing room members and initiate connections to them.
  void Function()? onStompReady;

  /// Called when any peer (including this one) triggers a shambles navigation.
  void Function()? onNavigateToShambles;

  static const _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  // ── Connect to signaling server ──────────────────────────────────────
  void connect() {
    print('[WebRTC] Connecting to $signalingUrl as peerId=$peerId');
    _stomp = StompClient(
      config: StompConfig(
        url: signalingUrl,
        webSocketConnectHeaders: {'Authorization': 'Bearer $authToken'},
        stompConnectHeaders: {'Authorization': 'Bearer $authToken'},
        onConnect: _onStompConnected,
        onDisconnect: (_) {
          print('[WebRTC] STOMP disconnected');
          _onDisconnected();
        },
        onWebSocketError: (error) {
          print('[WebRTC] WebSocket error: $error');
          _onDisconnected();
        },
        onWebSocketDone: () {
          print('[WebRTC] WebSocket done');
          _onDisconnected();
        },
        onStompError: (frame) {
          print('[WebRTC] STOMP error: ${frame.body}');
          _onDisconnected();
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stomp!.activate();
  }

  void _onStompConnected(StompFrame frame) {
    print('[WebRTC] STOMP connected. Subscribing...');

    _stomp!.subscribe(
      destination: '/topic/room/$roomCode',
      callback: (frame) {
        print('[WebRTC] Room event: ${frame.body}');
        if (frame.body != null) _onSignalMessage(frame.body!);
      },
    );

    _stomp!.subscribe(
      destination: '/user/queue/signal',
      callback: (frame) {
        print('[WebRTC] Signal: ${frame.body}');
        if (frame.body != null) _onSignalMessage(frame.body!);
      },
    );

    onStompReady?.call();
  }

  void _onDisconnected() {
    for (final p in _peers.values) {
      p.pc.close();
    }
    _peers.clear();
    _announcedPeers.clear();
  }

  /// Calls onPeerJoined exactly once per peer. Safe to call multiple times.
  void _announceJoined(String remotePeerId) {
    if (_announcedPeers.contains(remotePeerId)) return;
    _announcedPeers.add(remotePeerId);
    print('[WebRTC] Announcing joined: $remotePeerId');
    onPeerJoined?.call(remotePeerId);
  }

  void _announcePeerLeft(String remotePeerId) {
    _announcedPeers.remove(remotePeerId);
    onPeerLeft?.call(remotePeerId);
  }

  // ── Handle incoming signaling messages ──────────────────────────────
  void _onSignalMessage(String raw) async {
    final msg = jsonDecode(raw) as Map<String, dynamic>;
    final type = (msg['type'] ?? msg['eventType'] ?? '') as String;
    final from = (msg['from'] ?? msg['peerId'] ?? '').toString();

    print('[WebRTC] type=$type from=$from (me=$peerId)');

    if (from == peerId) return;

    switch (type) {
      case 'USER_JOINED':
      case 'user_joined':
      case 'join':
        if (from.isEmpty) break;
        _announceJoined(from);
        try {
          await _createOffer(from);
        } catch (e) {
          print('[WebRTC] _createOffer failed for $from: $e');
        }

      case 'offer':
        await _handleOffer(from, msg['sdp'] as String);

      case 'answer':
        final peer = _peers[from];
        if (peer == null) break;
        await peer.pc.setRemoteDescription(
          RTCSessionDescription(msg['sdp'] as String, 'answer'),
        );
        peer.remoteDescriptionSet = true;
        await _flushPendingCandidates(peer);
        // Offerer side: announce once answer is established
        _announceJoined(from);

      case 'ice-candidate':
        final peer = _peers[from];
        if (peer == null) break;
        final candidate = RTCIceCandidate(
          msg['candidate'] as String,
          msg['sdpMid'] as String?,
          msg['sdpMLineIndex'] as int?,
        );
        if (peer.remoteDescriptionSet) {
          await peer.pc.addCandidate(candidate);
        } else {
          print('[WebRTC] Buffering ICE candidate for $from');
          peer.pendingCandidates.add(candidate);
        }

      case 'navigate_to_shambles':
        onNavigateToShambles?.call();

      case 'leave':
        _peers[from]?.pc.close();
        _peers.remove(from);
        _announcePeerLeft(from);
    }
  }

  /// Sends navigate_to_shambles to every connected peer individually.
  void broadcastNavigateToShambles() {
    for (final id in _peers.keys) {
      _send({'type': 'navigate_to_shambles', 'to': id});
    }
  }

  Future<void> _flushPendingCandidates(PeerConnection peer) async {
    if (peer.pendingCandidates.isEmpty) return;
    print('[WebRTC] Flushing ${peer.pendingCandidates.length} buffered ICE candidates for ${peer.peerId}');
    for (final c in peer.pendingCandidates) {
      try {
        await peer.pc.addCandidate(c);
      } catch (e) {
        print('[WebRTC] addCandidate error: $e');
      }
    }
    peer.pendingCandidates.clear();
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
      print('[WebRTC] $remotePeerId → $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (_peers[remotePeerId]?.pc == pc) {
          _peers.remove(remotePeerId);
          _announcePeerLeft(remotePeerId);
        }
      }
    };

    return pc;
  }

  // ── Initiator: create offer ──────────────────────────────────────────
  Future<void> _createOffer(String remotePeerId) async {
    if (_peers.containsKey(remotePeerId)) {
      _peers[remotePeerId]?.dataChannel?.close();
      _peers[remotePeerId]?.pc.close();
      _peers.remove(remotePeerId);
    }
    final pc = await _createPc(remotePeerId);

    final dc = await pc.createDataChannel(
      'fileTransfer',
      RTCDataChannelInit()
        ..ordered = true
        ..maxRetransmits = 30,
    );
    final peer = PeerConnection(peerId: remotePeerId, pc: pc)..dataChannel = dc;
    _peers[remotePeerId] = peer;
    _setupDataChannel(dc, remotePeerId);

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    _send({'type': 'offer', 'to': remotePeerId, 'sdp': offer.sdp});
  }

  // ── Receiver: handle offer, send answer ─────────────────────────────
  Future<void> _handleOffer(String remotePeerId, String sdp) async {
    // Glare resolution: both sides sent offers simultaneously.
    // The peer with the lower ID yields and becomes the answerer.
    // The peer with the higher ID ignores the incoming offer and waits for its answer.
    if (_peers.containsKey(remotePeerId)) {
      if (peerId.compareTo(remotePeerId) > 0) {
        print('[WebRTC] Glare: we have higher ID ($peerId > $remotePeerId), ignoring their offer');
        return;
      }
      // We have lower ID — close our outgoing offer and become answerer
      print('[WebRTC] Glare: we have lower ID ($peerId < $remotePeerId), yielding to their offer');
      _peers[remotePeerId]?.dataChannel?.close();
      _peers[remotePeerId]?.pc.close();
      _peers.remove(remotePeerId);
    }

    final pc = await _createPc(remotePeerId);
    final peer = PeerConnection(peerId: remotePeerId, pc: pc);
    _peers[remotePeerId] = peer;

    pc.onDataChannel = (dc) {
      peer.dataChannel = dc;
      _setupDataChannel(dc, remotePeerId);
    };

    await pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
    peer.remoteDescriptionSet = true;
    await _flushPendingCandidates(peer);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    _send({'type': 'answer', 'to': remotePeerId, 'sdp': answer.sdp});

    // Answerer side: announce once answer is sent
    _announceJoined(remotePeerId);
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

  // ── Proactively connect to a peer already in the room ────────────────
  Future<void> connectToPeer(String remotePeerId) async {
    if (remotePeerId == peerId) return;
    if (_peers.containsKey(remotePeerId)) return;
    print('[WebRTC] Proactively connecting to $remotePeerId');
    try {
      await _createOffer(remotePeerId);
    } catch (e) {
      print('[WebRTC] connectToPeer failed for $remotePeerId: $e');
    }
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
    // Notify each peer individually — server requires a 'to' field
    for (final id in _peers.keys) {
      _send({'type': 'leave', 'to': id});
    }
    for (final p in _peers.values) {
      p.dataChannel?.close();
      p.pc.close();
    }
    _peers.clear();
    _announcedPeers.clear();
    _stomp?.deactivate();
  }
}