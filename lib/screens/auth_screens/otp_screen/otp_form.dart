import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors.dart';

class OtpForm extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final bool isLoading;
  final bool isVerified;
  final String otpValue;
  final int resendSeconds;
  final Animation<double> btnGlowAnim;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final void Function(int index, String value) onDigitChanged;
  final void Function(int index, KeyEvent event) onKeyEvent;

  const OtpForm({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.isLoading,
    required this.isVerified,
    required this.otpValue,
    required this.resendSeconds,
    required this.btnGlowAnim,
    required this.onVerify,
    required this.onResend,
    required this.onDigitChanged,
    required this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
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
            children: List.generate(
              6,
              (i) => _OtpDigitBox(
                controller: controllers[i],
                focusNode: focusNodes[i],
                onChanged: (v) => onDigitChanged(i, v),
                onKeyEvent: (e) => onKeyEvent(i, e),
              ),
            ),
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: btnGlowAnim,
            builder: (_, child) => Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: cyan.withValues(alpha: 0.35 * btnGlowAnim.value),
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
                onPressed: (isLoading || otpValue.length < 6) ? null : onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isVerified ? const Color(0xFF00C896) : cyan,
                  disabledBackgroundColor: cyan.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: isLoading
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
                            isVerified ? 'VERIFIED' : 'Verify OTP',
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
                            isVerified
                                ? Icons.check_rounded
                                : Icons.north_east_rounded,
                            color:
                                const Color(0xFF040810).withValues(alpha: 0.7),
                            size: 16,
                          ),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: resendSeconds > 0
                ? RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'RESEND IN  ',
                          style: TextStyle(
                            color:
                                const Color(0xFF2A4060).withValues(alpha: 0.8),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            letterSpacing: 1.4,
                          ),
                        ),
                        TextSpan(
                          text:
                              '00:${resendSeconds.toString().padLeft(2, '0')}',
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
                    onTap: onResend,
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
}

// ─── Digit Box ────────────────────────────────────────────────────────────────

class _OtpDigitBox extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final void Function(String) onChanged;
  final void Function(KeyEvent) onKeyEvent;

  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onKeyEvent,
  });

  @override
  State<_OtpDigitBox> createState() => _OtpDigitBoxState();
}

class _OtpDigitBoxState extends State<_OtpDigitBox> {
  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final isFocused = widget.focusNode.hasFocus;
    final hasValue = widget.controller.text.isNotEmpty;

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
        onKeyEvent: widget.onKeyEvent,
        child: TextField(
          controller: widget.controller,
          focusNode: widget.focusNode,
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
          onChanged: widget.onChanged,
        ),
      ),
    );
  }
}