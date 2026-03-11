import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';
import 'package:op_share_flutter/screens/scanning_room/target_icon_painter.dart';
import 'dart:math';
import '../shambles/shambles_transfer_screen.dart';
import 'radar_node.dart';
import 'radar_painter.dart';
import 'node_avatar.dart';
import 'peer_list_tile.dart';
import 'nav_item.dart';
class RoomActiveScreen extends StatefulWidget {
  const RoomActiveScreen({super.key});

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

  static const List<RadarNode> _allNodes = [
    RadarNode(
      label: 'KROOM_IPHONE',
      angle: -2.3,
      dist: 0.45,
      isOwner: true,
      peerName: 'Kroom-iPhone-15',
      connectionType: 'P2P-DIRECT',
      distance: '0.2m',
      status: 'READY',
    ),
    RadarNode(
      label: 'NODE_ZORO',
      angle: 0.5,
      dist: 0.76,
      isOwner: false,
      peerName: 'Node-Zoro-Mac',
      connectionType: 'RELAY',
      distance: '4.5m',
      status: 'STANDBY',
    ),
    RadarNode(
      label: 'GHOST_NODE',
      angle: -0.5,
      dist: 0.52,
      isOwner: false,
      peerName: 'Ghost-Node-Alpha',
      connectionType: 'RELAY',
      distance: '8.1m',
      status: 'STANDBY',
    ),
  ];

  int _selectedTab = 0;

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

    _spawnNodes();
  }

  void _spawnNodes() async {
    for (int i = 0; i < _allNodes.length; i++) {
      await Future.delayed(Duration(milliseconds: 1000 + i * 900));
      if (!mounted) return;
      setState(() => _visibleNodes.add(_allNodes[i]));
      _nodesCtrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _radarCtrl.dispose();
    _ringCtrl.dispose();
    _nodesCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  void _goToShambles() {
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 600),
      pageBuilder: (_, __, ___) =>
          ShamblesTransferScreen(peers: _visibleNodes),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
              begin: const Offset(0, 0.05), end: Offset.zero)
              .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ));
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
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: kCyan, width: 2),
                      ),
                      child: Center(
                        child: CustomPaint(
                          size: const Size(22, 22),
                          painter:  TargetIconPainter(),
                        ),
                      ),
                    ),
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
                              color: kCyan.withOpacity(_pulseAnim.value),
                              fontFamily: 'monospace')),
                    ),
                  ]),
                  const Icon(Icons.settings_suggest_outlined,
                      color: kCyan, size: 28),
                ]),
          ),

          // ── Surgical Radius ───────────────────────
          Text('SURGICAL RADIUS: 15.4M',
              style: TextStyle(
                  fontSize: 13,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: kCyan,
                  fontFamily: 'monospace')),
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
                      color: kCyan.withOpacity(0.55),
                      fontFamily: 'monospace')),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  NavItem(
                      icon: Icons.radio,
                      label: 'ROOM',
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0)),
                  NavItem(
                      icon: Icons.history_edu_outlined,
                      label: 'HISTORY',
                      selected: _selectedTab == 1,
                      onTap: () => setState(() => _selectedTab = 1)),
                  NavItem(
                      icon: Icons.storage_outlined,
                      label: 'STORAGE',
                      selected: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2)),
                ]),
          ),
        ]),
      ),
    );
  }
}




