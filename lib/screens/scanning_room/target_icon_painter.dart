import 'package:flutter/material.dart';
import 'package:opShare/screens/room_intitiation/colors_room.dart';

class TargetIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = kCyan
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, size.width / 2, p);
    canvas.drawCircle(c, size.width / 3.5, p);
    canvas.drawCircle(c, 2,
        Paint()..color = kCyan..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_) => false;
}