import 'package:teki_app/src/data/models/user.dart';

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
  });

  factory InventoryRecord.fromJson(Map<String, dynamic> json) => InventoryRecord(
        id: json['id'],
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        cantidadAnterior: (json['cantidadAnterior'] as num?)?.toDouble(),
        cantidadActual: (json['cantidadActual'] as num?)?.toDouble(),
        tipo: json['tipo'],
        concepto: json['concepto'],
        detalle: json['detalle'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
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
