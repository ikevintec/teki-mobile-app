import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UpdateCustomerSection extends StatelessWidget {
  final dynamic customer;

  const UpdateCustomerSection({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    const String selectedGroupValue = "";

    List<String> groupItems = ["General", "Walk In", "Local", "Foreign"];

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
                  "Edit Customer",
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
                  label: "Customer Name",
                  hint: customer["name"],
                  inputType: TextInputType.text),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Customer Email",
                  hint: customer["email"],
                  inputType: TextInputType.emailAddress),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Customer Phone",
                  hint: customer["phone"],
                  inputType: TextInputType.phone),
              const SizedBox(
                height: 20,
              ),
              const Row(
                children: [
                  Expanded(
                    child: TextFieldSection(
                        label: "Country",
                        hint: "Enter Country",
                        inputType: TextInputType.text),
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextFieldSection(
                        label: "City",
                        hint: "Enter City",
                        inputType: TextInputType.text),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const Expanded(
                    child: TextFieldSection(
                        label: "Zip Code",
                        hint: "Enter Zip Code",
                        inputType: TextInputType.number),
                  ),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                    child: TextFieldSection(
                        label: "Reward Point",
                        hint: customer["reward"],
                        inputType: TextInputType.number),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              DropdownFormFieldSection(
                label: "Customer Group",
                hint: customer["group"],
                items: groupItems,
                selectionItem: selectedGroupValue,
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldMaxLineSection(
                  labelText: "Address", hintText: customer["address"]),
              const SizedBox(
                height: 20,
              ),
              CustomElevatedButton(
                  buttonName: "Update Customer",
                  showToast: () {
                    SuccessToast.showSuccessToast(
                        context, "Update Complete", "Customer Update Complete");
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
