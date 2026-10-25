/// Compara en céntimos. Solo el efectivo recibido puede producir vuelto.
String? validateCashPayment({
  required double total,
  required double cash,
  required double nonCash,
}) {
  final totalCent = (total * 100).round();
  if (((cash + nonCash) * 100).round() < totalCent) {
    return 'El monto pagado es menor al total de la venta';
  }
  if ((nonCash * 100).round() > totalCent) {
    return 'Los pagos sin efectivo no pueden superar el total de la venta.';
  }
  return null;
}
