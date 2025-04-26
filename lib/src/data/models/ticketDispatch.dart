import 'package:teki_app/src/data/models/ticket.dart';
import 'package:teki_app/src/data/models/ticketDispatchDetail.dart';
import 'package:teki_app/src/data/models/user.dart';

class TicketDispatch {
  final int? id;
  final DateTime? fechaDespacho;
  final DateTime? fechaAnulacionDespacho;
  final Ticket? ticket;
  final User? despachador;
  final User? despachadorAnulacion;
  final List<TicketDispatchDetail>? despachos;
  final String? estado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  TicketDispatch({
    this.id,
    this.fechaDespacho,
    this.fechaAnulacionDespacho,
    this.ticket,
    this.despachador,
    this.despachadorAnulacion,
    this.despachos,
    this.estado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory TicketDispatch.fromJson(Map<String, dynamic> json) => TicketDispatch(
        id: json['id'],
        fechaDespacho: json['fechaDespacho'] != null ? DateTime.parse(json['fechaDespacho']) : null,
        fechaAnulacionDespacho: json['fechaAnulacionDespacho'] != null ? DateTime.parse(json['fechaAnulacionDespacho']) : null,
        ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
        despachador: json['despachador'] != null ? User.fromJson(json['despachador']) : null,
        despachadorAnulacion: json['despachadorAnulacion'] != null ? User.fromJson(json['despachadorAnulacion']) : null,
        despachos: json['despachos'] != null
            ? List<TicketDispatchDetail>.from(json['despachos'].map((x) => TicketDispatchDetail.fromJson(x)))
            : null,
        estado: json['estado'],
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'fechaDespacho': fechaDespacho?.toIso8601String(),
        'fechaAnulacionDespacho': fechaAnulacionDespacho?.toIso8601String(),
        'ticket': ticket?.toJson(),
        'despachador': despachador?.toJson(),
        'despachadorAnulacion': despachadorAnulacion?.toJson(),
        'despachos': despachos?.map((x) => x.toJson()).toList(),
        'estado': estado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
