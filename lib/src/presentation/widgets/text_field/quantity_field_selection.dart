import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/constants.dart';

class QuantityFieldSection extends StatefulWidget {
  final String label;
  final String hint;
  final int initialValue;
  final Function(int)? onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  const QuantityFieldSection({
    super.key,
    required this.label,
    required this.hint,
    this.initialValue = 0,
    this.onChanged,
    this.validator,
    this.enabled = true,
  });

  @override
  State<QuantityFieldSection> createState() => _QuantityFieldSectionState();
}

class _QuantityFieldSectionState extends State<QuantityFieldSection> {
  late TextEditingController _controller;
  int _quantity = 0;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialValue < 0 ? 0 : widget.initialValue;
    _controller = TextEditingController(text: _quantity.toString());

    _controller.addListener(() {
      final input = _controller.text;
      final value = int.tryParse(input);
      if (value != null && value >= 0 && value != _quantity) {
        setState(() {
          _quantity = value;
        });
        widget.onChanged?.call(_quantity);
      }
    });
  }

  void _updateQuantity(int delta) {
    final current = int.tryParse(_controller.text) ?? 0;
    final updated = current + delta;
    if (updated < 0) return;

    setState(() {
      _quantity = updated;
      _controller.text = updated.toString();
    });

    widget.onChanged?.call(_quantity);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      textAlign: TextAlign.center,
      controller: _controller,
      enabled: widget.enabled,
      validator: widget.validator,
      style: GoogleFonts.roboto(
        fontWeight: FontWeight.w600,
        fontSize: 10,
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        labelText: widget.label,
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        ),
        fillColor: Colors.white,
        filled: true,
        hintText: widget.hint,
        hintStyle: GoogleFonts.roboto(
          textStyle: const TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        prefix: GestureDetector(
          onTap: widget.enabled ? () => _updateQuantity(-1) : null,
          child: const Text(
                "  -",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,color: Colors.black),
              ),
        ),
        suffix: GestureDetector(
          onTap: widget.enabled ? () => _updateQuantity(1) : null,
          child: const Text(
                "+  ",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,color: Colors.black),
              ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFFE2E4E7), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1),
          borderRadius: BorderRadius.circular(30),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      keyboardType: TextInputType.numberWithOptions( signed: false),
    );
  }
}
