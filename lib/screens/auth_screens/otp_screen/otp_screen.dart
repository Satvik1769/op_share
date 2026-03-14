import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../room_intitiation/top_status_bar.dart';
import '../../room_intitiation/room_initiation_screen.dart';
import '../colors.dart';
import '../../auth_screens/contact_screen/corner_bracket_painter.dart';
import '../../auth_screens/contact_screen/dashed_circle_painter.dart';
import 'dart:math';


class VerifyOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const VerifyOtpScreen({super.key, required this.phoneNumber});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen>
    with TickerProviderStateMixin {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _isVerified = false;
  int _resendSeconds = 30;

  late AnimationController _ringRotate;
  late AnimationController _ringPulse;
  late AnimationController _scanLine;
  late AnimationController _btnGlow;
  late AnimationController _checkAnim;

  late Animation<double> _ringScale;
  late Animation<double> _scanPos;
  late Animation<double> _btnGlowAnim;
  late Animation<double> _checkScale;

  @override
  void initState() {
    super.initState();

    _ringRotate = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _ringPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scanLine = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _btnGlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _checkAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _ringScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _ringPulse, curve: Curves.easeInOut),
    );

    _scanPos = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanLine, curve: Curves.easeInOut),
    );

    _btnGlowAnim = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _btnGlow, curve: Curves.easeInOut),
    );

    _checkScale = CurvedAnimation(parent: _checkAnim, curve: Curves.elasticOut);

    _startResendTimer();
  }

  void _startResendTimer() async {
    for (int i = 30; i >= 0; i--) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() => _resendSeconds = i);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _ringRotate.dispose();
    _ringPulse.dispose();
    _scanLine.dispose();
    _btnGlow.dispose();
    _checkAnim.dispose();
    super.dispose();
  }

  String get _otpValue => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.length == 1 && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    setState(() {});
  }

  void _onKeyEvent(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _focusNodes[index - 1].requestFocus();
      _controllers[index - 1].clear();
      setState(() {});
    }
  }

  void _verifyOtp() async {
    if (_otpValue.length < 6) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isVerified = true;
    });
    await _checkAnim.forward();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const RoomInitiationScreen(),
        transitionsBuilder: (_, animation, __, child) => FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      (_) => false,
    );
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
                  const SizedBox(height: 32),
                  _buildOtpForm(),
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
          // Radial glow
          AnimatedBuilder(
            animation: _ringPulse,
            builder: (_, __) => Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cyan.withValues(alpha: 0.06 * _ringScale.value),
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
            animation: _ringRotate,
            builder: (_, __) => Transform.rotate(
              angle: _ringRotate.value * 2 * pi,
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
            animation: _ringScale,
            builder: (_, __) => Transform.scale(
              scale: _ringScale.value,
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
                      color: cyan.withValues(alpha: 0.2 * _ringScale.value),
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

          // Center icon — check when verified, shield + scan line otherwise
          ClipOval(
            child: SizedBox(
              width: 160,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_isVerified)
                    ScaleTransition(
                      scale: _checkScale,
                      child: Icon(Icons.verified_rounded,
                          color: cyan, size: 72),
                    )
                  else ...[
                    Icon(
                      Icons.lock_outline_rounded,
                      color: cyan.withValues(alpha: 0.85),
                      size: 72,
                    ),
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

  // ─── Title Block ──────────────────────────────────────────────────────────

  Widget _buildTitle() {
    return Column(
      children: [
        const SizedBox(height: 22),
        Text(
          'Verify Identity',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            color: const Color(0xFFE8F4FF),
            fontSize: 28,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'OTP dispatched to +91 ${widget.phoneNumber}',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: const Color(0xFF3A5878).withValues(alpha: 0.9),
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  // ─── OTP Form ─────────────────────────────────────────────────────────────

  Widget _buildOtpForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ENTER 6-DIGIT CODE',
            style: TextStyle(
              color: cyan.withValues(alpha: 0.45),
              fontSize: 9,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (i) => _buildDigitBox(i)),
          ),
          const SizedBox(height: 20),
          // Verify button
          AnimatedBuilder(
            animation: _btnGlowAnim,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: cyan.withValues(
                        alpha: 0.35 * _btnGlowAnim.value),
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
                onPressed:
                    (_isLoading || _otpValue.length < 6) ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isVerified
                      ? const Color(0xFF00C896)
                      : cyan,
                  disabledBackgroundColor: cyan.withValues(alpha: 0.3),
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
                          color: bg.withValues(alpha: 0.8),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _isVerified ? 'VERIFIED' : 'Verify OTP',
                            style: const TextStyle(
                              color: Color(0xFF040810),
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2.5,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _isVerified
                                ? Icons.check_rounded
                                : Icons.north_east_rounded,
                            color: const Color(0xFF040810).withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Resend row
          Center(
            child: _resendSeconds > 0
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'RESEND IN  ',
                          style: TextStyle(
                            color: const Color(0xFF2A4060).withValues(alpha: 0.8),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1.4,
                          ),
                        ),
                        TextSpan(
                          text: '00:${_resendSeconds.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: cyan.withValues(alpha: 0.7),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: () {
                      setState(() => _resendSeconds = 30);
                      _startResendTimer();
                    },
                    child: Text(
                      'RESEND OTP',
                      style: TextStyle(
                        color: cyan,
                        fontSize: 10,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final isFocused = _focusNodes[index].hasFocus;
    final hasValue = _controllers[index].text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 44,
      height: 54,
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFocused
              ? cyan.withValues(alpha: 0.8)
              : hasValue
                  ? cyan.withValues(alpha: 0.35)
                  : border,
          width: isFocused ? 1.5 : 1,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: cyan.withValues(alpha: 0.2),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (e) => _onKeyEvent(index, e),
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.spaceGrotesk(
            color: cyan,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
          cursorColor: cyan,
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (v) => _onDigitChanged(index, v),
          onTap: () => setState(() {}),
        ),
      ),
    );
  }
}