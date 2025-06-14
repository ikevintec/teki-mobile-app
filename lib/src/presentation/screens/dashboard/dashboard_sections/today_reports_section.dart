import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class TodayReportsSection extends StatelessWidget {
  const TodayReportsSection({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      margin: const EdgeInsets.only(left: 16, right: 16, top: 30),
      decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(1, 5), // changes position of shadow
            ),
          ],
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey.shade100),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Reportes diario",
                  style: GoogleFonts.raleway(
                      textStyle: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  )),
                ),
                IconButton(onPressed: null, icon: const Icon(Icons.arrow_forward_ios),iconSize: 15,),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                buildReports(
                  "Sales",
                  "20,000",
                  Colors.white,
                  "assets/icons/icon_svg/sale_service_icon.svg",
                  screenWidth,
                  context,
                ),
                buildReports(
                  "Purchase",
                  "20,000",
                  Colors.white,
                  "assets/icons/icon_svg/purchase_service_icon.svg",
                  screenWidth,
                  context,
                ),
                buildReports(
                  "Expense",
                  "10,000",
                  Colors.white,
                  "assets/icons/icon_svg/expenses_icon.svg",
                  screenWidth,
                  context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  GestureDetector buildReports(
    String title,
    String amount,
    Color reportColor,
    reportIcon,
    double screenWidth,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.analytics);
      },
      child: Container(
        width: screenWidth * 0.27,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: reportColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
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
                  child: SvgPicture.asset(
                    color: ColorSchema.primaryColor,
                    reportIcon,
                    width: 30,
                  )),
            ),
            const SizedBox(
              height: 4,
            ),
            Text(
              title,
              style: GoogleFonts.nunito(
                  textStyle: TextStyle(
                fontSize: MediaQuery.of(context).size.width * 0.035,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              )),
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
                  const TextSpan(text: "\$"),
                  TextSpan(text: amount),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
