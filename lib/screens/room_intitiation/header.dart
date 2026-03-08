import 'package:flutter/material.dart';
import 'colors_room.dart';

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'ROOM INITIATION',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PREPARE FOR SPATIAL DISPLACEMENT',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 3,
            color: kCyan.withOpacity(0.7),
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
