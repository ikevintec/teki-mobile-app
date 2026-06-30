import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/list_accounts_receivable.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/date_filters_modal.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/other_filters_modal.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/providers/accounts_receivable/seller_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

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

  @override
  Widget build(BuildContext context) {
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openDateFiltersModal,
                    icon: const Icon(Icons.calendar_month,
                        color: ColorSchema.primaryColor),
                    label: const Text(
                      'Fechas',
                      style: TextStyle(color: ColorSchema.primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: ColorSchema.primaryColor),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _openOtherFiltersModal,
                    icon: const Icon(Icons.filter_list_outlined,
                        color: ColorSchema.primaryColor),
                    label: const Text(
                      'Otros filtros',
                      style: TextStyle(color: ColorSchema.primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      side: const BorderSide(color: ColorSchema.primaryColor),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildTotalesSection(),
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

  Widget _buildTotalesSection() {
    final totales = ref
        .watch(accountsReceivableProvider(widget.tipoCuenta))
        .totales
        .where((t) => t.saldo > 1)
        .toList();

    if (totales.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: totales.map((t) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: RichText(
            text: TextSpan(
              style: GoogleFonts.roboto(fontSize: 14, color: Colors.black),
              children: [
                const TextSpan(
                  text: 'Total:  ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text:
                      '${formatExchange(moneda: t.codigoMoneda)}${t.saldo.toStringAsFixed(2)}',
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
