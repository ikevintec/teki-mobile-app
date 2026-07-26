import 'package:get/get.dart';
import 'package:teki_app/src/data/models/general/exchange.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/price.dart';

TicketDetail getTicketDetail(
    {required Product product,
    required SesionState sesion,
    double? quantity = 1}) {
  final price = getPriceProduct(product, sesion.office!, {
    'qty': quantity,
    'igv': sesion.config!.igv,
    'porcentajeRecargoPorItem': sesion.config!.porcentajeRecargoPorItem,
  });
  return TicketDetail(
    cantidad: quantity,
    montoOriginal: price,
    precioVentaUnitario: price,
    codigoProducto: product.codigo,
    codigoUnidadMedida: product.unidad?.codigo ?? '',
    precioCompraUnitario: product.precioCompra ?? 0,
    valorUnitario: 0,
    // Paridad web: prioridad al default del punto de venta (p. ej. exonerado
    // en Amazonía), luego la afectación del producto y '10' (Gravado -
    // Operación Onerosa) como último recurso. Un '' rompería el lookup
    // del catálogo 07 en calculoTotal.
    codigoTipoAfectacionIgv: sesion.office?.codigoAfectacionPorDefecto ??
        product.tipoAfectacion ??
        '10',
    tieneImpuestoBolsas: product.tieneImpuestoBolsas ?? false,
    porcentajeDescuentoGlobal: 0,
    porcentajeOtrosCargos:
    product.tipoProducto == 'PLAN' ? product.porcentajeOtrosCargos : null,
    esAnticipo: null,
    producto: product,
    despachos: [],
    descuento: 0,
    codigoDescuento: null,
    monedaOriginal: product.moneda,
    descripcion: product.nombre ?? '',
  );
}

TicketDetail changeQtyTicketDetail({
  required TicketDetail ticketDetail,
  required double quantity,
  required SesionState sesion,
}) {
  final newPrice = getPriceProduct(ticketDetail.producto!, sesion.office!, {
    'qty': quantity,
    'igv': sesion.config!.igv,
    'porcentajeRecargoPorItem': sesion.config!.porcentajeRecargoPorItem,
  });
  return ticketDetail.copyWith(
    cantidad: quantity,
    precioVentaUnitario: newPrice,
    montoOriginal: newPrice,
  );
}

double exchange(Exchance model, List<Currency> currencies) {
  if (model.montoOrigen == null) {
    model.copyWith(
      monto: 0,
    );
  }
  final Currency monedaOrigen = currencies.firstWhere((c) =>
      c.codigoMoneda == model.codigoMonedaOrigen && c.tipoCambio != null);
  if (monedaOrigen.isNull) {
    final messageError =
        'Debe registrar el tipo de cambio para la moneda ${model.codigoMonedaDestino}';
    errorNotification(messageError);
    throw Exception(messageError);
  }
  final Currency monedaDestino = currencies.firstWhere((c) =>
      c.codigoMoneda == model.codigoMonedaDestino && c.tipoCambio != null);
  if (monedaDestino.isNull) {
    final messageError =
        'Debe registrar el tipo de cambio para la moneda ${model.codigoMonedaDestino}';
    errorNotification(messageError);
    throw Exception(messageError);
  }
  final montoEnMonedaNacional = (model.montoOrigen ?? 1).toDouble() *
      (monedaOrigen.tipoCambio ?? 1).toDouble();
  return montoEnMonedaNacional / monedaDestino.tipoCambio!;
}

ProductsSaleState setPrice(ProductsSaleState state, int index, double price,
    bool incIgv, bool compra) {
  final existingTicketDetail = state.productsSales[index];
  final updatedTicketDetail = incIgv
      ? existingTicketDetail.copyWith(precioVentaUnitario: price)
      : compra
          ? existingTicketDetail.copyWith(precioCompraUnitario: price)
          : existingTicketDetail.copyWith(valorUnitario: price);
  return state.copyWith(
    productsSales: List.from(state.productsSales)
      ..[index] = updatedTicketDetail,
  );
}

ProductsSaleState setPriceExchange({
  required List<Currency> currencies,
  required Currency currency,
  required String monedaOrigen,
  required String monedaDestino,
  required double monto,
  required ProductsSaleState state,
  required int index,
  required SesionState sesion,
}) {
  final product = state.productsSales[index].producto;
  final Exchance tipoCambioRequest = Exchance(
    codigoMonedaOrigen: monedaOrigen,
    codigoMonedaDestino: monedaDestino,
    montoOrigen: monto,
  );
  final precioVentaUnitario = exchange(tipoCambioRequest, currencies);
  if (state.incIgv) {
    return setPrice(state, index, precioVentaUnitario, true, false);
  } else {
    if (product != null && !product.igv!) {
      return setPrice(state, index,
          precioVentaUnitario / (1 + sesion.config!.igv!), false, false);
    } else {
      return setPrice(state, index, precioVentaUnitario, false, false);
    }
  }
}

ProductsSaleState setPurchasePriceExchange({
  required List<Currency> currencies,
  required Currency currency,
  required String monedaOrigen,
  required String monedaDestino,
  required double? monto,
  required ProductsSaleState state,
  required int index,
  required SesionState sesion,
}) {
  final Exchance tipoCambioRequest = Exchance(
    codigoMonedaOrigen: monedaOrigen,
    codigoMonedaDestino: monedaDestino,
    montoOrigen: monto ?? 0,
  );
  final precioCompraUnitario = exchange(tipoCambioRequest, currencies);
  return setPrice(state, index, precioCompraUnitario, false, true);
}
