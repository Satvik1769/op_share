import 'dart:math';

import 'package:flutter/material.dart';

import '../room_intitiation/colors_room.dart';

/// Animated orbit rings around the central Shambles circle
class OrbitRingPainter extends CustomPainter {
  final double angle;
  final bool active;

  OrbitRingPainter(this.angle, this.active);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Static dim rings
    canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = kCyan.withOpacity(0.15)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);

    canvas.drawCircle(
        center,
        radius * 0.72,
        Paint()
          ..color = kCyan.withOpacity(0.10)
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke);

    if (!active) return;

    // Outer spinning arc
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        pi * 0.8,
        false,
        Paint()
          ..color = kCyan.withOpacity(0.7)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);

    // Inner counter-spinning arc
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius * 0.72),
        -angle * 1.3,
        pi * 0.4,
        false,
        Paint()
          ..color = kCyan.withOpacity(0.4)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant OrbitRingPainter old) =>
      old.angle != angle || old.active != active;
}
