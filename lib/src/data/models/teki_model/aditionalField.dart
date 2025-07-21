import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/formats.dart';

class AditionalField {
  final int? id;
  final String? valorCampo;
  final String? nombreCampo;
  final Ticket? ticket;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  AditionalField({
    this.id,
    this.valorCampo,
    this.nombreCampo,
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

  factory AditionalField.fromJson(Map<String, dynamic> json) => AditionalField(
        id: json['id'],
        valorCampo: json['valorCampo'],
        nombreCampo: json['nombreCampo'],
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
        'valorCampo': valorCampo,
        'nombreCampo': nombreCampo,
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

  AditionalField copyWith({
    int? id,
    String? valorCampo,
    String? nombreCampo,
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
    return AditionalField(
      id: id ?? this.id,
      valorCampo: valorCampo ?? this.valorCampo,
      nombreCampo: nombreCampo ?? this.nombreCampo,
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
