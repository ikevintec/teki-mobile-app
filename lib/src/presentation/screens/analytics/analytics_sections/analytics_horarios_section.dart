import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/response/dashboard_analytics.dart';
import 'package:teki_app/src/data/repositories/dashboard_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_insights_common.dart';

/// Mejores franjas horarias del mes (paridad web: ventas-horario →
/// GET /sales-by-schedule). La web lo pinta como heatmap día×franja;
/// en el celular se muestra el ranking de las 5 mejores franjas.
class AnalyticsHorariosSection extends StatefulWidget {
  final int id;

  const AnalyticsHorariosSection({super.key, required this.id});

  @override
  State<AnalyticsHorariosSection> createState() =>
      _AnalyticsHorariosSectionState();
}

class _AnalyticsHorariosSectionState extends State<AnalyticsHorariosSection> {
  // Mismos display maps de la web (ventas-horario.component.ts).
  static const _franjas = {'MANANA': 'Mañana', 'TARDE': 'Tarde', 'NOCHE': 'Noche'};
  static const _dias = {
    'LUNES': 'Lun', 'MARTES': 'Mar', 'MIERCOLES': 'Mié', 'JUEVES': 'Jue',
    'VIERNES': 'Vie', 'SABADO': 'Sáb', 'DOMINGO': 'Dom',
  };

  final _repo = DashboardRepositoryImpl();
  List<ScheduleSale> _top = [];
  bool _loading = true;
  int _loadSeq = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AnalyticsHorariosSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) _load();
  }

  Future<void> _load() async {
    final seq = ++_loadSeq;
    setState(() => _loading = true);
    try {
      final result =
          await _repo.getSalesBySchedule(analyticsMonthParams(widget.id));
      result.sort((a, b) => b.totalVentas.compareTo(a.totalVentas));
      if (mounted && seq == _loadSeq) {
        setState(() =>
            _top = result.where((e) => e.totalVentas > 0).take(5).toList());
      }
    } catch (_) {
      // Silencioso: la card se oculta si no hay datos.
      if (mounted && seq == _loadSeq) setState(() => _top = []);
    } finally {
      if (mounted && seq == _loadSeq) setState(() => _loading = false);
    }
  }

  String _label(ScheduleSale s) {
    final dia = _dias[s.diaSemana.toUpperCase()] ?? s.diaSemana;
    final franja = _franjas[s.franjaHoraria.toUpperCase()] ?? s.franjaHoraria;
    return '$dia · $franja';
  }

  @override
  Widget build(BuildContext context) {
    final max = _top.isEmpty ? 1.0 : _top.first.totalVentas;

    return AnalyticsInsightCard(
      icon: Icons.schedule_outlined,
      title: 'Mejores horarios',
      subtitle: '· este mes',
      loading: _loading,
      visible: _loading || _top.isNotEmpty,
      child: Column(
        children: [
          for (final s in _top)
            Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 84,
                    child: Text(
                      _label(s),
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (s.totalVentas / max).clamp(0.05, 1.0),
                        minHeight: 13,
                        backgroundColor: const Color(0xFFF0F2F8),
                        valueColor: AlwaysStoppedAnimation(
                          s == _top.first
                              ? const Color(0xFF378ADD)
                              : const Color(0xFF85B7EB),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 74,
                    child: Text(
                      'S/ ${fmtMontoAnalytics(s.totalVentas)}',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
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
