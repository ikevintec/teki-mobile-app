import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/formats.dart';

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

  factory GuiaRelacionada.fromJson(Map<String, dynamic> json) =>
      GuiaRelacionada(
        id: json['id'],
        codigoTipoGuia: json['codigoTipoGuia'],
        serieNumeroGuia: json['serieNumeroGuia'],
        ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
        modificado: json['modificado'],
        eliminado: json['eliminado'],
        createdOn: json['createdOn'] != null
            ? parseDateTimeFlexible(json['createdOn'])
            : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null
            ? parseDateTimeFlexible(json['updatedOn'])
            : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null
            ? parseDateTimeFlexible(json['deletedOn'])
            : null,
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
      
  GuiaRelacionada copyWith({
    int? id,
    String? codigoTipoGuia,
    String? serieNumeroGuia,
    Ticket? ticket,
    bool? modificado,
    bool? eliminado,
    DateTime? createdOn,
    int? createdBy,
    int? updatedBy,
    DateTime? updatedOn,
    int? deleteBy,
    DateTime? deletedOn,
  }) {
    return GuiaRelacionada(
      id: id ?? this.id,
      codigoTipoGuia: codigoTipoGuia ?? this.codigoTipoGuia,
      serieNumeroGuia: serieNumeroGuia ?? this.serieNumeroGuia,
      ticket: ticket ?? this.ticket,
      modificado: modificado ?? this.modificado,
      eliminado: eliminado ?? this.eliminado,
      createdOn: createdOn ?? this.createdOn,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedOn: updatedOn ?? this.updatedOn,
      deleteBy: deleteBy ?? this.deleteBy,
      deletedOn: deletedOn ?? this.deletedOn,
    );
  }
}
