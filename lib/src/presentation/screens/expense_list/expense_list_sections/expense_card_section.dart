import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ExpenseCardSection extends StatelessWidget {
  const ExpenseCardSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Claim Amount",
              style: GoogleFonts.raleway(
                color: const Color(0xFFA0A0A3),
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.attach_money_outlined,
                  color: Color(0xFF5D6571),
                  size: 26,
                ),
                Text(
                  "30,000",
                  style: GoogleFonts.roboto(
                    color: const Color(0xFF5D6571),
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildPendingItem("Pending", "2,900", Icons.pending_actions),
                _buildPendingItem(
                    "Approved", "5,000", Icons.check_circle_outline),
                _buildPendingItem("Rejected", "1,500", Icons.cancel_outlined),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingItem(String status, String amount, IconData iconData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(width: 5),
            Text(
              status,
              style: GoogleFonts.raleway(
                color: const Color(0xFFA0A0A3),
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            const Icon(
              Icons.attach_money_outlined,
              color: Color(0xFF5D6571),
              size: 20,
            ),
            Text(
              amount,
              style: GoogleFonts.roboto(
                color: const Color(0xFF5D6571),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
