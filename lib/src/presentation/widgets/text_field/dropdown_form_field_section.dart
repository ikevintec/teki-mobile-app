import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class DropdownFormFieldSection extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> items;
  String? selectionItem;

  DropdownFormFieldSection({
    super.key,
    required this.label,
    required this.hint,
    required this.items,
    required this.selectionItem,
  });

  @override
  State<DropdownFormFieldSection> createState() =>
      _DropdownFormFieldSectionState();
}

class _DropdownFormFieldSectionState extends State<DropdownFormFieldSection> {
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFFE2E4E7),
      ),
      decoration: InputDecoration(
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelText: widget.label,
        labelStyle: GoogleFonts.raleway(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Color(0xFF444444),
          ),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: widget.hint,
        hintStyle: GoogleFonts.nunito(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
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
      items: widget.items.map((String item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.nunito(color: Colors.black),
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          widget.selectionItem = value;
        });
      },
    );
  }
}
