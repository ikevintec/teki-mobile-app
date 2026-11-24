import 'package:flutter/material.dart';

/// Franja que dice qué falta para continuar, igual que en pedidos: pintar el
/// campo en rojo no basta para que el usuario sepa qué corregir.
///
/// En venta el botón principal está dentro del cuerpo (no en una barra
/// inferior como en pedidos), así que la franja flota por encima del total y
/// del botón para no taparlos.
void avisarFaltante(BuildContext context, String mensaje) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(mensaje),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 140),
      ),
    );
}
