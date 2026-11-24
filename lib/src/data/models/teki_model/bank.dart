import 'package:teki_app/src/data/models/teki_model/company.dart';

class Bank {
  final int? id;
  final String? nombre;
  final bool? estado;
  final Company? empresa;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Bank({
    this.id,
    this.nombre,
    this.estado,
    this.empresa,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Bank.fromJson(Map<String, dynamic> json) => Bank(
        id: json['id'],
        nombre: json['nombre'],
        estado: json['estado'],
        empresa: json['empresa'] != null
            ? Company.fromJson(json['empresa'])
            : null,
        createdOn: json['createdOn'] != null
            ? DateTime.parse(json['createdOn'])
            : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null
            ? DateTime.parse(json['updatedOn'])
            : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null
            ? DateTime.parse(json['deletedOn'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'estado': estado,
        'empresa': empresa?.toJson(),
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
