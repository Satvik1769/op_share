import 'package:flutter/material.dart';
import 'radar_node.dart';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';


class PeerListTile extends StatelessWidget {
  final RadarNode node;
  const PeerListTile({super.key, required this.node});

  @override
  Widget build(BuildContext context) {
    final isReady = node.status == 'READY';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorderDim),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isReady
                ? kCyan.withOpacity(0.14)
                : Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: isReady ? kCyan.withOpacity(0.4) : kBorderDim),
          ),
          child: Icon(
              node.isOwner ? Icons.phone_android : Icons.laptop_mac,
              color: isReady ? kCyan : Colors.white30,
              size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(node.peerName,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Text('${node.connectionType} • ${node.distance}',
                    style: TextStyle(
                        fontSize: 10,
                        color: kCyan.withOpacity(0.5),
                        fontFamily: 'monospace')),
              ]),
        ),
        if (isReady) ...[
          const Icon(Icons.signal_cellular_alt, color: kCyan, size: 18),
          const SizedBox(width: 4),
          const Text('READY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: kCyan,
                  letterSpacing: 1)),
        ] else
          Text('STANDBY',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white30,
                  letterSpacing: 1)),
      ]),
    );
  }
}
