import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class Table {
  final int? id;
  final int? numero;
  final Company? empresa;
  final Lounge? salon;
  final bool? multiMesa;
  final bool? mesaUnida;
  final DateTime? fechaUnion;
  final User? unidoPor;
  final DateTime? fechaSeparacion;
  final User? separadoPor;
  final Table? mesaConformada;
  final List<Table>? mesasUnidas;
  final String? mesasUnidasHistorico;
  final bool? estado;
  final OrderRestaurant? pedidoActual;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Table({
    this.id,
    this.numero,
    this.empresa,
    this.salon,
    this.multiMesa,
    this.mesaUnida,
    this.fechaUnion,
    this.unidoPor,
    this.fechaSeparacion,
    this.separadoPor,
    this.mesaConformada,
    this.mesasUnidas,
    this.mesasUnidasHistorico,
    this.estado,
    this.pedidoActual,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Table.fromJson(Map<String, dynamic> json) => Table(
        id: json['id'],
        numero: json['numero'],
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        salon: json['salon'] != null ? Lounge.fromJson(json['salon']) : null,
        multiMesa: json['multiMesa'],
        mesaUnida: json['mesaUnida'],
        fechaUnion: json['fechaUnion'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaUnion'])) : null,
        unidoPor: json['unidoPor'] != null ? User.fromJson(json['unidoPor']) : null,
        fechaSeparacion: json['fechaSeparacion'] != null ? parseDateTimeFlexible(DateTime.parse(json['fechaSeparacion'])) : null,
        separadoPor: json['separadoPor'] != null ? User.fromJson(json['separadoPor']) : null,
        mesaConformada: json['mesaConformada'] != null ? Table.fromJson(json['mesaConformada']) : null,
        mesasUnidas: json['mesasUnidas'] != null
            ? List<Table>.from(json['mesasUnidas'].map((x) => Table.fromJson(x)))
            : null,
        mesasUnidasHistorico: json['mesasUnidasHistorico'],
        estado: json['estado'],
        pedidoActual: json['pedidoActual'] != null ? OrderRestaurant.fromJson(json['pedidoActual']) : null,
        createdOn: json['createdOn'] != null ? parseDateTimeFlexible(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? parseDateTimeFlexible(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? parseDateTimeFlexible(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'numero': numero,
        'empresa': empresa?.toJson(),
        'salon': salon?.toJson(),
        'multiMesa': multiMesa,
        'mesaUnida': mesaUnida,
        'fechaUnion': fechaUnion?.toIso8601String(),
        'unidoPor': unidoPor?.toJson(),
        'fechaSeparacion': fechaSeparacion?.toIso8601String(),
        'separadoPor': separadoPor?.toJson(),
        'mesaConformada': mesaConformada?.toJson(),
        'mesasUnidas': mesasUnidas?.map((x) => x.toJson()).toList(),
        'mesasUnidasHistorico': mesasUnidasHistorico,
        'estado': estado,
        'pedidoActual': pedidoActual?.toJson(),
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
