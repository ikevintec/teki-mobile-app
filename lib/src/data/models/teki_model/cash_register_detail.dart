import 'package:teki_app/src/data/models/teki_model/cash_register.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/purchase.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class CashRegisterDetail {
  final int? id;
  final CashRegister? cashRegister;
  final String? tipoMovimientoCaja;
  final String? conceptoMovimientoCaja;
  final String? monedaMovimientoCaja;
  final List<PaymentDetail>? pagos;
  final double? monto;
  final int? turno;
  final String? descripcion;
  final String? detalle;
  final Ticket? ticket;
  final Quotation? quotation;
  final Purchase? compra;
  final DateTime? fechaMovimiento;
  final User? usuario;
  final bool? postCierre;
  final bool? estado;

  CashRegisterDetail({
    this.id,
    this.cashRegister,
    this.tipoMovimientoCaja,
    this.conceptoMovimientoCaja,
    this.monedaMovimientoCaja,
    this.pagos,
    this.monto,
    this.turno,
    this.descripcion,
    this.detalle,
    this.ticket,
    this.quotation,
    this.compra,
    this.fechaMovimiento,
    this.usuario,
    this.postCierre,
    this.estado,
  });

  factory CashRegisterDetail.fromJson(Map<String, dynamic> json) => CashRegisterDetail(
    id: json['id'],
    cashRegister: json['cashRegister'] != null ? CashRegister.fromJson(json['cashRegister']) : null,
    tipoMovimientoCaja: json['tipoMovimientoCaja'],
    conceptoMovimientoCaja: json['conceptoMovimientoCaja'],
    monedaMovimientoCaja: json['monedaMovimientoCaja'],
    pagos: (json['pagos'] as List?)?.map((e) => PaymentDetail.fromJson(e)).toList(),
    monto: (json['monto'] as num?)?.toDouble(),
    turno: json['turno'],
    descripcion: json['descripcion'],
    detalle: json['detalle'],
    ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
    quotation: json['quotation'] != null ? Quotation.fromJson(json['quotation']) : null,
    compra: json['compra'] != null ? Purchase.fromJson(json['compra']) : null,
    fechaMovimiento:parseDateTimeFlexible(json['fechaMovimiento']),
    usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
    postCierre: json['postCierre'],
    estado: json['estado'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'cashRegister': cashRegister?.toJson(),
    'tipoMovimientoCaja': tipoMovimientoCaja,
    'conceptoMovimientoCaja': conceptoMovimientoCaja,
    'monedaMovimientoCaja': monedaMovimientoCaja,
    'pagos': pagos?.map((e) => e.toJson()).toList(),
    'monto': monto,
    'turno': turno,
    'descripcion': descripcion,
    'detalle': detalle,
    'ticket': ticket?.toJson(),
    'quotation': quotation?.toJson(),
    'compra': compra?.toJson(),
    'fechaMovimiento': fechaMovimiento?.toIso8601String(),
    'usuario': usuario?.toJson(),
    'postCierre': postCierre,
    'estado': estado,
  };
}