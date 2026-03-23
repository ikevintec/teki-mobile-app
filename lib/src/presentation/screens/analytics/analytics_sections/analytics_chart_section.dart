import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/monthlyMovement.dart';
import 'package:teki_app/src/domain/repositories/monthlyMovement_repository.dart';
import 'package:teki_app/src/data/repositories/monthlyMovement_impl.dart';
import 'package:teki_app/src/utils/contstants.dart';

class AnalyticsChartSection extends StatefulWidget {
  final int id;

  const AnalyticsChartSection({super.key, required this.id});

  final Color leftBarColor = const Color(0xFF4A80E9); // Ingresos
  final Color rightBarColor = const Color(0xFF44DF9D); // Egresos
  final Color avgColor = const Color(0xFFFFA641); // Ganancia

  @override
  State<AnalyticsChartSection> createState() => _AnalyticsChartSectionState();
}

class _AnalyticsChartSectionState extends State<AnalyticsChartSection> {
  final double width = 10;
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
          final ingreso = item.totalIngresos.toDouble();
          final egreso = item.totalEgresos.toDouble();
          final ganancia =
              (ingreso - egreso).clamp(0, double.infinity).toDouble();

          return makeGroupData(index, ingreso, egreso, ganancia);
        });

        return AspectRatio(
          aspectRatio: 1.2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Center(
                  child: Text(
                    'Ingresos vs. Egresos',
                    style: GoogleFonts.raleway(
                      textStyle: TextStyle(
                        color: ColorSchema.primaryColor.withOpacity(0.7),
                        fontSize: MediaQuery.of(context).size.width * 0.06,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: BarChart(
                    BarChartData(
                      maxY: _calculateMaxY(data),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final label =
                                ['Ingresos', 'Egresos', 'Ganancia'][rodIndex];
                            return BarTooltipItem(
                              '$label\n${rod.toY.toStringAsFixed(2)}',
                              GoogleFonts.nunito(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 42,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() < data.length) {
                                return SideTitleWidget(
                                  meta: meta,
                                  space: 8,
                                  child: Text(
                                    data[value.toInt()].periodo,
                                    style: GoogleFonts.nunito(fontSize: 11),
                                  ),
                                );
                              }
                              return const SizedBox();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: _getInterval(data),
                            getTitlesWidget: (value, meta) {
                              final text = value >= 1000
                                  ? '${(value / 1000).toStringAsFixed(0)}K'
                                  : value.toStringAsFixed(0);
                              return SideTitleWidget(
                                meta: meta,
                                child: Text(
                                  text,
                                  style: GoogleFonts.nunito(fontSize: 11),
                                ),
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
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.3),
                            strokeWidth: 1,
                            dashArray: [5, 4],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(child: makeTransactionsIcon()),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  double _calculateMaxY(List<MonthlyMovement> data) {
    final maxIngreso =
        data.map((e) => e.totalIngresos).reduce((a, b) => a > b ? a : b);
    final maxEgreso =
        data.map((e) => e.totalEgresos).reduce((a, b) => a > b ? a : b);
    final maxGanancia = data
        .map(
            (e) => (e.totalIngresos - e.totalEgresos).clamp(0, double.infinity))
        .reduce((a, b) => a > b ? a : b);
    return [maxIngreso, maxEgreso, maxGanancia]
            .reduce((a, b) => a > b ? a : b) *
        1.2;
  }

  double _getInterval(List<MonthlyMovement> data) {
    final maxY = _calculateMaxY(data);
    if (maxY > 50000) return 10000;
    if (maxY > 10000) return 2000;
    if (maxY > 5000) return 1000;
    if (maxY > 1000) return 500;
    if (maxY > 100) return 50;
    return 10;
  }

  BarChartGroupData makeGroupData(
      int x, double ingreso, double egreso, double ganancia) {
    return BarChartGroupData(
      barsSpace: 4,
      x: x,
      barRods: [
        BarChartRodData(toY: ingreso, color: widget.leftBarColor, width: width),
        BarChartRodData(toY: egreso, color: widget.rightBarColor, width: width),
        BarChartRodData(toY: ganancia, color: widget.avgColor, width: width),
      ],
    );
  }

  Widget makeTransactionsIcon() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legend(widget.leftBarColor, 'Ingresos'),
        const SizedBox(width: 10),
        _legend(widget.rightBarColor, 'Egresos'),
        const SizedBox(width: 10),
        _legend(widget.avgColor, 'Ganancia'),
      ],
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.nunito(fontSize: 12)),
      ],
    );
  }
}
