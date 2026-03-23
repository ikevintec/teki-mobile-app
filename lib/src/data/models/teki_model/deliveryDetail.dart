import 'package:teki_app/src/data/models/teki_model/delivery.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';

class DeliveryDetail {
  final int? id;
  final Delivery? delivery;
  final OrderRestaurant? ordenRestaurante;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  DeliveryDetail({
    this.id,
    this.delivery,
    this.ordenRestaurante,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory DeliveryDetail.fromJson(Map<String, dynamic> json) => DeliveryDetail(
        id: json['id'],
        delivery: json['delivery'] != null ? Delivery.fromJson(json['delivery']) : null,
        ordenRestaurante: json['ordenRestaurante'] != null ? OrderRestaurant.fromJson(json['ordenRestaurante']) : null,
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
        'delivery': delivery?.toJson(),
        'ordenRestaurante': ordenRestaurante?.toJson(),
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
