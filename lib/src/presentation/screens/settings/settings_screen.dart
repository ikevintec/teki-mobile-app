import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/printer/ble_printer.dart';
import 'package:teki_app/src/routes/app_routes.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(sesionProvider);
    final companies = config.companies;
    final puntosVenta = config.offices;
    final saleStations = config.saleStations;

    final selectedCompany = config.companySelected;
    final selectedOffice = config.office;
    final selectedSaleStation = config.saleStation;

    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar (
          navigateName: "Configuración",
        ),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        color: const Color.fromARGB(255, 222, 242, 255).withOpacity(0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Empresa'),
            _buildDropdown(
              value: selectedCompany,
              items: companies
                  ?.map((company) => DropdownMenuItem(
                        value: company,
                        child: Text(company.razonSocial ?? 'Sin nombre'),
                      ))
                  .toList(),
              // Cambiar de empresa adjunta requiere permiso (paridad web);
              // sin él, el selector se muestra deshabilitado.
              onChanged: !ref
                      .watch(sesionProvider)
                      .hasPermission('SELECCIONAR_EMPRESAS_ADJUNTAS')
                  ? null
                  : (Companysummary? value) {
                      ref.read(sesionProvider.notifier).changeCompany(value!);
                    },
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Punto de Venta'),
            _buildDropdown(
              value: selectedOffice,
              items: puntosVenta
                  ?.map((office) => DropdownMenuItem(
                        value: office,
                        child: Text(office.nombre ?? 'Sin nombre'),
                      ))
                  .toList(),
              onChanged: (value) {
                ref.read(sesionProvider.notifier).changeOffice(value!, true);
              },
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Estación de Venta'),
            _buildDropdown(
              value: selectedSaleStation,
              items: saleStations
                  ?.map((station) => DropdownMenuItem(
                        value: station,
                        child: Text(station.nombre ?? 'Sin nombre'),
                      ))
                  .toList(),
              onChanged: (value) {
                ref.read(sesionProvider.notifier).changeSaleStation(value!);
              },
            ),
            const SizedBox(height: 20),
            _buildSectionTitle('Impresoras'),
            _buildPrinterEntry(ref),
          ],
        ),
      ),
    );
  }

  /// Acceso a la configuración de la impresora térmica Bluetooth (BLE).
  Widget _buildPrinterEntry(WidgetRef ref) {
    final printerState = ref.watch(blePrinterProvider);
    final printer = printerState.savedPrinter;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Get.toNamed(AppRoutes.printerSettings),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 3, offset: Offset(0, 1)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.print_rounded, size: 20, color: Colors.black54),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  printer != null
                      ? '${printer.name} · Bluetooth BLE'
                      : 'Configurar impresora Bluetooth',
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.black38),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
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
    required ValueChanged<T?>? onChanged,
  }) {
    return Container(
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
    );
  }
}
