import 'package:teki_app/src/data/models/accountReceivable.dart';
import 'package:teki_app/src/data/models/ticket.dart';

class TicketFee {
  final int? id;
  final int? numero;
  final DateTime? fecha;
  final DateTime? fechaPago;
  final double? monto;
  final Ticket? ticket;
  final AccountsReceivable? accountReceivable;
  final String? estadoCredito;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  TicketFee({
    this.id,
    this.numero,
    this.fecha,
    this.fechaPago,
    this.monto,
    this.ticket,
    this.accountReceivable,
    this.estadoCredito,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory TicketFee.fromJson(Map<String, dynamic> json) => TicketFee(
        id: json['id'],
        numero: json['numero'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
        fechaPago: json['fechaPago'] != null ? DateTime.parse(json['fechaPago']) : null,
        monto: (json['monto'] as num?)?.toDouble(),
        ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
        accountReceivable: json['accountReceivable'] != null
            ? AccountsReceivable.fromJson(json['accountReceivable'])
            : null,
        estadoCredito: json['estadoCredito'],
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
        'numero': numero,
        'fecha': fecha?.toIso8601String(),
        'fechaPago': fechaPago?.toIso8601String(),
        'monto': monto,
        'ticket': ticket?.toJson(),
        'accountReceivable': accountReceivable?.toJson(),
        'estadoCredito': estadoCredito,
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
