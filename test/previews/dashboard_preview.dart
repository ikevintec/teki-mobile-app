// Vista de prueba: todas las solicitudes son interceptadas, sin cuentas reales.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_main_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/dashboard_fixture.dart';
import '../support/loyalty_fixture.dart';

LoyaltySessionNotifier? previewSession;
Future<void> main() async {
  if (kReleaseMode) throw StateError('Solo para pruebas.');
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_URL=https://example.com/api');
  await initializeDateFormatting('es');
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'))
    ..httpClientAdapter = DashboardAdapter();
  previewSession = LoyaltySessionNotifier(dashboardSession());
  runApp(
    ProviderScope(
      overrides: [sesionProvider.overrideWith((_) => previewSession!)],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        builder: (context, child) => Banner(
          message: 'DATOS SIMULADOS',
          location: BannerLocation.topEnd,
          child: child!,
        ),
        home: const DashboardMainScreen(),
      ),
    ),
  );
}
