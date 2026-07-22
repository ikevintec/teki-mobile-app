import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/repositories/accounts_receivable_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/register_payment_sheet.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

void showAmortizeSheet(
  BuildContext context,
  int accountId, {
  String tipoCuenta = 'CC',
  VoidCallback? onSuccess,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AmortizeSheet(
      accountId: accountId,
      tipoCuenta: tipoCuenta,
      onSuccess: onSuccess,
    ),
  );
}

class _AmortizeSheet extends StatefulWidget {
  final int accountId;
  final String tipoCuenta;
  final VoidCallback? onSuccess;

  const _AmortizeSheet({
    required this.accountId,
    required this.tipoCuenta,
    this.onSuccess,
  });

  @override
  State<_AmortizeSheet> createState() => _AmortizeSheetState();
}

class _AmortizeSheetState extends State<_AmortizeSheet> {
  late Future<(AccountsReceivable, List<AccountsReceivableDetail>)> _future;

  @override
  void initState() {
    super.initState();
    final repo = AccountsReceivableRepositoryImpl();
    _future = Future.wait([
      repo.getById(widget.accountId),
      repo.getDetails(widget.accountId),
    ]).then((results) => (
          results[0] as AccountsReceivable,
          results[1] as List<AccountsReceivableDetail>,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: FutureBuilder<(AccountsReceivable, List<AccountsReceivableDetail>)>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final (account, details) = snap.data!;
                  final documento = account.tipoCuenta == 'CC'
                      ? '${account.serie ?? '--'}-${account.numero?.toString().padLeft(3, '0') ?? '--'}'
                      : account.comprobante ?? '--';

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Text(
                          documento,
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: ColoredBox(
                          color: Colors.grey[100]!,
                          child: ListView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(16),
                          children: [
                            _CompactInfoTile(account: account),
                            const SizedBox(height: 12),
                            _TotalsCard(account: account),
                            const SizedBox(height: 12),
                            _PaymentsSection(
                              details: details,
                              onRegisterPago: () async {
                                final nav = Navigator.of(context);
                                final result = await showRegisterPaymentSheet(
                                  context,
                                  account,
                                  widget.tipoCuenta,
                                );
                                if (result && mounted) {
                                  nav.pop();
                                  widget.onSuccess?.call();
                                }
                              },
                            ),
                          ],
                        ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Compact info tile ────────────────────────────────────────────────────────

class _CompactInfoTile extends StatelessWidget {
  final AccountsReceivable account;

  const _CompactInfoTile({required this.account});

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

  @override
  Widget build(BuildContext context) {
    final cliente = account.tipoCuenta == 'CC'
        ? account.cliente?.razonSocial ?? '--'
        : account.nombreProveedor ?? '--';
    final fechaVenc = account.fechaVencimiento != null
        ? DateFormat('dd/MM/yyyy').format(account.fechaVencimiento!)
        : '--';
    final estado = account.estadoCredito ?? '--';
    final estadoColor = _estadoColor(account.estadoCredito);

    return _Card(
      child: InkWell(
        onTap: () => _showDetail(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cliente,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.black38),
                        const SizedBox(width: 4),
                        Text(
                          'Vence: $fechaVenc',
                          style: GoogleFonts.roboto(
                              fontSize: 12, color: Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: estadoColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      estado,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: estadoColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        'Ver más',
                        style: GoogleFonts.roboto(
                            fontSize: 11, color: Colors.black38),
                      ),
                      const SizedBox(width: 2),
                      const Icon(Icons.chevron_right,
                          size: 16, color: Colors.black26),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _InfoDetailSheet(account: account),
    );
  }
}

class _InfoDetailSheet extends StatelessWidget {
  final AccountsReceivable account;

  const _InfoDetailSheet({required this.account});

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

  @override
  Widget build(BuildContext context) {
    final documento = account.tipoCuenta == 'CC'
        ? '${account.serie ?? '--'}-${account.numero?.toString().padLeft(3, '0') ?? '--'}'
        : account.comprobante ?? '--';
    final fechaEmision = account.fechaEmisionDate != null
        ? DateFormat('dd/MM/yyyy').format(account.fechaEmisionDate!)
        : account.fechaEmision ?? '--';
    final fechaVenc = account.fechaVencimiento != null
        ? DateFormat('dd/MM/yyyy').format(account.fechaVencimiento!)
        : '--';
    final cliente = account.tipoCuenta == 'CC'
        ? account.cliente?.razonSocial ?? '--'
        : account.nombreProveedor ?? '--';
    final vendedor = account.vendedor?.nombreCompleto ?? '--';
    final estado = account.estadoCredito ?? '--';
    final estadoColor = _estadoColor(account.estadoCredito);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Información',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _DetailRow(label: 'Documento', value: documento),
            _DetailRow(label: 'Fecha emisión', value: fechaEmision),
            _DetailRow(label: 'Fecha vencimiento', value: fechaVenc),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 130,
                  child: Text('Estado',
                      style: GoogleFonts.roboto(
                          fontSize: 13, color: Colors.black54)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: estadoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estado,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: estadoColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _DetailRow(label: 'Vendedor', value: vendedor),
            _DetailRow(
                label: account.tipoCuenta == 'CC'
                    ? 'Cliente'
                    : 'Proveedor',
                value: cliente),
          ],
        ),
      ),
    );
  }
}

// ─── Totals card ─────────────────────────────────────────────────────────────

class _TotalsCard extends StatelessWidget {
  final AccountsReceivable account;

  const _TotalsCard({required this.account});

  @override
  Widget build(BuildContext context) {
    final moneda = account.codigoMoneda ?? 'PEN';
    final simbolo = formatExchange(moneda: moneda);
    final montoTotal = account.tipoCuenta == 'CP'
        ? account.totalCompra
        : account.totalVenta;
    final montoPagado = account.montoPagado;
    final totalNotaCredito = account.totalNotaCredito;
    final montoRestante = account.montoRestante;

    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(label: 'Totales ($moneda)'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TotalCell(
                    label: 'Total',
                    value: montoTotal != null
                        ? '$simbolo${montoTotal.toStringAsFixed(2)}'
                        : '--',
                  ),
                ),
                Expanded(
                  child: _TotalCell(
                    label: 'Pagado',
                    value: montoPagado != null
                        ? '$simbolo${montoPagado.toStringAsFixed(2)}'
                        : '--',
                    valueColor: Colors.green[700],
                  ),
                ),
                if (totalNotaCredito != null && totalNotaCredito > 0)
                  Expanded(
                    child: _TotalCell(
                      label: 'Nota crédito',
                      value: '$simbolo${totalNotaCredito.toStringAsFixed(2)}',
                      valueColor: Colors.orange[700],
                    ),
                  ),
                Expanded(
                  child: _TotalCell(
                    label: 'Restante',
                    value: montoRestante != null
                        ? '$simbolo${montoRestante.toStringAsFixed(2)}'
                        : '--',
                    valueColor: ColorSchema.primaryColor,
                    bold: true,
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

class _TotalCell extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  const _TotalCell({
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.roboto(fontSize: 11, color: Colors.black45)),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

// ─── Payments section ─────────────────────────────────────────────────────────

class _PaymentsSection extends StatelessWidget {
  final List<AccountsReceivableDetail> details;
  final VoidCallback? onRegisterPago;

  const _PaymentsSection({required this.details, this.onRegisterPago});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionTitle(
                    label: details.isEmpty
                        ? 'Pagos realizados'
                        : 'Pagos realizados (${details.length})',
                  ),
                ),
                ElevatedButton(
                  onPressed: onRegisterPago,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    disabledBackgroundColor:
                        ColorSchema.primaryColor.withValues(alpha: 0.35),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Registrar pago',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (details.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  'Aún no hay pagos registrados.',
                  style:
                      GoogleFonts.roboto(fontSize: 13, color: Colors.black45),
                ),
              )
            else ...[
              const Divider(height: 1),
              ...details.map((d) => _PaymentTile(detail: d)),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  final AccountsReceivableDetail detail;

  const _PaymentTile({required this.detail});

  @override
  Widget build(BuildContext context) {
    final crd = detail.cashRegisterDetail;
    final moneda = crd?.monedaMovimientoCaja ?? 'PEN';
    final simbolo = formatExchange(moneda: moneda);
    final montoStr = crd?.monto != null
        ? '$simbolo${crd!.monto!.toStringAsFixed(2)}'
        : '--';
    final fecha = crd?.fechaMovimiento != null
        ? DateFormat('dd/MM/yyyy').format(crd!.fechaMovimiento!)
        : '--';
    final pagos = crd?.pagos ?? [];
    final metodosLabel = pagos.isEmpty
        ? null
        : pagos.length == 1
            ? (pagos.first.nombre ?? pagos.first.formaPago ?? '--')
            : '${pagos.length} métodos de pago';

    return InkWell(
      onTap: () => _showDetail(context),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    montoStr,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: ColorSchema.primaryColor,
                    ),
                  ),
                  if (metodosLabel != null)
                    Text(
                      metodosLabel,
                      style:
                          GoogleFonts.roboto(fontSize: 11, color: Colors.black45),
                    ),
                ],
              ),
            ),
            Text(
              fecha,
              style: GoogleFonts.roboto(fontSize: 11, color: Colors.black45),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 16, color: Colors.black26),
          ],
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PaymentDetailSheet(detail: detail),
    );
  }
}

class _PaymentDetailSheet extends StatelessWidget {
  final AccountsReceivableDetail detail;

  const _PaymentDetailSheet({required this.detail});

  @override
  Widget build(BuildContext context) {
    final crd = detail.cashRegisterDetail;
    final moneda = crd?.monedaMovimientoCaja ?? 'PEN';
    final simbolo = formatExchange(moneda: moneda);
    final montoStr = crd?.monto != null
        ? '$simbolo${crd!.monto!.toStringAsFixed(2)} $moneda'
        : '--';
    final fecha = crd?.fechaMovimiento != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(crd!.fechaMovimiento!)
        : '--';
    final descripcion =
        crd?.descripcion?.trim().isNotEmpty == true ? crd!.descripcion! : null;
    final pagos = crd?.pagos ?? [];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Detalle del pago',
              style: GoogleFonts.poppins(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 14),
            _DetailRow(label: 'Monto', value: montoStr, bold: true),
            _DetailRow(label: 'Fecha', value: fecha),
            if (descripcion != null)
              _DetailRow(label: 'Descripción', value: descripcion),
            if (pagos.isNotEmpty) ...[
              const SizedBox(height: 14),
              Text(
                'Métodos de pago',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ColorSchema.primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              ...pagos.map((p) => _MethodRow(pago: p)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Shared widgets ───────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: ColorSchema.primaryColor,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodRow extends StatelessWidget {
  final PaymentDetail pago;

  const _MethodRow({required this.pago});

  @override
  Widget build(BuildContext context) {
    final nombre = pago.nombre ?? pago.formaPago ?? '--';
    final montoStr =
        pago.monto != null ? pago.monto!.toStringAsFixed(2) : '--';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.payment_outlined, size: 16, color: Colors.black38),
          const SizedBox(width: 8),
          Expanded(
            child: Text(nombre,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.black87)),
          ),
          Text(
            montoStr,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: ColorSchema.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}
