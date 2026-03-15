import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:op_share_flutter/screens/auth_screens/contact_screen/phone_formatter.dart';
import '../../room_intitiation/top_status_bar.dart';
import '../colors.dart';
import '../otp_screen/otp_screen.dart';
import 'corner_bracket_painter.dart';
import 'dashed_circle_painter.dart';


class AuthRequestScreen extends StatefulWidget {
  const AuthRequestScreen({super.key});

  @override
  State<AuthRequestScreen> createState() => _AuthRequestScreenState();
}

class _AuthRequestScreenState extends State<AuthRequestScreen>
    with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  late AnimationController _ringPulse;
  late AnimationController _ringRotate;
  late AnimationController _scanLine;
  late AnimationController _dotController;
  late AnimationController _btnGlow;

  late Animation<double> _ringScale;
  late Animation<double> _scanPos;
  late Animation<double> _btnGlowAnim;

  @override
  void initState() {
    super.initState();

    _ringPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _ringRotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _btnGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _ringScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ringPulse, curve: Curves.easeInOut),
    );

    _scanPos = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanLine, curve: Curves.easeInOut),
    );

    _btnGlowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _btnGlow, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ringPulse.dispose();
    _ringRotate.dispose();
    _scanLine.dispose();
    _dotController.dispose();
    _btnGlow.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _requestToken() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).push(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, __, ___) =>
          VerifyOtpScreen(phoneNumber: _phoneController.text),
      transitionsBuilder: (_, animation, __, child) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
                  begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(
                  CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildTopBar(),
                  _buildScannerWidget(),
                  _buildTitle(),
                  const SizedBox(height: 28),
                  _buildForm(),
                  const Spacer(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Top Bar ──────────────────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/logo.png", width: 16, height: 16),
          const SizedBox(width: 6),
          StatusText('ROOM', letterSpacing: 3, fontSize: 14, bright: true),
        ],
      ),
    );
  }

  // ─── Scanner Widget ───────────────────────────────────────────────────────

  Widget _buildScannerWidget() {
    return SizedBox(
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Radial glow background
          AnimatedBuilder(
            animation: _ringPulse,
            builder: (_, __) => Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cyan.withOpacity(0.06 * _ringScale.value),
                    cyan.withOpacity(0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),

          // Outer dashed rotating ring
          AnimatedBuilder(
            animation: _ringRotate,
            builder: (_, __) => Transform.rotate(
              angle: _ringRotate.value * 2 * pi,
              child: CustomPaint(
                size: const Size(200, 200),
                painter: DashedCirclePainter(
                  color: cyan.withOpacity(0.25),
                  dashCount: 36,
                  strokeWidth: 1.0,
                ),
              ),
            ),
          ),

          // Inner ring (solid)
          AnimatedBuilder(
            animation: _ringScale,
            builder: (_, __) => Transform.scale(
              scale: _ringScale.value,
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: cyan.withOpacity(0.55),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cyan.withOpacity(0.2 * _ringScale.value),
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
              painter: CornerBracketPainter(color: cyan.withOpacity(0.9)),
            ),
          ),

          // Fingerprint icon + scan line
          ClipOval(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.fingerprint,
                    color: cyan.withOpacity(0.85),
                    size: 88,
                  ),
                  // Scan line
                  AnimatedBuilder(
                    animation: _scanPos,
                    builder: (_, __) => Positioned(
                      top: 160 * _scanPos.value,
                      left: 16,
                      right: 16,
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              cyan.withOpacity(0.9),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: cyan.withOpacity(0.5),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Title Block ──────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      children: [
        const SizedBox(height: 22),
        // Big heading
         Text(
          'Login or Signup',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: Color(0xFFE8F4FF),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Enter credentials to establish ROOM boundary',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF3A5878).withOpacity(0.9),
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ─── Form ─────────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CONTACT NUMBER',
            style: TextStyle(
              color: cyan.withOpacity(0.45),
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          // Phone input
          Container(
            decoration: BoxDecoration(
              color: card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border, width: 1),
            ),
            child: Row(
              children: [
                // Dialpad icon + country code
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      right: BorderSide(
                          color: border.withOpacity(0.8), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.dialpad,
                          color: cyan.withOpacity(0.5), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '+91',
                        style: TextStyle(
                          color: cyan.withOpacity(0.7),
                          fontSize: 13,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Text field
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      PhoneNumberFormatter(),
                    ],
                    style: const TextStyle(
                      color: Color(0xFFB0CDE8),
                      fontSize: 14,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                    ),
                    cursorColor: cyan,
                    decoration: InputDecoration(
                      hintText: '••• ••• ••••',
                      hintStyle: TextStyle(
                        color: const Color(0xFF243650).withOpacity(0.9),
                        fontSize: 14,
                        fontFamily: 'monospace',
                        letterSpacing: 3,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CTA Button
          AnimatedBuilder(
            animation: _btnGlowAnim,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: cyan.withOpacity(0.35 * _btnGlowAnim.value),
                    blurRadius: 20,
                    spreadRadius: 1,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: child,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestToken,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  disabledBackgroundColor: cyan.withOpacity(0.6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: bg.withOpacity(0.8),
                  ),
                )
                    : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Get OTP',
                      style: TextStyle(
                        color: Color(0xFF040810),
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      Icons.north_east_rounded,
                      color: const Color(0xFF040810).withOpacity(0.7),
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

