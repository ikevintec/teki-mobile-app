import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final String? buttonName;
  final dynamic routeName;
  final IconData? iconData;
  final Function? onPressed;

  const CustomFloatingActionButton(
      {super.key, this.buttonName, this.routeName, this.iconData, this.onPressed});

@override
Widget build(BuildContext context) {
  final bool hasLabel = buttonName != null && buttonName!.trim().isNotEmpty;

  return Align(
    alignment: Alignment.bottomRight,
    child: hasLabel
        ? FloatingActionButton.extended(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            onPressed: () {
              if (onPressed != null) {
                onPressed!();
                return;
              }
              if (routeName == null) {
                return;
              }
              Get.toNamed(routeName);
            },
            label: Text(
              buttonName!,
              style: GoogleFonts.raleway(
                  color: Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            icon: Icon(iconData ?? Icons.add, color: Colors.white70),
            backgroundColor: ColorSchema.primaryColor,
          )
        : FloatingActionButton(
            onPressed: () {
              if (onPressed != null) {
                onPressed!();
                return;
              }
              if (routeName == null) {
                return;
              }
              Get.toNamed(routeName);
            },
            backgroundColor: ColorSchema.primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            child: Icon(iconData ?? Icons.add, color: Colors.white),
          ),
  );
}
}