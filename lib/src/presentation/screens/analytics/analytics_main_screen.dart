import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_chart_section.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_chart_section_two.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_reports_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';

class AnalyticsMainScreen extends StatelessWidget {
  const AnalyticsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Analytics"),
      ),
      body: Container(
        color: Colors.white70,
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            AnalyticsReportSection(),
            SizedBox(
              height: 20,
            ),
            AnalyticsChartSection(),
            SizedBox(
              height: 20,
            ),
            AnalyticsChartSectionTwo(),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }
}
