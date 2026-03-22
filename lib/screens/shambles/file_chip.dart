import 'package:flutter/material.dart';
import 'package:opShare/screens/shambles/transfer_file.dart';

import '../room_intitiation/colors_room.dart';
import 'file_status.dart';

/// Horizontal file card in the staged list
class FileChip extends StatelessWidget {
  final TransferFile file;
  final VoidCallback? onRemove;

  const FileChip({super.key, required this.file, this.onRemove});

  @override
  Widget build(BuildContext context) {
    final isDone = file.status == FileStatus.done;
    final isTransferring = file.status == FileStatus.transferring;

    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isDone ? kCyan.withOpacity(0.6) : kBorderDim),
      ),
      child: Row(children: [
        Icon(file.icon, color: file.iconColor, size: 22),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${file.name}.${file.ext}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Row(children: [
                  Text(file.size,
                      style: TextStyle(
                        fontSize: 8,
                        color: kCyan.withOpacity(0.5),)),
                  if (isDone) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.check_circle_outline,
                        color: kCyan, size: 10),
                  ],
                ]),
                if (isTransferring)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: LinearProgressIndicator(
                      value: file.progress,
                      backgroundColor: kBorderDim,
                      color: kCyan,
                      minHeight: 2,
                    ),
                  ),
              ]),
        ),
        if (onRemove != null)
          GestureDetector(
            onTap: onRemove,
            child:
            const Icon(Icons.close, color: Colors.white24, size: 14),
          ),
      ]),
    );
  }
}
