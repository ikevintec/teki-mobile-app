import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/date_picker_section/date_picker.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_max_line_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UpdateBillerSection extends StatelessWidget {
  final dynamic biller;

  const UpdateBillerSection({super.key, required this.biller});

  @override
  Widget build(BuildContext context) {
    const warehouseSelectedValue = "";

    List<String> warehouseItems = [
      "Warehouse 1",
      "Warehouse 2",
      "Warehouse 3",
      "Warehouse 4",
      "Warehouse 5"
    ];

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
                  "Edit Biller",
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
                  label: "Biller Name",
                  hint: biller["name"],
                  inputType: TextInputType.text),
              const SizedBox(
                height: 20,
              ),
              const DatePicker(
                  labelText: "Date Of Join", hintText: "MM/DD/YYYY"),
              const SizedBox(
                height: 20,
              ),
              Row(
                children: [
                  Expanded(
                      child: TextFieldSection(
                          label: "Email",
                          hint: biller["email"],
                          inputType: TextInputType.emailAddress)),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: TextFieldSection(
                          label: "Phone",
                          hint: biller["phone"],
                          inputType: TextInputType.phone))
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
                    inputType: TextInputType.number,
                  )),
                  const SizedBox(
                    width: 10,
                  ),
                  Expanded(
                      child: TextFieldSection(
                    label: "Biller Code",
                    hint: biller["billerCode"],
                    inputType: TextInputType.number,
                  ))
                ],
              ),
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
              DropdownFormFieldSection(
                  label: "Warehouse",
                  hint: "Select Warehouse",
                  items: warehouseItems,
                  selectionItem: warehouseSelectedValue),
              const SizedBox(
                height: 20,
              ),
              TextFieldMaxLineSection(
                  labelText: "Address", hintText: biller["address"]),
              const SizedBox(
                height: 20,
              ),
              CustomElevatedButton(
                  buttonName: "Update Biller",
                  showToast: () {
                    SuccessToast.showSuccessToast(
                        context, "Update Complete", "Biller Update Complete");
                  }),
              const SizedBox(
                height: 20,
              ),
            ],
          ),
        ))
      ],
    );
  }
}
