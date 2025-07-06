import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/general/exhange.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/data/static/lists.dart';
import 'package:teki_app/src/providers/sale/products/helpers/tciket_detail_helper.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';

mixin ProductsSaleNotifierSettersMixin on StateNotifier<ProductsSaleState> {
  Ref get ref;

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  void setPageNumber(int pageNumber) {
    state = state.copyWith(pageNumber: pageNumber);
  }

  void setPaginacion(bool paginacion) {
    state = state.copyWith(paginacion: paginacion);
  }

  void setPerPage(int perPage) {
    state = state.copyWith(perPage: perPage);
  }

  void setSortField(String sortField) {
    state = state.copyWith(sortField: sortField);
  }

  void setSortOrder(int sortOrder) {
    state = state.copyWith(sortOrder: sortOrder);
  }

  void setFilterGlobal(String? filterGlobal) {
    state = state.copyWith(filterGlobal: filterGlobal);
  }

  void setIdPuntoVenta(int? idPuntoVenta) {
    state = state.copyWith(idPuntoVenta: idPuntoVenta);
  }

  void setIdPuntoVentaOrder(int? idPuntoVenta) {
    state = state.copyWith(idPuntoVenta: idPuntoVenta);
  }

  void setIncIgv(bool incIgv) {
    state = state.copyWith(incIgv: incIgv);
    if (state.productsSales.isNotEmpty) {
      calculoTotal();
    }
  }

  void setProductsSales(Product productsSales, int? index) {
    final existingProductIndex = index ??
        state.productsSales.indexWhere(
          (ticketDetail) =>
              (ticketDetail.producto != null
                  ? ticketDetail.producto!.id
                  : -1) ==
              productsSales.id,
        );
    if (existingProductIndex != -1) {
      final existingTicketDetail = state.productsSales[existingProductIndex];
      final updatedTicketDetail = changeQtyTicketDetail(
          ticketDetail: existingTicketDetail,
          quantity: (existingTicketDetail.cantidad ?? 0) + 1,
          sesion: ref.read(sesionProvider));
      state = state.copyWith(
        productsSales: List.from(state.productsSales)
          ..[existingProductIndex] = updatedTicketDetail,
      );
      return;
    }
    state = state.copyWith(
      productsSales: [
        ...state.productsSales,
        getTicketDetail(
            product: productsSales, sesion: ref.read(sesionProvider)),
      ],
    );
    setCurrency(state.currency!.codigoMoneda!);
  }

  void setCurrency(String codigoMoneda, [int? index]) {
    for (var i = 0; i < state.productsSales.length; i++) {
      if (index != null && i == index) continue;
      final double montoAnterior = state.incIgv
          ? state.productsSales[i].precioVentaUnitario!
          : state.productsSales[i].valorUnitario!;
      double? montoOriginal = state.productsSales[i].montoOriginal;
      final monedaOriginal = state.productsSales[i].monedaOriginal ??
          state.productsSales[i].producto!.moneda;
      if (montoOriginal == null) {
        state = state.copyWith(
          productsSales: List.from(state.productsSales)
            ..[i] = state.productsSales[i].copyWith(
              montoOriginal: montoAnterior,
            ),
        );
        montoOriginal = montoAnterior;
      }
      state = setPriceExchange(
          currencies: state.currencies,
          currency: state.currency!,
          monedaOrigen: monedaOriginal!,
          monedaDestino: codigoMoneda,
          monto: montoOriginal,
          state: state,
          index: i,
          sesion: ref.read(sesionProvider));
      if (state.productsSales[i].producto != null) {
        state = setPurchasePriceExchange(
            currencies: state.currencies,
            currency: state.currency!,
            monedaOrigen: monedaOriginal,
            monedaDestino: codigoMoneda,
            monto: state.productsSales[i].producto!.precioCompraUnidad ?? 0,
            state: state,
            index: i,
            sesion: ref.read(sesionProvider));
      }
    }
    state = state.copyWith(
        currency: state.currencies.firstWhere(
      (currency) => currency.codigoMoneda == codigoMoneda,
      orElse: () => state.currencies[0],
    ));
    calculoTotal();
  }

  void setCantidadProductSale(int index, double cantidad) {
    final existingTicketDetail = state.productsSales[index];
    if (existingTicketDetail.producto != null) {
      final updatedTicketDetail = changeQtyTicketDetail(
          ticketDetail: existingTicketDetail,
          quantity: cantidad,
          sesion: ref.read(sesionProvider));
      state = state.copyWith(
        productsSales: List.from(state.productsSales)
          ..[index] = updatedTicketDetail,
      );
    } else {
      final updatedTicketDetail = existingTicketDetail.copyWith(
        cantidad: cantidad,
      );
      state = state.copyWith(
        productsSales: List.from(state.productsSales)
          ..[index] = updatedTicketDetail,
      );
    }
    setCurrency(state.currency!.codigoMoneda!, index);
  }

  void setPrecioProductSale(int index, double precio) {
    final existingTicketDetail = state.productsSales[index];
    final updatedTicketDetail = state.incIgv
        ? existingTicketDetail.copyWith(
            precioVentaUnitario: precio,
            montoOriginal: precio,
            monedaOriginal: state.currency!.codigoMoneda)
        : existingTicketDetail.copyWith(
            valorUnitario: precio,
            montoOriginal: precio,
            monedaOriginal: state.currency!.codigoMoneda);
    state = state.copyWith(
      productsSales: List.from(state.productsSales)
        ..[index] = updatedTicketDetail,
    );
    calculoTotal();
  }

  void setDescriptionProductSale(int index, String description) {
    final existingTicketDetail = state.productsSales[index];
    final updatedTicketDetail =
        existingTicketDetail.copyWith(descripcion: description);
    state = state.copyWith(
      productsSales: List.from(state.productsSales)
        ..[index] = updatedTicketDetail,
    );
  }

  void createItemForm() {
    TicketDetail ticketDetail = TicketDetail(
      producto: null,
      codigoProducto: null,
      descripcion: '',
      cantidad: 1,
      detalle: '',
      codigoUnidadMedida: 'NIU',
      codigoTipoAfectacionIgv: '10',
      precioVentaUnitario: 0.0,
      valorUnitario: 0.0,
      valorVenta: 0.0,
      precioTotal: 0.0,
      monedaOriginal: state.currency!.codigoMoneda,
      montoOriginal: 0.0,
      esAnticipo: false,
      igv: 0.0,
    );
    state = state.copyWith(
      productsSales: [...state.productsSales, ticketDetail],
    );
    calculoTotal();
  }

  void calculoTotal() {
    final igvConfig = ref.watch(sesionProvider).config!.igv!;
    double porcentajeRecargoPorItem =
        ref.watch(sesionProvider).config!.porcentajeRecargoPorItem!;
    final tc = state.tipoComprobante;
    final porcentajeDescuentoGlobal = state.porcentajeDescuentoGlobal ?? 0.0;
    final porcentajeOtrosCargos = null;
    Ticket ticket = ref.read(ticketProvider).ticket;
    ticket = ticket.copyWith(
      totalValorVentaExonerada: 0,
      totalValorVentaExportacion: 0,
      totalValorVentaGravada: 0,
      totalValorVentaInafecta: 0,
      totalValorVentaGratuita: 0,
      totalValorBaseIsc: 0,
      totalValorBaseIgv: 0,
      totalValorVenta: 0,
      totalIsc: 0,
      totalIgv: 0,
      totalVenta: 0,
      totalDescuento: 0,
      descuentoPorItem: 0,
      descuentoGlobal: 0,
      montoBaseDescuento: 0,
      totalTributosBolsas: 0,
      montoBaseRetencion: 0,
      montoRetencion: 0,
      montoDetraccion: 0,
      totalAnticipos: 0,
      totalTributosOperacionGratuita: null,
    );
    for (var i = 0; i < state.productsSales.length; i++) {
      TicketDetail ticketDetailToUpdate = state.productsSales[i];
      ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          tributoVentaGratuita: null, porcentajeTributoVentaGratuita: null);
      Map<String, dynamic>? tipoIgv = catalogo07.firstWhere(
        (element) =>
            element['codigo'] == ticketDetailToUpdate.codigoTipoAfectacionIgv,
      );
      final cantidad = ticketDetailToUpdate.cantidad ?? 0;
      final esAnticipo = ticketDetailToUpdate.esAnticipo ?? false;
      final agregador = esAnticipo ? -1 : 1;
      double? valorVenta = 0.0;
      double? precioTotal = 0.0;
      var descuento = 0.0;
      double? montoBaseIgv = null;
      double? igv = 0.0;
      double? isc = 0.0;
      double? icbper = 0.0;
      if (ticketDetailToUpdate.isc != null) {
        isc = (ticketDetailToUpdate.isc!).toDouble();
      }
      if (ticketDetailToUpdate.tributoBolsa != null) {
        icbper = (ticketDetailToUpdate.tributoBolsa!).toDouble();
      }
      if (ticketDetailToUpdate.tieneImpuestoBolsas != null &&
          ticketDetailToUpdate.tieneImpuestoBolsas!) {
        icbper = 0.50 * cantidad;
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          tributoBolsa: icbper,
        );
        ticket = ticket.copyWith(
          totalTributosBolsas: (ticket.totalTributosBolsas ?? 0) + icbper,
        );
      }
      // Calcular el valor de venta
      final preciosIncluidoIgv = state.incIgv;

      if (tipoIgv['codigoRelacionado'] == '1001') {
        if (preciosIncluidoIgv) {
          ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
            valorUnitario: ticketDetailToUpdate.precioVentaUnitario! /
                (1 + ref.watch(sesionProvider).config!.igv!),
          );
        } else {
          ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
            precioVentaUnitario: ticketDetailToUpdate.valorUnitario! *
                (1 + ref.watch(sesionProvider).config!.igv!),
          );
        }
        valorVenta = ticketDetailToUpdate.valorUnitario! * cantidad;
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseDescuento: valorVenta,
        );
        if (ticketDetailToUpdate.descuento != null) {
          descuento = ticketDetailToUpdate.descuento!;
          valorVenta = valorVenta - descuento;
          ticket = ticket.copyWith(
            descuentoPorItem: (ticket.descuentoPorItem ?? 0) + descuento,
          );
        }
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          valorVenta: valorVenta,
        );
        montoBaseIgv = (valorVenta + isc!);
        igv = montoBaseIgv * igvConfig;
        precioTotal = (valorVenta + igv + isc + icbper!);
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseIgv: montoBaseIgv,
          porcentajeIgv: igvConfig * 100,
          igv: igv,
          precioTotal: precioTotal,
        );
      } else {
        if (preciosIncluidoIgv) {
          ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
            valorUnitario: ticketDetailToUpdate.precioVentaUnitario!,
          );
        } else {
          ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
            precioVentaUnitario: ticketDetailToUpdate.valorUnitario!,
          );
        }
        valorVenta = ticketDetailToUpdate.precioVentaUnitario! * cantidad;
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseDescuento: valorVenta,
        );
        if (ticketDetailToUpdate.descuento != null) {
          descuento = ticketDetailToUpdate.descuento!;
          valorVenta = valorVenta - descuento;
          ticket = ticket.copyWith(
            descuentoPorItem: ticket.descuentoPorItem! + descuento,
          );
        }
        precioTotal = valorVenta;
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          valorVenta: valorVenta,
          precioTotal: precioTotal,
          igv: null,
          montoBaseIgv: null,
          porcentajeIgv: null,
        );
      }
      ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
        montoBaseInafecto: null,
        montoBaseExonerado: null,
        montoBaseGratuito: null,
        montoBaseExportacion: null,
        valorReferencialUnitario: null,
        tributoVentaGratuita: null,
      );
      ticket = ticket.copyWith(
        totalDescuento: ticket.totalDescuento! + descuento,
      );
      ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
        porcentajeTributoVentaGratuita: null,
      );
      final valorAgrgador = (ticketDetailToUpdate.valorVenta! * agregador);
      if (tipoIgv['codigoRelacionado'] == '1001') {
        ticket = ticket.copyWith(
          totalValorVentaGravada:
              ticket.totalValorVentaGravada! + valorAgrgador,
          totalValorBaseIgv: ticket.totalValorBaseIgv! + valorAgrgador,
          totalIgv: ticket.totalIgv! + (ticketDetailToUpdate.igv! * agregador),
        );
      } else if (tipoIgv['codigoRelacionado'] == '1002') {
        ticket = ticket.copyWith(
          totalValorVentaInafecta:
              ticket.totalValorVentaInafecta! + valorAgrgador,
        );
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseInafecto: ticketDetailToUpdate.valorVenta!,
        );
      } else if (tipoIgv['codigoRelacionado'] == '1003') {
        ticket = ticket.copyWith(
          totalValorVentaExonerada:
              ticket.totalValorVentaExonerada! + valorAgrgador,
        );
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseExonerado: ticketDetailToUpdate.valorVenta!,
        );
      } else if (tipoIgv['codigoRelacionado'] == '1000') {
        ticket = ticket.copyWith(
          totalValorVentaExportacion:
              ticket.totalValorVentaExportacion! + valorAgrgador,
        );
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseExonerado: ticketDetailToUpdate.valorVenta!,
        );
      } else if (tipoIgv['codigoRelacionado'] == '1004') {
        if (['11', '12', '13', '14', '15', '16', '17']
            .contains(ticketDetailToUpdate.codigoTipoAfectacionIgv)) {
          ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
            porcentajeTributoVentaGratuita: igvConfig * 100,
            tributoVentaGratuita: ticketDetailToUpdate.valorVenta! * igvConfig,
          );
        } else {
          ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
            tributoVentaGratuita: 0,
            porcentajeTributoVentaGratuita: 0,
          );
        }
        ticket = ticket.copyWith(
          totalValorVentaGratuita:
              ticket.totalValorVentaGratuita! + valorAgrgador,
        );
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseGratuito: ticketDetailToUpdate.valorVenta,
          valorReferencialUnitario: ticketDetailToUpdate.precioVentaUnitario,
        );
        ticket = ticket.copyWith(
          totalTributosOperacionGratuita:
              ticket.totalTributosOperacionGratuita! +
                  (ticketDetailToUpdate.tributoVentaGratuita ?? 0),
        );
      }
      if (isc != null) {
        ticket = ticket.copyWith(
          totalValorBaseIsc:
              ticket.totalValorBaseIsc! + ticketDetailToUpdate.valorVenta!,
          totalIsc: ticket.totalIsc! + isc,
        );
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseIsc: ticketDetailToUpdate.valorVenta!,
        );
      } else {
        ticketDetailToUpdate = ticketDetailToUpdate.copyWith(
          montoBaseIsc: null,
        );
      }
      //actualizar detalle del ticket
      state = state.copyWith(
        productsSales: List.from(state.productsSales)
          ..[i] = ticketDetailToUpdate,
      );
      print('Valort unitario: ${ticketDetailToUpdate.valorUnitario}, '
          'Precio VentaUnitario Venta: ${ticketDetailToUpdate.precioVentaUnitario}, '
          'Precio Total: ${ticketDetailToUpdate.precioTotal}');
    }
    if (porcentajeDescuentoGlobal > 0) {
      final pordesGlobal = porcentajeDescuentoGlobal / 100;
      if (ticket.totalValorVentaGravada != null) {
        final descuentoGravada = ticket.totalValorVentaGravada! * pordesGlobal;
        ticket = ticket.copyWith(
          montoBaseDescuento: ticket.totalValorVentaGravada!,
          totalValorVentaGravada:
              ticket.totalValorVentaGravada! - descuentoGravada,
          totalDescuento: ticket.totalDescuento! + descuentoGravada,
          descuentoGlobal: ticket.descuentoGlobal! + descuentoGravada,
        );
      }
      if (ticket.totalValorVentaInafecta != null) {
        final descuentoInafecta =
            ticket.totalValorVentaInafecta! * pordesGlobal;
        ticket = ticket.copyWith(
          montoBaseDescuento: ticket.totalValorVentaInafecta,
          totalValorVentaInafecta:
              ticket.totalValorVentaInafecta! - descuentoInafecta,
          totalDescuento: ticket.totalDescuento! + descuentoInafecta,
          descuentoGlobal: ticket.descuentoGlobal! + descuentoInafecta,
        );
      }
      if (ticket.totalValorVentaExonerada != null) {
        final descuentoExonerada =
            ticket.totalValorVentaExonerada! * pordesGlobal;
        ticket = ticket.copyWith(
          montoBaseDescuento: ticket.totalValorVentaExonerada,
          totalValorVentaExonerada:
              ticket.totalValorVentaExonerada! - descuentoExonerada,
          totalDescuento: ticket.totalDescuento! + descuentoExonerada,
          descuentoGlobal: ticket.descuentoGlobal! + descuentoExonerada,
        );
      }
      if (ticket.totalValorBaseIgv != null) {
        ticket = ticket.copyWith(
          totalValorBaseIgv: ticket.totalValorBaseIgv! -
              (ticket.totalValorBaseIgv! * pordesGlobal),
        );
      }
      if (ticket.totalIgv != null) {
        ticket = ticket.copyWith(
          totalIgv: ticket.totalIgv! - (ticket.totalIgv! * pordesGlobal),
        );
      }
      if (ticket.totalValorBaseIsc != null) {
        ticket = ticket.copyWith(
          totalValorBaseIsc: ticket.totalValorBaseIsc! -
              (ticket.totalValorBaseIsc! * pordesGlobal),
        );
      }
      if (ticket.totalIsc != null) {
        ticket = ticket.copyWith(
          totalIsc: ticket.totalIsc! - (ticket.totalIsc! * pordesGlobal),
        );
      }
      ticket = ticket.copyWith(porcentajeDescuento: pordesGlobal);
    }
    ticket = ticket.copyWith(
      totalValorVenta: ticket.totalValorVentaGravada! +
          ticket.totalValorVentaInafecta! +
          ticket.totalValorVentaExonerada! +
          ticket.totalValorVentaExportacion!,
    );
    if (porcentajeOtrosCargos != null) {
      ticket = ticket.copyWith(
        otrosCargos: ticket.totalValorVenta! * (porcentajeOtrosCargos / 100),
      );
    }
    if (porcentajeRecargoPorItem != null) {
      ticket = ticket.copyWith(
        otrosCargos: ticket.totalValorVenta! * (porcentajeRecargoPorItem / 100),
      );
    }
    ticket = ticket.copyWith(
      totalVenta: ticket.totalValorVentaGravada! +
          ticket.totalValorVentaInafecta! +
          ticket.totalValorVentaExonerada! +
          ticket.totalValorVentaExportacion! +
          (ticket.totalIsc ?? 0)+
          (ticket.totalIgv ?? 0) +
          (ticket.totalTributosBolsas ?? 0)+
          (ticket.otrosCargos ?? 0) +
          (ticket.otrosTributos ?? 0),
    );
    if (state.flagRetencion) {
      ticket = ticket.copyWith(
        montoBaseRetencion: ticket.totalVenta!,
        porcentajeRetencion: ticket.porcentajeRetencion,
        montoRetencion: ticket.montoBaseRetencion! *
            ref.watch(sesionProvider).config!.porcentajeRetencion!,
      );
    }
    if (state.codigoTipoOperacion == '1001') {
      final montoDetraccionMonedaOrigen = ticket.totalVenta!;
      final tipoCambioDetraccion = exchange(
          Exchance(
            codigoMonedaOrigen: state.currency!.codigoMoneda!,
            codigoMonedaDestino: 'PEN',
            montoOrigen: montoDetraccionMonedaOrigen,
          ),
          state.currencies);
      ticket = ticket.copyWith(
        montoDetraccion: tipoCambioDetraccion,
      );
    }
    ref.read(ticketProvider.notifier).updateTicket(ticket);
    print('Total Venta: ${ticket.totalVenta}, '
        'Total Igv: ${ticket.totalIgv}, '
        'Total ISC: ${ticket.totalIsc}, '
        'Total Retencion: ${ticket.montoRetencion}, '
        'Total Detraction: ${ticket.montoDetraccion}'
        'Ticket: ${ticket.toJson()}, ');
  }
}
