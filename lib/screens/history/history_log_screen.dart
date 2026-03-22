import 'package:flutter/material.dart';
import 'package:opShare/screens/file_screen/manifest_entry.dart';
import 'package:opShare/screens/file_screen/transfer_status.dart';
import 'package:opShare/services/staging_store.dart';
import 'log_entry.dart';
import 'log_status.dart';

// ─── Screen ─────────────────────────────────────────────────────────────────

class HistoryLogScreen extends StatefulWidget {
  const HistoryLogScreen({super.key});

  @override
  State<HistoryLogScreen> createState() => _HistoryLogScreenState();
}

class _HistoryLogScreenState extends State<HistoryLogScreen>
    with TickerProviderStateMixin {
  int _selectedFilter = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // 0=ALL  1=SENT  2=RECEIVED  3=ABORTED
  final List<String> _filters = ['ALL', 'SENT', 'RECEIVED', 'ABORTED'];

  StagingStore get _store => StagingStore.instance;

  // Convert a ManifestEntry → LogEntry for display
  LogEntry _toLogEntry(ManifestEntry m, int index) {
    LogStatus logStatus;
    switch (m.status) {
      case TransferStatus.received:
        logStatus = LogStatus.received;
      case TransferStatus.interrupted:
        logStatus = LogStatus.aborted;
      case TransferStatus.syncing:
        logStatus = LogStatus.linked;
      default:
        logStatus = LogStatus.success;
    }

    final isReceived = m.status == TransferStatus.received;
    final isFailed = m.status == TransferStatus.interrupted;
    final shortTarget = m.target.length > 12
        ? m.target.substring(0, 12).toUpperCase()
        : m.target.toUpperCase();

    return LogEntry(
      id: index.toString(),
      name: 'SHAMBLES: ${m.filename.split('.').first.toUpperCase()}',
      dataNodes: isReceived ? 'FROM: $shortTarget' : 'TO: $shortTarget',
      swapped: m.size,
      timestamp: _formatTimestamp(m.timestamp),
      status: logStatus,
      sourceFingerprint: 'ROOM: ${m.room}  •  ${m.filename}',
      errorLog: isFailed ? 'TRANSFER_INTERRUPTED: connection lost.' : null,
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inDays == 0) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'Yesterday';
    return '${dt.day}/${dt.month}';
  }

  List<LogEntry> get _allEntries {
    final history = _store.transferHistory;
    return List.generate(history.length, (i) => _toLogEntry(history[i], i));
  }

  List<LogEntry> get _filteredEntries {
    final all = _allEntries;
    switch (_selectedFilter) {
      case 1: // SENT
        return all.where((e) => e.status == LogStatus.success || e.status == LogStatus.linked).toList();
      case 2: // RECEIVED
        return all.where((e) => e.status == LogStatus.received).toList();
      case 3: // ABORTED
        return all.where((e) => e.status == LogStatus.aborted).toList();
      default:
        return all;
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C11),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _store,
          builder: (context, _) => Column(
            children: [
              _buildHeader(),
              if (_store.transferHistory.isNotEmpty) _buildActiveCard(),
              _buildFilterRow(),
              _buildSequenceLabel(),
              Expanded(child: _buildLogList()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0xFF1C2333), width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.chevron_left,
                color: Color(0xFF00FFC8), size: 22),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'HISTORY',
                style: TextStyle(
                  color: Color(0xFFE0E8F0),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Active Card ──────────────────────────────────────────────────────────

  Widget _buildActiveCard() {
    final latest = _store.transferHistory.first;
    final totalFiles = _store.transferHistory.length;
    final isReceived = latest.status == TransferStatus.received;

    return Container(
      margin: const EdgeInsets.all(14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1520),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1A2840), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (_, __) => Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      const Color(0xFF00FFC8).withOpacity(0.3),
                      const Color(0xFF00FFC8),
                      _pulseAnimation.value,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFC8)
                            .withOpacity(0.4 * _pulseAnimation.value),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                isReceived ? 'LAST_RECEIVED' : 'LAST_SENT',
                style: const TextStyle(
                  color: Color(0xFF00FFC8),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                  fontFamily: 'monospace',
                ),
              ),
              const Spacer(),
              Text(
                _formatTimestamp(latest.timestamp),
                style: const TextStyle(
                  color: Color(0xFF3A5070),
                  fontSize: 9,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      latest.filename.split('.').first.toUpperCase(),
                      style: const TextStyle(
                        color: Color(0xFFD4E8FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ROOM: ${latest.room}',
                      style: TextStyle(
                        color: const Color(0xFF4A6080).withOpacity(0.9),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${latest.size}  •  ${isReceived ? 'FROM' : 'TO'}: ${latest.target.length > 10 ? latest.target.substring(0, 10) : latest.target}',
                      style: const TextStyle(
                        color: Color(0xFF2E4A6A),
                        fontSize: 9,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildViewManifestButton(totalFiles),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildRoomPreview(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewManifestButton(int totalFiles) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFF00FFC8).withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: const Color(0xFF00FFC8).withOpacity(0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'VIEW MANIFEST',
              style: TextStyle(
                color: Color(0xFF00FFC8),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFC8).withOpacity(0.25),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '+$totalFiles',
                style: const TextStyle(
                  color: Color(0xFF00FFC8),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomPreview() {
    return Container(
      width: 72,
      height: 88,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D2A3A), Color(0xFF051520)],
        ),
        border: Border.all(color: const Color(0xFF1A3050), width: 1),
      ),
      child: Stack(
        children: [
          ...List.generate(4, (i) {
            return Positioned(
              left: 8.0 + i * 16,
              top: 0,
              bottom: 0,
              child: Container(
                width: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF00FFC8).withOpacity(0.0),
                      const Color(0xFF00FFC8).withOpacity(0.15 + i * 0.05),
                      const Color(0xFF00FFC8).withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            );
          }),
          Center(
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00FFC8).withOpacity(0.15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFC8).withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Row ───────────────────────────────────────────────────────────

  Widget _buildFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_filters.length, (i) {
            final active = _selectedFilter == i;
            return Padding(
              padding: EdgeInsets.only(right: i < _filters.length - 1 ? 8 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _selectedFilter = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF00FFC8).withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF00FFC8).withOpacity(0.6)
                          : const Color(0xFF1C2A3A),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _filters[i],
                    style: TextStyle(
                      color: active
                          ? const Color(0xFF00FFC8)
                          : const Color(0xFF3A5070),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Sequence Label ───────────────────────────────────────────────────────

  Widget _buildSequenceLabel() {
    final count = _filteredEntries.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      child: Row(
        children: [
          Text(
            'TEMPORAL_SEQUENCE_LOGS ($count)',
            style: TextStyle(
              color: const Color(0xFF2A4060).withOpacity(0.9),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: const Color(0xFF1A2840))),
        ],
      ),
    );
  }

  // ─── Log List ─────────────────────────────────────────────────────────────

  Widget _buildLogList() {
    final entries = _filteredEntries;
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_outlined,
                color: const Color(0xFF2A4060).withOpacity(0.4), size: 40),
            const SizedBox(height: 12),
            Text(
              'NO_ENTRIES_FOUND',
              style: TextStyle(
                color: const Color(0xFF2A4060).withOpacity(0.7),
                fontFamily: 'monospace',
                fontSize: 12,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Send or receive files to build history.',
              style: TextStyle(
                color: const Color(0xFF2A4060).withOpacity(0.4),
                fontFamily: 'monospace',
                fontSize: 9,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          Container(height: 1, color: const Color(0xFF111A27)),
      itemBuilder: (_, i) => _buildLogTile(entries[i]),
    );
  }

  Widget _buildLogTile(LogEntry entry) {
    final isAborted = entry.status == LogStatus.aborted;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatusIcon(entry.status),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        entry.name,
                        style: TextStyle(
                          color: isAborted
                              ? const Color(0xFFFF6B6B)
                              : const Color(0xFFB8D4F0),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                          fontFamily: 'monospace',
                          decoration: isAborted
                              ? TextDecoration.underline
                              : TextDecoration.none,
                          decorationColor: const Color(0xFFFF4D4D),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.timestamp,
                      style: TextStyle(
                        color: const Color(0xFF3A5070).withOpacity(0.9),
                        fontSize: 9,
                        fontFamily: 'monospace',
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${entry.dataNodes}  •  ${entry.swapped}',
                  style: TextStyle(
                    color: const Color(0xFF2E4A6A).withOpacity(0.9),
                    fontSize: 9.5,
                    fontFamily: 'monospace',
                    letterSpacing: 0.6,
                  ),
                ),
                if (entry.sourceFingerprint != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoBox(
                    label: 'SOURCE_FINGERPRINT',
                    value: entry.sourceFingerprint!,
                    color: const Color(0xFF00FFC8),
                  ),
                ],
                if (entry.errorLog != null) ...[
                  const SizedBox(height: 6),
                  _buildInfoBox(
                    label: 'ERROR_LOG',
                    value: entry.errorLog!,
                    color: const Color(0xFFFF4D4D),
                  ),
                ],
                const SizedBox(height: 6),
                _buildStatusBadge(entry.status),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(LogStatus status) {
    switch (status) {
      case LogStatus.aborted:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFFFF4D4D).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFFFF4D4D).withOpacity(0.4), width: 1),
          ),
          child: const Icon(Icons.warning_amber_rounded,
              color: Color(0xFFFF4D4D), size: 14),
        );
      case LogStatus.received:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.greenAccent.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.greenAccent.withOpacity(0.35), width: 1),
          ),
          child: const Icon(Icons.download_outlined,
              color: Colors.greenAccent, size: 14),
        );
      case LogStatus.linked:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF00A8FF).withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF00A8FF).withOpacity(0.4), width: 1),
          ),
          child: const Icon(Icons.link, color: Color(0xFF00A8FF), size: 14),
        );
      default: // success / sent
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF00FFC8).withOpacity(0.07),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF00FFC8).withOpacity(0.25), width: 1),
          ),
          child: Icon(Icons.upload_outlined,
              color: const Color(0xFF00FFC8).withOpacity(0.7), size: 14),
        );
    }
  }

  Widget _buildInfoBox({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.5),
              fontSize: 8,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color.withOpacity(0.85),
              fontSize: 9,
              fontFamily: 'monospace',
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(LogStatus status) {
    Color color;
    String label;
    switch (status) {
      case LogStatus.aborted:
        color = const Color(0xFFFF4D4D);
        label = '• ABORTED';
      case LogStatus.received:
        color = Colors.greenAccent;
        label = '• RECEIVED';
      case LogStatus.linked:
        color = const Color(0xFF00A8FF);
        label = '• SYNCING';
      default:
        color = const Color(0xFF00FFC8);
        label = '• SENT';
    }
    return Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: 9,
        fontFamily: 'monospace',
        fontWeight: FontWeight.w700,
        letterSpacing: 1.5,
      ),
    );
  }
}