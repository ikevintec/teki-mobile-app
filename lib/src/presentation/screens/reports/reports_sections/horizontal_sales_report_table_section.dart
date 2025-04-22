import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/reports_model/sales_report_model.dart';

class HorizontalSalesReportTableSection extends StatelessWidget {
  const HorizontalSalesReportTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (salesReportModel.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    int totalStock = 0;
    int totalSold = 0;
    double totalAmount = 0;

    for (var data in salesReportModel) {
      totalStock += int.parse(data['stock']);
      totalSold += int.parse(data['sold']);
      totalAmount += double.parse(data['amount']);
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
                'Code',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Unit',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Stock',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Sold',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Amount',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
          ],
          rows: [
            ...salesReportModel.map(
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
                  DataCell(Text(data['code'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['unit'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['stock'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['sold'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['amount'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                ],
              ),
            ),
            // Total row
            DataRow(cells: [
              DataCell(Text('Total',
                  style: GoogleFonts.raleway(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              const DataCell(Text('')),
              DataCell(Text(totalStock.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalSold.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalAmount.toStringAsFixed(2),
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
