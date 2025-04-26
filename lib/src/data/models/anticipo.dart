import 'package:teki_app/src/data/models/ticket.dart';

class Anticipo {
  final int? id;
  final String? serie;
  final int? numero;
  final String? tipoComprobante;
  final double? total;
  final double? valorVenta;
  final Ticket? ticket;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Anticipo({
    this.id,
    this.serie,
    this.numero,
    this.tipoComprobante,
    this.total,
    this.valorVenta,
    this.ticket,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Anticipo.fromJson(Map<String, dynamic> json) => Anticipo(
        id: json['id'],
        serie: json['serie'],
        numero: json['numero'],
        tipoComprobante: json['tipoComprobante'],
        total: (json['total'] as num?)?.toDouble(),
        valorVenta: (json['valorVenta'] as num?)?.toDouble(),
        ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
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
        'serie': serie,
        'numero': numero,
        'tipoComprobante': tipoComprobante,
        'total': total,
        'valorVenta': valorVenta,
        'ticket': ticket?.toJson(),
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
