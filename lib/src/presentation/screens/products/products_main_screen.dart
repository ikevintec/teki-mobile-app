import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/products_model/product_list_model.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/product-list_section.dart';
import 'package:teki_app/src/presentation/screens/products/products_sections/search_field.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:sidebarx/sidebarx.dart';

class ProductsMainScreen extends StatefulWidget {
  const ProductsMainScreen({super.key});

  @override
  State<ProductsMainScreen> createState() => _ProductsMainScreenState();
}

class _ProductsMainScreenState extends State<ProductsMainScreen> {
  final controller = SidebarXController(selectedIndex: 1, extended: true);
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  List<Map<String, dynamic>> productList = List.from(productListModel);

  searchProduct(value) {
    setState(() {
      productList = productListModel
          .where((product) => product["name"]
              .toString()
              .toLowerCase()
              .contains(value.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                "Product List",
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
          onRefresh: () async {},
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              SearchField(onTextChanged: (value) => searchProduct(value)),
              const SizedBox(
                height: 10,
              ),
              ProductListSection(
                  isSmallScreen: isSmallScreen, productList: productList),
            ],
          ),
        ),
      ),
      floatingActionButton: const CustomFloatingActionButton(
          buttonName: "Add Product", routeName: AppRoutes.addProduct),
    );
  }
}
