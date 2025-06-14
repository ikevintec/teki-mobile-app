import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/enums/products.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/productPrice.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/update_product_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/products/profucts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ProductListSection extends ConsumerStatefulWidget {
  final dynamic isSmallScreen;
  final List<Product> productList;

  const ProductListSection({
    super.key,
    required this.isSmallScreen,
    required this.productList,
  });

  @override
  ConsumerState<ProductListSection> createState() => _ProductListSectionState();
}

class _ProductListSectionState extends ConsumerState<ProductListSection> {
  late ScrollController _scrollController;
  bool isLoadingMore = false; // Control de carga
  bool hasReachedEnd = false; // Control de fin de datos

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {}

  Future<void> _loadMoreProducts() async {
    Future.microtask(() {
      if (ref.read(productsProvider).isLoading) return;
      ref.read(productsProvider.notifier).loadNextPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(sesionProvider);
    final idPuntoVenta = provider.office?.id;
    final isLast = ref.watch(productsProvider).last;
    return widget.productList.isEmpty
        ? ListView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 100),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      "assets/images/other/empty_product.png",
                      width: 350,
                    ),
                    Text(
                      "No se encontraron productos",
                      style: GoogleFonts.raleway(
                        fontWeight: FontWeight.w500,
                        fontSize: 24,
                        color: const Color(0xFF333333),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        : ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.zero,
            itemCount: widget.productList.length +
                1, // +1 para el loader/mensaje final
            itemBuilder: (context, index) {
              if (index == widget.productList.length) {
                if (isLast) {
                  return const SizedBox(
                    height: 50,
                    child: Center(
                      child: Text(
                        "No hay más productos",
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                } else {
                  _loadMoreProducts();
                  return const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                        child: CircularProgressIndicator(
                      color: ColorSchema.primaryColor,
                      strokeWidth: 2,
                    )),
                  );
                }
              }

              final product = widget.productList[index];
              return Card(
                elevation: 0.1,
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: product.imagenUrl != null &&
                                  product.imagenUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    product.imagenUrl!,
                                    fit: BoxFit.contain,
                                    width: 60,
                                    height: 60,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Image.asset(
                                        'assets/images/gif/loader.gif',
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                      );
                                    },
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Icon(Icons.error),
                                  ),
                                )
                              : Image.asset(
                                  'assets/images/products/icon.png',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(Icons.error);
                                  },
                                  fit: BoxFit.contain,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8 , bottom: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nombre!,
                              style: GoogleFonts.raleway(
                                textStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Stock: ${product.inventarios?.firstWhere(
                                          (element) =>
                                              element.puntoVenta?.id ==
                                              idPuntoVenta,
                                          orElse: () => Inventory(
                                            stock: 0,
                                          ),
                                        ).stock ?? 0}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Precio venta: ${product.preciosVenta?.firstWhere(
                                          (element) =>
                                              element.tipoPrecio ==
                                              TipoPrecio.POR_DEFECTO,
                                          orElse: () => ProductPrice(),
                                        ).precio ?? "No registrado"}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Precio compra: ${product.precioCompra ?? "No registrado"}",
                                    style: GoogleFonts.nunito(
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(50),
                              color: Colors.blue.shade50.withOpacity(0.3),
                            ),
                            child: IconButton(
                              icon: Padding(
                                padding: const EdgeInsets.all(2.0),
                                child: SvgPicture.asset(
                                  "assets/icons/icon_svg/edit_icon.svg",
                                  color: Colors.blue,
                                ),
                              ),
                              onPressed: () {
                                Get.toNamed(AppRoutes.updateProduct,
                                    arguments: {
                                      "id": product.id,
                                    });
                              },
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              );
            },
          );
  }

  void buildModalBottomSheet(
      BuildContext context, Product product, int idPuntoVenta) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      context: context,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child:
              UpdateProductScreen(product: product, idPuntoVenta: idPuntoVenta),
        );
      },
    );
  }
}
