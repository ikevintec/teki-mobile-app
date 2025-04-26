import 'package:teki_app/src/data/models/commandDetail.dart';
import 'package:teki_app/src/data/models/cutomer.dart';
import 'package:teki_app/src/data/models/orderRestaurant.dart';
import 'package:teki_app/src/data/models/ticket.dart';

class Check {
  final int? id;
  final DateTime? fecha;
  final List<CommandDetail>? items;
  final OrderRestaurant? pedido;
  final Customer? cliente;
  final Ticket? comprobante;
  final bool? pagado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Check({
    this.id,
    this.fecha,
    this.items,
    this.pedido,
    this.cliente,
    this.comprobante,
    this.pagado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Check.fromJson(Map<String, dynamic> json) => Check(
        id: json['id'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
        items: json['items'] != null
            ? List<CommandDetail>.from(json['items'].map((x) => CommandDetail.fromJson(x)))
            : null,
        pedido: json['pedido'] != null ? OrderRestaurant.fromJson(json['pedido']) : null,
        cliente: json['cliente'] != null ? Customer.fromJson(json['cliente']) : null,
        comprobante: json['comprobante'] != null ? Ticket.fromJson(json['comprobante']) : null,
        pagado: json['pagado'],
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
        'fecha': fecha?.toIso8601String(),
        'items': items?.map((x) => x.toJson()).toList(),
        'pedido': pedido?.toJson(),
        'cliente': cliente?.toJson(),
        'comprobante': comprobante?.toJson(),
        'pagado': pagado,
        'eliminado': eliminado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
