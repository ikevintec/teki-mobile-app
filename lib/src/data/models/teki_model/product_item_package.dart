import 'package:teki_app/src/utils/formats.dart';

import 'product.dart';

class ProductItemPackage {
  int? id;
  Product? productoItem;
  double? cantidad;
  bool? modificado;
  bool? eliminado;
  DateTime? createdOn;
  int? createdBy;
  int? updatedBy;
  DateTime? updatedOn;
  int? deleteBy;
  DateTime? deletedOn;

  ProductItemPackage({
    this.id,
    this.productoItem,
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

  factory ProductItemPackage.fromJson(Map<String, dynamic> json) {
    return ProductItemPackage(
      id: json['id'],
      productoItem: json['productoItem'] != null
          ? Product.fromJson(json['productoItem'])
          : null,
      cantidad: (json['cantidad'] as num?)?.toDouble(),
      modificado: json['modificado'],
      eliminado: json['eliminado'],
      createdOn: parseDateTimeFlexible(json['createdOn']),
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      updatedOn: parseDateTimeFlexible(json['updatedOn']),
      deleteBy: json['deleteBy'],
      deletedOn: parseDateTimeFlexible(json['deletedOn']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      // Referencia mínima: el backend solo usa el id del productoItem, y
      // serializar el producto completo puede romper el guardado (precios con
      // referencia circular / payload gigante).
      'productoItem': productoItem == null
          ? null
          : {'id': productoItem!.id, 'nombre': productoItem!.nombre},
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
}
