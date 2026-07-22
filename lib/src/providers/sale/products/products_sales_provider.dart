import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_group_option.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/data/repositories/currency_repository_impl.dart';
import 'package:teki_app/src/data/repositories/inventory_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/currency_repository.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/quotation/quotation_view_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/helpers/products_sale_notifier_setters.dart';
import 'package:teki_app/src/providers/sale/products/local_products_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/price.dart';
import 'package:teki_app/src/utils/query_params_builders.dart';

final productSaleProvider =
    StateNotifierProvider<ProductsSaleNotifier, ProductsSaleState>((ref) {
      final ProductsRepository productsRepository = ProductsRepositoryImpl();
      final CurrencyRepository currencyRepository = CurrencyRepositoryImpl();
      final InventoryRepository inventoryRepository = InventoryRepositoryImpl();
      return ProductsSaleNotifier(
        productsRepository: productsRepository,
        currencyRepository: currencyRepository,
        inventoryRepository: inventoryRepository,
        ref: ref,
      );
    });

class ProductsSaleNotifier extends StateNotifier<ProductsSaleState>
    with ProductsSaleNotifierSettersMixin {
  @override
  final Ref ref;
  final ProductsRepository productsRepository;
  final CurrencyRepository currencyRepository;
  final InventoryRepository inventoryRepository;
  ProductsSaleNotifier({
    required this.ref,
    required this.productsRepository,
    required this.currencyRepository,
    required this.inventoryRepository,
  }) : super(
         ProductsSaleState(
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
         ),
       );

  /// Búsqueda ligera para la barra de búsqueda (endpoint `/products/search`).
  /// Devuelve solo la data mínima del producto para listar las coincidencias.
  /// El detalle completo se trae al seleccionar con [selectProductForSale].
  ///
  /// La búsqueda ligera no incluye inventario, así que se enriquece con
  /// [_enrichWithInventory] antes de devolver los resultados. Como este método
  /// se invoca desde la barra de búsqueda con debounce, la carga de inventario
  /// solo ocurre cuando el usuario deja de escribir.
  Future<List<Product>> searchProducts(String? filter) async {
    setFilterGlobal(filter);
    final officeId = ref.read(sesionProvider).office?.id;
    try {
      final List<Product> products;
      // Solo usamos la búsqueda local si está activo el flag Y ya hay productos
      // disponibles en memoria/cache. Si el JSON aún no se descargó o falló,
      // caemos a la búsqueda online para siempre buscar con lo disponible.
      if (_useLocalSearch && _localProductsAvailable) {
        products =
            await ref.read(localProductsProvider.notifier).searchLocal(filter ?? '');
      } else {
        params['contextoVentas'] = true;
        final params = buildProductSearchQueryParams(state);
        if (officeId != null) params['idPuntoVentaOrder'] = officeId;
        products = await productsRepository.searchProducts(params);
      }
      return await _enrichWithInventory(products, officeId);
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  /// Indica si la búsqueda de productos debe resolverse localmente (fuzzy sobre
  /// el cache) según el flag de configuración de la sesión.
  bool get _useLocalSearch =>
      ref.read(sesionProvider).config?.busquedaProductosLocalmente == true;

  /// Indica si ya hay productos cargados en memoria para la búsqueda local.
  /// Si no los hay (aún descargando o falló), se hace fallback a la búsqueda
  /// online para no dejar al usuario sin resultados.
  bool get _localProductsAvailable =>
      ref.read(localProductsProvider).allProducts.isNotEmpty;

  /// Precarga los productos planos en memoria/cache para la búsqueda local.
  /// Es no bloqueante: solo hace trabajo la primera vez y no afecta la carga
  /// inicial de la pantalla de venta.
  /// Desde esta ruta solo se lee cache; el endpoint `/products/flat` se dispara
  /// desde login/checkAuthStatus.
  void ensureLocalProductsLoaded() {
    if (!_useLocalSearch) return;
    unawaited(ref.read(localProductsProvider.notifier).ensureCacheLoaded());
  }

  /// Enriquece productos de la búsqueda ligera con su inventario en el punto de
  /// venta actual (endpoint `/inventory/operations/by-product-ids`). Si falla o
  /// no hay punto de venta, devuelve los productos sin modificar.
  Future<List<Product>> _enrichWithInventory(
    List<Product> products,
    int? officeId,
  ) async {
    if (products.isEmpty || officeId == null) return products;
    final ids = products.map((p) => p.id).whereType<int>().toList();
    if (ids.isEmpty) return products;

    final inventoryByProduct =
        await inventoryRepository.getInventoryByProductIds(
      ids,
      idPuntoVenta: officeId,
    );
    if (inventoryByProduct.isEmpty) return products;

    return products.map((p) {
      final inventory = inventoryByProduct[p.id];
      if (inventory == null) return p;
      return p.copyWith(inventarios: [inventory]);
    }).toList();
  }

  /// Búsqueda ligera por código de barras. Usa el mismo endpoint
  /// (`/products/search`) que la barra de búsqueda y devuelve la primera
  /// coincidencia. El detalle completo se trae al seleccionar.
  Future<Product?> getProductByBarcode(String barcode) async {
    state = state.copyWith(isBarcodeSearching: true);
    try {
      if (_useLocalSearch && _localProductsAvailable) {
        final localProduct =
            ref.read(localProductsProvider.notifier).findByBarcode(barcode);
        if (localProduct != null) return localProduct;
      }

      final params = buildProductSearchQueryParams(state);
      params['contextoVentas'] = true;
      params['filterGlobal'] = barcode;
      params['limit'] = 1;
      final officeId = ref.read(sesionProvider).office?.id;
      if (officeId != null) params['idPuntoVentaOrder'] = officeId;
      final results = await productsRepository.searchProducts(params);
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      errorNotification(e.toString());
      return null;
    } finally {
      state = state.copyWith(isBarcodeSearching: false);
    }
  }

  /// Trae el detalle completo del producto seleccionado (`/products/{id}`) y
  /// lo agrega a la venta. Se usa tanto al tocar un resultado de la búsqueda
  /// como al escanear un código de barras: la búsqueda solo trae data ligera,
  /// así que recién aquí se obtiene la información completa del producto.
  Future<void> selectProductForSale(Product lightProduct) async {
    final id = lightProduct.id;
    if (id == null) return;
    try {
      final fullProduct = await productsRepository.getProductById(id);
      setProductsSales(fullProduct, null);
    } catch (e) {
      errorNotification(e.toString());
    }
  }

  void loadInitialData(
    int? id, {
    int? quotationId,
    int? quotationIdForSale,
  }) async {
    setLoading(true);
    try {
      // Cargar currencies solo si no existen o si no se está editando
      if (state.currencies.isEmpty) {
        final response = await currencyRepository.getCurrencies();
        if (response.isNotEmpty) {
          state = state.copyWith(currencies: response, currency: response[0]);
        }
      }

      final customerNotifier = ref.read(customerSaleProvider.notifier);
      final productsSaleNotifier = ref.read(productSaleProvider.notifier);
      final ticketSaleNotifier = ref.read(ticketProvider.notifier);

      // Generar una venta nueva a partir de una cotización (no es edición)
      if (quotationIdForSale != null) {
        final quotationViewNotifier = ref.read(quotationViewProvider.notifier);
        final quotation = await quotationViewNotifier.fetchQuotationById(
          quotationIdForSale,
        );
        final ticketFromQuotation = quotation.toTicketForSale();
        ticketSaleNotifier.updateTicket(ticketFromQuotation);
        customerNotifier.setCustomerEntity(
          ticketFromQuotation.cliente ?? Customer(),
        );
        productsSaleNotifier.setProductsSaleEntity(
          ticketFromQuotation.items ?? [],
          monedaOrigen: ticketFromQuotation.codigoMoneda,
        );
        productsSaleNotifier.setIncIgv(ticketFromQuotation.incIgv ?? true);
        productsSaleNotifier.setCurrency(
          ticketFromQuotation.codigoMoneda ?? 'PEN',
        );
        ticketSaleNotifier.setEdited(false);
      } else if (quotationId != null) {
        // Cargar datos de edición de cotización
        final quotationViewNotifier = ref.read(quotationViewProvider.notifier);
        final quotation = await quotationViewNotifier.fetchQuotationById(
          quotationId,
        );
        final ticketFromQuotation = quotation.toTicketForEdit();
        ticketSaleNotifier.updateTicket(ticketFromQuotation);
        customerNotifier.setCustomerEntity(
          ticketFromQuotation.cliente ?? Customer(),
        );
        productsSaleNotifier.setProductsSaleEntity(
          ticketFromQuotation.items ?? [],
          monedaOrigen: ticketFromQuotation.codigoMoneda,
        );
        productsSaleNotifier.setIncIgv(ticketFromQuotation.incIgv ?? true);
        productsSaleNotifier.setCurrency(
          ticketFromQuotation.codigoMoneda ?? 'PEN',
        );
        ticketSaleNotifier.setEdited(true);
      } else if (id != null) {
        // Cargar datos de edición de comprobante
        final comprobanteNotifier = ref.read(comprobanteProvider.notifier);
        // Cargar el comprobante por ID
        Ticket comprobante = await comprobanteNotifier.fetchComprobanteById(id);
        ticketSaleNotifier.updateTicket(comprobante);
        customerNotifier.setCustomerEntity(comprobante.cliente ?? Customer());
        productsSaleNotifier.setProductsSaleEntity(
          comprobante.items ?? [],
          monedaOrigen: comprobante.codigoMoneda,
        );
        productsSaleNotifier.setIncIgv(comprobante.incIgv ?? true);
        productsSaleNotifier.setCurrency(comprobante.codigoMoneda ?? 'PEN');

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
      final customer =
          check.cliente ??
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
        // Paridad con la web: el precio base sale del precioVenta PERSISTIDO
        // en la comanda menos sus adicionales (respeta precios editados por
        // el mozo); solo si no hay persistido se cae al catálogo.
        final baseUnit = persistedBaseUnitPrice(detail);
        final mainProductForPricing = baseUnit != null
            ? _productWithOverridePrice(
                detail.producto!,
                baseUnit,
                sesion.office!.id,
              )
            : detail.producto!;
        final price = getPriceProduct(mainProductForPricing, sesion.office!, {
          'qty': qty,
          'igv': sesion.config!.igv,
          'porcentajeRecargoPorItem': sesion.config!.porcentajeRecargoPorItem,
        });
        items.add(
          TicketDetail(
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
          ),
        );

        // Productos de grupoProductoOpciones (también bloqueados como items del check)
        for (final option in (detail.grupoProductoOpciones ?? [])) {
          if (option.producto == null) continue;
          if (option.eliminado == true) continue;
          if ((option.precio ?? 0) <= 0) continue;

          // Regla web: la cantidad del adicional se multiplica por la
          // cantidad del item (3 combos con 1 gaseosa c/u → 3 gaseosas).
          final optQty = optionLineQuantity(detail, option);

          // Si option.precio tiene un valor, lo inyectamos como precio base
          // en una copia del producto para que getPriceProduct aplique
          // correctamente IGV, recargo y otrosCargos sin alterar el método.
          final productForPricing = (option.precio ?? 0) > 0
              ? _productWithOverridePrice(
                  option.producto!,
                  option.precio!,
                  sesion.office!.id,
                )
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

          items.add(
            TicketDetail(
              cantidad: optQty,
              precioVentaUnitario: optPrice,
              montoOriginal: optPrice,
              valorUnitario: 0,
              descripcion: option.producto!.nombre ?? option.nombreOpcion ?? '',
              codigoProducto: option.producto!.codigo,
              codigoUnidadMedida: option.producto!.unidad?.codigo ?? 'NIU',
              codigoTipoAfectacionIgv: option.producto!.tipoAfectacion ?? '10',
              tieneImpuestoBolsas:
                  option.producto!.tieneImpuestoBolsas ?? false,
              esAnticipo: null,
              descuento: 0,
              producto: option.producto,
              comandaDetalle: detail, // heredar del padre para bloqueo
              monedaOriginal: option.producto!.moneda ?? 'PEN',
              precioCompraUnitario: option.producto!.precioCompra ?? 0,
            ),
          );
        }
      }

      // Agregar servicio delivery como ítem si aplica
      final montoDelivery = check.pedido?.montoDelivery;
      if (montoDelivery != null && montoDelivery > 0) {
        items.add(
          TicketDetail(
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
          ),
        );
      }

      setProductsSaleEntity(items, monedaOrigen: 'PEN');

      // Vincular la cuenta y pedido de restaurante al ticket
      final ticketNotifier = ref.read(ticketProvider.notifier);
      ticketNotifier.updateTicket(
        ref
            .read(ticketProvider)
            .ticket
            .copyWith(
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

/// Cantidad de la línea de un adicional al emitir el comprobante:
/// cantidad de la opción × cantidad del item. Misma regla que la web
/// (emitir-comprobante: gpo.cantidad * item.cantidad).
double optionLineQuantity(CommandDetail detail, CommandDetailGroupOption option) =>
    ((option.cantidad ?? 1) * (detail.cantidad ?? 1)).toDouble();

/// Precio unitario base del item de comanda para el comprobante: el
/// precioVenta persistido (que incluye adicionales) menos sus adicionales
/// vigentes — misma regla que la web. Devuelve null si no hay precio
/// persistido utilizable (el caller cae al precio de catálogo).
double? persistedBaseUnitPrice(CommandDetail detail) {
  final persistido = detail.precioVenta;
  if (persistido == null || persistido <= 0) return null;
  final extras = (detail.grupoProductoOpciones ?? [])
      .where((g) => g.eliminado != true)
      .fold<double>(0.0, (s, g) => s + ((g.precio ?? 0) * (g.cantidad ?? 1)));
  final base = persistido - extras;
  return base > 0 ? base : null;
}

/// Devuelve una copia del [product] con un [preciosVenta] sintético que
/// usa [overridePrice] como precio base en lugar del precio original.
/// Esto permite que [getPriceProduct] aplique IGV, recargo y otrosCargos
/// normalmente sin modificar ese método.
Product _productWithOverridePrice(
  Product product,
  double overridePrice,
  int? officeId,
) {
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
