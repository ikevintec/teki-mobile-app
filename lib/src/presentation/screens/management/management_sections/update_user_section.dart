import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';

class UpdateUserSection extends StatefulWidget {
  final dynamic user;

  const UpdateUserSection({super.key, required this.user});

  @override
  State<UpdateUserSection> createState() => _UpdateUserSectionState();
}

class _UpdateUserSectionState extends State<UpdateUserSection> {
  String genderSelectionValue = "";
  String roleSelectionValue = "";

  List<String> genderItems = ["Male", "Gender"];
  List<String> roleItems = ["Supervisor", "Officer", "Manager"];

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Text(
                  "Edit User",
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
        const SizedBox(
          height: 20,
        ),
        const UploadImage(image: "assets/images/avatar/avatar.png"),

        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                const SizedBox(
                  height: 30,
                ),
                TextFieldSection(
                    label: "Name",
                    hint: widget.user["name"],
                    inputType: TextInputType.text),
                const SizedBox(
                  height: 20,
                ),
                TextFieldSection(
                    label: "Email",
                    hint: widget.user["email"],
                    inputType: TextInputType.emailAddress),
                const SizedBox(
                  height: 20,
                ),
                TextFieldSection(
                    label: "Phone",
                    hint: widget.user["phone"],
                    inputType: TextInputType.phone),
                const SizedBox(
                  height: 20,
                ),
                DropdownFormFieldSection(
                    label: "Gender",
                    hint: "Select Gender",
                    items: genderItems,
                    selectionItem: genderSelectionValue),
                const SizedBox(
                  height: 20,
                ),
                DropdownFormFieldSection(
                    label: "Role",
                    hint: "Select Role",
                    items: roleItems,
                    selectionItem: roleSelectionValue),
                const SizedBox(
                  height: 20,
                ),
                CustomElevatedButton(
                    buttonName: "Update User",
                    showToast: () {
                      SuccessToast.showSuccessToast(
                          context, "Create Complete", "User Create Complete");
                    }),
                const SizedBox(
                  height: 20,
                )
              ],
            )),
      ],
    );
  }
}
