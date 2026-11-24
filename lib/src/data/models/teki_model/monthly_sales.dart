class MonthlySales {
  final String periodo;
  final double totalFacturas;
  final double totalBoletas;
  final double totalNotasVenta;
  final double totalNotasCredito;
  final double totalNotasDebito;
  final double total;
  final String moneda;

  MonthlySales({
    required this.periodo,
    required this.totalFacturas,
    required this.totalBoletas,
    required this.totalNotasVenta,
    required this.totalNotasCredito,
    required this.totalNotasDebito,
    required this.total,
    required this.moneda,
  });

  factory MonthlySales.fromJson(Map<String, dynamic> json) {
    return MonthlySales(
      periodo: json['periodo'],
      totalFacturas: (json['totalFacturas'] as num?)?.toDouble() ?? 0.0,
      totalBoletas: (json['totalBoletas'] as num?)?.toDouble() ?? 0.0,
      totalNotasVenta: (json['totalNotasVenta'] as num?)?.toDouble() ?? 0.0,
      totalNotasCredito: (json['totalNotasCredito'] as num?)?.toDouble() ?? 0.0,
      totalNotasDebito: (json['totalNotasDebito'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      moneda: json['moneda'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'periodo': periodo,
      'totalFacturas': totalFacturas,
      'totalBoletas': totalBoletas,
      'totalNotasVenta': totalNotasVenta,
      'totalNotasCredito': totalNotasCredito,
      'totalNotasDebito': totalNotasDebito,
      'total': total,
      'moneda': moneda,
    };
  }
}
