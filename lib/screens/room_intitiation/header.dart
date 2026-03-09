import 'package:flutter/material.dart';
import 'colors_room.dart';
import 'package:google_fonts/google_fonts.dart';

class Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'ROOM INITIATION',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'PREPARE FOR SPATIAL DISPLACEMENT',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            letterSpacing: 3,
            color: kCyan.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}
