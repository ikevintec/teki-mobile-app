import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/sales_model/sales_list_model.dart';
import 'package:teki_app/src/presentation/screens/purchase/purchase_sections/add_payment_section.dart';
import 'package:teki_app/src/presentation/screens/sales/salesSections/edit_sales_section.dart';
import 'package:teki_app/src/presentation/screens/sales/salesSections/sale_generate_invoice-section.dart';
import 'package:teki_app/src/presentation/screens/sales/salesSections/sale_view_payment_card_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class HorizontalSalesTableSection extends StatefulWidget {
  const HorizontalSalesTableSection({super.key});

  @override
  State<HorizontalSalesTableSection> createState() =>
      _HorizontalSalesTableSectionState();
}

class _HorizontalSalesTableSectionState
    extends State<HorizontalSalesTableSection> {
  final List<String> list = <String>[
    'Edit',
    "Invoice",
    "Payment",
    "View Payment",
    'Delete',
  ];

  @override
  Widget build(BuildContext context) {
    if (salesListModel.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    int totalGrandSum = 0;
    int totalPaidSum = 0;
    double totalDueSum = 0;

    for (var data in salesListModel) {
      totalGrandSum += int.parse(data['grandTotal']);
      totalPaidSum += int.parse(data['paid']);
      totalDueSum += double.parse(data['due']);
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: DataTable(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E4E7), width: 0.5)),
          columnSpacing: 60,
          headingRowHeight: 50,
          dataRowHeight: 50,
          headingRowColor: WidgetStateProperty.all(const Color(0xFFEFF0F2)),
          dividerThickness: 0,
          border: TableBorder.all(
              color: const Color(0xFFE2E4E7),
              borderRadius: BorderRadius.circular(8)),
          columns: [
            DataColumn(
              label: Text(
                'SL',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Date',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Reference',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Customer',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Warehouse',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Status',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Biller',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Payment',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Grand Total',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Paid',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Due',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
          ],
          rows: [
            ...salesListModel.asMap().entries.map(
                  (entry) => DataRow(
                    cells: [
                      DataCell(Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.nunito(textStyle: const TextStyle()),
                      )),
                      DataCell(Text(entry.value['date'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['reference'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['customerName'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['warehouse'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: Color(entry.value["statusColor"]),
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(entry.value['status'],
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))),
                      )),
                      DataCell(Text(entry.value['billerName'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: Color(entry.value["paymentColor"]),
                            borderRadius: BorderRadius.circular(5)),
                        child: Text(entry.value['payment'],
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600))),
                      )),
                      DataCell(Text(entry.value['grandTotal'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['paid'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['due'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFFC1D5FE), width: 1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: DropdownButton(
                          dropdownColor: Colors.white,
                          borderRadius: BorderRadius.circular(5),
                          alignment: Alignment.center,
                          hint: Text(
                            "Action",
                            style: GoogleFonts.nunito(
                              color: const Color(0xFF696AE9),
                            ),
                          ),
                          onChanged: (String? value) {
                            if (value == 'Edit') {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          EditSalesSection(sales: entry)));
                            } else if (value == "Invoice") {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SaleGenerateInvoiceSection(
                                            products: entry,
                                          )));
                            } else if (value == "Payment") {
                              buildModalBottomSheet(context, entry);
                            } else if (value == "View Payment") {
                              _buildDialogModal(context, entry);
                            } else if (value == 'Delete') {
                              DeleteToast.showDeleteToast(
                                  context, entry.value["customerName"]);
                              setState(() {
                                salesListModel.removeAt(entry.key);
                              });
                            }
                          },
                          items: list.map((String choice) {
                            return DropdownMenuItem<String>(
                              value: choice,
                              child: Row(
                                children: [
                                  if (choice == 'Edit')
                                    SvgPicture.asset(
                                      "assets/icons/icon_svg/edit_icon.svg",
                                      color: Colors.blue,
                                      width: 16,
                                    ),
                                  if (choice == 'Invoice')
                                    SvgPicture.asset(
                                      "assets/icons/icon_svg/invoice_icon.svg",
                                      color: Colors.indigo,
                                      width: 16,
                                    ),
                                  if (choice == 'Payment')
                                    SvgPicture.asset(
                                      "assets/icons/icon_svg/add_payment.svg",
                                      color: const Color(0xFF950FF6),
                                      width: 18,
                                    ),
                                  if (choice == "View Payment")
                                    SvgPicture.asset(
                                      "assets/icons/icon_svg/view_payment.svg",
                                      color: Colors.orange,
                                      width: 18,
                                    ),
                                  if (choice == 'Delete')
                                    SvgPicture.asset(
                                      "assets/icons/icon_svg/delete_icon.svg",
                                      color: Colors.red,
                                      width: 18,
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    choice,
                                    style: GoogleFonts.nunito(
                                        textStyle: const TextStyle(
                                            color: Colors.black87)),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: Color(0xFF2C6AE5),
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
            DataRow(cells: [
              DataCell(Text('Total',
                  style: GoogleFonts.raleway(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              DataCell(Text(totalGrandSum.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalPaidSum.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalDueSum.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              const DataCell(Text('')),
            ])
          ],
        ),
      ),
    );
  }

  void _buildDialogModal(BuildContext context, dynamic payment) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        child: SaleViewPaymentCardSection(
          payment: payment,
        ),
      ),
    );
  }

  void buildModalBottomSheet(BuildContext context, entry) {
    showModalBottomSheet(
      backgroundColor: Colors.white,
      elevation: 0,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      context: context,
      builder: (_) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.9,
          child: AddPaymentSection(payment: entry),
        );
      },
    );
  }
}
