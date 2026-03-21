import 'dart:convert';
import 'package:stomp_dart_client/stomp_dart_client.dart';

class InviteService {
  final String signalingUrl;
  final String authToken;

  /// Called when an invite is received. Provides [roomCode] and [inviterName].
  void Function(String roomCode, String inviterName)? onInviteReceived;

  StompClient? _stomp;

  InviteService({required this.signalingUrl, required this.authToken});

  void connect() {
    _stomp = StompClient(
      config: StompConfig(
        url: signalingUrl,
        webSocketConnectHeaders: {'Authorization': 'Bearer $authToken'},
        stompConnectHeaders: {'Authorization': 'Bearer $authToken'},
        onConnect: _onConnected,
        onDisconnect: (_) => print('[InviteService] disconnected'),
        onWebSocketError: (e) => print('[InviteService] ws error: $e'),
        onStompError: (f) => print('[InviteService] stomp error: ${f.body}'),
        reconnectDelay: const Duration(seconds: 5),
      ),
    );
    _stomp!.activate();
  }

  void _onConnected(StompFrame frame) {
    print('[InviteService] STOMP connected, subscribing to /user/queue/room');
    _stomp!.subscribe(
      destination: '/user/queue/room',
      callback: (frame) {
        if (frame.body == null) return;
        try {
          final data = jsonDecode(frame.body!);
          if ((data['eventType'] ?? '') != 'ROOM_INVITE') return;
          final roomCode = (data['roomId'] ?? '').toString();
          final inviterName = (data['peerName'] ?? 'Someone').toString();
          if (roomCode.isNotEmpty) {
            onInviteReceived?.call(roomCode, inviterName);
          }
        } catch (e) {
          print('[InviteService] failed to parse invite: $e');
        }
      },
    );
  }

  void dispose() {
    _stomp?.deactivate();
    _stomp = null;
  }
}
