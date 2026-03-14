import 'dart:math';
import 'package:flutter/material.dart';
import 'transfer_status.dart';
import 'active_transfer.dart';
import 'manifest_entry.dart';
import '../shambles/shambles_transfer_screen.dart';


class FileScreen extends StatefulWidget {
  const FileScreen({super.key});

  @override
  State<FileScreen> createState() => _ManifestDetailsScreenState();
}

class _ManifestDetailsScreenState extends State<FileScreen>
    with TickerProviderStateMixin {

  late AnimationController _scanController;
  late AnimationController _progressController1;
  late AnimationController _progressController2;
  late AnimationController _fabPulseController;

  late Animation<double> _progress1Anim;
  late Animation<double> _progress2Anim;
  late Animation<double> _fabPulse;

  final List<ActiveTransfer> _activeTransfers = const [
    ActiveTransfer(
      filename: 'heart_anatomy.png',
      speed: '12.4 MB/s',
      eta: 'ETA: 00:04s',
      progress: 0.72,
      statusLabel: 'BROADCASTING...',
    ),
    ActiveTransfer(
      filename: 'surgeon_notes.pdf',
      speed: '8.1 MB/s',
      eta: 'ETA: 00:12s',
      progress: 0.42,
      statusLabel: 'SYNCING...',
    ),
  ];

  final List<ManifestEntry> _manifestEntries = const [
    ManifestEntry(
      filename: 'cardiac_valve_scan_4k.jpg',
      size: '4.2 MB',
      target: 'Thousand Sunny',
      room: 'OP-992',
      status: TransferStatus.success,
    ),
    ManifestEntry(
      filename: 'shambles_protocol_v2.sh',
      size: '0.12 MB',
      target: 'Node_Zoro',
      room: 'OP-003',
      status: TransferStatus.syncing,
    ),
    ManifestEntry(
      filename: 'forbidden_history_void...',
      size: '2.8 GB',
      target: 'Unknown_Node',
      room: 'OP-EAR',
      status: TransferStatus.interrupted,
    ),
    ManifestEntry(
      filename: 'scalpel_calibration.log',
      size: '1.5 MB',
      target: 'Medical_Bay_01',
      room: 'OP-10',
      status: TransferStatus.success,
    ),
  ];

  @override
  void initState() {
    super.initState();

    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _progressController1 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _progressController2 = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat();

    _fabPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _progress1Anim = Tween<double>(begin: 0.55, end: 0.95).animate(
      CurvedAnimation(parent: _progressController1, curve: Curves.easeInOut),
    );
    _progress2Anim = Tween<double>(begin: 0.25, end: 0.70).animate(
      CurvedAnimation(parent: _progressController2, curve: Curves.easeInOut),
    );
    _fabPulse = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _fabPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanController.dispose();
    _progressController1.dispose();
    _progressController2.dispose();
    _fabPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C11),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(bottom: 80),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 14),
                        _buildActiveShambles(),
                        const SizedBox(height: 18),
                        _buildTransferManifest(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // FAB
            Positioned(
              bottom: 70,
              left: 0,
              right: 0,
              child: Center(child: _buildFab()),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF141E2E), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.of(context).pushReplacement(PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (_, _, _) =>
                    const ShamblesTransferScreen(peers: []),
                transitionsBuilder: (_, animation, _, child) =>
                    FadeTransition(opacity: animation, child: child),
              ));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Icon(Icons.chevron_left,
                    color: Color(0xFF4A6080), size: 18),
                const SizedBox(width: 2),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'MANIFEST_0x7F4',
                  style: TextStyle(
                    color: Color(0xFF00FFC8),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedBuilder(
                      animation: _scanController,
                      builder: (_, __) {
                        final opacity =
                        (sin(_scanController.value * 2 * pi) * 0.4 + 0.6)
                            .clamp(0.2, 1.0);
                        return Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFF00FFC8).withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SCANNING NEURAL NETWORK...',
                      style: TextStyle(
                        color: const Color(0xFF00FFC8).withOpacity(0.6),
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        letterSpacing: 1.6,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
         SizedBox(width: 32,),
        ],
      ),
    );
  }

  // ─── Active Shambles Section ──────────────────────────────────────────────

  Widget _buildActiveShambles() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFC8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.bolt,
                    color: Color(0xFF00FFC8), size: 13),
              ),
              const SizedBox(width: 8),
              const Text(
                'ACTIVE SHAMBLES',
                style: TextStyle(
                  color: Color(0xFFB0C8E0),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: 'NODES_CONNECTED: ',
                      style: TextStyle(
                        color: Color(0xFF2A4060),
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        letterSpacing: 1,
                      ),
                    ),
                    TextSpan(
                      text: '84',
                      style: TextStyle(
                        color: Color(0xFF00FFC8),
                        fontSize: 8.5,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Card 1
          AnimatedBuilder(
            animation: _progress1Anim,
            builder: (_, __) => _buildActiveTransferCard(
              transfer: _activeTransfers[0],
              progressValue: _progress1Anim.value,
              progressColor: const Color(0xFF00FFC8),
            ),
          ),
          const SizedBox(height: 10),
          // Card 2
          AnimatedBuilder(
            animation: _progress2Anim,
            builder: (_, __) => _buildActiveTransferCard(
              transfer: _activeTransfers[1],
              progressValue: _progress2Anim.value,
              progressColor: const Color(0xFF00FFC8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTransferCard({
    required ActiveTransfer transfer,
    required double progressValue,
    required Color progressColor,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF162030), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  transfer.filename,
                  style: const TextStyle(
                    color: Color(0xFFCCE0F5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Text(
                transfer.speed,
                style: const TextStyle(
                  color: Color(0xFF8AAAC8),
                  fontSize: 11,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Text(
                transfer.statusLabel,
                style: TextStyle(
                  color: progressColor,
                  fontSize: 9,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
              const Spacer(),
              Text(
                transfer.eta,
                style: TextStyle(
                  color: const Color(0xFF3A5070).withOpacity(0.9),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1826),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progressValue,
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: LinearGradient(
                      colors: [
                        progressColor.withOpacity(0.5),
                        progressColor,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: progressColor.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Transfer Manifest Section ────────────────────────────────────────────

  Widget _buildTransferManifest() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFC8).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.article_outlined,
                    color: Color(0xFF00FFC8), size: 13),
              ),
              const SizedBox(width: 8),
              const Text(
                'TRANSFER MANIFEST',
                style: TextStyle(
                  color: Color(0xFFB0C8E0),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.2,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    'PURGE LOGS',
                    style: TextStyle(
                      color: const Color(0xFF2A4060).withOpacity(0.9),
                      fontSize: 8.5,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.delete_outline,
                    color: const Color(0xFF2A4060).withOpacity(0.7),
                    size: 13,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Entries
          ...List.generate(
            _manifestEntries.length,
                (i) => Column(
              children: [
                _buildManifestTile(_manifestEntries[i]),
                if (i < _manifestEntries.length - 1)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    color: const Color(0xFF0E1826),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManifestTile(ManifestEntry entry) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF131F30), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // File type icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _iconBg(entry.status),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(
                color: _iconBorder(entry.status),
                width: 1,
              ),
            ),
            child: Icon(
              _fileIcon(entry.filename, entry.status),
              color: _iconColor(entry.status),
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.filename,
                        style: const TextStyle(
                          color: Color(0xFFAAC4DE),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                          letterSpacing: 0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusChip(entry.status),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.sd_storage_outlined,
                        color: Color(0xFF2A4060), size: 10),
                    const SizedBox(width: 3),
                    Text(
                      entry.size,
                      style: const TextStyle(
                        color: Color(0xFF2A4060),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(Icons.near_me_outlined,
                        color: Color(0xFF2A4060), size: 10),
                    const SizedBox(width: 3),
                    Text(
                      'Target: ${entry.target}',
                      style: const TextStyle(
                        color: Color(0xFF2A4060),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.workspaces_outline,
                        color: Color(0xFF1E3050), size: 10),
                    const SizedBox(width: 3),
                    Text(
                      'Room: ${entry.room}',
                      style: const TextStyle(
                        color: Color(0xFF1E3050),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(TransferStatus status) {
    Color bg, border, text;
    String label;
    switch (status) {
      case TransferStatus.success:
        bg = const Color(0xFF00FFC8).withOpacity(0.08);
        border = const Color(0xFF00FFC8).withOpacity(0.3);
        text = const Color(0xFF00FFC8);
        label = 'SUCCESS';
        break;
      case TransferStatus.syncing:
        bg = const Color(0xFF007BFF).withOpacity(0.08);
        border = const Color(0xFF007BFF).withOpacity(0.35);
        text = const Color(0xFF4DA8FF);
        label = 'SYNCING';
        break;
      case TransferStatus.interrupted:
        bg = const Color(0xFFFF4D4D).withOpacity(0.1);
        border = const Color(0xFFFF4D4D).withOpacity(0.35);
        text = const Color(0xFFFF6B6B);
        label = 'INTERRUPTED';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: text,
          fontSize: 8,
          fontFamily: 'monospace',
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  IconData _fileIcon(String filename, TransferStatus status) {
    if (status == TransferStatus.interrupted) return Icons.error_outline;
    if (filename.contains('.jpg') || filename.contains('.png')) {
      return Icons.image_outlined;
    }
    if (filename.contains('.sh')) return Icons.terminal;
    if (filename.contains('.log')) return Icons.description_outlined;
    return Icons.insert_drive_file_outlined;
  }

  Color _iconBg(TransferStatus status) {
    switch (status) {
      case TransferStatus.interrupted:
        return const Color(0xFFFF4D4D).withOpacity(0.1);
      case TransferStatus.syncing:
        return const Color(0xFF007BFF).withOpacity(0.08);
      default:
        return const Color(0xFF00FFC8).withOpacity(0.07);
    }
  }

  Color _iconBorder(TransferStatus status) {
    switch (status) {
      case TransferStatus.interrupted:
        return const Color(0xFFFF4D4D).withOpacity(0.3);
      case TransferStatus.syncing:
        return const Color(0xFF007BFF).withOpacity(0.25);
      default:
        return const Color(0xFF00FFC8).withOpacity(0.2);
    }
  }

  Color _iconColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.interrupted:
        return const Color(0xFFFF6B6B);
      case TransferStatus.syncing:
        return const Color(0xFF4DA8FF);
      default:
        return const Color(0xFF00FFC8).withOpacity(0.75);
    }
  }

  // ─── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    return AnimatedBuilder(
      animation: _fabPulse,
      builder: (_, child) {
        return Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFC8).withOpacity(0.35 * _fabPulse.value),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: Color(0xFF00FFC8),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.add, color: Color(0xFF050A0F), size: 26),
        ),
      ),
    );
  }

}