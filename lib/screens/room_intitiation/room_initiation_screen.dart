import 'dart:math';
import 'package:flutter/material.dart';
import 'central_button.dart';
import 'colors_room.dart';
import 'top_status_bar.dart';
import 'header.dart';
import 'background_watermark.dart';

class RoomInitiationScreen extends StatefulWidget {
  const RoomInitiationScreen({super.key});

  @override
  State<RoomInitiationScreen> createState() => _RoomInitiationScreenState();
}

class _RoomInitiationScreenState extends State<RoomInitiationScreen>
    with TickerProviderStateMixin {
  // Ripple animation controllers
  late final List<AnimationController> _rippleControllers;
  late final List<Animation<double>> _rippleAnimations;


  // Glitch/pulse for status dot
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulseAnim;

  // Scan line sweep
  late final AnimationController _scanCtrl;
  late final Animation<double> _scanAnim;

  bool _isScanning = false;

  @override
  void initState() {
    super.initState();

    // 3 ripple rings with staggered delays
    _rippleControllers = List.generate(3, (i) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 2400),
      );
    });

    _rippleAnimations = _rippleControllers.map((ctrl) {
      return Tween<double>(begin: 0.6, end: 1.4).animate(
        CurvedAnimation(parent: ctrl, curve: Curves.easeOut),
      );
    }).toList();

    // Stagger ripple start
    for (int i = 0; i < _rippleControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 800), () {
        if (mounted) _rippleControllers[i].repeat();
      });
    }




    // Status dot pulse
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseCtrl);

    // Scan sweep
    _scanCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scanAnim = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _scanCtrl, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    for (final c in _rippleControllers) {
      c.dispose();
    }

    _pulseCtrl.dispose();
    _scanCtrl.dispose();
    super.dispose();
  }

  void _onActivateTap() {
    setState(() => _isScanning = true);
    _scanCtrl.forward(from: 0).then((_) {
      if (mounted) setState(() => _isScanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDarkBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Background watermark symbol
            const BackgroundWatermark(),

            Column(
              children: [
                TopStatusBar(),
                const SizedBox(height: 8),
                Header(),
                const Spacer(),
                CentralButton(
                  rippleControllers: _rippleControllers,
                  rippleAnimations: _rippleAnimations,
                  scanAnim: _scanAnim,
                  isScanning: _isScanning,
                  onTap: _onActivateTap,
                ),
                const Spacer(),
                _StatusCards(),
                const SizedBox(height: 16),
                _CommandBar(pulseAnim: _pulseAnim),
                const SizedBox(height: 12),
                _BottomBar(),
                const SizedBox(height: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }
}



// ─────────────────────────────────────────────
// STATUS CARDS
// ─────────────────────────────────────────────
class _StatusCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _StatusCard(label: 'SYSTEM', value: 'STABLE'),
          const SizedBox(width: 8),
          _StatusCard(label: 'PROTOCOL', value: 'OPE-OPE'),
          const SizedBox(width: 8),
          _StatusCard(label: 'ENCRYPT', value: 'HIGH-LVL'),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatusCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorderDim),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                letterSpacing: 1.5,
                color: kCyan.withOpacity(0.55),
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// COMMAND BAR
// ─────────────────────────────────────────────
class _CommandBar extends StatelessWidget {
  final Animation<double> pulseAnim;
  const _CommandBar({required this.pulseAnim});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: kCardBg,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: kBorderDim),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: pulseAnim,
              builder: (_, __) => Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: kCyan.withOpacity(pulseAnim.value),
                  boxShadow: [
                    BoxShadow(
                      color: kCyan.withOpacity(pulseAnim.value * 0.7),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'WAITING FOR USER COMMAND',
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2,
                color: kCyan.withOpacity(0.8),
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// BOTTOM BAR
// ─────────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            StatusText('SECURE_TUNNEL: ACTIVE'),
            StatusText('NODES: 0'),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            StatusText('COORD: 34.0522 N'),
            StatusText('118.2437 W'),
          ]),
        ],
      ),
    );
  }
}