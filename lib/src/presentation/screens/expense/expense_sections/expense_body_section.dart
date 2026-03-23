import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class ExpenseBodySection extends StatefulWidget {
  const ExpenseBodySection({super.key});

  @override
  State<ExpenseBodySection> createState() => _ExpenseBodySectionState();
}

class _ExpenseBodySectionState extends State<ExpenseBodySection> {
  String warehouseSelectedValue = "";
  String expenseTypeSelectedValue = "";
  String categorySelectedValue = "";

  List<String> warehouseItems = [
    "United State",
    "Canada",
    "Mexico",
    "France",
    "Germany"
  ];
  List<String> expenseTypeItems = ["Direct Expense", "Draft Expense"];
  List<String> categoryItems = [
    "Electrics",
    "Shoe",
    "Cloth",
    "Bag",
    "Computer",
    "Laptop"
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      child: ListView(
        children: [
          const SizedBox(
            height: 20,
          ),
          const DatePicker(labelText: "Date", hintText: "MM/DD/YYYY"),
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
              label: "Amount", hint: "4,470", inputType: TextInputType.number),
          const SizedBox(
            height: 20,
          ),
          DropdownFormFieldSection(
              label: "Warehouse",
              hint: "Select Warehouse",
              items: warehouseItems,
              selectionItem: warehouseSelectedValue),
          const SizedBox(
            height: 20,
          ),
          DropdownFormFieldSection(
              label: "Expense Type",
              hint: "Select Expense",
              items: expenseTypeItems,
              selectionItem: expenseTypeSelectedValue),
          const SizedBox(
            height: 20,
          ),
          DropdownFormFieldSection(
              label: "Category",
              hint: "Select Category",
              items: categoryItems,
              selectionItem: categorySelectedValue),
          const SizedBox(
            height: 20,
          ),
          const TextFieldMaxLineSection(
              labelText: "Purchase Note", hintText: "Enter Your Text Here..."),
          const SizedBox(
            height: 20,
          ),
          CustomElevatedButton(
            buttonName: "Submit",
            showToast: () {
              SuccessToast.showSuccessToast(
                  context, "Submit Complete", "Expense Submit Complete");
            },
          ),
          const SizedBox(
            height: 20,
          )
        ],
      ),
    );
  }
}
