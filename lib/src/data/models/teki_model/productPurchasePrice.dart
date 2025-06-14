

import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';

class ProductPurchasePrice {
  final int? id;
  final double? precio;
  final Supplier? proveedor;
  final User? usuario;

  ProductPurchasePrice({
    this.id,
    this.precio,
    this.proveedor,
    this.usuario,
  });

  factory ProductPurchasePrice.fromJson(Map<String, dynamic> json) =>
      ProductPurchasePrice(
        id: json['id'],
        precio: (json['precio'] as num?)?.toDouble(),
        proveedor: json['proveedor'] != null
            ? Supplier.fromJson(json['proveedor'])
            : null,
        usuario:
            json['usuario'] != null ? User.fromJson(json['usuario']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'precio': precio,
        'proveedor': proveedor?.toJson(),
        'usuario': usuario?.toJson(),
      };
}
