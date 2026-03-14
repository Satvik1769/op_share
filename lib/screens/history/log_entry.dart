import 'log_status.dart';

class LogEntry {
  final String id;
  final String name;
  final String dataNodes;
  final String swapped;
  final String timestamp;
  final LogStatus status;
  final String? sourceFingerprint;
  final String? errorLog;
  final String? stabilityLevel;

  const LogEntry({
    required this.id,
    required this.name,
    required this.dataNodes,
    required this.swapped,
    required this.timestamp,
    required this.status,
    this.sourceFingerprint,
    this.errorLog,
    this.stabilityLevel,
  });
}