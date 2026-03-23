import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class CreateSupplierSection extends StatelessWidget {
  const CreateSupplierSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Create Supplier"),
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
                label: "Supplier Name",
                hint: "Enter Supplier Name",
                inputType: TextInputType.text),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Supplier Email",
                hint: "Enter Supplier Email",
                inputType: TextInputType.emailAddress),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Supplier Phone",
                hint: "Enter Supplier Phone",
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
                label: "Company",
                hint: "Enter Company",
                inputType: TextInputType.text),
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
                  label: "Supplier Code",
                  hint: "Enter Supplier Coder",
                  inputType: TextInputType.number,
                ))
              ],
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
                buttonName: "Create Supplier",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "Supplier Create Complete");
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
