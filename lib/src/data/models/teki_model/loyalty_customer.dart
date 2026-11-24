class LoyaltyCustomer {
  final int id;
  final int cardId;
  final int? customerId;
  final String name;
  final String cardName;
  final String? document;
  final String? phone;
  final int? stamps;
  final int? availablePoints;
  final int? historicalPoints;
  final int? visits;
  final bool active;
  final DateTime? registeredAt;
  final String? membership;

  const LoyaltyCustomer({
    required this.id,
    required this.cardId,
    this.customerId,
    required this.name,
    required this.cardName,
    this.document,
    this.phone,
    this.stamps,
    this.availablePoints,
    this.historicalPoints,
    this.visits,
    this.active = false,
    this.registeredAt,
    this.membership,
  });

  factory LoyaltyCustomer.fromJson(Map<String, dynamic> json) =>
      LoyaltyCustomer(
        id: (json['id'] as num).toInt(),
        cardId: (json['idLoyaltyConfig'] as num).toInt(),
        customerId: (json['idCustomer'] as num?)?.toInt(),
        name: (json['clienteNombre'] as String?) ?? 'Cliente sin nombre',
        cardName:
            (json['tarjetaNombre'] as String?) ?? 'Tarjeta de fidelización',
        document: json['clienteDocumento'] as String?,
        phone: json['clienteTelefono'] as String?,
        stamps: (json['sellos'] as num?)?.toInt(),
        availablePoints: (json['puntosDisponibles'] as num?)?.toInt(),
        historicalPoints: (json['puntosAcumulados'] as num?)?.toInt(),
        visits: (json['visitas'] as num?)?.toInt(),
        active: json['activo'] == true,
        registeredAt: loyaltyDate(json['fechaRegistro']),
        membership:
            (json['membershipLevelActual'] as Map<String, dynamic>?)?['nombre']
                as String?,
      );

  String? get discreetDocument {
    final value = document;
    if (value == null || value.isEmpty) return null;
    return value.length <= 4
        ? value
        : '••••${value.substring(value.length - 4)}';
  }
}

DateTime? loyaltyDate(dynamic value) {
  if (value is num) {
    return DateTime.fromMillisecondsSinceEpoch(
      value.toInt(),
      isUtc: true,
    ).toLocal();
  }
  return value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
