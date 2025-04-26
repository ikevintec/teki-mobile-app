import 'package:teki_app/src/data/models/company.dart';
import 'package:teki_app/src/data/models/fileStorage.dart';

class TicketDesign {
  final int? id;
  final String? nombre;
  final String? tipoPdf; // Enum como string
  final String? formatoPlantilla; // Enum como string
  final bool? porDefecto;
  final FileStorage? jrxml;
  final FileStorage? jasper;
  final Company? empresa;
  final bool? estado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  TicketDesign({
    this.id,
    this.nombre,
    this.tipoPdf,
    this.formatoPlantilla,
    this.porDefecto,
    this.jrxml,
    this.jasper,
    this.empresa,
    this.estado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory TicketDesign.fromJson(Map<String, dynamic> json) => TicketDesign(
        id: json['id'],
        nombre: json['nombre'],
        tipoPdf: json['tipoPdf'],
        formatoPlantilla: json['formatoPlantilla'],
        porDefecto: json['porDefecto'],
        jrxml: json['jrxml'] != null ? FileStorage.fromJson(json['jrxml']) : null,
        jasper: json['jasper'] != null ? FileStorage.fromJson(json['jasper']) : null,
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        estado: json['estado'],
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipoPdf': tipoPdf,
        'formatoPlantilla': formatoPlantilla,
        'porDefecto': porDefecto,
        'jrxml': jrxml?.toJson(),
        'jasper': jasper?.toJson(),
        'empresa': empresa?.toJson(),
        'estado': estado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
