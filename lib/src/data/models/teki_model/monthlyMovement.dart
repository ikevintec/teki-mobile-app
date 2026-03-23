class MonthlyMovement {
  final String periodo;
  final double totalIngresos;
  final double totalEgresos;
  final String moneda;

  MonthlyMovement({
    required this.periodo,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.moneda,
  });

  factory MonthlyMovement.fromJson(Map<String, dynamic> json) {
    return MonthlyMovement(
      periodo: json['periodo'],
      totalIngresos: (json['totalIngresos'] as num).toDouble(),
      totalEgresos: (json['totalEgresos'] as num).toDouble(),
      moneda: json['moneda'],
    );
  }
}
