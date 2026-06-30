import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/caja_metodo_pago_balance.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_balance_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class CajaBalanceScreen extends ConsumerStatefulWidget {
  final int idCaja;

  const CajaBalanceScreen({super.key, required this.idCaja});

  @override
  ConsumerState<CajaBalanceScreen> createState() => _CajaBalanceScreenState();
}

class _CajaBalanceScreenState extends ConsumerState<CajaBalanceScreen> {
  String? _selectedMoneda;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() => _selectedMoneda = null);
      ref
          .read(cashRegisterBalanceProvider(widget.idCaja).notifier)
          .fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final balanceState =
        ref.watch(cashRegisterBalanceProvider(widget.idCaja));

    final monedas = balanceState.monedas;
    final monedaActiva = (_selectedMoneda != null &&
            monedas.contains(_selectedMoneda))
        ? _selectedMoneda!
        : (monedas.contains('PEN')
            ? 'PEN'
            : (monedas.isNotEmpty ? monedas.first : 'PEN'));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        surfaceTintColor: Colors.white,
        backgroundColor: ColorSchema.primaryColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 30),
        ),
        title: Text(
          'Balance por método de pago',
          style: GoogleFonts.raleway(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
      ),
      body: balanceState.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: ColorSchema.primaryColor,
                strokeWidth: 2,
              ),
            )
          : balanceState.error != null && balanceState.items.isEmpty
              ? _buildError(balanceState.error!)
              : _buildContent(balanceState, monedas, monedaActiva),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 48),
            const SizedBox(height: 12),
            Text(
              'No se pudo cargar el balance',
              style: GoogleFonts.roboto(
                  fontSize: 14, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => ref
                  .read(cashRegisterBalanceProvider(widget.idCaja).notifier)
                  .fetch(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style:
                  TextButton.styleFrom(foregroundColor: ColorSchema.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    CashRegisterBalanceState balanceState,
    List<String> monedas,
    String monedaActiva,
  ) {
    final itemsConData = balanceState.items
        .where((i) => i.hasDataForMoneda(monedaActiva))
        .toList();

    return Column(
      children: [
        // ── Selector de moneda ─────────────────────────────────────────────
        if (monedas.length > 1)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
            child: Row(
              children: [
                Text(
                  'Moneda',
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const Spacer(),
                _BalanceCurrencySelector(
                  monedas: monedas,
                  value: monedaActiva,
                  onChanged: (m) => setState(() => _selectedMoneda = m),
                ),
              ],
            ),
          ),
        if (monedas.length > 1)
          Divider(height: 1, color: Colors.grey.shade200),

        // ── Lista de métodos de pago ───────────────────────────────────────
        Expanded(
          child: balanceState.items.isEmpty
              ? Center(
                  child: Text(
                    'Sin datos de balance',
                    style: GoogleFonts.roboto(
                        fontSize: 13, color: Colors.grey.shade400),
                  ),
                )
              : itemsConData.isEmpty
                  ? Center(
                      child: Text(
                        'Sin movimientos para $monedaActiva',
                        style: GoogleFonts.roboto(
                            fontSize: 13, color: Colors.grey.shade400),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
                      children: [
                        ...itemsConData.map(
                          (item) => _MetodoPagoTile(
                            item: item,
                            moneda: monedaActiva,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _TotalCard(
                          balanceState: balanceState,
                          moneda: monedaActiva,
                        ),
                      ],
                    ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selector de moneda — chip con overlay (mismo estilo que la card de balance)
// ─────────────────────────────────────────────────────────────────────────────

class _BalanceCurrencySelector extends StatefulWidget {
  final List<String> monedas;
  final String value;
  final ValueChanged<String> onChanged;

  const _BalanceCurrencySelector({
    required this.monedas,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_BalanceCurrencySelector> createState() =>
      _BalanceCurrencySelectorState();
}

class _BalanceCurrencySelectorState extends State<_BalanceCurrencySelector> {
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
                              style: GoogleFonts.roboto(
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
                style: GoogleFonts.roboto(
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

// ─────────────────────────────────────────────────────────────────────────────
// Acordeón por método de pago
// ─────────────────────────────────────────────────────────────────────────────

class _MetodoPagoTile extends StatelessWidget {
  final CajaMetodoPagoBalance item;
  final String moneda;

  const _MetodoPagoTile({required this.item, required this.moneda});

  IconData _iconForMetodo(String metodo) {
    final lower = metodo.toLowerCase();
    if (lower.contains('efectivo')) { return Icons.payments_rounded; }
    if (lower.contains('yape') ||
        lower.contains('plin') ||
        lower.contains('lukita')) { return Icons.smartphone_rounded; }
    if (lower.contains('transfer')) { return Icons.account_balance_rounded; }
    if (lower.contains('tarjet') ||
        lower.contains('visa') ||
        lower.contains('master')) {
      return Icons.credit_card_rounded;
    }
    if (lower.contains('cheque')) { return Icons.receipt_long_rounded; }
    return Icons.attach_money_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final symbol = formatExchange(moneda: moneda);
    final ingreso = item.ingresoForMoneda(moneda);
    final egreso = item.egresoForMoneda(moneda);
    final ganancia = item.gananciaForMoneda(moneda);
    final isPositive = ganancia >= 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                _iconForMetodo(item.metodoPago),
                size: 18,
                color: ColorSchema.primaryColor,
              ),
            ),
            title: Text(
              item.metodoPago,
              style: GoogleFonts.roboto(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F1F1F),
              ),
            ),
            subtitle: Text(
              'Neto: $symbol${ganancia.toStringAsFixed(2)}',
              style: GoogleFonts.roboto(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isPositive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626),
              ),
            ),
            iconColor: Colors.grey.shade400,
            collapsedIconColor: Colors.grey.shade400,
            children: [
              Divider(height: 1, color: Colors.grey.shade100),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    // Ingresos
                    _BalanceRow(
                      label: 'Ingresos',
                      value: '$symbol${ingreso.toStringAsFixed(2)}',
                      icon: Icons.arrow_downward_rounded,
                      iconColor: const Color(0xFF16A34A),
                      valueColor: const Color(0xFF16A34A),
                    ),
                    const SizedBox(height: 10),
                    // Egresos
                    _BalanceRow(
                      label: 'Egresos',
                      value: '$symbol${egreso.toStringAsFixed(2)}',
                      icon: Icons.arrow_upward_rounded,
                      iconColor: const Color(0xFFEF4444),
                      valueColor: const Color(0xFFDC2626),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                          height: 1, color: Colors.grey.shade100),
                    ),
                    // Ganancia
                    _BalanceRow(
                      label: 'Ganancia',
                      value: '$symbol${ganancia.toStringAsFixed(2)}',
                      icon: isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      iconColor: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      valueColor: isPositive
                          ? const Color(0xFF16A34A)
                          : const Color(0xFFDC2626),
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BalanceRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color valueColor;
  final bool isBold;

  const _BalanceRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de totales
// ─────────────────────────────────────────────────────────────────────────────

class _TotalCard extends StatelessWidget {
  final CashRegisterBalanceState balanceState;
  final String moneda;

  const _TotalCard({
    required this.balanceState,
    required this.moneda,
  });

  @override
  Widget build(BuildContext context) {
    final symbol = formatExchange(moneda: moneda);
    final totalIngreso = balanceState.totalIngresoForMoneda(moneda);
    final totalEgreso = balanceState.totalEgresoForMoneda(moneda);
    final totalGanancia = balanceState.totalGananciaForMoneda(moneda);
    final isPositive = totalGanancia >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPositive
              ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
              : [const Color(0xFFB71C1C), const Color(0xFFC62828)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isPositive
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFDC2626))
                .withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total general',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$symbol${totalGanancia.toStringAsFixed(2)}',
            style: GoogleFonts.roboto(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TotalStat(
                  label: 'Ingresos',
                  value: '$symbol${totalIngreso.toStringAsFixed(2)}',
                  icon: Icons.arrow_downward_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withValues(alpha: 0.2),
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              Expanded(
                child: _TotalStat(
                  label: 'Egresos',
                  value: '$symbol${totalEgreso.toStringAsFixed(2)}',
                  icon: Icons.arrow_upward_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _TotalStat({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white.withValues(alpha: 0.7)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
