import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../../main.dart';
import '../../room_intitiation/room_initiation_screen.dart';
import '../colors.dart';
import 'otp_top_bar.dart';
import 'otp_scanner_widget.dart';
import 'otp_title.dart';
import 'otp_form.dart';

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
    for (final c in _controllers) c.dispose();
    for (final f in _focusNodes) f.dispose();
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


  Future<String> _getDeviceId() async {
    final info = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final android = await info.androidInfo;
      return android.id;
    } else if (Platform.isIOS) {
      final ios = await info.iosInfo;
      return ios.identifierForVendor ?? '';
    }
    return '';
  }

  Future<void> verifyOtp() async {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    deviceId = await _getDeviceId();
    final res = await http.post(
      Uri.parse('${appConfig.baseUrl}/auth/verify-otp'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'contactNumber': '$digits', 'otpCode': _otpValue, 'deviceId': deviceId}),
    );
    if (res.statusCode != 200) throw Exception('OTP verification failed');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    authToken = (data['token'] ?? data['accessToken'] ?? '').toString();
    currentUserId = (data['userId'] ?? data['id'] ?? '').toString();
  }

  Future<void> _resendOtp() async {
    final digits = widget.phoneNumber.replaceAll(RegExp(r'\D'), '');
    setState(() => _resendSeconds = 30);
    _startResendTimer();
    try {
      await http.post(
        Uri.parse('${appConfig.baseUrl}/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'contactNumber': '$digits'}),
      );
    } catch (_) {}
  }

  void _verifyOtp() async {
    if (_otpValue.length < 6) return;
    setState(() => _isLoading = true);
    try {
      await verifyOtp();
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      showAppSnackBar(context, 'OTP verification failed. Please check your OTP and try again.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _isVerified = true;
    });
    await _checkAnim.forward();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, __, ___) => const RoomInitiationScreen(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
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
                  const OtpTopBar(),
                  OtpScannerWidget(
                    ringPulse: _ringPulse,
                    ringRotate: _ringRotate,
                    ringScale: _ringScale,
                    scanPos: _scanPos,
                    checkScale: _checkScale,
                    isVerified: _isVerified,
                  ),
                  OtpTitle(phoneNumber: widget.phoneNumber),
                  const SizedBox(height: 32),
                  OtpForm(
                    controllers: _controllers,
                    focusNodes: _focusNodes,
                    isLoading: _isLoading,
                    isVerified: _isVerified,
                    otpValue: _otpValue,
                    resendSeconds: _resendSeconds,
                    btnGlowAnim: _btnGlowAnim,
                    onVerify: _verifyOtp,
                    onResend: _resendOtp,
                    onDigitChanged: _onDigitChanged,
                    onKeyEvent: _onKeyEvent,
                  ),
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
}