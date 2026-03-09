import 'package:flutter/material.dart';
import 'radar_node.dart';
import 'dart:math';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';


class NodeAvatar extends StatelessWidget {
  final RadarNode node;
  final Animation<double> animation;

  const NodeAvatar({super.key, required this.node, required this.animation});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final maxR = min(constraints.maxWidth, constraints.maxHeight) / 2 - 6;
      final center =
      Offset(constraints.maxWidth / 2, constraints.maxHeight / 2);
      final pos = node.position(maxR);
      final size = node.isOwner ? 52.0 : 44.0;

      return Positioned(
        left: center.dx + pos.dx - size / 2,
        top: center.dy + pos.dy - size / 2,
        child: ScaleTransition(
          scale: animation,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: node.isOwner ? kDarkBg : const Color(0xFF0E2830),
                border: Border.all(
                    color: node.isOwner ? kCyan : kCyan.withOpacity(0.45),
                    width: node.isOwner ? 2.5 : 1.5),
                boxShadow: node.isOwner
                    ? [
                  BoxShadow(
                      color: kCyan.withOpacity(0.5),
                      blurRadius: 14,
                      spreadRadius: 2)
                ]
                    : null,
              ),
              child: Icon(
                node.isOwner ? Icons.person : Icons.computer,
                color:
                node.isOwner ? kCyan : kCyan.withOpacity(0.55),
                size: node.isOwner ? 28 : 22,
              ),
            ),
            const SizedBox(height: 3),
            Text(node.label,
                style: TextStyle(
                    fontSize: 7,
                    letterSpacing: 0.8,
                    color: node.isOwner
                        ? Colors.white
                        : kCyan.withOpacity(0.65),
                    fontFamily: 'monospace',
                    fontWeight: node.isOwner
                        ? FontWeight.bold
                        : FontWeight.normal)),
          ]),
        ),
      );
    });
  }
}
