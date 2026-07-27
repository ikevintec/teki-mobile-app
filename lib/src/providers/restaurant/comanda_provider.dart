import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailGroupOption.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailPreparationOption.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/productImage.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/repositories/inventory_repository_impl.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/domain/repositories/products_repository.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/local_products_provider.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/utils/notifications.dart';

// ---------------------------------------------------------------------------
// CartItem
// ---------------------------------------------------------------------------

class CartItem {
  static int _counter = 0;
  static String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${_counter++}';

  final String id;
  final Product product;
  final int quantity;
  final double price;
  final bool paraLlevar;
  final String? nota;
  final List<CommandDetailGroupOption> grupoOpciones;
  final List<CommandDetailPreparationOption> preparacionOpciones;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.price,
    this.paraLlevar = false,
    this.nota,
    this.grupoOpciones = const [],
    this.preparacionOpciones = const [],
  });

  factory CartItem.create({
    required Product product,
    required int quantity,
    required double price,
    bool paraLlevar = false,
    String? nota,
    List<CommandDetailGroupOption> grupoOpciones = const [],
    List<CommandDetailPreparationOption> preparacionOpciones = const [],
  }) =>
      CartItem(
        id: _generateId(),
        product: product,
        quantity: quantity,
        price: price,
        paraLlevar: paraLlevar,
        nota: nota,
        grupoOpciones: grupoOpciones,
        preparacionOpciones: preparacionOpciones,
      );

  CartItem copyWith({
    String? id,
    Product? product,
    int? quantity,
    double? price,
    bool? paraLlevar,
    String? nota,
    bool clearNota = false,
    List<CommandDetailGroupOption>? grupoOpciones,
    List<CommandDetailPreparationOption>? preparacionOpciones,
  }) =>
      CartItem(
        id: id ?? this.id,
        product: product ?? this.product,
        quantity: quantity ?? this.quantity,
        price: price ?? this.price,
        paraLlevar: paraLlevar ?? this.paraLlevar,
        nota: clearNota ? null : (nota ?? this.nota),
        grupoOpciones: grupoOpciones ?? this.grupoOpciones,
        preparacionOpciones: preparacionOpciones ?? this.preparacionOpciones,
      );

  double get extrasPrice => grupoOpciones.fold(
        0.0,
        (sum, g) => sum + (g.precio ?? 0) * ((g.cantidad ?? 1)),
      );

  double get unitTotal => price + extrasPrice;

  double get totalPrice => unitTotal * quantity;
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

final comandaProvider =
    StateNotifierProvider<ComandaNotifier, ComandaState>(
  (ref) => ComandaNotifier(
    ref: ref,
    repository: RestaurantRepositoryImpl(),
    productsRepository: ProductsRepositoryImpl(),
    inventoryRepository: InventoryRepositoryImpl(),
  ),
);

class ComandaNotifier extends StateNotifier<ComandaState> {
  final Ref ref;
  final RestaurantRepository repository;
  final ProductsRepository productsRepository;
  final InventoryRepository inventoryRepository;
  final CommandPrintService _printService = CommandPrintService();

  /// Mismo tope que el `size: 500` del endpoint que se usaba antes.
  static const _menuLimit = 500;

  /// Imágenes ya pedidas en esta sesión: reabrir el menú no repite el POST.
  final Map<int, List<ProductImage>> _imagesCache = {};

  ComandaNotifier({
    required this.ref,
    required this.repository,
    required this.productsRepository,
    required this.inventoryRepository,
  })  : super(ComandaState(
          table: null,
          existingOrderId: null,
          cartItems: [],
          searchQuery: '',
          products: [],
          categorias: [],
          selectedCategoria: null,
          isLoadingProducts: false,
          isSubmitting: false,
        ));

  // -------------------------------------------------------------------------
  // Init / load
  // -------------------------------------------------------------------------

  Future<void> init(Table? table, {int? existingOrderId}) async {
    state = ComandaState(
      table: table,
      existingOrderId: existingOrderId ?? table?.pedidoActual?.id,
      cartItems: [],
      searchQuery: '',
      products: [],
      categorias: [],
      selectedCategoria: ComandaState.kFavoritos,
      isLoadingProducts: true,
      isSubmitting: false,
    );
    if (_useLocalSearch) {
      unawaited(ref.read(localProductsProvider.notifier).ensureCacheLoaded());
    }
    await loadProducts();
  }

  bool get _useLocalSearch =>
      ref.read(sesionProvider).config?.busquedaProductosLocalmente == true;

  /// Si el cache aún no está en memoria (descargando o falló), se cae a la
  /// búsqueda online para no dejar el menú vacío.
  bool get _localProductsAvailable =>
      ref.read(localProductsProvider).allProducts.isNotEmpty;

  Future<void> loadProducts({String query = ''}) async {
    state = state.copyWith(isLoadingProducts: true);
    try {
      final products = _useLocalSearch && _localProductsAvailable
          ? await _loadLocal(query)
          : await _loadOnline(query);
      final enriched = await _enrich(products);
      final categorias = enriched
          .map((p) => p.categoria?.nombre ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      state = state.copyWith(
        products: enriched,
        categorias: categorias,
        isLoadingProducts: false,
      );
    } catch (e) {
      errorNotification(e.toString());
      state = state.copyWith(isLoadingProducts: false);
    }
  }

  /// Menú y búsqueda sobre el cache local: con query vacía devuelve el menú
  /// completo; con query usa el mismo fuzzy que la venta. En ambos casos solo
  /// productos con `mostrarEnRestaurante`.
  Future<List<Product>> _loadLocal(String query) async {
    if (query.isEmpty) {
      return ref
          .read(localProductsProvider)
          .allProducts
          .where((p) => p.mostrarEnRestaurante == true)
          .take(_menuLimit)
          .toList();
    }
    final results =
        await ref.read(localProductsProvider.notifier).searchLocal(query);
    return results.where((p) => p.mostrarEnRestaurante == true).toList();
  }

  /// Búsqueda ligera (`/products/search`) con los mismos filtros que usaba el
  /// endpoint pesado de `/products`.
  Future<List<Product>> _loadOnline(String query) {
    final params = <String, dynamic>{
      'paginacion': false,
      'limit': _menuLimit,
      'mostrarEnRestaurante': true,
    };
    if (query.isNotEmpty) params['filterGlobal'] = query;
    return productsRepository.searchProducts(params);
  }

  /// La búsqueda ligera y el cache local no traen inventario ni imágenes: se
  /// completan con los endpoints por lote, en paralelo. Ambos son best-effort:
  /// si fallan, el menú se muestra igual.
  Future<List<Product>> _enrich(List<Product> products) async {
    final ids = products.map((p) => p.id).whereType<int>().toList();
    if (ids.isEmpty) return products;

    final officeId = ref.read(sesionProvider).office?.id;
    final missingImageIds =
        ids.where((id) => !_imagesCache.containsKey(id)).toList();

    final results = await Future.wait<Object>([
      officeId == null
          ? Future.value(<int, Inventory>{})
          : inventoryRepository.getInventoryByProductIds(
              ids,
              idPuntoVenta: officeId,
            ),
      productsRepository.getImagesByProductIds(missingImageIds),
    ]);
    final inventories = results[0] as Map<int, Inventory>;
    _imagesCache.addAll(results[1] as Map<int, List<ProductImage>>);

    return products.map((p) {
      final inventory = inventories[p.id];
      final images = _imagesCache[p.id];
      if (inventory == null && images == null) return p;
      return p.copyWith(
        inventarios: inventory != null ? [inventory] : p.inventarios,
        imagenes: images ?? p.imagenes,
      );
    }).toList();
  }

  /// Detalle completo del producto (grupos, preparaciones, precios de mayoreo)
  /// antes de abrir el sheet: ni la búsqueda ligera ni el cache local traen esa
  /// data. Devuelve `null` si falla (ya notificado).
  Future<Product?> getFullProduct(Product lightProduct) async {
    final id = lightProduct.id;
    if (id == null) return lightProduct;
    try {
      final full = await productsRepository.getProductById(id);
      // Conserva inventario e imágenes ya enriquecidos si el detalle no los trae.
      return full.copyWith(
        inventarios: (full.inventarios?.isNotEmpty ?? false)
            ? full.inventarios
            : lightProduct.inventarios,
        imagenes: (full.imagenes?.isNotEmpty ?? false)
            ? full.imagenes
            : lightProduct.imagenes,
      );
    } catch (e) {
      errorNotification(e.toString());
      return null;
    }
  }

  // -------------------------------------------------------------------------
  // Price logic
  // -------------------------------------------------------------------------

  /// Returns the most applicable price for the given quantity (mayoreo logic).
  static double computePrice(Product p, int quantity) {
    final prices = p.preciosVenta ?? [];
    if (prices.isEmpty) return 0;

    final mayoreoList = prices
        .where((pp) =>
            pp.tipoPrecio == 'MAYOREO' && pp.unidadesMayoreo != null)
        .toList()
      ..sort((a, b) =>
          (b.unidadesMayoreo ?? 0).compareTo(a.unidadesMayoreo ?? 0));

    for (final mp in mayoreoList) {
      if (quantity >= (mp.unidadesMayoreo ?? 0)) {
        return mp.precio ?? 0;
      }
    }

    final defaultPrice = prices.firstWhere(
      (pp) => pp.tipoPrecio == 'POR_DEFECTO',
      orElse: () => prices.first,
    );
    return defaultPrice.precio ?? 0;
  }

  // -------------------------------------------------------------------------
  // Cart CRUD
  // -------------------------------------------------------------------------

  void addCartItem(CartItem item) {
    state = state.copyWith(cartItems: [...state.cartItems, item]);
  }

  void updateCartItem(int index, CartItem item) {
    final items = List<CartItem>.from(state.cartItems);
    items[index] = item;
    state = state.copyWith(cartItems: items);
  }

  void removeCartItem(int index) {
    final items = List<CartItem>.from(state.cartItems);
    items.removeAt(index);
    state = state.copyWith(cartItems: items);
  }

  // -------------------------------------------------------------------------
  // Filters
  // -------------------------------------------------------------------------

  void selectCategoria(String? cat) {
    state = state.copyWith(
        selectedCategoria: cat, clearCategoria: cat == null);
  }

  void selectFavoritos() {
    state = state.copyWith(
        selectedCategoria: ComandaState.kFavoritos, clearCategoria: false);
  }

  void search(String q) {
    state = state.copyWith(searchQuery: q);
  }

  List<Product> get filteredProducts {
    var products = state.products;
    if (state.selectedCategoria == ComandaState.kFavoritos) {
      products = products.where((p) => p.favorito == true).toList();
    } else if (state.selectedCategoria != null) {
      products = products
          .where((p) => p.categoria?.nombre == state.selectedCategoria)
          .toList();
    }
    return products;
  }

  // -------------------------------------------------------------------------
  // Totals
  // -------------------------------------------------------------------------

  double get totalAmount =>
      state.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

  int get totalItems =>
      state.cartItems.fold(0, (sum, item) => sum + item.quantity);

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  Future<void> submitComanda(
    Office puntoVenta, {
    ConfigCompany? config,
    int? idCompany,
  }) async {
    if (state.cartItems.isEmpty) {
      warningNotification('Agregue al menos un producto');
      return;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final details = state.cartItems.map((cartItem) => CommandDetail(
            producto: cartItem.product,
            cantidad: cartItem.quantity.toDouble(),
            precioVenta: cartItem.unitTotal,
            nota: cartItem.nota,
            paraLlevar: cartItem.paraLlevar,
            grupoProductoOpciones: cartItem.grupoOpciones,
            preparacionProductoOpciones: cartItem.preparacionOpciones,
          )).toList();

      int? commandId;
      final existingOrderId = state.existingOrderId;
      if (existingOrderId != null) {
        final savedCommand = await repository.addCommand(existingOrderId, Command(items: details));
        commandId = savedCommand.id;
      } else {
        final order = OrderRestaurant(
          mesa: state.table,
          puntoVenta: puntoVenta,
          tipo: 'LOCAL',
          comandas: [Command(items: details)],
        );
        final createdOrder = await repository.createOrder(order);
        commandId = createdOrder.comandas?.firstOrNull?.id;
      }
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false);
      successNotification('Comanda enviada exitosamente');
      Get.back();

      if (commandId != null && config?.clienteImpresion == 'COFFE') {
        _printService.processCommand(
          commandId: commandId,
          puntoVenta: puntoVenta,
          escPos: config?.imprimeTicketsEscPos ?? false,
          clientPrinter: config?.clienteImpresion,
          idCompany: idCompany,
        );
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isSubmitting: false);
      errorNotification(e.toString());
    }
  }

  // -------------------------------------------------------------------------
  // Submit – pedido sin mesa
  // -------------------------------------------------------------------------

  /// Crea la orden y retorna el [OrderRestaurant] creado por el backend.
  /// Retorna `null` si hay un error (ya notificado internamente).
  /// La navegación post-creación es responsabilidad del screen llamador.
  Future<OrderRestaurant?> submitPedidoSinMesa({
    required Office puntoVenta,
    required String tipo,
    required String nombreCliente,
    required String tipoDocumentoReceptor,
    required String numeroDocumentoReceptor,
    required String denominacionReceptor,
    required String direccionReceptor,
    required String emailReceptor,
    required String telefonoReceptor,
    String? direccionCompleta,
    double? montoDelivery,
  }) async {
    if (state.cartItems.isEmpty) {
      warningNotification('Agregue al menos un producto');
      return null;
    }
    state = state.copyWith(isSubmitting: true);
    try {
      final details = state.cartItems.map((cartItem) => CommandDetail(
            producto: cartItem.product,
            cantidad: cartItem.quantity.toDouble(),
            precioVenta: cartItem.unitTotal,
            nota: cartItem.nota,
            paraLlevar: cartItem.paraLlevar,
            grupoProductoOpciones: cartItem.grupoOpciones,
            preparacionProductoOpciones: cartItem.preparacionOpciones,
          )).toList();

      final cliente = Customer(
        razonSocial: denominacionReceptor.isNotEmpty ? denominacionReceptor : nombreCliente,
        tipoDocumento: tipoDocumentoReceptor,
        numeroDocumento: numeroDocumentoReceptor,
        direccion: direccionReceptor,
        email: emailReceptor.isNotEmpty ? emailReceptor : null,
        telefono: telefonoReceptor.isNotEmpty ? telefonoReceptor : null,
      );

      final order = OrderRestaurant(
        puntoVenta: puntoVenta,
        tipo: tipo,
        comandas: [Command(items: details)],
        nombreCliente: nombreCliente,
        tipoDocumentoReceptor: tipoDocumentoReceptor,
        numeroDocumentoReceptor: numeroDocumentoReceptor,
        denominacionReceptor: denominacionReceptor.isNotEmpty ? denominacionReceptor : nombreCliente,
        direccionReceptor: direccionReceptor,
        emailReceptor: emailReceptor.isNotEmpty ? emailReceptor : null,
        telefonoReceptor: telefonoReceptor.isNotEmpty ? telefonoReceptor : null,
        cliente: cliente,
        direccionCompleta: direccionCompleta,
        montoDelivery: montoDelivery,
      );

      final createdOrder = await repository.createOrder(order);
      if (!mounted) return null;
      state = state.copyWith(isSubmitting: false);
      return createdOrder;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(isSubmitting: false);
      errorNotification(e.toString());
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class ComandaState {
  static const String kFavoritos = '_FAVORITOS_';

  final Table? table;
  final int? existingOrderId;
  final List<CartItem> cartItems;
  final String searchQuery;
  final List<Product> products;
  final List<String> categorias;
  final String? selectedCategoria;
  final bool isLoadingProducts;
  final bool isSubmitting;

  ComandaState({
    required this.table,
    this.existingOrderId,
    required this.cartItems,
    required this.searchQuery,
    required this.products,
    required this.categorias,
    required this.selectedCategoria,
    required this.isLoadingProducts,
    required this.isSubmitting,
  });

  ComandaState copyWith({
    Table? table,
    int? existingOrderId,
    List<CartItem>? cartItems,
    String? searchQuery,
    List<Product>? products,
    List<String>? categorias,
    String? selectedCategoria,
    bool? clearCategoria,
    bool? isLoadingProducts,
    bool? isSubmitting,
  }) =>
      ComandaState(
        table: table ?? this.table,
        existingOrderId: existingOrderId ?? this.existingOrderId,
        cartItems: cartItems ?? this.cartItems,
        searchQuery: searchQuery ?? this.searchQuery,
        products: products ?? this.products,
        categorias: categorias ?? this.categorias,
        selectedCategoria: clearCategoria == true
            ? null
            : (selectedCategoria ?? this.selectedCategoria),
        isLoadingProducts: isLoadingProducts ?? this.isLoadingProducts,
        isSubmitting: isSubmitting ?? this.isSubmitting,
      );
}
