import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class InventoryRecord {
  final int? id;
  final double? cantidad;
  final double? cantidadAnterior;
  final double? cantidadActual;
  final String? tipo; // TipoMovimientoInventario
  final String? concepto; // ConceptoMovimientoInventario
  final String? detalle;
  final DateTime? fecha;
  final User? responsable;
  final int? pedidoOrigenId, revisionPedidoOrigen;
  final String? pedidoOrigenNumero, eventoPedido, ventaPedidoNumero;

  String? get trazabilidadPedido {
    if (pedidoOrigenId == null) return null;
    final evento = const {
      'RESERVA': 'Reserva',
      'AJUSTE_RESERVA': 'Reserva ajustada',
      'LIBERACION': 'Reserva liberada',
      'CONVERSION': 'Reserva al convertir',
      'MOVIMIENTO_VENTA': 'Movimiento de venta',
    }[eventoPedido];
    return [
      'Pedido ${pedidoOrigenNumero ?? pedidoOrigenId}',
      if (revisionPedidoOrigen != null) 'rev. $revisionPedidoOrigen',
      if (evento != null) evento,
      if (ventaPedidoNumero != null) 'Conversión: $ventaPedidoNumero',
    ].join(' · ');
  }

  InventoryRecord({
    this.id,
    this.cantidad,
    this.cantidadAnterior,
    this.cantidadActual,
    this.tipo,
    this.concepto,
    this.detalle,
    this.fecha,
    this.responsable,
    this.pedidoOrigenId,
    this.revisionPedidoOrigen,
    this.pedidoOrigenNumero,
    this.eventoPedido,
    this.ventaPedidoNumero,
  });

  factory InventoryRecord.fromJson(
    Map<String, dynamic> json,
  ) => InventoryRecord(
    pedidoOrigenId: (json['pedidoOrigenId'] as num?)?.toInt(),
    revisionPedidoOrigen: (json['revisionPedidoOrigen'] as num?)?.toInt(),
    pedidoOrigenNumero: json['pedidoOrigenNumero'],
    eventoPedido: json['eventoPedido'],
    ventaPedidoNumero: json['ventaPedido'] == null
        ? null
        : '${json['ventaPedido']['serie']}-${json['ventaPedido']['numero']}',
    id: json['id'],
    cantidad: (json['cantidad'] as num?)?.toDouble(),
    cantidadAnterior: (json['cantidadAnterior'] as num?)?.toDouble(),
    cantidadActual: (json['cantidadActual'] as num?)?.toDouble(),
    tipo: json['tipo'],
    concepto: json['concepto'],
    detalle: json['detalle'],
    fecha: json['fecha'] != null ? parseDateTimeFlexible(json['fecha']) : null,
    responsable: json['responsable'] != null
        ? User.fromJson(json['responsable'])
        : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cantidad': cantidad,
    'cantidadAnterior': cantidadAnterior,
    'cantidadActual': cantidadActual,
    'tipo': tipo,
    'concepto': concepto,
    'detalle': detalle,
    'fecha': fecha?.toIso8601String(),
    'responsable': responsable?.toJson(),
  };
}
