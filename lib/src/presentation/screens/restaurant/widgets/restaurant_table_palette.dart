import 'package:flutter/material.dart';

/// Paleta del mapa de mesas de la web (`mesa-item.component.css`).
/// Mantener estos valores como única fuente para las tarjetas y su leyenda.
abstract final class RestaurantTablePalette {
  static const free = Color(0xFFAFAFAF);
  static const order = Color(0xFF0094FF);
  static const prepared = Color(0xFFF5B500);
  static const paying = Color(0xFF076F00);
  static const foreground = Colors.white;
  static const border = Color(0xFFD6D6D6);
  static const legendText = Color(0xFF4B5563);
}
