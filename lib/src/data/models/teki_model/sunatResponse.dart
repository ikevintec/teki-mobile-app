
import 'package:teki_app/src/data/models/teki_model/ticket.dart';

class SunatResponse {
  final int? id;
  final String? tramaResponse;
  final String? codigoRespuesta;
  final String? mensajeRespuesta;
  final String? estadoSunat;
  final Ticket? ticket;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  SunatResponse({
    this.id,
    this.tramaResponse,
    this.codigoRespuesta,
    this.mensajeRespuesta,
    this.estadoSunat,
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

  factory SunatResponse.fromJson(Map<String, dynamic> json) => SunatResponse(
        id: json['id'],
        tramaResponse: json['tramaResponse'],
        codigoRespuesta: json['codigoRespuesta'],
        mensajeRespuesta: json['mensajeRespuesta'],
        estadoSunat: json['estadoSunat'],
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
        'tramaResponse': tramaResponse,
        'codigoRespuesta': codigoRespuesta,
        'mensajeRespuesta': mensajeRespuesta,
        'estadoSunat': estadoSunat,
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
