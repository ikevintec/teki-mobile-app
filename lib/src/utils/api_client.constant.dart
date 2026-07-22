import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/storage_keys.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static bool _isLoggingOut = false;

  static void resetLogoutFlag() {
    _isLoggingOut = false;
  }

  /// Interceptores compartidos: auth + logout en 401 y logging solo en debug.
  /// Cualquier cliente Dio adicional debe usarlos (ver remote_whatsapp_datasource).
  static List<Interceptor> defaultInterceptors() => [
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString(StorageKeys.accessToken);
            // PlatformRequest siempre se envía (incluyendo login)
            options.headers['PlatformRequest'] = 'mobile';
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) async {
            if (e.response?.statusCode == 401 && !_isLoggingOut) {
              _isLoggingOut = true;

              // Cancelar todas las notificaciones pendientes de GetX
              Get.closeAllSnackbars();

              // warningNotification('Tu sesión ha expirado. Por favor inicia sesión nuevamente.');
              globalContainer.read(authStateProvider.notifier).logout();

              // Crear un error específico para evitar procesamiento adicional
              return handler.reject(
                DioException(
                  requestOptions: e.requestOptions,
                  type: DioExceptionType.cancel,
                  message: 'SESSION_EXPIRED',
                ),
              );
            }
            return handler.next(e);
          },
        ),
        // Logging solo en debug: en release filtraría token y credenciales.
        if (kDebugMode)
          LogInterceptor(
            request: true,
            requestHeader: true,
            responseHeader: true,
            error: true,
            requestBody: true,
            responseBody: true,
            logPrint: (obj) {
              debugPrint('--->: $obj');
            },
          ),
      ];

  static Dio dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.addAll(defaultInterceptors());
}
