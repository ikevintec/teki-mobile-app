import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:teki_app/src/data/models/teki_model/totales_comprobantes.dart';
import 'package:teki_app/src/data/models/teki_model/totales_forma_pagos.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/list_comprobantes.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/filter_actions.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/clean_filters_button.dart';

import 'package:teki_app/src/providers/accounts_receivable/seller_provider.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/providers/config/config.dart';

import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';

final filtroDesdeProvider = StateProvider<DateTime?>((ref) => null);
final filtroHastaProvider = StateProvider<DateTime?>((ref) => null);

class VerComprobanteScreen extends ConsumerStatefulWidget {
  const VerComprobanteScreen({super.key});

  @override
  ConsumerState<VerComprobanteScreen> createState() =>
      _VerComprobanteScreenState();
}

class _VerComprobanteScreenState extends ConsumerState<VerComprobanteScreen> {
  @override
  void initState() {
    super.initState();
    // Carga la lista de vendedores una sola vez al entrar a la pantalla, solo
    // si el usuario tiene permiso para ver todos los vendedores. loadOnce()
    // ignora llamadas posteriores, por lo que no se repite al recargar la
    // lista o cambiar de filtro.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(puedeVerTodosVendedoresProvider)) {
        ref.read(sellersProvider.notifier).loadOnce();
      }
    });
  }

  void _reloadWithCurrentDate() {
    final state = ref.read(comprobantesSaleProvider);
    final desde = state.filtroDesde;
    final hasta = state.filtroHasta;
    // ignore: unnecessary_null_comparison
    if (desde != null && hasta != null) {
      ref.read(comprobantesSaleProvider.notifier).loadFirstPage(
            desde: desde,
            hasta: hasta,
          );
    }
  }

  void _handleDateRangeChanged(DateTimeRange range) {
    final provider = ref.read(comprobantesSaleProvider.notifier);
    final desde = DateFormat('dd-MM-yyyy H:mm:ss').format(DateTime(
        range.start.year, range.start.month, range.start.day, 0, 0, 0));
    final hasta = DateFormat('dd-MM-yyyy H:mm:ss').format(
        DateTime(range.end.year, range.end.month, range.end.day, 23, 59, 59));
    provider.loadFirstPage(desde: desde, hasta: hasta);
  }


  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (prev, next) {
      if (next.office?.id != prev?.office?.id) _reloadWithCurrentDate();
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Ver Comprobante',
            style: TextStyle(color: Colors.white)),
        backgroundColor: ColorSchema.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () async {
              await Get.toNamed(AppRoutes.settings);
              if (mounted) _reloadWithCurrentDate();
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only( top: 8.0),
            child: CustomDatePicker(
              onDateSelected: (range) {
                debugPrint("Selected range: ${range.start} - ${range.end}");
                _handleDateRangeChanged(range);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FilterActions(),
                CleanFiltersButton(),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalesSection(),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 5),
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

    // Los totales del periodo son dato sensible (paridad web: VENTAS_VER_TOTALES)
    if (!ref.watch(sesionProvider).hasPermission('VENTAS_VER_TOTALES')) {
      return const SizedBox.shrink();
    }

    double totalDe(TotalesPorMoneda item) =>
        item.totalFacturas +
        item.totalBoletas +
        item.totalNotasVenta -
        item.totalNotasCredito +
        item.totalNotasDebito;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (int i = 0; i < items.length; i++)
                  Padding(
                    padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${simbolo(items[i].codigoMoneda)} ${totalDe(items[i]).toStringAsFixed(2)}',
                          style: GoogleFonts.roboto(
                            fontSize: i == 0 ? 17 : 13,
                            fontWeight: FontWeight.w700,
                            color: i == 0 ? Colors.black87 : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'IGV ${simbolo(items[i].codigoMoneda)} ${items[i].totalIgv.toStringAsFixed(2)}',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => _showDesgloseSheet(items),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Desglose',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ColorSchema.primaryColor,
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    size: 17, color: ColorSchema.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDesgloseSheet(List<TotalesPorMoneda> totales) {
    // Los métodos de pago se consultan solo al abrir el sheet.
    final formasPagoFuture =
        ref.read(comprobantesSaleProvider.notifier).fetchTotalesFormaPago();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DesgloseTotalesSheet(
        totales: totales,
        formasPagoFuture: formasPagoFuture,
      ),
    );
  }
}

/// Sheet con el desglose de totales del filtro actual: por tipo de
/// comprobante (datos ya cargados) y por método de pago (consulta on-demand).
class _DesgloseTotalesSheet extends StatefulWidget {
  final List<TotalesPorMoneda> totales;
  final Future<List<TotalVentasFormaPago>> formasPagoFuture;

  const _DesgloseTotalesSheet({
    required this.totales,
    required this.formasPagoFuture,
  });

  @override
  State<_DesgloseTotalesSheet> createState() => _DesgloseTotalesSheetState();
}

class _DesgloseTotalesSheetState extends State<_DesgloseTotalesSheet> {
  late String _moneda;

  @override
  void initState() {
    super.initState();
    final monedas = widget.totales.map((t) => t.codigoMoneda).toList();
    _moneda = monedas.contains('PEN')
        ? 'PEN'
        : (monedas.isNotEmpty ? monedas.first : 'PEN');
  }

  String _simbolo(String moneda) => switch (moneda) {
        'PEN' => 'S/',
        'USD' => '\$',
        'EUR' => '€',
        _ => moneda,
      };

  String _fmt(double v) => '${_simbolo(_moneda)} ${v.toStringAsFixed(2)}';

  Widget _fila(String label, double monto,
      {bool negativo = false, bool informativo = false}) {
    if (monto == 0) return const SizedBox.shrink();
    final color = negativo
        ? const Color(0xFFC62828)
        : informativo
            ? Colors.grey.shade600
            : Colors.black87;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: GoogleFonts.roboto(fontSize: 13, color: color)),
          ),
          Text(
            '${negativo ? '− ' : ''}${_fmt(monto)}',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: informativo ? FontWeight.w400 : FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grupo(String titulo, List<Widget> filas) {
    final visibles =
        filas.where((f) => f is! SizedBox).toList();
    if (visibles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 4, top: 10),
          child: Text(
            titulo,
            style: GoogleFonts.roboto(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(children: visibles),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final monedas = widget.totales.map((t) => t.codigoMoneda).toList();
    final t = widget.totales.firstWhere(
      (e) => e.codigoMoneda == _moneda,
      orElse: () => widget.totales.first,
    );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Totales del filtro',
                style: GoogleFonts.roboto(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 10),
            if (monedas.length > 1)
              Row(
                children: [
                  for (final m in monedas)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(m, style: const TextStyle(fontSize: 12)),
                        selected: _moneda == m,
                        selectedColor:
                            ColorSchema.primaryColor.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _moneda = m),
                      ),
                    ),
                ],
              ),
            _grupo('POR COMPROBANTE', [
              _fila('Facturas', t.totalFacturas),
              _fila('Boletas', t.totalBoletas),
              _fila('Notas de venta', t.totalNotasVenta),
              _fila('Notas de crédito', t.totalNotasCredito, negativo: true),
              _fila('Notas de débito', t.totalNotasDebito),
              _fila('IGV incluido', t.totalIgv, informativo: true),
            ]),
            FutureBuilder<List<TotalVentasFormaPago>>(
              future: widget.formasPagoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: ColorSchema.primaryColor),
                      ),
                    ),
                  );
                }
                final metodos = (snapshot.data ?? [])
                        .where((e) => e.codigoMoneda == _moneda)
                        .expand((e) => e.metodosPago)
                        .toList()
                      ..sort((a, b) => b.monto.compareTo(a.monto));
                return _grupo('POR MÉTODO DE PAGO', [
                  for (final m in metodos) _fila(m.metodoPago, m.monto),
                ]);
              },
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
