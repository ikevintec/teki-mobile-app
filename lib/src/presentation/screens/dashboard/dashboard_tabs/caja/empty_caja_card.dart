import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estado vacío de la tarjeta de balance: no existe caja para la fecha
// seleccionada (distinto de una caja aperturada sin movimientos).
// ─────────────────────────────────────────────────────────────────────────────

class EmptyCajaCard extends StatelessWidget {
  final DateTime fecha;

  /// Acción "Aperturar caja". Null oculta el botón (sin permiso
  /// CAJA_APERTURAR).
  final VoidCallback? onAperturar;

  const EmptyCajaCard({super.key, required this.fecha, this.onAperturar});

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
          if (onAperturar != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onAperturar,
              icon: const Icon(Icons.lock_open_rounded, size: 17),
              label: const Text('Aperturar caja'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.roboto(
                    fontSize: 13, fontWeight: FontWeight.w600),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
