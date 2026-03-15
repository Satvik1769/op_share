import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors.dart';

class OtpTitle extends StatelessWidget {
  final String phoneNumber;
  const OtpTitle({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'OTP dispatched to +91 $phoneNumber',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF3A5878).withValues(alpha: 0.9),
                fontSize: 12,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Icon(
                Icons.edit,
                size: 13,
                color: const Color(0xFF3A5878).withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }
}