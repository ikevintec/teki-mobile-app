import 'package:teki_app/src/data/models/teki_model/inventory.dart';

/// Respuesta de `/inventory/operations/by-product-ids`.
/// Relaciona el id de un producto con su inventario en un punto de venta.
class ProductInventory {
  /// Id del producto.
  final int? id;
  final Inventory? inventario;

  ProductInventory({this.id, this.inventario});

  factory ProductInventory.fromJson(Map<String, dynamic> json) =>
      ProductInventory(
        id: json['id'],
        inventario: json['inventario'] != null
            ? Inventory.fromJson(json['inventario'])
            : null,
      );
}
