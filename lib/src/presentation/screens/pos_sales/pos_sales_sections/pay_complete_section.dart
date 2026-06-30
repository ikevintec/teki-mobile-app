import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/button/custom_elevated_button.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class PayCompleteSection extends StatefulWidget {
  final String identificador;
  final bool isEdit;

  const PayCompleteSection({super.key, required this.identificador, this.isEdit = false});

  @override
  State<PayCompleteSection> createState() => _PayCompleteSectionState();
}

class _PayCompleteSectionState extends State<PayCompleteSection> {
  Random random = Random();

  String generateRandomNumber() {
    String randomNumber = "";
    for (int i = 0; i < 14; i++) {
      randomNumber += random.nextInt(10).toString();
    }
    return randomNumber;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isEdit ? "Edición Exitosa" : "Operación Exitosa",
                style: GoogleFonts.raleway(
                  textStyle: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Animated tick mark icon
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 500),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                builder: (_, double value, __) {
                  return Transform.scale(
                    scale: value,
                    child: Image.asset(
                      "assets/icons/icon_image/tick_mark_icon.png",
                      width: MediaQuery.of(context).size.width * 0.4,
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              Text(
                widget.isEdit ? "Venta editada!" : "Venta registrada!",
                style: GoogleFonts.raleway(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 22,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              // Additional text information
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Identificador de comprobante",
                    style: GoogleFonts.raleway(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 17,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  Text(
                    widget.identificador,
                    style: GoogleFonts.roboto(
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  // Add more text information here
                ],
              ),
              const SizedBox(height: 20),
              // Styled button
              CustomElevatedButton(
                  buttonName: "Volver",
                  showToast: () {Get.toNamed(AppRoutes.dashboard);},),
            ],
          ),
        ),
      ),
    );
  }
}
