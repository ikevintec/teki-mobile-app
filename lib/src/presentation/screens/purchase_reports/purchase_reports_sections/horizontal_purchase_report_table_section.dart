import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/reports_model/purchase_report_model.dart';

class HorizontalPurchaseReportTableSection extends StatelessWidget {
  const HorizontalPurchaseReportTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (purchaseReportModel.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: GoogleFonts.raleway(
              textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black54)),
        ),
      );
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
                'Company',
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
          ],
          rows: [
            ...purchaseReportModel.map(
              (data) => DataRow(
                cells: [
                  DataCell(Text(
                    data['date'],
                    style: GoogleFonts.nunito(textStyle: const TextStyle()),
                  )),
                  DataCell(Text(data['company'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['name'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                  DataCell(Text(data['unit'],
                      style: GoogleFonts.nunito(textStyle: const TextStyle()))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
