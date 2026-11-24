import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class Inventory {
  final int? id;
  final Office? puntoVenta;
  final Product? producto;
  final double? stock;
  final double? stockAnterior;
  final User? usuarioActualizacion;
  final DateTime? fechaActualizacion;
  final List<InventoryRecord>? registros;
  final List<BatchProduct>? lotes;
  final Company? empresa;

  Inventory({
    this.id,
    this.puntoVenta,
    this.producto,
    this.stock,
    this.stockAnterior,
    this.usuarioActualizacion,
    this.fechaActualizacion,
    this.registros,
    this.lotes,
    this.empresa,
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'],
      puntoVenta: json['puntoVenta'] != null
          ? Office.fromJson(json['puntoVenta'])
          : null,
      producto:
          json['producto'] != null ? Product.fromJson(json['producto']) : null,
      stock: (json['stock'] != null) ? (json['stock'] as num).toDouble() : null,
      stockAnterior: (json['stockAnterior'] != null)
          ? (json['stockAnterior'] as num).toDouble()
          : null,
      usuarioActualizacion: json['usuarioActualizacion'] != null
          ? User.fromJson(json['usuarioActualizacion'])
          : null,
      fechaActualizacion: json['fechaActualizacion'] != null
          ? parseDateTimeFlexible(json['fechaActualizacion'])

          : null,
      registros: json['registros'] != null
          ? List<InventoryRecord>.from(
              json['registros'].map((x) => InventoryRecord.fromJson(x)))
          : [],
      lotes: json['lotes'] != null
          ? List<BatchProduct>.from(
              json['lotes'].map((x) => BatchProduct.fromJson(x)))
          : [],
      empresa:
          json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'puntoVenta': puntoVenta?.toJson(),
      'producto': producto?.toJson(),
      'stock': stock,
      'stockAnterior': stockAnterior,
      'usuarioActualizacion': usuarioActualizacion?.toJson(),
      'fechaActualizacion': fechaActualizacion?.toIso8601String(),
      'registros':
          registros != null ? registros!.map((x) => x.toJson()).toList() : [],
      'lotes': lotes != null ? lotes!.map((x) => x.toJson()).toList() : [],
      'empresa': empresa?.toJson(),
    };
  }
}
