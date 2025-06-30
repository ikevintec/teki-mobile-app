import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 30),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildServices(
                        context,
                        "Productos",
                        "assets/icons/icon_image/products.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.products);
                    }),
                    buildServices(
                        context,
                        "Venta",
                        "assets/icons/icon_image/pos.png",
                        Colors.grey.shade100,
                        ColorSchema.primaryColor, () {
                      // Get.toNamed(AppRoutes.posSales);
                      Get.toNamed(AppRoutes.productsSales);
                    }),
                    //Ver Comprobantes
                    buildServices(
                        context,
                        "Comprobantes",
                        "assets/icons/icon_image/expense_list.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.comprobantesVer);
                    }),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildServices(
                        context,
                        "Trading",
                        "assets/icons/icon_image/trading.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.posSales);
                    }),
                    buildServices(
                        context,
                        "Expense",
                        "assets/icons/icon_image/expense_list.png",
                        Colors.grey.shade100,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.expenseList);
                    }),
                    buildServices(
                        context,
                        "Peoples",
                        "assets/icons/icon_image/customer.png",
                        Colors.grey.shade100,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.customer);
                    }),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildServices(
                        context,
                        "Sale",
                        "assets/icons/icon_image/sales_list.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.sales);
                    }),
                    buildServices(
                        context,
                        "Purchase",
                        "assets/icons/icon_image/purchase_list.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.purchase);
                    }),
                    buildServices(
                        context,
                        "Product",
                        "assets/icons/icon_image/products_list.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.products);
                    }),
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildServices(
                        context,
                        "Manage",
                        "assets/icons/icon_image/user_management.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.management);
                    }),
                    buildServices(
                        context,
                        "Report",
                        "assets/icons/icon_image/reports.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.report);
                    }),
                    buildServices(
                        context,
                        "Warehouse",
                        "assets/icons/icon_image/warehouse.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.warehouse);
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  InkWell buildServices(context, String service, String serviceIcon,
      Color serviceColor, Color serviceImageColor, Function onPressed) {
    return InkWell(
      onTap: () => onPressed(),
      child: Column(
        children: [
          Column(
            children: [
              Stack(alignment: Alignment.center, children: [
                Container(
                  width: 60,
                  height: 60,
                ),
                ImageIcon(
                  AssetImage(
                    serviceIcon,
                  ),
                  color: serviceImageColor,
                  size: 45,
                )
              ]),
              const SizedBox(
                height: 5,
              ),
              Text(
                service,
                style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.03)),
              )
            ],
          )
        ],
      ),
    );
  }

  GestureDetector buildReports(
    String title,
    Color reportColor,
    IconData reportIcon,
    double screenWidth,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.analytics);
      },
      child: Container(
        width: screenWidth * 0.42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: reportColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    reportIcon,
                    color: ColorSchema.primaryColor,
                    size: 30,
                  )),
            ),
            const SizedBox(
              height: 4,
            ),
            Text.rich(
              TextSpan(
                style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  color: const Color(0xFF333333),
                )),
                children: [
                  TextSpan(text: title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
