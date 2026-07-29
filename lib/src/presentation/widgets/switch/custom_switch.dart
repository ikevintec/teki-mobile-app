import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:teki_app/src/utils/constants.dart';

class CustomSwitch extends StatelessWidget {
  final String? title;
  final bool value;
  final String? textOn;
  final String? textOff;
  final Function(bool) onChanged;
  final bool? border;
  final bool? rightAlign;
  final bool? small;
  final Color? textColor;
  final Color? activeColor;
  final Color? activeToggleColor;
  final Color? activeTextColor;
  final Color? inactiveTextColor;

  const CustomSwitch({
    super.key,
    this.title,
    required this.value,
    required this.onChanged,
    this.textOn,
    this.textOff,
    this.border = true,
    this.rightAlign = false,
    this.small = false,
    this.textColor,
    this.activeColor,
    this.activeToggleColor,
    this.activeTextColor,
    this.inactiveTextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: border!
            ? BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE2E4E7), width: 1),
                borderRadius: BorderRadius.circular(20),
              )
            : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (rightAlign == false)
              // Flexible + ellipsis: los títulos largos se truncan en vez de
              // desbordar el Row cuando el switch va a mitad de ancho.
              Flexible(
                child: Text(
                  title ?? 'Switch',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: small == true ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: textColor ?? const Color(0xFF4B5563),
                  ),
                ),
              ),
              SizedBox(width: small == true ? 8 : 12),
            FlutterSwitch(
              activeColor: activeColor ?? ColorSchema.primaryColor,
              activeToggleColor: activeToggleColor ?? Colors.white,
              activeTextColor: activeTextColor ?? Colors.white,
              inactiveTextColor: inactiveTextColor ?? Colors.white,
              inactiveColor: const Color.fromARGB(255, 176, 178, 181),
              height: small == true ? 25 : 30,
              width: small == true ? 50 : 60,
              toggleSize: small == true ? 15 : 20,
              padding: 5,
              activeTextFontWeight: FontWeight.w500,
              inactiveTextFontWeight: FontWeight.w500,
              valueFontSize: small == true ? 12 : 14,
              showOnOff: true,
              inactiveText: textOff ?? "No",
              activeText: textOn ?? "Si",
              value: value,
              onToggle: onChanged,
            ),
            if (rightAlign == true)
              Text(
                title ?? 'Switch',
                style: TextStyle(
                  fontSize: small == true ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF4B5563),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
