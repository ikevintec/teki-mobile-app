import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/response/caja_resumen.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/currency_selector.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/movimiento_item.dart';
import 'package:teki_app/src/providers/cash_register/caja_resumen_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Modo reporte: resumen agregado del rango seleccionado.
// Responde: ¿cuánto gané?, ¿cuánto vendí / en qué gasté?, ¿dónde está mi dinero?
// ─────────────────────────────────────────────────────────────────────────────

class CajaResumenView extends StatelessWidget {
  final CajaResumenState state;
  final String? selectedMoneda;
  final ValueChanged<String> onMonedaChanged;
  final VoidCallback onVerMovimientos;
  final VoidCallback onRetry;

  const CajaResumenView({
    super.key,
    required this.state,
    required this.selectedMoneda,
    required this.onMonedaChanged,
    required this.onVerMovimientos,
    required this.onRetry,
  });

  String _fmt(String moneda, double v) =>
      '${formatExchange(moneda: moneda)}${v.toStringAsFixed(2)}';

  String get _rangoLabel {
    final range = state.range;
    if (range == null) return '';
    final fmt = DateFormat('dd MMM', 'es');
    return '${fmt.format(range.start)} – ${fmt.format(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
            color: ColorSchema.primaryColor, strokeWidth: 2),
      );
    }
    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 44),
            const SizedBox(height: 10),
            Text('No se pudo cargar el resumen',
                style: GoogleFonts.roboto(
                    fontSize: 14, color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                  foregroundColor: ColorSchema.primaryColor),
            ),
          ],
        ),
      );
    }

    final resumen = state.resumen;
    if (resumen == null || resumen.totales.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.query_stats_rounded,
                  color: Colors.grey.shade400, size: 26),
            ),
            const SizedBox(height: 12),
            Text('Sin movimientos en el periodo',
                style: GoogleFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(_rangoLabel,
                style: GoogleFonts.roboto(
                    fontSize: 13, color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    final monedas = resumen.monedas;
    final moneda = (selectedMoneda != null && monedas.contains(selectedMoneda))
        ? selectedMoneda!
        : (monedas.contains('PEN') ? 'PEN' : monedas.first);
    final total = resumen.totalDe(moneda);
    final conceptos = resumen.conceptosDe(moneda);
    final metodos = resumen.porMetodoPago
        .where((m) => m.hasDataForMoneda(moneda))
        .toList()
      ..sort((a, b) =>
          b.gananciaForMoneda(moneda).compareTo(a.gananciaForMoneda(moneda)));

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      children: [
        // ── ¿Cuánto gané? ─────────────────────────────────────────────────
        _card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.query_stats_rounded,
                          color: ColorSchema.primaryColor, size: 21),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Resumen del periodo',
                              style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                          Text(
                            '$_rangoLabel · ${resumen.totalCajas} caja(s)'
                            '${resumen.cajasAbiertas > 0 ? ' · ${resumen.cajasAbiertas} abierta(s)' : ''}',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                    if (monedas.length > 1)
                      CurrencySelector(
                        monedas: monedas,
                        value: moneda,
                        onChanged: onMonedaChanged,
                      ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _fmt(moneda, total?.neto ?? 0),
                    style: GoogleFonts.roboto(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: (total?.neto ?? 0) >= 0
                          ? Colors.grey.shade900
                          : const Color(0xFFDC2626),
                    ),
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 12),
                Row(
                  children: [
                    MovimientoItem(
                      label: 'Ingresos',
                      value: _fmt(moneda, total?.totalIngresos ?? 0),
                      dotColor: const Color(0xFF22C55E),
                      textColor: const Color(0xFF16A34A),
                    ),
                    Container(
                      width: 1,
                      height: 52,
                      color: Colors.grey.shade200,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    MovimientoItem(
                      label: 'Egresos',
                      value: _fmt(moneda, total?.totalEgresos ?? 0),
                      dotColor: const Color(0xFFEF4444),
                      textColor: const Color(0xFFDC2626),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // ── ¿Cuánto vendí / en qué gasté? ─────────────────────────────────
        _sectionTitle('Detalle por concepto'),
        _card(
          child: Column(
            children: [
              for (final c in conceptos) ...[
                _conceptoRow(c, moneda),
                if (c != conceptos.last)
                  Divider(height: 1, indent: 16, endIndent: 16,
                      color: Colors.grey.shade100),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── ¿Dónde está mi dinero? ────────────────────────────────────────
        if (metodos.isNotEmpty) ...[
          _sectionTitle('¿Dónde está mi dinero?'),
          _card(
            child: Column(
              children: [
                for (final m in metodos) ...[
                  _metodoRow(m, moneda),
                  if (m != metodos.last)
                    Divider(height: 1, indent: 16, endIndent: 16,
                        color: Colors.grey.shade100),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ── Drill-down ────────────────────────────────────────────────────
        OutlinedButton.icon(
          onPressed: onVerMovimientos,
          icon: const Icon(Icons.receipt_long_rounded, size: 17),
          label: const Text('Ver movimientos del periodo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorSchema.primaryColor,
            side: BorderSide(
                color: ColorSchema.primaryColor.withValues(alpha: 0.4)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            textStyle:
                GoogleFonts.roboto(fontSize: 13, fontWeight: FontWeight.w600),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _card({required Widget child}) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(
          title,
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _conceptoRow(ConceptoResumen c, String moneda) {
    final esOperativo = c.esOperativo;
    final color = esOperativo
        ? Colors.grey.shade500
        : (c.esIngreso ? const Color(0xFF16A34A) : const Color(0xFFDC2626));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              esOperativo
                  ? (c.esRetiro
                      ? Icons.savings_outlined
                      : c.esPropina
                          ? Icons.volunteer_activism_outlined
                          : Icons.lock_open_rounded)
                  : (c.esIngreso
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded),
              color: color,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.etiqueta,
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: esOperativo
                            ? Colors.grey.shade500
                            : const Color(0xFF1F1F1F))),
                Text('${c.operaciones} operación(es)',
                    style: GoogleFonts.roboto(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
            ),
          ),
          Text(
            _fmt(moneda, c.monto),
            style: GoogleFonts.roboto(
                fontSize: 14, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _metodoRow(dynamic m, String moneda) {
    final neto = m.gananciaForMoneda(moneda) as double;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.account_balance_wallet_outlined,
                color: ColorSchema.primaryColor, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.metodoPago as String,
                    style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F1F1F))),
                Text(
                  'Ing. ${_fmt(moneda, m.ingresoForMoneda(moneda) as double)}'
                  '  ·  Egr. ${_fmt(moneda, m.egresoForMoneda(moneda) as double)}',
                  style: GoogleFonts.roboto(
                      fontSize: 11, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
          Text(
            _fmt(moneda, neto),
            style: GoogleFonts.roboto(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: neto >= 0
                  ? const Color(0xFF16A34A)
                  : const Color(0xFFDC2626),
            ),
          ),
        ],
      ),
    );
  }
}
