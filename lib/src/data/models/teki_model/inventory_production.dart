import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

/// Orden de producción de inventario (GET /api/inventory-productions).
/// Al registrarse consume los items de la receta (paqueteItems) y da de alta
/// el producto terminado.
class InventoryProduction {
  final int? id;
  final int? numero;
  final DateTime? fecha;
  final DateTime? fechaAnulacion;
  final String? observacion;
  final Office? puntoVenta;
  final User? usuario;
  final bool? anulado;
  final List<InventoryProductionDetail> producciones;

  InventoryProduction({
    this.id,
    this.numero,
    this.fecha,
    this.fechaAnulacion,
    this.observacion,
    this.puntoVenta,
    this.usuario,
    this.anulado,
    this.producciones = const [],
  });

  factory InventoryProduction.fromJson(Map<String, dynamic> json) =>
      InventoryProduction(
        id: json['id'],
        numero: json['numero'],
        fecha: parseDateTimeFlexible(json['fecha']),
        fechaAnulacion: parseDateTimeFlexible(json['fechaAnulacion']),
        observacion: json['observacion'],
        puntoVenta:
            json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
        usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
        anulado: json['anulado'],
        producciones: json['producciones'] != null
            ? List<InventoryProductionDetail>.from((json['producciones'] as List)
                .map((x) => InventoryProductionDetail.fromJson(x)))
            : const [],
      );
}

/// Línea de una orden de producción: el producto terminado y la cantidad.
class InventoryProductionDetail {
  final int? id;
  final double? cantidad;
  final double? cantidadAlternativa;
  final Product? producto;

  InventoryProductionDetail({
    this.id,
    this.cantidad,
    this.cantidadAlternativa,
    this.producto,
  });

  factory InventoryProductionDetail.fromJson(Map<String, dynamic> json) =>
      InventoryProductionDetail(
        id: json['id'],
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        cantidadAlternativa: (json['cantidadAlternativa'] as num?)?.toDouble(),
        producto:
            json['producto'] != null ? Product.fromJson(json['producto']) : null,
      );
}
