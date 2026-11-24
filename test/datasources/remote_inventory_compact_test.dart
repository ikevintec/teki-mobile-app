import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/datasource/remote_inventory.dart';

void main() {
  test(
    'inventario solicita compact sin cambiar sede, filtros ni página',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final remote = RemoteInventory(dio: dio);
      final params = {
        'idPuntoVenta': 2,
        'pageNumber': 1,
        'perPage': 10,
        'clave': 'teléfono',
      };
      await remote.getInventory(params);
      expect(adapter.requests.single.path, '/inventory');
      expect(adapter.requests.single.queryParameters, {
        ...params,
        'compact': true,
      });
      expect(params.containsKey('compact'), isFalse);
    },
  );

  test(
    'consulta lotes del inventario exacto y movimientos por páginas separadas',
    () async {
      final adapter = _RecordingAdapter();
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final remote = RemoteInventory(dio: dio);
      final lots = await remote.getInventoryBatches(9, 2, 15);
      expect(lots.items.single.serie, 'SERIE-1');
      expect(lots.items.single.cantidad, 0);
      expect(lots.items.single.registros, isEmpty);
      expect(adapter.requests.last.path, '/batch-products/inventory/9');
      expect(adapter.requests.last.queryParameters, {
        'pageNumber': 2,
        'perPage': 15,
      });
      final history = await remote.getBatchRecords(42, 1, 15);
      expect(history.items.single.concepto, 'ANULACION_COMPRA');
      expect(history.items.single.responsable?.nombreCompleto, 'Ana Pérez');
      expect(adapter.requests.last.path, '/batch-products/42/records');
      expect(adapter.requests.last.queryParameters, {
        'pageNumber': 1,
        'perPage': 15,
      });
    },
  );

  test(
    'un error del detalle se propaga para mostrar reintento, no una lista vacía',
    () async {
      final adapter = _RecordingAdapter(statusCode: 503);
      final dio = Dio()..httpClientAdapter = adapter;
      addTearDown(() => dio.close(force: true));
      final remote = RemoteInventory(dio: dio);
      await expectLater(
        remote.getInventoryBatches(9, 0, 15),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        remote.getBatchRecords(42, 0, 15),
        throwsA(isA<DioException>()),
      );
    },
  );
}

class _RecordingAdapter implements HttpClientAdapter {
  final int statusCode;
  final requests = <RequestOptions>[];
  _RecordingAdapter({this.statusCode = 200});

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final items = options.path.endsWith('/records')
        ? [
            {
              'id': 1,
              'concepto': 'ANULACION_COMPRA',
              'cantidad': 1,
              'responsable': {
                'nombres': 'Ana',
                'apellidos': 'Pérez',
                'nombreCompleto': 'Ana Pérez',
              },
            },
          ]
        : options.path.startsWith('/batch-products/inventory/')
        ? [
            {'id': 42, 'serie': 'SERIE-1', 'cantidad': 0, 'tipoLote': 'SERIE'},
          ]
        : [];
    return ResponseBody.fromString(
      jsonEncode({'content': items, 'last': true}),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
