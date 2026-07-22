import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estado vacío de la tarjeta de balance: no existe caja para la fecha
// seleccionada (distinto de una caja aperturada sin movimientos).
// ─────────────────────────────────────────────────────────────────────────────

class EmptyCajaCard extends StatelessWidget {
  final DateTime fecha;

  const EmptyCajaCard({super.key, required this.fecha});

  bool get _esHoy {
    final now = DateTime.now();
    return fecha.year == now.year &&
        fecha.month == now.month &&
        fecha.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final fechaLabel = _esHoy
        ? 'hoy'
        : 'el ${DateFormat("dd 'de' MMMM", 'es').format(fecha)}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.point_of_sale_rounded,
                color: Colors.grey.shade400, size: 26),
          ),
          const SizedBox(height: 12),
          Text(
            'No hay caja aperturada',
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'para $fechaLabel',
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
