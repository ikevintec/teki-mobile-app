import 'package:flutter/material.dart';
import 'package:flutter_easy_faq/flutter_easy_faq.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SupportFaqQuestionSection extends StatelessWidget {
  const SupportFaqQuestionSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Frequently Asked Questions",
          textAlign: TextAlign.center,
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w700,
            fontSize: MediaQuery.of(context).size.width * 0.06,
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        buildFaqSection(context, "What is inventory management?",
            "Inventory management is the process of overseeing and controlling the flow of goods into and out of a company's inventory. It involves tracking inventory levels, ordering and restocking inventory, and optimizing inventory turnover to ensure that goods are available when needed without excess stockpiling."),
        const SizedBox(
          height: 10,
        ),
        buildFaqSection(context, "Why is inventory management important?",
            "Effective inventory management is crucial for businesses to maintain optimal levels of stock to meet customer demand while minimizing carrying costs and the risk of stockouts. It helps in reducing excess inventory, improving cash flow, and enhancing overall operational efficiency."),
        const SizedBox(
          height: 10,
        ),
        buildFaqSection(context, "What are the different types of inventory?",
            "Inventories can be classified into several types including raw materials, work-in-progress (WIP), finished goods, and MRO (maintenance, repair, and operating supplies). Additionally, inventory can be categorized based on its value, such as ABC classification (high, medium, and low-value items)."),
        const SizedBox(
          height: 10,
        ),
        buildFaqSection(context, "How can I calculate inventory turnover?",
            "Inventory turnover is calculated by dividing the cost of goods sold (COGS) by the average inventory during a specific period. The formula is: Inventory Turnover = COGS / Average Inventory. A higher turnover ratio generally indicates better inventory management efficiency."),
        const SizedBox(
          height: 10,
        ),
        buildFaqSection(
            context,
            "What is safety stock and why is it important?",
            "Safety stock is the extra inventory a company keeps on hand to mitigate the risk of stockouts due to unexpected fluctuations in demand or supply chain disruptions. It acts as a buffer to ensure that products are available even when demand exceeds expectations or when there are delays in replenishment."),
        const SizedBox(
          height: 10,
        ),
        buildFaqSection(context, "How can I optimize inventory levels?",
            "Optimizing inventory levels involves balancing the costs associated with holding inventory (such as storage costs, obsolescence, and carrying costs) with the costs of stockouts or lost pos_sales. This can be achieved through techniques such as demand forecasting, economic order quantity (EOQ) calculations, and just-in-time (JIT) inventory management."),
        const SizedBox(
          height: 20,
        ),
      ],
    );
  }

  Padding buildFaqSection(
      BuildContext context, String question, String answer) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: EasyFaq(
          padding: const EdgeInsets.all(20),
          backgroundColor: Colors.white,
          collapsedIcon: SvgPicture.asset(
            "assets/icons/icon_svg/down-arrow.svg",
            width: 22,
          ),
          expandedIcon: SvgPicture.asset(
            "assets/icons/icon_svg/up-arrow.svg",
            width: 18,
          ),
          duration: const Duration(milliseconds: 300),
          questionTextStyle: GoogleFonts.raleway(
              fontWeight: FontWeight.w700, color: Colors.black87, fontSize: 15),
          anserTextStyle:
              GoogleFonts.nunito(color: Colors.black54, fontSize: 15),
          question: question,
          answer: answer),
    );
  }
}
