import 'package:teki_app/src/data/models/teki_model/attached_company.dart';
import 'package:teki_app/src/data/models/teki_model/bank_account.dart';
import 'package:teki_app/src/data/models/teki_model/certificate.dart';
import 'package:teki_app/src/data/models/teki_model/module_access.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_design.dart';
import 'package:teki_app/src/data/models/teki_model/unit_code.dart';

class Company {
  final int? id;
  final String? direccion;
  final bool? estadoServicio;
  final String? restriccionCertificado;
  final String? estadoCerticado;
  final String? motivoCorteServicio;
  final String? razonSocial;
  final String? nombreComercial;
  final String? representante;
  final String? uuid;
  final String? dominio;
  final String? telefono;
  final String? url;
  final String? email;
  final String? emailNotificacion;
  final String? numeroNotificacion;
  final String? urlOse;
  final String? usuarioSol;
  final String? claveSol;
  final String? usuarioSecSol;
  final String? claveSecSol;
  final String? clientIdSunat;
  final String? clientSecretSunat;
  final bool? esProduccion;
  final bool? canalOnline;
  final String? ruc;
  final int? cantComprobanteDinamico;
  final bool? viewCode;
  final int? format;
  final String? tipoComprobantePorDefecto;
  final String? tipoGuiaPorDefecto;
  final bool? envioAutomaticoSunat;
  final bool? preciosIncluidoIgv;
  final bool? descripcionLarga;
  final bool? clientePorDefecto;
  final bool? previsualizarPostVenta;
  final bool? impresionAutomatica;
  final bool? aperturaCajaAutomatica;
  final bool? cierreCajaAutomatica;
  final bool? agruparItemsReporteCaja;
  final bool? inventario;
  final bool? validacionInventario;
  final bool? validacionLote;
  final bool? esGasolinera;
  final bool? esTiendaRopa;
  final bool? esRestaurante;
  final bool? usaCodigoBarras;
  final bool? ocultarModalRegistroComanda;
  final bool? recargoPorItem;
  final double? porcentajeRecargoPorItem;
  final bool? imprimeTicketsEscPos;
  final bool? nombreComercialPorPuntoVenta;
  final bool? usaWhatsappApi;
  final bool? envioAutomaticoWhatsappApi;
  final String? tiposDocumentosEnvioWhatsapp;
  final String? tipoImpresion;
  final String? tipoImpresionGuia;
  final String? tipoPedidoRestaurantePorDefecto;
  final bool? integracionApi;
  final bool? rucNv;
  final bool? usoBalanza;
  final bool? seleccionLoteAutomatica;
  final bool? agruparItemsVenta;
  final String? smtpUsuario;
  final String? smtpHost;
  final String? smtpClave;
  final String? smtpPuerto;
  final int? cantDecimales;
  final int? cantDecimalesPrecioProducto;
  final bool? registroExterno;
  final bool? controlDespacho;
  final bool? buscarPorPuntoVenta;
  final bool? excluirMonitoreo;
  final bool? root;
  final String? clienteImpresion;
  final String? urlLogo;
  final String? ubigeo;
  final String? departamento;
  final String? provincia;
  final String? distrito;
  final double? igv;
  final String? tokenEvolution;
  final String? tipoClienteWhatsapp;
  final bool? adicionarRetencionEnCotizacion;
  final Certificate? certificado;
  final UnitCode? unidad;
  final List<UnitCode>? unidades;
  final List<ModuleAccess>? modulos;
  final List<BankAccount>? cuentas;
  final List<AttachedCompany>? empresasAdjuntas;
  final TicketDesign? plantillaA4;
  final TicketDesign? plantillaA4Boleta;
  final TicketDesign? plantillaA4Factura;
  final TicketDesign? plantillaTicket;
  final TicketDesign? plantillaCotizacion;
  final TicketDesign? plantillaPercepcion;
  final TicketDesign? plantillaRetencion;
  final TicketDesign? plantillaOrdenRestaurante;
  final TicketDesign? plantillaGuia;
  final TicketDesign? plantillaGuiaTicket;
  final TicketDesign? plantillaGuiaManual;
  final TicketDesign? plantillaConstanciaEntrega;
  final TicketDesign? plantillaComunicacionBaja;
  final TicketDesign? plantillaLetra;
  final TicketDesign? plantillaMovimientoCaja;
  final TicketDesign? plantillaCompra;
  final TicketDesign? plantillaDespacho;
  final TicketDesign? plantillaCuentasPorCobrar;

  Company({
    this.id,
    this.direccion,
    this.estadoServicio,
    this.restriccionCertificado,
    this.estadoCerticado,
    this.motivoCorteServicio,
    this.razonSocial,
    this.nombreComercial,
    this.representante,
    this.uuid,
    this.dominio,
    this.telefono,
    this.url,
    this.email,
    this.emailNotificacion,
    this.numeroNotificacion,
    this.urlOse,
    this.usuarioSol,
    this.claveSol,
    this.usuarioSecSol,
    this.claveSecSol,
    this.clientIdSunat,
    this.clientSecretSunat,
    this.esProduccion,
    this.canalOnline,
    this.ruc,
    this.cantComprobanteDinamico,
    this.viewCode,
    this.format,
    this.tipoComprobantePorDefecto,
    this.tipoGuiaPorDefecto,
    this.envioAutomaticoSunat,
    this.preciosIncluidoIgv,
    this.descripcionLarga,
    this.clientePorDefecto,
    this.previsualizarPostVenta,
    this.impresionAutomatica,
    this.aperturaCajaAutomatica,
    this.cierreCajaAutomatica,
    this.agruparItemsReporteCaja,
    this.inventario,
    this.validacionInventario,
    this.validacionLote,
    this.esGasolinera,
    this.esTiendaRopa,
    this.esRestaurante,
    this.usaCodigoBarras,
    this.ocultarModalRegistroComanda,
    this.recargoPorItem,
    this.porcentajeRecargoPorItem,
    this.imprimeTicketsEscPos,
    this.nombreComercialPorPuntoVenta,
    this.usaWhatsappApi,
    this.envioAutomaticoWhatsappApi,
    this.tiposDocumentosEnvioWhatsapp,
    this.tipoImpresion,
    this.tipoImpresionGuia,
    this.tipoPedidoRestaurantePorDefecto,
    this.integracionApi,
    this.rucNv,
    this.usoBalanza,
    this.seleccionLoteAutomatica,
    this.agruparItemsVenta,
    this.smtpUsuario,
    this.smtpHost,
    this.smtpClave,
    this.smtpPuerto,
    this.cantDecimales,
    this.cantDecimalesPrecioProducto,
    this.registroExterno,
    this.controlDespacho,
    this.buscarPorPuntoVenta,
    this.excluirMonitoreo,
    this.root,
    this.clienteImpresion,
    this.urlLogo,
    this.ubigeo,
    this.departamento,
    this.provincia,
    this.distrito,
    this.igv,
    this.tokenEvolution,
    this.tipoClienteWhatsapp,
    this.adicionarRetencionEnCotizacion,
    this.certificado,
    this.unidad,
    this.unidades,
    this.modulos,
    this.cuentas,
    this.empresasAdjuntas,
    this.plantillaA4,
    this.plantillaA4Boleta,
    this.plantillaA4Factura,
    this.plantillaTicket,
    this.plantillaCotizacion,
    this.plantillaPercepcion,
    this.plantillaRetencion,
    this.plantillaOrdenRestaurante,
    this.plantillaGuia,
    this.plantillaGuiaTicket,
    this.plantillaGuiaManual,
    this.plantillaConstanciaEntrega,
    this.plantillaComunicacionBaja,
    this.plantillaLetra,
    this.plantillaMovimientoCaja,
    this.plantillaCompra,
    this.plantillaDespacho,
    this.plantillaCuentasPorCobrar,
  });
  factory Company.fromJson(Map<String, dynamic> json) => Company(
    id: json['id'] ,
    direccion: json['direccion'],
    estadoServicio: json['estadoServicio'],
    restriccionCertificado: json['restriccionCertificado'],
    estadoCerticado: json['estadoCerticado'],
    motivoCorteServicio: json['motivoCorteServicio'],
    razonSocial: json['razonSocial'],
    nombreComercial: json['nombreComercial'],
    representante: json['representante'],
    uuid: json['uuid'],
    dominio: json['dominio'],
    telefono: json['telefono'],
    url: json['url'],
    email: json['email'],
    emailNotificacion: json['emailNotificacion'],
    numeroNotificacion: json['numeroNotificacion'],
    urlOse: json['urlOse'],
    usuarioSol: json['usuarioSol'],
    claveSol: json['claveSol'],
    usuarioSecSol: json['usuarioSecSol'],
    claveSecSol: json['claveSecSol'],
    clientIdSunat: json['clientIdSunat'],
    clientSecretSunat: json['clientSecretSunat'],
    esProduccion: json['esProduccion'],
    canalOnline: json['canalOnline'],
    ruc: json['ruc'],
    cantComprobanteDinamico: json['cantComprobanteDinamico'],
    viewCode: json['viewCode'],
    format: json['format'],
    tipoComprobantePorDefecto: json['tipoComprobantePorDefecto'],
    tipoGuiaPorDefecto: json['tipoGuiaPorDefecto'],
    envioAutomaticoSunat: json['envioAutomaticoSunat'],
    preciosIncluidoIgv: json['preciosIncluidoIgv'],
    descripcionLarga: json['descripcionLarga'],
    clientePorDefecto: json['clientePorDefecto'],
    previsualizarPostVenta: json['previsualizarPostVenta'],
    impresionAutomatica: json['impresionAutomatica'],
    aperturaCajaAutomatica: json['aperturaCajaAutomatica'],
    cierreCajaAutomatica: json['cierreCajaAutomatica'],
    agruparItemsReporteCaja: json['agruparItemsReporteCaja'],
    inventario: json['inventario'],
    validacionInventario: json['validacionInventario'],
    validacionLote: json['validacionLote'],
    esGasolinera: json['esGasolinera'],
    esTiendaRopa: json['esTiendaRopa'],
    esRestaurante: json['esRestaurante'],
    usaCodigoBarras: json['usaCodigoBarras'],
    ocultarModalRegistroComanda: json['ocultarModalRegistroComanda'],
    recargoPorItem: json['recargoPorItem'],
    porcentajeRecargoPorItem: (json['porcentajeRecargoPorItem'] as num?)?.toDouble(),
    imprimeTicketsEscPos: json['imprimeTicketsEscPos'],
    nombreComercialPorPuntoVenta: json['nombreComercialPorPuntoVenta'],
    usaWhatsappApi: json['usaWhatsappApi'],
    envioAutomaticoWhatsappApi: json['envioAutomaticoWhatsappApi'],
    tiposDocumentosEnvioWhatsapp: json['tiposDocumentosEnvioWhatsapp'],
    tipoImpresion: json['tipoImpresion'],
    tipoImpresionGuia: json['tipoImpresionGuia'],
    tipoPedidoRestaurantePorDefecto: json['tipoPedidoRestaurantePorDefecto'],
    integracionApi: json['integracionApi'],
    rucNv: json['rucNv'],
    usoBalanza: json['usoBalanza'],
    seleccionLoteAutomatica: json['seleccionLoteAutomatica'],
    agruparItemsVenta: json['agruparItemsVenta'],
    smtpUsuario: json['smtpUsuario'],
    smtpHost: json['smtpHost'],
    smtpClave: json['smtpClave'],
    smtpPuerto: json['smtpPuerto'],
    cantDecimales: json['cantDecimales'],
    cantDecimalesPrecioProducto: json['cantDecimalesPrecioProducto'],
    registroExterno: json['registroExterno'],
    controlDespacho: json['controlDespacho'],
    buscarPorPuntoVenta: json['buscarPorPuntoVenta'],
    excluirMonitoreo: json['excluirMonitoreo'],
    root: json['root'],
    clienteImpresion: json['clienteImpresion'],
    urlLogo: json['urlLogo'],
    ubigeo: json['ubigeo'],
    departamento: json['departamento'],
    provincia: json['provincia'],
    distrito: json['distrito'],
    igv: (json['igv'] as num?)?.toDouble(),
    tokenEvolution: json['tokenEvolution'],
    tipoClienteWhatsapp: json['tipoClienteWhatsapp'],
    adicionarRetencionEnCotizacion: json['adicionarRetencionEnCotizacion'],
    certificado: json['certificado'] != null ? Certificate.fromJson(json['certificado']) : null,
    unidad: json['unidad'] != null ? UnitCode.fromJson(json['unidad']) : null,
    unidades: (json['unidades'] as List?)?.map((e) => UnitCode.fromJson(e)).toList(),
    modulos: (json['modulos'] as List?)?.map((e) => ModuleAccess.fromJson(e)).toList(),
    cuentas: (json['cuentas'] as List?)?.map((e) => BankAccount.fromJson(e)).toList(),
    empresasAdjuntas: (json['empresasAdjuntas'] as List?)?.map((e) => AttachedCompany.fromJson(e)).toList(),
    plantillaA4: json['plantillaA4'] != null ? TicketDesign.fromJson(json['plantillaA4']) : null,
    plantillaA4Boleta: json['plantillaA4Boleta'] != null ? TicketDesign.fromJson(json['plantillaA4Boleta']) : null,
    plantillaA4Factura: json['plantillaA4Factura'] != null ? TicketDesign.fromJson(json['plantillaA4Factura']) : null,
    plantillaTicket: json['plantillaTicket'] != null ? TicketDesign.fromJson(json['plantillaTicket']) : null,
    plantillaCotizacion: json['plantillaCotizacion'] != null ? TicketDesign.fromJson(json['plantillaCotizacion']) : null,
    plantillaPercepcion: json['plantillaPercepcion'] != null ? TicketDesign.fromJson(json['plantillaPercepcion']) : null,
    plantillaRetencion: json['plantillaRetencion'] != null ? TicketDesign.fromJson(json['plantillaRetencion']) : null,
    plantillaOrdenRestaurante: json['plantillaOrdenRestaurante'] != null ? TicketDesign.fromJson(json['plantillaOrdenRestaurante']) : null,
    plantillaGuia: json['plantillaGuia'] != null ? TicketDesign.fromJson(json['plantillaGuia']) : null,
    plantillaGuiaTicket: json['plantillaGuiaTicket'] != null ? TicketDesign.fromJson(json['plantillaGuiaTicket']) : null,
    plantillaGuiaManual: json['plantillaGuiaManual'] != null ? TicketDesign.fromJson(json['plantillaGuiaManual']) : null,
    plantillaConstanciaEntrega: json['plantillaConstanciaEntrega'] != null ? TicketDesign.fromJson(json['plantillaConstanciaEntrega']) : null,
    plantillaComunicacionBaja: json['plantillaComunicacionBaja'] != null ? TicketDesign.fromJson(json['plantillaComunicacionBaja']) : null,
    plantillaLetra: json['plantillaLetra'] != null ? TicketDesign.fromJson(json['plantillaLetra']) : null,
    plantillaMovimientoCaja: json['plantillaMovimientoCaja'] != null ? TicketDesign.fromJson(json['plantillaMovimientoCaja']) : null,
    plantillaCompra: json['plantillaCompra'] != null ? TicketDesign.fromJson(json['plantillaCompra']) : null,
    plantillaDespacho: json['plantillaDespacho'] != null ? TicketDesign.fromJson(json['plantillaDespacho']) : null,
    plantillaCuentasPorCobrar: json['plantillaCuentasPorCobrar'] != null ? TicketDesign.fromJson(json['plantillaCuentasPorCobrar']) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'direccion': direccion,
    'estadoServicio': estadoServicio,
    'restriccionCertificado': restriccionCertificado,
    'estadoCerticado': estadoCerticado,
    'motivoCorteServicio': motivoCorteServicio,
    'razonSocial': razonSocial,
    'nombreComercial': nombreComercial,
    'representante': representante,
    'uuid': uuid,
    'dominio': dominio,
    'telefono': telefono,
    'url': url,
    'email': email,
    'emailNotificacion': emailNotificacion,
    'numeroNotificacion': numeroNotificacion,
    'urlOse': urlOse,
    'usuarioSol': usuarioSol,
    'claveSol': claveSol,
    'usuarioSecSol': usuarioSecSol,
    'claveSecSol': claveSecSol,
    'clientIdSunat': clientIdSunat,
    'clientSecretSunat': clientSecretSunat,
    'esProduccion': esProduccion,
    'canalOnline': canalOnline,
    'ruc': ruc,
    'cantComprobanteDinamico': cantComprobanteDinamico,
    'viewCode': viewCode,
    'format': format,
    'tipoComprobantePorDefecto': tipoComprobantePorDefecto,
    'tipoGuiaPorDefecto': tipoGuiaPorDefecto,
    'envioAutomaticoSunat': envioAutomaticoSunat,
    'preciosIncluidoIgv': preciosIncluidoIgv,
    'descripcionLarga': descripcionLarga,
    'clientePorDefecto': clientePorDefecto,
    'previsualizarPostVenta': previsualizarPostVenta,
    'impresionAutomatica': impresionAutomatica,
    'aperturaCajaAutomatica': aperturaCajaAutomatica,
    'cierreCajaAutomatica': cierreCajaAutomatica,
    'agruparItemsReporteCaja': agruparItemsReporteCaja,
    'inventario': inventario,
    'validacionInventario': validacionInventario,
    'validacionLote': validacionLote,
    'esGasolinera': esGasolinera,
    'esTiendaRopa': esTiendaRopa,
    'esRestaurante': esRestaurante,
    'usaCodigoBarras': usaCodigoBarras,
    'ocultarModalRegistroComanda': ocultarModalRegistroComanda,
    'recargoPorItem': recargoPorItem,
    'porcentajeRecargoPorItem': porcentajeRecargoPorItem,
    'imprimeTicketsEscPos': imprimeTicketsEscPos,
    'nombreComercialPorPuntoVenta': nombreComercialPorPuntoVenta,
    'usaWhatsappApi': usaWhatsappApi,
    'envioAutomaticoWhatsappApi': envioAutomaticoWhatsappApi,
    'tiposDocumentosEnvioWhatsapp': tiposDocumentosEnvioWhatsapp,
    'tipoImpresion': tipoImpresion,
    'tipoImpresionGuia': tipoImpresionGuia,
    'tipoPedidoRestaurantePorDefecto': tipoPedidoRestaurantePorDefecto,
    'integracionApi': integracionApi,
    'rucNv': rucNv,
    'usoBalanza': usoBalanza,
    'seleccionLoteAutomatica': seleccionLoteAutomatica,
    'agruparItemsVenta': agruparItemsVenta,
    'smtpUsuario': smtpUsuario,
    'smtpHost': smtpHost,
    'smtpClave': smtpClave,
    'smtpPuerto': smtpPuerto,
    'cantDecimales': cantDecimales,
    'cantDecimalesPrecioProducto': cantDecimalesPrecioProducto,
    'registroExterno': registroExterno,
    'controlDespacho': controlDespacho,
    'buscarPorPuntoVenta': buscarPorPuntoVenta,
    'excluirMonitoreo': excluirMonitoreo,
    'root': root,
    'clienteImpresion': clienteImpresion,
    'urlLogo': urlLogo,
    'ubigeo': ubigeo,
    'departamento': departamento,
    'provincia': provincia,
    'distrito': distrito,
    'igv': igv,
    'tokenEvolution': tokenEvolution,
    'tipoClienteWhatsapp': tipoClienteWhatsapp,
    'adicionarRetencionEnCotizacion': adicionarRetencionEnCotizacion,
    'certificado': certificado?.toJson(),
    'unidad': unidad?.toJson(),
    'unidades': unidades?.map((e) => e.toJson()).toList(),
    'modulos': modulos?.map((e) => e.toJson()).toList(),
    'cuentas': cuentas?.map((e) => e.toJson()).toList(),
    'empresasAdjuntas': empresasAdjuntas?.map((e) => e.toJson()).toList(),
    'plantillaA4': plantillaA4?.toJson(),
    'plantillaA4Boleta': plantillaA4Boleta?.toJson(),
    'plantillaA4Factura': plantillaA4Factura?.toJson(),
    'plantillaTicket': plantillaTicket?.toJson(),
    'plantillaCotizacion': plantillaCotizacion?.toJson(),
    'plantillaPercepcion': plantillaPercepcion?.toJson(),
    'plantillaRetencion': plantillaRetencion?.toJson(),
    'plantillaOrdenRestaurante': plantillaOrdenRestaurante?.toJson(),
    'plantillaGuia': plantillaGuia?.toJson(),
    'plantillaGuiaTicket': plantillaGuiaTicket?.toJson(),
    'plantillaGuiaManual': plantillaGuiaManual?.toJson(),
    'plantillaConstanciaEntrega': plantillaConstanciaEntrega?.toJson(),
    'plantillaComunicacionBaja': plantillaComunicacionBaja?.toJson(),
    'plantillaLetra': plantillaLetra?.toJson(),
    'plantillaMovimientoCaja': plantillaMovimientoCaja?.toJson(),
    'plantillaCompra': plantillaCompra?.toJson(),
    'plantillaDespacho': plantillaDespacho?.toJson(),
    'plantillaCuentasPorCobrar': plantillaCuentasPorCobrar?.toJson(),
  };
}
