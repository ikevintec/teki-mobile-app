import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';

class LoyaltyCoupon {
  final int id;
  final int? enrollmentId;
  final int? cardId;
  final String name;
  final String? code;
  final String? status;
  final DateTime? issuedAt;
  final DateTime? expiresAt;
  final DateTime? usedAt;
  const LoyaltyCoupon({
    required this.id,
    this.enrollmentId,
    this.cardId,
    required this.name,
    this.code,
    this.status,
    this.issuedAt,
    this.expiresAt,
    this.usedAt,
  });

  factory LoyaltyCoupon.fromJson(Map<String, dynamic> json) {
    final enrollment = json['loyaltyCustomer'] as Map<String, dynamic>?;
    final definition = json['couponDef'] as Map<String, dynamic>?;
    return LoyaltyCoupon(
      id: (json['id'] as num).toInt(),
      enrollmentId: (enrollment?['id'] as num?)?.toInt(),
      cardId: (enrollment?['idLoyaltyConfig'] as num?)?.toInt(),
      name: (definition?['nombre'] as String?) ?? 'Cupón emitido',
      code: json['codigo'] as String?,
      status: json['estado'] as String?,
      issuedAt: loyaltyDate(json['fechaEmision']),
      expiresAt: loyaltyDate(json['fechaVencimiento']),
      usedAt: loyaltyDate(json['fechaUso']),
    );
  }

  String get statusLabel => switch (status) {
    'PENDIENTE' => 'Pendiente',
    'USADO' => 'Usado',
    'VENCIDO' => 'Vencido',
    'FINALIZADO' => 'Finalizado',
    _ => status ?? 'Sin estado informado',
  };
}
