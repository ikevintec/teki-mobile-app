DateTime? parseDateTimeFlexible(dynamic value) {
  if (value == null) return null;
  if (value is int) {
    // Asume timestamp en milisegundos
    return DateTime.fromMillisecondsSinceEpoch(value);
  } else if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }
  return null;
}

String formatDouble(double value) {
  if (value == value.toInt()) {
    return value.toInt().toString(); // 7.0 → 7
  }
  return value.toString(); // 7.25 → 7.25
}
