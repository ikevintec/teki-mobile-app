// import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_sections/customer_list_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
// import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/presentation/widgets/floating_aciton_button/custom_floating_action_button.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_Field.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:sidebarx/sidebarx.dart';

class CustomerMainScreen extends StatefulWidget {
  const CustomerMainScreen({super.key});

  @override
  State<CustomerMainScreen> createState() => _CustomerMainScreenState();
}

class _CustomerMainScreenState extends State<CustomerMainScreen> {
  final controller = SidebarXController(selectedIndex: 1, extended: true);
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    // final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _key,
      // endDrawer: DashboardDrawer(routeName: "Customer", controller: controller),
      // appBar: isSmallScreen
      //     ? AppBar(
      //         elevation: 0,
      //         backgroundColor: Colors.white,
      //         automaticallyImplyLeading: true,
      //         centerTitle: true,
      //         surfaceTintColor: Colors.white,
      //         title: Text(
      //           "Customer",
      //           style: GoogleFonts.raleway(
      //             textStyle: const TextStyle(fontWeight: FontWeight.w500),
      //           ),
      //         ),
      //         leading: IconButton(
      //           onPressed: () {
      //             Get.back();
      //           },
      //           icon: const Icon(
      //             Icons.keyboard_arrow_left,
      //             size: 30,
      //           ),
      //         ),
      //         actions: [
      //           IconButton(
      //             onPressed: () {
      //               if (!Platform.isAndroid && !Platform.isIOS) {
      //                 controller.setExtended(true);
      //               }
      //               if (_key.currentState != null) {
      //                 _key.currentState?.openEndDrawer();
      //               }
      //             },
      //             icon: const Icon(
      //               Icons.menu,
      //               size: 30,
      //             ),
      //           )
      //         ],
      //       )
      //     : null,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Clientes",
        ),
      ),
      body: Container(
        color: Colors.white70,
        child: Column(
          children: [
            const SizedBox(
              height: 20,
            ),
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: const CustomSearchField(hintText: "Search Customer")),
            const SizedBox(
              height: 20,
            ),
            const Expanded(child: CustomerListSection())
          ],
        ),
      ),
      floatingActionButton: const CustomFloatingActionButton(
          buttonName: "Create Customer", routeName: AppRoutes.addCustomer),
    );
  }
}
