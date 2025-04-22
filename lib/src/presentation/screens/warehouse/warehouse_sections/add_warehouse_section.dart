import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class AddWarehouseSection extends StatelessWidget {
  const AddWarehouseSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Add Warehouse",
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
                label: "Warehouse",
                hint: "Enter Warehouse",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Email",
                hint: "Enter Email Address",
                inputType: TextInputType.emailAddress),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Phone",
                hint: "Enter Phone Number",
                inputType: TextInputType.phone),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Zip",
                hint: "Enter Zip Code",
                inputType: TextInputType.phone),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "City",
                hint: "Enter Your City",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Country",
                hint: "Enter Your Country",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldMaxLineSection(
                labelText: "Address", hintText: "Enter Your Text Here"),
            const SizedBox(
              height: 20,
            ),
            CustomElevatedButton(
                buttonName: "Create Warehouse",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "Warehouse Create Complete");
                })
          ],
        ),
      ),
    );
  }
}
