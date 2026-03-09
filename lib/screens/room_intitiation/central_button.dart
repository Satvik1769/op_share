import 'dart:math';

import 'package:flutter/material.dart';
import 'colors_room.dart';
import 'package:google_fonts/google_fonts.dart';
class CentralButton extends StatelessWidget {
  final List<AnimationController> rippleControllers;
  final List<Animation<double>> rippleAnimations;

  final Animation<double> scanAnim;
  final bool isScanning;
  final VoidCallback onTap;

  const CentralButton({
    required this.rippleControllers,
    required this.rippleAnimations,
    required this.scanAnim,
    required this.isScanning,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const double outerSize = 500;
    const double innerSize = 300;

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
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
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
                      Text(
                        'ACTIVATE ROOM',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
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
                  Positioned(
                    bottom: 40,
                    child: Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: kCyan.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom dash indicator

          ],
        ),
      ),
    );
  }
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
