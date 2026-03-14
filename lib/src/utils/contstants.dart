import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ColorSchema {
  static const Color primaryColor = Color(0xFF2C6AE5);
  static const Color titleTextColor = Color(0xFF353537);
  static const Color subTitleTextColor = Color(0xFFADADB1);
}

class Environment {
  static intiEnvironment() async {
    await dotenv.load(fileName: ".env");
  }

  static String apiUrl = dotenv.env['API_URL'] ?? 'no url defined';
  static String wsUrl = dotenv.env['WS_URL'] ?? 'https://sock.teki.pe';
  static String wsPath = dotenv.env['WS_PATH'] ?? '/tekiwss';
  static String printUrl = dotenv.env['PRINT_URL'] ?? '';
}