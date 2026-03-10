// ─────────────────────────────────────────────────────────────────────────────
// shambles_transfer_screen.dart
//
// Screen 3 — Shambles Transfer
// Handles file staging, animated broadcast, and per-peer transfer progress.
//
// Depends on:  room_constants.dart  (kCyan, kDarkBg, kCardBg, kBorderDim,
//                                     RadarNode, NavItem)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';

import '../scanning_room/nav_item.dart';
import '../scanning_room/radar_node.dart';

// ─────────────────────────────────────────────
// FILE TRANSFER MODEL
// ─────────────────────────────────────────────
enum FileStatus { queued, transferring, done, failed }

class TransferFile {
  final String name;
  final String ext;
  final String size;
  final IconData icon;
  final Color iconColor;
  double progress; // 0.0 – 1.0
  FileStatus status;

  TransferFile({
    required this.name,
    required this.ext,
    required this.size,
    required this.icon,
    required this.iconColor,
    this.progress = 0.0,
    this.status = FileStatus.queued,
  });
}

// ─────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────
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
  // ── Animation controllers ─────────────────
  late final AnimationController _orbitCtrl;
  late final Animation<double> _orbitAnim;

  late final AnimationController _broadcastCtrl;
  late final Animation<double> _broadcastAnim;

  late final List<AnimationController> _dotCtrls;
  late final List<Animation<double>> _dotAnims;

  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // ── State ─────────────────────────────────
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
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorderDim),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ROOM',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 1)),
                        Text('GAMMA/OPE-OPE PROTOCOL ACTIVE',
                            style: TextStyle(
                                fontSize: 8,
                                letterSpacing: 1.5,
                                color: kCyan.withOpacity(0.5),
                                fontFamily: 'monospace')),
                      ]),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: kBorderDim,
                        borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.router_outlined,
                        color: kCyan, size: 20),
                  ),
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
                          fontSize: 9,
                          letterSpacing: 2,
                          color: kCyan.withOpacity(0.6),
                          fontFamily: 'monospace')),
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
                                fontSize: 9,
                                color: _isBroadcasting
                                    ? Colors.white24
                                    : kCyan,
                                letterSpacing: 1.5,
                                fontFamily: 'monospace')),
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
                      onTap: () => setState(() => _selectedTab = 1)),
                  NavItem(
                      icon: Icons.folder_outlined,
                      label: 'FILES',
                      selected: _selectedTab == 2,
                      onTap: () => setState(() => _selectedTab = 2)),
                  NavItem(
                      icon: Icons.settings_outlined,
                      label: 'CONFIG',
                      selected: _selectedTab == 3,
                      onTap: () => setState(() => _selectedTab = 3)),
                ]),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUB-WIDGETS  (public so they can be unit-tested or reused)
// ─────────────────────────────────────────────────────────────────────────────

/// Horizontal file card in the staged list
class FileChip extends StatelessWidget {
  final TransferFile file;
  final VoidCallback? onRemove;

  const FileChip({super.key, required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDone = file.status == FileStatus.done;
    final isTransferring = file.status == FileStatus.transferring;

    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDone ? kCyan.withOpacity(0.6) : kBorderDim),
      ),
      child: Row(children: [
        Icon(file.icon, color: file.iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${file.name}.${file.ext}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(file.size,
                      style: TextStyle(
                          fontSize: 8,
                          color: kCyan.withOpacity(0.5),
                          fontFamily: 'monospace')),
                  if (isDone) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline,
                        color: kCyan, size: 10),
                  ],
                ]),
                if (isTransferring)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: LinearProgressIndicator(
                      value: file.progress,
                      backgroundColor: kBorderDim,
                      color: kCyan,
                      minHeight: 2,
                    ),
                  ),
              ]),
        ),
        if (onRemove != null)
          GestureDetector(
            onTap: onRemove,
            child:
            const Icon(Icons.close, color: Colors.white24, size: 14),
          ),
      ]),
    );
  }
}

/// Animated orbit rings around the central Shambles circle
class OrbitRingPainter extends CustomPainter {
  final double angle;
  final bool active;

  OrbitRingPainter(this.angle, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Static dim rings
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = kCyan.withOpacity(0.15)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);

    canvas.drawCircle(
        center,
        radius * 0.72,
        Paint()
          ..color = kCyan.withOpacity(0.10)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);

    if (!active) return;

    // Outer spinning arc
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        pi * 0.8,
        false,
        Paint()
          ..color = kCyan.withOpacity(0.7)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Inner counter-spinning arc
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        -angle * 1.3,
        pi * 0.4,
        false,
        Paint()
          ..color = kCyan.withOpacity(0.4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant OrbitRingPainter old) =>
      old.angle != angle || old.active != active;
}

/// Live broadcast progress indicator
class BroadcastProgressBar extends StatelessWidget {
  final double percent;       // 0–100
  final int peersInRange;
  final double speedMbps;

  const BroadcastProgressBar({
    super.key,
    required this.percent,
    required this.peersInRange,
    required this.speedMbps,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    final done = pct >= 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderDim),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Colors.greenAccent : kCyan,
                  boxShadow: [
                    BoxShadow(
                        color: (done ? Colors.greenAccent : kCyan)
                            .withOpacity(0.7),
                        blurRadius: 6)
                  ]),
            ),
            const SizedBox(width: 8),
            Text(done ? 'TRANSFER COMPLETE' : 'BROADCASTING',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: done ? Colors.greenAccent : kCyan,
                    letterSpacing: 2)),
          ]),
          Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            backgroundColor: kBorderDim,
            color: done ? Colors.greenAccent : kCyan,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$peersInRange peers in range',
              style: TextStyle(
                  fontSize: 9,
                  color: kCyan.withOpacity(0.55),
                  fontFamily: 'monospace')),
          Text('${speedMbps.toStringAsFixed(0)} Mb/s',
              style: TextStyle(
                  fontSize: 9,
                  color: kCyan.withOpacity(0.55),
                  fontFamily: 'monospace')),
        ]),
      ]),
    );
  }
}

/// Small two-line info tile used at the bottom of the screen
class InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const InfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kBorderDim),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.5,
                color: kCyan.withOpacity(0.5),
                fontFamily: 'monospace')),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5)),
      ]),
    );
  }
}