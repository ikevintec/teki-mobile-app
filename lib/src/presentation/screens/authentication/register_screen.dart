import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordHidden = true;
  String _roleSelectedValue = "";

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userEmailAddressController =
      TextEditingController();
  final TextEditingController _userPhoneController = TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();

  List<String> roleItems = ["Admin", "Staff", "Customer"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white70,
        width: double.infinity,
        height: double.infinity,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logo/logo.png",
                    width: MediaQuery.of(context).size.width * 0.25,
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildNameField("Name", TextInputType.name),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildUserNameField(
                              "Username", TextInputType.name),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildEmailField(
                              "Email", TextInputType.emailAddress),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildPhoneField("Phone", TextInputType.phone),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildRoleSelector(),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildPasswordField("Password"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  buildElevatedButton(),
                  const SizedBox(
                    height: 20,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                            child: Divider(
                          color: Color(0xFFE2E4E7),
                          thickness: 0.7,
                        )),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          "or",
                          style: GoogleFonts.raleway(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: Colors.grey),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        const Expanded(
                            child: Divider(
                          color: Color(0xFFE2E4E7),
                          thickness: 0.7,
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Already have an account?",
                        style: GoogleFonts.raleway(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: Colors.grey),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.login);
                        },
                        child: Text(
                          "Log In",
                          style: GoogleFonts.raleway(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: ColorSchema.primaryColor),
                        ),
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  TextFormField buildNameField(String hint, TextInputType keyboardType) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter your name";
        }
        return null;
      },
      controller: _nameController,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: const Icon(
          Icons.account_circle,
          color: Color(0xFFE2E4E7),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
            textStyle: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
    );
  }

  TextFormField buildUserNameField(String hint, TextInputType keyboardType) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter your username";
        }
        return null;
      },
      controller: _userNameController,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: const Icon(
          Icons.account_circle,
          color: Color(0xFFE2E4E7),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
            textStyle: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
    );
  }

  TextFormField buildEmailField(String hint, TextInputType keyboardType) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter your email address";
        }
        final emailRegEx = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
        if (!emailRegEx.hasMatch(value)) {
          return "Enter your valid email address";
        }
        return null;
      },
      controller: _userEmailAddressController,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: const Icon(
          Icons.email_rounded,
          color: Color(0xFFE2E4E7),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
            textStyle: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
    );
  }

  TextFormField buildPhoneField(String hint, TextInputType keyboardType) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter your Phone";
        }
        return null;
      },
      controller: _userPhoneController,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        suffixIcon: const Icon(
          Icons.phone,
          color: Color(0xFFE2E4E7),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
            textStyle: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: keyboardType,
    );
  }

  Widget buildPasswordField(String hint) {
    return TextFormField(
      validator: (value) {
        if (value == null || value.isEmpty) {
          return "Enter your password";
        }
        if (value.length < 6) {
          return "Password must be at least 6 characters";
        }
        return null;
      },
      controller: _userPasswordController,
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
            textStyle: const TextStyle(
                color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 16)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordHidden = !_isPasswordHidden;
            });
          },
          icon: Icon(
            _isPasswordHidden ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xFFE2E4E7),
          ),
        ),
      ),
      obscureText: _isPasswordHidden,
    );
  }

  _register() {
    if (_formKey.currentState!.validate()) {
      Get.toNamed(AppRoutes.login);
    }
  }

  ElevatedButton buildElevatedButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          backgroundColor: ColorSchema.primaryColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
      onPressed: _register,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 40),
        child: Text(
          "Register",
          style: GoogleFonts.raleway(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }

  DropdownButtonFormField buildRoleSelector() {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFFE2E4E7),
      ),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        fillColor: Colors.white,
        filled: true,
        hintText: "Select Role",
        hintStyle: GoogleFonts.raleway(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(8),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      items: roleItems.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.raleway(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _roleSelectedValue = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }
}
