import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';

class LoyaltyPointsMovement {
  final int id;
  final int? points;
  final String? type;
  final String? process;
  final String? description;
  final DateTime? date;
  final int? ticketId;

  const LoyaltyPointsMovement({
    required this.id,
    this.points,
    this.type,
    this.process,
    this.description,
    this.date,
    this.ticketId,
  });

  factory LoyaltyPointsMovement.fromJson(Map<String, dynamic> json) =>
      LoyaltyPointsMovement(
        id: (json['id'] as num).toInt(),
        points: (json['puntos'] as num?)?.toInt(),
        type: json['tipo'] as String?,
        process: json['proceso'] as String?,
        description: json['descripcion'] as String?,
        date: loyaltyDate(json['fecha']),
        ticketId: (json['idTicket'] as num?)?.toInt(),
      );

  String get typeLabel => switch (type) {
    'ACUMULACION' => 'Acumulación',
    'CANJE' => 'Canje',
    'VENCIMIENTO' => 'Vencimiento',
    'AJUSTE' || 'AJUSTE_ADMIN' => 'Ajuste',
    _ => type ?? 'Movimiento de puntos',
  };

  String? get processLabel => switch (process) {
    'VENTA' => 'Venta',
    'CANJE_CUPON' => 'Canje de cupón',
    'CANJE_PRODUCTO' => 'Canje de producto',
    'STAMP_PREMIO' => 'Proceso de sellos',
    'CUMPLEAÑOS' => 'Cumpleaños',
    'ADMIN' || 'AJUSTE' || 'AJUSTE_MANUAL' => 'Ajuste administrativo',
    _ => process,
  };
}
