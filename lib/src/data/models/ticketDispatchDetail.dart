import 'package:teki_app/src/data/models/ticketDetail.dart';
import 'package:teki_app/src/data/models/ticketDispatch.dart';
import 'package:teki_app/src/data/models/user.dart';

class TicketDispatchDetail {
  final int? id;
  final DateTime? fechaDespacho;
  final DateTime? fechaAnulacionDespacho;
  final TicketDispatch? despacho;
  final TicketDetail? ticketDetail;
  final String? estado;
  final double? cantidad;
  final User? despachador;
  final User? despachadorAnulacion;
  final bool? anulacionDespacho;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  TicketDispatchDetail({
    this.id,
    this.fechaDespacho,
    this.fechaAnulacionDespacho,
    this.despacho,
    this.ticketDetail,
    this.estado,
    this.cantidad,
    this.despachador,
    this.despachadorAnulacion,
    this.anulacionDespacho,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory TicketDispatchDetail.fromJson(Map<String, dynamic> json) => TicketDispatchDetail(
        id: json['id'],
        fechaDespacho: json['fechaDespacho'] != null ? DateTime.parse(json['fechaDespacho']) : null,
        fechaAnulacionDespacho: json['fechaAnulacionDespacho'] != null ? DateTime.parse(json['fechaAnulacionDespacho']) : null,
        despacho: json['despacho'] != null ? TicketDispatch.fromJson(json['despacho']) : null,
        ticketDetail: json['ticketDetail'] != null ? TicketDetail.fromJson(json['ticketDetail']) : null,
        estado: json['estado'],
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        despachador: json['despachador'] != null ? User.fromJson(json['despachador']) : null,
        despachadorAnulacion: json['despachadorAnulacion'] != null ? User.fromJson(json['despachadorAnulacion']) : null,
        anulacionDespacho: json['anulacionDespacho'],
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
        'despacho': despacho?.toJson(),
        'ticketDetail': ticketDetail?.toJson(),
        'estado': estado,
        'cantidad': cantidad,
        'despachador': despachador?.toJson(),
        'despachadorAnulacion': despachadorAnulacion?.toJson(),
        'anulacionDespacho': anulacionDespacho,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
