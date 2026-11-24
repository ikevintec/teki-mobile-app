import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Identidad de ventas, acotada a pedidos: no cambia el tema global de la app.
class PedidosStyle extends StatelessWidget {
  final Widget child;
  const PedidosStyle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final actual = Theme.of(context);
    final oscuro = actual.brightness == Brightness.dark;
    final esquema =
        ColorScheme.fromSeed(
          seedColor: ColorSchema.primaryColor,
          brightness: actual.brightness,
        ).copyWith(
          primary: oscuro ? const Color(0xFFA9C7FF) : ColorSchema.primaryColor,
          onPrimary: oscuro ? const Color(0xFF002F6C) : Colors.white,
          surface: oscuro ? const Color(0xFF17191E) : Colors.white,
          surfaceContainerLow: oscuro
              ? const Color(0xFF202329)
              : const Color(0xFFF5F6F8),
          primaryContainer: oscuro
              ? const Color(0xFF193B70)
              : const Color(0xFFEAF1FF),
          onPrimaryContainer: oscuro
              ? const Color(0xFFD9E7FF)
              : const Color(0xFF173B70),
          secondaryContainer: oscuro
              ? const Color(0xFF193B70)
              : const Color(0xFFEAF1FF),
          onSecondaryContainer: oscuro
              ? const Color(0xFFD9E7FF)
              : const Color(0xFF173B70),
          surfaceTint: Colors.transparent,
        );
    final borde = OutlineInputBorder(borderRadius: BorderRadius.circular(12));
    return Theme(
      data: actual.copyWith(
        colorScheme: esquema,
        scaffoldBackgroundColor: esquema.surface,
        appBarTheme: actual.appBarTheme.copyWith(
          backgroundColor: ColorSchema.primaryColor,
          foregroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: actual.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        cardTheme: actual.cardTheme.copyWith(
          color: esquema.surface,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: esquema.outlineVariant),
          ),
        ),
        inputDecorationTheme: actual.inputDecorationTheme.copyWith(
          border: borde,
          enabledBorder: borde.copyWith(
            borderSide: BorderSide(color: esquema.outlineVariant),
          ),
          focusedBorder: borde.copyWith(
            borderSide: BorderSide(color: esquema.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        chipTheme: actual.chipTheme.copyWith(
          backgroundColor: esquema.surfaceContainerLow,
          selectedColor: esquema.primaryContainer,
          labelStyle: actual.textTheme.labelLarge?.copyWith(
            color: esquema.onSurface,
          ),
          side: BorderSide(color: esquema.outlineVariant),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        floatingActionButtonTheme: actual.floatingActionButtonTheme.copyWith(
          backgroundColor: ColorSchema.primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        bottomSheetTheme: actual.bottomSheetTheme.copyWith(
          backgroundColor: esquema.surface,
          surfaceTintColor: Colors.transparent,
        ),
      ),
      child: child,
    );
  }
}
