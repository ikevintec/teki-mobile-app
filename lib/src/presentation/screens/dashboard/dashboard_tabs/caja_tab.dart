import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CajaTab extends ConsumerStatefulWidget {
  final ValueNotifier<int> refreshNotifier;

  const CajaTab({super.key, required this.refreshNotifier});

  @override
  ConsumerState<CajaTab> createState() => _CajaTabState();
}

class _CajaTabState extends ConsumerState<CajaTab> {
  String? _selectedMoneda;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_onRefresh);
    Future.microtask(() => _fetchCashRegister());
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    setState(() => _selectedMoneda = null);
    _fetchCashRegister();
  }

  void _fetchCashRegister() {
    final sesion = ref.read(sesionProvider);
    final idPV = sesion.office?.id ?? 0;
    final idEV = sesion.saleStation?.id ?? 0;
    ref.read(cashRegisterProvider.notifier).fetch(
          idPuntoVenta: idPV,
          idEstacionVenta: idEV,
        );
  }

  @override
  Widget build(BuildContext context) {
    final cajaState = ref.watch(cashRegisterProvider);
    final balance = cajaState.balancePorMoneda;
    final ingresos = cajaState.totalIngresosPorMoneda;
    final egresos = cajaState.totalEgresosPorMoneda;

    final monedas = {...balance.keys}.toList()
      ..sort((a, b) => a == 'PEN' ? -1 : 1);

    final monedaActiva =
        (_selectedMoneda != null && monedas.contains(_selectedMoneda))
            ? _selectedMoneda!
            : (monedas.contains('PEN')
                ? 'PEN'
                : (monedas.isNotEmpty ? monedas.first : 'PEN'));

    String fmt(Map<String, double> map, String moneda) {
      final symbol = formatExchange(moneda: moneda);
      final v = map[moneda] ?? 0.0;
      return '$symbol${v.toStringAsFixed(2)}';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Text(
                  'Caja del Día',
                  style: GoogleFonts.raleway(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F1F1F),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMM yyyy', 'es').format(DateTime.now()),
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade400,
                  ),
                ),
                const Spacer(),
                // Botón actualizar
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedMoneda = null);
                    _fetchCashRegister();
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: ColorSchema.primaryColor.withValues(alpha: 0.08),
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
          ),

          // Tarjeta principal
          Container(
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
                    padding: EdgeInsets.symmetric(vertical: 56),
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
                              style: GoogleFonts.nunito(
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
                    : Column(
                        children: [
                          // Balance
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 20, 16, 16),
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
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: ColorSchema.primaryColor,
                                        size: 21,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Balance',
                                        style: GoogleFonts.nunito(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    if (monedas.length > 1)
                                      _CurrencySelector(
                                        monedas: monedas,
                                        value: monedaActiva,
                                        onChanged: (v) =>
                                            setState(() => _selectedMoneda = v),
                                      ),
                                  ],
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 0, bottom: 0),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      monedas.isEmpty
                                          ? '${formatExchange(moneda: 'PEN')}0.00'
                                          : fmt(balance, monedaActiva),
                                      style: GoogleFonts.nunito(
                                        fontSize: 34,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                              indent: 20,
                              endIndent: 20),

                          // Ingresos / Egresos
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                            child: monedas.isEmpty
                                ? Center(
                                    child: Text(
                                      'Sin movimientos hoy',
                                      style: GoogleFonts.nunito(
                                        fontSize: 12,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                                  )
                                : Row(
                                    children: [
                                      _MovimientoItem(
                                        label: 'Ingresos',
                                        value: fmt(ingresos, monedaActiva),
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
                                      _MovimientoItem(
                                        label: 'Egresos',
                                        value: fmt(egresos, monedaActiva),
                                        dotColor: const Color(0xFFEF4444),
                                        textColor: const Color(0xFFDC2626),
                                      ),
                                    ],
                                  ),
                          ),

                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _MovimientoItem extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final Color textColor;

  const _MovimientoItem({
    required this.label,
    required this.value,
    required this.dotColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: dotColor,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Selector de moneda mediante OverlayEntry — no usa Navigator, evita
/// disparar didPopNext en pantallas padres suscritas a RouteObserver.
class _CurrencySelector extends StatefulWidget {
  final List<String> monedas;
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({
    required this.monedas,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  final _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  void _select(String moneda) {
    _close();
    widget.onChanged(moneda);
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.monedas.map((m) {
                    final isSelected = m == widget.value;
                    return InkWell(
                      onTap: () => _select(m),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_rounded,
                                    size: 13,
                                    color: ColorSchema.primaryColor),
                              ),
                            Text(
                              m,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? ColorSchema.primaryColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _open
                ? ColorSchema.primaryColor.withValues(alpha: 0.12)
                : ColorSchema.primaryColor.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorSchema.primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.value,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorSchema.primaryColor,
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: ColorSchema.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
