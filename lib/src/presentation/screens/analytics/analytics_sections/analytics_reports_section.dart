import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AnalyticsReportSection extends StatelessWidget {
  const AnalyticsReportSection({super.key});

  @override
  Widget build(BuildContext context) {
    double cardWidth = MediaQuery.of(context).size.width; // Adjust as needed

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              buildReports(
                cardWidth,
                Colors.blue.shade50.withOpacity(0.6),
                "Sales",
                "20,000",
                "assets/icons/icon_image/sales.png",
                Colors.blue,
                Colors.blue.shade300,
                Colors.blue.shade50.withOpacity(0.6),
              ),
              const SizedBox(
                width: 10,
              ),
              buildReports(
                cardWidth,
                Colors.green.shade50.withOpacity(0.6),
                "Purchase",
                "20,000",
                "assets/icons/icon_image/purchase.png",
                Colors.green,
                Colors.green.shade300,
                Colors.green.shade50.withOpacity(0.6),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              buildReports(
                cardWidth,
                Colors.purple.shade50.withOpacity(0.6),
                "Expense",
                "20,000",
                "assets/icons/icon_image/expense.png",
                Colors.purple,
                Colors.purple.shade300,
                Colors.purple.shade50.withOpacity(0.6),
              ),
              const SizedBox(
                width: 10,
              ),
              buildReports(
                cardWidth,
                Colors.orange.shade50.withOpacity(0.6),
                "Profit",
                "20,000",
                "assets/icons/icon_image/profit.png",
                Colors.orange,
                Colors.orange.shade300,
                Colors.orange.shade50.withOpacity(0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Expanded buildReports(
    double cardWidth,
    Color reportColor,
    String reportTitle,
    String balance,
    String reportIcon,
    Color reportIconColor,
    Color balanceColor,
    Color splashPressedColor,
  ) {
    return Expanded(
      child: InkWell(
        splashColor: splashPressedColor,
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Card(
          color: reportColor,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Stack(alignment: Alignment.center, children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white54,
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  ImageIcon(
                    AssetImage(
                      reportIcon,
                    ),
                    color: reportIconColor,
                    size: 30,
                  )
                ]),
                SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportTitle,
                        style: GoogleFonts.raleway(
                          textStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: cardWidth * 0.04,
                            color: const Color(0xFF555555),
                          ),
                        ),
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Text(
                        balance,
                        style: GoogleFonts.nunito(
                          textStyle: TextStyle(
                            color: balanceColor,
                            fontSize: cardWidth * 0.05,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
