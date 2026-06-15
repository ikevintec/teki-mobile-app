import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/cashRegisterDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentDetail.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFee.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';

final ticketProvider =
    StateNotifierProvider<TicketNotifier, TicketProvider>((ref) {
  final TicketsSaleRepository ticketsSaleRepository =
      TicketSaleRepositoryImpl();
  return TicketNotifier(ref: ref, ticketsSaleRepository: ticketsSaleRepository);
});

class TicketNotifier extends StateNotifier<TicketProvider> {
  final TicketsSaleRepository ticketsSaleRepository;
  final Ref ref;
  TicketNotifier({
    required this.ref,
    required this.ticketsSaleRepository,
  }) : super(TicketProvider(
            ticket: Ticket(
                items: [],
                incIgv: true,
                tipoComprobante: 'NV', // Factura
                codigoMoneda: 'PEN',
                agruparItems: false,
                cambio: 0,
                despachoPosterior: false,
                isRetencion: false,
                pagoAnticipado: false,
                tipoVenta: "CONTADO",
                ordenCompra: '0101',
                codigoTipoOperacion: '0101', // Por defecto
                vendedor: ref.read(authStateProvider).user,
                puntoVenta: ref.read(sesionProvider).office,
                fechaEmisionDate: DateTime.now())));

  void updateTicket(Ticket ticket) {
    state = state.copyWith(ticket: ticket);
  }

  void setTipoComprobante(String tipoDocumento) {
    Ticket ticketToUpdate =
        state.ticket.copyWith(tipoComprobante: tipoDocumento);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setTipoOperacion(String codigoTipoOperacion) {
    Ticket ticketToUpdate =
        state.ticket.copyWith(codigoTipoOperacion: codigoTipoOperacion);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setNumeroOrden(String numeroOrden) {
    Ticket ticketToUpdate = state.ticket.copyWith(ordenCompra: numeroOrden);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setFechaEmision(DateTime fechaEmision) {
    Ticket ticketToUpdate = state.ticket.copyWith(
        fechaEmision: DateFormat('yyyy-MM-dd').format(fechaEmision),
        horaEmision: DateFormat('HH:mm:ss').format(fechaEmision),
        fechaEmisionDate: fechaEmision);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setFechaVencimiento(DateTime fechaVencimiento) {
    Ticket ticketToUpdate = state.ticket.copyWith(
      fechaVencimiento: DateFormat('yyyy-MM-dd').format(fechaVencimiento),
      fechaVencimientoDate: fechaVencimiento,
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setSerie(String serie) {
    Ticket ticketToUpdate = state.ticket.copyWith(serie: serie);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setNumero(int numero) {
    Ticket ticketToUpdate = state.ticket.copyWith(numero: numero);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setTicketsData() {
    final productSaleProviderData = ref.read(productSaleProvider);
    final clienteSaleProviderData = ref.read(customerSaleProvider);
    Ticket ticketToUpdate = state.ticket.copyWith(
      items: productSaleProviderData.productsSales,
      incIgv: productSaleProviderData.incIgv,
      // tipoComprobante: productSaleProviderData.tipoComprobante,
      codigoMoneda: productSaleProviderData.currency?.codigoMoneda,
      cliente: clienteSaleProviderData.customer,
      tipoDocumentoReceptor: clienteSaleProviderData.customer.tipoDocumento,
      numeroDocumentoReceptor: clienteSaleProviderData.customer.numeroDocumento,
      denominacionReceptor: clienteSaleProviderData.customer.razonSocial,
      direccionReceptor: clienteSaleProviderData.customer.direccion,
      emailReceptor: clienteSaleProviderData.customer.email,
      telefonoReceptor: clienteSaleProviderData.customer.telefono,
      puntoVenta: ref.read(sesionProvider).office,
      estacionVenta: ref.read(sesionProvider).saleStation,
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setAgruparItems(bool agrupar) {
    Ticket ticketToUpdate = state.ticket.copyWith(agruparItems: agrupar);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setMovimientoCaja({
    required double total,
    required List<PaymentDetail> pagos,
    required double cambio,
  }) {
    Ticket ticketToUpdate = state.ticket.copyWith(
      cuotas: null,
      movimientoCaja: CashRegisterDetail(pagos: pagos),
      cambio: cambio,
      tipoVenta: "CONTADO",
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setCuotas(List<TicketFee> cuotas, {int? diasCredito}) {
    Ticket ticketToUpdate = state.ticket.copyWith(
      movimientoCaja: null,
      cuotas: cuotas,
      tipoVenta: "CREDITO",
      diasCredito: diasCredito,
    );
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setVendedor(User vendedor) {
    Ticket ticketToUpdate = state.ticket.copyWith(vendedor: vendedor);
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void setPlacaVehiculo(String placa) {
    Ticket ticketToUpdate = state.ticket.copyWith(placaVehiculo: placa.isEmpty ? null : placa.toUpperCase());
    state = state.copyWith(ticket: ticketToUpdate);
  }

  void resetTicket() {
    state = TicketProvider(
      ticket: Ticket(
        items: [],
        incIgv: true,
        tipoComprobante: 'NV',
        codigoMoneda: 'PEN',
        agruparItems: false,
        cambio: 0,
        despachoPosterior: false,
        isRetencion: false,
        pagoAnticipado: false,
        tipoVenta: "CONTADO",
        ordenCompra: '0101',
        codigoTipoOperacion: '0101',
        vendedor: ref.read(authStateProvider).user,
        puntoVenta: ref.read(sesionProvider).office,
        fechaEmisionDate: DateTime.now(),
      ),
    );
  }

  void setEdited(bool isEdited) {
    state = state.copyWith(isEdit: isEdited);
  }

  /// Construye el payload del ticket listo para enviar al backend (sin llamar a la API).
  Ticket getTicketPayload() {
    return Ticket(
      serie: state.ticket.serie,
      id: state.ticket.id,
      tipoComprobante: state.ticket.tipoComprobante,
      numero: state.ticket.numero,
      fechaEmision: state.ticket.fechaEmision,
      fechaEmisionDate: state.ticket.fechaEmisionDate,
      horaEmision: state.ticket.horaEmision,
      codigoMoneda: state.ticket.codigoMoneda,
      fechaVencimiento: state.ticket.fechaVencimiento,
      fechaVencimientoDate: state.ticket.fechaVencimientoDate,
      codigoTipoOperacion: (state.ticket.codigoTipoOperacion?.isNotEmpty ?? false)
          ? state.ticket.codigoTipoOperacion
          : '0101',
      rucEmisor: state.ticket.rucEmisor,
      razonSocialEmisor: state.ticket.razonSocialEmisor,
      codigoLocalAnexoEmisor: state.ticket.codigoLocalAnexoEmisor,
      tipoDocumentoReceptor: state.ticket.tipoDocumentoReceptor,
      numeroDocumentoReceptor: state.ticket.numeroDocumentoReceptor,
      denominacionReceptor: state.ticket.denominacionReceptor,
      direccionReceptor: state.ticket.direccionReceptor,
      emailReceptor: state.ticket.emailReceptor,
      telefonoReceptor: state.ticket.telefonoReceptor,
      cliente: state.ticket.cliente,
      camposAdicionales: state.ticket.camposAdicionales,
      cuotas: state.ticket.cuotas,
      numeroOrdenRestaurante: state.ticket.numeroOrdenRestaurante,
      codigoTipoOtroDocumentoRelacionado: state.ticket.codigoTipoOtroDocumentoRelacionado,
      serieNumeroOtroDocumentoRelacionado: state.ticket.serieNumeroOtroDocumentoRelacionado,
      totalValorVentaExportacion: state.ticket.totalValorVentaExportacion == 0 ? null : state.ticket.totalValorVentaExportacion,
      totalValorVentaGravada: state.ticket.totalValorVentaGravada == 0 ? null : state.ticket.totalValorVentaGravada,
      totalValorVentaInafecta: state.ticket.totalValorVentaInafecta == 0 ? null : state.ticket.totalValorVentaInafecta,
      totalValorVentaExonerada: state.ticket.totalValorVentaExonerada == 0 ? null : state.ticket.totalValorVentaExonerada,
      totalValorVentaGratuita: state.ticket.totalValorVentaGratuita == 0 ? null : state.ticket.totalValorVentaGratuita,
      totalValorBaseIsc: state.ticket.totalValorBaseIsc == 0 ? null : state.ticket.totalValorBaseIsc,
      totalValorBaseIgv: state.ticket.totalValorBaseIgv == 0 ? null : state.ticket.totalValorBaseIgv,
      totalValorVentaGravadaIvap: state.ticket.totalValorVentaGravadaIvap == 0 ? null : state.ticket.totalValorVentaGravadaIvap,
      totalTributosOperacionGratuita: state.ticket.totalTributosOperacionGratuita == 0 ? null : state.ticket.totalTributosOperacionGratuita,
      totalTributosBolsas: state.ticket.totalTributosBolsas == 0 ? null : state.ticket.totalTributosBolsas,
      totalIvap: state.ticket.totalIvap == 0 ? null : state.ticket.totalIvap,
      totalIgv: state.ticket.totalIgv == 0 ? null : state.ticket.totalIgv,
      totalIsc: state.ticket.totalIsc == 0 ? null : state.ticket.totalIsc,
      otrosTributos: state.ticket.otrosTributos == 0 ? null : state.ticket.otrosTributos,
      otrosCargos: state.ticket.otrosCargos == 0 ? null : state.ticket.otrosCargos,
      porcentajeOtrosCargos: state.ticket.porcentajeOtrosCargos,
      totalValorVenta: state.ticket.totalValorVenta,
      totalVenta: state.ticket.totalVenta,
      totalVentaCredito: state.ticket.totalVentaCredito,
      totalAnticipos: state.ticket.totalAnticipos,
      pagoAnticipado: state.ticket.pagoAnticipado,
      regimenPercepcion: state.ticket.regimenPercepcion,
      montoPercepcion: state.ticket.montoPercepcion,
      porcentajePercepcion: state.ticket.porcentajePercepcion,
      totalVentaPercepcion: state.ticket.totalVentaPercepcion,
      montoBaseRetencion: state.ticket.montoBaseRetencion,
      montoRetencion: state.ticket.montoRetencion,
      porcentajeRetencion: state.ticket.porcentajeRetencion,
      montoBaseDescuento: state.ticket.montoBaseDescuento,
      porcentajeDescuento: state.ticket.porcentajeDescuento,
      totalDescuento: state.ticket.totalDescuento == 0 ? null : state.ticket.totalDescuento,
      descuentoGlobal: state.ticket.descuentoGlobal,
      descuentoPorItem: state.ticket.descuentoPorItem,
      codigoDescuento: state.ticket.codigoDescuento,
      porcentajeDescuentoGlobal: state.ticket.porcentajeDescuentoGlobal,
      serieAfectado: state.ticket.serieAfectado,
      numeroAfectado: state.ticket.numeroAfectado,
      tipoComprobanteAfectado: state.ticket.tipoComprobanteAfectado,
      motivoNota: state.ticket.motivoNota,
      codigoTipoNotaCredito: state.ticket.codigoTipoNotaCredito,
      codigoTipoNotaDebito: state.ticket.codigoTipoNotaDebito,
      identificadorDocumento: state.ticket.identificadorDocumento,
      estadoItem: state.ticket.estadoItem,
      estadoSunat: state.ticket.estadoSunat,
      estado: state.ticket.estado,
      estadoAnterior: state.ticket.estadoAnterior,
      mensajeRespuesta: state.ticket.mensajeRespuesta,
      motivoAnulacion: state.ticket.motivoAnulacion,
      incIgv: state.ticket.incIgv,
      agruparItems: state.ticket.agruparItems,
      efectivo: state.ticket.efectivo,
      cambio: state.ticket.cambio,
      items: state.ticket.items,
      anticipos: state.ticket.anticipos,
      guiasRelacionadas: state.ticket.guiasRelacionadas,
      uuid: state.ticket.uuid,
      ordenCompra: state.ticket.ordenCompra,
      condicionPago: state.ticket.condicionPago,
      observacion: state.ticket.observacion,
      codigosRespuestaSunat: state.ticket.codigosRespuestaSunat,
      boletaAnuladaSinEmitir: state.ticket.boletaAnuladaSinEmitir,
      envioAutomaticoSunat: state.ticket.envioAutomaticoSunat,
      archivos: state.ticket.archivos,
      sunatRespuestas: state.ticket.sunatRespuestas,
      codigoHash: state.ticket.codigoHash,
      codigoMedioPago: state.ticket.codigoMedioPago,
      cuentaDetraccion: state.ticket.cuentaDetraccion,
      codigoDetraccion: state.ticket.codigoDetraccion,
      porcentajeDetraccion: state.ticket.porcentajeDetraccion,
      montoDetraccion: state.ticket.montoDetraccion,
      empresa: state.ticket.empresa,
      empresaAdjunta: state.ticket.empresaAdjunta,
      puntoVenta: state.ticket.puntoVenta,
      estacionVenta: state.ticket.estacionVenta,
      cotizacion: state.ticket.cotizacion,
      tipoVenta: state.ticket.tipoVenta,
      esProduccion: state.ticket.esProduccion,
      diasCredito: state.ticket.diasCredito,
      anulado: state.ticket.anulado,
      comprobanteSustituto: state.ticket.comprobanteSustituto,
      isSendBill: state.ticket.isSendBill,
      idNotaVentaAnulada: state.ticket.idNotaVentaAnulada,
      vendedor: state.ticket.vendedor,
      pedidoRestaurante: state.ticket.pedidoRestaurante,
      cuentaRestaurante: state.ticket.cuentaRestaurante,
      canal: state.ticket.canal,
      comprobanteAnterior: state.ticket.comprobanteAnterior,
      movimientoCaja: state.ticket.movimientoCaja,
      intentosSendSummary: state.ticket.intentosSendSummary,
      createdOn: state.ticket.createdOn,
      adelanto: state.ticket.adelanto,
      createdBy: state.ticket.createdBy,
      updatedBy: state.ticket.updatedBy,
      updatedOn: state.ticket.updatedOn,
      deleteBy: state.ticket.deleteBy,
      deletedOn: state.ticket.deletedOn,
      isEdited: state.ticket.isEdited,
      numeroCotizacion: state.ticket.numeroCotizacion,
      despachoPosterior: state.ticket.despachoPosterior,
      isRetencion: state.ticket.isRetencion,
      placaVehiculo: state.ticket.placaVehiculo,
    );
  }

  Future<Ticket?> proceessTicket() async {
    try {
      final ticketToSend = getTicketPayload();
      if (state.isEdit && ticketToSend.id != null) {
        return await ticketsSaleRepository.updateTicket(ticketToSend);
      }
      return await ticketsSaleRepository.createTicket(ticketToSend);
    } catch (e) {
      errorNotification("Error al crear el ticket: $e");
      return null;
    }
  }

  // ignore: unused_element
  Future<Ticket?> _proceessTicketLegacy() async {
    try {
      Ticket ticketToSend = Ticket(
        serie: state.ticket.serie,
        id: state.ticket.id,
        tipoComprobante: state.ticket.tipoComprobante,
        numero: state.ticket.numero,
        fechaEmision: state.ticket.fechaEmision,
        fechaEmisionDate: state.ticket.fechaEmisionDate,
        horaEmision: state.ticket.horaEmision,
        codigoMoneda: state.ticket.codigoMoneda,
        fechaVencimiento: state.ticket.fechaVencimiento,
        fechaVencimientoDate: state.ticket.fechaVencimientoDate,
        codigoTipoOperacion: state.ticket.codigoTipoOperacion,
        rucEmisor: state.ticket.rucEmisor,
        razonSocialEmisor: state.ticket.razonSocialEmisor,
        codigoLocalAnexoEmisor: state.ticket.codigoLocalAnexoEmisor,
        tipoDocumentoReceptor: state.ticket.tipoDocumentoReceptor,
        numeroDocumentoReceptor: state.ticket.numeroDocumentoReceptor,
        denominacionReceptor: state.ticket.denominacionReceptor,
        direccionReceptor: state.ticket.direccionReceptor,
        emailReceptor: state.ticket.emailReceptor,
        telefonoReceptor: state.ticket.telefonoReceptor,
        cliente: state.ticket.cliente,
        camposAdicionales: state.ticket.camposAdicionales,
        cuotas: state.ticket.cuotas,
        numeroOrdenRestaurante: state.ticket.numeroOrdenRestaurante,
        codigoTipoOtroDocumentoRelacionado:
            state.ticket.codigoTipoOtroDocumentoRelacionado,
        serieNumeroOtroDocumentoRelacionado:
            state.ticket.serieNumeroOtroDocumentoRelacionado,
        totalValorVentaExportacion: state.ticket.totalValorVentaExportacion == 0
            ? null
            : state.ticket.totalValorVentaExportacion,
        totalValorVentaGravada: state.ticket.totalValorVentaGravada == 0
            ? null
            : state.ticket.totalValorVentaGravada,
        totalValorVentaInafecta: state.ticket.totalValorVentaInafecta == 0
            ? null
            : state.ticket.totalValorVentaInafecta,
        totalValorVentaExonerada: state.ticket.totalValorVentaExonerada == 0
            ? null
            : state.ticket.totalValorVentaExonerada,
        totalValorVentaGratuita: state.ticket.totalValorVentaGratuita == 0
            ? null
            : state.ticket.totalValorVentaGratuita,
        totalValorBaseIsc: state.ticket.totalValorBaseIsc == 0
            ? null
            : state.ticket.totalValorBaseIsc,
        totalValorBaseIgv: state.ticket.totalValorBaseIgv == 0
            ? null
            : state.ticket.totalValorBaseIgv,
        totalValorVentaGravadaIvap: state.ticket.totalValorVentaGravadaIvap == 0
            ? null
            : state.ticket.totalValorVentaGravadaIvap,
        totalTributosOperacionGratuita:
            state.ticket.totalTributosOperacionGratuita == 0
                ? null
                : state.ticket.totalTributosOperacionGratuita,
        totalTributosBolsas: state.ticket.totalTributosBolsas == 0
            ? null
            : state.ticket.totalTributosBolsas,
        totalIvap: state.ticket.totalIvap == 0 ? null : state.ticket.totalIvap,
        totalIgv: state.ticket.totalIgv == 0 ? null : state.ticket.totalIgv,
        totalIsc: state.ticket.totalIsc == 0 ? null : state.ticket.totalIsc,
        otrosTributos:
            state.ticket.otrosTributos == 0 ? null : state.ticket.otrosTributos,
        otrosCargos:
            state.ticket.otrosCargos == 0 ? null : state.ticket.otrosCargos,
        porcentajeOtrosCargos: state.ticket.porcentajeOtrosCargos,
        totalValorVenta: state.ticket.totalValorVenta,
        totalVenta: state.ticket.totalVenta,
        totalVentaCredito: state.ticket.totalVentaCredito,
        totalAnticipos: state.ticket.totalAnticipos,
        pagoAnticipado: state.ticket.pagoAnticipado,
        regimenPercepcion: state.ticket.regimenPercepcion,
        montoPercepcion: state.ticket.montoPercepcion,
        porcentajePercepcion: state.ticket.porcentajePercepcion,
        totalVentaPercepcion: state.ticket.totalVentaPercepcion,
        montoBaseRetencion: state.ticket.montoBaseRetencion,
        montoRetencion: state.ticket.montoRetencion,
        porcentajeRetencion: state.ticket.porcentajeRetencion,
        montoBaseDescuento: state.ticket.montoBaseDescuento,
        porcentajeDescuento: state.ticket.porcentajeDescuento,
        totalDescuento: state.ticket.totalDescuento == 0
                ? null
                : state.ticket.totalDescuento,
        descuentoGlobal: state.ticket.descuentoGlobal,
        descuentoPorItem: state.ticket.descuentoPorItem,
        codigoDescuento: state.ticket.codigoDescuento,
        porcentajeDescuentoGlobal: state.ticket.porcentajeDescuentoGlobal,
        serieAfectado: state.ticket.serieAfectado,
        numeroAfectado: state.ticket.numeroAfectado,
        tipoComprobanteAfectado: state.ticket.tipoComprobanteAfectado,
        motivoNota: state.ticket.motivoNota,
        codigoTipoNotaCredito: state.ticket.codigoTipoNotaCredito,
        codigoTipoNotaDebito: state.ticket.codigoTipoNotaDebito,
        identificadorDocumento: state.ticket.identificadorDocumento,
        estadoItem: state.ticket.estadoItem,
        estadoSunat: state.ticket.estadoSunat,
        estado: state.ticket.estado,
        estadoAnterior: state.ticket.estadoAnterior,
        mensajeRespuesta: state.ticket.mensajeRespuesta,
        motivoAnulacion: state.ticket.motivoAnulacion,
        incIgv: state.ticket.incIgv,
        agruparItems: state.ticket.agruparItems,
        efectivo: state.ticket.efectivo,
        cambio: state.ticket.cambio,
        items: state.ticket.items,
        anticipos: state.ticket.anticipos,
        guiasRelacionadas: state.ticket.guiasRelacionadas,
        uuid: state.ticket.uuid,
        ordenCompra: state.ticket.ordenCompra,
        condicionPago: state.ticket.condicionPago,
        observacion: state.ticket.observacion,
        codigosRespuestaSunat: state.ticket.codigosRespuestaSunat,
        boletaAnuladaSinEmitir: state.ticket.boletaAnuladaSinEmitir,
        envioAutomaticoSunat: state.ticket.envioAutomaticoSunat,
        archivos: state.ticket.archivos,
        sunatRespuestas: state.ticket.sunatRespuestas,
        codigoHash: state.ticket.codigoHash,
        codigoMedioPago: state.ticket.codigoMedioPago,
        cuentaDetraccion: state.ticket.cuentaDetraccion,
        codigoDetraccion: state.ticket.codigoDetraccion,
        porcentajeDetraccion: state.ticket.porcentajeDetraccion,
        montoDetraccion: state.ticket.montoDetraccion,
        empresa: state.ticket.empresa,
        empresaAdjunta: state.ticket.empresaAdjunta,
        puntoVenta: state.ticket.puntoVenta,
        estacionVenta: state.ticket.estacionVenta,
        cotizacion: state.ticket.cotizacion,
        tipoVenta: state.ticket.tipoVenta,
        esProduccion: state.ticket.esProduccion,
        diasCredito: state.ticket.diasCredito,
        anulado: state.ticket.anulado,
        comprobanteSustituto: state.ticket.comprobanteSustituto,
        isSendBill: state.ticket.isSendBill,
        idNotaVentaAnulada: state.ticket.idNotaVentaAnulada,
        vendedor: state.ticket.vendedor,
        pedidoRestaurante: state.ticket.pedidoRestaurante,
        cuentaRestaurante: state.ticket.cuentaRestaurante,
        canal: state.ticket.canal,
        comprobanteAnterior: state.ticket.comprobanteAnterior,
        movimientoCaja: state.ticket.movimientoCaja,
        intentosSendSummary: state.ticket.intentosSendSummary,
        createdOn: state.ticket.createdOn,
        adelanto: state.ticket.adelanto,
        createdBy: state.ticket.createdBy,
        updatedBy: state.ticket.updatedBy,
        updatedOn: state.ticket.updatedOn,
        deleteBy: state.ticket.deleteBy,
        deletedOn: state.ticket.deletedOn,
        isEdited: state.ticket.isEdited,
        numeroCotizacion: state.ticket.numeroCotizacion,
        despachoPosterior: state.ticket.despachoPosterior,
        isRetencion: state.ticket.isRetencion,
      );
      if (state.isEdit && ticketToSend.id != null) {
        return await ticketsSaleRepository.updateTicket(ticketToSend);
      }
      return await ticketsSaleRepository.createTicket(ticketToSend);
    } catch (e) {
      errorNotification("Error al crear el ticket: $e");
      return null;
    }
  }
}

class TicketProvider {
  final Ticket ticket;
  final bool isEdit;
  TicketProvider({required this.ticket, this.isEdit = false});
  TicketProvider copyWith({
    Ticket? ticket,
    bool? isEdit,
  }) {
    return TicketProvider(
      ticket: ticket ?? this.ticket,
      isEdit: isEdit ?? this.isEdit,
    );
  }
}
