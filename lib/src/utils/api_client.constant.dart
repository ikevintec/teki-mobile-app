import 'package:dio/dio.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiClient {
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: Environment.apiUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  )..interceptors.addAll([
      // LogInterceptor(
      //   request: true,
      //   requestHeader: true,
      //   responseHeader: true,
      //   error: true,
      //   requestBody: true,
      //   responseBody: true,
      //   logPrint: (obj) {
      //     print('--->: $obj');
      //   },
      // ),
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          bool isLoggingOut = false;
          if (e.response?.statusCode == 401 && !isLoggingOut) {
            isLoggingOut = true;
            globalContainer.read(authStateProvider.notifier).logout();
          }
          return handler.next(e);
        },
      )
    ]);
}
