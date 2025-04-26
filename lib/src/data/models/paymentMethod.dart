import 'package:teki_app/src/data/models/company.dart';

class PaymentMethod {
  final int? id;
  final String? formaPago;
  final String? tipoTarjeta;
  final String? nombre;
  final bool? online;
  final bool? requiereValidacion;
  final String? imagenUrl;
  final Company? empresa;
  final String? tipoMovimiento;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  PaymentMethod({
    this.id,
    this.formaPago,
    this.tipoTarjeta,
    this.nombre,
    this.online,
    this.requiereValidacion,
    this.imagenUrl,
    this.empresa,
    this.tipoMovimiento,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) => PaymentMethod(
        id: json['id'],
        formaPago: json['formaPago'],
        tipoTarjeta: json['tipoTarjeta'],
        nombre: json['nombre'],
        online: json['online'],
        requiereValidacion: json['requiereValidacion'],
        imagenUrl: json['imagenUrl'],
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        tipoMovimiento: json['tipoMovimiento'],
        modificado: json['modificado'],
        eliminado: json['eliminado'],
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'formaPago': formaPago,
        'tipoTarjeta': tipoTarjeta,
        'nombre': nombre,
        'online': online,
        'requiereValidacion': requiereValidacion,
        'imagenUrl': imagenUrl,
        'empresa': empresa?.toJson(),
        'tipoMovimiento': tipoMovimiento,
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
