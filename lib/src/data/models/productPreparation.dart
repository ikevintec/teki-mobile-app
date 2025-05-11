import 'package:teki_app/src/data/models/preparation.dart';
import 'package:teki_app/src/utils/formats.dart';

class ProductPreparation {
  int? id;
  Preparation? preparacion;
  bool? requerido;
  bool? modificado;
  bool? eliminado;
  DateTime? createdOn;
  int? createdBy;
  int? updatedBy;
  DateTime? updatedOn;
  int? deleteBy;
  DateTime? deletedOn;

  ProductPreparation({
    this.id,
    this.preparacion,
    this.requerido,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory ProductPreparation.fromJson(Map<String, dynamic> json) {
    return ProductPreparation(
      id: json['id'],
      preparacion: json['preparacion'] != null
          ? Preparation.fromJson(json['preparacion'])
          : null,
      requerido: json['requerido'],
      modificado: json['modificado'],
      eliminado: json['eliminado'],
      createdOn:parseDateTimeFlexible(json['createdOn']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      updatedOn:parseDateTimeFlexible(json['updatedOn']),
      deleteBy: json['deleteBy'],
      deletedOn:parseDateTimeFlexible(json['deletedOn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'preparacion': preparacion?.toJson(),
      'requerido': requerido,
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
}
