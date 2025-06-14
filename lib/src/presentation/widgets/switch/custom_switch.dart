import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CustomSwitch extends StatelessWidget {
  final String? title;
  final bool value;
  final String? textOn;
  final String? textOff;
  final Function(bool) onChanged;
  final bool? border;

  const CustomSwitch({
    super.key,
    this.title,
    required this.value,
    required this.onChanged,
    this.textOn,
    this.textOff,
    this.border = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        decoration: border!? BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE2E4E7), width: 1),
          borderRadius: BorderRadius.circular(20),
        ): null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title ?? 'Switch',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            FlutterSwitch(
              activeColor: ColorSchema.primaryColor,
              inactiveColor: const Color(0xFFC7C9CC),
              height: 30,
              width: 60,
              toggleSize: 20,
              padding: 5,
              activeTextFontWeight: FontWeight.w500,
              inactiveTextFontWeight: FontWeight.w500,
              valueFontSize: 14,
              showOnOff: true,
              inactiveText: textOff ?? "No",
              activeText: textOn ?? "Si",
              value: value,
              onToggle: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
