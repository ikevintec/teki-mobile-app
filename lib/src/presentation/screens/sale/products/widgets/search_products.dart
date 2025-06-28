import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/productPrice.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
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
                    return GestureDetector(
                      onTap: () {
                        _ignoreNextSearch = true;
                        ref.read(productSaleProvider.notifier).setProductsSales(product, null);
                        controller.closeView("");
                        FocusScope.of(context).unfocus();
                      },
                      child: ItemProduct(
                        product: product,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ];
        },
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
    return Padding(
      padding: const EdgeInsets.only(left: 15, right: 15, top: 10, bottom: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text((product.nombre ?? "").trim(),
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          SizedBox(height: 5),
          Row(
            children: [
              Text(
                '${product.moneda} ${(product.preciosVenta!.firstWhere(
                      (p) => p.tipoPrecio == "POR_DEFECTO",
                      orElse: () => ProductPrice(precio: 0.0),
                    ).precio)!.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
              ),
              const SizedBox(width: 5),
              Text("-"),
              const SizedBox(width: 5),
              Text(
                'Stock: ${(product.inventarios?.firstWhere((inv) => inv.puntoVenta!.id == puntoVenta!.id, orElse: () => Inventory(stock: 0.0)).stock ?? 0)}',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
                maxLines: 2,
              ),
              const Icon(Icons.category, size: 16, color: Colors.grey),
            ],
          ),
          Divider(
            color: Colors.grey.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
