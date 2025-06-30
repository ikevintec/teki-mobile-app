import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_chart_section.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_chart_section_two.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_reports_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class AnalyticsMainScreen extends ConsumerWidget {
  const AnalyticsMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sesionProvider);
    final id = config.office?.id ?? 0;
    final puntoVentaNombre = config.office?.nombre ?? 'No definido';

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: "Dashboard"),
      ),
      body: Container(
        color: Colors.white70,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "Punto de venta actual: $puntoVentaNombre",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                  ),
                  InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      Get.toNamed(AppRoutes.settings);
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorSchema.primaryColor,
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            AnalyticsReportSection(idPuntoVenta: id),
            const SizedBox(height: 20),
            AnalyticsChartSection(id: id),
            const SizedBox(height: 20),
            AnalyticsChartSectionTwo(id: id),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}
