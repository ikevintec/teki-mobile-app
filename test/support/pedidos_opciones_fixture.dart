import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'pedidos_fixture.dart';

class PedidosOpcionesAdapter extends PedidosAdapter {
  bool comercial = true,
      sinPrecio = false,
      clienteDni = false,
      fallarConfig = false,
      fallarPromos = false,
      fallarBorrador = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    Object? resultado;
    final error =
        (fallarConfig && o.path == '/distribuidor/configuracion') ||
        (fallarPromos && o.path == '/distribuidor/promociones/evaluar') ||
        (fallarBorrador &&
            o.path.contains('/borradores/') &&
            o.method == 'PUT');
    if (error) {
      requests.add(o);
      return ResponseBody.fromString(
        '{"mensaje":"Error QA recuperable"}',
        503,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    if (!comercial && o.path == '/distribuidor/configuracion') {
      resultado = {'preciosComerciales': false};
    } else if (o.path == '/products') {
      final ligero = {...PedidosAdapter.product}..remove('igv');
      resultado = {
        'content': [ligero],
      };
    } else if (!comercial && o.path == '/products/1') {
      resultado = {
        ...PedidosAdapter.product,
        'preciosVenta': [
          {'id': 1, 'tipoPrecio': 'POR_DEFECTO', 'precio': 6.0},
          {
            'id': 2,
            'tipoPrecio': 'MAYOREO',
            'precio': 5.5,
            'unidadesMayoreo': 10.0,
          },
        ],
      };
    } else if (sinPrecio && o.path == '/products/1') {
      resultado = {...PedidosAdapter.product, 'preciosVenta': []};
    } else if (clienteDni && o.path == '/customers') {
      resultado = [
        {
          'id': 1,
          'razonSocial': 'Cliente DNI QA',
          'numeroDocumento': '12345678',
          'tipoDocumento': '1',
        },
      ];
    }
    if (resultado == null) return super.fetch(o, body, cancel);
    requests.add(o);
    return ResponseBody.fromString(
      jsonEncode(resultado),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
