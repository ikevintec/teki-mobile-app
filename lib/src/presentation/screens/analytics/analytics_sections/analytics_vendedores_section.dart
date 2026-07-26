import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/response/dashboard_analytics.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_insights_common.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Ranking de vendedores del mes (paridad web: ventas-vendor →
/// GET /summary-vendedores). Top 5 en PEN.
class AnalyticsVendedoresSection extends StatefulWidget {
  final int id;

  const AnalyticsVendedoresSection({super.key, required this.id});

  @override
  State<AnalyticsVendedoresSection> createState() =>
      _AnalyticsVendedoresSectionState();
}

class _AnalyticsVendedoresSectionState
    extends State<AnalyticsVendedoresSection> {
  final _repo = DashboardRepositoryImpl();
  List<VendorSummary> _vendedores = [];
  bool _loading = true;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnalyticsVendedoresSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _load();
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() => _loading = true);
    try {
      final result = await _repo.getVendorsSummary({
        ...analyticsMonthParams(widget.id),
        'page': '0',
        'size': '5',
        'moneda': 'PEN',
      });
      if (mounted && seq == _loadSeq) setState(() => _vendedores = result);
    } catch (_) {
      // Silencioso: la card se oculta si no hay datos.
      if (mounted && seq == _loadSeq) setState(() => _vendedores = []);
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsInsightCard(
      icon: Icons.people_outline_rounded,
      title: 'Ventas por vendedor',
      subtitle: '· este mes',
      loading: _loading,
      visible: _loading || _vendedores.isNotEmpty,
      child: Column(
        children: [
          for (var i = 0; i < _vendedores.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                border: i < _vendedores.length - 1
                    ? Border(
                        bottom: BorderSide(color: Colors.grey.shade200, width: 0.7),
                      )
                    : null,
              ),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: i == 0
                          ? ColorSchema.primaryColor.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${i + 1}',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: i == 0
                              ? ColorSchema.primaryColor
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _vendedores[i].nombreVendedor,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '${_vendedores[i].cantidadVentas} venta(s)',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'S/ ${fmtMontoAnalytics(_vendedores[i].totalVentas)}',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
