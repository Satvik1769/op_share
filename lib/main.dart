import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:opShare/config/env_config.dart';
import 'package:opShare/firebase_options.dart';
import 'package:opShare/screens/auth_screens/contact_screen/contact_screen.dart';

late final EnvConfig appConfig;
String authToken = '';
String currentUserId = '';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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