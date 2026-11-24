// Vista visual aislada: solo contratos ficticios, sin acceso a cuentas ni emisión.
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';
import '../support/pedidos_opciones_fixture.dart';
import '../support/pedidos_fixture.dart';
import '../support/loyalty_fixture.dart';

class SelectorDemoAdapter extends PedidosOpcionesAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    if (o.path == '/distribuidor/tipos-precio') {
      return ResponseBody.fromString(
        jsonEncode([
          {
            'id': 1,
            'nombre': 'Minorista',
            'categoria': 'POR_DEFECTO',
            'principal': true,
            'estado': true,
          },
          {
            'id': 2,
            'nombre': 'Mayorista – Clientes y rutas de Guadalupe',
            'categoria': 'MAYOREO',
            'estado': true,
          },
        ]),
        200,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return super.fetch(o, body, cancel);
  }
}

Future<void> main() async {
  if (kReleaseMode) throw StateError('Solo para QA visual');
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api');
  await initializeDateFormatting('es');
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
    ..httpClientAdapter = SelectorDemoAdapter();
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
          builder: (ctx, child) => Banner(
            message: 'SIMULADO',
            location: BannerLocation.topEnd,
            child: child!,
          ),
          home: const ProductsSaleScreen(),
        ),
      ),
    ),
  );
}
