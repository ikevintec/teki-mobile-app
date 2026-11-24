// Vista nativa de QA: repositorio ficticio, sin API real ni emisión de ventas.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/ver_comprobantes.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';
import '../support/loyalty_fixture.dart';
import '../support/ventas_filtros_fixture.dart';

Future<void> main() async {
  if (kReleaseMode) throw StateError('Solo para pruebas');
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
  await initializeDateFormatting('es');
  final repository = VentasPrueba();
  runApp(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          (_) => LoyaltySessionNotifier(loyaltySession(roles: [])),
        ),
        comprobantesSaleProvider.overrideWith(
          (ref) => ComprobantesNotifier(repository: repository, ref: ref),
        ),
      ],
      child: GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: ColorSchema.primaryColor,
          ),
        ),
        builder: (_, child) => Banner(
          message: 'SIMULADO',
          location: BannerLocation.topEnd,
          child: child!,
        ),
        home: const VerComprobanteScreen(),
      ),
    ),
  );
}
