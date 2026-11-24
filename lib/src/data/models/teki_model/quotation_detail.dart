import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';

class QuotationDetail {
  final int? tipoComercialId;
  final String? tipoComercialNombre;
  final String? tipoComercialCategoria;
  final int? productoPrecioId;
  final double? precioReferencia;
  final String? origenPrecio;
  final int? proveedorId;
  final int? detalleOrigenId;
  final int? promocionId;
  final bool? esBonificacion;

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
  final String? estado;
  final Product? producto;

  QuotationDetail({
    this.tipoComercialId,
    this.tipoComercialNombre,
    this.tipoComercialCategoria,
    this.productoPrecioId,
    this.precioReferencia,
    this.origenPrecio,
    this.proveedorId,
    this.detalleOrigenId,
    this.promocionId,
    this.esBonificacion,

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
    this.estado,
    this.producto,
  });

  factory QuotationDetail.fromJson(
    Map<String, dynamic> json,
  ) => QuotationDetail(
            tipoComercialId: (json['tipoComercialId'] as num?)?.toInt(),
        tipoComercialNombre: json['tipoComercialNombre'] as String?,
        tipoComercialCategoria: json['tipoComercialCategoria'] as String?,
        productoPrecioId: (json['productoPrecioId'] as num?)?.toInt(),
        precioReferencia: (json['precioReferencia'] as num?)?.toDouble(),
        origenPrecio: json['origenPrecio'] as String?,
        proveedorId: (json['proveedorId'] as num?)?.toInt(),
        detalleOrigenId: (json['detalleOrigenId'] as num?)?.toInt(),
        promocionId: (json['promocionId'] as num?)?.toInt(),
        esBonificacion: json['esBonificacion'] as bool?,
id: json['id'],
    numeroOrden: json['numeroOrden'],
    numeroItem: json['numeroItem'],
    cantidad: (json['cantidad'] as num?)?.toDouble(),
    codigoUnidadMedida: json['codigoUnidadMedida'],
    descripcion: json['descripcion'],
    detalle: json['detalle'],
    codigoProductoSunat: json['codigoProductoSunat'],
    codigoProducto: json['codigoProducto'],
    codigoProductoGS1: json['codigoProductoGS1'],
    valorUnitario: (json['valorUnitario'] as num?)?.toDouble(),
    precioVentaUnitario: (json['precioVentaUnitario'] as num?)?.toDouble(),
    valorReferencialUnitario: (json['valorReferencialUnitario'] as num?)
        ?.toDouble(),
    montoBaseIgv: (json['montoBaseIgv'] as num?)?.toDouble(),
    montoBaseIvap: (json['montoBaseIvap'] as num?)?.toDouble(),
    montoBaseExportacion: (json['montoBaseExportacion'] as num?)?.toDouble(),
    montoBaseExonerado: (json['montoBaseExonerado'] as num?)?.toDouble(),
    montoBaseInafecto: (json['montoBaseInafecto'] as num?)?.toDouble(),
    montoBaseGratuito: (json['montoBaseGratuito'] as num?)?.toDouble(),
    montoBaseIsc: (json['montoBaseIsc'] as num?)?.toDouble(),
    tributoVentaGratuita: (json['tributoVentaGratuita'] as num?)?.toDouble(),
    tributoBolsa: (json['tributoBolsa'] as num?)?.toDouble(),
    ivap: (json['ivap'] as num?)?.toDouble(),
    igv: (json['igv'] as num?)?.toDouble(),
    isc: (json['isc'] as num?)?.toDouble(),
    porcentajeIgv: (json['porcentajeIgv'] as num?)?.toDouble(),
    porcentajeIvap: (json['porcentajeIvap'] as num?)?.toDouble(),
    porcentajeIsc: (json['porcentajeIsc'] as num?)?.toDouble(),
    porcentajeOtrosTributos: (json['porcentajeOtrosTributos'] as num?)
        ?.toDouble(),
    porcentajeTributoVentaGratuita:
        (json['porcentajeTributoVentaGratuita'] as num?)?.toDouble(),
    codigoTipoCalculoIsc: json['codigoTipoCalculoIsc'],
    codigoTipoAfectacionIgv: json['codigoTipoAfectacionIgv'],
    valorVenta: (json['valorVenta'] as num?)?.toDouble(),
    precioTotal: (json['precioTotal'] as num?)?.toDouble(),
    montoBaseDescuento: (json['montoBaseDescuento'] as num?)?.toDouble(),
    porcentajeDescuento: (json['porcentajeDescuento'] as num?)?.toDouble(),
    descuento: (json['descuento'] as num?)?.toDouble(),
    codigoDescuento: json['codigoDescuento'],
    estado: json['estado'],
    producto: json['producto'] != null
        ? Product.fromJson(json['producto'])
        : null,
  );

  Map<String, dynamic> toJson() => {
            'tipoComercialId': tipoComercialId,
        'tipoComercialNombre': tipoComercialNombre,
        'tipoComercialCategoria': tipoComercialCategoria,
        'productoPrecioId': productoPrecioId,
        'precioReferencia': precioReferencia,
        'origenPrecio': origenPrecio,
        'proveedorId': proveedorId,
        'detalleOrigenId': detalleOrigenId,
        'promocionId': promocionId,
        'esBonificacion': esBonificacion,
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
    'estado': estado,
    'producto': producto?.toJson(),
  };

  /// Convierte este detalle de cotización en un detalle de ticket,
  /// para poder reutilizar el formulario de venta en la edición de cotizaciones.
  /// [keepId]: false cuando el detalle se usa para crear un Ticket NUEVO
  /// (p. ej. "Generar venta" desde una cotización). El id de QuotationDetail
  /// no corresponde a una fila de TicketDetail; enviarlo hace que Hibernate
  /// trate el detalle como una entidad "detached" y falle el persist.
  TicketDetail toTicketDetail({bool keepId = true}) {
    return TicketDetail(
      tipoComercialId: tipoComercialId,
      tipoComercialNombre: tipoComercialNombre,
      tipoComercialCategoria: tipoComercialCategoria,
      productoPrecioId: productoPrecioId,
      precioReferencia: precioReferencia,
      origenPrecio: origenPrecio,
      proveedorId: proveedorId,
      detalleOrigenId: id ?? detalleOrigenId,
      promocionId: promocionId,
      esBonificacion: esBonificacion,

      id: keepId ? id : null,
      numeroOrden: numeroOrden,
      numeroItem: numeroItem,
      cantidad: cantidad,
      codigoUnidadMedida: codigoUnidadMedida,
      descripcion: descripcion,
      detalle: detalle,
      codigoProductoSunat: codigoProductoSunat,
      codigoProducto: codigoProducto,
      codigoProductoGS1: codigoProductoGS1,
      valorUnitario: valorUnitario,
      precioVentaUnitario: precioVentaUnitario,
      valorReferencialUnitario: valorReferencialUnitario,
      montoBaseIgv: montoBaseIgv,
      montoBaseIvap: montoBaseIvap,
      montoBaseExportacion: montoBaseExportacion,
      montoBaseExonerado: montoBaseExonerado,
      montoBaseInafecto: montoBaseInafecto,
      montoBaseGratuito: montoBaseGratuito,
      montoBaseIsc: montoBaseIsc,
      tributoVentaGratuita: tributoVentaGratuita,
      tributoBolsa: tributoBolsa,
      ivap: ivap,
      igv: igv,
      isc: isc,
      porcentajeIgv: porcentajeIgv,
      porcentajeIvap: porcentajeIvap,
      porcentajeIsc: porcentajeIsc,
      porcentajeOtrosTributos: porcentajeOtrosTributos,
      porcentajeTributoVentaGratuita: porcentajeTributoVentaGratuita,
      codigoTipoCalculoIsc: codigoTipoCalculoIsc,
      codigoTipoAfectacionIgv: codigoTipoAfectacionIgv,
      valorVenta: valorVenta,
      precioTotal: precioTotal,
      montoBaseDescuento: montoBaseDescuento,
      porcentajeDescuento: porcentajeDescuento,
      descuento: descuento,
      codigoDescuento: codigoDescuento,
      producto: producto,
    );
  }
}
