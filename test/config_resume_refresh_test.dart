import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/domain/repositories/auth_repository.dart';
import 'package:teki_app/src/domain/repositories/config_repository.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/shared/services/config_resume_refresh.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class _AuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _ConfigRepository implements ConfigRepository {
  final pending = <Completer<ConfigCompany>>[];
  @override
  Future<ConfigCompany> getConfigValue() {
    final result = Completer<ConfigCompany>();
    pending.add(result);
    return result.future;
  }
}

class _Storage extends KeyValueStorageServiceImpl {
  final saved = <String, dynamic>{};
  @override
  Future<void> setKeyValue<T>(String key, T value) async => saved[key] = value;
}

class _Session extends SesionNotifier {
  _Session() : super(saleStationRepository: _Stations()) {
    state = SesionState(
      login: LoginResponse(user: User(id: 1)),
      office: Office(id: 11),
      config: ConfigCompany(
        configuracionDistribuidor: {'preciosComerciales': false},
      ),
    );
  }
  void replaceSession() =>
      state = state.copyWith(login: LoginResponse(user: User(id: 2)));
}

class _Auth extends AuthStateNotifier {
  _Auth(Ref ref, _ConfigRepository config, _Storage storage)
    : super(
        ref: ref,
        authRepository: _AuthRepository(),
        saleStationRepository: _Stations(),
        configRepository: config,
        keyvalueStorage: storage,
      ) {
    state = AuthState(isLoggedIn: true);
  }
  void signedOut() => state = AuthState(isLoggedIn: false);
}

class _CommercialAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    return ResponseBody.fromString(
      jsonEncode(
        options.path.endsWith('tipos-precio')
            ? [
                {'id': 7, 'estado': true},
                {'id': 8, 'estado': true},
              ]
            : {'idTipoComercial': 7},
      ),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _ConfigRepository repo;
  late _Storage storage;
  late _Session session;
  late ProviderContainer container;
  late _Auth auth;

  setUp(() {
    dotenv.loadFromString(envString: 'API_URL=https://api.example.test/api');
    repo = _ConfigRepository();
    storage = _Storage();
    session = _Session();
    container = ProviderContainer(
      overrides: [
        sesionProvider.overrideWith((ref) => session),
        authStateProvider.overrideWith((ref) => _Auth(ref, repo, storage)),
      ],
    );
    auth = container.read(authStateProvider.notifier) as _Auth;
  });
  tearDown(() => container.dispose());

  Future<void> lifecycle(WidgetTester tester, AppLifecycleState state) async {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }

  Future<void> mount(WidgetTester tester) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ConfigResumeRefresh(child: SizedBox()),
      ),
    );
  }

  testWidgets(
    'solo refresca al regresar del fondo y agrupa consultas pendientes',
    (tester) async {
      await mount(tester);
      await lifecycle(tester, AppLifecycleState.resumed);
      await lifecycle(tester, AppLifecycleState.inactive);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(repo.pending, isEmpty);
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      await lifecycle(tester, AppLifecycleState.resumed);
      await lifecycle(tester, AppLifecycleState.paused);
      await lifecycle(tester, AppLifecycleState.resumed);
      expect(repo.pending, hasLength(1));
      final cfg = ConfigCompany(
        configuracionDistribuidor: {'preciosComerciales': true},
      );
      repo.pending.single.complete(cfg);
      await tester.pump();
      expect(container.read(sesionProvider).config, same(cfg));
      expect(storage.saved, hasLength(1));
    },
  );

  testWidgets('sin sesión no consulta y al desmontar retira observador', (
    tester,
  ) async {
    await mount(tester);
    auth.signedOut();
    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.resumed);
    expect(repo.pending, isEmpty);
    await tester.pumpWidget(const SizedBox());
    await lifecycle(tester, AppLifecycleState.paused);
    await lifecycle(tester, AppLifecycleState.resumed);
    expect(repo.pending, isEmpty);
  });

  test('un fallo conserva configuración y permite reintentar', () async {
    final old = container.read(sesionProvider).config;
    final failed = auth.refreshConfigCompany();
    repo.pending.single.completeError(StateError('offline ficticio'));
    expect(await failed, isNull);
    expect(container.read(sesionProvider).config, same(old));
    expect(storage.saved, isEmpty);
    final retry = auth.refreshConfigCompany();
    final cfg = ConfigCompany(inventario: true);
    repo.pending.last.complete(cfg);
    expect(await retry, same(cfg));
  });

  test('descarta respuesta posterior a logout', () async {
    final old = container.read(sesionProvider).config;
    final pending = auth.refreshConfigCompany();
    auth.signedOut();
    repo.pending.single.complete(ConfigCompany(inventario: true));
    expect(await pending, isNull);
    expect(container.read(sesionProvider).config, same(old));
    expect(storage.saved, isEmpty);
  });

  test(
    'una respuesta de sesión anterior no pisa la nueva ni su persistencia',
    () async {
      final first = auth.refreshConfigCompany();
      session.replaceSession();
      final second = auth.refreshConfigCompany();
      final cfg = ConfigCompany(inventario: true);
      repo.pending.last.complete(cfg);
      expect(await second, same(cfg));
      repo.pending.first.complete(ConfigCompany(inventario: false));
      expect(await first, isNull);
      expect(container.read(sesionProvider).config, same(cfg));
      expect(storage.saved, hasLength(1));
    },
  );

  test(
    'refresca contexto comercial y conserva tipo seleccionado elegible',
    () async {
      final previousDio = ApiClient.dio;
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'))
        ..httpClientAdapter = _CommercialAdapter();
      addTearDown(() {
        ApiClient.dio.close();
        ApiClient.dio = previousDio;
      });
      session.setComercial(const ContextoComercial(activo: true, cabecera: 8));
      final pending = auth.refreshConfigCompany();
      repo.pending.single.complete(
        ConfigCompany(
          configuracionDistribuidor: {
            'preciosComerciales': true,
            'mayoreoManual': true,
          },
        ),
      );
      expect(await pending, isNotNull);
      final current = container.read(sesionProvider).comercial!;
      expect(current.activo, isTrue);
      expect(current.mayoreoManual, isTrue);
      expect(current.cabecera, 8);
    },
  );

  test('al apagar comerciales refresca también el contexto activo', () async {
    session.setComercial(const ContextoComercial(activo: true, cabecera: 8));
    final pending = auth.refreshConfigCompany();
    repo.pending.single.complete(
      ConfigCompany(configuracionDistribuidor: {'preciosComerciales': false}),
    );
    expect(await pending, isNotNull);
    expect(container.read(sesionProvider).comercial!.activo, isFalse);
  });
  test(
    'al activar comerciales refresca un contexto tradicional ya abierto',
    () async {
      final previousDio = ApiClient.dio;
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://api.example.test/api'))
        ..httpClientAdapter = _CommercialAdapter();
      addTearDown(() {
        ApiClient.dio.close();
        ApiClient.dio = previousDio;
      });
      session.setComercial(const ContextoComercial());
      final pending = auth.refreshConfigCompany();
      repo.pending.single.complete(
        ConfigCompany(configuracionDistribuidor: {'preciosComerciales': true}),
      );
      expect(await pending, isNotNull);
      expect(container.read(sesionProvider).comercial!.activo, isTrue);
    },
  );

  test(
    'si el modo sigue igual conserva el contexto sin volver a consultar tipos',
    () async {
      const previous = ContextoComercial(activo: true, cabecera: 8);
      session.setComercial(previous);
      final pending = auth.refreshConfigCompany();
      repo.pending.single.complete(
        ConfigCompany(configuracionDistribuidor: {'preciosComerciales': true}),
      );
      expect(await pending, isNotNull);
      expect(container.read(sesionProvider).comercial, same(previous));
    },
  );
}
