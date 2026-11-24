import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/response/dashboard_analytics.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_insights_common.dart';

/// Dona de ventas por categoría del mes actual (paridad web:
/// ventas-categoria → GET /total-categories).
class AnalyticsCategoriasSection extends StatefulWidget {
  final int id;

  const AnalyticsCategoriasSection({super.key, required this.id});

  @override
  State<AnalyticsCategoriasSection> createState() =>
      _AnalyticsCategoriasSectionState();
}

class _AnalyticsCategoriasSectionState
    extends State<AnalyticsCategoriasSection> {
  static const _colors = [
    Color(0xFF534AB7),
    Color(0xFF1D9E75),
    Color(0xFFD85A30),
    Color(0xFF378ADD),
    Color(0xFFD4537E),
    Color(0xFFB4B2A9),
  ];

  final _repo = DashboardRepositoryImpl();
  List<TotalCategory> _categorias = [];
  bool _loading = true;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnalyticsCategoriasSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _load();
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() => _loading = true);
    try {
      final result =
          await _repo.getTotalCategories(analyticsMonthParams(widget.id));
      result.sort((a, b) => b.total.compareTo(a.total));
      if (mounted && seq == _loadSeq) setState(() => _categorias = result);
    } catch (_) {
      // Silencioso: la card se oculta si no hay datos.
      if (mounted && seq == _loadSeq) setState(() => _categorias = []);
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  /// Top 5 categorías + agregado "Otras" (mismo criterio visual del mockup:
  /// la dona pierde legibilidad con más de 6 segmentos en el celular).
  List<TotalCategory> get _segmentos {
    final conVenta = _categorias.where((c) => c.total > 0).toList();
    if (conVenta.length <= 6) return conVenta;
    final top = conVenta.take(5).toList();
    final otras = conVenta
        .skip(5)
        .fold(0.0, (s, c) => s + c.total);
    return [...top, TotalCategory(categoria: 'Otras', total: otras)];
  }

  @override
  Widget build(BuildContext context) {
    final segmentos = _segmentos;
    final total = segmentos.fold(0.0, (s, c) => s + c.total);

    return AnalyticsInsightCard(
      icon: Icons.donut_small_outlined,
      title: 'Ventas por categoría',
      subtitle: '· este mes',
      loading: _loading,
      visible: _loading || segmentos.isNotEmpty,
      child: total <= 0
          ? const SizedBox.shrink()
          : Row(
              children: [
                SizedBox(
                  width: 110,
                  height: 110,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                      sections: [
                        for (var i = 0; i < segmentos.length; i++)
                          PieChartSectionData(
                            value: segmentos[i].total,
                            color: _colors[i % _colors.length],
                            radius: 24,
                            showTitle: false,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < segmentos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 5),
                          child: Row(
                            children: [
                              Container(
                                width: 9,
                                height: 9,
                                decoration: BoxDecoration(
                                  color: _colors[i % _colors.length],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  segmentos[i].categoria,
                                  style: GoogleFonts.roboto(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                '${(segmentos[i].total / total * 100).toStringAsFixed(0)}%',
                                style: GoogleFonts.roboto(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
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
