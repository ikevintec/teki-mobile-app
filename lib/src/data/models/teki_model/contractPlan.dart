import 'package:teki_app/src/utils/formats.dart';

class ContractPlan {
  final int? id;
  final String? nombre;
  final String? url;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  ContractPlan({
    this.id,
    this.nombre,
    this.url,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory ContractPlan.fromJson(Map<String, dynamic> json) => ContractPlan(
        id: json['id'],
        nombre: json['nombre'],
        url: json['url'],
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
        'nombre': nombre,
        'url': url,
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
