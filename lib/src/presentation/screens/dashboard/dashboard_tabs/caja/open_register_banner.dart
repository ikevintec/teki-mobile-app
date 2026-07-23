import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Aviso de caja aperturada en una fecha distinta a la seleccionada.
// Un tap navega a la fecha de esa caja.
// ─────────────────────────────────────────────────────────────────────────────

class OpenRegisterBanner extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;

  const OpenRegisterBanner({super.key, required this.fecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fechaLabel = DateFormat('dd/MM', 'es').format(fecha);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Material(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE082)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF57C00), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tienes una caja abierta del $fechaLabel',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF795548),
                    ),
                  ),
                ),
                Text(
                  'Ir a esa caja',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF57C00),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: Color(0xFFF57C00), size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
