import 'package:teki_app/src/data/models/teki_model/office.dart';

class Printer {
  final int? id;
  final String? nombre;
  final String? ip;

  final String? codigoCoffe;
  final Office? puntoVenta;
  final int? anchoPapel;

  final double? coffeEscala;
  final bool? imprimirLogoTicket;

  final bool? abrirGaveta;

  final bool? letraGrandeComanda;

  final bool? ocultarNumeroOrden;
  final String? fontsizeXNumeroOrden;
  final String? fontsizeYNumeroOrden;

  final bool? ocultarFecha;
  final String? fontsizeXFecha;
  final String? fontsizeYFecha;

  final bool? ocultarCamarero;
  final String? fontsizeXCamarero;
  final String? fontsizeYCamarero;

  final bool? ocultarCliente;
  final String? fontsizeXCliente;
  final String? fontsizeYCliente;

  final bool? ocultarMesa;
  final String? fontsizeXMesa;
  final String? fontsizeYMesa;

  final bool? ocultarSalon;
  final String? fontsizeXSalon;
  final String? fontsizeYSalon;

  final bool? ocultarArea;
  final String? fontsizeXArea;
  final String? fontsizeYArea;

  final bool? ocultarItems;
  final String? fontsizeXItems;
  final String? fontsizeYItems;

  final String? fontsizeXExtras;
  final String? fontsizeYExtras;

  final String? tipoImpresora;
  final String? tipoImpresion;

  Printer({
    this.id,
    this.nombre,
    this.ip,
    this.codigoCoffe,
    this.puntoVenta,
    this.anchoPapel,
    this.coffeEscala,
    this.imprimirLogoTicket,
    this.abrirGaveta,
    this.letraGrandeComanda,
    this.ocultarNumeroOrden,
    this.fontsizeXNumeroOrden,
    this.fontsizeYNumeroOrden,
    this.ocultarFecha,
    this.fontsizeXFecha,
    this.fontsizeYFecha,
    this.ocultarCamarero,
    this.fontsizeXCamarero,
    this.fontsizeYCamarero,
    this.ocultarCliente,
    this.fontsizeXCliente,
    this.fontsizeYCliente,
    this.ocultarMesa,
    this.fontsizeXMesa,
    this.fontsizeYMesa,
    this.ocultarSalon,
    this.fontsizeXSalon,
    this.fontsizeYSalon,
    this.ocultarArea,
    this.fontsizeXArea,
    this.fontsizeYArea,
    this.ocultarItems,
    this.fontsizeXItems,
    this.fontsizeYItems,
    this.fontsizeXExtras,
    this.fontsizeYExtras,
    this.tipoImpresora,
    this.tipoImpresion,
  });

  factory Printer.fromJson(Map<String, dynamic> json) => Printer(
        id: json['id'],
        nombre: json['nombre'],
        ip: json['ip'],
        codigoCoffe: json['codigoCoffe'],
        puntoVenta:
            json['puntoVenta'] != null ? Office.fromJson(json['puntoVenta']) : null,
        anchoPapel: json['anchoPapel'],
        coffeEscala: (json['coffeEscala'] as num?)?.toDouble(),
        imprimirLogoTicket: json['imprimirLogoTicket'],
        abrirGaveta: json['abrirGaveta'],
        letraGrandeComanda: json['letraGrandeComanda'],
        ocultarNumeroOrden: json['ocultarNumeroOrden'],
        fontsizeXNumeroOrden: json['fontsizeXNumeroOrden'],
        fontsizeYNumeroOrden: json['fontsizeYNumeroOrden'],
        ocultarFecha: json['ocultarFecha'],
        fontsizeXFecha: json['fontsizeXFecha'],
        fontsizeYFecha: json['fontsizeYFecha'],
        ocultarCamarero: json['ocultarCamarero'],
        fontsizeXCamarero: json['fontsizeXCamarero'],
        fontsizeYCamarero: json['fontsizeYCamarero'],
        ocultarCliente: json['ocultarCliente'],
        fontsizeXCliente: json['fontsizeXCliente'],
        fontsizeYCliente: json['fontsizeYCliente'],
        ocultarMesa: json['ocultarMesa'],
        fontsizeXMesa: json['fontsizeXMesa'],
        fontsizeYMesa: json['fontsizeYMesa'],
        ocultarSalon: json['ocultarSalon'],
        fontsizeXSalon: json['fontsizeXSalon'],
        fontsizeYSalon: json['fontsizeYSalon'],
        ocultarArea: json['ocultarArea'],
        fontsizeXArea: json['fontsizeXArea'],
        fontsizeYArea: json['fontsizeYArea'],
        ocultarItems: json['ocultarItems'],
        fontsizeXItems: json['fontsizeXItems'],
        fontsizeYItems: json['fontsizeYItems'],
        fontsizeXExtras: json['fontsizeXExtras'],
        fontsizeYExtras: json['fontsizeYExtras'],
        tipoImpresora: json['tipoImpresora'],
        tipoImpresion: json['tipoImpresion'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'ip': ip,
        'codigoCoffe': codigoCoffe,
        'puntoVenta': puntoVenta?.toJson(),
        'anchoPapel': anchoPapel,
        'coffeEscala': coffeEscala,
        'imprimirLogoTicket': imprimirLogoTicket,
        'abrirGaveta': abrirGaveta,
        'letraGrandeComanda': letraGrandeComanda,
        'ocultarNumeroOrden': ocultarNumeroOrden,
        'fontsizeXNumeroOrden': fontsizeXNumeroOrden,
        'fontsizeYNumeroOrden': fontsizeYNumeroOrden,
        'ocultarFecha': ocultarFecha,
        'fontsizeXFecha': fontsizeXFecha,
        'fontsizeYFecha': fontsizeYFecha,
        'ocultarCamarero': ocultarCamarero,
        'fontsizeXCamarero': fontsizeXCamarero,
        'fontsizeYCamarero': fontsizeYCamarero,
        'ocultarCliente': ocultarCliente,
        'fontsizeXCliente': fontsizeXCliente,
        'fontsizeYCliente': fontsizeYCliente,
        'ocultarMesa': ocultarMesa,
        'fontsizeXMesa': fontsizeXMesa,
        'fontsizeYMesa': fontsizeYMesa,
        'ocultarSalon': ocultarSalon,
        'fontsizeXSalon': fontsizeXSalon,
        'fontsizeYSalon': fontsizeYSalon,
        'ocultarArea': ocultarArea,
        'fontsizeXArea': fontsizeXArea,
        'fontsizeYArea': fontsizeYArea,
        'ocultarItems': ocultarItems,
        'fontsizeXItems': fontsizeXItems,
        'fontsizeYItems': fontsizeYItems,
        'fontsizeXExtras': fontsizeXExtras,
        'fontsizeYExtras': fontsizeYExtras,
        'tipoImpresora': tipoImpresora,
        'tipoImpresion': tipoImpresion,
      };
}
