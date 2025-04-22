import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/reports_model/stock_report_model.dart';

class HorizontalStockReportTableSection extends StatelessWidget {
  const HorizontalStockReportTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (stockReportModel.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    int totalOpeningStock = 0;
    int totalReceived = 0;
    int total = 0;
    int totalSales = 0;
    int totalClosingStock = 0;

    for (var data in stockReportModel) {
      totalOpeningStock += int.parse(data['openingStock']);
      totalReceived += int.parse(data['received']);
      total += int.parse(data['total']);
      totalSales += int.parse(data['pos_sales']);
      totalClosingStock += int.parse(data['closingStock']);
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
            borderRadius: BorderRadius.circular(8)
          ),
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
                'Unit',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Opening Stock',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Received',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Total',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Sales',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
            DataColumn(
              label: Text(
                'Closing Stock',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              numeric: true,
            ),
          ],
          rows: [
            ...stockReportModel.map(
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
                  DataCell(Text(data['unit'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['openingStock'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['received'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['total'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['pos_sales'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['closingStock'],
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
              const DataCell(Text('')),
              DataCell(Text(totalOpeningStock.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalReceived.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(total.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalSales.toString(),
                  style: GoogleFonts.inter(
                      textStyle:
                          const TextStyle(fontWeight: FontWeight.bold)))),
              DataCell(Text(totalClosingStock.toString(),
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
