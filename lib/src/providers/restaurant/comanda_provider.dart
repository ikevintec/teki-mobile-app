import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/cutomer.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailGroupOption.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetailPreparationOption.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/restaurant_repository.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:dio/dio.dart';

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
  (ref) => ComandaNotifier(repository: RestaurantRepositoryImpl()),
);

class ComandaNotifier extends StateNotifier<ComandaState> {
  final RestaurantRepository repository;
  final Dio _dio = ApiClient.dio;
  final CommandPrintService _printService = CommandPrintService();

  ComandaNotifier({required this.repository})
      : super(ComandaState(
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
    await loadProducts();
  }

  Future<void> loadProducts({String query = ''}) async {
    state = state.copyWith(isLoadingProducts: true);
    try {
      final params = <String, dynamic>{
        'mostrarEnRestaurante': true,
        'size': 500,
      };
      if (query.isNotEmpty) params['filterGlobal'] = query;
      final response = await _dio.get('/products', queryParameters: params);
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      final products = list.map((e) => Product.fromJson(e)).toList();
      final categorias = products
          .map((p) => p.categoria?.nombre ?? '')
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
      state = state.copyWith(
        products: products,
        categorias: categorias,
        isLoadingProducts: false,
      );
    } catch (e) {
      errorNotification(e.toString());
      state = state.copyWith(isLoadingProducts: false);
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
      Get.back();
      successNotification('Comanda enviada exitosamente');

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
