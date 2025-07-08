import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:teki_app/src/presentation/screens/comprobantes/list_comprobantes.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';

import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';

import 'package:teki_app/src/utils/contstants.dart';

final filtroDesdeProvider = StateProvider<DateTime?>((ref) => null);
final filtroHastaProvider = StateProvider<DateTime?>((ref) => null);

class VerComprobanteScreen extends ConsumerStatefulWidget {
  const VerComprobanteScreen({super.key});

  @override
  ConsumerState<VerComprobanteScreen> createState() =>
      _VerComprobanteScreenState();
}

class _VerComprobanteScreenState extends ConsumerState<VerComprobanteScreen> {
  void _handleDateRangeChanged(DateTimeRange range) {
    final provider = ref.read(comprobantesSaleProvider.notifier);
    final desde = DateFormat('dd-MM-yyyy H:mm:ss').format(DateTime(
        range.start.year, range.start.month, range.start.day, 0, 0, 0));
    final hasta = DateFormat('dd-MM-yyyy H:mm:ss').format(
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59));
    provider.loadFirstPage(desde, hasta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ver Comprobante',
            style: TextStyle(color: Colors.white)),
        backgroundColor: ColorSchema.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          CustomDatePicker(
            onDateSelected: (range) {
              print("Selected range: ${range.start} - ${range.end}");
              _handleDateRangeChanged(range);
            },
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalesSection(),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Comprobantes:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: TicketListSection(),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  ///Listado Totales
  Widget _buildTotalesSection() {
    final items = ref.watch(comprobantesSaleProvider).totalesPorMoneda;

    if (items.isEmpty) return const SizedBox.shrink();

    String simbolo(String moneda) {
      switch (moneda) {
        case 'PEN':
          return 'S/';
        case 'USD':
          return '\$';
        case 'EUR':
          return '€';
        default:
          return '';
      }
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: items.map((item) {
          final total = item.totalFacturas +
              item.totalBoletas +
              item.totalNotasVenta -
              item.totalNotasCredito +
              item.totalNotasDebito;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: RichText(
              text: TextSpan(
                style: GoogleFonts.raleway(
                  fontSize: 15,
                  color: Colors.black,
                ),
                children: [
                  const TextSpan(
                    text: 'Total:  ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(
                    text:
                        '${simbolo(item.codigoMoneda)} ${total.toStringAsFixed(2)}',
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
