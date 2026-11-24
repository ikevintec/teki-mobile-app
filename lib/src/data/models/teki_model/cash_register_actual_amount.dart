
class CashRegisterActualAmount {
  final int? id;
  final double? monto;
  final String? moneda;

  CashRegisterActualAmount({
    this.id,
    this.monto,
    this.moneda,
  });

  factory CashRegisterActualAmount.fromJson(Map<String, dynamic> json) => CashRegisterActualAmount(
        id: json['id'],
        monto: (json['monto'] as num?)?.toDouble(),
        moneda: json['moneda'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'monto': monto,
        'moneda': moneda,
      };
}
