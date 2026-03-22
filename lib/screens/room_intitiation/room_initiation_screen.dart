import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:opShare/main.dart';
import 'package:opShare/screens/auth_screens/colors.dart' as auth_colors;
import 'package:opShare/services/invite_service.dart';
import 'central_button.dart';
import 'colors_room.dart';
import 'top_status_bar.dart';
import 'header.dart';
import 'background_watermark.dart';
import '../scanning_room/scanning_room_screen.dart';

String baseUrl = appConfig.baseUrl;

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

  final TextEditingController _roomCodeController = TextEditingController();
  bool _isJoining = false;

  late final InviteService _inviteService;

  @override
  void initState() {
    super.initState();

    // Start the global invite listener
    final wsUrl = appConfig.baseUrl
        .replaceFirst(RegExp(r'^https'), 'wss')
        .replaceFirst(RegExp(r'^http'), 'ws');
    _inviteService = InviteService(
      signalingUrl: '$wsUrl/ws-native',
      authToken: authToken,
    );
    _inviteService.onInviteReceived = (roomCode, inviterName) {
      if (!mounted) return;
      _showInviteDialog(roomCode, inviterName);
    };
    _inviteService.connect();

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
    _roomCodeController.dispose();
    _inviteService.dispose();
    super.dispose();
  }

  void _showInviteDialog(String roomCode, String inviterName) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: kDarkBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: kCyan.withOpacity(0.3)),
        ),
        title: Text(
          'ROOM INVITE',
          style: TextStyle(
            color: kCyan,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$inviterName has invited you to join a room.',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('CODE: ',
                    style: TextStyle(
                        color: kCyan.withOpacity(0.6),
                        fontSize: 11,
                        letterSpacing: 1)),
                Text(
                  roomCode,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('DECLINE',
                style: TextStyle(
                    color: Colors.redAccent.withOpacity(0.8),
                    fontSize: 11,
                    letterSpacing: 2)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              try {
                final response = await http.post(
                  Uri.parse('$baseUrl/rooms/$roomCode/join'),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $authToken',
                  },
                );
                if (!mounted) return;
                if (response.statusCode == 200) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RoomActiveScreen(
                        roomCode: roomCode,
                        isOwner: false,
                      ),
                    ),
                  );
                } else {
                  auth_colors.showAppSnackBarFromMessenger(
                    ScaffoldMessenger.of(context),
                    'Could not join room (${response.statusCode})',
                    isError: true,
                  );
                }
              } catch (e) {
                if (!mounted) return;
                auth_colors.showAppSnackBarFromMessenger(
                  ScaffoldMessenger.of(context),
                  'Network error joining room',
                  isError: true,
                );
              }
            },
            child: Text('JOIN',
                style: TextStyle(
                    color: kCyan,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2)),
          ),
        ],
      ),
    );
  }


  Future<void> joinRoom(BuildContext context) async {
    final roomCode = _roomCodeController.text.trim();
    if(roomCode.isEmpty) return;
    final messenger = ScaffoldMessenger.of(context);
    final response = await http.post(
      Uri.parse('$baseUrl/rooms/$roomCode/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print(data);
      setState(() => _isJoining = true);
      if (!mounted) return;
      setState(() => _isJoining = false);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoomActiveScreen(roomCode: roomCode, isOwner: false),
        ),
      );
    } else {
      auth_colors.showAppSnackBarFromMessenger(messenger, 'Something went wrong, cannot join room.', isError: true);
    }
  }


  void _onJoinRoom() async {
    joinRoom(context);
  }

  Future<void> _createRoom() async {
    final messenger = ScaffoldMessenger.of(context);
    final response = await http.post(
      Uri.parse('$baseUrl/rooms'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print(data);
      setState(() => _isJoining = true);
      if (!mounted) return;
      setState(() => _isJoining = false);
      final String roomId = data["roomId"].toString();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => RoomActiveScreen(roomCode: roomId, isOwner: true),
        ),
      );
    } else {
      auth_colors.showAppSnackBarFromMessenger(messenger, 'Something went wrong, cannot create room.', isError: true);
    }
  }

  void _onActivateTap() async {
    setState(() => _isScanning = true);
    await _scanCtrl.forward(from: 0);
    if (!mounted) return;
    await _createRoom();
    if (!mounted) return;
    setState(() => _isScanning = false);
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
                _JoinRoomSection(
                  controller: _roomCodeController,
                  isJoining: _isJoining,
                  onJoin: _onJoinRoom,
                ),
                const SizedBox(height: 16),
                _StatusCards(),
                const SizedBox(height: 16),
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
          color: kCardBg.withOpacity(0.5),
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

// ─────────────────────────────────────────────
// JOIN ROOM SECTION
// ─────────────────────────────────────────────
class _JoinRoomSection extends StatelessWidget {
  final TextEditingController controller;
  final bool isJoining;
  final VoidCallback onJoin;

  const _JoinRoomSection({
    required this.controller,
    required this.isJoining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 1, color: kCyan.withOpacity(0.3)),
              const SizedBox(width: 8),
              Text(
                'JOIN EXISTING ROOM',
                style: TextStyle(
                  fontSize: 8,
                  letterSpacing: 2.5,
                  color: kCyan.withOpacity(0.45),
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 1, color: kCyan.withOpacity(0.3))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorderDim),
                  ),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.tag_rounded,
                          size: 15,
                          color: kCyan.withOpacity(0.5),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: controller,
                          keyboardType: TextInputType.text,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9a-z\-]')),
                            LengthLimitingTextInputFormatter(12),
                          ],
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3,
                          ),
                          cursorColor: kCyan,
                          decoration: InputDecoration(
                            hintText: 'ROOM-CODE',
                            hintStyle: TextStyle(
                              color: kCyan.withOpacity(0.18),
                              fontSize: 13,
                              letterSpacing: 3,
                              fontFamily: 'monospace',
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: isJoining ? null : onJoin,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 48,
                  width: 80,
                  decoration: BoxDecoration(
                    color: isJoining ? kCyan.withOpacity(0.15) : kCardBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isJoining ? kCyan.withOpacity(0.6) : kCyan.withOpacity(0.35),
                    ),
                    boxShadow: isJoining
                        ? [
                            BoxShadow(
                              color: kCyan.withOpacity(0.2),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: isJoining
                      ? Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: kCyan.withOpacity(0.8),
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            'JOIN',
                            style: GoogleFonts.spaceGrotesk(
                              color: kCyan,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}