import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';

class AddUserMainScreen extends StatefulWidget {
  const AddUserMainScreen({super.key});

  @override
  State<AddUserMainScreen> createState() => _AddUserMainScreenState();
}

class _AddUserMainScreenState extends State<AddUserMainScreen> {
  String genderSelectionValue = "";
  String roleSelectionValue = "";

  List<String> genderItems = ["Male", "Gender"];
  List<String> roleItems = ["Supervisor", "Officer", "Manager"];
  String imageUrl = "assets/images/avatar/avatar.png";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Add New User"),
      ),
      body: Container(
        color: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: ListView(
          children: [
            const SizedBox(
              height: 20,
            ),
            UploadImage(
              image: imageUrl,
              onImageSelected: (newImageUrl,file) {
                imageUrl = newImageUrl; // Actualiza la URL de la imagen
                setState(() {});
              },
            ),
            const SizedBox(
              height: 20,
            ),
            const TextFieldSection(
                label: "Name",
                hint: "Enter Your Name",
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
                hint: "Enter Your Phone",
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
                buttonName: "Create User",
                showToast: () {
                  SuccessToast.showSuccessToast(
                      context, "Create Complete", "User Create Complete");
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
