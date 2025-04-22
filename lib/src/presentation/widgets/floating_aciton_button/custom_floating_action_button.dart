import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class CustomFloatingActionButton extends StatelessWidget {
  final String buttonName;
  final dynamic routeName;

  const CustomFloatingActionButton(
      {super.key, required this.buttonName, required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomRight,
      child: FloatingActionButton.extended(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () {
          Get.toNamed(routeName);
        },
        label: Text(
          buttonName,
          style: GoogleFonts.raleway(
              color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 16),
        ),
        icon: const Icon(
          Icons.add_circle_outline_rounded,
          color: Colors.white70,
          size: 24,
        ),
        backgroundColor: ColorSchema.primaryColor,
      ),
    );
  }
}
