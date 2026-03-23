import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class AddPaymentSection extends StatelessWidget {
  final dynamic payment;

  const AddPaymentSection({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    const paymentSelectedValue = "";

    List<String> paymentItems = ["Card", "Bank", "Cash"];

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
                  "Add Payment",
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
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ListView(
            children: [
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Received Amount",
                  hint: payment.value["grandTotal"],
                  inputType: TextInputType.number),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Paying Amount",
                  hint: payment.value["paid"],
                  inputType: TextInputType.number),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Charge",
                  hint: payment.value["due"],
                  inputType: TextInputType.number),
              const SizedBox(
                height: 20,
              ),
              const TextFieldSection(
                  label: "Card Number",
                  hint: "XXXX XXXX XXXX 9293",
                  inputType: TextInputType.number),
              const SizedBox(
                height: 20,
              ),
              const DatePicker(
                  labelText: "Expired Date", hintText: "MM/DD/YYYY"),
              const SizedBox(
                height: 20,
              ),
              DropdownFormFieldSection(
                  label: "Payment Type",
                  hint: "Select Type",
                  items: paymentItems,
                  selectionItem: paymentSelectedValue),
              const SizedBox(
                height: 20,
              ),
              const TextFieldMaxLineSection(
                  labelText: "Sale Note", hintText: "Type Sales Note"),
              const SizedBox(
                height: 20,
              ),
              CustomElevatedButton(
                  buttonName: "Pay Now",
                  showToast: () {
                    SuccessToast.showSuccessToast(context, "Payment Complete",
                        "${payment.value["supplierName"]} Payment Complete");
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
