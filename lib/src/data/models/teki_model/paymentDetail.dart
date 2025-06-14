import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';

class PaymentDetail {
  final int? id;
  final PaymentMethod? metodoPago;
  final CashRegisterDetail? cashRegisterDetail;
  final String? formaPago;
  final String? tipoTarjeta;
  final String? nombre;
  final String? numeroOperacion;
  final double? monto;
  final bool? eliminado;
  final bool? modificado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  PaymentDetail({
    this.id,
    this.metodoPago,
    this.cashRegisterDetail,
    this.formaPago,
    this.tipoTarjeta,
    this.nombre,
    this.numeroOperacion,
    this.monto,
    this.eliminado,
    this.modificado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory PaymentDetail.fromJson(Map<String, dynamic> json) => PaymentDetail(
        id: json['id'],
        metodoPago: json['metodoPago'] != null ? PaymentMethod.fromJson(json['metodoPago']) : null,
        cashRegisterDetail: json['cashRegisterDetail'] != null ? CashRegisterDetail.fromJson(json['cashRegisterDetail']) : null,
        formaPago: json['formaPago'],
        tipoTarjeta: json['tipoTarjeta'],
        nombre: json['nombre'],
        numeroOperacion: json['numeroOperacion'],
        monto: (json['monto'] as num?)?.toDouble(),
        eliminado: json['eliminado'],
        modificado: json['modificado'],
        createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'metodoPago': metodoPago?.toJson(),
        'cashRegisterDetail': cashRegisterDetail?.toJson(),
        'formaPago': formaPago,
        'tipoTarjeta': tipoTarjeta,
        'nombre': nombre,
        'numeroOperacion': numeroOperacion,
        'monto': monto,
        'eliminado': eliminado,
        'modificado': modificado,
        'createdOn': createdOn?.toIso8601String(),
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
      };
}
