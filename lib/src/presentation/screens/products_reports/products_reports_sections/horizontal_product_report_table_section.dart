import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/reports_model/product_report_model.dart';

class HorizontalProductReportTableSection extends StatelessWidget {
  const HorizontalProductReportTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (productReportModel.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    int totalPurchaseQty = 0;
    double totalPurchaseAmount = 0;
    int totalSoldQty = 0;
    double totalSoldAmount = 0;

    for (var data in productReportModel) {
      totalPurchaseQty += int.parse(data['purchasedQty']);
      totalPurchaseAmount += double.parse(data['purchasedAmount']);
      totalSoldQty += int.parse(data['soldQty']);
      totalSoldAmount += double.parse(data['soldAmount']);
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
          dividerThickness: 0.0,
          border: TableBorder.all(
              color: const Color(
                0xFFE2E4E7,
              ),
              borderRadius: BorderRadius.circular(8)),
          columns: [
            DataColumn(
              label: Text(
                'Date',
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
                'Name',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Purchased Qty',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Purchased Amount',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Sold Qty',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Sold Amount',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
          ],
          rows: [
            ...productReportModel.map(
              (data) => DataRow(
                cells: [
                  DataCell(Text(
                    data['date'],
                    style: GoogleFonts.nunito(textStyle: const TextStyle()),
                  )),
                  DataCell(Text(data['warehouse'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['name'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['purchasedQty'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['purchasedAmount'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['soldQty'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['soldAmount'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
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
              DataCell(Text(totalPurchaseQty.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalPurchaseAmount.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalSoldQty.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalSoldAmount.toStringAsFixed(2),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
            ]),
          ],
        ),
      ),
    );
  }
}
