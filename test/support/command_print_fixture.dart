import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';

Map<String, dynamic> commandPrintArea(
  int id,
  String printer, {
  int office = 1,
  String mode = 'PDF',
}) => {
  'id': id,
  'nombre': 'Área QA $id',
  'impresoras': [
    {
      'id': id,
      'nombre': printer,
      'tipoImpresora': 'TICKETERA',
      'tipoImpresion': mode,
      'codigoCoffe': printer,
      'puntoVenta': {'id': office},
    },
  ],
};
Map<String, dynamic> commandPrintProduct(
  int id,
  int area,
  String printer, {
  int office = 1,
  String mode = 'PDF',
}) => {
  'id': id,
  'nombre': 'Producto QA $id',
  'tipoProducto': 'ARTICULO',
  'categoria': {
    'id': area,
    'nombre': 'Categoría QA',
    'areaProduccion': commandPrintArea(
      area,
      printer,
      office: office,
      mode: mode,
    ),
  },
};

/// Todas las solicitudes se interceptan. Nunca conecta con impresoras reales.
class CommandPrintFixtureAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final jobs = <Map<String, dynamic>>[];
  final failPrinters = <String>{};
  final offlinePrinters = <String>{};
  bool failCommand = false;
  Future<void>? printGate;
  late List<Map<String, dynamic>> items = [
    for (final p in [
      commandPrintProduct(1, 1, 'COCINA'),
      commandPrintProduct(2, 2, 'BAR'),
      commandPrintProduct(3, 1, 'COCINA'),
      commandPrintProduct(4, 3, 'OTRA_SEDE', office: 2),
    ])
      {'id': p['id'], 'cantidad': 1.0, 'precioVenta': 10.0, 'producto': p},
  ];
  Map<String, dynamic> get command => {'id': 501, 'items': items};
  ResponseBody response(Object body, [int status = 200]) =>
      ResponseBody.fromString(
        jsonEncode(body),
        status,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    if (o.path == '/commands/501') {
      return response(
        failCommand ? {'message': 'Error de comanda QA'} : command,
        failCommand ? 503 : 200,
      );
    }
    if (o.path == '/ticket-esc-pos/command/501') {
      return response({
        'orden': '101',
        'zona': 'Área QA ${o.queryParameters['idArea']}',
        'nombreCliente': 'Cliente QA',
        'items': [
          {'producto': 'Producto QA', 'cantidad': '1'},
        ],
      });
    }
    if (o.path.endsWith('/print-coffe') && o.method == 'POST') {
      final job = Map<String, dynamic>.from(o.data as Map);
      jobs.add(job);
      if (printGate != null) await printGate;
      if (failPrinters.contains(job['printerName'])) {
        return response({'message': 'Impresora QA sin conexión'}, 503);
      }
      if (offlinePrinters.contains(job['printerName'])) {
        return response({
          'printed': false,
          'message': 'Agente QA no disponible',
        });
      }
      return response({'printed': true});
    }
    throw StateError('Contrato QA inesperado: ${o.method} ${o.path}');
  }

  @override
  void close({bool force = false}) {}
}
