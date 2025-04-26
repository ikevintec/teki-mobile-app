import 'package:teki_app/src/data/models/batchProductSale.dart';
import 'package:teki_app/src/data/models/commandDetail.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/ticket.dart';
import 'package:teki_app/src/data/models/ticketDispatchDetail.dart';

class TicketDetail {
  final int? id;
  final int? numeroOrden;
  final int? numeroItem;
  final double? cantidad;
  final String? codigoUnidadMedida;
  final String? descripcion;
  final String? detalle;
  final String? codigoProductoSunat;
  final String? codigoProducto;
  final String? codigoProductoGS1;
  final double? valorUnitario;
  final double? precioCompraUnitario;
  final double? precioVentaUnitario;
  final double? valorReferencialUnitario;
  final double? montoBaseIgv;
  final double? montoBaseIvap;
  final double? montoBaseExportacion;
  final double? montoBaseExonerado;
  final double? montoBaseInafecto;
  final double? montoBaseGratuito;
  final double? montoBaseIsc;
  final double? tributoVentaGratuita;
  final double? tributoBolsa;
  final double? ivap;
  final double? igv;
  final double? isc;
  final double? porcentajeIgv;
  final double? porcentajeIvap;
  final double? porcentajeIsc;
  final double? porcentajeOtrosTributos;
  final double? porcentajeTributoVentaGratuita;
  final String? codigoTipoCalculoIsc;
  final String? codigoTipoAfectacionIgv;
  final double? valorVenta;
  final double? precioTotal;
  final double? montoBaseDescuento;
  final double? porcentajeDescuento;
  final double? descuento;
  final String? codigoDescuento;
  final bool? esAnticipo;
  final bool? estado;
  final String? uuid;
  final String? uuidRelated;
  final Ticket? ticket;
  final Product? producto;
  final CommandDetail? comandaDetalle;
  final List<BatchProductSale>? lotes;
  final List<TicketDispatchDetail>? despachos;
  final String? estadoDespacho;
  final DateTime? fechaInicioPlan;
  final bool? modificado;
  final bool? eliminado;
  final DateTime? createdOn;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;

  TicketDetail({
    this.id,
    this.numeroOrden,
    this.numeroItem,
    this.cantidad,
    this.codigoUnidadMedida,
    this.descripcion,
    this.detalle,
    this.codigoProductoSunat,
    this.codigoProducto,
    this.codigoProductoGS1,
    this.valorUnitario,
    this.precioCompraUnitario,
    this.precioVentaUnitario,
    this.valorReferencialUnitario,
    this.montoBaseIgv,
    this.montoBaseIvap,
    this.montoBaseExportacion,
    this.montoBaseExonerado,
    this.montoBaseInafecto,
    this.montoBaseGratuito,
    this.montoBaseIsc,
    this.tributoVentaGratuita,
    this.tributoBolsa,
    this.ivap,
    this.igv,
    this.isc,
    this.porcentajeIgv,
    this.porcentajeIvap,
    this.porcentajeIsc,
    this.porcentajeOtrosTributos,
    this.porcentajeTributoVentaGratuita,
    this.codigoTipoCalculoIsc,
    this.codigoTipoAfectacionIgv,
    this.valorVenta,
    this.precioTotal,
    this.montoBaseDescuento,
    this.porcentajeDescuento,
    this.descuento,
    this.codigoDescuento,
    this.esAnticipo,
    this.estado,
    this.uuid,
    this.uuidRelated,
    this.ticket,
    this.producto,
    this.comandaDetalle,
    this.lotes,
    this.despachos,
    this.estadoDespacho,
    this.fechaInicioPlan,
    this.modificado,
    this.eliminado,
    this.createdOn,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) => TicketDetail(
    id: json['id'],
    numeroOrden: json['numeroOrden'],
    numeroItem: json['numeroItem'],
    cantidad: json['cantidad'],
    codigoUnidadMedida: json['codigoUnidadMedida'],
    descripcion: json['descripcion'],
    detalle: json['detalle'],
    codigoProductoSunat: json['codigoProductoSunat'],
    codigoProducto: json['codigoProducto'],
    codigoProductoGS1: json['codigoProductoGS1'],
    valorUnitario: json['valorUnitario'],
    precioCompraUnitario: json['precioCompraUnitario'],
    precioVentaUnitario: json['precioVentaUnitario'],
    valorReferencialUnitario: json['valorReferencialUnitario'],
    montoBaseIgv: json['montoBaseIgv'],
    montoBaseIvap: json['montoBaseIvap'],
    montoBaseExportacion: json['montoBaseExportacion'],
    montoBaseExonerado: json['montoBaseExonerado'],
    montoBaseInafecto: json['montoBaseInafecto'],
    montoBaseGratuito: json['montoBaseGratuito'],
    montoBaseIsc: json['montoBaseIsc'],
    tributoVentaGratuita: json['tributoVentaGratuita'],
    tributoBolsa: json['tributoBolsa'],
    ivap: json['ivap'],
    igv: json['igv'],
    isc: json['isc'],
    porcentajeIgv: json['porcentajeIgv'],
    porcentajeIvap: json['porcentajeIvap'],
    porcentajeIsc: json['porcentajeIsc'],
    porcentajeOtrosTributos: json['porcentajeOtrosTributos'],
    porcentajeTributoVentaGratuita: json['porcentajeTributoVentaGratuita'],
    codigoTipoCalculoIsc: json['codigoTipoCalculoIsc'],
    codigoTipoAfectacionIgv: json['codigoTipoAfectacionIgv'],
    valorVenta: json['valorVenta'],
    precioTotal: json['precioTotal'],
    montoBaseDescuento: json['montoBaseDescuento'],
    porcentajeDescuento: json['porcentajeDescuento'],
    descuento: json['descuento'],
    codigoDescuento: json['codigoDescuento'],
    esAnticipo: json['esAnticipo'],
    estado: json['estado'],
    uuid: json['uuid'],
    uuidRelated: json['uuidRelated'],
    ticket: json['ticket'] != null ? Ticket.fromJson(json['ticket']) : null,
    producto: json['producto'] != null ? Product.fromJson(json['producto']) : null,
    comandaDetalle: json['comandaDetalle'] != null ? CommandDetail.fromJson(json['comandaDetalle']) : null,
    lotes: json['lotes'] != null ? List<BatchProductSale>.from(json['lotes'].map((x) => BatchProductSale.fromJson(x))) : null,
    despachos: json['despachos'] != null ? List<TicketDispatchDetail>.from(json['despachos'].map((x) => TicketDispatchDetail.fromJson(x))) : null,
    estadoDespacho: json['estadoDespacho'],
    fechaInicioPlan: json['fechaInicioPlan'] != null ? DateTime.parse(json['fechaInicioPlan']) : null,
    modificado: json['modificado'],
    eliminado: json['eliminado'],
    createdOn: json['createdOn'] != null ? DateTime.parse(json['createdOn']) : null,
    createdBy: json['createdBy'],
    updatedBy: json['updatedBy'],
    updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
    deleteBy: json['deleteBy'],
    deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'numeroOrden': numeroOrden,
    'numeroItem': numeroItem,
    'cantidad': cantidad,
    'codigoUnidadMedida': codigoUnidadMedida,
    'descripcion': descripcion,
    'detalle': detalle,
    'codigoProductoSunat': codigoProductoSunat,
    'codigoProducto': codigoProducto,
    'codigoProductoGS1': codigoProductoGS1,
    'valorUnitario': valorUnitario,
    'precioCompraUnitario': precioCompraUnitario,
    'precioVentaUnitario': precioVentaUnitario,
    'valorReferencialUnitario': valorReferencialUnitario,
    'montoBaseIgv': montoBaseIgv,
    'montoBaseIvap': montoBaseIvap,
    'montoBaseExportacion': montoBaseExportacion,
    'montoBaseExonerado': montoBaseExonerado,
    'montoBaseInafecto': montoBaseInafecto,
    'montoBaseGratuito': montoBaseGratuito,
    'montoBaseIsc': montoBaseIsc,
    'tributoVentaGratuita': tributoVentaGratuita,
    'tributoBolsa': tributoBolsa,
    'ivap': ivap,
    'igv': igv,
    'isc': isc,
    'porcentajeIgv': porcentajeIgv,
    'porcentajeIvap': porcentajeIvap,
    'porcentajeIsc': porcentajeIsc,
    'porcentajeOtrosTributos': porcentajeOtrosTributos,
    'porcentajeTributoVentaGratuita': porcentajeTributoVentaGratuita,
    'codigoTipoCalculoIsc': codigoTipoCalculoIsc,
    'codigoTipoAfectacionIgv': codigoTipoAfectacionIgv,
    'valorVenta': valorVenta,
    'precioTotal': precioTotal,
    'montoBaseDescuento': montoBaseDescuento,
    'porcentajeDescuento': porcentajeDescuento,
    'descuento': descuento,
    'codigoDescuento': codigoDescuento,
    'esAnticipo': esAnticipo,
    'estado': estado,
    'uuid': uuid,
    'uuidRelated': uuidRelated,
    'ticket': ticket?.toJson(),
    'producto': producto?.toJson(),
    'comandaDetalle': comandaDetalle?.toJson(),
    'lotes': lotes?.map((x) => x.toJson()).toList(),
    'despachos': despachos?.map((x) => x.toJson()).toList(),
    'estadoDespacho': estadoDespacho,
    'fechaInicioPlan': fechaInicioPlan?.toIso8601String(),
    'modificado': modificado,
    'eliminado': eliminado,
    'createdOn': createdOn?.toIso8601String(),
    'createdBy': createdBy,
    'updatedBy': updatedBy,
    'updatedOn': updatedOn?.toIso8601String(),
    'deleteBy': deleteBy,
    'deletedOn': deletedOn?.toIso8601String(),
  };
}
