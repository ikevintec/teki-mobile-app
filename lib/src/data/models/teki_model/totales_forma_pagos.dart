/// Totales de venta por método de pago para una moneda.
///
/// El backend (GET /tickets/operations/totales-forma-pago) responde PLANO:
/// `[{codigoMoneda, metodoPago, monto}, ...]` — igual que en la web, el
/// agrupado por moneda se hace en el cliente ([fromFlatJsonList]).
class TotalVentasFormaPago {
  final String codigoMoneda;
  final List<PaymentMethodTotal> metodosPago;

  const TotalVentasFormaPago({
    required this.codigoMoneda,
    this.metodosPago = const [],
  });

  /// Agrupa la lista plana del backend por moneda (espejo del reduce de
  /// loadTotalesFormaPago en ver-comprobantes web).
  static List<TotalVentasFormaPago> fromFlatJsonList(List<dynamic> raw) {
    final Map<String, List<PaymentMethodTotal>> porMoneda = {};
    for (final e in raw) {
      final m = e as Map<String, dynamic>;
      final moneda = (m['codigoMoneda'] ?? '') as String;
      porMoneda.putIfAbsent(moneda, () => []).add(PaymentMethodTotal.fromJson(m));
    }
    return porMoneda.entries
        .map((e) =>
            TotalVentasFormaPago(codigoMoneda: e.key, metodosPago: e.value))
        .toList();
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
