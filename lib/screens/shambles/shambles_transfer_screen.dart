
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';
import 'package:op_share_flutter/screens/shambles/transfer_file.dart';

import '../history/history_log_screen.dart';
import '../scanning_room/nav_item.dart';
import '../scanning_room/radar_node.dart';


import 'broadcast_progress_bar.dart';
import 'file_chip.dart';
import 'file_status.dart';
import 'info_tile.dart';
import 'orbit_ring_painter.dart';


class ShamblesTransferScreen extends StatefulWidget {
  /// Peers passed in from RoomActiveScreen
  final List<RadarNode> peers;

  const ShamblesTransferScreen({super.key, required this.peers});

  @override
  State<ShamblesTransferScreen> createState() =>
      _ShamblesTransferScreenState();
}

class _ShamblesTransferScreenState extends State<ShamblesTransferScreen>
    with TickerProviderStateMixin {

  late final AnimationController _orbitCtrl;
  late final Animation<double> _orbitAnim;

  late final AnimationController _broadcastCtrl;
  late final Animation<double> _broadcastAnim;

  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>> _dotAnims;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;


  final List<TransferFile> _files = [
    TransferFile(
      name: 'heart_anatomy',
      ext: 'png',
      size: '2.3 MB',
      icon: Icons.image_outlined,
      iconColor: kCyan,
    ),
  ];

  bool _isBroadcasting = false;
  double _broadcastPercent = 0.0;
  final double _speedMbps = 309;
  final int _peersInRange = 4;
  int _selectedTab = 0; // TRANSFER tab

  // Fixed dot positions around the central circle
  static const List<Offset> _dotOffsets = [
    Offset(-90, -20),
    Offset(85, -35),
    Offset(100, 45),
    Offset(-80, 55),
    Offset(10, -95),
  ];

  // Available mock file types for "+ ADD FILE"
  List<TransferFile> get _mockFilePool => [
    TransferFile(
        name: 'chest_xray_scan',
        ext: 'zip',
        size: '14.7 MB',
        icon: Icons.folder_zip_outlined,
        iconColor: const Color(0xFFFFD54F)),
    TransferFile(
        name: 'patient_records',
        ext: 'pdf',
        size: '890 KB',
        icon: Icons.picture_as_pdf_outlined,
        iconColor: const Color(0xFFFF7043)),
    TransferFile(
        name: 'mri_sequence',
        ext: 'mp4',
        size: '38.2 MB',
        icon: Icons.videocam_outlined,
        iconColor: const Color(0xFFAB47BC)),
    TransferFile(
        name: 'lab_results',
        ext: 'csv',
        size: '120 KB',
        icon: Icons.table_chart_outlined,
        iconColor: const Color(0xFF66BB6A)),
    TransferFile(
        name: 'op_log',
        ext: 'txt',
        size: '44 KB',
        icon: Icons.description_outlined,
        iconColor: const Color(0xFF90A4AE)),
  ];

  @override
  void initState() {
    super.initState();

    // Slow orbit of the outer rings
    _orbitCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 8))
      ..repeat();
    _orbitAnim =
        Tween<double>(begin: 0, end: 2 * pi).animate(_orbitCtrl);

    // Broadcast fill — drives _broadcastPercent
    _broadcastCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6));
    _broadcastAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _broadcastCtrl, curve: Curves.easeInOut));
    _broadcastCtrl.addListener(() {
      setState(() {
        _broadcastPercent = _broadcastAnim.value * 100;
      });
      if (_broadcastCtrl.isCompleted && mounted) {
        setState(() {
          _isBroadcasting = false;
          for (final f in _files) {
            f.status = FileStatus.done;
            f.progress = 1.0;
          }
        });
      }
    });

    // 5 bobbing dots
    _dotCtrls = List.generate(
        5,
            (i) => AnimationController(
            vsync: this,
            duration: Duration(milliseconds: 1800 + i * 300))
          ..repeat(reverse: true));
    _dotAnims = _dotCtrls
        .map((c) => Tween<double>(begin: -4, end: 4)
        .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();

    // Central circle scale pulse
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _pulseAnim =
        Tween<double>(begin: 0.92, end: 1.0).animate(_pulseCtrl);
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    _broadcastCtrl.dispose();
    for (final c in _dotCtrls) c.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────
  void _startBroadcast() {
    if (_isBroadcasting || _files.isEmpty) return;
    setState(() {
      _isBroadcasting = true;
      _broadcastPercent = 0;
      for (final f in _files) {
        f.status = FileStatus.transferring;
        f.progress = 0;
      }
    });
    _broadcastCtrl.forward(from: 0);
  }

  void _addMockFile() {
    if (_files.length >= 6) return;
    setState(() => _files.add(_mockFilePool[_files.length % _mockFilePool.length]));
  }

  void _removeFile(int index) {
    if (_isBroadcasting) return;
    setState(() => _files.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Column(children: [
          // ── Top Bar ───────────────────────────────
          Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child:
                    const Icon(Icons.menu, color: kCyan, size: 26),
                  ),
                  const Text('SHAMBLES TRANSFER',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2)),
                  const Icon(Icons.info_outline, color: kCyan, size: 22),
                ]),
          ),

          // ── Room Badge ────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding:
            const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('ROOM',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 5)),
                  Text('OPE-OPE PROTOCOL ACTIVE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 1.5,
                          color: kCyan.withOpacity(0.5))),
                ]),
          ),
          const SizedBox(height: 12),

          // ── File Staging Header ───────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('STAGED (${_files.length})',
                      style: TextStyle(
                          fontSize: 12,
                          letterSpacing: 2,
                          color: kCyan.withOpacity(0.6),)),
                  GestureDetector(
                    onTap: _isBroadcasting ? null : _addMockFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: _isBroadcasting
                                ? kBorderDim
                                : kCyan.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(children: [
                        Icon(Icons.add,
                            color: _isBroadcasting
                                ? Colors.white24
                                : kCyan,
                            size: 14),
                        const SizedBox(width: 4),
                        Text('ADD FILE',
                            style: TextStyle(
                                fontSize: 12,
                                color: _isBroadcasting
                                    ? Colors.white24
                                    : kCyan,
                                letterSpacing: 1.5,)),
                      ]),
                    ),
                  ),
                ]),
          ),
          const SizedBox(height: 6),

          // ── Horizontal File Chip List ─────────────
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _files.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) => FileChip(
                file: _files[i],
                onRemove: _isBroadcasting ? null : () => _removeFile(i),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // ── Central Shambles Circle ───────────────
          Expanded(
            child: Stack(alignment: Alignment.center, children: [
              // Floating ambient dots
              ...List.generate(5, (i) {
                return AnimatedBuilder(
                  animation: _dotAnims[i],
                  builder: (_, __) => Transform.translate(
                    offset: _dotOffsets[i] + Offset(0, _dotAnims[i].value),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kCyan.withOpacity(0.5),
                        boxShadow: [
                          BoxShadow(
                              color: kCyan.withOpacity(0.6), blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                );
              }),

              // Orbit ring (spins faster when broadcasting)
              AnimatedBuilder(
                animation: _orbitAnim,
                builder: (_, __) => CustomPaint(
                  size: const Size(240, 240),
                  painter: OrbitRingPainter(
                      _orbitAnim.value, _isBroadcasting),
                ),
              ),

              // Pulsing central glow circle
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kCyan,
                      boxShadow: [
                        BoxShadow(
                            color: kCyan.withOpacity(0.6),
                            blurRadius: 30,
                            spreadRadius: 4),
                        BoxShadow(
                            color: kCyan.withOpacity(0.25),
                            blurRadius: 60,
                            spreadRadius: 16),
                      ],
                    ),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.content_cut,
                              size: 36, color: kDarkBg),
                          const SizedBox(height: 6),
                          const Text('SHAMBLES',
                              style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: kDarkBg,
                                  letterSpacing: 2)),
                        ]),
                  ),
                ),
              ),
            ]),
          ),

          // ── Broadcast / Progress Area ─────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(children: [
              if (_isBroadcasting || _broadcastPercent >= 100)
                BroadcastProgressBar(
                  percent: _broadcastPercent,
                  peersInRange: _peersInRange,
                  speedMbps: _speedMbps,
                  etaSeconds: ((1.0 - _broadcastCtrl.value) *
                          _broadcastCtrl.duration!.inSeconds)
                      .ceil(),
                )
              else
                GestureDetector(
                  onTap: _startBroadcast,
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: kCardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: kBorderDim),
                    ),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.send_outlined,
                              color: kCyan, size: 18),
                          const SizedBox(width: 10),
                          const Text('BROADCAST TO PEERS',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                  color: kCyan)),
                        ]),
                  ),
                ),
              const SizedBox(height: 10),

              // Protocol + Nodes info row
              Row(children: [
                Expanded(
                    child: InfoTile(
                        label: 'PROTOCOL', value: 'OP-OP-0002-X')),
                const SizedBox(width: 8),
                Expanded(
                    child: InfoTile(
                        label: 'NODES',
                        value: '${widget.peers.length}')),
              ]),
              const SizedBox(height: 8),
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
                      icon: Icons.swap_horiz,
                      label: 'TRANSFER',
                      selected: _selectedTab == 0,
                      onTap: () => setState(() => _selectedTab = 0)),
                  NavItem(
                      icon: Icons.history_edu_outlined,
                      label: 'HISTORY',
                      selected: _selectedTab == 1,
                      onTap: () {
                        setState(() => _selectedTab = 1);
                        Navigator.of(context).push(PageRouteBuilder(
                          transitionDuration:
                          const Duration(milliseconds: 400),
                          pageBuilder: (_, __, ___) =>
                          const HistoryLogScreen(),
                          transitionsBuilder:
                              (_, animation, __, child) => FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                  begin: const Offset(0.05, 0),
                                  end: Offset.zero)
                                  .animate(CurvedAnimation(
                                  parent: animation,
                                  curve: Curves.easeOut)),
                              child: child,
                            ),
                          ),
                        ));
                      }),
                  NavItem(
                      icon: Icons.folder_outlined,
                      label: 'FILES',
                      selected: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2)),
                ]),
          ),
        ]),
      ),
    );
  }
}

