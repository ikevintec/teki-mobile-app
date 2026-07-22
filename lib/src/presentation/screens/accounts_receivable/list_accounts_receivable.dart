import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/account_actions_sheet.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class AccountsReceivableListSection extends ConsumerStatefulWidget {
  final String tipoCuenta;

  const AccountsReceivableListSection({super.key, required this.tipoCuenta});

  @override
  ConsumerState<AccountsReceivableListSection> createState() =>
      _AccountsReceivableListSectionState();
}

class _AccountsReceivableListSectionState
    extends ConsumerState<AccountsReceivableListSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final provider = accountsReceivableProvider(widget.tipoCuenta);
      final state = ref.read(provider);
      final reachedEnd = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300;

      if (reachedEnd && state.hasMore && !state.isLoading) {
        ref.read(provider.notifier).fetchMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    await ref
        .read(accountsReceivableProvider(widget.tipoCuenta).notifier)
        .loadFirstPage();
  }

  Color _estadoColor(String? estado) {
    switch (estado) {
      case 'VENCIDO':
        return Colors.red;
      case 'PAGADO':
        return Colors.green;
      case 'PENDIENTE':
        return Colors.orange;
      case 'ANULADO':
        return Colors.grey;
      case 'REFINANCIADO':
        return Colors.blue;
      default:
        return Colors.black54;
    }
  }

  String _tituloItem(AccountsReceivable item) {
    if (widget.tipoCuenta == 'CC') {
      return '${item.serie ?? '--'} - ${item.numero ?? '--'}';
    }
    return item.comprobante ?? '--';
  }

  String _personaItem(AccountsReceivable item) {
    if (widget.tipoCuenta == 'CC') {
      return item.cliente?.razonSocial ?? '--';
    }
    return item.nombreProveedor ?? '--';
  }

  @override
  Widget build(BuildContext context) {
    final provider = accountsReceivableProvider(widget.tipoCuenta);
    final state = ref.watch(provider);
    final accounts = state.accounts;
    final hasMore = state.hasMore;
    final isLoading = state.isLoading;

    final isInitialLoad = isLoading && accounts.isEmpty;

    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (accounts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: Text('No hay registros por mostrar.')),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: accounts.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == accounts.length && hasMore) {
            if (!state.isLoading) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                ref.read(provider.notifier).fetchMore();
              });
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final item = accounts[index];

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            color: Colors.white,
            child: Column(
              children: [
                ListTile(
                  onTap: () => showAccountActionsSheet(
                    context,
                    ref,
                    item,
                    widget.tipoCuenta,
                  ),
                  leading: Icon(
                    widget.tipoCuenta == 'CC'
                        ? Icons.call_received_rounded
                        : Icons.call_made_rounded,
                    size: 32,
                    color: ColorSchema.primaryColor,
                  ),
                  title: Text(
                    _tituloItem(item),
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        _personaItem(item),
                        style: GoogleFonts.roboto(fontSize: 12),
                      ),
                      Text(
                        'Vence: ${item.fechaVencimiento != null ? DateFormat('dd-MM-yyyy').format(item.fechaVencimiento!) : '--'}',
                        style: GoogleFonts.roboto(fontSize: 11),
                      ),
                      Text(
                        item.estadoCredito ?? '--',
                        style: GoogleFonts.roboto(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _estadoColor(item.estadoCredito),
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${formatExchange(moneda: item.codigoMoneda ?? 'PEN')}${((widget.tipoCuenta == 'CC' ? item.totalVenta : item.totalCompra) ?? 0).toStringAsFixed(2)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: ColorSchema.primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Divider(color: Colors.grey[300]!, height: 0.2),
              ],
            ),
          );
        },
      ),
    );
  }
}
