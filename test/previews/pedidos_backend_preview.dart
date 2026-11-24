// Entrada de QA: API y MySQL efímeros de PedidosBrowserFixtureTest, sin mocks HTTP.
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';

Future<void> main() async {
  const url = String.fromEnvironment('QA_API_URL');
  final uri = Uri.tryParse(url);
  if (kReleaseMode ||
      uri == null ||
      uri.scheme != 'http' ||
      !['localhost', '127.0.0.1'].contains(uri.host) ||
      !uri.hasPort ||
      uri.path != '/api' ||
      uri.port == 8080) {
    throw StateError(
      'Requiere la API efímera de QA en un puerto local independiente.',
    );
  }
  WidgetsFlutterBinding.ensureInitialized();
  dotenv.loadFromString(envString: 'API_URL=$url');
  await initializeDateFormatting('es');
  final dio = Dio(BaseOptions(baseUrl: url));
  final response = await dio.post(
    '/auth/login',
    data: {'username': 'test-admin', 'password': 'TestPass123!'},
  );
  final token = response.data['accessToken'] as String;
  dio.options.headers['Authorization'] = 'Bearer $token';
  ApiClient.dio = dio;
  final company = Companysummary(
    id: 999900,
    nombreComercial: 'Empresa QA local',
  );
  final session = pedidosSession().copyWith(
    login: LoginResponse(
      accessToken: token,
      user: User(id: 999900, empresa: company),
    ),
    company: company,
    companySelected: company,
    roles: ['SUPER_USUARIO'],
    office: Office(id: 999900, nombre: 'Sede QA'),
    saleStation: SaleStation(id: 999900, nombre: 'Caja QA'),
  );
  runApp(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
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
            message: 'API LOCAL',
            location: BannerLocation.topEnd,
            child: child!,
          ),
          home: const PedidosScreen(),
        ),
      ),
    ),
  );
}
