import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class DropdownFormFieldSection extends StatefulWidget {
  final String label;
  final String hint;

  /// Opción 1: lista de strings simples
  final List<String>? items;

  final bool? readOnly;

  /// Opción 2: lista de mapas {label: ..., value: ...}
  final List<Map<String, String>>? itemsMap;
  final String? labelKey;
  final String? valueKey;

  String? selectionItem;
  final ValueChanged<String?>? onChanged;

  DropdownFormFieldSection({
    super.key,
    required this.label,
    required this.hint,
    required this.selectionItem,
    this.readOnly,
    this.items,
    this.itemsMap,
    this.labelKey,
    this.valueKey,
    this.onChanged,
  }) : assert((items != null && itemsMap == null) || (itemsMap != null && items == null),
            'Debes usar solo uno: items o itemsMap');

  @override
  State<DropdownFormFieldSection> createState() =>
      _DropdownFormFieldSectionState();
}

class _DropdownFormFieldSectionState extends State<DropdownFormFieldSection> {
  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> dropdownItems = widget.items != null
        ? widget.items!
            .map((item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: GoogleFonts.nunito(color: Colors.black)),
                ))
            .toList()
        : widget.itemsMap!
            .map((map) {
              final value = map[widget.valueKey!] ?? '';
              final label = map[widget.labelKey!] ?? '';
              return DropdownMenuItem<String>(
                value: value,
                child: Text(label, style: GoogleFonts.nunito(color: Colors.black)),
              );
            }).toList();

    final bool valueExists = widget.items != null
        ? widget.items!.contains(widget.selectionItem)
        : widget.itemsMap!.any((e) => e[widget.valueKey!] == widget.selectionItem);

    return DropdownButtonFormField<String>(
      isExpanded: true,
      style: GoogleFonts.nunito(
        textStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFF4B5563),
        ),
      ),
      value: valueExists ? widget.selectionItem : null,
      dropdownColor: Colors.white,
      icon: const Icon(
        Icons.keyboard_arrow_down,
        color: Color(0xFFE2E4E7),
      ),
      decoration: InputDecoration(
        isDense: true, // 🔽 Esto reduce la altura vertical
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        labelText: widget.label,
        labelStyle: GoogleFonts.raleway(
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
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
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      items: dropdownItems,
      onChanged: widget.readOnly == true
          ? null
          :(String? value) {
        setState(() {
          widget.selectionItem = value;
        });
        if (widget.onChanged != null) {
          widget.onChanged!(value);
        }
      },
    );
  }
}
