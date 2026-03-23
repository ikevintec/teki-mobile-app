import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/purchase/purchase_sections/horizontal_purchase_table_section.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/start_end_date_picker_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class PurchaseMainScreen extends StatelessWidget {
  const PurchaseMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          elevation: 0,
          surfaceTintColor: Colors.white,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: Text(
            "Manage Purchase",
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
                    Get.toNamed(AppRoutes.purchaseReturn);
                  },
                  icon: SvgPicture.asset(
                    "assets/icons/icon_svg/purchase_return.svg",
                    width: 25,
                  )),
            )
          ]),
      body: Container(
        color: Colors.white70,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: StartEndDatePickerSection(),
            ),
            const SizedBox(
              height: 20,
            ),
            Center(
              child: CustomElevatedButton(
                  buttonName: "Generate Purchase",
                  showToast: () {
                    SuccessToast.showSuccessToast(context, "Generate Complete",
                        "Purchase List Generate Complete");
                  }),
            ),
            const SizedBox(
              height: 40,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Manage Purchase List",
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
                    child: HorizontalPurchaseTableSection())),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
