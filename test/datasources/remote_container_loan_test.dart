import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/datasource/remote_container_loan.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';

void main() {
  late _Adapter adapter;
  late Dio dio;
  late RemoteContainerLoan remote;

  setUp(() {
    adapter = _Adapter();
    dio = Dio()..httpClientAdapter = adapter;
    remote = RemoteContainerLoan(dio: dio);
  });
  tearDown(() => dio.close(force: true));

  test('lista con filtros y lee la página', () async {
    adapter.body = {
      'content': [
        {
          'id': 7,
          'customer': 'Ana',
          'quantity': 3,
          'pendingQuantity': 2,
          'pendingValue': 28,
        },
      ],
      'totalElements': 41,
    };
    final (items, total) = await remote.getLoans(
      customerId: 5,
      pending: true,
      page: 1,
      size: 20,
    );
    expect(adapter.requests.single.path, '/container-loans');
    expect(adapter.requests.single.queryParameters, {
      'customerId': 5,
      'pending': true,
      'page': 1,
      'size': 20,
    });
    expect(items.single.pendingQuantity, 2);
    expect(total, 41);
  });

  test(
    'la carga anterior envía fecha ISO UTC, cantidad entera y sin nota vacía',
    () async {
      adapter.body = {'id': 9, 'openingBalance': true, 'quantity': 4};
      final loanedOn = DateTime(2026, 1, 15);
      final loan = await remote.registerOpening(
        ContainerOpening(
          customerId: 3,
          officeId: 1,
          productId: 10,
          quantity: 4,
          unitCost: 10.5,
          loanedOn: loanedOn,
          stockAlreadyDeducted: true,
          requestId: 'req-1',
          note: '  ',
        ),
      );
      final request = adapter.requests.single;
      expect(request.path, '/container-loans/opening');
      expect(request.data, {
        'customerId': 3,
        'officeId': 1,
        'productId': 10,
        'quantity': 4,
        'unitCost': 10.5,
        'loanedOn': loanedOn.toUtc().toIso8601String(),
        'stockAlreadyDeducted': true,
        'requestId': 'req-1',
      });
      expect(loan.openingBalance, isTrue);
    },
  );

  test('productos de carga y anulación usan sus rutas', () async {
    adapter.body = [
      {
        'id': 10,
        'name': 'Bidón lleno',
        'container': 'Bidón vacío',
        'unitCost': 14,
      },
    ];
    final products = await remote.getOpeningProducts('bid');
    expect(adapter.requests.last.path, '/container-loans/opening-products');
    expect(adapter.requests.last.queryParameters, {'term': 'bid'});
    expect(products.single.unitCost, 14);
    expect(products.single.currency, 'PEN');

    adapter.body = {'id': 9, 'cancelled': true};
    final cancelled = await remote.cancelOpening(9);
    expect(adapter.requests.last.path, '/container-loans/9/cancel-opening');
    expect(cancelled.cancelled, isTrue);
  });

  test('un rechazo del servidor muestra su mensaje', () async {
    adapter
      ..statusCode = 412
      ..body = {
        'mensaje':
            'Revierta las devoluciones antes de anular la carga inicial.',
      };
    await expectLater(
      remote.cancelOpening(9),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'mensaje',
          contains('Revierta las devoluciones'),
        ),
      ),
    );
  });
}

class _Adapter implements HttpClientAdapter {
  int statusCode = 200;
  Object body = const {};
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
