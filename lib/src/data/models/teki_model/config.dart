import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/unit_code.dart';

class ConfigCompany {
  bool? envioAutomaticoSunat;
  bool? preciosIncluidoIgv;
  bool? descripcionLarga;
  bool? clientePorDefecto;
  String? tipoComprobantePorDefecto;
  String? tipoGuiaPorDefecto;
  bool? impresionAutomatica;
  String? restriccionCertificado;
  bool? previsualizarPostVenta;
  bool? inventario;
  bool? validacionInventario;
  bool? validacionLote;
  bool? esGasolinera;
  bool? esTiendaRopa;
  bool? esRestaurante;
  bool? usaCodigoBarras;
  bool? ocultarModalRegistroComanda;
  String? tipoImpresion;
  String? tipoImpresionGuia;
  String? tipoPedidoRestaurantePorDefecto;
  String? tiposDocumentosEnvioWhatsapp;
  int? cantDecimales;
  bool? nombreComercialPorPuntoVenta;
  bool? usaWhatsappApi;
  bool? envioAutomaticoWhatsappApi;
  bool? usoBalanza;
  bool? seleccionLoteAutomatica;
  bool? agruparItemsVenta;
  bool? recargoPorItem;
  double? porcentajeRecargoPorItem;
  bool? imprimeTicketsEscPos;
  bool? imprimirBoletaLite;
  String? clienteImpresion;
  bool? controlDespacho;
  bool? buscarPorPuntoVenta;
  bool? excluirMonitoreo;

  Customer? clientePorDefectoData;
  List<UnitCode>? unidades;
  List<PaymentMethod>? formasPago;
  double? igv;
  double? igvPorDefecto;
  String? tipoClienteWhatsapp;
  bool? adicionarRetencionEnCotizacion;
  double? porcentajeRetencion;
  bool? motivoAnulacionPlato;
  bool? busquedaProductosLocalmente;

  ConfigCompany({
    this.envioAutomaticoSunat,
    this.preciosIncluidoIgv,
    this.descripcionLarga,
    this.clientePorDefecto,
    this.tipoComprobantePorDefecto,
    this.tipoGuiaPorDefecto,
    this.impresionAutomatica,
    this.restriccionCertificado,
    this.previsualizarPostVenta,
    this.inventario,
    this.validacionInventario,
    this.validacionLote,
    this.esGasolinera,
    this.esTiendaRopa,
    this.esRestaurante,
    this.usaCodigoBarras,
    this.ocultarModalRegistroComanda,
    this.tipoImpresion,
    this.tipoImpresionGuia,
    this.tipoPedidoRestaurantePorDefecto,
    this.tiposDocumentosEnvioWhatsapp,
    this.cantDecimales,
    this.nombreComercialPorPuntoVenta,
    this.usaWhatsappApi,
    this.envioAutomaticoWhatsappApi,
    this.usoBalanza,
    this.seleccionLoteAutomatica,
    this.agruparItemsVenta,
    this.recargoPorItem,
    this.porcentajeRecargoPorItem,
    this.imprimeTicketsEscPos,
    this.imprimirBoletaLite,
    this.clienteImpresion,
    this.controlDespacho,
    this.buscarPorPuntoVenta,
    this.excluirMonitoreo,
    this.clientePorDefectoData,
    this.unidades,
    this.formasPago,
    this.igv,
    this.igvPorDefecto,
    this.tipoClienteWhatsapp,
    this.adicionarRetencionEnCotizacion,
    this.porcentajeRetencion,
    this.motivoAnulacionPlato,
    this.busquedaProductosLocalmente,
  });

  factory ConfigCompany.fromJson(Map<String, dynamic> json) {
    return ConfigCompany(
      envioAutomaticoSunat: json['envioAutomaticoSunat'],
      preciosIncluidoIgv: json['preciosIncluidoIgv'],
      descripcionLarga: json['descripcionLarga'],
      clientePorDefecto: json['clientePorDefecto'],
      tipoComprobantePorDefecto: json['tipoComprobantePorDefecto'],
      tipoGuiaPorDefecto: json['tipoGuiaPorDefecto'],
      impresionAutomatica: json['impresionAutomatica'],
      restriccionCertificado: json['restriccionCertificado'],
      previsualizarPostVenta: json['previsualizarPostVenta'],
      inventario: json['inventario'],
      validacionInventario: json['validacionInventario'],
      validacionLote: json['validacionLote'],
      esGasolinera: json['esGasolinera'],
      esTiendaRopa: json['esTiendaRopa'],
      esRestaurante: json['esRestaurante'],
      usaCodigoBarras: json['usaCodigoBarras'],
      ocultarModalRegistroComanda: json['ocultarModalRegistroComanda'],
      tipoImpresion: json['tipoImpresion'],
      tipoImpresionGuia: json['tipoImpresionGuia'],
      tipoPedidoRestaurantePorDefecto: json['tipoPedidoRestaurantePorDefecto'],
      tiposDocumentosEnvioWhatsapp: json['tiposDocumentosEnvioWhatsapp'],
      cantDecimales: json['cantDecimales'],
      nombreComercialPorPuntoVenta: json['nombreComercialPorPuntoVenta'],
      usaWhatsappApi: json['usaWhatsappApi'],
      envioAutomaticoWhatsappApi: json['envioAutomaticoWhatsappApi'],
      usoBalanza: json['usoBalanza'],
      seleccionLoteAutomatica: json['seleccionLoteAutomatica'],
      agruparItemsVenta: json['agruparItemsVenta'],
      recargoPorItem: json['recargoPorItem'],
      porcentajeRecargoPorItem: (json['porcentajeRecargoPorItem'] as num?)?.toDouble(),
      imprimeTicketsEscPos: json['imprimeTicketsEscPos'],
      imprimirBoletaLite: json['imprimirBoletaLite'],
      clienteImpresion: json['clienteImpresion'],
      controlDespacho: json['controlDespacho'],
      buscarPorPuntoVenta: json['buscarPorPuntoVenta'],
      excluirMonitoreo: json['excluirMonitoreo'],
      clientePorDefectoData: json['clientePorDefectoData'] != null
          ? Customer.fromJson(json['clientePorDefectoData'])
          : null,
      unidades: (json['unidades'] as List<dynamic>?)
          ?.map((e) => UnitCode.fromJson(e))
          .toList(),
      formasPago: (json['formasPago'] as List<dynamic>?)
          ?.map((e) => PaymentMethod.fromJson(e))
          .toList(),
      igv: (json['igv'] as num?)?.toDouble(),
      igvPorDefecto: (json['igvPorDefecto'] as num?)?.toDouble(),
      tipoClienteWhatsapp: json['tipoClienteWhatsapp'],
      adicionarRetencionEnCotizacion: json['adicionarRetencionEnCotizacion'],
      porcentajeRetencion: (json['porcentajeRetencion'] as num?)?.toDouble(),
      motivoAnulacionPlato: json['motivoAnulacionPlato'],
      busquedaProductosLocalmente: json['busquedaProductosLocalmente'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'envioAutomaticoSunat': envioAutomaticoSunat,
      'preciosIncluidoIgv': preciosIncluidoIgv,
      'descripcionLarga': descripcionLarga,
      'clientePorDefecto': clientePorDefecto,
      'tipoComprobantePorDefecto': tipoComprobantePorDefecto,
      'tipoGuiaPorDefecto': tipoGuiaPorDefecto,
      'impresionAutomatica': impresionAutomatica,
      'restriccionCertificado': restriccionCertificado,
      'previsualizarPostVenta': previsualizarPostVenta,
      'inventario': inventario,
      'validacionInventario': validacionInventario,
      'validacionLote': validacionLote,
      'esGasolinera': esGasolinera,
      'esTiendaRopa': esTiendaRopa,
      'esRestaurante': esRestaurante,
      'usaCodigoBarras': usaCodigoBarras,
      'ocultarModalRegistroComanda': ocultarModalRegistroComanda,
      'tipoImpresion': tipoImpresion,
      'tipoImpresionGuia': tipoImpresionGuia,
      'tipoPedidoRestaurantePorDefecto': tipoPedidoRestaurantePorDefecto,
      'tiposDocumentosEnvioWhatsapp': tiposDocumentosEnvioWhatsapp,
      'cantDecimales': cantDecimales,
      'nombreComercialPorPuntoVenta': nombreComercialPorPuntoVenta,
      'usaWhatsappApi': usaWhatsappApi,
      'envioAutomaticoWhatsappApi': envioAutomaticoWhatsappApi,
      'usoBalanza': usoBalanza,
      'seleccionLoteAutomatica': seleccionLoteAutomatica,
      'agruparItemsVenta': agruparItemsVenta,
      'recargoPorItem': recargoPorItem,
      'porcentajeRecargoPorItem': porcentajeRecargoPorItem,
      'imprimeTicketsEscPos': imprimeTicketsEscPos,
      'imprimirBoletaLite': imprimirBoletaLite,
      'clienteImpresion': clienteImpresion,
      'controlDespacho': controlDespacho,
      'buscarPorPuntoVenta': buscarPorPuntoVenta,
      'excluirMonitoreo': excluirMonitoreo,
      'clientePorDefectoData': clientePorDefectoData?.toJson(),
      'unidades': unidades?.map((e) => e.toJson()).toList(),
      'formasPago': formasPago?.map((e) => e.toJson()).toList(),
      'igv': igv,
      'igvPorDefecto': igvPorDefecto,
      'tipoClienteWhatsapp': tipoClienteWhatsapp,
      'adicionarRetencionEnCotizacion': adicionarRetencionEnCotizacion,
      'porcentajeRetencion': porcentajeRetencion,
      'motivoAnulacionPlato': motivoAnulacionPlato,
      'busquedaProductosLocalmente': busquedaProductosLocalmente,
    };
  }
}
