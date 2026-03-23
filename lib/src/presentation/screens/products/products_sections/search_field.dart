import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class SearchField extends StatelessWidget {
  final ValueChanged<String> onTextChanged;
  final TextEditingController? controller;

  const SearchField({super.key, required this.onTextChanged, this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
      ),
      child: TextField(
        controller: controller,
        onChanged: onTextChanged,
        decoration: InputDecoration(
          hintText: "Buscar productos",
          hintStyle: GoogleFonts.nunito(
              textStyle: const TextStyle(color: Colors.grey)),
          suffixIcon: const Icon(Icons.search, color: Colors.grey),
          filled: true,
          fillColor: Colors.white,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide: const BorderSide(color: Colors.grey, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(25),
            borderSide:
                const BorderSide(color: ColorSchema.primaryColor, width: 1),
          ),
          contentPadding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }
}
