import 'package:toastification/toastification.dart';
// Solo datos sintéticos; no llama a ninguna cuenta real.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';
import '../support/pedidos_fixture.dart';
import '../support/pedidos_varios_fixture.dart';
import '../support/loyalty_fixture.dart';

Future<void> main() async {
  if (kReleaseMode) throw StateError('Solo para pruebas');
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
  await initializeDateFormatting('es');
  final hoy = DateTime.now().toIso8601String().split('T').first;
  final adapter = const bool.fromEnvironment('QA_VARIOS')
      ? PedidosVariosAdapter()
      : (PedidosAdapter()..conPromocion = true);
  for (final (id, nombre, estado) in [
    (1, 'Bodega Los Olivos', 'PENDIENTE'),
    (2, 'Minimarket Norte', 'CONCRETADA'),
    (3, 'Bodega Santa Rosa', 'ANULADA'),
    (4, 'Bodega La Esquina', 'PENDIENTE'),
  ]) {
    adapter.pedidosIniciales.add({
      'id': id,
      'serie': 'PE01',
      'numero': id,
      'denominacionReceptor': nombre,
      'numeroDocumentoReceptor': '20123456789',
      'codigoMoneda': 'PEN',
      'totalVenta': 125.5 + id,
      'fechaEmision': hoy,
      'estadoCotizacion': estado,
      'puedeEditarPedido': false,
      'items': [
        {
          'descripcion': 'Arroz extra 1 kg',
          'cantidad': 5,
          'precioVentaUnitario': 6,
        },
      ],
    });
  }
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
    ..httpClientAdapter = adapter;
  runApp(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          (_) => LoyaltySessionNotifier(pedidosSession()),
        ),
      ],
      child: ToastificationWrapper(
        child: GetMaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: ColorSchema.primaryColor,
            ),
          ),
          darkTheme: ThemeData(brightness: Brightness.dark, useMaterial3: true),
          builder: (ctx, child) => Banner(
            message: 'SIMULADO',
            location: BannerLocation.topEnd,
            child: child!,
          ),
          home: const PedidosScreen(),
        ),
      ),
    ),
  );
}
