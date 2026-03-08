import 'dart:math';

import 'package:flutter/material.dart';
import 'colors_room.dart';
class CentralButton extends StatelessWidget {
  final List<AnimationController> rippleControllers;
  final List<Animation<double>> rippleAnimations;
  final Animation<double> rotationAnim;
  final Animation<double> scanAnim;
  final bool isScanning;
  final VoidCallback onTap;

  const CentralButton({
    required this.rippleControllers,
    required this.rippleAnimations,
    required this.rotationAnim,
    required this.scanAnim,
    required this.isScanning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double outerSize = 260;
    const double innerSize = 160;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripple rings
            ...List.generate(3, (i) {
              return AnimatedBuilder(
                animation: rippleAnimations[i],
                builder: (_, __) {
                  final scale = rippleAnimations[i].value;
                  final opacity =
                      (1.0 - (scale - 0.6) / 0.8).clamp(0.0, 1.0) * 0.5;
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: innerSize,
                      height: innerSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kCyan.withOpacity(opacity),
                          width: 1.5,
                        ),
                      ),
                    ),
                  );
                },
              );
            }),

            // Outer rotating dashed ring
            AnimatedBuilder(
              animation: rotationAnim,
              builder: (_, __) {
                return Transform.rotate(
                  angle: rotationAnim.value,
                  child: CustomPaint(
                    size: const Size(outerSize - 10, outerSize - 10),
                    painter: _DashedCirclePainter(),
                  ),
                );
              },
            ),

            // Scan sweep overlay
            if (isScanning)
              AnimatedBuilder(
                animation: scanAnim,
                builder: (_, __) {
                  return CustomPaint(
                    size: const Size(innerSize + 40, innerSize + 40),
                    painter: _ScanSweepPainter(scanAnim.value),
                  );
                },
              ),

            // Inner glowing circle
            Container(
              width: innerSize,
              height: innerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kDarkBg,
                border: Border.all(color: kCyan, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: kCyan.withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: kCyan.withOpacity(0.15),
                    blurRadius: 50,
                    spreadRadius: 12,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radio,
                    size: 40,
                    color: kCyan,
                    shadows: [
                      Shadow(color: kCyan.withOpacity(0.8), blurRadius: 16),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ACTIVATE ROOM',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: kCyan,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TAP TO SCAN',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      color: kCyan.withOpacity(0.6),
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),

            // Bottom dash indicator
            Positioned(
              bottom: 12,
              child: Container(
                width: 30,
                height: 3,
                decoration: BoxDecoration(
                  color: kCyan.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// DASHED CIRCLE PAINTER
// ─────────────────────────────────────────────
class _DashedCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kCyan.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const dashCount = 40;
    const dashLength = 0.08;
    const gapLength = 0.08;

    double angle = 0;
    const step = (dashLength + gapLength) * pi * 2 / (dashCount * (dashLength + gapLength));

    for (int i = 0; i < dashCount; i++) {
      final startAngle = angle;
      final endAngle = angle + dashLength * pi * 2 / dashCount;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        endAngle - startAngle,
        false,
        paint,
      );
      angle += (dashLength + gapLength) * pi * 2 / dashCount;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────
// SCAN SWEEP PAINTER
// ─────────────────────────────────────────────
class _ScanSweepPainter extends CustomPainter {
  final double angle;
  _ScanSweepPainter(this.angle);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: angle - 0.8,
        endAngle: angle,
        colors: [
          Colors.transparent,
          kCyan.withOpacity(0.5),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle - 0.8,
      0.8,
      true,
      sweepPaint,
    );

    // Leading edge line
    final linePaint = Paint()
      ..color = kCyan.withOpacity(0.9)
      ..strokeWidth = 2;
    canvas.drawLine(
      center,
      Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      ),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanSweepPainter old) => old.angle != angle;
}
