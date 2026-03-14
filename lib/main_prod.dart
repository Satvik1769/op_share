import 'package:op_share_flutter/config/env_config.dart';
import 'package:op_share_flutter/main.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp(config: EnvConfig.prod));
}