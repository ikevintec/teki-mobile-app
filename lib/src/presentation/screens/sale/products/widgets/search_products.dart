import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/productPrice.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class SearchProducts extends ConsumerStatefulWidget {
  final FormGroup form;
  const SearchProducts({super.key, required this.form});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _SearchProductsState();
}

class _SearchProductsState extends ConsumerState<SearchProducts> {
  Timer? _debounce;
  bool _ignoreNextSearch = false;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onScanBarcode() async {
    final code = await BarcodeScannerSheet.show(context);
    if (code == null || code.isEmpty) return;

    final product =
        await ref.read(productSaleProvider.notifier).getProductByBarcode(code);
    if (!mounted) return;
    if (product != null) {
      ref.read(productSaleProvider.notifier).setProductsSales(product, null);
    } else {
      errorNotification("Producto no encontrado para el código de barras: $code");
    }
  }

  Future<List<Product>> onSearchChanged(String query) async {
    if (_ignoreNextSearch) {
      _ignoreNextSearch = false;
      return [];
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    final completer = Completer<List<Product>>();
    _debounce = Timer(const Duration(seconds: 1), () async {
      if (query.isNotEmpty) {
        final products =
            await ref.read(productSaleProvider.notifier).getProducts(query);
        completer.complete(products);
        print(completer);
      } else {
        completer.complete([]);
      }
    });

    return completer.future;
  }

  @override
  Widget build(BuildContext context) {
    final isBarcodeSearching =
        ref.watch(productSaleProvider).isBarcodeSearching;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: AbsorbPointer(
              absorbing: isBarcodeSearching,
              child: SearchAnchor.bar(
        barHintText: "Buscar producto",
        barBackgroundColor: WidgetStateProperty.all(Colors.white),
        dividerColor: ColorSchema.primaryColor,
        barOverlayColor: WidgetStateProperty.all(Colors.white),
        viewBackgroundColor: Colors.white,
        isFullScreen: false,
        suggestionsBuilder: (context, controller) {
          if (controller.text.isEmpty) {
            return [
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: const Text(
                    "Sin elementos...",
                  ),
                ),
              ),
            ]; // Mostrar el texto cuando está vacío
          }
          return [
            FutureBuilder<List<Product>>(
              future: onSearchChanged(controller.text),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const ListTile(
                    title: Text("Buscando..."),
                  );
                } else if (snapshot.hasError) {
                  return ListTile(
                    title: Text("Error: ${snapshot.error}"),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const ListTile(
                    title: Text("No se encontraron resultados."),
                  );
                }

                final products = snapshot.data!;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: products.map((product) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            _ignoreNextSearch = true;
                            ref.read(productSaleProvider.notifier).setProductsSales(product, null);
                            controller.closeView("");
                            FocusScope.of(context).unfocus();
                          },
                          child: ItemProduct(product: product),
                        ),
                        Divider(height: 1, thickness: 1, color: Colors.grey.shade300),
                      ],
                    );
                  }).toList(),
                );
              },
            ),
          ];
        },
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
                  : const Icon(Icons.qr_code_scanner,
                      color: ColorSchema.primaryColor, size: 22),
            ),
          ),
        ],
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
