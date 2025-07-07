class PaymentMethodTotal {
  final String metodoPago;
  final double monto;
  final String codigoMoneda;

  PaymentMethodTotal({
    required this.metodoPago,
    required this.monto,
    required this.codigoMoneda,
  });

  factory PaymentMethodTotal.fromJson(Map<String, dynamic> json) {
    return PaymentMethodTotal(
      metodoPago: json['metodoPago'] ?? '',
      monto: (json['monto'] ?? 0).toDouble(),
      codigoMoneda: json['codigoMoneda'] ?? '',
    );
  }
}
