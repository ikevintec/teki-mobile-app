import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/reports_model/payment_report_model.dart';

class HorizontalPaymentReportTableSection extends StatelessWidget {
  const HorizontalPaymentReportTableSection({super.key});

  @override
  Widget build(BuildContext context) {
    if (paymentReportModel.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
        ),
      );
    }

    double totalAmount = 0;

    for (var data in paymentReportModel) {
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
                'Reference No',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Invoice No',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Paid by',
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
            ...paymentReportModel.map(
              (data) => DataRow(
                cells: [
                  DataCell(Text(
                    data['date'],
                    style: GoogleFonts.roboto(textStyle: const TextStyle()),
                  )),
                  DataCell(Text(data['warehouse'],
                      style: GoogleFonts.roboto(textStyle: const TextStyle()))),
                  DataCell(Text(data['reference'],
                      style: GoogleFonts.roboto(textStyle: const TextStyle()))),
                  DataCell(Text(data['invoice'],
                      style: GoogleFonts.roboto(textStyle: const TextStyle()))),
                  DataCell(Text(data['paid'],
                      style: GoogleFonts.roboto(textStyle: const TextStyle()))),
                  DataCell(Text(data['status'],
                      style: GoogleFonts.roboto(textStyle: const TextStyle()))),
                  DataCell(Text(data['amount'],
                      style: GoogleFonts.roboto(textStyle: const TextStyle()))),
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
              const DataCell(Text('')),
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
