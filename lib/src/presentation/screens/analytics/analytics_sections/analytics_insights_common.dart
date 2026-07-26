import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// Utilidades compartidas por las secciones de insights de analíticas
// (categorías, horarios, vendedores). Mismos filtros que la web: mes
// actual en dd-MM-yyyy + punto de venta.

Map<String, dynamic> analyticsMonthParams(int idPuntoVenta) {
  final now = DateTime.now();
  final fmt = DateFormat('dd-MM-yyyy');
  return {
    'filtroDesde': fmt.format(DateTime(now.year, now.month, 1)),
    'filtroHasta': fmt.format(DateTime(now.year, now.month + 1, 0)),
    'idPuntoVenta': idPuntoVenta.toString(),
  };
}

String fmtMontoAnalytics(double v) =>
    NumberFormat('#,##0.00', 'es_PE').format(v);

/// Card contenedora con título e ícono, estilo del módulo de analíticas.
/// Se oculta sola (SizedBox.shrink) cuando [visible] es false — las
/// secciones sin datos no dejan huecos en la pantalla.
class AnalyticsInsightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool loading;
  final bool visible;
  final Widget child;

  const AnalyticsInsightCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.loading,
    required this.visible,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: Colors.grey.shade700),
                const SizedBox(width: 6),
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(width: 6),
                  Text(
                    subtitle!,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            if (loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else
              child,
          ],
        ),
      ),
    );
  }
}
