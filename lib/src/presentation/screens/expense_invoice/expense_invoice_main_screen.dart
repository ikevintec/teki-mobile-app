import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/expense_invoice/expense_invoice_sections/expense_invoice_list_section.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_Field.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class ExpenseInvoiceMainScreen extends StatelessWidget {
  const ExpenseInvoiceMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.white,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: Text(
          "Expense Invoice",
          style: GoogleFonts.raleway(fontWeight: FontWeight.w500),
        ),
        automaticallyImplyLeading: false,
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: const Icon(
              Icons.chevron_left,
              size: 30,
            )),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
                onPressed: () {
                  Get.toNamed(AppRoutes.addExpenseInvoice);
                },
                icon: SvgPicture.asset(
                  "assets/icons/icon_svg/add_expense_icon.svg",
                  width: 25,
                )),
          )
        ],
      ),
      body: Container(
        color: Colors.white70,
        child: const Column(
          children: [
            SizedBox(
              height: 20,
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchField(hintText: "Search Expense Invoice"),
            ),
            SizedBox(
              height: 20,
            ),
            Expanded(child: ExpenseInvoiceListSection())
          ],
        ),
      ),
    );
  }
}
