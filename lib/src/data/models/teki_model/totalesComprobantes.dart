class TotalesPorMoneda {
  final double totalFacturas;
  final double totalIgv;
  final double totalBoletas;
  final double totalNotasVenta;
  final double totalNotasCredito;
  final double totalNotasDebito;
  final String codigoMoneda;

  TotalesPorMoneda({
    required this.totalFacturas,
    required this.totalIgv,
    required this.totalBoletas,
    required this.totalNotasVenta,
    required this.totalNotasCredito,
    required this.totalNotasDebito,
    required this.codigoMoneda,
  });

  factory TotalesPorMoneda.fromJson(Map<String, dynamic> json) {
    return TotalesPorMoneda(
      totalFacturas: (json['totalFacturas'] ?? 0).toDouble(),
      totalIgv: (json['totalIgv'] ?? 0).toDouble(),
      totalBoletas: (json['totalBoletas'] ?? 0).toDouble(),
      totalNotasVenta: (json['totalNotasVenta'] ?? 0).toDouble(),
      totalNotasCredito: (json['totalNotasCredito'] ?? 0).toDouble(),
      totalNotasDebito: (json['totalNotasDebito'] ?? 0).toDouble(),
      codigoMoneda: json['codigoMoneda'] ?? '',
    );
  }
}
