import 'package:teki_app/src/data/static/lists.dart';

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
  return value.toStringAsFixed(2); // 7.25 → 7.25
}

String formatExchange({required String moneda}) {
  switch (moneda) {
    case 'PEN':
      return 'S/. ';
    case 'USD':
      return '\$ ';
    case 'EUR':
      return '€ ';
    case 'GBP':
      return '£ ';
    default:
      return moneda; // Retorna el código de moneda si no coincide con los casos anteriores
  }
}

  String formatEstadoSunat(String? value) {
    switch (value) {
      case 'ACEPT':
        return 'Aceptado';
      case 'RECHA':
        return 'Rechazado';
      case 'ANULA':
        return 'Anulado';
      case 'N_ENV':
        return 'No enviado';
      default:
        return '-';
    }
  }

String formatTipoComprobante(String tipoComprobante) {
  List<Map<String, String>> lista = tipoComprobantesVenta;
  Map<String, String> item =
      lista.firstWhere((item) => item['value'] == tipoComprobante);
  return item['label2'] ?? '';
}
