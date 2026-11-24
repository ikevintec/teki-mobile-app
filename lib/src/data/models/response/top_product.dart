/// Producto del ranking de más vendidos (GET /products/top-orders).
class TopProduct {
  final String nombreProducto;
  final double cantidad;

  const TopProduct({required this.nombreProducto, required this.cantidad});

  factory TopProduct.fromJson(Map<String, dynamic> json) {
    return TopProduct(
      nombreProducto: json['nombreProducto'] as String? ?? 'Sin nombre',
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0,
    );
  }
}
