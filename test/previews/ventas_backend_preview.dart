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
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/data/repositories/auth_repository_impl.dart';
import 'package:teki_app/src/data/repositories/config_repository_impl.dart';
import 'package:teki_app/src/data/repositories/sale_station_Repository_impl.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
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
    data: {
      'username': const String.fromEnvironment(
        'QA_USER',
        defaultValue: 'test-admin',
      ),
      'password': 'TestPass123!',
    },
  );
  final token = response.data['accessToken'] as String;
  dio.options.headers['Authorization'] = 'Bearer $token';
  ApiClient.dio = dio;
  final config = await ConfigRepositoryImpl().getConfigValue();
  // El fixture emite únicamente NV; no configura certificado ni series fiscales.
  config.tipoComprobantePorDefecto = 'NV';
  final company = Companysummary(
    id: 999900,
    nombreComercial: 'Empresa QA local',
  );
  final session = pedidosSession().copyWith(
    login: LoginResponse.fromJson(Map<String, dynamic>.from(response.data)),
    config: config,
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
        authStateProvider.overrideWith(
          (ref) => QaAuthVentas(ref, session.login),
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
            message: 'API LOCAL',
            location: BannerLocation.topEnd,
            child: child!,
          ),
          home: const ProductsSaleScreen(),
        ),
      ),
    ),
  );
}

// Autenticación real del fixture; evita iniciar notificaciones/configuración ajenas al recorrido.
class QaAuthVentas extends AuthStateNotifier {
  QaAuthVentas(Ref ref, LoginResponse login)
    : super(
        ref: ref,
        authRepository: AuthRepositoryImpl(),
        saleStationRepository: SaleStationRepositoryImpl(),
        configRepository: ConfigRepositoryImpl(),
        keyvalueStorage: KeyValueStorageServiceImpl(),
      ) {
    state = AuthState(
      isLoggedIn: true,
      user: login.user,
      token: login.accessToken,
    );
  }
}
