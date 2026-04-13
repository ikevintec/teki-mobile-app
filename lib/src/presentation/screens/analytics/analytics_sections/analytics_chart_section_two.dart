import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:teki_app/src/data/models/teki_model/monthlySales.dart';
import 'package:teki_app/src/domain/repositories/monthlySales_repository.dart';
import 'package:teki_app/src/data/repositories/monthlysales_impl.dart';
import 'package:teki_app/src/utils/contstants.dart';

class AnalyticsChartSectionTwo extends StatefulWidget {
  final int id;

  const AnalyticsChartSectionTwo({super.key, required this.id});

  final List<Color> barColors = const [
    Color(0xFF4A80E9), // Facturas
    Color(0xFF44DF9D), // Boletas
    Color(0xFFFFA641), // Notas de Venta
    Color(0xFFEF476F), // Notas de Crédito
    Color(0xFF6A4C93), // Notas de Débito
  ];

  @override
  State<AnalyticsChartSectionTwo> createState() =>
      _AnalyticsChartSectionTwoState();
}

class _AnalyticsChartSectionTwoState extends State<AnalyticsChartSectionTwo> {
  final double width = 8;
  final MonthlySalesRepository repository = MonthlySalesRepositoryImpl();

  late Future<List<MonthlySales>> futureSales;

  @override
  void initState() {
    super.initState();
    futureSales = repository.getSales(widget.id);
  }

  @override
  void didUpdateWidget(covariant AnalyticsChartSectionTwo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.id != widget.id) {
      setState(() {
        futureSales = repository.getSales(widget.id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MonthlySales>>(
      future: futureSales,
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
          final f = item.totalFacturas.toDouble();
          final b = item.totalBoletas.toDouble();
          final nv = item.totalNotasVenta.toDouble();
          final nc = item.totalNotasCredito.toDouble();
          final nd = item.totalNotasDebito.toDouble();
          final total = f + b + nv + nc + nd;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: total,
                width: 28,
                borderRadius: BorderRadius.circular(6),
                rodStackItems: [
                  BarChartRodStackItem(0, f, widget.barColors[0]),
                  BarChartRodStackItem(f, f + b, widget.barColors[1]),
                  BarChartRodStackItem(f + b, f + b + nv, widget.barColors[2]),
                  BarChartRodStackItem(f + b + nv, f + b + nv + nc, widget.barColors[3]),
                  BarChartRodStackItem(f + b + nv + nc, total, widget.barColors[4]),
                ],
              ),
            ],
          );
        });

        final screenWidth = MediaQuery.of(context).size.width;
        final chartWidth = (data.length * 90.0).clamp(screenWidth - 32, double.infinity);

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
                    final item = data[group.x];
                    return BarTooltipItem(
                      '${item.periodo}\n',
                      GoogleFonts.roboto(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      children: [
                        if (item.totalFacturas > 0)
                          TextSpan(
                            text: 'Facturas: ${item.totalFacturas.toStringAsFixed(2)}\n',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: widget.barColors[0]),
                          ),
                        if (item.totalBoletas > 0)
                          TextSpan(
                            text: 'Boletas: ${item.totalBoletas.toStringAsFixed(2)}\n',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: widget.barColors[1]),
                          ),
                        if (item.totalNotasVenta > 0)
                          TextSpan(
                            text: 'Notas Venta: ${item.totalNotasVenta.toStringAsFixed(2)}\n',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: widget.barColors[2]),
                          ),
                        if (item.totalNotasCredito > 0)
                          TextSpan(
                            text: 'Notas Crédito: ${item.totalNotasCredito.toStringAsFixed(2)}\n',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: widget.barColors[3]),
                          ),
                        if (item.totalNotasDebito > 0)
                          TextSpan(
                            text: 'Notas Débito: ${item.totalNotasDebito.toStringAsFixed(2)}',
                            style: GoogleFonts.roboto(fontSize: 11, fontWeight: FontWeight.w600, color: widget.barColors[4]),
                          ),
                      ],
                    );
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 42,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() < data.length) {
                        return SideTitleWidget(
                          meta: meta,
                          space: 8,
                          child: Text(data[value.toInt()].periodo, style: GoogleFonts.roboto(fontSize: 11)),
                        );
                      }
                      return const SizedBox();
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
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                horizontalInterval: _getInterval(data),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                  dashArray: [4, 4],
                ),
                drawVerticalLine: false,
              ),
              borderData: FlBorderData(show: false),
              barGroups: rawBarGroups,
            ),
          ),
        );

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Text(
                  'Ventas por Mes',
                  style: GoogleFonts.raleway(
                    textStyle: TextStyle(
                      color: ColorSchema.primaryColor.withOpacity(0.8),
                      fontSize: screenWidth * 0.06,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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
              Center(child: makeLegend()),
            ],
          ),
        );
      },
    );
  }

  double _calculateMaxY(List<MonthlySales> data) {
    return data
            .map((e) => e.totalFacturas + e.totalBoletas + e.totalNotasVenta + e.totalNotasCredito + e.totalNotasDebito)
            .reduce((a, b) => a > b ? a : b) *
        1.2;
  }

  double _getInterval(List<MonthlySales> data) {
    final maxY = _calculateMaxY(data);
    if (maxY > 50000) return 10000;
    if (maxY > 10000) return 2000;
    if (maxY > 5000) return 1000;
    if (maxY > 1000) return 500;
    if (maxY > 100) return 50;
    return 10;
  }

  Widget makeLegend() {
    final labels = [
      'Facturas',
      'Boletas',
      'Notas Venta',
      'Notas Crédito',
      'Notas Débito'
    ];
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      children: List.generate(labels.length, (index) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 10, height: 10, color: widget.barColors[index]),
            const SizedBox(width: 4),
            Text(labels[index], style: GoogleFonts.roboto(fontSize: 12)),
          ],
        );
      }),
    );
  }
}
