/// Utilidad para formatear precios de forma inteligente
class PriceFormatter {
  /// Convierte un double a string mostrando enteros sin decimales
  /// Ejemplos: 10.0 -> "10", 10.5 -> "10.5", 10.50 -> "10.5", 10.99 -> "10.99"
  static String formatPrice(double? price) {
    if (price == null) return '0';
    
    // Si es un entero, mostrarlo sin decimales
    if (price % 1 == 0) {
      return price.toInt().toString();
    }
    
    // Si tiene decimales, mostrarlos pero quitar ceros innecesarios al final
    return price.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
  }
  
  /// Convierte un string a double de forma segura
  static double parsePrice(String? priceString) {
    if (priceString == null || priceString.trim().isEmpty) return 0.0;
    return double.tryParse(priceString.trim()) ?? 0.0;
  }
  
  /// Verifica si dos precios son efectivamente diferentes (diferencia mayor a 1 centavo)
  static bool areSignificantlyDifferent(double? price1, double? price2) {
    final p1 = price1 ?? 0.0;
    final p2 = price2 ?? 0.0;
    return (p1 - p2).abs() > 0.01;
  }
}