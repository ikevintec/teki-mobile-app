import 'package:teki_app/src/data/models/teki_model/fileStorage.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/utils/formats.dart';

class TicketFile {
  final int? id;
  final String? tipoArchivo;
  final String? estadoArchivo;
  final FileStorage? fileStorage;
  final Ticket? ticket;
  final int? orden;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  TicketFile({
    this.id,
    this.tipoArchivo,
    this.estadoArchivo,
    this.fileStorage,
    this.ticket,
    this.orden,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory TicketFile.fromJson(Map<String, dynamic> json) => TicketFile(
        id: json['id'],
        tipoArchivo: json['tipoArchivo'],
        estadoArchivo: json['estadoArchivo'],
        fileStorage: json['fileStorage'] != null ? FileStorage.fromJson(json['fileStorage']) : null,
        ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
        orden: json['orden'],
        modificado: json['modificado'],
        eliminado: json['eliminado'],
        createdOn: json['createdOn'] != null ? parseDateTimeFlexible(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? parseDateTimeFlexible(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? parseDateTimeFlexible(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipoArchivo': tipoArchivo,
        'estadoArchivo': estadoArchivo,
        'fileStorage': fileStorage?.toJson(),
        'ticket': ticket?.toJson(),
        'orden': orden,
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
