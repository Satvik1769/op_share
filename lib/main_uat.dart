import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:opShare/config/env_config.dart';
import 'package:opShare/firebase_options.dart';
import 'package:opShare/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  appConfig = EnvConfig.uat;
  runApp(const MyApp(config: EnvConfig.uat));
}