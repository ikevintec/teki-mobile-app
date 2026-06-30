import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/pos_sales/pos_sales_sections/pay_complete_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/search_field/custom_search_Field.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_action_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class PosBillsSection extends StatefulWidget {
  final dynamic product;

  const PosBillsSection({super.key, required this.product});

  @override
  State<PosBillsSection> createState() => _PosBillsSectionState();
}

class _PosBillsSectionState extends State<PosBillsSection> {
  String customerSelectedValue = "";
  String billerSelectedValue = "";
  String warehouseSelectedValue = "";
  String paymentTypeSelectionValue = "";

  List<String> customerItems = [
    "Shane Watson",
    "David Warner",
    "David Miller",
    "Hashim Amla",
    "Imran Tahir",
    "JP Duminy",
    "Kagiso Rabada",
    "Stuart Broad"
  ];
  List<String> billerItems = [
    "Shane Watson",
    "David Warner",
    "David Miller",
    "Hashim Amla",
    "Imran Tahir",
    "JP Duminy",
    "Kagiso Rabada",
    "Stuart Broad"
  ];
  List<String> warehouseItems = [
    "Warehouse 1",
    "Warehouse 2",
    "Warehouse 3",
    "Warehouse 4",
    "Warehouse 5"
  ];
  List<String> paymentTypeItems = ["Card", "Cash", "Bank"];

  late List<int> quantities;
  late List<double> subtotals;
  double totalSubtotals = 0;

  @override
  void initState() {
    super.initState();
    quantities = List<int>.filled(widget.product.length, 1);
    subtotals = List<double>.filled(widget.product.length, 0);
    _calculateSubtotals();
  }

  void _calculateSubtotals() {
    for (int i = 0; i < widget.product.length; i++) {
      double productTax = double.parse(widget.product[i]["product-tax"]);
      double productDiscount =
          double.parse(widget.product[i]["product-discount"]);
      double price = double.parse(widget.product[i]['price']);
      subtotals[i] = quantities[i] * (price + productTax - productDiscount);
      double totalSubtotal =
          subtotals.fold(0, (prev, element) => prev + element);
      setState(() {
        totalSubtotals = totalSubtotal;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: CustomAppBar(navigateName: "POS Bills")),
      body: Container(
        color: Colors.white70,
        child: ListView(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: CustomSearchField(
                  hintText: "Scan/ Search Product By Code/ Name"),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  const Expanded(
                    child: TextFieldSection(
                        label: "Reference",
                        hint: "Enter Reference No",
                        inputType: TextInputType.name),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: DropdownFormFieldSection(
                        label: "Warehouse",
                        hint: "Select Warehouse",
                        items: warehouseItems,
                        selectionItem: warehouseSelectedValue),
                  ),
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownFormFieldActionSection(
                  label: "Customer",
                  hint: "Select Customer",
                  items: customerItems,
                  selectionItem: customerSelectedValue,
                  checkValue: "customer",
                  addTitle: "Add Customer"),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DropdownFormFieldSection(
                  label: "Biller",
                  hint: "Select Biller",
                  items: billerItems,
                  selectionItem: billerSelectedValue),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "POS Products Item",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 20)),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            if (widget.product.isEmpty)
              Center(
                child: Column(
                  children: [
                    Text(
                      'No products item available',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade400),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    CustomElevatedButton(
                        buttonName: "Go POS",
                        showToast: () {
                          Get.toNamed(AppRoutes.sales);
                        })
                  ],
                ),
              )
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: DataTable(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(
                            color: const Color(0xFFE2E4E7), width: 0.5)),
                    columnSpacing: 35,
                    headingRowHeight: 50,
                    dataRowHeight: 70,
                    headingRowColor:
                        WidgetStateProperty.all(const Color(0xFFEFF0F2)),
                    dividerThickness: 0,
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
                          'Tax',
                          style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Discount',
                          style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Price',
                          style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Quantity',
                          style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Sub Total',
                          style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Action',
                          style: GoogleFonts.raleway(
                              textStyle:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        numeric: true,
                      ),
                    ],
                    rows: List.generate(
                      widget.product.length,
                      (index) {
                        return DataRow(
                          cells: [
                            DataCell(Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(widget.product[index]['name'],
                                    style: GoogleFonts.raleway(
                                        textStyle: const TextStyle(
                                            fontWeight: FontWeight.w600))),
                                const SizedBox(
                                  height: 4,
                                ),
                                Text(
                                  "Batch :  ${widget.product[index]["barcode"]}",
                                  style: GoogleFonts.roboto(
                                      textStyle: TextStyle(
                                          color: Colors.grey.shade500)),
                                )
                              ],
                            )),
                            DataCell(Text(
                                "${widget.product[index]["product-tax"]}%",
                                style: GoogleFonts.roboto(
                                    textStyle: const TextStyle()))),
                            DataCell(Text(
                                "${widget.product[index]["product-discount"]}%",
                                style: GoogleFonts.roboto(
                                    textStyle: const TextStyle()))),
                            DataCell(Text("\$${widget.product[index]['price']}",
                                style: GoogleFonts.roboto(
                                    textStyle: const TextStyle()))),
                            DataCell(Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (quantities[index] > 1) {
                                      setState(() {
                                        quantities[index]--;
                                        _calculateSubtotals();
                                      });
                                    }
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: const Color(0xFFC1D5FE),
                                            width: 2)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: SvgPicture.asset(
                                        "assets/icons/icon_svg/minus_button.svg",
                                        width: 12,
                                        color: const Color(0xFFC1D5FE),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  "${quantities[index]}",
                                  style: GoogleFonts.roboto(
                                      textStyle: const TextStyle(fontSize: 18)),
                                ),
                                const SizedBox(
                                  width: 10,
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      quantities[index]++;
                                      _calculateSubtotals();
                                    });
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        color: const Color(0xFF2C6AE5),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(
                                            color: const Color(0xFF2C6AE5),
                                            width: 2)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: SvgPicture.asset(
                                        "assets/icons/icon_svg/plus_button.svg",
                                        width: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )),
                            DataCell(Text("\$${subtotals[index]}",
                                style: GoogleFonts.roboto(
                                    textStyle: const TextStyle()))),
                            DataCell(
                              GestureDetector(
                                onTap: () {
                                  showConfirmationDialog(context, () {
                                    setState(() {
                                      widget.product.removeAt(index);
                                    });
                                  }, "Are you sure you want to remove this item?");
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                          color: Colors.red, width: 1)),
                                  child: Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: SvgPicture.asset(
                                      "assets/icons/icon_svg/close_icon.svg",
                                      width: 12,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            const SizedBox(
              height: 80,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(
                color: Color(0xFFC1D5FE),
              ),
            ),
            buildTotalSection(),
            const SizedBox(
              height: 20,
            ),
            buildGrandTotalSection(),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  buildElevatedButton("Reset", const Color(0xFF32C98D)),
                  buildElevatedButton("Save Draft", const Color(0xFFDF7272)),
                  buildElevatedButton("Payment", const Color(0xFF2C6AE5))
                ],
              ),
            ),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Padding buildGrandTotalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: const Color(0xFFC1D5FE), width: 1)),
        child: Text(
          "Grand Total : \$$totalSubtotals",
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(fontSize: 24, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  SingleChildScrollView buildTotalSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 50,
        headingRowHeight: 30,
        dataRowHeight: 50,
        border: TableBorder.all(
          color: Colors.white,
        ),
        dividerThickness: 0,
        columns: [
          DataColumn(
            label: Text("Total",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          DataColumn(
            label: Text("Item",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          DataColumn(
            label: Text("Tax/%",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          DataColumn(
            label: Text("Discount/%",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold))),
          ),
          DataColumn(
            label: Text("Shipping/\$",
                style: GoogleFonts.raleway(
                    textStyle: const TextStyle(fontWeight: FontWeight.bold))),
          ),
        ],
        rows: [
          DataRow(cells: [
            DataCell(Text(
              "\$$totalSubtotals",
              style: GoogleFonts.roboto(textStyle: const TextStyle()),
            )),
            DataCell(Text(
              "${widget.product.length}",
              style: GoogleFonts.roboto(textStyle: const TextStyle()),
            )),
            DataCell(buildTextField("Enter Tax")),
            DataCell(buildTextField("Discount")),
            DataCell(buildTextField("Shipping"))
          ])
        ],
      ),
    );
  }

  ElevatedButton buildElevatedButton(String buttonName, Color bgColor) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(5))),
      onPressed: () {
        if (buttonName == "Reset") {
          showConfirmationDialog(context, () {
            setState(() {
              widget.product.clear();
              totalSubtotals = 0;
            });
          }, "Are you sure you want to reset POS item?");
        } else if (buttonName == "Payment") {
          buildPaymentModal(
              context, paymentTypeSelectionValue, paymentTypeItems);
        } else if (buttonName == "Save Draft") {
          SuccessToast.showSuccessToast(
              context, "POS Bills Save Complete", "Saved Complete");
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: Text(
          buttonName,
          style: GoogleFonts.raleway(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  TextField buildTextField(String hint) {
    return TextField(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        fillColor: const Color(0xFFFCFCFC),
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
            textStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        )),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: TextInputType.number,
    );
  }

  void buildPaymentModal(BuildContext context, String paymentTypeSelectionValue,
      List<String> paymentTypeItems) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        elevation: 0,
        child: Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 12.0),
                      child: Text(
                        "Make Payment",
                        style: GoogleFonts.raleway(
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(color: Colors.red, width: 1)),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            "assets/icons/icon_svg/close_icon.svg",
                            width: 10,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(
                  height: 30,
                ),
                const TextFieldSection(
                    label: "Received Amount",
                    hint: "\$4995.00",
                    inputType: TextInputType.number),
                const SizedBox(
                  height: 20,
                ),
                const TextFieldSection(
                    label: "Paying Amount",
                    hint: "\$3595.00",
                    inputType: TextInputType.number),
                const SizedBox(
                  height: 20,
                ),
                const TextFieldSection(
                    label: "Change",
                    hint: "\$0.00",
                    inputType: TextInputType.number),
                const SizedBox(
                  height: 20,
                ),
                DropdownFormFieldSection(
                    label: "Payment Type",
                    hint: "Select Type",
                    items: paymentTypeItems,
                    selectionItem: paymentTypeSelectionValue),
                const SizedBox(
                  height: 20,
                ),
                const TextFieldSection(
                    label: "Card Number",
                    hint: "xxxx xxxx xxxx 3454",
                    inputType: TextInputType.number),
                const SizedBox(
                  height: 20,
                ),
                const DatePicker(
                  labelText: "Expired Date",
                  hintText: "MM/DD/YYYY",
                ),
                const SizedBox(
                  height: 20,
                ),
                const TextFieldMaxLineSection(
                    labelText: "Sale Note", hintText: "Type Sales Note..."),
                const SizedBox(
                  height: 20,
                ),
                SizedBox(
                  width: double.infinity,
                  child: CustomElevatedButton(
                      buttonName: "Pay Now",
                      showToast: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PayCompleteSection(
                                identificador: "Identificador"),
                          ),
                        );
                      }),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showConfirmationDialog(
      BuildContext context, Function onYesPressed, subText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        shadowColor: Colors.white,
        title: Text(
          "Confirmation",
          style: GoogleFonts.raleway(
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        content: Text(
          subText,
          style: GoogleFonts.roboto(),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              onYesPressed();
              Navigator.of(context).pop();
            },
            child: const Text("Yes"),
          ),
        ],
      ),
    );
  }
}
