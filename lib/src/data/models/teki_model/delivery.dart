import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/deliveryDetail.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';

class Delivery {
  final int? id;
  final DateTime? fechaCreacion;
  final DateTime? fechaEnvio;
  final DateTime? fechaEntrega;
  final String? estado;
  final User? repartidor;
  final Company? empresa;
  final Office? puntoVenta;
  final double? montoCambio;
  final List<DeliveryDetail>? items;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Delivery({
    this.id,
    this.fechaCreacion,
    this.fechaEnvio,
    this.fechaEntrega,
    this.estado,
    this.repartidor,
    this.empresa,
    this.puntoVenta,
    this.montoCambio,
    this.items,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) => Delivery(
    id: json['id'],
    fechaCreacion: json['fechaCreacion'] != null ? DateTime.parse(json['fechaCreacion']) : null,
    fechaEnvio: json['fechaEnvio'] != null ? DateTime.parse(json['fechaEnvio']) : null,
    fechaEntrega: json['fechaEntrega'] != null ? DateTime.parse(json['fechaEntrega']) : null,
    estado: json['estado'],
    repartidor: json['repartidor'] != null ? User.fromJson(json['repartidor']) : null,
    empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
    montoCambio: json['montoCambio'],
    items: json['items'] != null ? List<DeliveryDetail>.from(json['items'].map((x) => DeliveryDetail.fromJson(x))) : null,
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
    'fechaCreacion': fechaCreacion?.toIso8601String(),
    'fechaEnvio': fechaEnvio?.toIso8601String(),
    'fechaEntrega': fechaEntrega?.toIso8601String(),
    'estado': estado,
    'repartidor': repartidor?.toJson(),
    'empresa': empresa?.toJson(),
    'puntoVenta': puntoVenta?.toJson(),
    'montoCambio': montoCambio,
    'items': items?.map((x) => x.toJson()).toList(),
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
