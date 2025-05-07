import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class TextFieldSection extends StatelessWidget {
  final String label;
  final String hint;
  final dynamic inputType;
  final String? initialValue;
  final Function(String)? onChanged;
  final bool enabled;
  final bool isReadOnly;
  final TextEditingController? controller;
  final String? Function(String?)? validator;


  const TextFieldSection({
    super.key,
    required this.label,
    required this.hint,
    required this.inputType,
    this.onChanged,
    this.initialValue,
    this.enabled = true,
    this.isReadOnly = false,
    this.controller,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      validator: validator,
      enabled: enabled,
      readOnly: isReadOnly,
      controller: controller,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        labelText: label,
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: hint,
        hintStyle: GoogleFonts.nunito(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      onChanged: onChanged,
      keyboardType: inputType,
    );
  }
}
