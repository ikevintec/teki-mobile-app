/// Totales de venta por método de pago para una moneda — espejo de
/// TotalVentasFormaPago de la web (GET /tickets/operations/totales-forma-pago).
class TotalVentasFormaPago {
  final String codigoMoneda;
  final List<PaymentMethodTotal> metodosPago;

  const TotalVentasFormaPago({
    required this.codigoMoneda,
    this.metodosPago = const [],
  });

  factory TotalVentasFormaPago.fromJson(Map<String, dynamic> json) {
    return TotalVentasFormaPago(
      codigoMoneda: json['codigoMoneda'] ?? '',
      metodosPago: (json['metodosPago'] as List? ?? [])
          .map((e) => PaymentMethodTotal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PaymentMethodTotal {
  final String metodoPago;
  final double monto;

  const PaymentMethodTotal({required this.metodoPago, required this.monto});

  factory PaymentMethodTotal.fromJson(Map<String, dynamic> json) {
    return PaymentMethodTotal(
      metodoPago: json['metodoPago'] ?? '',
      monto: (json['monto'] ?? 0).toDouble(),
    );
  }
}
