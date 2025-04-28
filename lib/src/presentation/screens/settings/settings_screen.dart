import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';

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
      appBar: AppBar(
        title: const Text('Configuración'),
        centerTitle: true,
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
              onChanged: (value) {
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
          ],
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
    required ValueChanged<T?> onChanged,
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
