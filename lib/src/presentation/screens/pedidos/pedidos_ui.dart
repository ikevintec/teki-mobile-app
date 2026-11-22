import 'package:dio/dio.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/data/services/distribuidor/pedidos_service.dart';

String mensajePedido(Object e) {
  if (e is DioException && e.response?.data is Map) {
    final data = e.response!.data as Map;
    return '${data['mensaje'] ?? data['message'] ?? 'No se pudo completar la operación.'}';
  }
  return e is StateError
      ? e.message.toString()
      : 'No se pudo completar la operación. Conservamos tu pedido; vuelve a intentarlo.';
}

String estadoPedido(Map<String, dynamic> p) =>
    const {
      'ENVIADO': 'Enviado',
      'EN_ATENCION': 'En atención',
      'CONVERTIDO': 'Convertido en venta',
      'ANULADO': 'Anulado',
      'ANULADA': 'Anulado',
      'PENDIENTE': 'Pendiente',
      'CONCRETADA': 'Convertido en venta',
    }[p['estadoPedido'] ?? p['estadoCotizacion']] ??
    'Pendiente';

PedidosService servicioPedidos(SesionState s) =>
    PedidosService(s.claveContexto);
