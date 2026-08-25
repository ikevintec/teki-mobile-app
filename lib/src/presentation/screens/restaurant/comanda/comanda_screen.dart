import 'dart:async';

import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/pedido_sin_mesa_dialog.dart';
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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    Future.microtask(() {
      if (!mounted) return;
      ref.read(comandaProvider.notifier).init(
            widget.table,
            existingOrderId: widget.existingOrderId,
          );
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
    _debounce = Timer(const Duration(milliseconds: 700), () {
      ref.read(comandaProvider.notifier).loadProducts(query: value);
    });
    setState(() {});
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
    final fullProduct =
        await ref.read(comandaProvider.notifier).getFullProduct(product);
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
    final office = ref.read(sesionProvider).office;
    if (office == null) {
      warningNotification('No hay punto de venta seleccionado');
      return;
    }
    final notifier = ref.read(comandaProvider.notifier);
    if (notifier.totalItems == 0) {
      warningNotification('La canasta está vacía');
      return;
    }

    final result = await showPedidoSinMesaDialog(context);
    if (result == null) return;

    final createdOrder = await notifier.submitPedidoSinMesa(
      puntoVenta: office,
      tipo: result.tipo,
      nombreCliente: result.nombreCliente,
      tipoDocumentoReceptor: result.tipoDocumentoReceptor,
      numeroDocumentoReceptor: result.numeroDocumentoReceptor,
      denominacionReceptor: result.denominacionReceptor,
      direccionReceptor: result.direccionReceptor,
      emailReceptor: result.emailReceptor,
      telefonoReceptor: result.telefonoReceptor,
      direccionCompleta: result.direccionCompleta,
      montoDelivery: result.montoDelivery,
    );

    if (createdOrder == null) return; // error ya notificado
    if (!mounted) return;

    // Si generarComprobante: cargar la cuenta y lanzar flujo de comprobante
    if (result.generarComprobante) {
      final cuentaId = createdOrder.cuentas?.isNotEmpty == true
          ? createdOrder.cuentas![0].id
          : null;

      if (cuentaId != null) {
        try {
          final fullCheck =
              await ref.read(cobradorProvider.notifier).getCheckById(cuentaId);
          if (!mounted) return;
          await ref.read(productSaleProvider.notifier).initFromCheck(fullCheck);
          if (!mounted) return;
          // Reemplaza ComandaScreen con ProductsSaleScreen; back → pedidos
          Get.offUntil(
            GetPageRoute(
              page: () => const ProductsSaleScreen(),
              routeName: '/products_sale_from_pedido',
            ),
            (route) => route.settings.name == AppRoutes.ordersRestaurant,
          );
          successNotification('Pedido creado exitosamente');
        } catch (e) {
          errorNotification('Error al cargar la cuenta: $e');
          Get.until((route) =>
              route.settings.name == AppRoutes.ordersRestaurant);
          successNotification('Pedido creado. No se pudo abrir el comprobante.');
        }
        return;
      }
    }

    // Sin generarComprobante o sin cuenta: volver a pedidos
    successNotification('Pedido creado exitosamente');
    Get.until(
        (route) => route.settings.name == AppRoutes.ordersRestaurant);
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
    if (notifier.totalItems == 0) {
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
                  const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Confirmar Comanda',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(dialogCtx, false),
                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            // Body
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: ColorSchema.primaryColor.withValues(alpha: 0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: ColorSchema.primaryColor.withValues(alpha: 0.7), size: 18),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w600)),
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
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
            ),
            if (!widget.isPedidoSinMesa && widget.table?.salon?.nombre != null)
              Text(
                widget.table!.salon!.nombre!,
                style: const TextStyle(
                    fontSize: 11, color: Colors.white70),
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
                          fontSize: 14, color: Colors.black38),
                      prefixIcon: const Icon(Icons.search,
                          color: Colors.black38, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  size: 18, color: Colors.black38),
                              onPressed: () {
                                _debounce?.cancel();
                                _searchController.clear();
                                setState(() {});
                                ref.read(comandaProvider.notifier).loadProducts();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 16),
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
                        selected: state.selectedCategoria ==
                            ComandaState.kFavoritos,
                        onTap: () => notifier.selectFavoritos(),
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
                        color: ColorSchema.primaryColor),
                  )
                : filtered.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 52, color: Colors.grey.shade300),
                                const SizedBox(height: 10),
                                Text(
                                  'No hay productos',
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding:
                            const EdgeInsets.fromLTRB(12, 12, 12, 110),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.70,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final product = filtered[i];
                          return ProductMenuCard(
                            product: product,
                            isLoading: _openingProductId == product.id,
                            onTap: () => _openProduct(product),
                          );
                        },
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
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Main CTA
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: state.isSubmitting
                        ? null
                        : (widget.isPedidoSinMesa ? _handlePedidoSinMesa : _submit),
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
                            size: 20),
                    label: Text(
                      widget.isPedidoSinMesa
                          ? (totalItems > 0
                              ? 'Siguiente  ·  S/ ${notifier.totalAmount.toStringAsFixed(2)}'
                              : 'Siguiente')
                          : (totalItems > 0
                              ? 'Agregar Comanda  ·  S/ ${notifier.totalAmount.toStringAsFixed(2)}'
                              : 'Agregar Comanda'),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorSchema.primaryColor,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                          ColorSchema.primaryColor.withValues(alpha: 0.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: ColorSchema.primaryColor, width: 1.5),
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
                              minWidth: 20, minHeight: 20),
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
          border: Border.all(
            color: selected ? Colors.white : Colors.white38,
          ),
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
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
