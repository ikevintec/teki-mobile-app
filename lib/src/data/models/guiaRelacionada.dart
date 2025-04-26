import 'package:teki_app/src/data/models/ticket.dart';

class GuiaRelacionada {
  final int? id;
  final String? codigoTipoGuia;
  final String? serieNumeroGuia;
  final Ticket? ticket;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  GuiaRelacionada({
    this.id,
    this.codigoTipoGuia,
    this.serieNumeroGuia,
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

  factory GuiaRelacionada.fromJson(Map<String, dynamic> json) => GuiaRelacionada(
        id: json['id'],
        codigoTipoGuia: json['codigoTipoGuia'],
        serieNumeroGuia: json['serieNumeroGuia'],
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
        'codigoTipoGuia': codigoTipoGuia,
        'serieNumeroGuia': serieNumeroGuia,
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
