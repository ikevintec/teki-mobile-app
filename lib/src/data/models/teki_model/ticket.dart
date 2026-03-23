import 'package:teki_app/src/data/models/teki_model/aditionalField.dart';
import 'package:teki_app/src/data/models/teki_model/anticipo.dart';
import 'package:teki_app/src/data/models/teki_model/attachedCompany.dart';
import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/guiaRelacionada.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/sunatResponse.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFee.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFile.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class Ticket {
  final int? id;
  final String? serie;
  final int? numero;
  final String? fechaEmision;
  final DateTime? fechaEmisionDate;
  final DateTime? fechaVencimientoDate;
  final String? horaEmision;
  final String? tipoComprobante;
  final String? codigoMoneda;
  final String? fechaVencimiento;
  final String? codigoTipoOperacion;
  final String? rucEmisor;
  final String? razonSocialEmisor;
  final String? codigoLocalAnexoEmisor;
  final String? tipoDocumentoReceptor;
  final String? numeroDocumentoReceptor;
  final String? denominacionReceptor;
  final String? direccionReceptor;
  final String? emailReceptor;
  final String? telefonoReceptor;
  final Customer? cliente;
  final List<AditionalField>? camposAdicionales;
  final List<TicketFee>? cuotas;
  final String? numeroOrdenRestaurante;
  final String? codigoTipoOtroDocumentoRelacionado;
  final String? serieNumeroOtroDocumentoRelacionado;
  final double? totalValorVentaExportacion;
  final double? totalValorVentaGravada;
  final double? totalValorVentaInafecta;
  final double? totalValorVentaExonerada;
  final double? totalValorVentaGratuita;
  final double? totalValorBaseIsc;
  final double? totalValorBaseIgv;
  final double? totalValorVentaGravadaIvap;
  final double? totalTributosOperacionGratuita;
  final double? totalTributosBolsas;
  final double? totalIvap;
  final double? totalIgv;
  final double? totalIsc;
  final double? otrosTributos;
  final double? otrosCargos;
  final double? porcentajeOtrosCargos;
  final double? totalValorVenta;
  final double? totalVenta;
  final double? totalVentaCredito;
  final double? totalAnticipos;
  final bool? pagoAnticipado;
  final String? regimenPercepcion;
  final double? montoPercepcion;
  final double? porcentajePercepcion;
  final double? totalVentaPercepcion;
  final double? montoBaseRetencion;
  final double? montoRetencion;
  final double? porcentajeRetencion;
  final double? montoBaseDescuento;
  final double? porcentajeDescuento;
  final double? totalDescuento;
  final double? descuentoGlobal;
  final double? descuentoPorItem;
  final String? codigoDescuento;
  final double? porcentajeDescuentoGlobal;
  final String? serieAfectado;
  final int? numeroAfectado;
  final String? tipoComprobanteAfectado;
  final String? motivoNota;
  final String? codigoTipoNotaCredito;
  final String? codigoTipoNotaDebito;
  final String? identificadorDocumento;
  final int? estadoItem;
  final String? estadoSunat;
  final String? estado;
  final String? estadoAnterior;
  final String? mensajeRespuesta;
  final String? motivoAnulacion;
  final bool? incIgv;
  final bool? agruparItems;
  final double? efectivo;
  final double? cambio;
  final List<TicketDetail>? items;
  final List<Anticipo>? anticipos;
  final List<GuiaRelacionada>? guiasRelacionadas;
  final String? uuid;
  final String? ordenCompra;
  final String? condicionPago;
  final String? observacion;
  final String? codigosRespuestaSunat;
  final bool? boletaAnuladaSinEmitir;
  final bool? envioAutomaticoSunat;
  final List<TicketFile>? archivos;
  final List<SunatResponse>? sunatRespuestas;
  final String? codigoHash;
  final String? codigoMedioPago;
  final String? cuentaDetraccion;
  final String? codigoDetraccion;
  final double? porcentajeDetraccion;
  final double? montoDetraccion;
  final Company? empresa;
  final AttachedCompany? empresaAdjunta;
  final Office? puntoVenta;
  final SaleStation? estacionVenta;
  final Quotation? cotizacion;
  final String? tipoVenta;
  final bool? esProduccion;
  final int? diasCredito;
  final bool? anulado;
  final String? comprobanteSustituto;
  final bool? isSendBill;
  final String? idNotaVentaAnulada;
  final User? vendedor;
  final OrderRestaurant? pedidoRestaurante;
  final int? cuentaRestaurante;
  final String? canal;
  final String? comprobanteAnterior;
  final CashRegisterDetail? movimientoCaja;
  final int? intentosSendSummary;
  final DateTime? createdOn;
  final double? adelanto;
  final int? createdBy;
  final int? updatedBy;
  final DateTime? updatedOn;
  final int? deleteBy;
  final DateTime? deletedOn;
  final bool? isEdited;
  final String? numeroCotizacion;
  final bool? despachoPosterior;
  final bool? isRetencion;

  Ticket({
    this.id,
    this.serie,
    this.numero,
    this.fechaEmision,
    this.fechaEmisionDate,
    this.fechaVencimientoDate,
    this.horaEmision,
    this.tipoComprobante,
    this.codigoMoneda,
    this.fechaVencimiento,
    this.codigoTipoOperacion,
    this.rucEmisor,
    this.razonSocialEmisor,
    this.codigoLocalAnexoEmisor,
    this.tipoDocumentoReceptor,
    this.numeroDocumentoReceptor,
    this.denominacionReceptor,
    this.direccionReceptor,
    this.emailReceptor,
    this.telefonoReceptor,
    this.cliente,
    this.camposAdicionales,
    this.cuotas,
    this.numeroOrdenRestaurante,
    this.codigoTipoOtroDocumentoRelacionado,
    this.serieNumeroOtroDocumentoRelacionado,
    this.totalValorVentaExportacion,
    this.totalValorVentaGravada,
    this.totalValorVentaInafecta,
    this.totalValorVentaExonerada,
    this.totalValorVentaGratuita,
    this.totalValorBaseIsc,
    this.totalValorBaseIgv,
    this.totalValorVentaGravadaIvap,
    this.totalTributosOperacionGratuita,
    this.totalTributosBolsas,
    this.totalIvap,
    this.totalIgv,
    this.totalIsc,
    this.otrosTributos,
    this.otrosCargos,
    this.porcentajeOtrosCargos,
    this.totalValorVenta,
    this.totalVenta,
    this.totalVentaCredito,
    this.totalAnticipos,
    this.pagoAnticipado,
    this.regimenPercepcion,
    this.montoPercepcion,
    this.porcentajePercepcion,
    this.totalVentaPercepcion,
    this.montoBaseRetencion,
    this.montoRetencion,
    this.porcentajeRetencion,
    this.montoBaseDescuento,
    this.porcentajeDescuento,
    this.totalDescuento,
    this.descuentoGlobal,
    this.descuentoPorItem,
    this.codigoDescuento,
    this.porcentajeDescuentoGlobal,
    this.serieAfectado,
    this.numeroAfectado,
    this.tipoComprobanteAfectado,
    this.motivoNota,
    this.codigoTipoNotaCredito,
    this.codigoTipoNotaDebito,
    this.identificadorDocumento,
    this.estadoItem,
    this.estadoSunat,
    this.estado,
    this.estadoAnterior,
    this.mensajeRespuesta,
    this.motivoAnulacion,
    this.incIgv,
    this.agruparItems,
    this.efectivo,
    this.cambio,
    this.items,
    this.anticipos,
    this.guiasRelacionadas,
    this.uuid,
    this.ordenCompra,
    this.condicionPago,
    this.observacion,
    this.codigosRespuestaSunat,
    this.boletaAnuladaSinEmitir,
    this.envioAutomaticoSunat,
    this.archivos,
    this.sunatRespuestas,
    this.codigoHash,
    this.codigoMedioPago,
    this.cuentaDetraccion,
    this.codigoDetraccion,
    this.porcentajeDetraccion,
    this.montoDetraccion,
    this.empresa,
    this.empresaAdjunta,
    this.puntoVenta,
    this.estacionVenta,
    this.cotizacion,
    this.tipoVenta,
    this.esProduccion,
    this.diasCredito,
    this.anulado,
    this.comprobanteSustituto,
    this.isSendBill,
    this.idNotaVentaAnulada,
    this.vendedor,
    this.pedidoRestaurante,
    this.cuentaRestaurante,
    this.canal,
    this.comprobanteAnterior,
    this.movimientoCaja,
    this.intentosSendSummary,
    this.createdOn,
    this.adelanto,
    this.createdBy,
    this.updatedBy,
    this.updatedOn,
    this.deleteBy,
    this.deletedOn,
    this.isEdited,
    this.numeroCotizacion,
    this.despachoPosterior,
    this.isRetencion,
  });

  factory Ticket.fromJson(Map<String, dynamic> json) => Ticket(
        id: json['id'],
        serie: json['serie'],
        numero: json['numero'],
        fechaEmision: json['fechaEmision'],
        fechaEmisionDate: parseDateTimeFlexible(json['fechaEmisionDate']),
        fechaVencimientoDate: parseDateTimeFlexible(json['fechaVencimientoDate']),
        horaEmision: json['horaEmision'],
        tipoComprobante: json['tipoComprobante'],
        codigoMoneda: json['codigoMoneda'],
        fechaVencimiento: json['fechaVencimiento'],
        codigoTipoOperacion: json['codigoTipoOperacion'],
        rucEmisor: json['rucEmisor'],
        razonSocialEmisor: json['razonSocialEmisor'],
        codigoLocalAnexoEmisor: json['codigoLocalAnexoEmisor'],
        tipoDocumentoReceptor: json['tipoDocumentoReceptor'],
        numeroDocumentoReceptor: json['numeroDocumentoReceptor'],
        denominacionReceptor: json['denominacionReceptor'],
        direccionReceptor: json['direccionReceptor'],
        emailReceptor: json['emailReceptor'],
        telefonoReceptor: json['telefonoReceptor'],
        cliente:
            json['cliente'] != null ? Customer.fromJson(json['cliente']) : null,
        camposAdicionales: json['camposAdicionales'] != null
            ? List<AditionalField>.from(json['camposAdicionales']
                .map((x) => AditionalField.fromJson(x)))
            : null,
        cuotas: json['cuotas'] != null
            ? List<TicketFee>.from(
                json['cuotas'].map((x) => TicketFee.fromJson(x)))
            : null,
        numeroOrdenRestaurante: json['numeroOrdenRestaurante'],
        codigoTipoOtroDocumentoRelacionado:
            json['codigoTipoOtroDocumentoRelacionado'],
        serieNumeroOtroDocumentoRelacionado:
            json['serieNumeroOtroDocumentoRelacionado'],
        totalValorVentaExportacion: json['totalValorVentaExportacion'],
        totalValorVentaGravada: json['totalValorVentaGravada'],
        totalValorVentaInafecta: json['totalValorVentaInafecta'],
        totalValorVentaExonerada: json['totalValorVentaExonerada'],
        totalValorVentaGratuita: json['totalValorVentaGratuita'],
        totalValorBaseIsc: json['totalValorBaseIsc'],
        totalValorBaseIgv: json['totalValorBaseIgv'],
        totalValorVentaGravadaIvap: json['totalValorVentaGravadaIvap'],
        totalTributosOperacionGratuita: json['totalTributosOperacionGratuita'],
        totalTributosBolsas: json['totalTributosBolsas'],
        totalIvap: json['totalIvap'],
        totalIgv: json['totalIgv'],
        totalIsc: json['totalIsc'],
        otrosTributos: json['otrosTributos'],
        otrosCargos: json['otrosCargos'],
        porcentajeOtrosCargos: json['porcentajeOtrosCargos'],
        totalValorVenta: json['totalValorVenta'],
        totalVenta: json['totalVenta'],
        totalVentaCredito: json['totalVentaCredito'],
        totalAnticipos: json['totalAnticipos'],
        pagoAnticipado: json['pagoAnticipado'],
        regimenPercepcion: json['regimenPercepcion'],
        montoPercepcion: json['montoPercepcion'],
        porcentajePercepcion: json['porcentajePercepcion'],
        totalVentaPercepcion: json['totalVentaPercepcion'],
        montoBaseRetencion: json['montoBaseRetencion'],
        montoRetencion: json['montoRetencion'],
        porcentajeRetencion: json['porcentajeRetencion'],
        montoBaseDescuento: json['montoBaseDescuento'],
        porcentajeDescuento: json['porcentajeDescuento'],
        totalDescuento: json['totalDescuento'],
        descuentoGlobal: json['descuentoGlobal'],
        descuentoPorItem: json['descuentoPorItem'],
        codigoDescuento: json['codigoDescuento'],
        porcentajeDescuentoGlobal: json['porcentajeDescuentoGlobal'],
        serieAfectado: json['serieAfectado'],
        numeroAfectado: json['numeroAfectado'],
        tipoComprobanteAfectado: json['tipoComprobanteAfectado'],
        motivoNota: json['motivoNota'],
        codigoTipoNotaCredito: json['codigoTipoNotaCredito'],
        codigoTipoNotaDebito: json['codigoTipoNotaDebito'],
        identificadorDocumento: json['identificadorDocumento'],
        estadoItem: json['estadoItem'],
        estadoSunat: json['estadoSunat'],
        estado: json['estado'],
        estadoAnterior: json['estadoAnterior'],
        mensajeRespuesta: json['mensajeRespuesta'],
        motivoAnulacion: json['motivoAnulacion'],
        incIgv: json['incIgv'],
        agruparItems: json['agruparItems'],
        efectivo: json['efectivo'],
        cambio: json['cambio'],
        items: json['items'] != null
            ? List<TicketDetail>.from(
                json['items'].map((x) => TicketDetail.fromJson(x)))
            : null,
        anticipos: json['anticipos'] != null
            ? List<Anticipo>.from(
                json['anticipos'].map((x) => Anticipo.fromJson(x)))
            : null,
        guiasRelacionadas: json['guiasRelacionadas'] != null
            ? List<GuiaRelacionada>.from(json['guiasRelacionadas']
                .map((x) => GuiaRelacionada.fromJson(x)))
            : null,
        uuid: json['uuid'],
        ordenCompra: json['ordenCompra'],
        condicionPago: json['condicionPago'],
        observacion: json['observacion'],
        codigosRespuestaSunat: json['codigosRespuestaSunat'],
        boletaAnuladaSinEmitir: json['boletaAnuladaSinEmitir'],
        envioAutomaticoSunat: json['envioAutomaticoSunat'],
        archivos: json['archivos'] != null
            ? List<TicketFile>.from(
                json['archivos'].map((x) => TicketFile.fromJson(x)))
            : null,
        sunatRespuestas: json['sunatRespuestas'] != null
            ? List<SunatResponse>.from(
                json['sunatRespuestas'].map((x) => SunatResponse.fromJson(x)))
            : null,
        codigoHash: json['codigoHash'],
        codigoMedioPago: json['codigoMedioPago'],
        cuentaDetraccion: json['cuentaDetraccion'],
        codigoDetraccion: json['codigoDetraccion'],
        porcentajeDetraccion: json['porcentajeDetraccion'],
        montoDetraccion: json['montoDetraccion'],
        empresa:
            json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
        empresaAdjunta: json['empresaAdjunta'] != null
            ? AttachedCompany.fromJson(json['empresaAdjunta'])
            : null,
        puntoVenta: json['puntoVenta'] != null
            ? Office.fromJson(json['puntoVenta'])
            : null,
        estacionVenta: json['estacionVenta'] != null
            ? SaleStation.fromJson(json['estacionVenta'])
            : null,
        cotizacion: json['cotizacion'] != null
            ? Quotation.fromJson(json['cotizacion'])
            : null,
        tipoVenta: json['tipoVenta'],
        esProduccion: json['esProduccion'],
        diasCredito: json['diasCredito'],
        anulado: json['anulado'],
        comprobanteSustituto: json['comprobanteSustituto'],
        isSendBill: json['isSendBill'],
        idNotaVentaAnulada: json['idNotaVentaAnulada'],
        vendedor:
            json['vendedor'] != null ? User.fromJson(json['vendedor']) : null,
        pedidoRestaurante: json['pedidoRestaurante'] != null
            ? OrderRestaurant.fromJson(json['pedidoRestaurante'])
            : null,
        cuentaRestaurante: json['cuentaRestaurante'],
        canal: json['canal'],
        comprobanteAnterior: json['comprobanteAnterior'],
        movimientoCaja: json['movimientoCaja'] != null
            ? CashRegisterDetail.fromJson(json['movimientoCaja'])
            : null,
        intentosSendSummary: json['intentosSendSummary'],
        createdOn: parseDateTimeFlexible(json['createdOn']),
        adelanto: json['adelanto'],
        createdBy: json['createdBy'],
        updatedBy: json['updatedBy'],
        updatedOn: parseDateTimeFlexible(json['updatedOn']),
        deleteBy: json['deleteBy'],
        deletedOn: parseDateTimeFlexible(json['deletedOn']),
        isEdited: json['isEdited'],
        numeroCotizacion: json['numeroCotizacion'],
        despachoPosterior: json['despachoPosterior'] ?? false,
        isRetencion: json['isRetencion'] ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'serie': serie,
        'numero': numero,
        'fechaEmision': fechaEmision,
        'fechaEmisionDate': fechaEmisionDate?.toIso8601String(),
        'fechaVencimientoDate': fechaVencimientoDate?.toIso8601String(),
        'horaEmision': horaEmision,
        'tipoComprobante': tipoComprobante,
        'codigoMoneda': codigoMoneda,
        'fechaVencimiento': fechaVencimiento,
        'codigoTipoOperacion': codigoTipoOperacion,
        'rucEmisor': rucEmisor,
        'razonSocialEmisor': razonSocialEmisor,
        if(codigoLocalAnexoEmisor != null) 'codigoLocalAnexoEmisor': codigoLocalAnexoEmisor,
        'tipoDocumentoReceptor': tipoDocumentoReceptor,
        'numeroDocumentoReceptor': numeroDocumentoReceptor,
        'denominacionReceptor': denominacionReceptor,
        'direccionReceptor': direccionReceptor,
        'emailReceptor': emailReceptor,
        'telefonoReceptor': telefonoReceptor,
        'cliente': cliente?.toJson(),
        'camposAdicionales': camposAdicionales?.map((x) => x.toJson()).toList(),
        'cuotas': cuotas?.map((x) => x.toJson()).toList(),
        'numeroOrdenRestaurante': numeroOrdenRestaurante,
        'codigoTipoOtroDocumentoRelacionado':
            codigoTipoOtroDocumentoRelacionado,
        'serieNumeroOtroDocumentoRelacionado':
            serieNumeroOtroDocumentoRelacionado,
        'totalValorVentaExportacion': totalValorVentaExportacion,
        'totalValorVentaGravada': totalValorVentaGravada,
        'totalValorVentaInafecta': totalValorVentaInafecta,
        'totalValorVentaExonerada': totalValorVentaExonerada,
        'totalValorVentaGratuita': totalValorVentaGratuita,
        'totalValorBaseIsc': totalValorBaseIsc,
        'totalValorBaseIgv': totalValorBaseIgv,
        'totalValorVentaGravadaIvap': totalValorVentaGravadaIvap,
        'totalTributosOperacionGratuita': totalTributosOperacionGratuita,
        'totalTributosBolsas': totalTributosBolsas,
        'totalIvap': totalIvap,
        'totalIgv': totalIgv,
        'totalIsc': totalIsc,
        'otrosTributos': otrosTributos,
        'otrosCargos': otrosCargos,
        'porcentajeOtrosCargos': porcentajeOtrosCargos,
        'totalValorVenta': totalValorVenta,
        'totalVenta': totalVenta,
        'totalVentaCredito': totalVentaCredito,
        'totalAnticipos': totalAnticipos,
        'pagoAnticipado': pagoAnticipado,
        'regimenPercepcion': regimenPercepcion,
        'montoPercepcion': montoPercepcion,
        'porcentajePercepcion': porcentajePercepcion,
        'totalVentaPercepcion': totalVentaPercepcion,
        'montoBaseRetencion': montoBaseRetencion,
        'montoRetencion': montoRetencion,
        'porcentajeRetencion': porcentajeRetencion,
        'montoBaseDescuento': montoBaseDescuento,
        'porcentajeDescuento': porcentajeDescuento,
        'totalDescuento': totalDescuento,
        'descuentoGlobal': descuentoGlobal,
        'descuentoPorItem': descuentoPorItem,
        'codigoDescuento': codigoDescuento,
        'porcentajeDescuentoGlobal': porcentajeDescuentoGlobal,
        'serieAfectado': serieAfectado,
        'numeroAfectado': numeroAfectado,
        'tipoComprobanteAfectado': tipoComprobanteAfectado,
        'motivoNota': motivoNota,
        'codigoTipoNotaCredito': codigoTipoNotaCredito,
        'codigoTipoNotaDebito': codigoTipoNotaDebito,
        'identificadorDocumento': identificadorDocumento,
        'estadoItem': estadoItem,
        'estadoSunat': estadoSunat,
        'estado': estado,
        'estadoAnterior': estadoAnterior,
        'mensajeRespuesta': mensajeRespuesta,
        'motivoAnulacion': motivoAnulacion,
        'incIgv': incIgv,
        'agruparItems': agruparItems,
        'efectivo': efectivo,
        'cambio': cambio,
        'items': items?.map((x) => x.toJson()).toList(),
        'anticipos': anticipos?.map((x) => x.toJson()).toList(),
        'guiasRelacionadas': guiasRelacionadas?.map((x) => x.toJson()).toList(),
        'uuid': uuid,
        'ordenCompra': ordenCompra,
        'condicionPago': condicionPago,
        'observacion': observacion,
        'codigosRespuestaSunat': codigosRespuestaSunat,
        'boletaAnuladaSinEmitir': boletaAnuladaSinEmitir,
        'envioAutomaticoSunat': envioAutomaticoSunat,
        'archivos': archivos?.map((x) => x.toJson()).toList(),
        'sunatRespuestas': sunatRespuestas?.map((x) => x.toJson()).toList(),
        'codigoHash': codigoHash,
        'codigoMedioPago': codigoMedioPago,
        'cuentaDetraccion': cuentaDetraccion,
        'codigoDetraccion': codigoDetraccion,
        'porcentajeDetraccion': porcentajeDetraccion,
        'montoDetraccion': montoDetraccion,
        'empresa': empresa?.toJson(),
        'empresaAdjunta': empresaAdjunta?.toJson(),
        'puntoVenta': puntoVenta?.toJson(),
        'estacionVenta': estacionVenta?.toJson(),
        'cotizacion': cotizacion?.toJson(),
        'tipoVenta': tipoVenta,
        'esProduccion': esProduccion,
        'diasCredito': diasCredito,
        'anulado': anulado,
        'comprobanteSustituto': comprobanteSustituto,
        'isSendBill': isSendBill,
        'idNotaVentaAnulada': idNotaVentaAnulada,
        'vendedor': vendedor?.toJson(),
        'pedidoRestaurante': pedidoRestaurante?.toJson(),
        'cuentaRestaurante': cuentaRestaurante,
        'canal': canal,
        'comprobanteAnterior': comprobanteAnterior,
        'movimientoCaja': movimientoCaja?.toJson(),
        'intentosSendSummary': intentosSendSummary,
        'createdOn': createdOn?.toIso8601String(),
        'adelanto': adelanto,
        'createdBy': createdBy,
        'updatedBy': updatedBy,
        'updatedOn': updatedOn?.toIso8601String(),
        'deleteBy': deleteBy,
        'deletedOn': deletedOn?.toIso8601String(),
        'isEdited': isEdited,
        'numeroCotizacion': numeroCotizacion,
        'despachoPosterior': despachoPosterior ?? false,
        'isRetencion': isRetencion ?? false,
      };

  Ticket copyWith({
    int? id,
    String? serie,
    int? numero,
    String? fechaEmision,
    DateTime? fechaEmisionDate,
    DateTime? fechaVencimientoDate,
    String? horaEmision,
    String? tipoComprobante,
    String? codigoMoneda,
    String? fechaVencimiento,
    String? codigoTipoOperacion,
    String? rucEmisor,
    String? razonSocialEmisor,
    String? codigoLocalAnexoEmisor,
    String? tipoDocumentoReceptor,
    String? numeroDocumentoReceptor,
    String? denominacionReceptor,
    String? direccionReceptor,
    String? emailReceptor,
    String? telefonoReceptor,
    Customer? cliente,
    List<AditionalField>? camposAdicionales,
    List<TicketFee>? cuotas,
    String? numeroOrdenRestaurante,
    String? codigoTipoOtroDocumentoRelacionado,
    String? serieNumeroOtroDocumentoRelacionado,
    double? totalValorVentaExportacion,
    double? totalValorVentaGravada,
    double? totalValorVentaInafecta,
    double? totalValorVentaExonerada,
    double? totalValorVentaGratuita,
    double? totalValorBaseIsc,
    double? totalValorBaseIgv,
    double? totalValorVentaGravadaIvap,
    double? totalTributosOperacionGratuita,
    double? totalTributosBolsas,
    double? totalIvap,
    double? totalIgv,
    double? totalIsc,
    double? otrosTributos,
    double? otrosCargos,
    double? porcentajeOtrosCargos,
    double? totalValorVenta,
    double? totalVenta,
    double? totalVentaCredito,
    double? totalAnticipos,
    bool? pagoAnticipado,
    String? regimenPercepcion,
    double? montoPercepcion,
    double? porcentajePercepcion,
    double? totalVentaPercepcion,
    double? montoBaseRetencion,
    double? montoRetencion,
    double? porcentajeRetencion,
    double? montoBaseDescuento,
    double? porcentajeDescuento,
    double? totalDescuento,
    double? descuentoGlobal,
    double? descuentoPorItem,
    String? codigoDescuento,
    double? porcentajeDescuentoGlobal,
    String? serieAfectado,
    int? numeroAfectado,
    String? tipoComprobanteAfectado,
    String? motivoNota,
    String? codigoTipoNotaCredito,
    String? codigoTipoNotaDebito,
    String? identificadorDocumento,
    int? estadoItem,
    String? estadoSunat,
    String? estado,
    String? estadoAnterior,
    String? mensajeRespuesta,
    String? motivoAnulacion,
    bool? incIgv,
    bool? agruparItems,
    double? efectivo,
    double? cambio,
    List<TicketDetail>? items,
    List<Anticipo>? anticipos,
    List<GuiaRelacionada>? guiasRelacionadas,
    String? uuid,
    String? ordenCompra,
    String? condicionPago,
    String? observacion,
    String? codigosRespuestaSunat,
    bool? boletaAnuladaSinEmitir,
    bool? envioAutomaticoSunat,
    List<TicketFile>? archivos,
    List<SunatResponse>? sunatRespuestas,
    String? codigoHash,
    String? codigoMedioPago,
    String? cuentaDetraccion,
    String? codigoDetraccion,
    double? porcentajeDetraccion,
    double? montoDetraccion,
    Company? empresa,
    AttachedCompany? empresaAdjunta,
    Office? puntoVenta,
    SaleStation? estacionVenta,
    Quotation? cotizacion,
    String? tipoVenta,
    bool? esProduccion,
    int? diasCredito,
    bool? anulado,
    String? comprobanteSustituto,
    bool? isSendBill,
    String? idNotaVentaAnulada,
    User? vendedor,
    OrderRestaurant? pedidoRestaurante,
    int? cuentaRestaurante,
    String? canal,
    String? comprobanteAnterior,
    CashRegisterDetail? movimientoCaja,
    int? intentosSendSummary,
    DateTime? createdOn,
    double? adelanto,
    int? createdBy,
    int? updatedBy,
    DateTime? updatedOn,
    int? deleteBy,
    DateTime? deletedOn,
    bool? isEdited,
    String? numeroCotizacion,
    bool? despachoPosterior,
    bool? isRetencion,
  }) {
    return Ticket(
      id: id ?? this.id,
      serie: serie ?? this.serie,
      numero: numero ?? this.numero,
      fechaEmision: fechaEmision ?? this.fechaEmision,
      fechaEmisionDate: fechaEmisionDate ?? this.fechaEmisionDate,
      fechaVencimientoDate: fechaVencimientoDate ?? this.fechaVencimientoDate,
      horaEmision: horaEmision ?? this.horaEmision,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      codigoMoneda: codigoMoneda ?? this.codigoMoneda,
      fechaVencimiento: fechaVencimiento ?? this.fechaVencimiento,
      codigoTipoOperacion: codigoTipoOperacion ?? this.codigoTipoOperacion,
      rucEmisor: rucEmisor ?? this.rucEmisor,
      razonSocialEmisor: razonSocialEmisor ?? this.razonSocialEmisor,
      codigoLocalAnexoEmisor:
          codigoLocalAnexoEmisor ?? this.codigoLocalAnexoEmisor,
      tipoDocumentoReceptor:
          tipoDocumentoReceptor ?? this.tipoDocumentoReceptor,
      numeroDocumentoReceptor:
          numeroDocumentoReceptor ?? this.numeroDocumentoReceptor,
      denominacionReceptor: denominacionReceptor ?? this.denominacionReceptor,
      direccionReceptor: direccionReceptor ?? this.direccionReceptor,
      emailReceptor: emailReceptor ?? this.emailReceptor,
      telefonoReceptor: telefonoReceptor ?? this.telefonoReceptor,
      cliente: cliente ?? this.cliente,
      camposAdicionales: camposAdicionales ?? this.camposAdicionales,
      cuotas: cuotas ?? this.cuotas,
      numeroOrdenRestaurante:
          numeroOrdenRestaurante ?? this.numeroOrdenRestaurante,
      codigoTipoOtroDocumentoRelacionado: codigoTipoOtroDocumentoRelacionado ??
          this.codigoTipoOtroDocumentoRelacionado,
      serieNumeroOtroDocumentoRelacionado:
          serieNumeroOtroDocumentoRelacionado ??
              this.serieNumeroOtroDocumentoRelacionado,
      totalValorVentaExportacion:
          totalValorVentaExportacion ?? this.totalValorVentaExportacion,
      totalValorVentaGravada:
          totalValorVentaGravada ?? this.totalValorVentaGravada,
      totalValorVentaInafecta:
          totalValorVentaInafecta ?? this.totalValorVentaInafecta,
      totalValorVentaExonerada:
          totalValorVentaExonerada ?? this.totalValorVentaExonerada,
      totalValorVentaGratuita:
          totalValorVentaGratuita ?? this.totalValorVentaGratuita,
      totalValorBaseIsc: totalValorBaseIsc ?? this.totalValorBaseIsc,
      totalValorBaseIgv: totalValorBaseIgv ?? this.totalValorBaseIgv,
      totalValorVentaGravadaIvap:
          totalValorVentaGravadaIvap ?? this.totalValorVentaGravadaIvap,
      totalTributosOperacionGratuita:
          totalTributosOperacionGratuita ?? this.totalTributosOperacionGratuita,
      totalTributosBolsas: totalTributosBolsas ?? this.totalTributosBolsas,
      totalIvap: totalIvap ?? this.totalIvap,
      totalIgv: totalIgv ?? this.totalIgv,
      totalIsc: totalIsc ?? this.totalIsc,
      otrosTributos: otrosTributos ?? this.otrosTributos,
      otrosCargos: otrosCargos ?? this.otrosCargos,
      porcentajeOtrosCargos:
          porcentajeOtrosCargos ?? this.porcentajeOtrosCargos,
      totalValorVenta: totalValorVenta ?? this.totalValorVenta,
      totalVenta: totalVenta ?? this.totalVenta,
      totalVentaCredito: totalVentaCredito ?? this.totalVentaCredito,
      totalAnticipos: totalAnticipos ?? this.totalAnticipos,
      pagoAnticipado: pagoAnticipado ?? this.pagoAnticipado,
      regimenPercepcion: regimenPercepcion ?? this.regimenPercepcion,
      montoPercepcion: montoPercepcion ?? this.montoPercepcion,
      porcentajePercepcion: porcentajePercepcion ?? this.porcentajePercepcion,
      totalVentaPercepcion: totalVentaPercepcion ?? this.totalVentaPercepcion,
      montoBaseRetencion: montoBaseRetencion ?? this.montoBaseRetencion,
      montoRetencion: montoRetencion ?? this.montoRetencion,
      porcentajeRetencion: porcentajeRetencion ?? this.porcentajeRetencion,
      montoBaseDescuento: montoBaseDescuento ?? this.montoBaseDescuento,
      porcentajeDescuento: porcentajeDescuento ?? this.porcentajeDescuento,
      totalDescuento: totalDescuento ?? this.totalDescuento,
      descuentoGlobal: descuentoGlobal ?? this.descuentoGlobal,
      descuentoPorItem: descuentoPorItem ?? this.descuentoPorItem,
      codigoDescuento: codigoDescuento ?? this.codigoDescuento,
      porcentajeDescuentoGlobal:
          porcentajeDescuentoGlobal ?? this.porcentajeDescuentoGlobal,
      serieAfectado: serieAfectado ?? this.serieAfectado,
      numeroAfectado: numeroAfectado ?? this.numeroAfectado,
      tipoComprobanteAfectado:
          tipoComprobanteAfectado ?? this.tipoComprobanteAfectado,
      motivoNota: motivoNota ?? this.motivoNota,
      codigoTipoNotaCredito:
          codigoTipoNotaCredito ?? this.codigoTipoNotaCredito,
      codigoTipoNotaDebito: codigoTipoNotaDebito ?? this.codigoTipoNotaDebito,
      identificadorDocumento:
          identificadorDocumento ?? this.identificadorDocumento,
      estadoItem: estadoItem ?? this.estadoItem,
      estadoSunat: estadoSunat ?? this.estadoSunat,
      estado: estado ?? this.estado,
      estadoAnterior: estadoAnterior ?? this.estadoAnterior,
      mensajeRespuesta: mensajeRespuesta ?? this.mensajeRespuesta,
      motivoAnulacion: motivoAnulacion ?? this.motivoAnulacion,
      incIgv: incIgv ?? this.incIgv,
      agruparItems: agruparItems ?? this.agruparItems,
      efectivo: efectivo ?? this.efectivo,
      cambio: cambio ?? this.cambio,
      items: items ?? this.items,
      anticipos: anticipos ?? this.anticipos,
      guiasRelacionadas: guiasRelacionadas ?? this.guiasRelacionadas,
      uuid: uuid ?? this.uuid,
      ordenCompra: ordenCompra ?? this.ordenCompra,
      condicionPago: condicionPago ?? this.condicionPago,
      observacion: observacion ?? this.observacion,
      codigosRespuestaSunat:
          codigosRespuestaSunat ?? this.codigosRespuestaSunat,
      boletaAnuladaSinEmitir:
          boletaAnuladaSinEmitir ?? this.boletaAnuladaSinEmitir,
      envioAutomaticoSunat: envioAutomaticoSunat ?? this.envioAutomaticoSunat,
      archivos: archivos ?? this.archivos,
      sunatRespuestas: sunatRespuestas ?? this.sunatRespuestas,
      codigoHash: codigoHash ?? this.codigoHash,
      codigoMedioPago: codigoMedioPago ?? this.codigoMedioPago,
      cuentaDetraccion: cuentaDetraccion ?? this.cuentaDetraccion,
      codigoDetraccion: codigoDetraccion ?? this.codigoDetraccion,
      porcentajeDetraccion: porcentajeDetraccion ?? this.porcentajeDetraccion,
      montoDetraccion: montoDetraccion ?? this.montoDetraccion,
      empresa: empresa ?? this.empresa,
      empresaAdjunta: empresaAdjunta ?? this.empresaAdjunta,
      puntoVenta: puntoVenta ?? this.puntoVenta,
      estacionVenta: estacionVenta ?? this.estacionVenta,
      cotizacion: cotizacion ?? this.cotizacion,
      tipoVenta: tipoVenta ?? this.tipoVenta,
      esProduccion: esProduccion ?? this.esProduccion,
      diasCredito: diasCredito ?? this.diasCredito,
      anulado: anulado ?? this.anulado,
      comprobanteSustituto: comprobanteSustituto ?? this.comprobanteSustituto,
      isSendBill: isSendBill ?? this.isSendBill,
      idNotaVentaAnulada: idNotaVentaAnulada ?? this.idNotaVentaAnulada,
      vendedor: vendedor ?? this.vendedor,
      pedidoRestaurante: pedidoRestaurante ?? this.pedidoRestaurante,
      cuentaRestaurante: cuentaRestaurante ?? this.cuentaRestaurante,
      canal: canal ?? this.canal,
      comprobanteAnterior: comprobanteAnterior ?? this.comprobanteAnterior,
      movimientoCaja: movimientoCaja ?? this.movimientoCaja,
      intentosSendSummary: intentosSendSummary ?? this.intentosSendSummary,
      createdOn: createdOn ?? this.createdOn,
      adelanto: adelanto ?? this.adelanto,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedOn: updatedOn ?? this.updatedOn,
      deleteBy: deleteBy ?? this.deleteBy,
      deletedOn: deletedOn ?? this.deletedOn,
      isEdited: isEdited ?? this.isEdited,
      numeroCotizacion: numeroCotizacion ?? this.numeroCotizacion,
      despachoPosterior: despachoPosterior ?? this.despachoPosterior,
      isRetencion: isRetencion ?? this.isRetencion,
    );
  }
}
