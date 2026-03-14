class ActiveTransfer {
  final String filename;
  final String speed;
  final String eta;
  final double progress;
  final String statusLabel;

  const ActiveTransfer({
    required this.filename,
    required this.speed,
    required this.eta,
    required this.progress,
    required this.statusLabel,
  });
}
