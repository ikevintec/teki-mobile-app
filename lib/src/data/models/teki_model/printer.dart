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
  final String? fontsizeNumeroOrden;
  final String? fontsizeXNumeroOrden;
  final String? fontsizeYNumeroOrden;

  final bool? ocultarFecha;
  final String? fontsizeOcultarFecha;
  final String? fontsizeXOcultarFecha;
  final String? fontsizeYOcultarFecha;

  final bool? ocultarCamarero;
  final String? fontsizeOcultarCamarero;
  final String? fontsizeXOcultarCamarero;
  final String? fontsizeYOcultarCamarero;

  final bool? ocultarCliente;
  final String? fontsizeOcultarCliente;
  final String? fontsizeXOcultarCliente;
  final String? fontsizeYOcultarCliente;

  final bool? ocultarMesa;
  final String? fontsizeOcultarMesa;
  final String? fontsizeXOcultarMesa;
  final String? fontsizeYOcultarMesa;

  final bool? ocultarSalon;
  final String? fontsizeOcultarSalon;
  final String? fontsizeXOcultarSalon;
  final String? fontsizeYOcultarSalon;

  final bool? ocultarArea;
  final String? fontsizeOcultarArea;
  final String? fontsizeXOcultarArea;
  final String? fontsizeYOcultarArea;

  final bool? ocultarItems;
  final String? fontsizeOcultarItems;
  final String? fontsizeXOcultarItems;
  final String? fontsizeYOcultarItems;

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
    this.fontsizeNumeroOrden,
    this.fontsizeXNumeroOrden,
    this.fontsizeYNumeroOrden,
    this.ocultarFecha,
    this.fontsizeOcultarFecha,
    this.fontsizeXOcultarFecha,
    this.fontsizeYOcultarFecha,
    this.ocultarCamarero,
    this.fontsizeOcultarCamarero,
    this.fontsizeXOcultarCamarero,
    this.fontsizeYOcultarCamarero,
    this.ocultarCliente,
    this.fontsizeOcultarCliente,
    this.fontsizeXOcultarCliente,
    this.fontsizeYOcultarCliente,
    this.ocultarMesa,
    this.fontsizeOcultarMesa,
    this.fontsizeXOcultarMesa,
    this.fontsizeYOcultarMesa,
    this.ocultarSalon,
    this.fontsizeOcultarSalon,
    this.fontsizeXOcultarSalon,
    this.fontsizeYOcultarSalon,
    this.ocultarArea,
    this.fontsizeOcultarArea,
    this.fontsizeXOcultarArea,
    this.fontsizeYOcultarArea,
    this.ocultarItems,
    this.fontsizeOcultarItems,
    this.fontsizeXOcultarItems,
    this.fontsizeYOcultarItems,
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
        fontsizeNumeroOrden: json['fontsizeNumeroOrden'],
        fontsizeXNumeroOrden: json['fontsizeXNumeroOrden'],
        fontsizeYNumeroOrden: json['fontsizeYNumeroOrden'],
        ocultarFecha: json['ocultarFecha'],
        fontsizeOcultarFecha: json['fontsizeOcultarFecha'],
        fontsizeXOcultarFecha: json['fontsizeXOcultarFecha'],
        fontsizeYOcultarFecha: json['fontsizeYOcultarFecha'],
        ocultarCamarero: json['ocultarCamarero'],
        fontsizeOcultarCamarero: json['fontsizeOcultarCamarero'],
        fontsizeXOcultarCamarero: json['fontsizeXOcultarCamarero'],
        fontsizeYOcultarCamarero: json['fontsizeYOcultarCamarero'],
        ocultarCliente: json['ocultarCliente'],
        fontsizeOcultarCliente: json['fontsizeOcultarCliente'],
        fontsizeXOcultarCliente: json['fontsizeXOcultarCliente'],
        fontsizeYOcultarCliente: json['fontsizeYOcultarCliente'],
        ocultarMesa: json['ocultarMesa'],
        fontsizeOcultarMesa: json['fontsizeOcultarMesa'],
        fontsizeXOcultarMesa: json['fontsizeXOcultarMesa'],
        fontsizeYOcultarMesa: json['fontsizeYOcultarMesa'],
        ocultarSalon: json['ocultarSalon'],
        fontsizeOcultarSalon: json['fontsizeOcultarSalon'],
        fontsizeXOcultarSalon: json['fontsizeXOcultarSalon'],
        fontsizeYOcultarSalon: json['fontsizeYOcultarSalon'],
        ocultarArea: json['ocultarArea'],
        fontsizeOcultarArea: json['fontsizeOcultarArea'],
        fontsizeXOcultarArea: json['fontsizeXOcultarArea'],
        fontsizeYOcultarArea: json['fontsizeYOcultarArea'],
        ocultarItems: json['ocultarItems'],
        fontsizeOcultarItems: json['fontsizeOcultarItems'],
        fontsizeXOcultarItems: json['fontsizeXOcultarItems'],
        fontsizeYOcultarItems: json['fontsizeYOcultarItems'],
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
        'fontsizeNumeroOrden': fontsizeNumeroOrden,
        'fontsizeXNumeroOrden': fontsizeXNumeroOrden,
        'fontsizeYNumeroOrden': fontsizeYNumeroOrden,
        'ocultarFecha': ocultarFecha,
        'fontsizeOcultarFecha': fontsizeOcultarFecha,
        'fontsizeXOcultarFecha': fontsizeXOcultarFecha,
        'fontsizeYOcultarFecha': fontsizeYOcultarFecha,
        'ocultarCamarero': ocultarCamarero,
        'fontsizeOcultarCamarero': fontsizeOcultarCamarero,
        'fontsizeXOcultarCamarero': fontsizeXOcultarCamarero,
        'fontsizeYOcultarCamarero': fontsizeYOcultarCamarero,
        'ocultarCliente': ocultarCliente,
        'fontsizeOcultarCliente': fontsizeOcultarCliente,
        'fontsizeXOcultarCliente': fontsizeXOcultarCliente,
        'fontsizeYOcultarCliente': fontsizeYOcultarCliente,
        'ocultarMesa': ocultarMesa,
        'fontsizeOcultarMesa': fontsizeOcultarMesa,
        'fontsizeXOcultarMesa': fontsizeXOcultarMesa,
        'fontsizeYOcultarMesa': fontsizeYOcultarMesa,
        'ocultarSalon': ocultarSalon,
        'fontsizeOcultarSalon': fontsizeOcultarSalon,
        'fontsizeXOcultarSalon': fontsizeXOcultarSalon,
        'fontsizeYOcultarSalon': fontsizeYOcultarSalon,
        'ocultarArea': ocultarArea,
        'fontsizeOcultarArea': fontsizeOcultarArea,
        'fontsizeXOcultarArea': fontsizeXOcultarArea,
        'fontsizeYOcultarArea': fontsizeYOcultarArea,
        'ocultarItems': ocultarItems,
        'fontsizeOcultarItems': fontsizeOcultarItems,
        'fontsizeXOcultarItems': fontsizeXOcultarItems,
        'fontsizeYOcultarItems': fontsizeYOcultarItems,
        'tipoImpresora': tipoImpresora,
        'tipoImpresion': tipoImpresion,
      };
}
