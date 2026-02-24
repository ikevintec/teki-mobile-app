import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/purchaseDetail.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/supplier.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class Purchase {
  final int? id;
  final String? tipoComprobante;
  final String? comprobante;
  final DateTime? fecha;
  final String? numeroDocumentoProveedor;
  final String? nombreProveedor;
  final Supplier? proveedor;
  final String? tipoCompra;
  final String? tipoOperacion;
  final String? estadoOrdenCompra;
  final int? diasCredito;
  final String? codigoMoneda;
  final List<PurchaseDetail>? items;
  final Company? empresa;
  final Office? puntoVenta;
  final User? usuario;
  final SaleStation? estacionVenta;
  final String? uuid;
  final CashRegisterDetail? movimientoCaja;
  final bool? anulado;
  final String? motivoAnulacion;
  final bool? estado;

  Purchase({
    this.id,
    this.tipoComprobante,
    this.comprobante,
    this.fecha,
    this.numeroDocumentoProveedor,
    this.nombreProveedor,
    this.proveedor,
    this.tipoCompra,
    this.tipoOperacion,
    this.estadoOrdenCompra,
    this.diasCredito,
    this.codigoMoneda,
    this.items,
    this.empresa,
    this.puntoVenta,
    this.usuario,
    this.estacionVenta,
    this.uuid,
    this.movimientoCaja,
    this.anulado,
    this.motivoAnulacion,
    this.estado,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) => Purchase(
    id: json['id'],
    tipoComprobante: json['tipoComprobante'],
    comprobante: json['comprobante'],
    fecha: json['fecha'] != null ? parseDateTimeFlexible(json['fecha']) : null,
    numeroDocumentoProveedor: json['numeroDocumentoProveedor'],
    nombreProveedor: json['nombreProveedor'],
    proveedor: json['proveedor'] != null ? Supplier.fromJson(json['proveedor']) : null,
    tipoCompra: json['tipoCompra'],
    tipoOperacion: json['tipoOperacion'],
    estadoOrdenCompra: json['estadoOrdenCompra'],
    diasCredito: json['diasCredito'],
    codigoMoneda: json['codigoMoneda'],
    items: (json['items'] as List?)?.map((e) => PurchaseDetail.fromJson(e)).toList(),
    empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
    usuario: json['usuario'] != null ? User.fromJson(json['usuario']) : null,
    estacionVenta: json['estacionVenta'] != null ? SaleStation.fromJson(json['estacionVenta']) : null,
    uuid: json['uuid'],
    movimientoCaja: json['movimientoCaja'] != null ? CashRegisterDetail.fromJson(json['movimientoCaja']) : null,
    anulado: json['anulado'],
    motivoAnulacion: json['motivoAnulacion'],
    estado: json['estado'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'tipoComprobante': tipoComprobante,
    'comprobante': comprobante,
    'fecha': fecha?.toIso8601String(),
    'numeroDocumentoProveedor': numeroDocumentoProveedor,
    'nombreProveedor': nombreProveedor,
    'proveedor': proveedor?.toJson(),
    'tipoCompra': tipoCompra,
    'tipoOperacion': tipoOperacion,
    'estadoOrdenCompra': estadoOrdenCompra,
    'diasCredito': diasCredito,
    'codigoMoneda': codigoMoneda,
    'items': items?.map((e) => e.toJson()).toList(),
    'empresa': empresa?.toJson(),
    'puntoVenta': puntoVenta?.toJson(),
    'usuario': usuario?.toJson(),
    'estacionVenta': estacionVenta?.toJson(),
    'uuid': uuid,
    'movimientoCaja': movimientoCaja?.toJson(),
    'anulado': anulado,
    'motivoAnulacion': motivoAnulacion,
    'estado': estado,
  };
}