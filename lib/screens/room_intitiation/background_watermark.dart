import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors_room.dart';


class BackgroundWatermark extends StatelessWidget {
  const BackgroundWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: 0.04,
              child: RotatedBox(
                quarterTurns: -1,
                child: Text(
                  'ROOM',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 150,
                    fontWeight: FontWeight.w900,
                    color: kCyan,
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: 0.04,
              child: RotatedBox(
                quarterTurns: -1,
                child: Text(
                  'SHAMBLES',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 120,
                    fontWeight: FontWeight.w900,
                    color: kCyan,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}
