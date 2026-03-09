import 'package:flutter/material.dart';
import 'package:op_share_flutter/screens/room_intitiation/colors_room.dart';
import 'dart:math';


class RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double ringProgress;

  RadarPainter({required this.sweepAngle, required this.ringProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = min(size.width, size.height) / 2 - 6;

    // BG fill
    canvas.drawCircle(center, maxR, Paint()..color = const Color(0xFF071418));

    // Grid rings
    final ringPaint = Paint()
      ..color = kCyan.withOpacity(0.14)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (int r = 1; r <= 4; r++) {
      canvas.drawCircle(center, maxR * r / 4, ringPaint);
    }

    // Cross hairs
    final crossPaint = Paint()
      ..color = kCyan.withOpacity(0.07)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(center.dx - maxR, center.dy),
        Offset(center.dx + maxR, center.dy), crossPaint);
    canvas.drawLine(Offset(center.dx, center.dy - maxR),
        Offset(center.dx, center.dy + maxR), crossPaint);

    // Sweep sector
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..shader = SweepGradient(
          startAngle: sweepAngle - 1.2,
          endAngle: sweepAngle,
          colors: [Colors.transparent, kCyan.withOpacity(0.3)],
        ).createShader(Rect.fromCircle(center: center, radius: maxR))
        ..style = PaintingStyle.fill,
    );

    // Sweep line
    canvas.drawLine(
      center,
      Offset(center.dx + maxR * cos(sweepAngle),
          center.dy + maxR * sin(sweepAngle)),
      Paint()
        ..color = kCyan.withOpacity(0.85)
        ..strokeWidth = 1.5,
    );

    // Expanding ping ring
    final pulseR = maxR * ringProgress;
    canvas.drawCircle(
      center,
      pulseR,
      Paint()
        ..color = kCyan.withOpacity((1.0 - ringProgress) * 0.4)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );

    // Center dot
    canvas.drawCircle(center, 5,
        Paint()..color = kCyan..style = PaintingStyle.fill);

    // Outer rim
    canvas.drawCircle(
      center,
      maxR,
      Paint()
        ..color = kCyan.withOpacity(0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant RadarPainter old) =>
      old.sweepAngle != sweepAngle || old.ringProgress != ringProgress;
}

