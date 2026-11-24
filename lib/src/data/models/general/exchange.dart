class Exchance {
  final String codigoMonedaOrigen;
  final String codigoMonedaDestino;
  final double? monto;
  final double? montoOrigen;

  Exchance(
      {required this.codigoMonedaOrigen,
      required this.codigoMonedaDestino,
      this.monto,
      this.montoOrigen
      });
  
  copyWith({
    String? codigoMonedaOrigen,
    String? codigoMonedaDestino,
    double? monto,
    double? montoOrigen,
  }) {
    return Exchance(
      codigoMonedaOrigen: codigoMonedaOrigen ?? this.codigoMonedaOrigen,
      codigoMonedaDestino: codigoMonedaDestino ?? this.codigoMonedaDestino,
      monto: monto ?? this.monto,
      montoOrigen: montoOrigen ?? this.montoOrigen,
    );
  }
}
