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
          borderRadius: BorderRadius.circular(16),
          color: Colors.blue.shade50.withOpacity(0.5)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Today Reports",
                  style: GoogleFonts.raleway(
                      textStyle: TextStyle(
                    fontSize: screenWidth * 0.05,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF333333),
                  )),
                ),
                InkWell(
                  onTap: () {
                    Get.toNamed(AppRoutes.analytics);
                  },
                  child: Text(
                    "View",
                    style: GoogleFonts.raleway(
                        textStyle: TextStyle(
                      color: ColorSchema.primaryColor.withOpacity(0.7),
                      fontSize: screenWidth * 0.04,
                      fontWeight: FontWeight.w600,
                    )),
                  ),
                )
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
                  Colors.lightBlueAccent.shade100.withOpacity(0.25),
                  "assets/icons/icon_svg/sale_service_icon.svg",
                  screenWidth,
                  context,
                ),
                buildReports(
                  "Purchase",
                  "20,000",
                  Colors.purple.shade100.withOpacity(0.25),
                  "assets/icons/icon_svg/purchase_service_icon.svg",
                  screenWidth,
                  context,
                ),
                buildReports(
                  "Expense",
                  "10,000",
                  Colors.teal.shade100.withOpacity(0.25),
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
          borderRadius: BorderRadius.circular(8),
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
                    reportIcon,
                    width: 20,
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
