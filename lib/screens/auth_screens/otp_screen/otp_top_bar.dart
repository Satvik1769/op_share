import 'package:flutter/material.dart';
import '../../room_intitiation/top_status_bar.dart';

class OtpTopBar extends StatelessWidget {
  const OtpTopBar({super.key});

  @override
  Widget build(BuildContext context) {
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
}