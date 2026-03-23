import 'package:teki_app/src/data/models/teki_model/batchProduct.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';

class BatchProductSale {
  final int? id;
  final BatchProduct? lote;
  final TicketDetail? item;
  final double? cantidad;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  BatchProductSale({
    this.id,
    this.lote,
    this.item,
    this.cantidad,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory BatchProductSale.fromJson(Map<String, dynamic> json) => BatchProductSale(
        id: json['id'],
        lote: json['lote'] != null ? BatchProduct.fromJson(json['lote']) : null,
        item: json['item'] != null ? TicketDetail.fromJson(json['item']) : null,
        cantidad: (json['cantidad'] as num?)?.toDouble(),
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
        'lote': lote?.toJson(),
        'item': item?.toJson(),
        'cantidad': cantidad,
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
