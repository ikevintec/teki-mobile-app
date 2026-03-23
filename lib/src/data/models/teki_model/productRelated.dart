import 'package:teki_app/src/utils/formats.dart';

import 'product.dart';

class ProductRelated {
  final int? id;
  final Product? productoRelacionado;
  final bool? valorPorcentaje;
  final double? valorVenta;
  final String? codigoTipoAfectacionIgv;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  ProductRelated({
    this.id,
    this.productoRelacionado,
    this.valorPorcentaje,
    this.valorVenta,
    this.codigoTipoAfectacionIgv,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory ProductRelated.fromJson(Map<String, dynamic> json) => ProductRelated(
        id: json['id'],
        productoRelacionado: json['productoRelacionado'] != null
            ? Product.fromJson(json['productoRelacionado'])
            : null,
        valorPorcentaje: json['valorPorcentaje'],
        valorVenta: (json['valorVenta'] as num?)?.toDouble(),
        codigoTipoAfectacionIgv: json['codigoTipoAfectacionIgv'],
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
        'productoRelacionado': productoRelacionado?.toJson(),
        'valorPorcentaje': valorPorcentaje,
        'valorVenta': valorVenta,
        'codigoTipoAfectacionIgv': codigoTipoAfectacionIgv,
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
