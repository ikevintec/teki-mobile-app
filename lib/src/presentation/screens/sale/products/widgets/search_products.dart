import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class SearchProducts extends ConsumerStatefulWidget {
  final FormGroup form;
  const SearchProducts({super.key, required this.form});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchProductsState();
}

class _SearchProductsState extends ConsumerState<SearchProducts>
    with WidgetsBindingObserver {
  Timer? _debounce;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double _fieldTopY = 0;

  final ValueNotifier<List<Product>> _results = ValueNotifier([]);
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);
  final ValueNotifier<bool> _hasSearched = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
  }

  @override
  void didChangeMetrics() {
    // Rebuild overlay when keyboard appears/disappears
    _overlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _debounce?.cancel();
    _controller.removeListener(_onTextChange);
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    _results.dispose();
    _isSearching.dispose();
    _hasSearched.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _onTextChange() {
    setState(() {}); // rebuild for clear button visibility
    final query = _controller.text.trim();
    if (query.isEmpty) {
      _debounce?.cancel();
      _results.value = [];
      _isSearching.value = false;
      _hasSearched.value = false;
      return;
    }
    _isSearching.value = true;
    _hasSearched.value = false;
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final products = await ref.read(productSaleProvider.notifier).searchProducts(query);
      if (mounted) {
        _results.value = products;
        _isSearching.value = false;
        _hasSearched.value = true;
      }
    });
  }

  Future<void> _selectProduct(Product product) async {
    _controller.clear();
    _results.value = [];
    _hasSearched.value = false;
    _focusNode.unfocus();
    // El resultado de la búsqueda es ligero: al seleccionar se trae el detalle
    // completo del producto antes de agregarlo a la venta.
    await ref.read(productSaleProvider.notifier).selectProductForSale(product);
  }

  void _showOverlay() {
    _removeOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    final fieldWidth = renderBox != null ? renderBox.size.width - 58 : 280.0;
    if (renderBox != null) {
      final offset = renderBox.localToGlobal(Offset.zero);
      _fieldTopY = offset.dy;
    }
    _overlayEntry = OverlayEntry(
      builder: (_) => _SuggestionsDropdown(
        layerLink: _layerLink,
        width: fieldWidth,
        fieldTopY: _fieldTopY,
        results: _results,
        isSearching: _isSearching,
        hasSearched: _hasSearched,
        controller: _controller,
        onSelect: _selectProduct,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _onScanBarcode() async {
    final code = await BarcodeScannerSheet.show(context);
    if (code == null || code.isEmpty) return;
    final product = await ref.read(productSaleProvider.notifier).getProductByBarcode(code);
    if (!mounted) return;
    if (product != null) {
      await ref.read(productSaleProvider.notifier).selectProductForSale(product);
    } else {
      errorNotification("Producto no encontrado para el código de barras: $code");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBarcodeSearching = ref.watch(productSaleProvider).isBarcodeSearching;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: CompositedTransformTarget(
              link: _layerLink,
              child: AbsorbPointer(
                absorbing: isBarcodeSearching,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Buscar producto',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.black38),
                      prefixIcon: const Icon(Icons.search, color: ColorSchema.primaryColor, size: 22),
                      suffixIcon: _controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.black38),
                              onPressed: () {
                                _controller.clear();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: ColorSchema.primaryColor, width: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isBarcodeSearching ? null : _onScanBarcode,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: isBarcodeSearching
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        color: ColorSchema.primaryColor,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.qr_code_scanner, color: ColorSchema.primaryColor, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsDropdown extends StatelessWidget {
  final LayerLink layerLink;
  final double width;
  final double fieldTopY;
  final ValueNotifier<List<Product>> results;
  final ValueNotifier<bool> isSearching;
  final ValueNotifier<bool> hasSearched;
  final TextEditingController controller;
  final void Function(Product) onSelect;

  const _SuggestionsDropdown({
    required this.layerLink,
    required this.width,
    required this.fieldTopY,
    required this.results,
    required this.isSearching,
    required this.hasSearched,
    required this.controller,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // Space from bottom of field (fieldTopY + 54px offset) to top of keyboard (or screen bottom)
    final keyboardTop = mq.size.height - mq.viewInsets.bottom;
    final dropdownTop = fieldTopY + 54;
    final maxHeight = (keyboardTop - dropdownTop - 8).clamp(80.0, double.infinity);

    return CompositedTransformFollower(
      link: layerLink,
      showWhenUnlinked: false,
      offset: const Offset(0, 54),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: ListenableBuilder(
            listenable: Listenable.merge([results, isSearching, hasSearched, controller]),
            builder: (context, _) {
              final query = controller.text.trim();
              final Widget content;

              if (query.isEmpty) {
                return const SizedBox.shrink();
              } else if (isSearching.value) {
                content = const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: ColorSchema.primaryColor),
                      ),
                      SizedBox(width: 10),
                      Text('Buscando...', style: TextStyle(fontSize: 13, color: Colors.black54)),
                    ],
                  ),
                );
              } else if (hasSearched.value && results.value.isEmpty) {
                content = const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text(
                    'No se encontraron resultados.',
                    style: TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                );
              } else if (results.value.isNotEmpty) {
                content = ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: maxHeight),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: results.value.map((product) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => onSelect(product),
                              child: ItemProduct(product: product),
                            ),
                            if (product != results.value.last)
                              Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                );
              } else {
                return const SizedBox.shrink();
              }

              return Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(14),
                color: Colors.white,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class ItemProduct extends ConsumerWidget {
  final Product product;
  const ItemProduct({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puntoVenta = ref.watch(sesionProvider).office;
    final precio = (product.preciosVenta?.firstWhere(
          (p) => p.tipoPrecio == "POR_DEFECTO",
          orElse: () => ProductPrice(precio: 0.0),
        ).precio ?? 0.0);
    final stock = product.inventarios
            ?.firstWhere(
              (inv) => inv.puntoVenta?.id == puntoVenta?.id,
              orElse: () => Inventory(stock: 0.0),
            )
            .stock ??
        0.0;
    final inicial = (product.nombre?.isNotEmpty == true)
        ? product.nombre![0].toUpperCase()
        : 'P';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(
              inicial,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: ColorSchema.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (product.nombre ?? '').trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${product.moneda ?? ''} ${precio.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.inventory_2_outlined, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 3),
                    Text(
                      'Stock: $stock',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.add_circle_outline, size: 20, color: ColorSchema.primaryColor.withValues(alpha: 0.5)),
        ],
      ),
    );
  }
}
