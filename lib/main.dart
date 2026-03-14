import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:op_share_flutter/config/env_config.dart';
import 'package:op_share_flutter/screens/room_intitiation/room_initiation_screen.dart';

late final EnvConfig appConfig;

void main() {
  runApp(const MyApp(config: EnvConfig.prod));
}

class MyApp extends StatelessWidget {
  final EnvConfig config;

  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    appConfig = config;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      theme: ThemeData.dark().copyWith(
        textTheme:
            GoogleFonts.spaceGroteskTextTheme(ThemeData.dark().textTheme),
      ),
      home: const AuthRequestScreen(),
    );
  }
}