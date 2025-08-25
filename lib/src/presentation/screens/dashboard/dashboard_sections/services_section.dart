import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ServicesSection extends ConsumerWidget {
  const ServicesSection({super.key});

  void openNewSale(WidgetRef ref) {
    final ticket = ref.read(ticketProvider);
    if (ticket.isEdit) {
      // Limpiar completamente todos los providers para nueva venta
      ref.invalidate(ticketProvider);
      ref.invalidate(productSaleProvider);
      ref.invalidate(customerSaleProvider);
    }
    Get.toNamed(AppRoutes.productsSales);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.only(left: 30, right: 30, top: 50),
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
                    //Ver Comprobantes
                    buildServices(
                        context,
                        "Comprobantes",
                        "assets/icons/icon_image/expense_list.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.comprobantesVer);
                    }),
                    buildServices(
                        context,
                        "Venta",
                        "assets/icons/icon_image/pos.png",
                        Colors.grey.shade100,
                        ColorSchema.primaryColor, () {
                      // Get.toNamed(AppRoutes.posSales);
                      openNewSale(ref);
                    }),
                  ],
                ),
                const SizedBox(
                  height: 40,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    buildServices(
                        context,
                        "Clientes",
                        "assets/icons/icon_image/customer.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.customer);
                    }),
                    buildServices(
                        context,
                        "Stats",
                        "assets/icons/icon_image/trading.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.analytics);
                    }),
                    buildServices(
                        context,
                        "Ajustes",
                        "assets/icons/icon_image/user_management.png",
                        Colors.white,
                        ColorSchema.primaryColor, () {
                      Get.toNamed(AppRoutes.settings);
                    }),
                  ],
                ),
                const SizedBox(
                  height: 30,
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
                  size: 55,
                )
              ]),
              const SizedBox(
                height: 5,
              ),
              Text(
                service,
                style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.035)),
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
