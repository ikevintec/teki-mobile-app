import 'package:teki_app/src/data/models/teki_model/cashRegisterActualAmount.dart';
import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class CashRegister {
  final int? id;
  final Company? empresa;
  final Office? puntoVenta;
  final SaleStation? estacionVenta;
  final int? turno;
  final List<CashRegisterActualAmount>? montosReales;
  final List<CashRegisterDetail>? cashRegisterDetails;
  final String? fechaClave;
  final DateTime? fecha;
  final DateTime? fechaInicio;
  final DateTime? fechaCierre;
  final String? estadoCaja;
  final User? usuario;
  final User? usuarioCierre;
  final List<int>? data;

  CashRegister({
    this.id,
    this.empresa,
    this.puntoVenta,
    this.estacionVenta,
    this.turno,
    this.montosReales,
    this.cashRegisterDetails,
    this.fechaClave,
    this.fecha,
    this.fechaInicio,
    this.fechaCierre,
    this.estadoCaja,
    this.usuario,
    this.usuarioCierre,
    this.data,
  });

  factory CashRegister.fromJson(Map<String, dynamic> json) => CashRegister(
        id: json['id'],
        empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
        estacionVenta: json['estacionVenta'] != null ? SaleStation.fromJson(json['estacionVenta']) : null,
        turno: json['turno'],
        montosReales: json['montosReales'] != null
            ? List<CashRegisterActualAmount>.from(
                json['montosReales'].map((x) => CashRegisterActualAmount.fromJson(x)))
            : null,
        cashRegisterDetails: json['cashRegisterDetails'] != null
            ? List<CashRegisterDetail>.from(
                json['cashRegisterDetails'].map((x) => CashRegisterDetail.fromJson(x)))
            : null,
        fechaClave: json['fechaClave'],
        fecha: parseDateTimeFlexible(json['fecha']),
        fechaInicio: parseDateTimeFlexible(json['fechaInicio']),
        fechaCierre: parseDateTimeFlexible(json['fechaCierre']),
        estadoCaja: json['estadoCaja'],
        usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
        usuarioCierre: json['usuarioCierre'] != null ? User.fromJson(json['usuarioCierre']) : null,
        data: json['data'] != null ? List<int>.from(json['data']) : null,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'empresa': empresa?.toJson(),
        'puntoVenta': puntoVenta?.toJson(),
        'estacionVenta': estacionVenta?.toJson(),
        'turno': turno,
        'montosReales': montosReales?.map((x) => x.toJson()).toList(),
        'cashRegisterDetails': cashRegisterDetails?.map((x) => x.toJson()).toList(),
        'fechaClave': fechaClave,
        'fecha': fecha?.toIso8601String(),
        'fechaInicio': fechaInicio?.toIso8601String(),
        'fechaCierre': fechaCierre?.toIso8601String(),
        'estadoCaja': estadoCaja,
        'usuario': usuario?.toJson(),
        'usuarioCierre': usuarioCierre?.toJson(),
        'data': data,
      };
}
