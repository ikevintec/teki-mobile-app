import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/utils/formats.dart';

class Lounge {
  final int? id;
  final String? nombre;
  final Company? empresa;
  final Office? puntoVenta;
  final Printer? impresoraCuentaRestaurante;
  final bool? estado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Lounge({
    this.id,
    this.nombre,
    this.empresa,
    this.puntoVenta,
    this.impresoraCuentaRestaurante,
    this.estado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Lounge.fromJson(Map<String, dynamic> json) => Lounge(
        id: json['id'],
        nombre: json['nombre'],
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
        impresoraCuentaRestaurante: json['impresoraCuentaRestaurante'] != null
            ? Printer.fromJson(json['impresoraCuentaRestaurante'])
            : null,
        estado: json['estado'],
        createdOn: json['createdOn'] != null ? parseDateTimeFlexible(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? parseDateTimeFlexible(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? parseDateTimeFlexible(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'empresa': empresa?.toJson(),
        'puntoVenta': puntoVenta?.toJson(),
        'impresoraCuentaRestaurante': impresoraCuentaRestaurante?.toJson(),
        'estado': estado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
