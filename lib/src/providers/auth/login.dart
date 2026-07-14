import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:teki_app/src/shared/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/repositories/auth_repository_impl.dart';
import 'package:teki_app/src/data/repositories/config_repository_impl.dart';
import 'package:teki_app/src/data/repositories/sale_station_Repository_impl.dart';
import 'package:teki_app/src/domain/repositories/auth_repository.dart';
import 'package:teki_app/src/domain/repositories/config_repository.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repositoy.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

// Creación del Provider que gestionará los cambios de estado
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  final AuthRepository authRepository = AuthRepositoryImpl();
  final SaleStationRepository saleStationRepository = SaleStationRepositoryImpl();
  final ConfigRepository configRepository = ConfigRepositoryImpl();
  final KeyValueStorageServiceImpl keyvalueStorage = KeyValueStorageServiceImpl();

  return AuthStateNotifier(
    ref: ref,
    authRepository: authRepository,
    saleStationRepository: saleStationRepository,
    configRepository: configRepository,
    keyvalueStorage: keyvalueStorage,
  );
});

// Notifier encargado de manejar el estado de la autenticación
class AuthStateNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final AuthRepository authRepository;
  final SaleStationRepository saleStationRepository;
  final ConfigRepository configRepository;
  final KeyValueStorageServiceImpl keyvalueStorage;

  AuthStateNotifier({
    required this.saleStationRepository,
    required this.ref,
    required this.authRepository,
    required this.configRepository,
    required this.keyvalueStorage,
  }) : super(AuthState(isLoggedIn: false));

  void login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      LoginResponse response = await authRepository.login(username, password);

      state = state.copyWith(
        isLoggedIn: true,
        token: response.accessToken,
        user: response.user,
      );

      //Seteamos los valores que van aperdurar
      await keyvalueStorage.setKeyValue('access_token', response.accessToken);
      await keyvalueStorage.setKeyValue('login', jsonEncode(response.toJson()));
      await setConfigProvider(ref, response, saleStationRepository);

      // Obtenemos los permisos/roles del usuario (una sola vez, al iniciar sesión)
      final List<String> roles = await authRepository.getRoles();
      ref.read(sesionProvider.notifier).setRoles(roles);
      await keyvalueStorage.setKeyValue('roles', jsonEncode(roles));

      ConfigCompany configCompany = await setConfigCompanies(ref, configRepository);
      await keyvalueStorage.setKeyValue('configCompany', jsonEncode(configCompany.toJson()));
      
      // Resetear el flag de logout para permitir nuevas sesiones
      ApiClient.resetLogoutFlag();

      // Inicializar push notifications con el userId del usuario autenticado
      final userId = response.user?.id;
      if (userId != null) {
        NotificationService.instance.initialize(userId);
      }

      successNotification('Sesion iniciada');
      Get.offAllNamed('/dashboard');
    } on DioException catch (e) {
      String message = 'Ocurrió un error desconocido.';

      if (e.type == DioExceptionType.connectionTimeout) {
        message = 'Tiempo de espera agotado al conectar con el servidor.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        message = 'Tiempo de espera agotado al recibir respuesta del servidor.';
      } else if (e.type == DioExceptionType.sendTimeout) {
        message = 'Tiempo de espera agotado al enviar datos al servidor.';
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;

        if (statusCode == 401) {
          message =
              'Credenciales incorrectas. Verifica tu usuario y contraseña.';
        } else if (statusCode == 403) {
          message = 'Acceso denegado. No tienes permisos suficientes.';
        } else if (statusCode == 500) {
          message = 'Error interno del servidor.';
        } else if (errorData is Map) {
          message = errorData['mensaje'] ?? errorData['message'] ?? 'Error HTTP $statusCode';
        } else {
          message = 'Error HTTP $statusCode';
        }
      } else if (e.type == DioExceptionType.unknown) {
        message = 'Error de red o el servidor no está disponible.';
      } else {
        message = e.message ?? 'Error inesperado';
      }
      errorNotification(message);
      logout();
    } on Exception catch (e) {
      errorNotification(e.toString());
      logout();
    } catch (e) {
      setError('No se pudo iniciar Sesion: ${e.toString()}');
      errorNotification(e.toString());
      logout();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> checkAuthStatus() async {
    final token = await keyvalueStorage.getValue<String>('access_token');
    final loginJson = await keyvalueStorage.getValue<String>('login');
    final configCompanyJson =
        await keyvalueStorage.getValue<String>('configCompany');
    final rolesJson = await keyvalueStorage.getValue<String>('roles');

    if (token != null && loginJson != null && configCompanyJson != null) {
      final login = LoginResponse.fromJson(jsonDecode(loginJson));

      state = state.copyWith(
        isLoggedIn: true,
        token: token,
        user: login.user,
        isLoading: false,
      );
      try {
        await setConfigProvider(ref, login, saleStationRepository);
        ConfigCompany configCompany =
            ConfigCompany.fromJson(jsonDecode(configCompanyJson));
        ref.read(sesionProvider.notifier).setConfigCompany(configCompany);

        // Restauramos los roles persistidos sin repetir la petición
        if (rolesJson != null) {
          ref
              .read(sesionProvider.notifier)
              .setRoles(List<String>.from(jsonDecode(rolesJson)));
        }

        final userId = login.user?.id;
        if (userId != null) {
          NotificationService.instance.initialize(userId);
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          logout();
        } else {
          errorNotification('Error de conexión al cargar la configuración.');
        }
      } catch (e) {
        errorNotification(e.toString());
      }
    } else {
      logout();
    }
  }

  void logout() async {
    NotificationService.instance.dispose();
    await keyvalueStorage.removeKey('access_token');
    await keyvalueStorage.removeKey('login');
    await keyvalueStorage.removeKey('configCompany');
    await keyvalueStorage.removeKey('roles');

    state = state.copyWith(
      isLoggedIn: false,
      token: null,
      user: null,
      errorMessage: null,
      isLoading: false,
    );

    String actualRoute = Get.currentRoute;

    if (actualRoute != '/login' && actualRoute != '/splashScreen') {
      Get.offAllNamed('/login');
    }
    return;
  }

  void setError(String errorMessage) {
    state = state.copyWith(errorMessage: errorMessage);
  }
}

// Estado del Auth Provider
class AuthState {
  final bool isLoggedIn;
  final String? token;
  final String? errorMessage;
  final User? user;
  final bool isLoading;

  AuthState({
    required this.isLoggedIn,
    this.token,
    this.errorMessage,
    this.user,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isLoggedIn,
    String? token,
    String? errorMessage,
    User? user,
    bool? isLoading,
  }) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      token: token ?? this.token,
      errorMessage: errorMessage ?? this.errorMessage,
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Seteo de configuración global tras autenticación
Future<void> setConfigProvider(
  Ref ref,
  LoginResponse login,
  SaleStationRepository saleStationRepository,
) async {
  final user = login.user;
  final puntosVenta = user?.puntosVenta ?? [];
  final estacionAsignada = user?.estacionVenta;

  Office? defaultPv;
  if (estacionAsignada != null) {
    defaultPv = puntosVenta.firstWhere(
      (pv) => pv.id == estacionAsignada.puntoVenta?.id,
      orElse: () => puntosVenta.isNotEmpty ? puntosVenta.first : Office(),
    );
  } else {
    final pvCompany = puntosVenta.where((pv) => pv.rucAsignado == user?.rucAsignado).firstOrNull;
    defaultPv = pvCompany ?? (puntosVenta.isNotEmpty ? puntosVenta.first : Office());
  }

  final int idPuntoVenta = defaultPv.id ?? 0;
  List<SaleStation> saleStations = [];
  try {
    saleStations = await saleStationRepository.getSaleStations(idPuntoVenta);
  } on DioException catch (e) {
    if (e.response?.statusCode == 401) {
      rethrow;
    }
    final message = (e.response?.data is Map ? e.response?.data['message'] : null) ?? 'Error de conexión';
    return Future.error('Error al obtener los puntos de venta: $message');
  } catch (e) {
    return Future.error('Error al obtener los puntos de venta: ${e.toString()}');
  }
  if (saleStations.isEmpty) {
    return Future.error('No se encontraron puntos de venta para la empresa.');
  }
  ref.read(sesionProvider.notifier).setFullConfig(login, saleStations, defaultPv);
}

Future<ConfigCompany> setConfigCompanies(Ref ref, ConfigRepository configRepository) async {
  ConfigCompany configCompany = ConfigCompany();
  try {
    configCompany = await configRepository.getConfigValue();
  } catch (e) {
    return Future.error('Error al obtener la configuración de la empresa: ${e.toString()}');
  }

  ref.read(sesionProvider.notifier).setConfigCompany(configCompany);
  return configCompany;
}
