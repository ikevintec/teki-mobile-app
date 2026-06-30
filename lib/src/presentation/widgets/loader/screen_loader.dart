import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ScreenLoader extends StatelessWidget {
  final String? message;
  const ScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: ColoredBox(
        color: ColorSchema.primaryColor,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 4,
                color: Colors.white,
              ),
              const SizedBox(height: 20),
              Text(
                message ?? "Cargando...",
                textAlign: TextAlign.center,
                style: GoogleFonts.raleway(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
