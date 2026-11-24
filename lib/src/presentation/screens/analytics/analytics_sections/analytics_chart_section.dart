import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/monthly_movement.dart';
import 'package:teki_app/src/domain/repositories/monthly_movement_repository.dart';
import 'package:teki_app/src/data/repositories/monthly_movement_impl.dart';
import 'package:teki_app/src/utils/constants.dart';

class AnalyticsChartSection extends StatefulWidget {
  final int id;

  const AnalyticsChartSection({super.key, required this.id});

  final Color leftBarColor = const Color(0xFF4A80E9);  // Ingresos
  final Color rightBarColor = const Color(0xFF44DF9D); // Egresos
  final Color avgColor = const Color(0xFFFFA641);       // Ganancia

  @override
  State<AnalyticsChartSection> createState() => _AnalyticsChartSectionState();
}

class _AnalyticsChartSectionState extends State<AnalyticsChartSection> {
  final MovementMonthRepository repository = MovementMonthRepositoryImpl();
  late Future<List<MonthlyMovement>> futureMovements;

  @override
  void initState() {
    super.initState();
    futureMovements = repository.getMovementsBySalePoint(widget.id);
  }

  @override
  void didUpdateWidget(covariant AnalyticsChartSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      setState(() {
        futureMovements = repository.getMovementsBySalePoint(widget.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonthlyMovement>>(
      future: futureMovements,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final data = snapshot.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('No hay datos para mostrar.'));
        }

        final rawBarGroups = List.generate(data.length, (index) {
          final item = data[index];
          final ingreso  = item.totalIngresos.toDouble();
          final egreso   = item.totalEgresos.toDouble();
          final ganancia = (ingreso - egreso).clamp(0, double.infinity).toDouble();
          return makeGroupData(index, ingreso, egreso, ganancia);
        });

        final screenWidth = MediaQuery.of(context).size.width;
        final chartWidth = (data.length * 130.0).clamp(screenWidth - 32, double.infinity);

        final chart = SizedBox(
          width: chartWidth,
          height: 280,
          child: BarChart(
            BarChartData(
              groupsSpace: 24,
              maxY: _calculateMaxY(data),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => const Color(0xFF2D2D2D),
                  fitInsideVertically: true,
                  fitInsideHorizontally: true,
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final labels = ['Ingresos', 'Egresos', 'Ganancia'];
                    final colors = [widget.leftBarColor, widget.rightBarColor, widget.avgColor];
                    return BarTooltipItem(
                      '${data[group.x].periodo}\n',
                      GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      children: [
                        TextSpan(
                          text: '${labels[rodIndex]}: ${rod.toY.toStringAsFixed(2)}',
                          style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: colors[rodIndex]),
                        ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 || i >= data.length) return const SizedBox.shrink();
                      return SideTitleWidget(
                        meta: meta,
                        space: 8,
                        child: Text(data[i].periodo, style: GoogleFonts.roboto(fontSize: 11)),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 60,
                    interval: _getInterval(data),
                    getTitlesWidget: (value, meta) {
                      if (value == meta.min || value == meta.max) return const SizedBox.shrink();
                      final text = value >= 1000
                          ? '${(value / 1000).toStringAsFixed(0)}K'
                          : value.toStringAsFixed(0);
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(text, style: GoogleFonts.roboto(fontSize: 11)),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: rawBarGroups,
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                horizontalInterval: _getInterval(data),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withValues(alpha: 0.3),
                  strokeWidth: 1,
                  dashArray: [5, 4],
                ),
              ),
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Text(
                  'Ingresos vs. Egresos',
                  style: GoogleFonts.raleway(
                    textStyle: TextStyle(
                      color: ColorSchema.primaryColor.withValues(alpha: 0.7),
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: chart,
              ),
              const SizedBox(height: 12),
              Center(child: _legend()),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  double _calculateMaxY(List<MonthlyMovement> data) {
    final maxIngreso  = data.map((e) => e.totalIngresos).reduce((a, b) => a > b ? a : b);
    final maxEgreso   = data.map((e) => e.totalEgresos).reduce((a, b) => a > b ? a : b);
    final maxGanancia = data
        .map((e) => (e.totalIngresos - e.totalEgresos).clamp(0, double.infinity))
        .reduce((a, b) => a > b ? a : b);
    return [maxIngreso, maxEgreso, maxGanancia].reduce((a, b) => a > b ? a : b) * 1.2;
  }

  double _getInterval(List<MonthlyMovement> data) {
    final maxY = _calculateMaxY(data);
    if (maxY > 50000) return 10000;
    if (maxY > 10000) return 2000;
    if (maxY > 5000)  return 1000;
    if (maxY > 1000)  return 500;
    if (maxY > 100)   return 50;
    return 10;
  }

  BarChartGroupData makeGroupData(int x, double ingreso, double egreso, double ganancia) {
    return BarChartGroupData(
      x: x,
      barsSpace: 4,
      barRods: [
        BarChartRodData(toY: ingreso,  color: widget.leftBarColor,  width: 18, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: egreso,   color: widget.rightBarColor, width: 18, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: ganancia, color: widget.avgColor,      width: 18, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _legend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem(widget.leftBarColor, 'Ingresos'),
        const SizedBox(width: 10),
        _legendItem(widget.rightBarColor, 'Egresos'),
        const SizedBox(width: 10),
        _legendItem(widget.avgColor, 'Ganancia'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.roboto(fontSize: 12)),
      ],
    );
  }
}
