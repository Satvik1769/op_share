import 'package:flutter/foundation.dart';
import '../screens/shambles/transfer_file.dart';
import '../screens/shambles/file_status.dart';
import '../screens/file_screen/manifest_entry.dart';
import '../screens/file_screen/transfer_status.dart';

/// Shared singleton that connects ShamblesTrasferScreen → FileScreen.
/// Shambles writes to it; FileScreen reads from it.
class StagingStore extends ChangeNotifier {
  static final StagingStore instance = StagingStore._();
  StagingStore._();

  /// Files currently being broadcast (shown as active in FileScreen).
  final List<TransferFile> activeFiles = [];

  /// Completed transfer history (shown in manifest in FileScreen).
  final List<ManifestEntry> transferHistory = [];

  void setActiveFiles(List<TransferFile> files) {
    activeFiles
      ..clear()
      ..addAll(files);
    notifyListeners();
  }

  /// Called during broadcast to update per-file progress for FileScreen.
  void updateProgress(double progress) {
    for (final f in activeFiles) {
      f.progress = progress;
    }
    notifyListeners();
  }

  void markAllDone(String roomCode, List<String> peerLabels) {
    final target = peerLabels.isEmpty ? 'All peers' : peerLabels.join(', ');
    for (final f in activeFiles) {
      f.progress = 1.0;
      f.status = FileStatus.done;
      transferHistory.insert(
        0,
        ManifestEntry(
          filename: '${f.name}.${f.ext}',
          size: f.size,
          target: target,
          room: roomCode,
          status: TransferStatus.success,
        ),
      );
    }
    activeFiles.clear();
    notifyListeners();
  }

  void clearActiveFiles() {
    activeFiles.clear();
    notifyListeners();
  }
}
