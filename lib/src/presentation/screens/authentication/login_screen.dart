import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _isPasswordHidden = true;
  bool _submitted = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userEmailAddressController =
      TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();

  // Derivados del primaryColor (#2C6AE5 - azul)
  static const Color _gradientTop = Color.fromARGB(255, 244, 248, 255);
  static const Color _gradientBottom = Color.fromARGB(232, 210, 225, 255);
  static const Color _errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _userEmailAddressController.addListener(() => setState(() {}));
    _userPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _userEmailAddressController.dispose();
    _userPasswordController.dispose();
    super.dispose();
  }

  Color _iconColor(TextEditingController controller) {
    if (_submitted && controller.text.trim().isEmpty) return _errorColor;
    return ColorSchema.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color.fromARGB(255, 252, 253, 255), _gradientTop, _gradientBottom],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              children: [
                Image.asset(
                  "assets/images/logo/logo-teki-solo.png",
                  width: MediaQuery.of(context).size.width * 0.20,
                ),
                const SizedBox(height: 2),
                Text(
                  "TEKI",
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: ColorSchema.primaryColor,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.12),
                        spreadRadius: 0,
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Bienvenido",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF2D3748),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Inicia sesión para continuar",
                        style: GoogleFonts.raleway(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _buildTextField(
                              "Correo electrónico",
                              TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField("Contraseña"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      _buildLoginButton(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    final isLoading = ref.watch(authStateProvider).isLoading;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorSchema.primaryColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
        onPressed: isLoading ? null : _login,
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                "Iniciar Sesión",
                style: GoogleFonts.raleway(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }

  void _login() {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      final email = _userEmailAddressController.text.trim();
      final password = _userPasswordController.text.trim();
      ref.read(authStateProvider.notifier).login(email, password);
    }
  }

  TextFormField _buildTextField(String hint, TextInputType keyboardType) {
    return TextFormField(
      controller: _userEmailAddressController,
      keyboardType: keyboardType,
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w500),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "El correo electrónico es requerido";
        }
        return null;
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Icon(
          Icons.email_outlined,
          color: _iconColor(_userEmailAddressController),
          size: 20,
        ),
        fillColor: const Color(0xFFF7F8FC),
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorSchema.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPasswordField(String hint) {
    return TextFormField(
      controller: _userPasswordController,
      obscureText: _isPasswordHidden,
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      style: GoogleFonts.raleway(fontSize: 15, fontWeight: FontWeight.w500),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return "La contraseña es requerida";
        }
        return null;
      },
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        prefixIcon: Icon(
          Icons.lock_outline,
          color: _iconColor(_userPasswordController),
          size: 20,
        ),
        fillColor: const Color(0xFFF7F8FC),
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.raleway(
          color: Colors.grey.shade400,
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFEAECF0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ColorSchema.primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE53935), width: 1.5),
        ),
        suffixIcon: IconButton(
          onPressed: () {
            setState(() {
              _isPasswordHidden = !_isPasswordHidden;
            });
          },
          icon: Icon(
            _isPasswordHidden
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }
}
