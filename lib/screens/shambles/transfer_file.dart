import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'file_status.dart';

class TransferFile {
  final String name;
  final String ext;
  final String size;
  final IconData icon;
  final Color iconColor;

  /// Absolute path on device (null for legacy/mock entries).
  final String? path;

  /// Raw bytes — populated when file is picked with withData: true.
  final Uint8List? bytes;

  double progress; // 0.0 – 1.0
  FileStatus status;

  TransferFile({
    required this.name,
    required this.ext,
    required this.size,
    required this.icon,
    required this.iconColor,
    this.path,
    this.bytes,
    this.progress = 0.0,
    this.status = FileStatus.queued,
  });
}
