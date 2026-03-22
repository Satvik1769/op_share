import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:op_share_flutter/config/env_config.dart';
import 'package:op_share_flutter/screens/auth_screens/contact_screen/contact_screen.dart';

late final EnvConfig appConfig;
String authToken = '';
String currentUserId = '';

void main() {
  appConfig = EnvConfig.prod;
  runApp(const MyApp(config: EnvConfig.prod));
}

class MyApp extends StatelessWidget {
  final EnvConfig config;

  const MyApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
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