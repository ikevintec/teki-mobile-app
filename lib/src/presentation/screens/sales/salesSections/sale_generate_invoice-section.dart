import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';

class SaleGenerateInvoiceSection extends StatefulWidget {
  final dynamic products;

  const SaleGenerateInvoiceSection({super.key, required this.products});

  @override
  State<SaleGenerateInvoiceSection> createState() =>
      _SaleGenerateInvoiceSectionState();
}

class _SaleGenerateInvoiceSectionState
    extends State<SaleGenerateInvoiceSection> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Sale Invoice",
        ),
      ),
      body: Container(
        color: Colors.white70,
        child: ListView(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildInfoSection(
                title: "Invoice Details",
                children: [
                  _buildInfoRow(
                    title: "Date",
                    value: "03/16/2024",
                  ),
                  _buildInfoRow(
                    title: "Reference",
                    value: "S-5852987452",
                  ),
                  _buildInfoRow(
                    title: "Status",
                    value: "Completed",
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSectionTitle(title: "From")),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildContactInfo(
                name: "Richard Joseph",
                email: "info@example.com",
                phone: "+02 782 930 782",
                address: "Milton Street, New York, USA",
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSectionTitle(title: "To"),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildContactInfo(
                name: "Walk - in - Customer",
                email: "N/A",
                phone: "+02 202 396 228",
                address: "Kashba, New York, USA",
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: DataTable(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFFE2E4E7),
                        width: 0.5,
                      )),
                  columnSpacing: 60,
                  headingRowHeight: 50,
                  dataRowHeight: 50,
                  dividerThickness: 0,
                  headingRowColor:
                      WidgetStateProperty.all(const Color(0xFFEFF0F2)),
                  border: TableBorder.all(
                      color: const Color(0xFFE2E4E7),
                      borderRadius: BorderRadius.circular(8)),
                  columns: [
                    DataColumn(
                      label: Text(
                        'Products',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Batch No',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Unit',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Precio Unitario',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Qty',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Tax',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Descuento',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    DataColumn(
                      label: Text(
                        'Subtotal',
                        style: GoogleFonts.raleway(
                            textStyle:
                                const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                  rows: [
                    DataRow(
                      cells: [
                        DataCell(Text("3D Cannon Camera",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("30566205",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("pc",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("25.00",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("1",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("10%",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("5%",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("23.00",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(Text("Green Lemon",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("30566206",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("kg",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("70.00",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("1",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("0%",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("0%",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                        DataCell(Text("70.00",
                            style: GoogleFonts.nunito(
                                textStyle: const TextStyle()))),
                      ],
                    ),
                    DataRow(cells: [
                      DataCell(Text('Total:',
                          style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      DataCell(Text("8.00",
                          style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      DataCell(Text("10.00",
                          style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      DataCell(Text("93.00",
                          style: GoogleFonts.inter(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                    ]),
                    DataRow(
                      cells: [
                        DataCell(
                          Text(
                            'Order Discount =',
                            style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const DataCell(Text('')),
                        const DataCell(Text('')),
                        const DataCell(Text('')),
                        const DataCell(Text('')),
                        const DataCell(Text('')),
                        const DataCell(Text('')),
                        const DataCell(Text('-0.00')), // Set the value here
                      ],
                    ),
                    DataRow(cells: [
                      DataCell(Text('Order Tax =',
                          style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('+3 (2%)')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Total General:',
                          style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text("0.00")),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Paid Amount =',
                          style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('96.0')),
                    ]),
                    DataRow(cells: [
                      DataCell(Text('Due Amount =',
                          style: GoogleFonts.raleway(
                              textStyle: const TextStyle(
                                  fontWeight: FontWeight.bold)))),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('')),
                      const DataCell(Text('0.00')),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: "Sale Notes : ",
                    style: GoogleFonts.raleway(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
                TextSpan(
                    text: "N/A",
                    style: GoogleFonts.nunito(
                      color: Colors.grey,
                    ))
              ])),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: "Remarks : ",
                    style: GoogleFonts.raleway(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
                TextSpan(
                    text: "N/A",
                    style: GoogleFonts.nunito(
                      color: Colors.grey,
                    ))
              ])),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: "Created By : ",
                    style: GoogleFonts.raleway(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
                TextSpan(
                    text: "Richard Joseph",
                    style: GoogleFonts.nunito(
                      color: Colors.grey,
                    ))
              ])),
            ),
            const SizedBox(
              height: 10,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text.rich(TextSpan(children: [
                TextSpan(
                    text: "Email : ",
                    style: GoogleFonts.raleway(
                        color: Colors.black87, fontWeight: FontWeight.w500)),
                TextSpan(
                    text: "info@example.com",
                    style: GoogleFonts.nunito(
                      color: Colors.grey,
                    ))
              ])),
            ),
            const SizedBox(
              height: 30,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFF4581DD), Color(0xFF42DDAC)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.raleway(
              color: Colors.white70,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.nunito(
              color: Colors.white60,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.nunito(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({required String title}) {
    return Text(
      title,
      style: GoogleFonts.raleway(
        color: Colors.black87,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }

  Widget _buildContactInfo({
    required String name,
    required String email,
    required String phone,
    required String address,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildContactItem(title: "Name", value: name),
        _buildContactItem(title: "Email", value: email),
        _buildContactItem(title: "Phone", value: phone),
        _buildContactItem(title: "Address", value: address),
      ],
    );
  }

  Widget _buildContactItem({required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title:",
            style: GoogleFonts.raleway(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.nunito(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
