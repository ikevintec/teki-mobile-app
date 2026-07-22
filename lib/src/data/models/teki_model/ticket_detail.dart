import 'dart:ffi';

import 'package:teki_app/src/data/models/teki_model/batch_product_sale.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_dispatch_detail.dart';
import 'package:teki_app/src/utils/formats.dart';

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
  //Borrar de ser necesario
  final double? montoOriginal;
  final bool? tieneImpuestoBolsas;
  final double? porcentajeDescuentoGlobal;
  final double? porcentajeOtrosCargos;
  final String? monedaOriginal;
  final Double? interes;

  TicketDetail(
      {this.id,
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
      this.montoOriginal,
      this.tieneImpuestoBolsas,
      this.porcentajeDescuentoGlobal,
      this.porcentajeOtrosCargos,
      this.monedaOriginal,
      this.interes});

  factory TicketDetail.fromJson(Map<String, dynamic> json) => TicketDetail(
        id: json['id'],
        numeroOrden: json['numeroOrden'],
        numeroItem: json['numeroItem'],
        cantidad: (json['cantidad'] ?? 0).toDouble(),
        codigoUnidadMedida: json['codigoUnidadMedida'],
        descripcion: json['descripcion'],
        detalle: json['detalle'],
        codigoProductoSunat: json['codigoProductoSunat'],
        codigoProducto: json['codigoProducto'],
        codigoProductoGS1: json['codigoProductoGS1'],
        valorUnitario: (json['valorUnitario'] ?? 0).toDouble(),
        precioCompraUnitario: (json['precioCompraUnitario'] ?? 0).toDouble(),
        precioVentaUnitario: (json['precioVentaUnitario'] ?? 0).toDouble(),
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
        producto: json['producto'] != null
            ? Product.fromJson(json['producto'])
            : null,
        comandaDetalle: json['comandaDetalle'] != null
            ? CommandDetail.fromJson(json['comandaDetalle'])
            : null,
        lotes: json['lotes'] != null
            ? List<BatchProductSale>.from(
                json['lotes'].map((x) => BatchProductSale.fromJson(x)))
            : null,
        despachos: json['despachos'] != null
            ? List<TicketDispatchDetail>.from(
                json['despachos'].map((x) => TicketDispatchDetail.fromJson(x)))
            : null,
        estadoDespacho: json['estadoDespacho'],
        fechaInicioPlan: json['fechaInicioPlan'] != null
            ? parseDateTimeFlexible(json['fechaInicioPlan'])
            : null,
        modificado: json['modificado'],
        eliminado: json['eliminado'],
        createdOn: json['createdOn'] != null
            ? parseDateTimeFlexible(json['createdOn'])
            : null,
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: json['updatedOn'] != null
            ? parseDateTimeFlexible(json['updatedOn'])
            : null,
        deleteBy: json['deleteBy'],
        deletedOn: json['deletedOn'] != null
            ? parseDateTimeFlexible(json['deletedOn'])
            : null,
        porcentajeDescuentoGlobal:
            json['porcentajeDescuentoGlobal']?.toDouble(),
        montoOriginal: json['montoOriginal']?.toDouble(),
        interes: json['interes']?.toDouble(),
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
        //descuento
        if (descuento != null) 'descuento': descuento,
        if (descuento != null) 'montoBaseDescuento': montoBaseDescuento,
        if (descuento != null) 'porcentajeDescuento': porcentajeDescuento,
        if (descuento != null) 'codigoDescuento': "00",

        //interes
        if (interes != null) 'interes': interes,
        'esAnticipo': esAnticipo,
        'estado': estado,
        'uuid': uuid,
        'uuidRelated': uuidRelated,
        'ticket': ticket?.toJson(),
        'producto': producto?.toJson(),
        if (comandaDetalle != null) 'comandaDetalle': comandaDetalle?.toJson(),
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
        //Borrar de ser necesario
        'montoOriginal': montoOriginal,
        'tieneImpuestoBolsas': tieneImpuestoBolsas,
        'porcentajeDescuentoGlobal': porcentajeDescuentoGlobal,
        'porcentajeOtrosCargos': porcentajeOtrosCargos,
        'monedaOriginal': monedaOriginal,
      };

  // implement copywith
  TicketDetail copyWith({
    int? id,
    int? numeroOrden,
    int? numeroItem,
    double? cantidad,
    String? codigoUnidadMedida,
    String? descripcion,
    String? detalle,
    String? codigoProductoSunat,
    String? codigoProducto,
    String? codigoProductoGS1,
    double? valorUnitario,
    double? precioCompraUnitario,
    double? precioVentaUnitario,
    double? valorReferencialUnitario,
    double? montoBaseIgv,
    double? montoBaseIvap,
    double? montoBaseExportacion,
    double? montoBaseExonerado,
    double? montoBaseInafecto,
    double? montoBaseGratuito,
    double? montoBaseIsc,
    double? tributoVentaGratuita,
    double? tributoBolsa,
    double? ivap,
    double? igv,
    double? isc,
    double? porcentajeIgv,
    double? porcentajeIvap,
    double? porcentajeIsc,
    double? porcentajeOtrosTributos,
    double? porcentajeTributoVentaGratuita,
    String? codigoTipoCalculoIsc,
    String? codigoTipoAfectacionIgv,
    double? valorVenta,
    double? precioTotal,
    double? montoBaseDescuento,
    double? porcentajeDescuento,
    double? descuento,
    String? codigoDescuento,
    bool? esAnticipo,
    bool? estado,
    String? uuid,
    String? uuidRelated,
    Ticket? ticket,
    Product? producto,
    CommandDetail? comandaDetalle,
    List<BatchProductSale>? lotes,
    List<TicketDispatchDetail>? despachos,
    String? estadoDespacho,
    DateTime? fechaInicioPlan,
    bool? modificado,
    bool? eliminado,
    DateTime? createdOn,
    int? createdBy,
    int? updatedBy,
    DateTime? updatedOn,
    int? deleteBy,
    DateTime? deletedOn,
    double? montoOriginal,
    bool? tieneImpuestoBolsas,
    double? porcentajeDescuentoGlobal,
    double? porcentajeOtrosCargos,
    String? monedaOriginal,
  }) {
    return TicketDetail(
      id: id ?? this.id,
      numeroOrden: numeroOrden ?? this.numeroOrden,
      numeroItem: numeroItem ?? this.numeroItem,
      cantidad: cantidad ?? this.cantidad,
      codigoUnidadMedida: codigoUnidadMedida ?? this.codigoUnidadMedida,
      descripcion: descripcion ?? this.descripcion,
      detalle: detalle ?? this.detalle,
      codigoProductoSunat: codigoProductoSunat ?? this.codigoProductoSunat,
      codigoProducto: codigoProducto ?? this.codigoProducto,
      codigoProductoGS1: codigoProductoGS1 ?? this.codigoProductoGS1,
      valorUnitario: valorUnitario ?? this.valorUnitario,
      precioCompraUnitario: precioCompraUnitario ?? this.precioCompraUnitario,
      precioVentaUnitario: precioVentaUnitario ?? this.precioVentaUnitario,
      valorReferencialUnitario:
          valorReferencialUnitario ?? this.valorReferencialUnitario,
      montoBaseIgv: montoBaseIgv ?? this.montoBaseIgv,
      montoBaseIvap: montoBaseIvap ?? this.montoBaseIvap,
      montoBaseExportacion: montoBaseExportacion ?? this.montoBaseExportacion,
      montoBaseExonerado: montoBaseExonerado ?? this.montoBaseExonerado,
      montoBaseInafecto: montoBaseInafecto ?? this.montoBaseInafecto,
      montoBaseGratuito: montoBaseGratuito ?? this.montoBaseGratuito,
      montoBaseIsc: montoBaseIsc ?? this.montoBaseIsc,
      tributoVentaGratuita: tributoVentaGratuita ?? this.tributoVentaGratuita,
      tributoBolsa: tributoBolsa ?? this.tributoBolsa,
      ivap: ivap ?? this.ivap,
      igv: igv ?? this.igv,
      isc: isc ?? this.isc,
      porcentajeIgv: porcentajeIgv ?? this.porcentajeIgv,
      porcentajeIvap: porcentajeIvap ?? this.porcentajeIvap,
      porcentajeIsc: porcentajeIsc ?? this.porcentajeIsc,
      porcentajeOtrosTributos:
          porcentajeOtrosTributos ?? this.porcentajeOtrosTributos,
      porcentajeTributoVentaGratuita:
          porcentajeTributoVentaGratuita ?? this.porcentajeTributoVentaGratuita,
      codigoTipoCalculoIsc: codigoTipoCalculoIsc ?? this.codigoTipoCalculoIsc,
      codigoTipoAfectacionIgv:
          codigoTipoAfectacionIgv ?? this.codigoTipoAfectacionIgv,
      valorVenta: valorVenta ?? this.valorVenta,
      precioTotal: precioTotal ?? this.precioTotal,
      montoBaseDescuento: montoBaseDescuento ?? this.montoBaseDescuento,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      descuento: descuento ?? this.descuento,
      codigoDescuento: codigoDescuento ?? this.codigoDescuento,
      esAnticipo: esAnticipo ?? this.esAnticipo,
      estado: estado ?? this.estado,
      uuid: uuid ?? this.uuid,
      uuidRelated: uuidRelated ?? this.uuidRelated,
      ticket: ticket ?? this.ticket,
      producto: producto ?? this.producto,
      comandaDetalle: comandaDetalle ?? this.comandaDetalle,
      lotes: lotes ?? this.lotes,
      despachos: despachos ?? this.despachos,
      estadoDespacho: estadoDespacho ?? this.estadoDespacho,
      fechaInicioPlan: fechaInicioPlan ?? this.fechaInicioPlan,
      modificado: modificado ?? this.modificado,
      eliminado: eliminado ?? this.eliminado,
      createdOn: createdOn ?? this.createdOn,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedOn: updatedOn ?? this.updatedOn,
      deleteBy: deleteBy ?? this.deleteBy,
      deletedOn: deletedOn ?? this.deletedOn,
      montoOriginal: montoOriginal ?? this.montoOriginal,
      tieneImpuestoBolsas: tieneImpuestoBolsas ?? this.tieneImpuestoBolsas,
      porcentajeDescuentoGlobal:
          porcentajeDescuentoGlobal ?? this.porcentajeDescuentoGlobal,
      porcentajeOtrosCargos:
          porcentajeOtrosCargos ?? this.porcentajeOtrosCargos,
      monedaOriginal: monedaOriginal ?? this.monedaOriginal,
    );
  }
}
