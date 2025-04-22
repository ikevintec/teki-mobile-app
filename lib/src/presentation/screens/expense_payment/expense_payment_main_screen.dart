import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class ExpensePaymentMainScreen extends StatefulWidget {
  const ExpensePaymentMainScreen({super.key});

  @override
  State<ExpensePaymentMainScreen> createState() =>
      _ExpensePaymentMainScreenState();
}

class _ExpensePaymentMainScreenState extends State<ExpensePaymentMainScreen> {
  String statusSelectedValue = "";
  String paymentSelectedValue = "";

  List<String> statusItems = ["Paid", "Unpaid", "Draft"];
  List<String> paymentItems = ["Card", "Cash", "Bank"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Expense Payment"),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Card Number",
                hint: "**** **** **** 5600",
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Voucher No",
                hint: "748",
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Amount",
                hint: "4,470",
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            const DatePicker(labelText: "Date & CVV", hintText: "MM/DD/YYYY"),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldSection(
                label: "Status",
                hint: "Select Status",
                items: statusItems,
                selectionItem: statusSelectedValue),
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
                labelText: "Purchase Note",
                hintText: "Enter Your Text Here..."),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Submit",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Payment Complete", "Expense Payment Complete");
                }),
            const SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
