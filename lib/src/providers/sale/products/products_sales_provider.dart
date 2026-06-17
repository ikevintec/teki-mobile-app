import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/productPrice.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/data/repositories/currency_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/currency_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/quotation/quotation_view_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/helpers/products_sale_notifier_setters.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/price.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final productSaleProvider =
    StateNotifierProvider<ProductsSaleNotifier, ProductsSaleState>(
  (ref) {
    final ProductsRepository productsRepository = ProductsRepositoryImpl();
    final CurrencyRepository currencyRepository = CurrencyRepositoryImpl();
    return ProductsSaleNotifier(
      productsRepository: productsRepository,
      currencyRepository: currencyRepository,
      ref: ref,
    );
  },
);

class ProductsSaleNotifier extends StateNotifier<ProductsSaleState>
    with ProductsSaleNotifierSettersMixin {
  @override
  final Ref ref;
  final ProductsRepository productsRepository;
  final CurrencyRepository currencyRepository;
  ProductsSaleNotifier({
    required this.ref,
    required this.productsRepository,
    required this.currencyRepository,
  }) : super(ProductsSaleState(
          tipoComprobante:
              ref.watch(sesionProvider).config!.tipoComprobantePorDefecto ??
                  'NV', // Factura
          productsSales: [],
          currencies: [],
          incIgv: true,
          currency: null,
          isLoading: true,
          isBarcodeSearching: false,
          error: null,
          pageNumber: 0,
          paginacion: true,
          perPage: 20,
          sortField: 'id',
          sortOrder: 1,
          filterGlobal: '',
          idPuntoVenta: null,
          otrosTributos: null,
          porcentajeDescuentoGlobal: null,
          flagRetencion: false,
          porcentajeRetencion:
              ref.watch(sesionProvider).config!.porcentajeRetencion ?? 0.0,
          codigoTipoOperacion: '0101',
        ));

  Future<List<Product>> getProducts(String? filter) async {
    setFilterGlobal(filter);
    try {
      final response =
          await productsRepository.getProducts(buildProductQueryParams(state));
      if (response.content != null || response.content!.isNotEmpty) {
        return response.content!;
      }
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    state = state.copyWith(isBarcodeSearching: true);
    try {
      final params = <String, dynamic>{
        'filterGlobal': barcode,
        'perPage': 1,
        'paginacion': true,
        'pageNumber': 0,
        'sortField': 'id',
        'sortOrder': 1,
      };
      final response = await productsRepository.getProducts(params);
      if (response.content != null && response.content!.isNotEmpty) {
        return response.content!.first;
      }
      return null;
    } catch (e) {
      errorNotification(e.toString());
      return null;
    } finally {
      state = state.copyWith(isBarcodeSearching: false);
    }
  }

  void loadInitialData(int? id, {int? quotationId}) async {
    setLoading(true);
    try {
      // Cargar currencies solo si no existen o si no se está editando
      if (state.currencies.isEmpty) {
        final response = await currencyRepository.getCurrencies();
        if (response.isNotEmpty) {
          state = state.copyWith(
            currencies: response,
            currency: response[0],
          );
        }
      }

      final customerNotifier = ref.read(customerSaleProvider.notifier);
      final productsSaleNotifier = ref.read(productSaleProvider.notifier);
      final ticketSaleNotifier = ref.read(ticketProvider.notifier);

      // Cargar datos de edición de cotización
      if (quotationId != null) {
        final quotationViewNotifier = ref.read(quotationViewProvider.notifier);
        final quotation = await quotationViewNotifier.fetchQuotationById(quotationId);
        final ticketFromQuotation = quotation.toTicketForEdit();
        ticketSaleNotifier.updateTicket(ticketFromQuotation);
        customerNotifier.setCustomerEntity(ticketFromQuotation.cliente ?? Customer());
        productsSaleNotifier.setProductsSaleEntity(ticketFromQuotation.items ?? [],
            monedaOrigen: ticketFromQuotation.codigoMoneda);
        productsSaleNotifier.setIncIgv(ticketFromQuotation.incIgv ?? true);
        productsSaleNotifier.setCurrency(ticketFromQuotation.codigoMoneda ?? 'PEN');
        ticketSaleNotifier.setEdited(true);
      } else if (id != null) {
        // Cargar datos de edición de comprobante
        final comprobanteNotifier = ref.read(comprobanteProvider.notifier);
        // Cargar el comprobante por ID
        Ticket comprobante = await comprobanteNotifier.fetchComprobanteById(id);
        ticketSaleNotifier.updateTicket(comprobante);
        customerNotifier.setCustomerEntity(comprobante.cliente?? Customer());
        productsSaleNotifier.setProductsSaleEntity(comprobante.items ?? [], monedaOrigen: comprobante.codigoMoneda);
        productsSaleNotifier.setIncIgv( comprobante.incIgv ?? true);
        productsSaleNotifier.setCurrency( comprobante.codigoMoneda ?? 'PEN');

        ticketSaleNotifier.setEdited(true);
      }
    } catch (e) {
      setError(e.toString());
      errorNotification(e.toString());
    } finally {
      setLoading(false);
    }
  }

  void removeProductSale(int index) {
    if (state.productsSales[index].comandaDetalle != null) return;
    state = state.copyWith(
      productsSales: List.from(state.productsSales)..removeAt(index),
    );
    calculoTotal();
  }

  Future<void> initFromCheck(Check check) async {
    setLoading(true);
    try {
      // Reset ticket provider
      ref.read(ticketProvider.notifier).resetTicket();

      // Resolver cliente: del check o el cliente por defecto de la sesión
      final customer = check.cliente ??
          ref.read(sesionProvider).config?.clientePorDefectoData ??
          Customer();
      ref.read(customerSaleProvider.notifier).setCustomerEntity(customer);

      // Cargar divisas si están vacías
      if (state.currencies.isEmpty) {
        final response = await currencyRepository.getCurrencies();
        if (response.isNotEmpty) {
          state = state.copyWith(currencies: response, currency: response[0]);
        }
      }

      // Convertir CommandDetail → TicketDetail usando getPriceProduct (mismo método que la búsqueda de productos)
      final sesion = ref.read(sesionProvider);
      final items = <TicketDetail>[];

      for (final detail in (check.items ?? [])) {
        if (detail.estadoComandaDetalle?.toUpperCase() == 'CANCELADO') continue;
        if (detail.producto == null) continue;

        // Producto principal
        final qty = (detail.cantidad ?? 1).toDouble();
        final price = getPriceProduct(detail.producto!, sesion.office!, {
          'qty': qty,
          'igv': sesion.config!.igv,
          'porcentajeRecargoPorItem': sesion.config!.porcentajeRecargoPorItem,
        });
        items.add(TicketDetail(
          cantidad: qty,
          precioVentaUnitario: price,
          montoOriginal: price,
          valorUnitario: 0,
          descripcion: detail.producto!.nombre ?? '',
          codigoProducto: detail.producto!.codigo,
          codigoUnidadMedida: detail.producto!.unidad?.codigo ?? 'NIU',
          codigoTipoAfectacionIgv: detail.producto!.tipoAfectacion ?? '10',
          tieneImpuestoBolsas: detail.producto!.tieneImpuestoBolsas ?? false,
          esAnticipo: null,
          descuento: 0,
          producto: detail.producto,
          comandaDetalle: detail,
          monedaOriginal: detail.producto!.moneda ?? 'PEN',
          precioCompraUnitario: detail.producto!.precioCompra ?? 0,
          porcentajeOtrosCargos: detail.producto!.tipoProducto == 'PLAN'
              ? detail.producto!.porcentajeOtrosCargos
              : null,
        ));

        // Productos de grupoProductoOpciones (también bloqueados como items del check)
        for (final option in (detail.grupoProductoOpciones ?? [])) {
          if (option.producto == null) continue;
          if ((option.precio ?? 0) <= 0) continue;

          final optQty = (option.cantidad ?? 1).toDouble();

          // Si option.precio tiene un valor, lo inyectamos como precio base
          // en una copia del producto para que getPriceProduct aplique
          // correctamente IGV, recargo y otrosCargos sin alterar el método.
          final productForPricing = (option.precio ?? 0) > 0
              ? _productWithOverridePrice(option.producto!, option.precio!, sesion.office!.id)
              : option.producto!;

          double optPrice = getPriceProduct(productForPricing, sesion.office!, {
            'qty': optQty,
            'igv': sesion.config!.igv,
            'porcentajeRecargoPorItem': sesion.config!.porcentajeRecargoPorItem,
          });

          // Fallback: si aún es 0 (producto sin preciosVenta) usar option.precio directo
          if (optPrice == 0 && (option.precio ?? 0) > 0) {
            optPrice = option.precio!.toDouble();
          }

          items.add(TicketDetail(
            cantidad: optQty,
            precioVentaUnitario: optPrice,
            montoOriginal: optPrice,
            valorUnitario: 0,
            descripcion: option.producto!.nombre ?? option.nombreOpcion ?? '',
            codigoProducto: option.producto!.codigo,
            codigoUnidadMedida: option.producto!.unidad?.codigo ?? 'NIU',
            codigoTipoAfectacionIgv: option.producto!.tipoAfectacion ?? '10',
            tieneImpuestoBolsas: option.producto!.tieneImpuestoBolsas ?? false,
            esAnticipo: null,
            descuento: 0,
            producto: option.producto,
            comandaDetalle: detail, // heredar del padre para bloqueo
            monedaOriginal: option.producto!.moneda ?? 'PEN',
            precioCompraUnitario: option.producto!.precioCompra ?? 0,
          ));
        }
      }

      // Agregar servicio delivery como ítem si aplica
      final montoDelivery = check.pedido?.montoDelivery;
      if (montoDelivery != null && montoDelivery > 0) {
        items.add(TicketDetail(
          cantidad: 1.0,
          precioVentaUnitario: montoDelivery,
          montoOriginal: montoDelivery,
          valorUnitario: 0,
          descripcion: 'Servicio delivery',
          codigoUnidadMedida: 'ZZ',
          codigoTipoAfectacionIgv: '10',
          tieneImpuestoBolsas: false,
          esAnticipo: null,
          descuento: 0,
          producto: null,
          comandaDetalle: null,
          monedaOriginal: 'PEN',
          precioCompraUnitario: 0,
        ));
      }

      setProductsSaleEntity(items, monedaOrigen: 'PEN');

      // Vincular la cuenta y pedido de restaurante al ticket
      final ticketNotifier = ref.read(ticketProvider.notifier);
      ticketNotifier.updateTicket(
        ref.read(ticketProvider).ticket.copyWith(
          cuentaRestaurante: check.id,
          pedidoRestaurante: check.pedido,
        ),
      );
    } catch (e) {
      setError(e.toString());
    } finally {
      setLoading(false);
    }
  }

}

/// Devuelve una copia del [product] con un [preciosVenta] sintético que
/// usa [overridePrice] como precio base en lugar del precio original.
/// Esto permite que [getPriceProduct] aplique IGV, recargo y otrosCargos
/// normalmente sin modificar ese método.
Product _productWithOverridePrice(Product product, double overridePrice, int? officeId) {
  // Preservar el puntoVenta del primer precio existente (si aplica por PV)
  // para que el filtro interno de getPriceProduct lo encuentre.
  final usaPorPuntoVenta = product.preciosPorPuntoVenta == true;
  final existingPv = usaPorPuntoVenta
      ? (product.preciosVenta ?? [])
          .where((p) => p.puntoVenta?.id == officeId)
          .map((p) => p.puntoVenta)
          .firstOrNull
      : null;

  final syntheticPrice = ProductPrice(
    precio: overridePrice,
    tipoPrecio: 'POR_DEFECTO',
    puntoVenta: usaPorPuntoVenta ? existingPv : null,
  );

  return product.copyWith(preciosVenta: [syntheticPrice]);
}

class ProductsSaleState {
  final List<TicketDetail> productsSales;
  final List<Currency> currencies;
  final Currency? currency;
  final bool isLoading;
  final bool isBarcodeSearching;
  final String? error;
  // Parámetros de configuración
  final bool incIgv;
  final String tipoComprobante;
  final double? porcentajeDescuentoGlobal;
  final double? otrosTributos;
  final bool flagRetencion;
  final double porcentajeRetencion;
  final String codigoTipoOperacion;
  // Parámetros de búsqueda
  final int? pageNumber;
  final bool? paginacion;
  final int? perPage;
  final String? sortField;
  final int? sortOrder;
  final String? filterGlobal;
  final int? idPuntoVenta;

  ProductsSaleState({
    required this.productsSales,
    required this.currencies,
    required this.currency,
    required this.isLoading,
    required this.isBarcodeSearching,
    required this.error,
    required this.pageNumber,
    required this.paginacion,
    required this.perPage,
    required this.sortField,
    required this.sortOrder,
    required this.filterGlobal,
    required this.idPuntoVenta,
    required this.incIgv,
    required this.tipoComprobante,
    required this.otrosTributos,
    required this.porcentajeDescuentoGlobal,
    required this.flagRetencion,
    required this.porcentajeRetencion,
    required this.codigoTipoOperacion,
  });

  ProductsSaleState copyWith({
    List<TicketDetail>? productsSales,
    List<Currency>? currencies,
    Currency? currency,
    bool? isLoading,
    bool? isBarcodeSearching,
    String? error,
    //configuración
    bool? incIgv,
    String? tipoComprobante,
    double? otrosTributos,
    double? porcentajeDescuentoGlobal,
    bool? flagRetencion,
    double? porcentajeRetencion,
    String? codigoTipoOperacion,
    // búsqueda
    int? pageNumber,
    bool? paginacion,
    int? perPage,
    String? sortField,
    int? sortOrder,
    String? filterGlobal,
    int? idPuntoVenta,
  }) {
    return ProductsSaleState(
      productsSales: productsSales ?? this.productsSales,
      currencies: currencies ?? this.currencies,
      currency: currency ?? this.currency,
      isLoading: isLoading ?? this.isLoading,
      isBarcodeSearching: isBarcodeSearching ?? this.isBarcodeSearching,
      error: error ?? this.error,
      pageNumber: pageNumber ?? this.pageNumber,
      paginacion: paginacion ?? this.paginacion,
      perPage: perPage ?? this.perPage,
      sortField: sortField ?? this.sortField,
      sortOrder: sortOrder ?? this.sortOrder,
      filterGlobal: filterGlobal ?? this.filterGlobal,
      idPuntoVenta: idPuntoVenta ?? this.idPuntoVenta,
      incIgv: incIgv ?? this.incIgv,
      tipoComprobante: tipoComprobante ?? this.tipoComprobante,
      otrosTributos: otrosTributos ?? this.otrosTributos,
      porcentajeDescuentoGlobal:
      porcentajeDescuentoGlobal ?? this.porcentajeDescuentoGlobal,
      flagRetencion: flagRetencion ?? this.flagRetencion,
      porcentajeRetencion: porcentajeRetencion ?? this.porcentajeRetencion,
      codigoTipoOperacion: codigoTipoOperacion ?? this.codigoTipoOperacion,
    );
  }
}
