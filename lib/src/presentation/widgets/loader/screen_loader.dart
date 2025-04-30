import 'package:flutter/material.dart';

class ScreenLoader extends StatelessWidget {
  final String? message;
  const ScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white70,
      body: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(strokeWidth: 1,),
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