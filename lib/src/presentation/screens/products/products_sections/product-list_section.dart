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
  final Future<void> Function() onRefresh;

  const ProductListSection({
    super.key,
    required this.isSmallScreen,
    required this.productList,
    required this.onRefresh,
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
        ? RefreshIndicator(
            color: ColorSchema.primaryColor,
            onRefresh: widget.onRefresh,
            child: ListView(
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
            ),
          )
        : RefreshIndicator(
            color: ColorSchema.primaryColor,
            onRefresh: widget.onRefresh,
            child: ListView.builder(
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
              final stock = product.inventarios?.firstWhere(
                    (e) => e.puntoVenta?.id == idPuntoVenta,
                    orElse: () => Inventory(stock: 0),
                  ).stock ??
                  0;
              final precioVenta = product.preciosVenta
                  ?.firstWhere(
                    (e) => e.tipoPrecio == TipoPrecio.POR_DEFECTO,
                    orElse: () => ProductPrice(),
                  )
                  .precio;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Imagen
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F6FA),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.all(6.0),
                            child: product.imagenUrl != null &&
                                    product.imagenUrl!.isNotEmpty
                                ? Image.network(
                                    product.imagenUrl!,
                                    fit: BoxFit.contain,
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Image.asset(
                                        'assets/images/gif/loader.gif',
                                        fit: BoxFit.cover,
                                      );
                                    },
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.broken_image_outlined,
                                            color: Colors.grey),
                                  )
                                : Image.asset(
                                    'assets/images/products/icon.png',
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) =>
                                        const Icon(Icons.inventory_2_outlined,
                                            color: Colors.grey),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nombre ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _infoChip(
                                  icon: Icons.inventory_2_outlined,
                                  label: 'Stock: $stock',
                                  color: stock > 0
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFC62828),
                                  bg: stock > 0
                                      ? const Color(0xFFE8F5E9)
                                      : const Color(0xFFFFEBEE),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Venta: ${precioVenta ?? "—"}',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF555555),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    'Compra: ${product.precioCompra ?? "—"}',
                                    style: GoogleFonts.roboto(
                                      fontSize: 11,
                                      color: const Color(0xFF555555),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Botón editar
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Get.toNamed(AppRoutes.updateProduct,
                              arguments: {'id': product.id});
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SvgPicture.asset(
                            'assets/icons/icon_svg/edit_icon.svg',
                            width: 18,
                            height: 18,
                            colorFilter: const ColorFilter.mode(
                              Color(0xFF3949AB),
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
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
