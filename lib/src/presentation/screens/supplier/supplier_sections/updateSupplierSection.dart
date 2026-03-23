import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UpdateSupplierSection extends StatelessWidget {
  final dynamic supplier;

  const UpdateSupplierSection({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  "Edit Supplier",
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
                  label: "Supplier Name",
                  hint: supplier["name"],
                  inputType: TextInputType.text),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Supplier Email",
                  hint: supplier["email"],
                  inputType: TextInputType.emailAddress),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Supplier Phone",
                  hint: supplier["phone"],
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
                          inputType: TextInputType.text)),
                  SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: TextFieldSection(
                          label: "City",
                          hint: "Enter City",
                          inputType: TextInputType.text))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                  label: "Company",
                  hint: supplier["company"],
                  inputType: TextInputType.text),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  const Expanded(
                      child: TextFieldSection(
                    label: "Zip Code",
                    hint: "Enter Zip Code",
                    inputType: TextInputType.number,
                  )),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: TextFieldSection(
                    label: "Supplier Code",
                    hint: supplier["code"],
                    inputType: TextInputType.number,
                  ))
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldMaxLineSection(
                  labelText: "Address", hintText: supplier["address"]),
              const SizedBox(
                height: 20,
              ),
              CustomElevatedButton(
                  buttonName: "Update Supplier",
                  showToast: () {
                    SuccessToast.showSuccessToast(
                        context, "Update Complete", "Supplier Update Complete");
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
