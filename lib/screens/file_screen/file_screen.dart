import 'dart:math';
import 'package:flutter/material.dart';
import 'package:gal/gal.dart';
import 'package:open_filex/open_filex.dart';
import 'package:opShare/services/staging_store.dart';
import 'package:opShare/screens/shambles/transfer_file.dart';
import 'transfer_status.dart';
import 'manifest_entry.dart';
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

  StagingStore get _store => StagingStore.instance;

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

  static const _imageExts = {'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic', 'heif'};

  Future<void> _saveFile(BuildContext ctx, String path, String filename) async {
    final ext = filename.contains('.')
        ? filename.split('.').last.toLowerCase()
        : '';
    try {
      if (_imageExts.contains(ext)) {
        // Save image directly to the device gallery (Camera Roll on iOS)
        await Gal.putImage(path, album: 'Op Share');
        if (ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Saved to gallery')),
          );
        }
      } else {
        // For other file types, open with the native app
        // (e.g. PDF viewer, audio player) — user can save from there
        final result = await OpenFilex.open(path);
        if (result.type != ResultType.done && ctx.mounted) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text('Cannot open file: ${result.message}')),
          );
        }
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
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
                  child: ListenableBuilder(
                    listenable: _store,
                    builder: (context, _) => SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),
                          if (_store.activeFiles.isNotEmpty) ...[
                            _buildActiveShambles(),
                            const SizedBox(height: 18),
                          ],
                          _buildTransferManifest(),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
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
            onTap: () => Navigator.of(context).pop(),
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
    final files = _store.activeFiles;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FFC8).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: const Icon(Icons.bolt, color: Color(0xFF00FFC8), size: 13),
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
              Text(
                'FILES: ${files.length}',
                style: const TextStyle(
                  color: Color(0xFF00FFC8),
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...files.asMap().entries.map((e) {
            final f = e.value;
            final ctrl = e.key == 0 ? _progressController1 : _progressController2;
            final anim = e.key == 0 ? _progress1Anim : _progress2Anim;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AnimatedBuilder(
                animation: ctrl,
                builder: (_, __) => _buildActiveFileCard(f, anim.value),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActiveFileCard(TransferFile f, double progressValue) {
    const progressColor = Color(0xFF00FFC8);
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
                  '${f.name}.${f.ext}',
                  style: const TextStyle(
                    color: Color(0xFFCCE0F5),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                f.size,
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
          const Text(
            'BROADCASTING...',
            style: TextStyle(
              color: progressColor,
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 8),
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
                widthFactor: progressValue.clamp(0.0, 1.0),
                child: Container(
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF007B63), progressColor],
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
          if (_store.transferHistory.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'NO TRANSFERS YET',
                  style: TextStyle(
                    color: const Color(0xFF00FFC8).withOpacity(0.3),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    letterSpacing: 2,
                  ),
                ),
              ),
            )
          else
            ...List.generate(
              _store.transferHistory.length,
              (i) {
                final entries = _store.transferHistory;
                return Column(
                  children: [
                    _buildManifestTile(entries[i]),
                    if (i < entries.length - 1)
                      Container(
                        height: 1,
                        margin: const EdgeInsets.symmetric(vertical: 2),
                        color: const Color(0xFF0E1826),
                      ),
                  ],
                );
              },
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
                      entry.status == TransferStatus.received
                          ? 'From: ${entry.target}'
                          : 'Target: ${entry.target}',
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
                // Save button for received files
                if (entry.status == TransferStatus.received && entry.savedPath != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _saveFile(context, entry.savedPath!, entry.filename),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.greenAccent.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.download_outlined,
                            color: Colors.greenAccent, size: 12),
                        SizedBox(width: 5),
                        Text('SAVE TO DEVICE',
                            style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 9,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1)),
                      ]),
                    ),
                  ),
                ],
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
        label = 'SENT';
        break;
      case TransferStatus.received:
        bg = Colors.greenAccent.withOpacity(0.08);
        border = Colors.greenAccent.withOpacity(0.3);
        text = Colors.greenAccent;
        label = 'RECEIVED';
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
      case TransferStatus.received:
        return Colors.greenAccent.withOpacity(0.07);
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
      case TransferStatus.received:
        return Colors.greenAccent.withOpacity(0.2);
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
      case TransferStatus.received:
        return Colors.greenAccent.withOpacity(0.75);
      default:
        return const Color(0xFF00FFC8).withOpacity(0.75);
    }
  }


}