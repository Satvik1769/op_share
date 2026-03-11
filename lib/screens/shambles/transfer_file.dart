import 'package:flutter/material.dart';

import 'file_status.dart';

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
