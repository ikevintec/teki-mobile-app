import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Keeps the container forms aligned with the app's blue identity.
class ContainerFormStyle extends StatelessWidget {
  final Widget child;
  const ContainerFormStyle({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: ColorSchema.primaryColor,
        ),
        inputDecorationTheme: InputDecorationTheme(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(44, 48),
            backgroundColor: ColorSchema.primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

class ContainerSheetHeader extends StatelessWidget {
  final String title;
  final bool saving;
  const ContainerSheetHeader({
    super.key,
    required this.title,
    this.saving = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ),
      IconButton(
        tooltip: 'Cerrar',
        onPressed: saving ? null : () => Navigator.of(context).pop(),
        icon: const Icon(Icons.close),
      ),
    ],
  );
}
