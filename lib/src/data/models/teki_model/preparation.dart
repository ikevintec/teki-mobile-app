import 'package:teki_app/src/data/models/teki_model/preparation_option.dart';

class Preparation {
  int? id;
  String? nombre;
  List<PreparationOption>? opciones;
  bool? modificado;
  bool? eliminado;
  DateTime? createdOn;
  int? createdBy;
  int? updatedBy;
  DateTime? updatedOn;
  int? deleteBy;
  DateTime? deletedOn;

  Preparation({
    this.id,
    this.nombre,
    this.opciones,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Preparation.fromJson(Map<String, dynamic> json) {
    return Preparation(
      id: json['id'],
      nombre: json['nombre'],
      opciones: json['opciones'] != null
          ? List<PreparationOption>.from(
              json['opciones'].map((x) => PreparationOption.fromJson(x)))
          : [],
      modificado: json['modificado'],
      eliminado: json['eliminado'],
      createdOn:
          json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      updatedOn:
          json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
      deleteBy: json['deleteBy'],
      deletedOn:
          json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'opciones': opciones?.map((x) => x.toJson()).toList(),
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
