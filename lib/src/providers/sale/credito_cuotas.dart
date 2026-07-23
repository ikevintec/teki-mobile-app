/// Lógica pura de reparto y validación de cuotas de crédito.
class CreditoCuotas {
  CreditoCuotas._();

  /// Reparte [total] en [n] cuotas de 2 decimales cuya suma reconstruye
  /// exactamente el total: todas iguales y la última absorbe el residuo
  /// de centavos. Evita el descuadre de `total/n` redondeado por cuota.
  /// Ej: 100.00 en 3 → [33.33, 33.33, 33.34].
  static List<double> repartir(double total, int n) {
    if (n <= 0) return const [];
    final base = (total / n * 100).floor() / 100; // trunca a 2 decimales
    final cuotas = List<double>.filled(n, base);
    // Residuo en centavos que falta para llegar al total exacto.
    final asignado = base * n;
    final residuo = ((total - asignado) * 100).round() / 100;
    cuotas[n - 1] = ((base + residuo) * 100).round() / 100;
    return cuotas;
  }

  /// True si la suma de [montos] EXCEDE [total] (más de 1 centavo de
  /// tolerancia por flotantes). Paridad con el validador web totalCuotas,
  /// que solo bloquea cuando las cuotas superan el total de la venta.
  static bool excedeTotal(List<double> montos, double total) {
    final suma = montos.fold<double>(0, (a, b) => a + b);
    return suma - total > 0.01;
  }
}
