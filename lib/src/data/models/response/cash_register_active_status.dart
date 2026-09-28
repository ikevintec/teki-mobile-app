class CashRegisterActiveStatus {
  final bool cajaActiva;
  final int? idCaja;
  final DateTime? fechaCaja;
  final int? turno;
  final bool fechaPasada;

  const CashRegisterActiveStatus({
    required this.cajaActiva,
    this.idCaja,
    this.fechaCaja,
    this.turno,
    required this.fechaPasada,
  });

  factory CashRegisterActiveStatus.fromJson(Map<String, dynamic> json) {
    final rawFecha = json['fechaCaja'];
    DateTime? fecha;
    if (rawFecha is num) {
      fecha = DateTime.fromMillisecondsSinceEpoch(rawFecha.toInt());
    } else if (rawFecha is String) {
      fecha = DateTime.tryParse(rawFecha);
    }
    return CashRegisterActiveStatus(
      cajaActiva: json['cajaActiva'] == true,
      idCaja: (json['idCaja'] as num?)?.toInt(),
      fechaCaja: fecha,
      turno: (json['turno'] as num?)?.toInt(),
      fechaPasada: json['fechaPasada'] == true,
    );
  }
}
