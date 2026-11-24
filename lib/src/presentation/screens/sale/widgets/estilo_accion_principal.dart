import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Botón de la acción principal de venta y cotización (Continuar, Confirmar,
/// Finalizar Pago). Mismas medidas que "Enviar pedido": 48 de alto, esquinas
/// de 12 y sin sombra.
final ButtonStyle estiloAccionPrincipal = ElevatedButton.styleFrom(
  backgroundColor: ColorSchema.primaryColor,
  foregroundColor: Colors.white,
  disabledBackgroundColor: ColorSchema.primaryColor.withValues(alpha: 0.5),
  disabledForegroundColor: Colors.white,
  minimumSize: const Size(48, 48),
  padding: const EdgeInsets.symmetric(horizontal: 16),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  elevation: 0,
  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
);
