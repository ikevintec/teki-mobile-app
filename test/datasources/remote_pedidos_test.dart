import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/datasource/remote_quotation_datasource.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  Object body = {'id': 20, 'tipoComprobante': 'PE'};
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    return ResponseBody.fromString(
      jsonEncode(body),
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
  test(
    'pedidos usan su API para crear/editar/numerar; cotizaciones conservan la anterior',
    () async {
      final adapter = _Adapter();
      final dio = Dio(BaseOptions(baseUrl: 'http://localhost/api'))
        ..httpClientAdapter = adapter;
      final remote = RemoteQuotationDatasource(dio: dio);
      await remote.createQuotation(
        Ticket(tipoComprobante: 'PE', comercial: {'tipoPrecioCabeceraId': 2}),
      );
      await remote.updateQuotation(Ticket(id: 20, tipoComprobante: 'PE'));
      adapter.body = 23;
      expect(await remote.getNextQuotationNumber('PE', 'PE01'), 23);
      adapter.body = {'id': 21, 'tipoComprobante': 'CO'};
      await remote.createQuotation(Ticket(tipoComprobante: 'CO'));
      expect(adapter.requests.map((r) => '${r.method} ${r.path}'), [
        'POST /ticket-order',
        'PUT /ticket-order',
        'GET /ticket-order/next-number',
        'POST /quotation',
      ]);
      expect(adapter.requests.first.data['tipoPrecioCabeceraId'], 2);
      dio.close(force: true);
    },
  );
}
