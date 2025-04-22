import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class AddCustomerSection extends StatefulWidget {
  const AddCustomerSection({super.key});

  @override
  State<AddCustomerSection> createState() => _AddCustomerSectionState();
}

class _AddCustomerSectionState extends State<AddCustomerSection> {
  final String selectedGroupValue = "";

  List<String> groupItems = ["General", "Walk In", "Local", "Foreign"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Create Customer",
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
                label: "Customer Name",
                hint: "Enter Customer Name",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Customer Email",
                hint: "Enter Customer Email",
                inputType: TextInputType.emailAddress),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Customer Phone",
                hint: "Enter Customer Phone",
                inputType: TextInputType.phone),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Country",
                hint: "Enter Country",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "City",
                hint: "Enter City",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Zip Code",
                hint: "Enter Zip Code",
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Reward Point",
                hint: "Enter Reward Point",
                inputType: TextInputType.number),
            const SizedBox(
              height: 20,
            ),
            DropdownFormFieldSection(
              label: "Customer Group",
              hint: "Select Group",
              items: groupItems,
              selectionItem: selectedGroupValue,
            ),
            const SizedBox(
              height: 20,
            ),
            const TextFieldMaxLineSection(
                labelText: "Address", hintText: "Enter Your Text Here..."),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Create Customer",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "Customer Create Complete");
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
