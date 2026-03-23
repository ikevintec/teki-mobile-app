import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/reports_model/warehouse_report_model.dart';
import 'package:teki_app/src/presentation/widgets/toast/delete_toast.dart';

class HorizontalWarehouseReportTableSection extends StatefulWidget {
  const HorizontalWarehouseReportTableSection({super.key});

  @override
  State<HorizontalWarehouseReportTableSection> createState() =>
      _HorizontalWarehouseReportTableSectionState();
}

class _HorizontalWarehouseReportTableSectionState
    extends State<HorizontalWarehouseReportTableSection> {
  final List<String> list = <String>[
    'Edit',
    'Delete',
  ];
  late String dropdownValue;

  @override
  Widget build(BuildContext context) {
    if (warehouseReportModel.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black54),
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
                'SL',
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
                'Phone',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Email',
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            DataColumn(
              label: Text(
                'Address',
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
            ),
          ],
          rows: [
            ...warehouseReportModel.asMap().entries.map(
                  (entry) => DataRow(
                    cells: [
                      DataCell(Text(
                        '${entry.key + 1}',
                        style: GoogleFonts.nunito(textStyle: const TextStyle()),
                      )),
                      DataCell(Text(entry.value['warehouse'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['phone'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['email'],
                          style: GoogleFonts.nunito(
                              textStyle: const TextStyle()))),
                      DataCell(Text(entry.value['address'],
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
                            } else if (value == 'Delete') {
                              setState(() {
                                warehouseReportModel.removeAt(entry.key);
                              });
                              DeleteToast.showDeleteToast(
                                  context, entry.value["warehouse"]);
                            }
                          },
                          items: list.map((String choice) {
                            return DropdownMenuItem<String>(
                              value: choice,
                              child: Row(
                                children: [
                                  if (choice == 'Edit')
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2.0),
                                      child: SvgPicture.asset(
                                        "assets/icons/icon_svg/edit_icon.svg",
                                        width: 16,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  if (choice == 'Delete')
                                    SvgPicture.asset(
                                      "assets/icons/icon_svg/delete_icon.svg",
                                      width: 20,
                                      color: Colors.red,
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
                      ))
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
