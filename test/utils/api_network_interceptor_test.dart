import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/network_error.dart';

class _Adapter implements HttpClientAdapter {
  _Adapter(this.status);
  final int status;
  int calls = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    calls++;
    return ResponseBody.fromString(
      '{"message":"error del servidor"}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    ApiClient.resetLogoutFlag();
  });

  test(
    '401 en login llega como credenciales y no como sesión expirada',
    () async {
      final adapter = _Adapter(401);
      final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
        ..httpClientAdapter = adapter
        ..interceptors.addAll(ApiClient.defaultInterceptors());
      addTearDown(dio.close);
      try {
        await dio.post(
          '/auth/login',
          data: {'username': 'qa@example.test', 'password': 'ficticia'},
        );
        fail('Debía rechazar las credenciales');
      } on DioException catch (error) {
        expect(error.type, DioExceptionType.badResponse);
        expect(error.response?.statusCode, 401);
        expect(error.message, isNot('SESSION_EXPIRED'));
      }
      expect(adapter.calls, 1);
    },
  );

  test('503 normalizado sin reintentar una escritura', () async {
    final adapter = _Adapter(503);
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.test'))
      ..httpClientAdapter = adapter
      ..interceptors.addAll(ApiClient.defaultInterceptors());
    addTearDown(dio.close);
    await expectLater(
      dio.post('/tickets', data: {'fixture': true}),
      throwsA(
        isA<DioException>().having(
          (error) => error.message,
          'mensaje',
          NetworkMessages.unavailable,
        ),
      ),
    );
    expect(adapter.calls, 1);
  });
}
