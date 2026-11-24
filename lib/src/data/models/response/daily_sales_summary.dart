/// Resumen de las ventas de un día: cantidad de comprobantes y montos por
/// moneda. Se calcula en el cliente a partir del listado de tickets del día
/// (las notas de crédito restan monto y no cuentan como venta).
class DailySalesSummary {
  final int totalVentas;
  final List<MontoMonedaVenta> montos;

  const DailySalesSummary({this.totalVentas = 0, this.montos = const []});

  /// Ticket promedio de la moneda [moneda]; 0 si no hay ventas.
  double ticketPromedio(String moneda) {
    if (totalVentas == 0) return 0;
    final m = montos.where((e) => e.moneda == moneda);
    if (m.isEmpty) return 0;
    return m.first.monto / totalVentas;
  }
}

class MontoMonedaVenta {
  final String moneda;
  final double monto;

  const MontoMonedaVenta({required this.moneda, required this.monto});
}
