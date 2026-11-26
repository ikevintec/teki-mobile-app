import 'package:teki_app/src/providers/restaurant/direct_checkout/cart_quote_provider.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'dart:async';

import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/direct_order_checkout_screen.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/printer/ble_printer.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/direct_checkout_printing.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/cart_bottom_sheet.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail_sheet.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_menu_card.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/cobrador_provider.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class ComandaScreen extends ConsumerStatefulWidget {
  final Table? table;
  final int? existingOrderId;
  final bool isPedidoSinMesa;

  const ComandaScreen({
    super.key,
    this.table,
    this.existingOrderId,
    this.isPedidoSinMesa = false,
  });

  @override
  ConsumerState<ComandaScreen> createState() => _ComandaScreenState();
}

class _ComandaScreenState extends ConsumerState<ComandaScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;

  /// Producto cuyo detalle completo se está trayendo tras el tap; bloquea
  /// nuevos taps y muestra el spinner en su card.
  int? _openingProductId;
  bool _openingCheckout = false;
  bool _hasPendingCheckout = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() async {
      if (!mounted) return;
      ref
          .read(comandaProvider.notifier)
          .init(widget.table, existingOrderId: widget.existingOrderId);
      if (widget.isPedidoSinMesa) {
        final s = ref.read(sesionProvider);
        final scope =
            '${s.companySelected?.id ?? s.company?.id}:${s.login.user?.id}:${s.office?.id}:${s.saleStation?.id}';
        try {
          final pending = await ref
              .read(directCheckoutServiceProvider)
              .pending(scope);
          if (mounted) setState(() => _hasPendingCheckout = pending != null);
        } catch (_) {
          /* The checkout itself reports recovery/storage errors. */
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    ref.read(comandaProvider.notifier).search(value);
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      ref.read(comandaProvider.notifier).loadProducts(query: value);
    });
    setState(() {});
  }

  List<Widget> _productSection(List<Product> products, {String? title}) {
    final session = ref.read(sesionProvider);
    return [
      if (title != null)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.all(12),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.70,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          delegate: SliverChildBuilderDelegate((_, index) {
            final product = products[index];
            return ProductMenuCard(
              product: product,
              displayPrice: ComandaNotifier.computePrice(
                product,
                1,
                office: session.office,
                config: session.config,
              ),
              isLoading: _openingProductId == product.id,
              onTap: () => _openProduct(product),
            );
          }, childCount: products.length),
        ),
      ),
    ];
  }

  Future<void> _reloadProducts() async {
    await ref
        .read(comandaProvider.notifier)
        .loadProducts(query: _searchController.text);
  }

  /// La lista es data ligera: al tocar se trae el detalle completo (grupos,
  /// preparaciones, mayoreo) y recién ahí se abre el sheet.
  Future<void> _openProduct(Product product) async {
    if (_openingProductId != null) return;
    setState(() => _openingProductId = product.id);
    final fullProduct = await ref
        .read(comandaProvider.notifier)
        .getFullProduct(product);
    if (!mounted) return;
    setState(() => _openingProductId = null);
    if (fullProduct == null) return;

    showProductDetailSheet(
      context,
      product: fullProduct,
      onConfirm: (item, _) {
        ref.read(comandaProvider.notifier).addCartItem(item);
      },
    );
  }

  // -------------------------------------------------------------------------
  // Cart sheet
  // -------------------------------------------------------------------------

  void _openCartSheet() {
    final notifier = ref.read(comandaProvider.notifier);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CartBottomSheet(
        parentContext: context,
        onConfirm: (item, index) {
          if (index != null) {
            notifier.updateCartItem(index, item);
          }
        },
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Submit – pedido sin mesa
  // -------------------------------------------------------------------------

  Future<void> _handlePedidoSinMesa() async {
    if (_openingCheckout) return;
    final session = ref.read(sesionProvider);
    if (session.office?.id == null || session.saleStation?.id == null) {
      warningNotification('Seleccione una sede y estación válidas.');
      return;
    }
    final cart = ref.read(comandaProvider).cartItems;
    if (cart.isEmpty && !_hasPendingCheckout) return;
    setState(() => _openingCheckout = true);
    final order = directOrderFromCart(cart, session.office);
    final cartQuote = ref.read(restaurantCartQuoteProvider);
    final initialQuote = cartQuote.isLoading || cartQuote.hasError
        ? null
        : cartQuote.valueOrNull;
    final result = await Navigator.of(context).push<DirectCheckoutResult>(
      MaterialPageRoute(
        builder: (_) =>
            DirectOrderCheckoutScreen(order: order, initialQuote: initialQuote),
      ),
    );
    if (!mounted) return;
    if (result == null) {
      final scope =
          '${session.companySelected?.id ?? session.company?.id}:${session.login.user?.id}:${session.office?.id}:${session.saleStation?.id}';
      try {
        final pending = await ref
            .read(directCheckoutServiceProvider)
            .pending(scope);
        if (mounted) setState(() => _hasPendingCheckout = pending != null);
      } catch (_) {
        // The checkout reports a storage failure before allowing another POST.
      }
      if (mounted) setState(() => _openingCheckout = false);
      return;
    }
    final ble = ref.read(blePrinterProvider).savedPrinter;
    final printerService = ref.read(printerServiceProvider);
    final printing = DirectCheckoutPrinting();
    if (session.config != null) {
      unawaited(
        printing
            .process(
              result,
              claimPrinting: () => ref
                  .read(directCheckoutServiceProvider)
                  .claimPrinting(
                    '${session.companySelected?.id ?? session.company?.id}:${session.login.user?.id}:${session.office?.id}:${session.saleStation?.id}',
                    result.checkoutData['operationId'] as String,
                  ),
              config: session.config!,
              office: session.office!,
              station: session.saleStation!,
              company: session.companySelected?.id ?? session.company?.id,
              printBle: ble == null
                  ? null
                  : (ticket) => ComprobantePrintService().autoprintBle(
                      ticketId: ticket.id!,
                      printerService: printerService,
                      blePrinter: ble,
                      config: session.config!,
                    ),
            )
            .then((warnings) {
              for (final warning in warnings) {
                warningNotification(warning);
              }
            }),
      );
    }
    if (result.action == 'EDIT') {
      try {
        final fullCheck = await ref
            .read(cobradorProvider.notifier)
            .getCheckById(result.check.id!);
        if (!mounted) return;
        await ref
            .read(productSaleProvider.notifier)
            .initFromCheck(
              fullCheck,
              excluirIgv:
                  result.checkoutData['excluirIgv'] == true &&
                  result.checkoutData['tipoComprobante'] == 'NV',
            );
        if (!mounted) return;
        // Keep the selected receipt type/series when handing over to the full editor.
        ref
            .read(ticketProvider.notifier)
            .setTipoComprobante(
              result.checkoutData['tipoComprobante'] ??
                  session.config?.tipoComprobantePorDefecto ??
                  'NV',
            );
        final agreed = result.checkoutData;
        final ticketNotifier = ref.read(ticketProvider.notifier);
        ticketNotifier.updateTicket(
          ref
              .read(ticketProvider)
              .ticket
              .copyWith(
                serie: agreed['serie'],
                propina: (agreed['propina'] as num?)?.toDouble(),
                mozoResponsable: agreed['idMozo'] == null
                    ? null
                    : User(
                        id: agreed['idMozo'],
                        nombreCompleto: agreed['nombreMozo'],
                      ),
                pagosPropina: (agreed['pagosPropina'] as List?)
                    ?.map((p) => PaymentDetail.fromJson(p))
                    .toList(),
                movimientoCaja: CashRegisterDetail(
                  pagos: (agreed['pagos'] as List?)
                      ?.map((p) => PaymentDetail.fromJson(p))
                      .toList(),
                ),
              ),
        );
        Get.offUntil(
          GetPageRoute(
            page: () => const ProductsSaleScreen(),
            routeName: '/products_sale_from_pedido',
          ),
          (route) => route.settings.name == AppRoutes.ordersRestaurant,
        );
      } catch (_) {
        Get.until((route) => route.settings.name == AppRoutes.ordersRestaurant);
        warningNotification(
          'Pedido guardado. Puede abrir la cuenta desde la lista.',
        );
      }
      return;
    }
    // The list is underneath the receipt; closing it leaves the saved order visible.
    ref.read(ordersRestaurantProvider.notifier).updateEstadoPago('TODOS');
    Get.until((route) => route.settings.name == AppRoutes.ordersRestaurant);
    if (result.action == 'INVOICE') {
      final ticket = result.check.comprobante!;
      Get.to(
        () => PdfViewerScreen(
          uuid: ticket.uuid,
          fileName: ticket.identificadorDocumento ?? '',
          fileSize: session.config?.tipoImpresion ?? 'A4',
          ticketId: ticket.id,
          onNewOrder: () {
            Get.back();
            Get.to(() => const ComandaScreen(isPedidoSinMesa: true));
          },
        ),
      );
    } else {
      successNotification('Borrador guardado');
    }
  }

  // -------------------------------------------------------------------------
  // Submit – comanda con mesa
  // -------------------------------------------------------------------------

  Future<void> _submit() async {
    final office = ref.read(sesionProvider).office;
    if (office == null) {
      warningNotification('No hay punto de venta seleccionado');
      return;
    }

    final notifier = ref.read(comandaProvider.notifier);
    if (notifier.totalItems == 0 && !_hasPendingCheckout) {
      warningNotification('La canasta está vacía');
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: const BoxDecoration(
                color: ColorSchema.primaryColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Confirmar Comanda',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx, false),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: ColorSchema.primaryColor.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se enviará una comanda con ${notifier.totalItems} item(s) por un total de S/ ${notifier.totalAmount.toStringAsFixed(2)}.',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(dialogCtx, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey.shade700,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogCtx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorSchema.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirmar',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final sesion = ref.read(sesionProvider);
    await notifier.submitComanda(
      office,
      config: sesion.config,
      idCompany: sesion.company?.id,
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(comandaProvider);
    final notifier = ref.read(comandaProvider.notifier);
    final filtered = notifier.filteredProducts;
    final totalItems = state.cartItems.length;
    if (widget.isPedidoSinMesa) ref.watch(restaurantCartQuoteProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isPedidoSinMesa
                  ? 'Pedido (sin mesa)'
                  : 'Mesa ${widget.table?.numero ?? widget.table?.id ?? ''}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (!widget.isPedidoSinMesa && widget.table?.salon?.nombre != null)
              Text(
                widget.table!.salon!.nombre!,
                style: const TextStyle(fontSize: 11, color: Colors.white70),
              ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          // Search + categories header (primary colored)
          Container(
            color: ColorSchema.primaryColor,
            child: Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar productos...',
                      hintStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.black38,
                      ),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Colors.black38,
                        size: 20,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: Colors.black38,
                              ),
                              onPressed: () {
                                _debounce?.cancel();
                                _searchController.clear();
                                ref.read(comandaProvider.notifier).search('');
                                setState(() {});
                                ref
                                    .read(comandaProvider.notifier)
                                    .loadProducts();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                // Chips: Favoritos → Todas → categorías
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    children: [
                      _CategoryChip(
                        label: 'Favoritos',
                        icon: Icons.star_rounded,
                        selected:
                            state.selectedCategoria == ComandaState.kFavoritos,
                        onTap: () {
                          _debounce?.cancel();
                          final hadQuery = _searchController.text.isNotEmpty;
                          _searchController.clear();
                          if (hadQuery) notifier.search('');
                          notifier.selectFavoritos();
                          if (hadQuery) notifier.loadProducts();
                        },
                      ),
                      _CategoryChip(
                        label: 'Todas',
                        selected: state.selectedCategoria == null,
                        onTap: () => notifier.selectCategoria(null),
                      ),
                      ...state.categorias.map(
                        (cat) => _CategoryChip(
                          label: cat,
                          selected: state.selectedCategoria == cat,
                          onTap: () => notifier.selectCategoria(cat),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Product grid
          Expanded(
            child: RefreshIndicator(
              color: ColorSchema.primaryColor,
              onRefresh: _reloadProducts,
              child: state.isLoadingProducts
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: ColorSchema.primaryColor,
                      ),
                    )
                  : filtered.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.2,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 52,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'No hay productos',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        if (state.selectedCategoria ==
                                ComandaState.kFavoritos &&
                            state.searchQuery.trim().isEmpty) ...[
                          if (notifier.favoriteProducts.isNotEmpty)
                            ..._productSection(
                              notifier.favoriteProducts,
                              title: 'Favoritos',
                            ),
                          if (notifier.topSellingProducts.isNotEmpty)
                            ..._productSection(
                              notifier.topSellingProducts,
                              title: 'Más vendidos',
                            ),
                        ] else
                          ..._productSection(filtered),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                      ],
                    ),
            ),
          ),
        ],
      ),
      // Bottom bar
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Main CTA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isSubmitting || _openingCheckout
                        ? null
                        : (widget.isPedidoSinMesa
                              ? _handlePedidoSinMesa
                              : _submit),
                    icon: state.isSubmitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Icon(
                            widget.isPedidoSinMesa
                                ? Icons.arrow_forward_rounded
                                : Icons.receipt_long_rounded,
                            size: 20,
                          ),
                    label: Text(
                      widget.isPedidoSinMesa
                          ? (totalItems > 0
                                ? 'Completar pedido'
                                : (_hasPendingCheckout
                                      ? 'Recuperar pedido'
                                      : 'Completar pedido'))
                          : (totalItems > 0
                                ? 'Agregar Comanda  ·  S/ ${notifier.totalAmount.toStringAsFixed(2)}'
                                : 'Agregar Comanda'),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorSchema.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: ColorSchema.primaryColor
                          .withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Cart button with badge
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    InkWell(
                      onTap: _openCartSheet,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: ColorSchema.primaryColor,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.shopping_basket_outlined,
                              color: ColorSchema.primaryColor,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (totalItems > 0)
                      Positioned(
                        top: -6,
                        right: -6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 20,
                            minHeight: 20,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$totalItems',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category chip
// ---------------------------------------------------------------------------

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.white24,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? Colors.white : Colors.white38),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: selected ? ColorSchema.primaryColor : Colors.white,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? ColorSchema.primaryColor : Colors.white,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
