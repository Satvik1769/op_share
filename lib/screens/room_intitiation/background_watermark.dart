import 'package:flutter/material.dart';
import 'colors_room.dart';


class BackgroundWatermark extends StatelessWidget {
  const BackgroundWatermark();

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Opacity(
          opacity: 0.04,
          child: Text(
            '7',
            style: TextStyle(
              fontSize: 400,
              fontWeight: FontWeight.w900,
              color: kCyan,
              letterSpacing: -20,
            ),
          ),
        ),
      ),
    );
  }
}
