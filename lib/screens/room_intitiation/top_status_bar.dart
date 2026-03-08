// ─────────────────────────────────────────────
// TOP STATUS BAR
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'colors_room.dart';


class StatusText extends StatelessWidget {
  final String text;
  final bool bright;
  const StatusText(this.text, {super.key, this.bright = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 9,
        letterSpacing: 1.2,
        fontFamily: 'monospace',
        color: bright ? kCyan : kCyan.withOpacity(0.5),
        fontWeight: bright ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}



class TopStatusBar extends StatelessWidget {
  const TopStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StatusText('LATENCY: 0MS'),
            StatusText('REGION: SECTOR_7'),
          ]),
          Row(children: [
            const Icon(Icons.radio_button_checked, color: kCyan, size: 16),
            const SizedBox(width: 6),
            StatusText('ROOM', bright: true),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusText('OPE-OPE V.2.4'),
            StatusText('STATUS: STANDBY'),
          ]),
        ],
      ),
    );
  }
}