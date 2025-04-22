import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UpdateSaleInvoiceSection extends StatelessWidget {
  final dynamic saleInvoice;

  const UpdateSaleInvoiceSection({super.key, required this.saleInvoice});

  @override
  Widget build(BuildContext context) {
    const statusSelectedValue = "";

    List<String> statusItems = ["Paid", "Partial", "Due"];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "Edit Sale Invoice",
                  style: GoogleFonts.raleway(
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      color: Color(0xFF444444),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(
                  Icons.close,
                  size: 26,
                  color: Color(0xFF444444),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        ),
        Divider(
          color: Colors.grey.shade300,
        ),
        Expanded(
            child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Customer Name",
                  hint: saleInvoice["customerName"],
                  inputType: TextInputType.name),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Company",
                  hint: saleInvoice["company"],
                  inputType: TextInputType.text),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Phone",
                  hint: saleInvoice["customerPhone"],
                  inputType: TextInputType.phone),
              const SizedBox(
                height: 20,
              ),
              DatePicker(labelText: "Date", hintText: saleInvoice["date"]),
              const SizedBox(
                height: 20,
              ),
              DropdownFormFieldSection(
                  label: "Payment Status",
                  hint: "Select Payment Status",
                  items: statusItems,
                  selectionItem: statusSelectedValue),
              const SizedBox(
                height: 20,
              ),
              CustomElevatedButton(
                  buttonName: "Update Sale Invoice",
                  showToast: () {
                    SuccessToast.showSuccessToast(context, "Update Complete",
                        "${saleInvoice["customerName"]} Update Complete");
                  }),
              const SizedBox(
                height: 20,
              )
            ],
          ),
        ))
      ],
    );
  }
}
