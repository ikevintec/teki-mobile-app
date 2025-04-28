import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/text_field/dropdown_form_field_section.dart';
import 'package:teki_app/src/presentation/widgets/toast/success_toast.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';
import 'package:teki_app/src/utils/contstants.dart';

class EditProfileSection extends StatefulWidget {
  const EditProfileSection({super.key});

  @override
  State<EditProfileSection> createState() => _EditProfileSectionState();
}

class _EditProfileSectionState extends State<EditProfileSection> {
  bool showPassword = false;

  final TextEditingController _nameController =
      TextEditingController(text: "Shane Watson");
  final TextEditingController _phoneController =
      TextEditingController(text: "+02 259 857 654");
  final TextEditingController _emailController =
      TextEditingController(text: "shane@example.com");
  final TextEditingController _userNameController =
      TextEditingController(text: "Shane_Watson");
  final TextEditingController _companyController =
      TextEditingController(text: "teki_app");
  final TextEditingController _addressController =
      TextEditingController(text: "5874 Street Park, New York, USA");
  final TextEditingController _passwordController =
      TextEditingController(text: "123456");

  String genderSelectedValue = "";
  String roleSelectedValue = "";

  List<String> genderItems = ["Male", "Female"];
  List<String> roleItems = ["Admin", "Staff", "Manager"];

  String imageUrl = "assets/images/avatar/avatar.png";

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12), topRight: Radius.circular(12)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [ColorSchema.primaryColor, Colors.white],
        ),
      ),
      child: ListView(
        children: [
          _buildHeader(),
          const Divider(color: Colors.white38),
          const SizedBox(height: 20),
          UploadImage(
            image: imageUrl,
            onImageSelected: (newImageUrl,file) {
              imageUrl = newImageUrl; // Actualiza la URL de la imagen
              setState(() {});
            },
          ),
          const SizedBox(height: 20),
          _buildForm(),
          const SizedBox(height: 20),
          _buildUpdateButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Edit Profile",
              style: GoogleFonts.raleway(
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                  color: Colors.white70,
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.close,
              size: 26,
              color: Colors.white70,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          )
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0),
      elevation: 0,
      color: Colors.white60,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          children: [
            _buildTextField("Name", _nameController),
            const SizedBox(height: 20),
            _buildTextField("Phone", _phoneController),
            const SizedBox(height: 20),
            _buildTextField("Email", _emailController),
            const SizedBox(height: 20),
            _buildTextField("User Name", _userNameController),
            const SizedBox(height: 20),
            _buildTextField("Company", _companyController),
            const SizedBox(height: 20),
            _buildTextField("Address", _addressController),
            const SizedBox(height: 20),
            _buildPasswordField(),
            const SizedBox(height: 20),
            DropdownFormFieldSection(
                label: "Gender",
                hint: "Male",
                items: genderItems,
                selectionItem: genderSelectedValue),
            const SizedBox(height: 20),
            DropdownFormFieldSection(
                label: "Role",
                hint: "Admin",
                items: roleItems,
                selectionItem: roleSelectedValue),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: label,
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        fillColor: const Color(0xFFFCFCFC),
        filled: true,
        hintText: controller.text,
        hintStyle: GoogleFonts.nunito(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: TextInputType.name,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      obscureText: !showPassword,
      controller: _passwordController,
      decoration: InputDecoration(
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              showPassword = !showPassword;
            });
          },
          icon: Icon(showPassword
              ? Icons.remove_red_eye
              : Icons.remove_red_eye_outlined),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: "Password",
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        fillColor: const Color(0xFFFCFCFC),
        filled: true,
        hintText: _passwordController.text,
        hintStyle: GoogleFonts.nunito(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: TextInputType.name,
    );
  }

  Widget _buildUpdateButton() {
    return Center(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.45,
        child: ElevatedButton(
          onPressed: () {
            SuccessToast.showSuccessToast(
                context, "Update Complete", "Profile Update Complete");
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            backgroundColor: ColorSchema.primaryColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.update,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                "Update Profile",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
