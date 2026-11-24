/// Lógica pura de reparto y validación de cuotas de crédito.
class CreditoCuotas {
  CreditoCuotas._();

  /// Redondeo estándar a 2 decimales (en céntimos, sin errores binarios).
  static double round2(double v) => (v * 100).round() / 100;

  /// Reparte [total] en [n] cuotas de 2 decimales cuya suma reconstruye
  /// exactamente el total. Trabaja en céntimos enteros: las primeras cuotas
  /// absorben el residuo. Ej: 100.00 en 3 → [33.34, 33.33, 33.33].
  static List<double> repartir(double total, int n) {
    if (n <= 0) return const [];
    final totalCent = (total * 100).round();
    final baseCent = totalCent ~/ n;
    final residuo = totalCent - baseCent * n;
    return List<double>.generate(
        n, (i) => (baseCent + (i < residuo ? 1 : 0)) / 100);
  }

  /// True si la suma de [montos] difiere del [total] en más de 1 centavo.
  /// Paridad con la validación del backend (FIX CC/CP): la suma de cuotas
  /// debe IGUALAR el total del crédito, ni más ni menos.
  static bool descuadraTotal(List<double> montos, double total) {
    final sumaCent = montos.fold<int>(0, (a, b) => a + (b * 100).round());
    return (sumaCent - (total * 100).round()).abs() > 1;
  }
}
