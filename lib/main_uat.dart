import 'package:flutter/material.dart';
import 'package:opShare/config/env_config.dart';
import 'package:opShare/main.dart';

void main() {
  appConfig = EnvConfig.uat;
  runApp(const MyApp(config: EnvConfig.uat));
}
