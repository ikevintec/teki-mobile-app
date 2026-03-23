import 'package:flutter/material.dart';

class KeyboardDismisser extends StatelessWidget {
  final Widget child;

  const KeyboardDismisser({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final FocusScopeNode focusScope = FocusScope.of(context);
        final FocusNode? focusedChild = focusScope.focusedChild;
        
        // Solo hacer unfocus si no hay un campo actualmente enfocado
        // o si el tap no está cerca de campos de texto
        if (focusedChild != null) {
          // Dar un pequeño delay para permitir que otros campos reciban el focus
          Future.delayed(const Duration(milliseconds: 100), () {
            // Solo hacer unfocus si después del delay no hay un nuevo campo enfocado
            if (focusScope.focusedChild == focusedChild) {
              focusScope.unfocus();
            }
          });
        }
      },
      child: child,
    );
  }
}