import 'package:teki_app/src/data/models/teki_model/cashRegister.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';

class CashRegisterActualAmount {
  final int? id;
  final CashRegister? cashRegister;
  final double? monto;
  final String? moneda;
  final DateTime? fechaCierre;
  final User? usuarioCierre;
  final String? condicionCierre;

  CashRegisterActualAmount({
    this.id,
    this.cashRegister,
    this.monto,
    this.moneda,
    this.fechaCierre,
    this.usuarioCierre,
    this.condicionCierre,
  });

  factory CashRegisterActualAmount.fromJson(Map<String, dynamic> json) => CashRegisterActualAmount(
        id: json['id'],
        cashRegister: json['cashRegister'] != null ? CashRegister.fromJson(json['cashRegister']) : null,
        monto: (json['monto'] as num?)?.toDouble(),
        moneda: json['moneda'],
        fechaCierre: json['fechaCierre'] != null ? DateTime.parse(json['fechaCierre']) : null,
        usuarioCierre: json['usuarioCierre'] != null ? User.fromJson(json['usuarioCierre']) : null,
        condicionCierre: json['condicionCierre'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'cashRegister': cashRegister?.toJson(),
        'monto': monto,
        'moneda': moneda,
        'fechaCierre': fechaCierre?.toIso8601String(),
        'usuarioCierre': usuarioCierre?.toJson(),
        'condicionCierre': condicionCierre,
      };
}
