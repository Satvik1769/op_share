import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:op_share_flutter/screens/room_intitiation/room_initiation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme:
            GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
      ),
      home: const RoomInitiationScreen(),
    );
  }
}
