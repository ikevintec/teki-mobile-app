import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';

class Command {
  final int? id;
  final DateTime? fecha;
  final int? orden;
  final int? numeroComanda;
  final String? estadoComanda;
  final List<CommandDetail>? items;
  final OrderRestaurant? pedido;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  Command({
    this.id,
    this.fecha,
    this.orden,
    this.numeroComanda,
    this.estadoComanda,
    this.items,
    this.pedido,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory Command.fromJson(Map<String, dynamic> json) => Command(
        id: json['id'],
        fecha: json['fecha'] != null ? DateTime.parse(json['fecha']) : null,
        orden: json['orden'],
        numeroComanda: json['numeroComanda'],
        estadoComanda: json['estadoComanda'],
        items: json['items'] != null
            ? List<CommandDetail>.from(json['items'].map((x) => CommandDetail.fromJson(x)))
            : null,
        pedido: json['pedido'] != null ? OrderRestaurant.fromJson(json['pedido']) : null,
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
        'orden': orden,
        'numeroComanda': numeroComanda,
        'estadoComanda': estadoComanda,
        'items': items?.map((x) => x.toJson()).toList(),
        'pedido': pedido?.toJson(),
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
