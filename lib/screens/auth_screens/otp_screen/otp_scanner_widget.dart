import 'dart:math';
import 'package:flutter/material.dart';
import '../colors.dart';
import '../contact_screen/corner_bracket_painter.dart';
import '../contact_screen/dashed_circle_painter.dart';

class OtpScannerWidget extends StatelessWidget {
  final Animation<double> ringPulse;
  final Animation<double> ringRotate;
  final Animation<double> ringScale;
  final Animation<double> scanPos;
  final Animation<double> checkScale;
  final bool isVerified;

  const OtpScannerWidget({
    super.key,
    required this.ringPulse,
    required this.ringRotate,
    required this.ringScale,
    required this.scanPos,
    required this.checkScale,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow
          AnimatedBuilder(
            animation: ringPulse,
            builder: (_, __) => Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cyan.withValues(alpha: 0.06 * ringScale.value),
                    cyan.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Rotating dashed ring
          AnimatedBuilder(
            animation: ringRotate,
            builder: (_, __) => Transform.rotate(
              angle: ringRotate.value * 2 * pi,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: DashedCirclePainter(
                  color: cyan.withValues(alpha: 0.25),
                  dashCount: 36,
                  strokeWidth: 1.0,
                ),
              ),
            ),
          ),

          // Inner pulsing ring
          AnimatedBuilder(
            animation: ringScale,
            builder: (_, __) => Transform.scale(
              scale: ringScale.value,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cyan.withValues(alpha: 0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withValues(alpha: 0.2 * ringScale.value),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Corner brackets
          SizedBox(
            width: 170,
            height: 170,
            child: CustomPaint(
              painter: CornerBracketPainter(color: cyan.withValues(alpha: 0.9)),
            ),
          ),

          // Center icon
          ClipOval(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isVerified)
                    ScaleTransition(
                      scale: checkScale,
                      child: Icon(Icons.verified_rounded, color: cyan, size: 72),
                    )
                  else ...[
                    Icon(
                      Icons.lock_outline_rounded,
                      color: cyan.withValues(alpha: 0.85),
                      size: 72,
                    ),
                    AnimatedBuilder(
                      animation: scanPos,
                      builder: (_, __) => Positioned(
                        top: 160 * scanPos.value,
                        left: 16,
                        right: 16,
                        child: Container(
                          height: 1.5,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                cyan.withValues(alpha: 0.9),
                                Colors.transparent,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: cyan.withValues(alpha: 0.5),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}