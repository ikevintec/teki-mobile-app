import 'package:teki_app/src/data/models/teki_model/batchProduct.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';

class InventoryAdjustmentDetail {
  final int? id;
  final Product? producto;
  final double? cantidad;
  final double? cantidadAlternativa;
  final double? stock;
  final double? stockAnterior;
  final String? tipo;
  final String? concepto;
  final List<BatchProduct>? lotes;

  InventoryAdjustmentDetail({
    this.id,
    this.producto,
    this.cantidad,
    this.cantidadAlternativa,
    this.stock,
    this.stockAnterior,
    this.tipo,
    this.concepto,
    this.lotes,
  });

  factory InventoryAdjustmentDetail.fromJson(Map<String, dynamic> json) =>
      InventoryAdjustmentDetail(
        id: json['id'],
        producto: json['producto'] != null ? Product.fromJson(json['producto']) : null,
        cantidad: (json['cantidad'] as num?)?.toDouble(),
        cantidadAlternativa: (json['cantidadAlternativa'] as num?)?.toDouble(),
        stock: (json['stock'] as num?)?.toDouble(),
        stockAnterior: (json['stockAnterior'] as num?)?.toDouble(),
        tipo: json['tipo'],
        concepto: json['concepto'],
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (producto?.id != null) 'producto': {'id': producto!.id},
        if (cantidad != null)
          'cantidad': (cantidad! % 1 == 0) ? cantidad!.toInt() : cantidad,
        if (cantidadAlternativa != null)
          'cantidadAlternativa': (cantidadAlternativa! % 1 == 0)
              ? cantidadAlternativa!.toInt()
              : cantidadAlternativa,
        if (stock != null) 'stock': stock,
        if (stockAnterior != null) 'stockAnterior': stockAnterior,
        if (tipo != null) 'tipo': tipo,
        if (concepto != null && concepto!.isNotEmpty) 'concepto': concepto,
        if (lotes != null && lotes!.isNotEmpty)
          'lotes': lotes!.map(_serializeLote).toList(),
      };

  static Map<String, dynamic> _serializeLote(BatchProduct l) => {
        if (l.id != null) 'id': l.id,
        'cantidad': (l.cantidad ?? 1).toInt(),
        if (l.tipoLote != null) 'tipoLote': l.tipoLote,
        if (l.serie != null) 'serie': l.serie,
        'talla': l.talla,
        'color': l.color,
        'fechaFabricacion': l.fechaFabricacion?.toIso8601String(),
        'fechaVencimiento': l.fechaVencimiento?.toIso8601String(),
        'precioCompra': l.precioCompra,
        'compraLote': null,
      };

  InventoryAdjustmentDetail copyWith({
    int? id,
    Product? producto,
    double? cantidad,
    double? cantidadAlternativa,
    double? stock,
    double? stockAnterior,
    String? tipo,
    String? concepto,
    List<BatchProduct>? lotes,
  }) =>
      InventoryAdjustmentDetail(
        id: id ?? this.id,
        producto: producto ?? this.producto,
        cantidad: cantidad ?? this.cantidad,
        cantidadAlternativa: cantidadAlternativa ?? this.cantidadAlternativa,
        stock: stock ?? this.stock,
        stockAnterior: stockAnterior ?? this.stockAnterior,
        tipo: tipo ?? this.tipo,
        concepto: concepto ?? this.concepto,
        lotes: lotes ?? this.lotes,
      );
}
