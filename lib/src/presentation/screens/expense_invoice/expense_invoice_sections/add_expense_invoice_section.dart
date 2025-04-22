import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class AddExpenseInvoiceSection extends StatelessWidget {
  const AddExpenseInvoiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    const statusSelectedValue = "";

    List<String> statusItems = ["Paid", "Partial", "Due"];

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Add Expense Invoice"),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Customer Name",
                hint: "Enter Customer Name",
                inputType: TextInputType.name),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Company",
                hint: "Enter Your Company",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Phone",
                hint: "Enter Your Phone",
                inputType: TextInputType.phone),
            const SizedBox(
              height: 20,
            ),
            const DatePicker(labelText: "Date", hintText: "MM/DD/YYYY"),
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
                buttonName: "Add Expense Invoice",
                showToast: () {
                  SuccessToast.showSuccessToast(context, "Create Complete",
                      "Sale Invoice Created Complete");
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
