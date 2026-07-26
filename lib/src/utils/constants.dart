import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ColorSchema {
  static const Color primaryColor = Color(0xFF2C6AE5);
  static const Color titleTextColor = Color(0xFF353537);
  static const Color subTitleTextColor = Color(0xFFADADB1);
  static const Color quotationColor = Color(0xFFF59E0B);
}

class Environment {
  /// Debug y profile cargan `.env` (entorno local del desarrollador).
  /// Los builds RELEASE cargan siempre `.env.production`: así un `.env`
  /// apuntando a localhost nunca puede colarse en un build de tienda.
  static initEnvironment() async {
    await dotenv.load(fileName: kReleaseMode ? '.env.production' : '.env');
  }

  static String apiUrl = dotenv.env['API_URL'] ?? 'no url defined';
  static String wsUrl = dotenv.env['WS_URL'] ?? 'https://sock.teki.pe';
  static String wsPath = dotenv.env['WS_PATH'] ?? '/tekiwss';
  static String printUrl = dotenv.env['PRINT_URL'] ?? '';
  static String iaUrl = dotenv.env['IA_URL'] ?? 'https://ai.teki.pe/ai';
}