import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class CreateBillerSection extends StatefulWidget {
  const CreateBillerSection({super.key});

  @override
  State<CreateBillerSection> createState() => _CreateBillerSectionState();
}

class _CreateBillerSectionState extends State<CreateBillerSection> {
  final warehouseSelectedValue = "";

  List<String> warehouseItems = [
    "Warehouse 1",
    "Warehouse 2",
    "Warehouse 3",
    "Warehouse 4",
    "Warehouse 5"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Create Biller",
        ),
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
                label: "Biller Name",
                hint: "Enter Biller Name",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Email",
                hint: "Enter Email",
                inputType: TextInputType.emailAddress),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Phone",
                hint: "Enter Phone",
                inputType: TextInputType.phone),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "NID Or Passport Number",
                hint: "Enter NID OR Passport Number",
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            const DatePicker(labelText: "Date Of Join", hintText: "MM/DD/YYYY"),
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
            const Row(
              children: [
                Expanded(
                    child: TextFieldSection(
                  label: "Zip Code",
                  hint: "Enter Zip Code",
                  inputType: TextInputType.number,
                )),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                    child: TextFieldSection(
                  label: "Biller Code",
                  hint: "Enter Biller Code",
                  inputType: TextInputType.number,
                )),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            const TextFieldMaxLineSection(
                labelText: "Address", hintText: "Enter Text Here..."),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Create Biller",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "Biller Create Complete");
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
