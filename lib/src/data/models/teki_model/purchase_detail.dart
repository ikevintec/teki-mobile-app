import 'package:teki_app/src/data/models/teki_model/account_receivable.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product_purchase.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';

class PurchaseDetail {
  final int? id;
  final Purchase? compra;
  final AccountsReceivable? cuentaCredito;
  final Product? producto;
  final double? precioCompra;
  final double? precioCompraNeto;
  final double? cantidad;
  final double? factor;
  final List<BatchProductPurchase>? lotes;
  final Supplier? proveedor;
  final double? importeTotal;
  final bool? eliminado;
  final bool? modificado;

  PurchaseDetail({
    this.id,
    this.compra,
    this.cuentaCredito,
    this.producto,
    this.precioCompra,
    this.precioCompraNeto,
    this.cantidad,
    this.factor,
    this.lotes,
    this.proveedor,
    this.importeTotal,
    this.eliminado,
    this.modificado,
  });

  factory PurchaseDetail.fromJson(Map<String, dynamic> json) => PurchaseDetail(
    id: json['id'],
    compra: json['compra'] != null ? Purchase.fromJson(json['compra']) : null,
    cuentaCredito: json['cuentaCredito'] != null ? AccountsReceivable.fromJson(json['cuentaCredito']) : null,
    producto: json['producto'] != null ? Product.fromJson(json['producto']) : null,
    precioCompra: (json['precioCompra'] as num?)?.toDouble(),
    precioCompraNeto: (json['precioCompraNeto'] as num?)?.toDouble(),
    cantidad: (json['cantidad'] as num?)?.toDouble(),
    factor: (json['factor'] as num?)?.toDouble(),
    lotes: (json['lotes'] as List?)?.map((e) => BatchProductPurchase.fromJson(e)).toList(),
    proveedor: json['proveedor'] != null ? Supplier.fromJson(json['proveedor']) : null,
    importeTotal: (json['importeTotal'] as num?)?.toDouble(),
    eliminado: json['eliminado'],
    modificado: json['modificado'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'compra': compra?.toJson(),
    'cuentaCredito': cuentaCredito?.toJson(),
    'producto': producto?.toJson(),
    'precioCompra': precioCompra,
    'precioCompraNeto': precioCompraNeto,
    'cantidad': cantidad,
    'factor': factor,
    'lotes': lotes?.map((e) => e.toJson()).toList(),
    'proveedor': proveedor?.toJson(),
    'importeTotal': importeTotal,
    'eliminado': eliminado,
    'modificado': modificado,
  };
}
