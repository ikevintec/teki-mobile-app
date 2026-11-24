import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/purchase_detail.dart';

class BatchProductPurchase {
  final int? id;
  final BatchProduct? lote;
  final PurchaseDetail? item;
  final double? cantidad;
  final bool? modificado;
  final bool? eliminado;

  BatchProductPurchase({
    this.id,
    this.lote,
    this.item,
    this.cantidad,
    this.modificado,
    this.eliminado,
  });

  factory BatchProductPurchase.fromJson(Map<String, dynamic> json) => BatchProductPurchase(
    id: json['id'],
    lote: json['lote'] != null ? BatchProduct.fromJson(json['lote']) : null,
    item: json['item'] != null ? PurchaseDetail.fromJson(json['item']) : null,
    cantidad: (json['cantidad'] as num?)?.toDouble(),
    modificado: json['modificado'],
    eliminado: json['eliminado'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'lote': lote?.toJson(),
    'item': item?.toJson(),
    'cantidad': cantidad,
    'modificado': modificado,
    'eliminado': eliminado,
  };
}