import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class ServicesSection extends StatelessWidget {
  const ServicesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildServices(
                  context,
                  "Products",
                  "assets/icons/icon_image/products.png",
                  Colors.grey.shade100,
                  Colors.purple, () {
                Get.toNamed(AppRoutes.products);
              }),
              buildServices(
                  context,
                  "Trading",
                  "assets/icons/icon_image/trading.png",
                  Colors.grey.shade100,
                  Colors.green, () {
                Get.toNamed(AppRoutes.sales);
              }),
              buildServices(
                  context,
                  "Expenses",
                  "assets/icons/icon_image/expense.png",
                  Colors.grey.shade100,
                  Colors.orange, () {
                Get.toNamed(AppRoutes.expense);
              }),
              buildServices(context, "POS", "assets/icons/icon_image/pos.png",
                  Colors.grey.shade100, Colors.amber, () {
                Get.toNamed(AppRoutes.posSales);
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
                  Colors.grey.shade100,
                  Colors.red, () {
                Get.toNamed(AppRoutes.sales);
              }),
              buildServices(
                  context,
                  "Purchase",
                  "assets/icons/icon_image/purchase_list.png",
                  Colors.grey.shade100,
                  Colors.cyan, () {
                Get.toNamed(AppRoutes.purchase);
              }),
              buildServices(
                  context,
                  "Product",
                  "assets/icons/icon_image/products_list.png",
                  Colors.grey.shade100,
                  Colors.teal, () {
                Get.toNamed(AppRoutes.products);
              }),
              buildServices(
                  context,
                  "Expense",
                  "assets/icons/icon_image/expense_list.png",
                  Colors.grey.shade100,
                  Colors.pink, () {
                Get.toNamed(AppRoutes.expenseList);
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
                  Colors.grey.shade100,
                  Colors.brown, () {
                Get.toNamed(AppRoutes.management);
              }),
              buildServices(
                  context,
                  "Report",
                  "assets/icons/icon_image/reports.png",
                  Colors.grey.shade100,
                  Colors.indigo, () {
                Get.toNamed(AppRoutes.report);
              }),
              buildServices(
                  context,
                  "Warehouse",
                  "assets/icons/icon_image/warehouse.png",
                  Colors.grey.shade100,
                  Colors.lime, () {
                Get.toNamed(AppRoutes.warehouse);
              }),
              buildServices(
                  context,
                  "Peoples",
                  "assets/icons/icon_image/customer.png",
                  Colors.grey.shade100,
                  Colors.blueGrey, () {
                Get.toNamed(AppRoutes.customer);
              }),
            ],
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
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                      color: serviceColor,
                      borderRadius: BorderRadius.circular(50)),
                ),
                ImageIcon(
                  AssetImage(
                    serviceIcon,
                  ),
                  color: serviceImageColor,
                  size: 35,
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
}
