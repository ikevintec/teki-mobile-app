import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class TextFieldSection extends StatelessWidget {
  final String label;
  final String hint;
  final dynamic inputType;

  const TextFieldSection(
      {super.key,
      required this.label,
      required this.hint,
      required this.inputType});

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: label,
        labelStyle: GoogleFonts.raleway(
            color: const Color(0xFF444444),
            textStyle:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
            textStyle: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.w500,
        )),
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
      keyboardType: inputType,
    );
  }
}
