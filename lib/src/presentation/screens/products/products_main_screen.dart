import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/product.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/product-list_section.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/search_field.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/providers/products/profucts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:sidebarx/sidebarx.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ProductsMainScreen extends ConsumerStatefulWidget {
  const ProductsMainScreen({super.key});

  @override
  ConsumerState<ProductsMainScreen> createState() => _ProductsMainScreenState();
}

class _ProductsMainScreenState extends ConsumerState<ProductsMainScreen> {
  final controller = SidebarXController(selectedIndex: 1, extended: true);
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  late var productState = ref.watch(productProvider);
  late List<Product> productList = [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      Future.microtask(() {
        ref.read(productProvider.notifier).resetProducts();
      });
      _loaded = true;
    }
  }

  Timer? _debounce;
  void onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) {
      _debounce?.cancel();
    }
    _debounce = Timer(const Duration(milliseconds: 1000), () {
      ref.read(productProvider.notifier).searchProducts(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // muy importante cancelar cuando destruyes el widget
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    productState = ref.watch(productProvider);
    List<Product> productListModel = productState.products;
    bool isLoading = productState.isLoading && productListModel.isEmpty;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      key: _key,
      endDrawer: DashboardDrawer(routeName: "Products", controller: controller),
      appBar: isSmallScreen
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white,
              automaticallyImplyLeading: true,
              centerTitle: true,
              surfaceTintColor: Colors.white,
              title: Text(
                "Productos",
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              leading: IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: const Icon(
                  Icons.keyboard_arrow_left,
                  size: 30,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 5.0),
                  child: IconButton(
                    onPressed: () {
                      if (!Platform.isAndroid && !Platform.isIOS) {
                        controller.setExtended(true);
                      }
                      if (_key.currentState != null) {
                        _key.currentState?.openEndDrawer();
                      }
                    },
                    icon: const Icon(
                      Icons.menu,
                      size: 30,
                    ),
                  ),
                )
              ],
            )
          : null,
      body: Container(
        color: Colors.white70,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.read(productProvider.notifier).resetProducts();
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              SearchField(onTextChanged: onSearchChanged),
              const SizedBox(
                height: 10,
              ),
              isLoading
                  ? Expanded(
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: ColorSchema.primaryColor,
                              strokeWidth: 2,
                            ),
                            SizedBox(
                              height: 10,
                            ),
                            Text(
                              "Cargando productos...",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                  : ProductListSection(
                      isSmallScreen: isSmallScreen,
                      productList: productListModel),
            ],
          ),
        ),
      ),
      floatingActionButton: const CustomFloatingActionButton(
          buttonName: "Agregar", 
          routeName: AppRoutes.addProduct,
          iconData: Icons.add_circle_outline,
      ),
    );
  }
}
