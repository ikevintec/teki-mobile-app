import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductSupply {
  final int? id;
  final Product? productoInsumo;
  final double? cantidad;
  final double? porcion;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  ProductSupply({
    this.id,
    this.productoInsumo,
    this.cantidad,
    this.porcion,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory ProductSupply.fromJson(Map<String, dynamic> json) => ProductSupply(
        id: json['id'],
        productoInsumo: json['productoInsumo'] != null
            ? Product.fromJson(json['productoInsumo'])
            : null,
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        porcion: (json['porcion'] as num?)?.toDouble(),
        modificado: json['modificado'],
        eliminado: json['eliminado'],
        createdOn: parseDateTimeFlexible(json['createdOn']),
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: parseDateTimeFlexible(json['updatedOn']),
        deleteBy: json['deleteBy'],
        deletedOn: parseDateTimeFlexible(json['deletedOn']),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productoInsumo': productoInsumo?.toJson(),
        'cantidad': cantidad,
        'porcion': porcion,
        'modificado': modificado,
        'eliminado': eliminado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
