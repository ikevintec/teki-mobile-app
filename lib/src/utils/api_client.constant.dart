import 'package:dio/dio.dart';
import 'package:get/get.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/utils/contstants.dart';
// import 'package:teki_app/src/utils/notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static bool _isLoggingOut = false;
  
  static void resetLogoutFlag() {
    _isLoggingOut = false;
  }
  
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.addAll([
      LogInterceptor(
        request: true,
        requestHeader: true,
        responseHeader: true,
        error: true,
        requestBody: true,
        responseBody: true,
        logPrint: (obj) {
          print('--->: $obj');
        },
      ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            options.headers['PlatformRequest'] = 'mobile';
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
      )
    ]);
}
