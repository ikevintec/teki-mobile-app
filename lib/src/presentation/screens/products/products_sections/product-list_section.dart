import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/enums/products.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/data/models/productPrice.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/update_product_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/products/profucts.dart';
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
      if (ref.read(productProvider).isLoading) return;
      ref.read(productProvider.notifier).loadNextPage();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(configProvider);
    final idPuntoVenta = provider.office?.id;
    return Expanded(
      child: widget.productList.isEmpty
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
                        "No Product Found",
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
              physics: const BouncingScrollPhysics(),
              itemCount: widget.productList.length +
                  1, // +1 para el loader/mensaje final
              itemBuilder: (context, index) {
                if (index == widget.productList.length) {
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

                final product = widget.productList[index];
                return Card(
                  elevation: 0.1,
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: Padding(
                            padding: const EdgeInsets.all(5.0),
                            child: product.imagenUrl != null &&
                                    product.imagenUrl!.isNotEmpty
                                ? Image.network(
                                    product.imagenUrl!,
                                    fit: BoxFit.contain,
                                  )
                                : Image.asset(
                                    'assets/images/logo/logo-teki-solo.png',
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.error);
                                    },
                                    fit: BoxFit.contain,
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.nombre!,
                                style: GoogleFonts.raleway(
                                  textStyle: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: widget.isSmallScreen ? 16 : 18,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8, top: 6),
                                  child: Text(
                                    product.categoria?.nombre ??
                                        "Sin Categoria",
                                    style: GoogleFonts.raleway(
                                      textStyle: const TextStyle(
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Stock: ${product.inventarios?.firstWhere((element) => element.puntoVenta?.id == idPuntoVenta).stock ?? 0}",
                                      style: GoogleFonts.nunito(),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Precio venta: ${product.preciosVenta?.firstWhere(
                                            (element) =>
                                                element.tipoPrecio ==
                                                TipoPrecio.POR_DEFECTO,
                                            orElse: () => ProductPrice(),
                                          ).precio ?? "No registrado"}",
                                      style: GoogleFonts.nunito(),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      "Precio compra: ${product.precioCompra ?? "No registrado"}",
                                      style: GoogleFonts.nunito(),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
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
                                  buildModalBottomSheet(context, product);
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
            ),
    );
  }

  void buildModalBottomSheet(BuildContext context, Product product) {
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
          child: UpdateProductScreen(product: product),
        );
      },
    );
  }
}
