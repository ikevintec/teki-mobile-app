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
  test(
    'clientes envía filtro de tarjeta, búsqueda y paginación al servidor',
    () async {
      adapter.body = {
        'content': [
          {
            'id': 11,
            'idLoyaltyConfig': 1,
            'idCustomer': 900,
            'clienteNombre': 'María',
            'tarjetaNombre': 'Recargas',
            'clienteDocumento': '12345678',
            'sellos': 14,
            'puntosDisponibles': 40,
            'puntosAcumulados': 50,
            'activo': true,
          },
        ],
        'totalElements': 81,
        'last': false,
      };
      final page = await remote.getCustomers(
        1,
        filter: ' María ',
        page: 3,
        size: 7,
      );
      expect(adapter.requests.single.path, '/loyalty/customers');
      expect(adapter.requests.single.queryParameters, {
        'idLoyaltyConfig': 1,
        'filtro': 'María',
        'pageNumber': 3,
        'perPage': 7,
      });
      expect(page.total, 81);
      expect(page.items.length, 1);
      expect(page.hasMore, true);
      expect(page.items.single.discreetDocument, '••••5678');
      expect(page.items.single.stamps, 14);
      expect(page.items.single.availablePoints, 40);
    },
  );

  test(
    'detalle usa inscripción y mantiene null como saldo no informado',
    () async {
      adapter.body = {
        'id': 11,
        'idLoyaltyConfig': 1,
        'idCustomer': 900,
        'clienteNombre': 'María',
        'tarjetaNombre': 'Recargas',
        'fechaRegistro': 1792771200000,
      };
      final member = await remote.getCustomer(11);
      expect(adapter.requests.single.path, '/loyalty/customers/11');
      expect(member.customerId, 900);
      expect(member.availablePoints, null);
      expect(member.registeredAt!.millisecondsSinceEpoch, 1792771200000);
    },
  );

  test('movimientos siempre paginados, con signo y referencia real', () async {
    adapter.body = {
      'content': [
        {
          'id': 1,
          'puntos': -10,
          'tipo': 'CANJE',
          'proceso': 'CANJE_CUPON',
          'idTicket': 42,
          'fecha': '2026-10-23T12:00:00Z',
        },
      ],
      'totalElements': 1,
      'last': true,
    };
    final page = await remote.getMovements(11, page: 2, size: 10);
    expect(adapter.requests.single.path, '/loyalty/customers/11/movimientos');
    expect(adapter.requests.single.queryParameters, {
      'pageNumber': 2,
      'perPage': 10,
    });
    expect(page.items.single.points, -10);
    expect(page.items.single.typeLabel, 'Canje');
    expect(page.items.single.processLabel, 'Canje de cupón');
    expect(page.items.single.ticketId, 42);
    expect(page.hasMore, false);
  });

  test(
    'cupones usa la inscripción elegida y excluye cupones globales',
    () async {
      adapter.body = {
        'content': [
          {
            'id': 3,
            'loyaltyCustomer': {'id': 11, 'idLoyaltyConfig': 1},
            'couponDef': {'nombre': 'Recarga de prueba'},
            'estado': 'USADO',
            'codigo': 'DEMO',
          },
        ],
        'totalElements': 1,
        'last': true,
      };
      final page = await remote.getCoupons(11, page: 1, size: 5);
      expect(adapter.requests.single.path, '/loyalty/coupons');
      expect(adapter.requests.single.queryParameters, {
        'idLoyaltyCustomer': 11,
        'esGlobal': false,
        'pageNumber': 1,
        'perPage': 5,
      });
      expect(page.items.single.statusLabel, 'Usado');
      expect(page.items.single.enrollmentId, 11);
      expect(page.items.single.cardId, 1);
      expect(adapter.requests.single.method, 'GET');
    },
  );
}
