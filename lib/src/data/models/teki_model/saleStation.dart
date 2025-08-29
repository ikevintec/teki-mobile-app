import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';

class SaleStation {
  final int? id;
  final String? nombre;
  final Office? puntoVenta;
  final Printer? impresoraComprobante;
  final Printer? impresoraCuentaRestaurante;
  final bool? estado;

  SaleStation({
    this.id,
    this.nombre,
    this.puntoVenta,
    this.impresoraComprobante,
    this.impresoraCuentaRestaurante,
    this.estado,
  });

  factory SaleStation.fromJson(Map<String, dynamic> json) => SaleStation(
    id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
    nombre: json['nombre'],
    puntoVenta: json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
    impresoraComprobante: json['impresoraComprobante'] != null ? Printer.fromJson(json['impresoraComprobante']) : null,
    impresoraCuentaRestaurante: json['impresoraCuentaRestaurante'] != null ? Printer.fromJson(json['impresoraCuentaRestaurante']) : null,
    estado: json['estado'] is bool ? json['estado'] : json['estado'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'puntoVenta': puntoVenta?.toJson(),
    'impresoraComprobante': impresoraComprobante?.toJson(),
    'impresoraCuentaRestaurante': impresoraCuentaRestaurante?.toJson(),
    'estado': estado,
  };
}