import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PastCashRegisterBanner extends StatelessWidget {
  final DateTime fecha;
  final VoidCallback onTap;

  const PastCashRegisterBanner({
    super.key,
    required this.fecha,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fechaLabel = DateFormat('dd/MM/yyyy').format(fecha);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Material(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFE082)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFFF57C00),
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'La caja activa tiene una fecha pasada',
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF5D4037),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Las nuevas ventas se registrarán en la caja del '
                      '$fechaLabel hasta que la cierres.',
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF795548),
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: onTap,
                      child: Text(
                        'Ir a la caja activa',
                        style: GoogleFonts.roboto(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFF57C00),
                          decoration: TextDecoration.underline,
                          decorationColor: const Color(0xFFF57C00),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
