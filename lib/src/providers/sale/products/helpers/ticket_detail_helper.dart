import 'package:get/get.dart';
import 'package:teki_app/src/data/models/general/exchange.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/price.dart';

TicketDetail getTicketDetail({
  required Product product,
  required SesionState sesion,
  double? quantity = 1,
  bool isQuotation = false,
}) {
  // Envase retornable: al agregar, el canje viene activo por defecto con su
  // tarifa "para canje" (paridad web). Las cotizaciones no lo manejan.
  final bool devolvioEnvase = manejaEnvaseRetornable(
    product,
    sesion,
    isQuotation: isQuotation,
  );
  final price = getAutomaticPrice(
    product,
    sesion,
    quantity ?? 1,
    conCanje: devolvioEnvase,
  );
  return TicketDetail(
    cantidad: quantity,
    montoOriginal: price,
    precioVentaUnitario: price,
    devolvioEnvase: devolvioEnvase ? true : null,
    codigoProducto: product.codigo,
    codigoUnidadMedida: product.unidad?.codigo ?? '',
    precioCompraUnitario: product.precioCompra ?? 0,
    valorUnitario: 0,
    // Paridad web: prioridad al default del punto de venta (p. ej. exonerado
    // en Amazonía), luego la afectación del producto y '10' (Gravado -
    // Operación Onerosa) como último recurso. Un '' rompería el lookup
    // del catálogo 07 en calculoTotal.
    codigoTipoAfectacionIgv:
        sesion.office?.codigoAfectacionPorDefecto ??
        product.tipoAfectacion ??
        '10',
    tieneImpuestoBolsas: product.tieneImpuestoBolsas ?? false,
    porcentajeDescuentoGlobal: 0,
    porcentajeOtrosCargos: product.tipoProducto == 'PLAN'
        ? product.porcentajeOtrosCargos
        : null,
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
  bool isQuotation = false,
}) {
  // En retornables un precio manual se conserva al cambiar la cantidad.
  if (ticketDetail.precioManual &&
      manejaEnvaseRetornable(
        ticketDetail.producto,
        sesion,
        isQuotation: isQuotation,
      )) {
    return ticketDetail.copyWith(cantidad: quantity);
  }
  final newPrice = getAutomaticPrice(
    ticketDetail.producto!,
    sesion,
    quantity,
    conCanje:
        ticketDetail.devolvioEnvase == true ||
        ticketDetail.prestamoEnvase == true,
  );
  return ticketDetail.copyWith(
    cantidad: quantity,
    precioVentaUnitario: newPrice,
    montoOriginal: newPrice,
  );
}

double exchange(Exchance model, List<Currency> currencies) {
  if (model.montoOrigen == null) {
    model.copyWith(monto: 0);
  }
  final Currency monedaOrigen = currencies.firstWhere(
    (c) => c.codigoMoneda == model.codigoMonedaOrigen && c.tipoCambio != null,
  );
  if (monedaOrigen.isNull) {
    final messageError =
        'Debe registrar el tipo de cambio para la moneda ${model.codigoMonedaDestino}';
    errorNotification(messageError);
    throw Exception(messageError);
  }
  final Currency monedaDestino = currencies.firstWhere(
    (c) => c.codigoMoneda == model.codigoMonedaDestino && c.tipoCambio != null,
  );
  if (monedaDestino.isNull) {
    final messageError =
        'Debe registrar el tipo de cambio para la moneda ${model.codigoMonedaDestino}';
    errorNotification(messageError);
    throw Exception(messageError);
  }
  final montoEnMonedaNacional =
      (model.montoOrigen ?? 1).toDouble() *
      (monedaOrigen.tipoCambio ?? 1).toDouble();
  return montoEnMonedaNacional / monedaDestino.tipoCambio!;
}

ProductsSaleState setPrice(
  ProductsSaleState state,
  int index,
  double price,
  bool incIgv,
  bool compra,
) {
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
      return setPrice(
        state,
        index,
        precioVentaUnitario / (1 + sesion.config!.igv!),
        false,
        false,
      );
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

// ─── Envases retornables (paridad con emitir-comprobante de la web) ────────

enum ModoEnvase { canje, venta, prestamo }

/// Empresa con retorno de envases y producto configurado con su envase.
bool productoConEnvase(Product? product, SesionState sesion) =>
    sesion.config?.permitirRetornoEnvase == true &&
    product?.envaseRetornable == true &&
    product?.productoEnvase?.id != null;

/// La línea muestra y envía la modalidad de envase. Nunca en cotización.
bool manejaEnvaseRetornable(
  Product? product,
  SesionState sesion, {
  required bool isQuotation,
}) => !isQuotation && productoConEnvase(product, sesion);

/// Préstamo: solo ventas directas (factura, boleta, nota de venta) con
/// inventario, fuera de cuentas de restaurante.
bool puedePrestarEnvase(
  TicketProvider sale,
  SesionState sesion,
  List<TicketDetail> lines,
) =>
    !sale.isQuotation &&
    sesion.config?.inventario == true &&
    const {'01', '03', 'NV'}.contains(sale.ticket.tipoComprobante) &&
    sale.ticket.cuentaRestaurante == null &&
    !lines.any((td) => td.comandaDetalle != null);

/// El préstamo queda a nombre de un cliente identificado, nunca el por defecto.
bool clienteRegistradoParaEnvase(Customer? cliente, SesionState sesion) {
  final predeterminado = sesion.config?.clientePorDefectoData;
  final documento = cliente?.numeroDocumento?.trim() ?? '';
  return cliente?.id != null &&
      documento.isNotEmpty &&
      cliente?.porDefecto != true &&
      !(predeterminado?.id != null && cliente?.id == predeterminado?.id) &&
      !(predeterminado?.numeroDocumento != null &&
          documento == predeterminado?.numeroDocumento);
}

/// Consultar préstamos desde la venta: mismos requisitos que el módulo.
bool puedeConsultarPrestamos(
  TicketProvider sale,
  SesionState sesion,
  Customer? cliente,
) =>
    !sale.isQuotation &&
    sesion.config?.permitirRetornoEnvase == true &&
    sesion.config?.inventario == true &&
    clienteRegistradoParaEnvase(cliente, sesion) &&
    (sesion.hasPermission('INVENTARIO_VER') ||
        sesion.hasPermission('SUPER_USUARIO'));

ModoEnvase modoEnvase(TicketDetail td) => td.prestamoEnvase == true
    ? ModoEnvase.prestamo
    : td.devolvioEnvase == true
    ? ModoEnvase.canje
    : ModoEnvase.venta;

String etiquetaModoEnvase(ModoEnvase modo) => switch (modo) {
  ModoEnvase.canje => 'Canje',
  ModoEnvase.venta => 'Venta con envase',
  ModoEnvase.prestamo => 'Préstamo',
};

String detalleModoEnvase(ModoEnvase modo) => switch (modo) {
  ModoEnvase.canje => 'El cliente entrega un envase vacío.',
  ModoEnvase.venta => 'El cliente compra también el envase.',
  ModoEnvase.prestamo => 'El cliente devolverá el envase después.',
};

String resumenEnvase(TicketDetail td) {
  final cantidad = (td.cantidad ?? 0);
  final n = cantidad == cantidad.roundToDouble()
      ? cantidad.toInt().toString()
      : cantidad.toString();
  final uno = cantidad == 1;
  return switch (modoEnvase(td)) {
    ModoEnvase.canje =>
      '${uno ? 'Ingresa' : 'Ingresan'} $n ${uno ? 'vacío' : 'vacíos'} al entregar.',
    ModoEnvase.prestamo =>
      '$n ${uno ? 'envase por devolver' : 'envases por devolver'}.',
    ModoEnvase.venta => 'El precio incluye el envase.',
  };
}

/// Tarifa automática. En productos con envase configurado: canje/préstamo usan
/// el precio "para canje" (sede y mayoreo por cantidad) y la venta con envase
/// el precio normal sin las tarifas de canje. Mismo IGV y recargo que el normal.
double getAutomaticPrice(
  Product product,
  SesionState sesion,
  double qty, {
  required bool conCanje,
}) {
  final office = sesion.office!;
  final ops = {
    'qty': qty,
    'igv': sesion.config!.igv,
    'porcentajeRecargoPorItem': sesion.config!.porcentajeRecargoPorItem,
  };
  if (!productoConEnvase(product, sesion)) {
    return getPriceProduct(product, office, ops);
  }
  final precios = product.preciosVenta ?? const <ProductPrice>[];
  if (conCanje) {
    final porPuntoVenta = product.preciosPorPuntoVenta ?? false;
    final canje = precios
        .where(
          (p) =>
              p.paraCanje == true &&
              p.precio != null &&
              (porPuntoVenta
                  ? p.puntoVenta?.id == office.id
                  : p.puntoVenta == null) &&
              (p.tipoPrecio != 'MAYOREO' || (p.unidadesMayoreo ?? 0) <= qty),
        )
        .toList();
    final mayoreo = canje.where((p) => p.tipoPrecio == 'MAYOREO').toList()
      ..sort(
        (a, b) => (b.unidadesMayoreo ?? 0).compareTo(a.unidadesMayoreo ?? 0),
      );
    final elegido = mayoreo.isNotEmpty
        ? mayoreo.first
        : canje.isNotEmpty
        ? canje.first
        : null;
    if (elegido != null) {
      return getPriceProduct(
        product.copyWith(
          preciosVenta: [elegido.copyWith(tipoPrecio: 'POR_DEFECTO')],
        ),
        office,
        ops,
      );
    }
  }
  return getPriceProduct(
    product.copyWith(
      preciosVenta: precios.where((p) => p.paraCanje != true).toList(),
    ),
    office,
    ops,
  );
}
