import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivableDetail.dart';
import 'package:teki_app/src/data/repositories/accounts_receivable_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/widgets/amortize_sheet.dart';
import 'package:teki_app/src/providers/accounts_receivable/accounts_receivable_notifier.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

void showAccountActionsSheet(
  BuildContext context,
  WidgetRef ref,
  AccountsReceivable account,
  String tipoCuenta,
) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AccountActionsContent(
      account: account,
      tipoCuenta: tipoCuenta,
      ref: ref,
      pageContext: context,
    ),
  );
}

class _AccountActionsContent extends StatelessWidget {
  final AccountsReceivable account;
  final String tipoCuenta;
  final WidgetRef ref;
  final BuildContext pageContext;

  const _AccountActionsContent({
    required this.account,
    required this.tipoCuenta,
    required this.ref,
    required this.pageContext,
  });

  String get _personaNombre {
    if (tipoCuenta == 'CC') {
      return account.cliente?.razonSocial ?? '--';
    }
    return account.nombreProveedor ?? '--';
  }

  String get _comprobante {
    if (tipoCuenta == 'CC') {
      return '${account.serie ?? '--'}-${account.numero?.toString().padLeft(3, '0') ?? '--'}';
    }
    return account.comprobante ?? '--';
  }

  String get _montoStr {
    final moneda = formatExchange(moneda: account.codigoMoneda ?? 'PEN');
    final codigo = account.codigoMoneda ?? 'PEN';
    final monto = (account.montoRestante ?? 0).toStringAsFixed(2);
    return '$codigo $moneda$monto';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                _comprobante,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                _personaNombre,
                style: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            _ActionTile(
              icon: Icons.payments_outlined,
              label: 'Ver pagos',
              onTap: () {
                Navigator.pop(context);
                _showPaymentsModal(pageContext);
              },
            ),
            if (account.estadoCredito != 'ANULADO' &&
                account.estadoCredito != 'PAGADO') ...[
              _ActionTile(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Amortizar',
                onTap: () {
                  Navigator.pop(context);
                  showAmortizeSheet(
                    pageContext,
                    account.id!,
                    tipoCuenta: tipoCuenta,
                    onSuccess: () => ref
                        .read(accountsReceivableProvider(tipoCuenta).notifier)
                        .loadFirstPage(),
                  );
                },
              ),
            ],
            if (account.estadoCredito != 'ANULADO') ...[
              _ActionTile(
                icon: Icons.update_outlined,
                label: 'Extender plazo',
                onTap: () {
                  Navigator.pop(context);
                  _showExtendDialog(pageContext);
                },
              ),
              _ActionTile(
                icon: Icons.cancel_outlined,
                label: 'Anular',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _showCancelConfirm(pageContext);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showPaymentsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _PaymentsSheet(accountId: account.id!),
    );
  }

  void _showCancelConfirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirmar anulación'),
        content: Text(
          '¿Estás seguro de anular la cuenta $_comprobante de $_personaNombre por $_montoStr?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(accountsReceivableProvider(tipoCuenta).notifier)
                  .cancelAccount(account.id!);
            },
            child: const Text('Sí, anular',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExtendDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Extender plazo'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Días a extender',
              border: OutlineInputBorder(),
            ),
            validator: (v) {
              final n = int.tryParse(v ?? '');
              if (n == null || n <= 0) {
                return 'Ingresa un número entero mayor a 0';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              final dias = int.parse(controller.text.trim());
              Navigator.pop(ctx);
              _showExtendConfirm(context, dias);
            },
            child: const Text('Continuar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showExtendConfirm(BuildContext context, int dias) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Confirmar extensión'),
        content: Text(
          '¿Estás seguro de extender el plazo de la cuenta de $_personaNombre en $dias ${dias == 1 ? 'día' : 'días'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('No'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(accountsReceivableProvider(tipoCuenta).notifier)
                  .extendAccount(account.id!, dias);
            },
            child: const Text('Sí, extender',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? ColorSchema.primaryColor;
    return ListTile(
      leading: Icon(icon, color: c),
      title: Text(label, style: TextStyle(color: c)),
      onTap: onTap,
    );
  }
}

class _PaymentsSheet extends StatefulWidget {
  final int accountId;

  const _PaymentsSheet({required this.accountId});

  @override
  State<_PaymentsSheet> createState() => _PaymentsSheetState();
}

class _PaymentsSheetState extends State<_PaymentsSheet> {
  late Future<List<AccountsReceivableDetail>> _future;

  @override
  void initState() {
    super.initState();
    _future = AccountsReceivableRepositoryImpl().getDetails(widget.accountId);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Pagos registrados',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: FutureBuilder<List<AccountsReceivableDetail>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Error al cargar pagos: ${snap.error}',
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }
                  final details = snap.data ?? [];
                  if (details.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('No hay pagos registrados.'),
                    );
                  }
                  return ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: details.length,
                    separatorBuilder: (_, i) => Divider(
                      height: 1,
                      color: Colors.grey[200],
                    ),
                    itemBuilder: (_, i) => _PaymentTile(detail: details[i]),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    montoStr,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: ColorSchema.primaryColor,
                    ),
                  ),
                  if (metodosLabel != null)
                    Text(
                      metodosLabel,
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: Colors.black45),
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

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DetailRow({required this.label, required this.value, this.bold = false});

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
  final dynamic pago;

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
