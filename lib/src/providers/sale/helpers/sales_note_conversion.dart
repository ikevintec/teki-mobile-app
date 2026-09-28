import 'package:teki_app/src/data/models/teki_model/additional_field.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product_sale.dart';
import 'package:teki_app/src/data/models/teki_model/guia_relacionada.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';

bool canConvertSalesNote(Ticket ticket) {
  return ticket.tipoComprobante == 'NV' &&
      ticket.anulado != true &&
      (ticket.comprobanteSustituto?.trim().isEmpty ?? true);
}

Ticket buildTicketFromSalesNote({
  required Ticket source,
  required DateTime now,
  Office? pointOfSale,
  SaleStation? saleStation,
  User? seller,
}) {
  if (!canConvertSalesNote(source) ||
      (source.identificadorDocumento?.trim().isEmpty ?? true)) {
    throw ArgumentError('La nota de venta no se puede convertir.');
  }

  final documentType = source.tipoDocumentoReceptor == '1' ? '03' : '01';

  return Ticket(
    tipoComprobante: documentType,
    fechaEmisionDate: now,
    codigoMoneda: source.codigoMoneda,
    codigoTipoOperacion: '0101',
    tipoDocumentoReceptor: source.tipoDocumentoReceptor,
    numeroDocumentoReceptor: source.numeroDocumentoReceptor,
    denominacionReceptor: source.denominacionReceptor,
    direccionReceptor: source.direccionReceptor,
    emailReceptor: source.emailReceptor,
    telefonoReceptor: source.telefonoReceptor,
    cliente: source.cliente,
    camposAdicionales: source.camposAdicionales?.map(_cloneField).toList(),
    tipoVenta: source.tipoVenta,
    diasCredito: source.diasCredito,
    totalVentaCredito: source.totalVentaCredito,
    observacion: source.observacion,
    otrosCargos: source.otrosCargos,
    otrosTributos: source.otrosTributos,
    porcentajeOtrosCargos: source.porcentajeOtrosCargos,
    regimenPercepcion: source.regimenPercepcion,
    porcentajePercepcion: source.porcentajePercepcion,
    porcentajeDescuentoGlobal: source.porcentajeDescuentoGlobal,
    numeroCotizacion: source.numeroCotizacion,
    incIgv: source.incIgv ?? true,
    agruparItems: source.agruparItems ?? false,
    items: source.items?.map(_cloneItem).toList(),
    guiasRelacionadas: source.guiasRelacionadas?.map(_cloneGuide).toList(),
    idNotaVentaAnulada: source.identificadorDocumento,
    puntoVenta: pointOfSale,
    estacionVenta: saleStation,
    vendedor: seller,
    cambio: 0,
    despachoPosterior: false,
    isRetencion: false,
    pagoAnticipado: false,
  );
}

AditionalField _cloneField(AditionalField source) => AditionalField(
  nombreCampo: source.nombreCampo,
  valorCampo: source.valorCampo,
);

GuiaRelacionada _cloneGuide(GuiaRelacionada source) => GuiaRelacionada(
  codigoTipoGuia: source.codigoTipoGuia,
  serieNumeroGuia: source.serieNumeroGuia,
);

BatchProductSale _cloneBatchSale(BatchProductSale source) =>
    BatchProductSale(lote: source.lote, cantidad: source.cantidad);

TicketDetail _cloneItem(TicketDetail source) => TicketDetail(
  numeroOrden: source.numeroOrden,
  numeroItem: source.numeroItem,
  cantidad: source.cantidad,
  codigoUnidadMedida: source.codigoUnidadMedida,
  descripcion: source.descripcion,
  detalle: source.detalle,
  codigoProductoSunat: source.codigoProductoSunat,
  codigoProducto: source.codigoProducto,
  codigoProductoGS1: source.codigoProductoGS1,
  valorUnitario: source.valorUnitario,
  precioCompraUnitario: source.precioCompraUnitario,
  precioVentaUnitario: source.precioVentaUnitario,
  valorReferencialUnitario: source.valorReferencialUnitario,
  montoBaseIgv: source.montoBaseIgv,
  montoBaseIvap: source.montoBaseIvap,
  montoBaseExportacion: source.montoBaseExportacion,
  montoBaseExonerado: source.montoBaseExonerado,
  montoBaseInafecto: source.montoBaseInafecto,
  montoBaseGratuito: source.montoBaseGratuito,
  montoBaseIsc: source.montoBaseIsc,
  tributoVentaGratuita: source.tributoVentaGratuita,
  tributoBolsa: source.tributoBolsa,
  ivap: source.ivap,
  igv: source.igv,
  isc: source.isc,
  porcentajeIgv: source.porcentajeIgv,
  porcentajeIvap: source.porcentajeIvap,
  porcentajeIsc: source.porcentajeIsc,
  porcentajeOtrosTributos: source.porcentajeOtrosTributos,
  porcentajeTributoVentaGratuita: source.porcentajeTributoVentaGratuita,
  codigoTipoCalculoIsc: source.codigoTipoCalculoIsc,
  codigoTipoAfectacionIgv: source.codigoTipoAfectacionIgv,
  valorVenta: source.valorVenta,
  precioTotal: source.precioTotal,
  montoBaseDescuento: source.montoBaseDescuento,
  porcentajeDescuento: source.porcentajeDescuento,
  descuento: source.descuento,
  codigoDescuento: source.codigoDescuento,
  esAnticipo: source.esAnticipo,
  devolvioEnvase: source.devolvioEnvase,
  estado: source.estado,
  producto: source.producto,
  lotes: source.lotes?.map(_cloneBatchSale).toList(),
  estadoDespacho: source.estadoDespacho,
  fechaInicioPlan: source.fechaInicioPlan,
  montoOriginal: source.montoOriginal,
  tieneImpuestoBolsas: source.tieneImpuestoBolsas,
  porcentajeDescuentoGlobal: source.porcentajeDescuentoGlobal,
  porcentajeOtrosCargos: source.porcentajeOtrosCargos,
  monedaOriginal: source.monedaOriginal,
  interes: source.interes,
);
