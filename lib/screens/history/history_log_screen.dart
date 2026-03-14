import 'package:flutter/material.dart';
import 'log_entry.dart';
import 'log_status.dart';
import '../shambles/shambles_transfer_screen.dart';


// ─── Screen ─────────────────────────────────────────────────────────────────

class HistoryLogScreen extends StatefulWidget {
  const HistoryLogScreen({super.key});

  @override
  State<HistoryLogScreen> createState() => _HistoryLogScreenState();
}

class _HistoryLogScreenState extends State<HistoryLogScreen>
    with TickerProviderStateMixin {
  int _selectedFilter = 0;
  int _selectedNav = 1;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _filters = ['ALL_EVENTS', 'LINKED', 'ABORTED'];

  final List<LogEntry> _entries = const [
    LogEntry(
      id: '1',
      name: 'SHAMBLES: HEART_PIRATE_04',
      dataNodes: '3 DATA_NODES',
      swapped: '1.2GB SWAPPED',
      timestamp: '14:28 UTC',
      status: LogStatus.success,
      sourceFingerprint: '0x7F4L_8821_SUB_ROUTINE_ALPHA',
    ),
    LogEntry(
      id: '2',
      name: 'SHAMBLES: EUSTASS_KID_88',
      dataNodes: '1 DATA_NODE',
      swapped: '450MB SWAPPED',
      timestamp: '13:10 UTC',
      status: LogStatus.success,
    ),
    LogEntry(
      id: '3',
      name: 'SHAMBLES: BLACKBEARD_ADM',
      dataNodes: 'CONNECTION_LOST',
      swapped: 'ROOM_STABILITY: LOW',
      timestamp: '08:31 UTC',
      status: LogStatus.aborted,
      errorLog: 'PROTOCOL_MISMATCH: Peer refused spatial swap.',
    ),
    LogEntry(
      id: '4',
      name: 'SHAMBLES: STRAW_HAT_L',
      dataNodes: '12 DATA_NODES',
      swapped: '6.6GB SWAPPED',
      timestamp: 'Yesterday 21:16',
      status: LogStatus.success,
      stabilityLevel: 'STABILITY_LEVEL: LOW',
    ),
  ];

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

  List<LogEntry> get _filteredEntries {
    switch (_selectedFilter) {
      case 1:
        return _entries
            .where((e) => e.status == LogStatus.linked)
            .toList();
      case 2:
        return _entries
            .where((e) => e.status == LogStatus.aborted)
            .toList();
      default:
        return _entries;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C11),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildActiveCard(),
            _buildFilterRow(),
            _buildSequenceLabel(),
            Expanded(child: _buildLogList()),
            _buildBottomNav(),
          ],
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
                'HISTORY_LOG',
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
          const Icon(Icons.crop_free, color: Color(0xFF4A5568), size: 20),
        ],
      ),
    );
  }

  // ─── Active Card ──────────────────────────────────────────────────────────

  Widget _buildActiveCard() {
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
              const Text(
                'ACTIVE_LINK_STABLE',
                style: TextStyle(
                  color: Color(0xFF00FFC8),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
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
                    const Text(
                      'LATEST_SHAMBLES',
                      style: TextStyle(
                        color: Color(0xFFD4E8FF),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: R00M_A1_77XP',
                      style: TextStyle(
                        color: const Color(0xFF4A6080).withOpacity(0.9),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildViewManifestButton(),
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

  Widget _buildViewManifestButton() {
    return GestureDetector(
      onTap: () {},
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
              child: const Text(
                '+2',
                style: TextStyle(
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
          // Vertical light beams
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
      padding: const EdgeInsets.symmetric(horizontal: 14),
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
    );
  }

  // ─── Sequence Label ───────────────────────────────────────────────────────

  Widget _buildSequenceLabel() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            'TEMPORAL_SEQUENCE_LOGS',
            style: TextStyle(
              color: const Color(0xFF2A4060).withOpacity(0.9),
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              height: 1,
              color: const Color(0xFF1A2840),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Log List ─────────────────────────────────────────────────────────────

  Widget _buildLogList() {
    final entries = _filteredEntries;
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'NO_ENTRIES_FOUND',
          style: TextStyle(
            color: const Color(0xFF2A4060).withOpacity(0.7),
            fontFamily: 'monospace',
            fontSize: 12,
            letterSpacing: 2,
          ),
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
                  '${entry.dataNodes} • ${entry.swapped}',
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
                if (entry.stabilityLevel != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    entry.stabilityLevel!,
                    style: TextStyle(
                      color: const Color(0xFF2E4A6A).withOpacity(0.7),
                      fontSize: 9,
                      fontFamily: 'monospace',
                      letterSpacing: 0.8,
                    ),
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
      default:
        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF00FFC8).withOpacity(0.07),
            shape: BoxShape.circle,
            border: Border.all(
                color: const Color(0xFF00FFC8).withOpacity(0.25), width: 1),
          ),
          child: Icon(Icons.swap_horiz,
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
        break;
      case LogStatus.linked:
        color = const Color(0xFF00A8FF);
        label = '• LINKED';
        break;
      default:
        color = const Color(0xFF00FFC8);
        label = '• SUCCESS';
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

  // ─── Bottom Nav ───────────────────────────────────────────────────────────

  Widget _buildBottomNav() {
    const items = [
      {'icon': Icons.swap_horiz_rounded, 'label': 'TRANSFER'},
      {'icon': Icons.access_time_rounded, 'label': 'LOG'},
    ];

    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF111A27), width: 1)),
        color: Color(0xFF080C11),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = _selectedNav == i;
          final item = items[i];
          return GestureDetector(
            onTap: () {
                setState(() => _selectedNav = i);
                if (i == 0) {
                  Navigator.of(context).push(PageRouteBuilder(
                    transitionDuration: const Duration(milliseconds: 400),
                    pageBuilder: (_, __, ___) =>
                        const ShamblesTransferScreen(peers: []),
                    transitionsBuilder: (_, animation, __, child) =>
                        FadeTransition(opacity: animation, child: child),
                  ));
                }
              },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFF00FFC8).withOpacity(0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: active
                        ? const Color(0xFF00FFC8)
                        : const Color(0xFF2A3F58),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: active
                        ? const Color(0xFF00FFC8)
                        : const Color(0xFF2A3F58),
                    fontSize: 8,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}