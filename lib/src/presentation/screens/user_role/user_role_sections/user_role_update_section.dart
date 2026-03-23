import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';

class UserRoleUpdateSection extends StatelessWidget {
  final dynamic user;

  const UserRoleUpdateSection({super.key, required this.user});

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
                  "Edit User Role",
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
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                TextFieldSection(
                    label: "Role",
                    hint: user["role"],
                    inputType: TextInputType.text),
                const SizedBox(
                  height: 20,
                ),
                TextFieldSection(
                    label: "Description",
                    hint: user["description"],
                    inputType: TextInputType.text),
                const SizedBox(
                  height: 20,
                ),
                CustomElevatedButton(
                    buttonName: "Update User Role",
                    showToast: () {
                      SuccessToast.showSuccessToast(context, "Update Complete",
                          "User Role Update Complete");
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
