import 'dart:math';

import 'package:flutter/material.dart';

class RadarNode {
  final String label;
  final double angle;
  final double dist;
  final bool isOwner;
  final String peerName;
  final String connectionType;
  final String distance;
  final String status;

  const RadarNode({
    required this.label,
    required this.angle,
    required this.dist,
    required this.isOwner,
    required this.peerName,
    required this.connectionType,
    required this.distance,
    required this.status,
  });

  Offset position(double radarRadius) =>
      Offset(cos(angle) * dist * radarRadius, sin(angle) * dist * radarRadius);
}