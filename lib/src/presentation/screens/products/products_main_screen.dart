import 'dart:async';
// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/product-list_section.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/search_field.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
// import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
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

  late var productState = ref.watch(productsProvider);
  late List<Product> productList = [];
  late TextEditingController searchController;

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      Future.microtask(() {
        ref.read(productsProvider.notifier).resetProducts();
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
      ref.read(productsProvider.notifier).searchProducts(value);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel(); // muy importante cancelar cuando destruyes el widget
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    productState = ref.watch(productsProvider);
    List<Product> productListModel = productState.products;
    bool isLoading = productState.isLoading && productListModel.isEmpty;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      key: _key,
      // endDrawer: DashboardDrawer(routeName: "Products", controller: controller),
      // appBar: isSmallScreen
      //     ? AppBar(
      //         elevation: 0,
      //         backgroundColor: ColorSchema.primaryColor,
      //         automaticallyImplyLeading: true,
      //         centerTitle: true,
      //         surfaceTintColor: Colors.white,
      //         title: Text(
      //           "Productos",
      //           style: GoogleFonts.raleway(
      //             color: Colors.white,
      //             textStyle: const TextStyle(fontWeight: FontWeight.w500),
      //           ),
      //         ),
      //         leading: IconButton(
      //           color: Colors.white,
      //           onPressed: () {
      //             Get.back();
      //           },
      //           icon: const Icon(
      //             color: Colors.white,
      //             Icons.keyboard_arrow_left,
      //             size: 30,
      //           ),
      //         ),
      //         actions: [
      //           Padding(
      //             padding: const EdgeInsets.only(right: 5.0),
      //             child: IconButton(
      //               onPressed: () {
      //                 if (!Platform.isAndroid && !Platform.isIOS) {
      //                   controller.setExtended(true);
      //                 }
      //                 if (_key.currentState != null) {
      //                   _key.currentState?.openEndDrawer();
      //                 }
      //               },
      //               icon: const Icon(
      //                 color: Colors.white,
      //                 Icons.menu,
      //                 size: 30,
      //               ),
      //             ),
      //           )
      //         ],
      //       )
      //     : null,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Productos",
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: SearchField(
              onTextChanged: onSearchChanged,
              controller: searchController,
            ),
          ),
          const SizedBox(height: 10),
          if (isLoading)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: ColorSchema.primaryColor,
                      strokeWidth: 2,
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Cargando productos...",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.75,
              child: ProductListSection(
                isSmallScreen: isSmallScreen,
                productList: productListModel,
                onRefresh: () async {
                  await ref.read(productsProvider.notifier).resetProducts();
                  searchController.clear();
                },
              ),
            ),
        ],
      ),
      floatingActionButton: const CustomFloatingActionButton(
        buttonName: "Agregar",
        routeName: AppRoutes.createProduct,
        iconData: Icons.add_circle_outline,
      ),
    );
  }
}
