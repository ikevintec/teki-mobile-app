import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';

class ExpenseDetailsSection extends StatelessWidget {
  final dynamic expenseData;

  const ExpenseDetailsSection({super.key, required this.expenseData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Expense Details",
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Divider(
                color: Colors.blue.shade50,
              ),
              const SizedBox(
                height: 30,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expense Name",
                    style: GoogleFonts.raleway(
                      color: const Color(0xFFA0A0A3),
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${expenseData["expense-name"]}",
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF5D6571),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Expense Category",
                    style: GoogleFonts.raleway(
                      color: const Color(0xFFA0A0A3),
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${expenseData["expense-category"]}",
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF5D6571),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Bill Amount",
                          style: GoogleFonts.raleway(
                            color: const Color(0xFFA0A0A3),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.attach_money_outlined,
                              color: Color(0xFF5D6571),
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "${expenseData["amount"]}",
                              style: GoogleFonts.roboto(
                                color: const Color(0xFF5D6571),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Voucher No",
                          style: GoogleFonts.raleway(
                            color: const Color(0xFFA0A0A3),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${expenseData["voucher"]}",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF5D6571),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Start Date",
                          style: GoogleFonts.raleway(
                            color: const Color(0xFFA0A0A3),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${expenseData["start-date"]}",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF5D6571),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "End Date",
                          style: GoogleFonts.raleway(
                            color: const Color(0xFFA0A0A3),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${expenseData["end-date"]}",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF5D6571),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Status",
                          style: GoogleFonts.raleway(
                            color: const Color(0xFFA0A0A3),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${expenseData["status"]}",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF5D6571),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Expense Type",
                          style: GoogleFonts.raleway(
                            color: const Color(0xFFA0A0A3),
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Text(
                          "${expenseData["expense-type"]}",
                          style: GoogleFonts.roboto(
                            color: const Color(0xFF5D6571),
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        )
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(
                height: 30,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Warehouse",
                    style: GoogleFonts.raleway(
                      color: const Color(0xFFA0A0A3),
                      fontWeight: FontWeight.w500,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(
                    height: 5,
                  ),
                  Text(
                    "${expenseData["warehouse"]}",
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF5D6571),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 40,
              ),
              Text(
                "Bill Attachment",
                style: GoogleFonts.raleway(
                  color: const Color(0xFFA0A0A3),
                  fontWeight: FontWeight.w500,
                  fontSize: 18,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  SvgPicture.asset(
                    "assets/icons/icon_svg/pdf.svg",
                    width: 40,
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Expense Receipt",
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8A9099),
                            fontSize: 18),
                      ),
                      Text(
                        "256 kb",
                        style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: const Color(0xFF9C9CA1)),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
