import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isChecked = false;
  bool _isPasswordHidden = true;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userEmailAddressController =
      TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();

  final String _defaultEmail = "admin";
  final String _defaultPassword = "admin";
  @override
  void initState() {
    _userEmailAddressController.text = _defaultEmail;
    _userPasswordController.text = _defaultPassword;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.grey.shade50,
        width: double.infinity,
        height: double.infinity,
        //cambiar el stroke y color de borde
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 30),
            margin: const EdgeInsets.symmetric(horizontal: 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: ColorSchema.primaryColor,
                width: 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 0.1,
                  blurRadius: 3,
                  blurStyle: BlurStyle.outer,

                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/logo/logo-teki-solo.png",
                    width: MediaQuery.of(context).size.width * 0.25,
                  ),
                  Text("Teki app",
                      style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: ColorSchema.primaryColor)),
                  const SizedBox(
                    height: 30,
                  ),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildTextField("", TextInputType.emailAddress),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: buildPasswordField(""),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isChecked = !_isChecked;
                          });
                        },
                        child: Container(),
                        // child: Row(
                        //   children: [
                        //     Padding(
                        //       padding: const EdgeInsets.only(left: 6),
                        //       child: Checkbox(
                        //         activeColor: ColorSchema.primaryColor,
                        //         side: const BorderSide(
                        //           color: Color(0xFFE2E4E7),
                        //         ),
                        //         splashRadius: 0,
                        //         value: _isChecked,
                        //         onChanged: (bool? value) {
                        //           setState(() {
                        //             _isChecked = value!;
                        //           });
                        //         },
                        //       ),
                        //     ),
                        //     Text(
                        //       "Remember me",
                        //       style: GoogleFonts.raleway(
                        //         fontWeight: FontWeight.w600,
                        //         color: Colors.grey,
                        //         fontSize: 15,
                        //       ),
                        //     )
                        //   ],
                        // ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Get.toNamed(AppRoutes.forgotPassword);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 20),
                          child: Text(
                            "¿Olvidaste tu contraseña?",
                            style: GoogleFonts.raleway(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: Colors.grey),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  buildElevatedButton(),
                  const SizedBox(
                    height: 30,
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
                          "ó",
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ElevatedButton buildElevatedButton() {
    final isLoading = ref.watch(authStateProvider).isLoading;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorSchema.primaryColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 40),
      ),
      onPressed: isLoading ? null : _login,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Iniciar Sesión",
            style: GoogleFonts.raleway(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 10),
          isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                ),
        ],
      ),
    );
  }

  _login() {
    if (_formKey.currentState!.validate()) {
      final email = _userEmailAddressController.text.trim();
      final password = _userPasswordController.text.trim();
      ref.read(authStateProvider.notifier).login(email, password);
    }
  }

  showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  TextFormField buildTextField(String hint, TextInputType keyboardType) {
    return TextFormField(
      // validator: (value) {
      //   if (value == null || value.isEmpty) {
      //     return "Enter your email address";
      //   }
      //   final emailRegEx = RegExp(r'^[\w-]+(\.[\w-]+)*@[\w-]+(\.[\w-]+)+$');
      //   if (!emailRegEx.hasMatch(value)) {
      //     return "Enter your valid email address";
      //   }
      //   return null;
      // },
      controller: _userEmailAddressController,
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

  Widget buildPasswordField(String hint) {
    return TextFormField(
      // validator: (value) {
      //   if (value == null || value.isEmpty) {
      //     return "Enter your password";
      //   }
      //   if (value.length < 6) {
      //     return "Password must be at least 6 characters";
      //   }
      //   return null;
      // },
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
}
