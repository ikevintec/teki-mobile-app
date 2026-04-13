class CashRegisterResponse {
  final int? id;
  final String? estadoCaja;
  final List<MontoMoneda> montosTotalesIngresos;
  final List<MontoMoneda> montosTotalesEgresos;
  final List<MontoMoneda> montosIngresosEfectivo;

  CashRegisterResponse({
    this.id,
    this.estadoCaja,
    required this.montosTotalesIngresos,
    required this.montosTotalesEgresos,
    required this.montosIngresosEfectivo,
  });

  factory CashRegisterResponse.fromJson(Map<String, dynamic> json) {
    return CashRegisterResponse(
      id: json['id'],
      estadoCaja: json['estadoCaja'],
      montosTotalesIngresos: _parseMontos(json['montosTotalesIngresos']),
      montosTotalesEgresos: _parseMontos(json['montosTotalesEgresos']),
      montosIngresosEfectivo: _parseMontos(json['montosIngresosEfectivo']),
    );
  }

  static List<MontoMoneda> _parseMontos(dynamic raw) {
    if (raw == null) return [];
    return (raw as List)
        .map((e) => MontoMoneda.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

class MontoMoneda {
  final double monto;
  final String moneda;

  MontoMoneda({required this.monto, required this.moneda});

  factory MontoMoneda.fromJson(Map<String, dynamic> json) {
    return MontoMoneda(
      monto: (json['monto'] as num).toDouble(),
      moneda: json['moneda'] as String,
    );
  }
}

/// Wrapper de la respuesta paginada de `/cash-register-detail`.
class CashRegisterDetailPage {
  final List<Map<String, dynamic>> rawItems;
  final bool isLast;
  final int totalElements;

  CashRegisterDetailPage({
    required this.rawItems,
    required this.isLast,
    required this.totalElements,
  });

  factory CashRegisterDetailPage.fromJson(Map<String, dynamic> json) {
    return CashRegisterDetailPage(
      rawItems: (json['content'] as List)
          .cast<Map<String, dynamic>>(),
      isLast: json['last'] as bool? ?? true,
      totalElements: json['totalElements'] as int? ?? 0,
    );
  }
}
