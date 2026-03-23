import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_chart_section.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_chart_section_two.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_sections/analytics_reports_section.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';


class AnalyticsMainScreen extends ConsumerStatefulWidget {
  const AnalyticsMainScreen({super.key});

  @override
  ConsumerState<AnalyticsMainScreen> createState() =>
      _AnalyticsMainScreenState();
}

class _AnalyticsMainScreenState extends ConsumerState<AnalyticsMainScreen> {
  dynamic selectedOfficeLocal;

  @override
  void initState() {
    super.initState();
    final config = ref.read(sesionProvider);
    selectedOfficeLocal = config.office;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(sesionProvider);
    final id = selectedOfficeLocal?.id ?? 0;

    final puntosVenta = config.offices;

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
                  // Expanded(
                  //   child: Text(
                  //     "Punto de venta actual: $puntoVentaNombre",
                  //     style: const TextStyle(
                  //       fontSize: 16,
                  //       fontWeight: FontWeight.w600,
                  //       color: Color(0xFF333333),
                  //     ),
                  //   ),
                  // ),
                  // InkWell(
                  //   borderRadius: BorderRadius.circular(50),
                  //   onTap: () {
                  //     Get.toNamed(AppRoutes.settings);
                  //   },
                  //   child: Container(
                  //     width: 40,
                  //     height: 40,
                  //     decoration: BoxDecoration(
                  //       color: ColorSchema.primaryColor,
                  //       borderRadius: BorderRadius.circular(50),
                  //     ),
                  //     child: const Icon(
                  //       Icons.tune,
                  //       color: Colors.white,
                  //       size: 24,
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            _buildSectionTitle('  Seleccione un Punto de Venta'),
            _buildDropdown(
              value: selectedOfficeLocal,
              items: puntosVenta
                  ?.map((office) => DropdownMenuItem(
                        value: office,
                        child: Text(office.nombre ?? 'Sin nombre'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedOfficeLocal = value;
                });
              },
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

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>>? items,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
              offset: Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: DropdownButtonFormField<T>(
          value: value,
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14),
          ),
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
