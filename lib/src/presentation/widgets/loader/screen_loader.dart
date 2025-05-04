import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ScreenLoader extends StatelessWidget {
  final String? message;
  const ScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const CircularProgressIndicator(strokeWidth: 3, color: ColorSchema.primaryColor,),
            const SizedBox(
              height: 20,
            ),
            Text(
              message ?? "Cargando...",
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          ],
        )
      ),
    );
  }
}