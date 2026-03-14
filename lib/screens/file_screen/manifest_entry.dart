import 'package:op_share_flutter/screens/file_screen/transfer_status.dart';

class ManifestEntry {
  final String filename;
  final String size;
  final String target;
  final String room;
  final TransferStatus status;

  const ManifestEntry({
    required this.filename,
    required this.size,
    required this.target,
    required this.room,
    required this.status,
  });
}
