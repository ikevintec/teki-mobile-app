import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final String buttonName;
  final dynamic routeName;
  final IconData? iconData;

  const CustomFloatingActionButton(
      {super.key, required this.buttonName, required this.routeName, this.iconData});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        onPressed: () {
          Get.toNamed(routeName);
        },
        label: Text(
          buttonName,
          style: GoogleFonts.raleway(
              color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        icon: iconData != null
            ? Icon(
                iconData,
                color: Colors.white70,
              )
            : const Icon(Icons.add, color: Colors.white70),
        backgroundColor: ColorSchema.primaryColor,
      ),
    );
  }
}
