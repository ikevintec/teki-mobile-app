import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class TextFieldSection extends StatefulWidget {
  final String label;
  final String hint;
  final TextInputType inputType;
  final String? initialValue;
  final Function(String)? onChanged;
  final bool enabled;
  final bool isReadOnly;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final String? prefix;
  final bool showBorders;
  final double? paddingHorinzontal;
  final double? fontSize;
  final List<TextInputFormatter>? inputFormatters;
  final Color borderColor;
  final FocusNode? focusNode;
  final bool? showDoneButton;
  final bool dismissKeyboardOnTapOutside;



  const TextFieldSection({
    super.key,
    required this.label,
    required this.hint,
    required this.inputType,
    this.onChanged,
    this.focusNode,
    this.initialValue,
    this.enabled = true,
    this.isReadOnly = false,
    this.controller,
    this.validator,
    this.prefix,
    this.showBorders = true,
    this.paddingHorinzontal = 10,
    this.fontSize = 15,
    this.inputFormatters,
    this.borderColor = const Color(0xFFE2E4E7),
    this.showDoneButton = false,
    this.dismissKeyboardOnTapOutside = false,
  });

  @override
  State<TextFieldSection> createState() => _TextFieldSectionState();
}

class _TextFieldSectionState extends State<TextFieldSection> {
  FocusNode? _internalFocusNode;
  bool _isFieldFocused = false;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode!;

  @override
  void initState() {
    super.initState();
    if (widget.focusNode == null) {
      _internalFocusNode = FocusNode();
    }
    _effectiveFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFieldFocused = _effectiveFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isIos = Theme.of(context).platform == TargetPlatform.iOS;
    return TextFormField(
      validator: widget.validator,
      enabled: widget.enabled,
      readOnly: widget.isReadOnly,
      controller: widget.controller,
      focusNode: _effectiveFocusNode,
        inputFormatters: widget.inputType == TextInputType.number &&  (widget.inputFormatters ?? []).isEmpty ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))] : widget.inputFormatters,
      style: GoogleFonts.nunito(
        fontWeight: FontWeight.w600,
        fontSize: widget.fontSize,
      ),
      decoration: InputDecoration(
        prefixText: widget.prefix,
        suffixIcon: (isIos && widget.showDoneButton == true && _isFieldFocused)
            ? GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: const Icon(
                  Icons.keyboard_hide,
                  size: 18,
                  color: Colors.grey,
                ),
              )
            : null,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 10,horizontal: widget.paddingHorinzontal!),
        labelText: widget.label,
        labelStyle: GoogleFonts.raleway(
          color: const Color(0xFF444444),
          textStyle: TextStyle(fontWeight: FontWeight.w700, fontSize: widget.fontSize),
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
          
          borderSide: BorderSide(color: widget.borderColor, width: widget.showBorders ? 1 : 0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: widget.borderColor, width: widget.showBorders ? 1 : 0),
          borderRadius: BorderRadius.circular(20),
        ),
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      onChanged: widget.onChanged,
      keyboardType: widget.inputType,
    );
  }
}
