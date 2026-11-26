import 'package:teki_app/src/presentation/widgets/product_search_result.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/presentation/screens/pedidos/precio_linea.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/estilo_accion_principal.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
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
  int _searchVersion = 0;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  double _fieldTopY = 0;

  final ValueNotifier<List<Product>> _results = ValueNotifier([]);
  final ValueNotifier<bool> _isSearching = ValueNotifier(false);
  final ValueNotifier<String?> _searchError = ValueNotifier(null);
  final ValueNotifier<bool> _hasSearched = ValueNotifier(false);
  // Productos con una operación pendiente: muestran un indicador y no aceptan un
  // segundo toque hasta terminar (en red lenta parecía que no pasaba nada).
  final ValueNotifier<Set<int>> _agregando = ValueNotifier({});
  Future<void> _cola = Future.value();

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
    _searchError.dispose();
    _agregando.dispose();
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
    final version = ++_searchVersion;
    _searchError.value = null;
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
      try {
        final products = await ref.read(productSaleProvider.notifier).searchProducts(query);
        if (!mounted || version != _searchVersion) return;
        _results.value = products;
        _isSearching.value = false;
        _hasSearched.value = true;
      } catch (_) {
        if (!mounted || version != _searchVersion) return;
        _results.value = [];
        _isSearching.value = false;
        _hasSearched.value = false;
        _searchError.value = 'No pudimos buscar los productos. Revisa tu conexión.';
      }
    });
  }

  void _encolar(
    Product product,
    Future<void> Function(ProductsSaleNotifier) accion, {
    bool restaurarBusqueda = false,
  }) {
    final id = product.id;
    if (id == null || _agregando.value.contains(id)) return;
    final carrito = ref.read(productSaleProvider.notifier);
    _agregando.value = {..._agregando.value, id};
    _cola = _cola.then((_) async {
      try {
        if (carrito.mounted) await accion(carrito);
      } catch (_) {
        if (mounted) {
          _searchError.value =
              'No pudimos actualizar el producto. Inténtalo nuevamente.';
        }
      } finally {
        if (mounted) {
          _agregando.value = {..._agregando.value}..remove(id);
          if (restaurarBusqueda &&
              carrito.mounted &&
              identical(ref.read(productSaleProvider.notifier), carrito)) {
            _focusNode.requestFocus();
          }
        }
      }
    });
  }

  void _selectProduct(Product product) {
    _encolar(
      product,
      (carrito) => carrito.selectProductForSale(
        product,
        solicitarPrecioManual: (_) async {
          if (!mounted) return null;
          final precio = await ingresarPrecio(context);
          if (mounted) _focusNode.requestFocus();
          return precio;
        },
      ),
    );
  }

  bool _carritoActual(ProductsSaleNotifier carrito) =>
      mounted &&
      carrito.mounted &&
      identical(ref.read(productSaleProvider.notifier), carrito);

  List<TicketDetail> _lineas(Product producto) => ref
      .read(productSaleProvider)
      .productsSales
      .where((l) => l.producto?.id == producto.id && l.esBonificacion != true)
      .toList();

  int _indiceLinea(TicketDetail linea) => ref
      .read(productSaleProvider)
      .productsSales
      .indexWhere(
        (actual) => linea.uuid != null
            ? actual.uuid == linea.uuid
            : identical(actual, linea),
      );

  bool _editable(TicketDetail linea) =>
      linea.comandaDetalle == null && linea.esBonificacion != true;

  void _disminuir(Product producto) {
    _encolar(producto, (carrito) async {
      if (!_carritoActual(carrito)) return;
      final linea = _lineas(producto).where(_editable).lastOrNull;
      if (linea == null) return;
      final indice = _indiceLinea(linea);
      if ((linea.cantidad ?? 1) <= 1) {
        carrito.removeProductSale(indice);
      } else {
        carrito.setCantidadProductSale(
          indice,
          linea.cantidad! - 1,
          actualizarSeries: true,
        );
      }
    });
  }

  void _quitar(Product producto) {
    _encolar(producto, (carrito) async {
      if (!_carritoActual(carrito)) return;
      final lineas = _lineas(producto).where(_editable).toList();
      for (final linea in lineas.reversed) {
        final indice = _indiceLinea(linea);
        if (indice >= 0) carrito.removeProductSale(indice);
      }
    });
  }

  void _editarCantidad(Product producto) {
    _encolar(producto, (carrito) async {
      if (!_carritoActual(carrito)) return;
      final cambio = await editarCantidadResultado(context, producto, _lineas(producto));
      if (cambio == null || !_carritoActual(carrito)) return;
      final indice = _indiceLinea(cambio.$1);
      if (indice >= 0) {
        carrito.setCantidadProductSale(indice, cambio.$2, actualizarSeries: true);
      }
    }, restaurarBusqueda: true);
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
        onDecrease: _disminuir,
        onEdit: _editarCantidad,
        onRemove: _quitar,
        agregando: _agregando,
        onDone: _focusNode.unfocus,
        error: _searchError,
        onRetry: _onTextChange,
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
      await ref.read(productSaleProvider.notifier).selectProductForSale(product,solicitarPrecioManual:(_)=>ingresarPrecio(context));
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
  final void Function(Product) onDecrease;
  final void Function(Product) onEdit;
  final void Function(Product) onRemove;
  final ValueNotifier<String?> error;
  final VoidCallback onRetry;
  final ValueNotifier<Set<int>> agregando;
  final VoidCallback onDone;

  const _SuggestionsDropdown({
    required this.layerLink,
    required this.width,
    required this.fieldTopY,
    required this.results,
    required this.isSearching,
    required this.hasSearched,
    required this.controller,
    required this.onSelect,
    required this.onDecrease,
    required this.onEdit,
    required this.onRemove,
    required this.error,
    required this.onRetry,
    required this.agregando,
    required this.onDone,
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
            listenable: Listenable.merge([results, isSearching, hasSearched, controller, error, agregando]),
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
              } else if (error.value != null) {
                content = Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(error.value!, semanticsLabel: error.value),
                    TextButton(onPressed: onRetry, child: const Text('Reintentar')),
                  ]),
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: results.value.map((product) {
                              return Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ItemProduct(
                                    product: product,
                                    agregando: agregando.value.contains(product.id),
                                    onAdd: () => onSelect(product),
                                    onDecrease: () => onDecrease(product),
                                    onEdit: () => onEdit(product),
                                    onRemove: () => onRemove(product),
                                  ),
                                  if (product != results.value.last)
                                    Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      // Igual que la búsqueda de pedidos: la lista queda abierta
                      // para sumar varios productos y se cierra a propósito.
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: estiloAccionPrincipal,
                            onPressed: onDone,
                            child: const Text('Listo'),
                          ),
                        ),
                      ),
                    ],
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

typedef ItemProduct = ProductSearchResult;
