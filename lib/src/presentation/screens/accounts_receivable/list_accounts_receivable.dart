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
          return _AccountRow(
            item: item,
            tipoCuenta: widget.tipoCuenta,
            moneda: formatExchange(moneda: item.codigoMoneda ?? 'PEN'),
            titulo: _tituloItem(item),
            persona: _personaItem(item),
            onTap: () => showAccountActionsSheet(
              context,
              ref,
              item,
              widget.tipoCuenta,
            ),
          );
        },
      ),
    );
  }
}

/// Fila de una cuenta por cobrar/pagar. Rediseño UX:
/// - Estado como chip de color (se lee más rápido que texto suelto).
/// - A la derecha el SALDO pendiente destacado + el total en gris (antes se
///   mostraba solo el total, confuso cuando ya estaba pagado).
/// - El vencimiento en rojo/ámbar SOLO si la cuenta sigue debiendo; una cuenta
///   PAGADA/ANULADA muestra su fecha en gris neutro (antes salía "venció hace
///   N días" en rojo aunque estuviera pagada: contradecía el chip verde).
class _AccountRow extends StatelessWidget {
  final AccountsReceivable item;
  final String tipoCuenta;
  final String moneda;
  final String titulo;
  final String persona;
  final VoidCallback onTap;

  const _AccountRow({
    required this.item,
    required this.tipoCuenta,
    required this.moneda,
    required this.titulo,
    required this.persona,
    required this.onTap,
  });

  bool get _saldado =>
      item.estadoCredito == 'PAGADO' ||
      item.estadoCredito == 'ANULADO' ||
      item.estadoCredito == 'REFINANCIADO';

  double get _total =>
      (tipoCuenta == 'CC'
          ? (item.totalVentaCredito ?? item.totalVenta)
          : item.totalCompra) ??
      0;

  double get _saldo =>
      item.montoRestante ?? (_total - (item.montoPagado ?? 0));

  _EstadoStyle get _estadoStyle {
    switch (item.estadoCredito) {
      case 'PAGADO':
        return const _EstadoStyle('PAGADO', Color(0xFF15803D), Color(0xFFDCFCE7));
      case 'PENDIENTE':
        return const _EstadoStyle('PENDIENTE', Color(0xFFB45309), Color(0xFFFEF3C7));
      case 'VENCIDO':
        return const _EstadoStyle('VENCIDO', Color(0xFFB91C1C), Color(0xFFFEE2E2));
      case 'ANULADO':
        return const _EstadoStyle('ANULADO', Color(0xFF6B7280), Color(0xFFF3F4F6));
      case 'REFINANCIADO':
        return const _EstadoStyle('REFINANCIADO', Color(0xFF1D4ED8), Color(0xFFDBEAFE));
      default:
        return const _EstadoStyle('--', Color(0xFF6B7280), Color(0xFFF3F4F6));
    }
  }

  String _venceLabel() {
    final vence = item.fechaVencimiento;
    if (vence == null) return '';
    final hoy = DateTime.now();
    final dias = DateTime(vence.year, vence.month, vence.day)
        .difference(DateTime(hoy.year, hoy.month, hoy.day))
        .inDays;
    final fecha = DateFormat('dd/MM/yy').format(vence);
    if (_saldado) return fecha; // saldada: solo la fecha, sin alarma
    if (dias < 0) return 'Venció hace ${-dias} día(s) · $fecha';
    if (dias == 0) return 'Vence hoy · $fecha';
    if (dias == 1) return 'Vence mañana · $fecha';
    return 'Vence en $dias días · $fecha';
  }

  Color _venceColor() {
    final vence = item.fechaVencimiento;
    if (_saldado || vence == null) return Colors.grey.shade500;
    final dias = DateTime(vence.year, vence.month, vence.day)
        .difference(DateTime.now())
        .inDays;
    if (dias < 0) return const Color(0xFFC62828);
    if (dias <= 3) return const Color(0xFFE65100);
    return Colors.grey.shade600;
  }

  @override
  Widget build(BuildContext context) {
    final estilo = _estadoStyle;
    final hayVence = item.fechaVencimiento != null;
    final saldoCero = _saldo.abs() < 0.01;

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFECEEF1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          titulo,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Chip(estilo: estilo),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    persona,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.roboto(
                      fontSize: 12.5,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (hayVence) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.event_outlined,
                            size: 13, color: _venceColor()),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            _venceLabel(),
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              color: _venceColor(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  saldoCero ? 'Saldado' : 'Saldo',
                  style: GoogleFonts.roboto(
                    fontSize: 10.5,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '$moneda${_saldo.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: saldoCero
                        ? Colors.grey.shade500
                        : ColorSchema.primaryColor,
                  ),
                ),
                if (!saldoCero)
                  Text(
                    'de $moneda${_total.toStringAsFixed(2)}',
                    style: GoogleFonts.roboto(
                      fontSize: 10.5,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadoStyle {
  final String label;
  final Color fg;
  final Color bg;
  const _EstadoStyle(this.label, this.fg, this.bg);
}

class _Chip extends StatelessWidget {
  final _EstadoStyle estilo;
  const _Chip({required this.estilo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: estilo.bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        estilo.label,
        style: GoogleFonts.roboto(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: estilo.fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
