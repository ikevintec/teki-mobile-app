import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/calendar_filter.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/currency_selector.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/historial_item.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/imprimir_caja_modal.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/movimiento_item.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja/tipo_selector.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_tabs/caja_balance_screen.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_detail_provider.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CajaTab extends ConsumerStatefulWidget {
  final ValueNotifier<int> refreshNotifier;

  const CajaTab({super.key, required this.refreshNotifier});

  @override
  ConsumerState<CajaTab> createState() => _CajaTabState();
}

class _CajaTabState extends ConsumerState<CajaTab> {
  String? _selectedMoneda;
  DateTime _selectedDate = DateTime.now();
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    widget.refreshNotifier.addListener(_onRefresh);
    // La carga inicial la dispara CustomDatePicker vía onDateSelected al montarse.
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    widget.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(cashRegisterDetailProvider.notifier).loadMore();
    }
  }

  /// Llamado por refreshNotifier (al volver de una sub-pantalla).
  /// Refresca la fecha actualmente seleccionada.
  void _onRefresh() {
    setState(() => _selectedMoneda = null);
    _fetchCashRegister();
  }

  /// Llamado por CustomDatePicker cada vez que el usuario selecciona una fecha.
  void _onDateChanged(DateTimeRange range) {
    setState(() {
      _selectedDate = range.start;
      _selectedMoneda = null;
    });
    _fetchCashRegister();
  }

  Future<void> _fetchCashRegister() async {
    if (!mounted) return;
    await ref.read(cashRegisterProvider.notifier).fetchAndLoadDetail(
          selectedMoneda: _selectedMoneda,
          fecha: _selectedDate,
        );
  }

  void _loadDetail() {
    ref
        .read(cashRegisterProvider.notifier)
        .loadDetail(selectedMoneda: _selectedMoneda);
  }

  void _onMonedaChanged(String newMoneda) {
    setState(() => _selectedMoneda = newMoneda);
    ref.read(cashRegisterDetailProvider.notifier).changeMoneda(newMoneda);
  }

  String _fmt(Map<String, double> map, String moneda) {
    final symbol = formatExchange(moneda: moneda);
    final v = map[moneda] ?? 0.0;
    return '$symbol${v.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cashRegisterProvider);
    final detailState = ref.watch(cashRegisterDetailProvider);

    final balance = cajaState.balancePorMoneda;
    final ingresos = cajaState.totalIngresosPorMoneda;
    final egresos = cajaState.totalEgresosPorMoneda;

    final monedas = cajaState.monedas;
    final monedaActiva = cajaState.monedaActiva(_selectedMoneda);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Selector de fecha ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.only(top: 0, left: 8, right: 4),
          child: CustomDatePicker(
            onDateSelected: _onDateChanged,
            singleDayPicker: true,
          ),
        ),
        SizedBox(height: 12),
        // ── Tarjeta de balance ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: cajaState.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: ColorSchema.primaryColor,
                        strokeWidth: 2,
                      ),
                    ),
                  )
                : cajaState.error != null
                    ? Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.grey.shade400, size: 44),
                            const SizedBox(height: 10),
                            Text(
                              'No se pudo cargar la caja',
                              style: GoogleFonts.roboto(
                                  fontSize: 14, color: Colors.grey.shade500),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            TextButton.icon(
                              onPressed: () {
                                setState(() => _selectedMoneda = null);
                                _fetchCashRegister();
                              },
                              icon: const Icon(Icons.refresh),
                              label: const Text('Reintentar'),
                              style: TextButton.styleFrom(
                                  foregroundColor: ColorSchema.primaryColor),
                            ),
                          ],
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    color: ColorSchema.primaryColor
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet_rounded,
                                    color: ColorSchema.primaryColor,
                                    size: 21,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Balance',
                                  style: GoogleFonts.roboto(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const Spacer(),
                                if (monedas.length > 1) ...[
                                  CurrencySelector(
                                    monedas: monedas,
                                    value: monedaActiva,
                                    onChanged: _onMonedaChanged,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                GestureDetector(
                                  onTap: () {
                                    setState(() => _selectedMoneda = null);
                                    _fetchCashRegister();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: ColorSchema.primaryColor
                                          .withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.refresh_rounded,
                                      size: 18,
                                      color: ColorSchema.primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                monedas.isEmpty
                                    ? '${formatExchange(moneda: 'PEN')}0.00'
                                    : _fmt(balance, monedaActiva),
                                style: GoogleFonts.roboto(
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ),
                            Divider(
                                height: 1,
                                color: Colors.grey.shade200),
                            const SizedBox(height: 12),
                            monedas.isEmpty
                                ? Center(
                                    child: Text(
                                      'Sin movimientos hoy',
                                      style: GoogleFonts.roboto(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      MovimientoItem(
                                        label: 'Ingresos',
                                        value: _fmt(ingresos, monedaActiva),
                                        dotColor: const Color(0xFF22C55E),
                                        textColor: const Color(0xFF16A34A),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 52,
                                        color: Colors.grey.shade200,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 16),
                                      ),
                                      MovimientoItem(
                                        label: 'Egresos',
                                        value: _fmt(egresos, monedaActiva),
                                        dotColor: const Color(0xFFEF4444),
                                        textColor: const Color(0xFFDC2626),
                                      ),
                                    ],
                                  ),
                          ],
                        ),
                      ),
          ),
        ),

        const SizedBox(height: 12),

        // ── Botón ver balance + imprimir ───────────────────────────────────
        if (!cajaState.isLoading &&
            cajaState.registers.isNotEmpty &&
            cajaState.registers.first.id != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CajaBalanceScreen(
                          idCaja: cajaState.registers.first.id!,
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.bar_chart_rounded, size: 17),
                    label: const Text('Ver balance'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSchema.primaryColor,
                      side: BorderSide(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 1,
                  child: OutlinedButton(
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => ImprimirCajaModal(
                        idCaja: cajaState.registers.first.id!,
                        moneda: monedaActiva,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ColorSchema.primaryColor,
                      side: BorderSide(
                        color: ColorSchema.primaryColor.withValues(alpha: 0.4),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    child: const Icon(Icons.print_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),

        const SizedBox(height: 12),

        // ── Selector Ingresos / Egresos ────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TipoSelector(
            tipo: detailState.tipo,
            isBlocked: detailState.isLoading || detailState.isLoadingMore,
            onChanged: (t) =>
                ref.read(cashRegisterDetailProvider.notifier).changeTipo(t),
          ),
        ),

        const SizedBox(height: 10),

        // ── Historial (solo esta parte scrollea) ───────────────────────────
        Expanded(
          child: _buildHistorialList(detailState, cajaState.isLoading),
        ),
      ],
    );
  }

  Widget _buildHistorialList(
      CashRegisterDetailState detailState, bool cajaLoading) {
    if (cajaLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorSchema.primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    if (detailState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: ColorSchema.primaryColor,
          strokeWidth: 2,
        ),
      );
    }

    if (detailState.error != null && detailState.items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 40),
            const SizedBox(height: 8),
            Text(
              'No se pudo cargar el historial',
              style: GoogleFonts.roboto(
                  fontSize: 13, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _loadDetail,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                  foregroundColor: ColorSchema.primaryColor),
            ),
          ],
        ),
      );
    }

    if (detailState.items.isEmpty) {
      return Center(
        child: Text(
          'Sin movimientos',
          style: GoogleFonts.roboto(
              fontSize: 13, color: Colors.grey.shade400),
        ),
      );
    }

    return RefreshIndicator(
      color: ColorSchema.primaryColor,
      onRefresh: () async => _loadDetail(),
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount:
            detailState.items.length + (detailState.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == detailState.items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorSchema.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }
          final item = detailState.items[index];
          return HistorialItem(
            item: item,
            tipo: detailState.tipo,
          );
        },
      ),
    );
  }
}
