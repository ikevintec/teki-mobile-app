import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/datasource/remote_loyalty.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object body = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
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
  late _Adapter adapter;
  late Dio dio;
  late RemoteLoyalty remote;
  setUp(() {
    adapter = _Adapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api'))
      ..httpClientAdapter = adapter;
    remote = RemoteLoyalty(dio: dio);
  });
  tearDown(() => dio.close(force: true));

  test(
    'reutiliza listado y detalle de tarjetas sin escribir ni elegir la principal',
    () async {
      final json = {
        'id': 2,
        'nombre': 'Otra tarjeta',
        'slug': 'otra',
        'activo': true,
        'principal': false,
        'permitirSellos': true,
        'permitirPuntos': true,
      };
      adapter.body = [json];
      final cards = await remote.getCards();
      adapter.body = json;
      final detail = await remote.getCard(cards.single.id);
      expect(adapter.requests.map((r) => r.path), [
        '/loyalty/config/cards',
        '/loyalty/config/cards/2',
      ]);
      expect(adapter.requests.every((r) => r.method == 'GET'), true);
      expect(detail.tipo, 'Sellos · Puntos');
      expect(detail.principal, false);
    },
  );

  test(
    'rechazo del servidor y errores de conexión se traducen sin mostrar credenciales',
    () async {
      adapter.status = 403;
      adapter.body = {'message': 'private internal detail'};
      await expectLater(
        remote.getCards(),
        throwsA(predicate((e) => e.toString().contains('No tienes acceso'))),
      );
      adapter.status = 404;
      await expectLater(
        remote.getCard(9),
        throwsA(
          predicate((e) => e.toString().contains('ya no está disponible')),
        ),
      );
      adapter.status = 500;
      await expectLater(
        remote.getCards(),
        throwsA(predicate((e) => !e.toString().contains('private internal'))),
      );
    },
  );

  test('cancelación no se convierte en error de conexión', () async {
    final token = CancelToken()..cancel('closed');
    await expectLater(
      remote.getCards(cancelToken: token),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, isEmpty);
  });
}
