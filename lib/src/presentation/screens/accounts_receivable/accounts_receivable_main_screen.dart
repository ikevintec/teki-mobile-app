import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/list_accounts_receivable.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/date_filters_modal.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/other_filters_modal.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/providers/accounts_receivable/seller_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class _FilterButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool hasActiveFilter;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _FilterButton({
    required this.label,
    required this.icon,
    required this.hasActiveFilter,
    required this.isLoading,
    required this.onTap,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        OutlinedButton.icon(
          onPressed: isLoading ? null : onTap,
          icon: Icon(icon, color: isLoading ? Colors.grey : ColorSchema.primaryColor),
          label: Text(
            label,
            style: TextStyle(color: isLoading ? Colors.grey : ColorSchema.primaryColor),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            side: BorderSide(color: isLoading ? Colors.grey : ColorSchema.primaryColor),
          ),
        ),
        if (hasActiveFilter && !isLoading)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onClear,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: ColorSchema.primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cleaning_services, size: 13, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}

class AccountsReceivableMainScreen extends ConsumerStatefulWidget {
  /// 'CC' = Cuentas por Cobrar, 'CP' = Cuentas por Pagar
  final String tipoCuenta;

  const AccountsReceivableMainScreen({super.key, required this.tipoCuenta});

  @override
  ConsumerState<AccountsReceivableMainScreen> createState() =>
      _AccountsReceivableMainScreenState();
}

class _AccountsReceivableMainScreenState
    extends ConsumerState<AccountsReceivableMainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sellersProvider.notifier).loadOnce();
      ref
          .read(accountsReceivableProvider(widget.tipoCuenta).notifier)
          .loadFirstPage();
    });
  }

  String get _titulo =>
      widget.tipoCuenta == 'CC' ? 'Cuentas por Cobrar' : 'Cuentas por Pagar';

  void _openDateFiltersModal() {
    showCustomModal(
      context: context,
      child: DateFiltersModal(tipoCuenta: widget.tipoCuenta),
      tittle: 'Filtrar por fechas',
      allowButtons: false,
      showButtoms: false,
    );
  }

  void _openOtherFiltersModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OtherFiltersModal(tipoCuenta: widget.tipoCuenta),
    );
  }

  bool _hasDateFilters(AccountsReceivableState state) {
    return state.filtroEmisionDesde != null ||
        state.filtroEmisionHasta != null ||
        state.filtroVencimientoDesde != null ||
        state.filtroVencimientoHasta != null;
  }

  bool _hasOtherFilters(AccountsReceivableState state) {
    return (state.tipoComprobante?.isNotEmpty ?? false) ||
        state.numero != null ||
        state.serie != null ||
        state.cliente != null ||
        state.comprobante != null ||
        state.diasCredito != null ||
        (state.estadoCredito?.isNotEmpty ?? false) ||
        state.idVendedor != null ||
        state.idPuntoVenta != null;
  }

  void _clearDateFilters() {
    ref
        .read(accountsReceivableProvider(widget.tipoCuenta).notifier)
        .applyDateFilters(
          filtroEmisionDesde: null,
          filtroEmisionHasta: null,
          filtroVencimientoDesde: null,
          filtroVencimientoHasta: null,
        );
  }

  void _clearOtherFilters() {
    ref
        .read(accountsReceivableProvider(widget.tipoCuenta).notifier)
        .applyOtherFilters(
          tipoComprobante: null,
          numero: null,
          serie: null,
          cliente: null,
          comprobante: null,
          diasCredito: null,
          estadoCredito: null,
          idVendedor: null,
          idPuntoVenta: null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountsReceivableProvider(widget.tipoCuenta));
    final isLoading = state.isLoading;
    final hasDateFilters = _hasDateFilters(state);
    final hasOtherFilters = _hasOtherFilters(state);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_titulo, style: const TextStyle(color: Colors.white)),
        backgroundColor: ColorSchema.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 20),
            child: Row(
              children: [
                Expanded(
                  child: _FilterButton(
                    label: 'Fechas',
                    icon: Icons.calendar_month,
                    hasActiveFilter: hasDateFilters,
                    isLoading: isLoading,
                    onTap: _openDateFiltersModal,
                    onClear: _clearDateFilters,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FilterButton(
                    label: 'Otros filtros',
                    icon: Icons.filter_list_outlined,
                    hasActiveFilter: hasOtherFilters,
                    isLoading: isLoading,
                    onTap: _openOtherFiltersModal,
                    onClear: _clearOtherFilters,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildTotalesSection(state),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: AccountsReceivableListSection(tipoCuenta: widget.tipoCuenta),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalesSection(AccountsReceivableState state) {
    // Paridad web: desglose por moneda (crédito, pagado y saldo), con el
    // mismo estilo de card que los totales de Ver Comprobantes.
    final totales = state.totales
        .where((t) => t.totalCredito.abs() > 0.009 || t.totalPagado.abs() > 0.009)
        .toList();

    if (totales.isEmpty) return const SizedBox.shrink();

    final etiquetaSaldo =
        widget.tipoCuenta == 'CC' ? 'Por cobrar' : 'Por pagar';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < totales.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Text(
              '$etiquetaSaldo ${formatExchange(moneda: totales[i].codigoMoneda)}'
              '${totales[i].saldo.toStringAsFixed(2)}',
              style: GoogleFonts.roboto(
                fontSize: i == 0 ? 17 : 13,
                fontWeight: FontWeight.w700,
                color: i == 0 ? Colors.black87 : Colors.grey.shade700,
              ),
            ),
            Text(
              'Crédito ${formatExchange(moneda: totales[i].codigoMoneda)}'
              '${totales[i].totalCredito.toStringAsFixed(2)}'
              '  ·  Pagado ${formatExchange(moneda: totales[i].codigoMoneda)}'
              '${totales[i].totalPagado.toStringAsFixed(2)}',
              style: GoogleFonts.roboto(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
