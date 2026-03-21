import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';
import 'package:op_share_flutter/services/webrtc_service.dart';
import '../../main.dart';
import '../auth_screens/colors.dart' as auth_colors;
import '../shambles/shambles_transfer_screen.dart';
import 'radar_node.dart';
import 'radar_painter.dart';
import 'node_avatar.dart';
import 'peer_list_tile.dart';
import 'nearby_users_sheet.dart';

class RoomActiveScreen extends StatefulWidget {
  final String roomCode;
  final bool isOwner;
  const RoomActiveScreen({super.key, this.roomCode = '', this.isOwner = false});

  @override
  State<RoomActiveScreen> createState() => _RoomActiveScreenState();
}

class _RoomActiveScreenState extends State<RoomActiveScreen>
    with TickerProviderStateMixin {
  late final AnimationController _radarCtrl;
  late final Animation<double> _radarAnim;
  late final AnimationController _nodesCtrl;
  late final Animation<double> _nodesAnim;
  late final AnimationController _ringCtrl;
  late final Animation<double> _ringAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  final List<RadarNode> _visibleNodes = [];
  late final WebRTCService _webrtc;
  final _rng = Random();

  Future<void> leaveRoom(BuildContext context) async {
    if (widget.roomCode.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final response = await http.post(
      Uri.parse('${appConfig.baseUrl}/rooms/${widget.roomCode}/leave'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      Navigator.pop(context);
    } else {
      auth_colors.showAppSnackBarFromMessenger(messenger, 'Something went wrong, cannot leave room.', isError: true);
    }
  }


  @override
  void initState() {
    super.initState();

    _radarCtrl =
    AnimationController(vsync: this, duration: const Duration(seconds: 3))
      ..repeat();
    _radarAnim =
        Tween<double>(begin: 0, end: 2 * pi).animate(_radarCtrl);

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat();
    _ringAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ringCtrl, curve: Curves.easeOut));

    _nodesCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _nodesAnim =
        CurvedAnimation(parent: _nodesCtrl, curve: Curves.elasticOut);

    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    _initWebRTC();
  }

  Future<void> _fetchAndConnectExistingPeers() async {
    try {
      final response = await http.get(
        Uri.parse('${appConfig.baseUrl}/rooms/${widget.roomCode}/peers'),
        headers: {'Authorization': 'Bearer $authToken'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List members = data is List ? data : (data['members'] ?? data['peers'] ?? []);
        for (final m in members) {
          final memberId = (m is Map ? (m['userId'] ?? m['peerId'] ?? m['id']) : m).toString();
          await _webrtc.connectToPeer(memberId);
        }
      }
    } catch (e) {
      print('[Radar] fetchExistingPeers error: $e');
    }
  }

  void _initWebRTC() {
    final wsUrl = appConfig.baseUrl
        .replaceFirst(RegExp(r'^https'), 'wss')
        .replaceFirst(RegExp(r'^http'), 'ws');

    _webrtc = WebRTCService(
      roomCode: widget.roomCode,
      peerId: currentUserId,
      signalingUrl: '$wsUrl/ws-native',
      authToken: authToken,
    );

    _webrtc.onStompReady = () => _fetchAndConnectExistingPeers();

    _webrtc.onPeerJoined = (peerId) {
      print('[Radar] onPeerJoined called: $peerId mounted=$mounted');
      if (!mounted) return;
      if (_visibleNodes.any((n) => n.peerName == peerId)) return; // dedup guard
      final node = RadarNode(
        label: peerId.substring(0, min(8, peerId.length)).toUpperCase(),
        angle: _rng.nextDouble() * 2 * pi,
        dist: 0.3 + _rng.nextDouble() * 0.55,
        isOwner: false,
        peerName: peerId,
        connectionType: 'P2P-DIRECT',
        distance: '—',
        status: 'READY',
      );
      setState(() => _visibleNodes.add(node));
      _nodesCtrl.forward(from: 0);
    };

    _webrtc.onPeerLeft = (peerId) {
      if (!mounted) return;
      setState(() => _visibleNodes.removeWhere((n) => n.peerName == peerId));
    };

    _webrtc.onNavigateToShambles = () {
      if (!mounted) return;
      _navigateToShambles();
    };

    _webrtc.connect();
  }

  @override
  void dispose() {
    _webrtc.dispose();
    _radarCtrl.dispose();
    _ringCtrl.dispose();
    _nodesCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _navigateToShambles() {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) =>
          ShamblesTransferScreen(peers: _visibleNodes, webrtc: _webrtc),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ));
  }

  void _goToShambles() {
    _webrtc.broadcastNavigateToShambles(); // tell all peers to navigate
    _navigateToShambles();                  // navigate ourselves
  }

  void _openNearbyUsersSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => NearbyUsersSheet(
        roomCode: widget.roomCode,
        authToken: authToken,
        baseUrl: appConfig.baseUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(children: [
          // ── Top App Bar ───────────────────────────
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => leaveRoom(context),
                    child:    Image.asset("assets/images/logo.png", width: 20, height: 20),
                  ),
                  Column(children: [
                     Text('ROOM ACTIVE',
                        style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: kCyan,
                            letterSpacing: 3)),
                    AnimatedBuilder(
                      animation: _pulseAnim,
                      builder: (_, __) => Text('SCANNING FOR NODES...',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 2,
                              color: kCyan.withOpacity(_pulseAnim.value),)),
                    ),
                  ]),
                  const SizedBox(width: 12,)
                ]),
          ),

          // ── Surgical Radius ───────────────────────
          Text('SURGICAL RADIUS: 15.4M',
              style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: kCyan,)),
          const SizedBox(height: 6),

          // ── RADAR ─────────────────────────────────
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: AnimatedBuilder(
                animation: Listenable.merge([_radarAnim, _ringAnim]),
                builder: (_, __) => CustomPaint(
                  painter: RadarPainter(
                    sweepAngle: _radarAnim.value,
                    ringProgress: _ringAnim.value,
                  ),
                  child: LayoutBuilder(
                    builder: (_, constraints) => Stack(
                      children: _visibleNodes
                          .map((n) => NodeAvatar(
                                node: n,
                                animation: _nodesAnim,
                                radarSize: constraints.biggest,
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── SHAMBLES button ───────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 10),
            child: Column(children: [
              GestureDetector(
                onTap: _goToShambles,
                child: Container(
                  width:200,
                  height: 56,
                  decoration: BoxDecoration(
                    color: kCyan,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                          color: kCyan.withOpacity(0.5),
                          blurRadius: 22,
                          spreadRadius: 2)
                    ],
                  ),
                  child: const Center(
                    child: Text('SHAMBLES',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: kDarkBg,
                            letterSpacing: 2)),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text('SELECT NODES TO SWAP DATA',
                  style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2.5,
                      color: kCyan.withOpacity(0.55),)),
              if (widget.isOwner) ...[
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: _openNearbyUsersSheet,
                  child: Container(
                    width: 200,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: kCyan.withOpacity(0.6)),
                    ),
                    child: Center(
                      child: Text(
                        'DISCOVER NEARBY',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: kCyan,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ]),
          ),

          // ── Divider ───────────────────────────────
          Container(height: 1, color: kBorderDim),

          // ── Connected Peers ───────────────────────
          Expanded(
            flex: 4,
            child: Column(children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          'CONNECTED PEERS (${_visibleNodes.length})',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: kCyan,
                              letterSpacing: 1.5)),
                      Text('0.5ms LATENCY',
                          style: TextStyle(
                              fontSize: 10,
                              color: kCyan.withOpacity(0.6),
                              letterSpacing: 1)),
                    ]),
              ),
              Expanded(
                child: ListView.separated(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _visibleNodes.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 8),
                  itemBuilder: (_, i) =>
                      PeerListTile(node: _visibleNodes[i]),
                ),
              ),
              const SizedBox(height: 6),
            ]),
          ),

          // ── Bottom Nav ────────────────────────────
          Container(height: 1, color: kBorderDim),

        ]),
      ),
    );
  }
}




