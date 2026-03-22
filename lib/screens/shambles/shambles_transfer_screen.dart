
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:opShare/screens/room_intitiation/colors_room.dart';
import 'package:opShare/screens/shambles/transfer_file.dart';
import 'package:opShare/services/chunked_upload_service.dart';
import 'package:opShare/services/staging_store.dart';
import 'package:path_provider/path_provider.dart';

import '../file_screen/file_screen.dart';
import '../file_screen/manifest_entry.dart';
import '../file_screen/transfer_status.dart';
import '../history/history_log_screen.dart';
import '../scanning_room/nav_item.dart';
import '../scanning_room/radar_node.dart';
import '../../services/webrtc_service.dart';

import 'broadcast_progress_bar.dart';
import 'file_chip.dart';
import 'file_status.dart';
import 'info_tile.dart';
import 'orbit_ring_painter.dart';


class ShamblesTransferScreen extends StatefulWidget {
  final List<RadarNode> peers;
  final WebRTCService webrtc;

  const ShamblesTransferScreen({super.key, required this.peers, required this.webrtc});

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


  final List<TransferFile> _files = [];
  final ChunkedUploadService _uploadService = ChunkedUploadService();
  String? _activeUploadId;

  bool _isBroadcasting = false;
  bool _isPicking = false;
  double _uploadProgress = 0;
  double _speedMbps = 0;
  int _etaSeconds = 0;
  final List<(DateTime, int)> _speedSamples = [];
  int _selectedTab = 0; // TRANSFER tab

  // Incoming transfer state (receiver side)
  bool _isReceiving = false;
  bool _receiveComplete = false;
  int _receivedBytes = 0;
  final Map<String, List<int>> _receiveBuffers = {};
  final Map<String, _FileMeta> _incomingMeta = {};

  // Fixed dot positions around the central circle
  static const List<Offset> _dotOffsets = [
    Offset(-90, -20),
    Offset(85, -35),
    Offset(100, 45),
    Offset(-80, 55),
    Offset(10, -95),
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

    // Broadcast fill animation
    _broadcastCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6));
    _broadcastAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _broadcastCtrl, curve: Curves.easeInOut));
    _broadcastCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        final peerLabels = widget.peers.map((p) => p.label).toList();
        // Publish completed files to shared store (FileScreen reads this)
        StagingStore.instance.markAllDone('ACTIVE', peerLabels);
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

    // Receive file metadata (name/ext/size) before bytes arrive
    widget.webrtc.onFileMeta = (fromPeerId, name, ext, totalSize) {
      _incomingMeta[fromPeerId] = _FileMeta(name, ext, totalSize);
      _receiveBuffers[fromPeerId] = [];
      if (mounted) setState(() => _isReceiving = true);
    };

    // Listen for incoming file chunks from peers
    widget.webrtc.onDataReceived = (fromPeerId, chunk, _) {
      if (!mounted) return;
      _receiveBuffers.putIfAbsent(fromPeerId, () => []);
      _receiveBuffers[fromPeerId]!.addAll(chunk);

      final meta = _incomingMeta[fromPeerId];
      final received = _receiveBuffers[fromPeerId]!.length;
      final isComplete = meta != null
          ? received >= meta.totalSize
          : chunk.length < 64 * 1024;

      final totalBytes = _receiveBuffers.values.fold<int>(0, (sum, buf) => sum + buf.length);
      setState(() {
        _isReceiving = !isComplete;
        _receivedBytes = totalBytes;
        if (isComplete) {
          _receiveComplete = true;
          final bytes = Uint8List.fromList(_receiveBuffers[fromPeerId]!);
          _receiveBuffers.remove(fromPeerId);
          _incomingMeta.remove(fromPeerId);
          _saveReceivedFile(fromPeerId, bytes, meta);
          Future.delayed(const Duration(seconds: 4), () {
            if (mounted) setState(() { _receiveComplete = false; _receivedBytes = 0; });
          });
        }
      });
    };
  }

  @override
  void dispose() {
    if (_activeUploadId != null) {
      _uploadService.cancelUpload(_activeUploadId!);
    }
    _orbitCtrl.dispose();
    _broadcastCtrl.dispose();
    for (final c in _dotCtrls) c.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // ── Actions ───────────────────────────────

  /// If a previous broadcast completed, reset so "BROADCAST TO PEERS" button shows again.
  void _resetBroadcastIfDone() {
    if (_broadcastCtrl.isCompleted && !_isBroadcasting) {
      _broadcastCtrl.reset();
      for (final f in _files) {
        f.status = FileStatus.queued;
        f.progress = 0;
      }
    }
  }

  Future<void> _saveReceivedFile(
      String fromPeerId, Uint8List bytes, _FileMeta? meta) async {
    final name = meta?.name ?? 'file_${DateTime.now().millisecondsSinceEpoch}';
    final ext = meta?.ext ?? 'bin';
    try {
      final dir = await getApplicationDocumentsDirectory();
      final receivedDir = Directory('${dir.path}/received');
      await receivedDir.create(recursive: true);
      // Avoid overwriting by appending a counter if file exists
      String filePath = '${receivedDir.path}/$name.$ext';
      int counter = 1;
      while (await File(filePath).exists()) {
        filePath = '${receivedDir.path}/${name}_$counter.$ext';
        counter++;
      }
      await File(filePath).writeAsBytes(bytes);
      StagingStore.instance.addReceivedFile(ManifestEntry(
        filename: '$name.$ext',
        size: _formatBytes(bytes.length),
        target: fromPeerId,
        room: widget.webrtc.roomCode,
        status: TransferStatus.received,
        savedPath: filePath,
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save file: $e')));
      }
    }
  }

  void _startBroadcast() async {
    if (_isBroadcasting || _files.isEmpty) return;
    setState(() {
      _isBroadcasting = true;
      _uploadProgress = 0;
      _speedMbps = 0;
      _etaSeconds = 0;
      _speedSamples.clear();
      for (final f in _files) {
        f.status = FileStatus.transferring;
        f.progress = 0;
      }
    });

    StagingStore.instance.setActiveFiles(List.from(_files));

    // Use ALL WebRTC-connected peers regardless of same-network or not.
    // isPeerSameNetwork requires IP exchange to have completed — if that
    // hasn't happened yet it returns false for everyone and nothing gets sent.
    final connectedPeerIds = widget.webrtc.connectedPeerIds;

    if (connectedPeerIds.isNotEmpty) {
      final sendableFiles = _files.where((f) => f.bytes != null && f.bytes!.isNotEmpty).toList();
      final total = sendableFiles.length;
      for (int i = 0; i < sendableFiles.length; i++) {
        final f = sendableFiles[i];
        final fileIndex = i;
        await widget.webrtc.sendFileToPeers(
          connectedPeerIds,
          f.bytes!,
          name: f.name,
          ext: f.ext,
          onProgress: (p) {
            if (!mounted) return;
            final now = DateTime.now();
            final bytesSent = (p * f.bytes!.length).round();

            // Rolling window of 5 samples (~320 KB of data)
            _speedSamples.add((now, bytesSent));
            if (_speedSamples.length > 5) _speedSamples.removeAt(0);

            double speedBps = 0;
            if (_speedSamples.length >= 2) {
              final first = _speedSamples.first;
              final last = _speedSamples.last;
              final deltaBytes = last.$2 - first.$2;
              final deltaSecs = last.$1.difference(first.$1).inMilliseconds / 1000.0;
              if (deltaSecs > 0) speedBps = deltaBytes / deltaSecs;
            }

            final newProgress = (fileIndex + p) / total;
            final totalBytes = _files.fold<int>(0, (s, f) => s + (f.bytes?.length ?? 0));
            final remaining = ((1.0 - newProgress) * totalBytes).round();
            final eta = speedBps > 0 ? (remaining / speedBps).ceil() : 0;

            setState(() {
              _uploadProgress = newProgress;
              _speedMbps = speedBps / (1024 * 1024);
              _etaSeconds = eta;
            });
          },
        );
      }
      // Mark 100% when done
      if (mounted) setState(() => _uploadProgress = 1.0);
    }

    // Drive the visual progress bar to completion
    _broadcastCtrl.forward(from: _uploadProgress);

    // API: chunked upload as fallback for peers not on WebRTC
    final roomId = int.parse(widget.webrtc.roomCode);
    final notConnected = widget.peers
        .where((p) => !connectedPeerIds.contains(p.peerName))
        .toList();
    if (notConnected.isNotEmpty) {
      for (final f in _files) {
        await _uploadViaApi(f, roomId);
      }
    }
  }

  Future<void> _uploadViaApi(TransferFile f, int roomId) async {
    if (f.bytes == null || f.bytes!.isEmpty) return;

    try {
      final hash = ChunkedUploadService.computeHash(f.bytes!);
      final isDup = await _uploadService.isDuplicate(hash, roomId);
      if (isDup) return;

      final mimeType = _mimeForExt(f.ext);
      final uploadId = await _uploadService.initUpload(
          '${f.name}.${f.ext}', f.bytes!.length, mimeType, roomId);
      _activeUploadId = uploadId;

      await _uploadService.uploadChunks(uploadId, f.bytes!, onProgress: (p) {
        if (mounted) setState(() => _uploadProgress = p);
      });

      await _uploadService.completeUpload(uploadId);
      _activeUploadId = null;
    } catch (e) {
      _activeUploadId = null;
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  static String _mimeForExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      case 'mp4':
        return 'video/mp4';
      case 'mov':
        return 'video/quicktime';
      case 'mp3':
        return 'audio/mpeg';
      case 'wav':
        return 'audio/wav';
      case 'zip':
        return 'application/zip';
      case 'doc':
      case 'docx':
        return 'application/msword';
      default:
        return 'application/octet-stream';
    }
  }

  Future<void> _pickFile() async {
    if (_isBroadcasting || _files.length >= 8 || _isPicking) return;
    setState(() => _isPicking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
        type: FileType.any,
      );
      if (result == null || result.files.isEmpty) return;
      _resetBroadcastIfDone();
      setState(() {
        for (final pf in result.files) {
          if (_files.length >= 8) break;
          final ext = (pf.extension ?? 'bin').toLowerCase();
          _files.add(TransferFile(
            name: pf.name.contains('.')
                ? pf.name.substring(0, pf.name.lastIndexOf('.'))
                : pf.name,
            ext: ext,
            size: _formatBytes(pf.size),
            icon: _iconForExt(ext),
            iconColor: _colorForExt(ext),
            path: pf.path,
            bytes: pf.bytes,
          ));
        }
      });
    } finally {
      setState(() => _isPicking = false);
    }
  }

  void _removeFile(int index) {
    if (_isBroadcasting) return;
    _resetBroadcastIfDone();
    setState(() => _files.removeAt(index));
  }

  // ── Helpers ───────────────────────────────
  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static IconData _iconForExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
        return Icons.image_outlined;
      case 'pdf':
        return Icons.picture_as_pdf_outlined;
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return Icons.videocam_outlined;
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
        return Icons.audio_file_outlined;
      case 'zip':
      case 'rar':
      case '7z':
      case 'tar':
        return Icons.folder_zip_outlined;
      case 'csv':
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_outlined;
      case 'doc':
      case 'docx':
        return Icons.description_outlined;
      case 'txt':
      case 'log':
        return Icons.article_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  static Color _colorForExt(String ext) {
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'heic':
        return kCyan;
      case 'pdf':
        return const Color(0xFFFF7043);
      case 'mp4':
      case 'mov':
      case 'avi':
      case 'mkv':
        return const Color(0xFFAB47BC);
      case 'mp3':
      case 'wav':
      case 'aac':
      case 'm4a':
        return const Color(0xFF42A5F5);
      case 'zip':
      case 'rar':
      case '7z':
        return const Color(0xFFFFD54F);
      case 'csv':
      case 'xls':
      case 'xlsx':
        return const Color(0xFF66BB6A);
      default:
        return const Color(0xFF90A4AE);
    }
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
                  const SizedBox(height: 12,),
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
                    onTap: (_isBroadcasting || _isPicking) ? null : _pickFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: (_isBroadcasting || _isPicking)
                                ? kBorderDim
                                : kCyan.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _isPicking
                          ? SizedBox(
                              width: 60,
                              height: 18,
                              child: Center(
                                child: SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    color: kCyan.withOpacity(0.7),
                                  ),
                                ),
                              ),
                            )
                          : Row(children: [
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
                                      letterSpacing: 1.5)),
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
              if (_isBroadcasting || _broadcastCtrl.isCompleted)
                AnimatedBuilder(
                  animation: _broadcastAnim,
                  builder: (_, __) {
                    // Show real progress when we have it; fall back to animation
                    final realPct = _uploadProgress * 100;
                    final animPct = _broadcastAnim.value * 100;
                    final showPct = realPct > 0 ? realPct : animPct;
                    return BroadcastProgressBar(
                      percent: showPct,
                      peersInRange: widget.peers.length,
                      speedMbps: _speedMbps,
                      etaSeconds: showPct >= 100 ? 0 : _etaSeconds,
                    );
                  },
                )
              else if (_isReceiving || _receiveComplete)
                _IncomingTransferCard(
                  isReceiving: _isReceiving,
                  receivedBytes: _receivedBytes,
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
                      onTap: () {
                        setState(() => _selectedTab = 2);
                        Navigator.of(context).push(PageRouteBuilder(
                          transitionDuration:
                          const Duration(milliseconds: 400),
                          pageBuilder: (_, __, ___) =>
                          const FileScreen(),
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
                ]),
          ),
        ]),
      ),
    );
  }
}

class _IncomingTransferCard extends StatelessWidget {
  final bool isReceiving;
  final int receivedBytes;

  const _IncomingTransferCard({
    required this.isReceiving,
    required this.receivedBytes,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    final done = !isReceiving;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1F0D),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: done
              ? Colors.greenAccent.withOpacity(0.4)
              : Colors.greenAccent.withOpacity(0.25),
        ),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Colors.greenAccent : Colors.greenAccent.withOpacity(0.7),
                boxShadow: [
                  BoxShadow(color: Colors.greenAccent.withOpacity(0.6), blurRadius: 6)
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(done ? 'FILE RECEIVED' : 'INCOMING TRANSFER',
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.greenAccent,
                    letterSpacing: 2)),
          ]),
          Text(_formatBytes(receivedBytes),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: done ? 1.0 : null,
            backgroundColor: Colors.greenAccent.withOpacity(0.12),
            color: Colors.greenAccent,
            minHeight: 6,
          ),
        ),
        if (done) ...[
          const SizedBox(height: 8),
          Text('Transfer complete — view in FILES tab',
              style: TextStyle(
                  fontSize: 9,
                  color: Colors.greenAccent.withOpacity(0.6),
                  letterSpacing: 1)),
        ],
      ]),
    );
  }
}

class _FileMeta {
  final String name;
  final String ext;
  final int totalSize;
  const _FileMeta(this.name, this.ext, this.totalSize);
}
