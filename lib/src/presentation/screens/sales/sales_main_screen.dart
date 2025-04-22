import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/sales/salesSections/horizontal_sales_table_section.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/start_end_date_picker_section.dart';
import 'package:teki_app/src/presentation/widgets/drawer/dashboard_drawer.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:sidebarx/sidebarx.dart';

class SalesMainScreen extends StatefulWidget {
  const SalesMainScreen({super.key});

  @override
  State<SalesMainScreen> createState() => _SalesMainScreenState();
}

class _SalesMainScreenState extends State<SalesMainScreen> {
  final controller = SidebarXController(selectedIndex: 1, extended: true);
  final GlobalKey<ScaffoldState> _key = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _key,
      endDrawer: Drawer(
        child: DashboardDrawer(routeName: "Trading", controller: controller),
      ),
      appBar: isSmallScreen
          ? AppBar(
              elevation: 0,
              backgroundColor: Colors.white70,
              automaticallyImplyLeading: true,
              centerTitle: true,
              surfaceTintColor: Colors.white,
              title: Text(
                "Sales",
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
                IconButton(
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
                )
              ],
            )
          : null,
      body: Container(
        color: Colors.white70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 10,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: StartEndDatePickerSection(),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: CustomElevatedButton(
                  buttonName: "Generate Sales",
                  showToast: () {
                    SuccessToast.showSuccessToast(context, "Generate Complete",
                        "Sales List Generate Complete");
                  }),
            ),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Existing Sales List",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                        color: Colors.black87,
                        fontSize: 18,
                        fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Expanded(
                child: SingleChildScrollView(
                    child: HorizontalSalesTableSection())),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
      floatingActionButton: Align(
        alignment: Alignment.bottomRight,
        child: FloatingActionButton.extended(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onPressed: () {
            Get.toNamed(AppRoutes.salesReturn);
          },
          label: Text(
            "Sales Return",
            style: GoogleFonts.raleway(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
          icon: const Icon(
            Icons.rotate_right,
            color: Colors.white70,
            size: 24,
          ),
          backgroundColor: ColorSchema.primaryColor,
        ),
      ),
    );
  }
}
