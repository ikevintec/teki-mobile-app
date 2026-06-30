import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  bool _rememberEmail = false;
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _userEmailAddressController =
      TextEditingController();
  final TextEditingController _userPasswordController = TextEditingController();

  static const String _savedEmailKey = 'remembered_email';

  // Derivados del primaryColor (#2C6AE5 - azul)
  static const Color _gradientTop = Color.fromARGB(255, 244, 248, 255);
  static const Color _gradientBottom = Color.fromARGB(232, 205, 221, 255);
  static const Color _errorColor = Color(0xFFE53935);

  @override
  void initState() {
    super.initState();
    _userEmailAddressController.addListener(() => setState(() {}));
    _userPasswordController.addListener(() => setState(() {}));
    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString(_savedEmailKey);
    if (savedEmail != null && savedEmail.isNotEmpty) {
      setState(() {
        _userEmailAddressController.text = savedEmail;
        _rememberEmail = true;
      });
    }
  }

  Future<void> _onRememberToggle(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (!value) {
      await prefs.remove(_savedEmailKey);
    }
    setState(() => _rememberEmail = value);
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
      body: Stack(
        children: [
          // Fondo con gradiente
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color.fromARGB(255, 252, 253, 255), _gradientTop, _gradientBottom],
              ),
            ),
          ),
          // Nubes decorativas en la parte inferior
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _CloudPainter()),
            ),
          ),
          // Contenido del formulario
          Center(
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
                        const SizedBox(height: 20),
                        _buildRememberCheckbox(),
                        const SizedBox(height: 20),
                        _buildLoginButton(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Future<void> _login() async {
    setState(() => _submitted = true);
    if (_formKey.currentState!.validate()) {
      final email = _userEmailAddressController.text.trim();
      final password = _userPasswordController.text.trim();
      final prefs = await SharedPreferences.getInstance();
      if (_rememberEmail) {
        await prefs.setString(_savedEmailKey, email);
      } else {
        await prefs.remove(_savedEmailKey);
      }
      ref.read(authStateProvider.notifier).login(email, password);
    }
  }

  Widget _buildRememberCheckbox() {
    return GestureDetector(
      onTap: () => _onRememberToggle(!_rememberEmail),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'Recordar correo',
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: _rememberEmail,
              onChanged: (val) => _onRememberToggle(val ?? false),
              activeColor: ColorSchema.primaryColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
              side: BorderSide(color: Colors.grey.shade400, width: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  TextFormField _buildTextField(String hint, TextInputType keyboardType) {
    return TextFormField(
      controller: _userEmailAddressController,
      keyboardType: keyboardType,
      autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
      style: GoogleFonts.roboto(fontSize: 15),
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
      style: GoogleFonts.roboto(fontSize: 15),
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

/// Pinta tres capas de nubes superpuestas en la parte inferior de la pantalla.
/// Cada capa usa curvas bezier cuadráticas para los "puffs" y va aumentando
/// la opacidad hacia el frente, generando sensación de profundidad.
class _CloudPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Capa 1 — más atrás, ondas grandes y suaves
    final paint1 = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    // Amplitud ~8% — ondas anchas y suaves
    final path1 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.63)
      ..quadraticBezierTo(size.width * 0.13, size.height * 0.55, size.width * 0.26, size.height * 0.61)
      ..quadraticBezierTo(size.width * 0.39, size.height * 0.68, size.width * 0.51, size.height * 0.61)
      ..quadraticBezierTo(size.width * 0.63, size.height * 0.54, size.width * 0.76, size.height * 0.61)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.68, size.width, size.height * 0.62)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path1, paint1);

    // Capa 2 — profundidad media, amplitud ~7%
    final paint2 = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.fill;

    final path2 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.10, size.height * 0.67, size.width * 0.22, size.height * 0.73)
      ..quadraticBezierTo(size.width * 0.34, size.height * 0.80, size.width * 0.46, size.height * 0.73)
      ..quadraticBezierTo(size.width * 0.58, size.height * 0.66, size.width * 0.70, size.height * 0.73)
      ..quadraticBezierTo(size.width * 0.82, size.height * 0.80, size.width * 0.93, size.height * 0.74)
      ..quadraticBezierTo(size.width * 0.97, size.height * 0.72, size.width, size.height * 0.73)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path2, paint2);

    // Capa 3 — al frente, amplitud ~6%
    final paint3 = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final path3 = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.84)
      ..quadraticBezierTo(size.width * 0.08, size.height * 0.78, size.width * 0.18, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.89, size.width * 0.38, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.48, size.height * 0.77, size.width * 0.58, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.68, size.height * 0.89, size.width * 0.78, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.88, size.height * 0.77, size.width * 0.95, size.height * 0.83)
      ..quadraticBezierTo(size.width * 0.98, size.height * 0.85, size.width, size.height * 0.84)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path3, paint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
