import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'pedidos_fixture.dart';

/// HTTP ficticio del contrato de borradores; no usa cuentas ni red externas.
class BorradoresPedidosAdapter extends PedidosAdapter {
  final List<Map<String, dynamic>> borradores = [];
  final Map<String, int> eliminados = {};
  Future<void> Function(RequestOptions)? antesEliminar;
  bool fallar = false, perderRespuestaEliminar = false;
  int eliminaciones = 0;

  BorradoresPedidosAdapter({int cantidad = 2}) {
    for (var i = 1; i <= cantidad; i++) {
      borradores.add({
        'id': 'borrador-prueba-${i.toString().padLeft(4, '0')}',
        'revision': 3,
        'idPuntoVenta': 1,
        'nombre': 'Borrador QA $i',
      });
    }
  }

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    if (o.path == '/ticket-order/gestion/borradores') {
      requests.add(o);
      final pagina = (o.queryParameters['pagina'] as num?)?.toInt() ?? 0;
      return respuesta({
        'content': borradores
            .where(
              (b) => b['idPuntoVenta'] == o.queryParameters['idPuntoVenta'],
            )
            .skip(pagina * 20)
            .take(20)
            .toList(),
      }, 200);
    }
    if (o.method == 'DELETE' &&
        o.path.startsWith('/ticket-order/gestion/borradores/')) {
      requests.add(o);
      eliminaciones++;
      await antesEliminar?.call(o);
      if (fallar) {
        return respuesta({'message': 'No pudimos eliminar el borrador.'}, 503);
      }
      final id = o.path.split('/').last;
      final revision = o.queryParameters['revision'];
      final actual = borradores.where((b) => b['id'] == id).firstOrNull;
      if (actual == null && eliminados[id] == revision) {
        return ResponseBody.fromString('', 204);
      }
      if (actual == null ||
          actual['revision'] != revision ||
          actual['idPuntoVenta'] != o.queryParameters['idPuntoVenta']) {
        return respuesta({
          'message': 'El borrador cambió. Actualiza la lista.',
        }, 409);
      }
      borradores.remove(actual);
      eliminados[id] = revision as int;
      if (perderRespuestaEliminar) {
        perderRespuestaEliminar = false;
        return respuesta({'message': 'Respuesta perdida; reintenta.'}, 503);
      }
      return ResponseBody.fromString('', 204);
    }
    return super.fetch(o, body, cancel);
  }

  ResponseBody respuesta(Object data, int status) => ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
