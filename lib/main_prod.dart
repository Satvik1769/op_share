import 'package:opShare/config/env_config.dart';
import 'package:opShare/main.dart';
import 'package:flutter/material.dart';

void main() {
  appConfig = EnvConfig.prod;
  runApp(const MyApp(config: EnvConfig.prod));
}