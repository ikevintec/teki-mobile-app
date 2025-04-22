import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/utils/contstants.dart';

class LegendElement {
  final String label;
  final Color color;

  LegendElement.created(this.label, this.color);
}

class LegendsListWidget extends StatelessWidget {
  final List<LegendElement> legends;

  const LegendsListWidget({super.key, required this.legends});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: legends.map((legend) {
        return Row(
          children: [
            Container(
              width: 16,
              height: 16,
              color: legend.color,
            ),
            const SizedBox(width: 4),
            Text(legend.label),
          ],
        );
      }).toList(),
    );
  }
}

class AnalyticsChartSectionTwo extends StatelessWidget {
  const AnalyticsChartSectionTwo({super.key});

  final pilateColor = const Color(0xFFFFA641);
  final cyclingColor = const Color(0xFF44DF9D);
  final quickWorkoutColor = const Color(0xFF4A80E9);
  final betweenSpace = 0.2;

  BarChartGroupData generateGroupData(
      int x, double pilates, double quickWorkout, double cycling) {
    return BarChartGroupData(
      x: x,
      groupVertically: true,
      barRods: [
        BarChartRodData(
          fromY: 0,
          toY: pilates,
          color: pilateColor,
          width: 8,
        ),
        BarChartRodData(
          fromY: pilates + betweenSpace,
          toY: pilates + betweenSpace + quickWorkout,
          color: quickWorkoutColor,
          width: 8,
        ),
        BarChartRodData(
          fromY: pilates + betweenSpace + quickWorkout + betweenSpace,
          toY: pilates + betweenSpace + quickWorkout + betweenSpace + cycling,
          color: cyclingColor,
          width: 8,
        ),
      ],
    );
  }

  Widget bottomTitles(double value, TitleMeta meta) {
    final style = GoogleFonts.nunito(
        textStyle: const TextStyle(
      color: Color(0xff7589a2),
      fontWeight: FontWeight.bold,
      fontSize: 10,
    ));
    String text;
    switch (value.toInt()) {
      case 0:
        text = 'JAN';
        break;
      case 1:
        text = 'FEB';
        break;
      case 2:
        text = 'MAR';
        break;
      case 3:
        text = 'APR';
        break;
      case 4:
        text = 'MAY';
        break;
      case 5:
        text = 'JUN';
        break;
      case 6:
        text = 'JUL';
        break;
      case 7:
        text = 'AUG';
        break;
      case 8:
        text = 'SEP';
        break;
      case 9:
        text = 'OCT';
        break;
      case 10:
        text = 'NOV';
        break;
      case 11:
        text = 'DEC';
        break;
      default:
        text = '';
    }
    return SideTitleWidget(
      meta: TitleMeta(
        axisSide: meta.axisSide,
        min: 0.1,
        max: 11.1,
        parentAxisSize: meta.parentAxisSize,
        axisPosition: meta.axisPosition,
        appliedInterval: meta.appliedInterval,
        sideTitles: meta.sideTitles,
        rotationQuarterTurns: meta.rotationQuarterTurns,
        formattedValue: text
      ),
      space: 4,
      angle: 0,
      child: Text(text, style: style),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Activity',
            style: GoogleFonts.raleway(
                textStyle: TextStyle(
              color: ColorSchema.primaryColor.withOpacity(0.7),
              fontSize: MediaQuery.of(context).size.width * 0.045,
              fontWeight: FontWeight.bold,
            )),
          ),
          const SizedBox(height: 8),
          LegendsListWidget(
            legends: [
              LegendElement.created(
                'Pilates     ',
                pilateColor,
              ),
              LegendElement.created('Quick workouts    ', quickWorkoutColor),
              LegendElement.created('Cycling     ', cyclingColor),
            ],
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 2,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceBetween,
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(),
                  rightTitles: const AxisTitles(),
                  topTitles: const AxisTitles(),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: bottomTitles,
                      reservedSize: 20,
                    ),
                  ),
                ),
                barTouchData: BarTouchData(enabled: true),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: true),
                barGroups: [
                  generateGroupData(0, 2, 3, 2),
                  generateGroupData(1, 2, 5, 1.7),
                  generateGroupData(2, 1.3, 3.1, 2.8),
                  generateGroupData(3, 3.1, 4, 3.1),
                  generateGroupData(4, 0.8, 3.3, 3.4),
                  generateGroupData(5, 2, 5.6, 1.8),
                  generateGroupData(6, 1.3, 3.2, 2),
                  generateGroupData(7, 2.3, 3.2, 3),
                  generateGroupData(8, 2, 4.8, 2.5),
                  generateGroupData(9, 1.2, 3.2, 2.5),
                  generateGroupData(10, 1, 4.8, 3),
                  generateGroupData(11, 2, 4.4, 2.8),
                ],
                maxY: 11 + (betweenSpace * 3),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: 3.3,
                      color: pilateColor,
                      strokeWidth: 1,
                      dashArray: [20, 4],
                    ),
                    HorizontalLine(
                      y: 8,
                      color: quickWorkoutColor,
                      strokeWidth: 1,
                      dashArray: [20, 4],
                    ),
                    HorizontalLine(
                      y: 11,
                      color: cyclingColor,
                      strokeWidth: 1,
                      dashArray: [20, 4],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
