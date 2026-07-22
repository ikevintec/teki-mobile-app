import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/cash_register_detail.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_movimiento_screen.dart';
import 'package:teki_app/src/utils/formats.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Item del historial
// ─────────────────────────────────────────────────────────────────────────────

class HistorialItem extends StatelessWidget {
  final CashRegisterDetail item;
  final String tipo;

  const HistorialItem({super.key, required this.item, required this.tipo});

  @override
  Widget build(BuildContext context) {
    final isIngreso = tipo == 'INGRESO';
    final amountColor =
        isIngreso ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final iconBgColor = isIngreso
        ? const Color(0xFF16A34A).withValues(alpha: 0.1)
        : const Color(0xFFDC2626).withValues(alpha: 0.1);
    final symbol = formatExchange(moneda: item.monedaMovimientoCaja ?? 'PEN');
    final monto = item.monto ?? 0.0;
    final hora = item.fechaMovimiento != null
        ? DateFormat('HH:mm', 'es').format(item.fechaMovimiento!)
        : '';
    final usuario = item.usuario?.nombreCompleto ?? '';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => CajaMovimientoScreen(item: item),
        ),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icono
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isIngreso
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Descripción + usuario
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.descripcion ?? item.conceptoMovimientoCaja ?? '-',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F1F1F),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (usuario.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    usuario,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Monto + hora
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$symbol${monto.toStringAsFixed(2)}',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: amountColor,
                ),
              ),
              if (hora.isNotEmpty) ...[
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey.shade400),
                    const SizedBox(width: 3),
                    Text(
                      hora,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    ),
    );
  }
}
