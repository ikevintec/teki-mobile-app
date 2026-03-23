import 'package:teki_app/src/data/models/teki_model/inventory_adjustment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class InventoryAdjustment {
  final int? id;
  final Office? puntoVenta;
  final User? usuario;
  final DateTime? fecha;
  final String? estadoAjuste;
  final String? motivo;
  final String? observacion;
  final List<InventoryAdjustmentDetail>? items;

  InventoryAdjustment({
    this.id,
    this.puntoVenta,
    this.usuario,
    this.fecha,
    this.estadoAjuste,
    this.motivo,
    this.observacion,
    this.items,
  });

  factory InventoryAdjustment.fromJson(Map<String, dynamic> json) =>
      InventoryAdjustment(
        id: json['id'],
        puntoVenta: json['puntoVenta'] != null
            ? Office.fromJson(json['puntoVenta'])
            : null,
        usuario:
            json['usuario'] != null ? User.fromJson(json['usuario']) : null,
        fecha: parseDateTimeFlexible(json['fecha']),
        estadoAjuste: json['estadoAjuste'],
        motivo: json['motivo'],
        observacion: json['observacion'],
        items: (json['items'] as List?)
            ?.map((e) => InventoryAdjustmentDetail.fromJson(e))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (puntoVenta?.id != null) 'puntoVenta': {'id': puntoVenta!.id},
        if (usuario != null) 'usuario': usuario!.toJson(),
        if (fecha != null) 'fecha': fecha!.toIso8601String(),
        if (estadoAjuste != null) 'estadoAjuste': estadoAjuste,
        if (motivo != null && motivo!.isNotEmpty) 'motivo': motivo,
        if (observacion != null && observacion!.isNotEmpty)
          'observacion': observacion,
        if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
      };

  InventoryAdjustment copyWith({
    int? id,
    Office? puntoVenta,
    User? usuario,
    DateTime? fecha,
    String? estadoAjuste,
    String? motivo,
    String? observacion,
    List<InventoryAdjustmentDetail>? items,
  }) =>
      InventoryAdjustment(
        id: id ?? this.id,
        puntoVenta: puntoVenta ?? this.puntoVenta,
        usuario: usuario ?? this.usuario,
        fecha: fecha ?? this.fecha,
        estadoAjuste: estadoAjuste ?? this.estadoAjuste,
        motivo: motivo ?? this.motivo,
        observacion: observacion ?? this.observacion,
        items: items ?? this.items,
      );
}
