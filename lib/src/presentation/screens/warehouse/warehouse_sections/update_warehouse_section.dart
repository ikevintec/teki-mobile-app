import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UpdateWarehouseSection extends StatelessWidget {
  final dynamic warehouse;

  const UpdateWarehouseSection({super.key, required this.warehouse});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "Edit Warehouse",
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                label: "Warehouse",
                hint: warehouse["warehouse"],
                inputType: TextInputType.text,
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                label: "Email",
                hint: warehouse["email"],
                inputType: TextInputType.emailAddress,
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldSection(
                label: "Phone",
                hint: warehouse["phone"],
                inputType: TextInputType.phone,
              ),
              const SizedBox(
                height: 20,
              ),
              const TextFieldSection(
                label: "Zip",
                hint: "Enter Zip Code",
                inputType: TextInputType.number,
              ),
              const SizedBox(
                height: 20,
              ),
              const TextFieldSection(
                label: "City",
                hint: "Enter Your City",
                inputType: TextInputType.text,
              ),
              const SizedBox(
                height: 20,
              ),
              const TextFieldSection(
                label: "Country",
                hint: "Enter Your Country",
                inputType: TextInputType.text,
              ),
              const SizedBox(
                height: 20,
              ),
              TextFieldMaxLineSection(
                  labelText: "Address", hintText: warehouse["address"]),
              const SizedBox(
                height: 20,
              ),
              CustomElevatedButton(
                  buttonName: "Update Warehouse",
                  showToast: () {
                    SuccessToast.showSuccessToast(context, "Update Complete",
                        "${warehouse["warehouse"]} Update Complete");
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
