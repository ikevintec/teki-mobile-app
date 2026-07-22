import 'package:teki_app/src/data/models/teki_model/attached_company.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/quotation_detail.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/utils/formats.dart';

class Quotation {
  final int? id;
  final String? serie;
  final int? numero;
  final String? fechaEmision;
  final DateTime? fechaEmisionDate;
  final DateTime? fechaEntrega;
  final String? horaEmision;
  final int? ofertaValido;
  final int? tiempoEntrega;
  final String? codigoMoneda;
  final String? fechaVencimiento;
  final Customer? cliente;
  final String? tipoDocumentoReceptor;
  final String? numeroDocumentoReceptor;
  final String? denominacionReceptor;
  final String? direccionReceptor;
  final String? emailReceptor;
  final String? telefonoReceptor;
  final bool? isQuotation;
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
  final double? totalValorVenta;
  final double? totalVenta;
  final double? montoBaseDescuento;
  final double? porcentajeDescuento;
  final double? totalDescuento;
  final String? codigoDescuento;
  final double? adelanto;
  final String? estadoCotizacion;
  final List<QuotationDetail>? items;
  final String? observacion;
  final Company? empresa;
  final AttachedCompany? empresaAdjunta;
  final CashRegisterDetail? movimientoCaja;
  final Office? puntoVenta;
  final SaleStation? estacionVenta;
  final User? vendedor;
  final bool? esProduccion;
  final String? tipoVenta;
  final int? diasCredito;
  final String? rucEmisor;
  final bool? incIgv;
  final bool? agruparItems;

  Quotation({
    this.id,
    this.serie,
    this.numero,
    this.fechaEmision,
    this.fechaEmisionDate,
    this.fechaEntrega,
    this.horaEmision,
    this.ofertaValido,
    this.tiempoEntrega,
    this.codigoMoneda,
    this.fechaVencimiento,
    this.cliente,
    this.tipoDocumentoReceptor,
    this.numeroDocumentoReceptor,
    this.denominacionReceptor,
    this.direccionReceptor,
    this.emailReceptor,
    this.telefonoReceptor,
    this.isQuotation,
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
    this.totalValorVenta,
    this.totalVenta,
    this.montoBaseDescuento,
    this.porcentajeDescuento,
    this.totalDescuento,
    this.codigoDescuento,
    this.adelanto,
    this.estadoCotizacion,
    this.items,
    this.observacion,
    this.empresa,
    this.empresaAdjunta,
    this.movimientoCaja,
    this.puntoVenta,
    this.estacionVenta,
    this.vendedor,
    this.esProduccion,
    this.tipoVenta,
    this.diasCredito,
    this.rucEmisor,
    this.incIgv,
    this.agruparItems,
  });

  factory Quotation.fromJson(Map<String, dynamic> json) => Quotation(
    id: json['id'],
    serie: json['serie'],
    numero: json['numero'],
    fechaEmision: json['fechaEmision'],
    fechaEmisionDate: parseDateTimeFlexible(json['fechaEmisionDate']),
    fechaEntrega: parseDateTimeFlexible(json['fechaEntrega']),
    horaEmision: json['horaEmision'],
    ofertaValido: json['ofertaValido'],
    tiempoEntrega: json['tiempoEntrega'],
    codigoMoneda: json['codigoMoneda'],
    fechaVencimiento: json['fechaVencimiento'],
    cliente: json['cliente'] != null
        ? Customer.fromJson(json['cliente'])
        : null,
    tipoDocumentoReceptor: json['tipoDocumentoReceptor'],
    numeroDocumentoReceptor: json['numeroDocumentoReceptor'],
    denominacionReceptor: json['denominacionReceptor'],
    direccionReceptor: json['direccionReceptor'],
    emailReceptor: json['emailReceptor'],
    telefonoReceptor: json['telefonoReceptor'],
    isQuotation: json['isQuotation'],
    totalValorVentaExportacion: (json['totalValorVentaExportacion'] as num?)
        ?.toDouble(),
    totalValorVentaGravada: (json['totalValorVentaGravada'] as num?)
        ?.toDouble(),
    totalValorVentaInafecta: (json['totalValorVentaInafecta'] as num?)
        ?.toDouble(),
    totalValorVentaExonerada: (json['totalValorVentaExonerada'] as num?)
        ?.toDouble(),
    totalValorVentaGratuita: (json['totalValorVentaGratuita'] as num?)
        ?.toDouble(),
    totalValorBaseIsc: (json['totalValorBaseIsc'] as num?)?.toDouble(),
    totalValorBaseIgv: (json['totalValorBaseIgv'] as num?)?.toDouble(),
    totalValorVentaGravadaIvap: (json['totalValorVentaGravadaIvap'] as num?)
        ?.toDouble(),
    totalTributosOperacionGratuita:
        (json['totalTributosOperacionGratuita'] as num?)?.toDouble(),
    totalTributosBolsas: (json['totalTributosBolsas'] as num?)?.toDouble(),
    totalIvap: (json['totalIvap'] as num?)?.toDouble(),
    totalIgv: (json['totalIgv'] as num?)?.toDouble(),
    totalIsc: (json['totalIsc'] as num?)?.toDouble(),
    otrosTributos: (json['otrosTributos'] as num?)?.toDouble(),
    otrosCargos: (json['otrosCargos'] as num?)?.toDouble(),
    totalValorVenta: (json['totalValorVenta'] as num?)?.toDouble(),
    totalVenta: (json['totalVenta'] as num?)?.toDouble(),
    montoBaseDescuento: (json['montoBaseDescuento'] as num?)?.toDouble(),
    porcentajeDescuento: (json['porcentajeDescuento'] as num?)?.toDouble(),
    totalDescuento: (json['totalDescuento'] as num?)?.toDouble(),
    codigoDescuento: json['codigoDescuento'],
    adelanto: (json['adelanto'] as num?)?.toDouble(),
    estadoCotizacion: json['estadoCotizacion'],
    items: (json['items'] as List?)
        ?.map((e) => QuotationDetail.fromJson(e))
        .toList(),
    observacion: json['observacion'],
    empresa: json['empresa'] != null ? Company.fromJson(json['empresa']) : null,
    empresaAdjunta: json['empresaAdjunta'] != null
        ? AttachedCompany.fromJson(json['empresaAdjunta'])
        : null,
    movimientoCaja: json['movimientoCaja'] != null
        ? CashRegisterDetail.fromJson(json['movimientoCaja'])
        : null,
    puntoVenta: json['puntoVenta'] != null
        ? Office.fromJson(json['puntoVenta'])
        : null,
    estacionVenta: json['estacionVenta'] != null
        ? SaleStation.fromJson(json['estacionVenta'])
        : null,
    vendedor: json['vendedor'] != null ? User.fromJson(json['vendedor']) : null,
    esProduccion: json['esProduccion'],
    tipoVenta: json['tipoVenta'],
    diasCredito: json['diasCredito'],
    rucEmisor: json['rucEmisor'],
    incIgv: json['incIgv'],
    agruparItems: json['agruparItems'],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'serie': serie,
    'numero': numero,
    'fechaEmision': fechaEmision,
    'fechaEmisionDate': fechaEmisionDate?.toIso8601String(),
    'fechaEntrega': fechaEntrega?.toIso8601String(),
    'horaEmision': horaEmision,
    'ofertaValido': ofertaValido,
    'tiempoEntrega': tiempoEntrega,
    'codigoMoneda': codigoMoneda,
    'fechaVencimiento': fechaVencimiento,
    'cliente': cliente?.toJson(),
    'tipoDocumentoReceptor': tipoDocumentoReceptor,
    'numeroDocumentoReceptor': numeroDocumentoReceptor,
    'denominacionReceptor': denominacionReceptor,
    'direccionReceptor': direccionReceptor,
    'emailReceptor': emailReceptor,
    'telefonoReceptor': telefonoReceptor,
    'isQuotation': isQuotation,
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
    'totalValorVenta': totalValorVenta,
    'totalVenta': totalVenta,
    'montoBaseDescuento': montoBaseDescuento,
    'porcentajeDescuento': porcentajeDescuento,
    'totalDescuento': totalDescuento,
    'codigoDescuento': codigoDescuento,
    'adelanto': adelanto,
    'estadoCotizacion': estadoCotizacion,
    'items': items?.map((e) => e.toJson()).toList(),
    'observacion': observacion,
    'empresa': empresa?.toJson(),
    'empresaAdjunta': empresaAdjunta?.toJson(),
    'movimientoCaja': movimientoCaja?.toJson(),
    'puntoVenta': puntoVenta?.toJson(),
    'estacionVenta': estacionVenta?.toJson(),
    'vendedor': vendedor?.toJson(),
    'esProduccion': esProduccion,
    'tipoVenta': tipoVenta,
    'diasCredito': diasCredito,
    'rucEmisor': rucEmisor,
    'incIgv': incIgv,
    'agruparItems': agruparItems,
  };

  /// Convierte esta cotización en un Ticket nuevo (sin id) para "Generar venta":
  /// reutiliza cliente/items de la cotización pero se crea como un ticket normal
  /// (tipoComprobante editable, por defecto Boleta), enlazado a la cotización
  /// de origen mediante el campo `cotizacion` para que el backend la concrete.
  Ticket toTicketForSale() {
    return Ticket(
      tipoComprobante: '03',
      codigoMoneda: codigoMoneda,
      cliente: cliente,
      tipoDocumentoReceptor: tipoDocumentoReceptor,
      numeroDocumentoReceptor: numeroDocumentoReceptor,
      denominacionReceptor: denominacionReceptor,
      direccionReceptor: direccionReceptor,
      emailReceptor: emailReceptor,
      telefonoReceptor: telefonoReceptor,
      items: items?.map((e) => e.toTicketDetail(keepId: false)).toList(),
      observacion: observacion,
      empresa: empresa,
      empresaAdjunta: empresaAdjunta,
      puntoVenta: puntoVenta,
      estacionVenta: estacionVenta,
      vendedor: vendedor,
      esProduccion: esProduccion,
      tipoVenta: tipoVenta,
      diasCredito: diasCredito,
      rucEmisor: rucEmisor,
      incIgv: incIgv,
      agruparItems: agruparItems,
      montoBaseDescuento: montoBaseDescuento,
      porcentajeDescuento: porcentajeDescuento,
      totalDescuento: totalDescuento,
      codigoDescuento: codigoDescuento,
      adelanto: adelanto,
      cotizacion: Quotation(id: id, serie: serie, numero: numero),
    );
  }

  /// Convierte esta cotización en un Ticket para reutilizar el formulario
  /// de venta (ProductsSaleScreen) en el flujo de edición de cotizaciones.
  Ticket toTicketForEdit() {
    return Ticket(
      id: id,
      serie: serie,
      numero: numero,
      fechaEmision: fechaEmision,
      fechaEmisionDate: fechaEmisionDate,
      horaEmision: horaEmision,
      tipoComprobante: 'CO',
      codigoMoneda: codigoMoneda,
      fechaVencimiento: fechaVencimiento,
      cliente: cliente,
      tipoDocumentoReceptor: tipoDocumentoReceptor,
      numeroDocumentoReceptor: numeroDocumentoReceptor,
      denominacionReceptor: denominacionReceptor,
      direccionReceptor: direccionReceptor,
      emailReceptor: emailReceptor,
      telefonoReceptor: telefonoReceptor,
      totalValorVentaExportacion: totalValorVentaExportacion,
      totalValorVentaGravada: totalValorVentaGravada,
      totalValorVentaInafecta: totalValorVentaInafecta,
      totalValorVentaExonerada: totalValorVentaExonerada,
      totalValorVentaGratuita: totalValorVentaGratuita,
      totalValorBaseIsc: totalValorBaseIsc,
      totalValorBaseIgv: totalValorBaseIgv,
      totalValorVentaGravadaIvap: totalValorVentaGravadaIvap,
      totalTributosOperacionGratuita: totalTributosOperacionGratuita,
      totalTributosBolsas: totalTributosBolsas,
      totalIvap: totalIvap,
      totalIgv: totalIgv,
      totalIsc: totalIsc,
      otrosTributos: otrosTributos,
      otrosCargos: otrosCargos,
      totalValorVenta: totalValorVenta,
      totalVenta: totalVenta,
      montoBaseDescuento: montoBaseDescuento,
      porcentajeDescuento: porcentajeDescuento,
      totalDescuento: totalDescuento,
      codigoDescuento: codigoDescuento,
      adelanto: adelanto,
      items: items?.map((e) => e.toTicketDetail()).toList(),
      observacion: observacion,
      empresa: empresa,
      empresaAdjunta: empresaAdjunta,
      movimientoCaja: movimientoCaja,
      puntoVenta: puntoVenta,
      estacionVenta: estacionVenta,
      vendedor: vendedor,
      esProduccion: esProduccion,
      tipoVenta: tipoVenta,
      diasCredito: diasCredito,
      rucEmisor: rucEmisor,
      incIgv: incIgv,
      agruparItems: agruparItems,
    );
  }
}
