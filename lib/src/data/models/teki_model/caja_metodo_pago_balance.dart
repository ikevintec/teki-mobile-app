import 'package:teki_app/src/data/models/response/cash_register_response.dart';

class CajaMetodoPagoBalance {
  final String metodoPago;
  final List<MontoMoneda> ingreso;
  final List<MontoMoneda> egreso;

  CajaMetodoPagoBalance({
    required this.metodoPago,
    required this.ingreso,
    required this.egreso,
  });

  factory CajaMetodoPagoBalance.fromJson(Map<String, dynamic> json) {
    return CajaMetodoPagoBalance(
      metodoPago: json['metodoPago'] as String? ?? '',
      ingreso: _parseList(json['ingreso']),
      egreso: _parseList(json['egreso']),
    );
  }

  static List<MontoMoneda> _parseList(dynamic raw) {
    if (raw == null) return [];
    return (raw as List)
        .map((e) => MontoMoneda.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  double ingresoForMoneda(String moneda) => ingreso
      .where((m) => m.moneda == moneda)
      .fold(0.0, (acc, m) => acc + m.monto);

  double egresoForMoneda(String moneda) => egreso
      .where((m) => m.moneda == moneda)
      .fold(0.0, (acc, m) => acc + m.monto);

  double gananciaForMoneda(String moneda) =>
      ingresoForMoneda(moneda) - egresoForMoneda(moneda);

  bool hasDataForMoneda(String moneda) =>
      ingresoForMoneda(moneda) != 0 || egresoForMoneda(moneda) != 0;
}
