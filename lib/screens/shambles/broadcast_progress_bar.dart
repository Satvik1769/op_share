import 'package:flutter/material.dart';

import '../room_intitiation/colors_room.dart';

/// Live broadcast progress indicator
class BroadcastProgressBar extends StatelessWidget {
  final double percent;       // 0–100
  final int peersInRange;
  final double speedMbps;
  final int etaSeconds;       // remaining seconds, 0 when done

  const BroadcastProgressBar({
    super.key,
    required this.percent,
    required this.peersInRange,
    required this.speedMbps,
    required this.etaSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final pct = percent.clamp(0.0, 100.0);
    final done = pct >= 100;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderDim),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done ? Colors.greenAccent : kCyan,
                  boxShadow: [
                    BoxShadow(
                        color: (done ? Colors.greenAccent : kCyan)
                            .withOpacity(0.7),
                        blurRadius: 6)
                  ]),
            ),
            const SizedBox(width: 8),
            Text(done ? 'TRANSFER COMPLETE' : 'BROADCASTING',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: done ? Colors.greenAccent : kCyan,
                    letterSpacing: 2)),
          ]),
          Text('${pct.toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: Colors.white)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct / 100.0,
            backgroundColor: kBorderDim,
            color: done ? Colors.greenAccent : kCyan,
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('$peersInRange peers in range',
              style: TextStyle(
                fontSize: 9,
                color: kCyan.withOpacity(0.55),)),
          Text('${speedMbps.toStringAsFixed(0)} Mb/s',
              style: TextStyle(
                fontSize: 9,
                color: kCyan.withOpacity(0.55),)),
          Text(done ? 'ETA: --' : 'ETA: ${etaSeconds}s',
              style: TextStyle(
                fontSize: 9,
                color: kCyan.withOpacity(0.55),)),
        ]),
      ]),
    );
  }
}
