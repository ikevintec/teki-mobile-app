import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/account_receivable.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/repositories/accounts_receivable_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/shared/payment/payment_method_picker.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

Future<bool> showRegisterPaymentSheet(
  BuildContext context,
  AccountsReceivable account,
  String tipoCuenta,
) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.white,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: _RegisterPaymentSheet(account: account, tipoCuenta: tipoCuenta),
    ),
  ).then((v) => v ?? false);
}

// ─── Sheet widget ─────────────────────────────────────────────────────────────

class _RegisterPaymentSheet extends ConsumerStatefulWidget {
  final AccountsReceivable account;
  final String tipoCuenta;

  const _RegisterPaymentSheet({
    required this.account,
    required this.tipoCuenta,
  });

  @override
  ConsumerState<_RegisterPaymentSheet> createState() =>
      _RegisterPaymentSheetState();
}

class _RegisterPaymentSheetState extends ConsumerState<_RegisterPaymentSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _detalleController = TextEditingController();
  final List<PaymentEntry> _entries = [];
  bool _isLoading = false;
  bool _submitted = false;
  bool _validateMonto = false;

  @override
  void dispose() {
    _montoController.dispose();
    _descripcionController.dispose();
    _detalleController.dispose();
    for (final e in _entries) {
      e.dispose();
    }
    super.dispose();
  }

  double get _monto => double.tryParse(_montoController.text) ?? 0.0;
  double get _montoRestante => widget.account.montoRestante ?? 0.0;
  double get _totalAsignado =>
      _entries.fold(0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));
  double get _porAsignar => (_monto - _totalAsignado).clamp(0.0, double.infinity);

  bool get _hasCash => _entries.any((e) => (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO');
  bool get _hasNonCash => _entries.any((e) => (e.method.formaPago ?? '').toUpperCase() != 'EFECTIVO');
  double get _cashTotal => _entries
      .where((e) => (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO')
      .fold(0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));
  double get _nonCashTotal => _entries
      .where((e) => (e.method.formaPago ?? '').toUpperCase() != 'EFECTIVO')
      .fold(0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));
  double get _cambio {
    if (!_hasCash) return 0.0;
    final cashNeeded = (_monto - _nonCashTotal).clamp(0.0, double.infinity);
    return (_cashTotal - cashNeeded).clamp(0.0, double.infinity);
  }

  String? get _paymentError {
    if (_entries.isEmpty) return _submitted ? 'Selecciona al menos un método de pago' : null;
    if (_totalAsignado < _monto - 0.005) return 'El monto asignado es menor al total';
    if (_hasNonCash && _totalAsignado > _monto + 0.005) return 'Al usar métodos sin efectivo, el monto debe ser exacto';
    return null;
  }

  bool get _amountsMatch => _entries.isNotEmpty && _monto > 0 && _paymentError == null;

  List<PaymentMethod> get _paymentMethods {
    final all = ref.read(sesionProvider).config?.formasPago ?? [];
    final Map<int, PaymentMethod> uniqueMap = {};
    bool efectivoAdded = false;
    for (final p in all) {
      if (p.id == null) continue;
      final forma = (p.formaPago ?? '').toUpperCase();
      final movimiento = (p.tipoMovimiento ?? '').toLowerCase();
      if (forma == 'EFECTIVO') {
        if (!efectivoAdded) {
          uniqueMap[p.id!] = p;
          efectivoAdded = true;
        }
      } else if (movimiento == 'ingreso') {
        uniqueMap.putIfAbsent(p.id!, () => p);
      }
    }
    return uniqueMap.values.toList();
  }

  void _addPayment(PaymentMethod method) {
    final n = double.tryParse(_montoController.text);
    final valid = n != null && n > 0 && n <= _montoRestante + 0.005;
    if (!valid) {
      setState(() => _validateMonto = true);
      return;
    }
    if (_entries.any((e) => e.method.id == method.id)) return;
    setState(() {
      _entries.add(PaymentEntry(method: method, initialAmount: _porAsignar));
    });
  }

  void _removePayment(int index) {
    _entries[index].dispose();
    setState(() => _entries.removeAt(index));
  }

  Future<void> _submit() async {
    setState(() { _submitted = true; _validateMonto = true; });
    if (!_formKey.currentState!.validate()) return;
    if (_entries.isEmpty || !_amountsMatch) return;

    setState(() => _isLoading = true);

    try {
      final session = ref.read(sesionProvider);
      final idPuntoVenta = session.office?.id;
      final idEstacionVenta = session.saleStation?.id;

      if (idPuntoVenta == null || idEstacionVenta == null) {
        errorNotification('No se encontró la estación de venta en la sesión');
        setState(() => _isLoading = false);
        return;
      }

      final moneda = widget.account.codigoMoneda ?? 'PEN';
      final cambio = _cambio;
      final pagos = _entries.map((e) {
        final amount = double.tryParse(e.amountController.text) ?? 0.0;
        final isCash = (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO';
        final effectiveAmount = isCash ? (amount - cambio).clamp(0.0, amount) : amount;
        return {
          'formaPago': e.method.formaPago,
          'tipoTarjeta': null,
          'nombre': e.method.nombre,
          'numeroOperacion': null,
          'monto': effectiveAmount,
          'montoPagado': amount,
          'cambio': isCash ? cambio : 0,
          'metodoPago': e.method.toJson(),
        };
      }).toList();

      await AccountsReceivableRepositoryImpl().registerPayment(
        account: widget.account,
        descripcion: _descripcionController.text.trim(),
        detalle: _detalleController.text.trim().isEmpty
            ? null
            : _detalleController.text.trim(),
        monto: _monto,
        moneda: moneda,
        pagos: pagos,
        idPuntoVenta: idPuntoVenta,
        idEstacionVenta: idEstacionVenta,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      errorNotification('Error al registrar pago: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moneda = widget.account.codigoMoneda ?? 'PEN';
    final simbolo = formatExchange(moneda: moneda);
    final documento = widget.tipoCuenta == 'CC'
        ? '${widget.account.serie ?? '--'}-${widget.account.numero?.toString().padLeft(3, '0') ?? '--'}'
        : widget.account.comprobante ?? '--';
    final paymentMethods = _paymentMethods;

    final paymentsError = _paymentError;

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle + título ─────────────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorSchema.primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Text(
                    'Nuevo pago',
                    style: GoogleFonts.roboto(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Contenido scrollable ────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoCard(
                    documento: documento,
                    tipoCuenta: widget.tipoCuenta,
                    montoRestante: _montoRestante,
                    simbolo: simbolo,
                    moneda: moneda,
                  ),
                  const SizedBox(height: 12),

                  // Monto + Descripción en una sola fila
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _montoController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*\.?\d{0,2}')),
                          ],
                          autovalidateMode: _validateMonto
                              ? AutovalidateMode.always
                              : AutovalidateMode.disabled,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: paymentInputDecoration(
                            label: 'Monto *',
                            hint: '0.00',
                            prefix: simbolo,
                          ),
                          onChanged: (_) => setState(() {}),
                          validator: (v) {
                            final n = double.tryParse(v ?? '');
                            if (n == null || n <= 0) return 'Ingresa un monto mayor a 0';
                            if (n > _montoRestante + 0.005) {
                              return 'Máx $simbolo${_montoRestante.toStringAsFixed(2)}';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: _descripcionController,
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: paymentInputDecoration(
                            label: 'Descripción *',
                            hint: 'Motivo del pago',
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Obligatorio';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Detalle en fila completa
                  TextFormField(
                    controller: _detalleController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: paymentInputDecoration(
                      label: 'Detalle (opcional)',
                      hint: 'Información adicional',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 14),

                  // Header métodos de pago
                  Row(
                    children: [
                      Text(
                        'Métodos de pago',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                      const Spacer(),
                      if (_monto > 0 && _entries.isNotEmpty)
                        AssignedBadge(
                          asignado: _totalAsignado,
                          total: _monto,
                          simbolo: simbolo,
                          cambio: _cambio,
                        ),
                    ],
                  ),
                  if (paymentsError != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      paymentsError,
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: Colors.red[700]),
                    ),
                  ],
                  const SizedBox(height: 8),

                  // ── Lista de métodos de pago ────────────────────────
                  ...List.generate(paymentMethods.length, (i) {
                    final method = paymentMethods[i];
                    final entryIndex =
                        _entries.indexWhere((e) => e.method.id == method.id);
                    final entry =
                        entryIndex >= 0 ? _entries[entryIndex] : null;
                    return PaymentMethodRow(
                      method: method,
                      entry: entry,
                      onTap: () => entry == null
                          ? _addPayment(method)
                          : _removePayment(entryIndex),
                      onRemove: entry != null
                          ? () => _removePayment(entryIndex)
                          : null,
                      onAmountChanged: () => setState(() {}),
                    );
                  }),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          // ── Botón fijo al fondo ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorSchema.primaryColor,
                  disabledBackgroundColor:
                      ColorSchema.primaryColor.withValues(alpha: 0.4),
                  foregroundColor: Colors.white,
                  disabledForegroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Registrar pago',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

}

// ─── Info card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final String documento;
  final String tipoCuenta;
  final double montoRestante;
  final String simbolo;
  final String moneda;

  const _InfoCard({
    required this.documento,
    required this.tipoCuenta,
    required this.montoRestante,
    required this.simbolo,
    required this.moneda,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: ColorSchema.primaryColor.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  documento,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    tipoCuenta == 'CC' ? 'Cuenta por cobrar' : 'Cuenta por pagar',
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      color: ColorSchema.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tipoCuenta == 'CC' ? 'Por cobrar' : 'Por pagar',
                style: GoogleFonts.roboto(fontSize: 11, color: Colors.black45),
              ),
              Text(
                '$simbolo${montoRestante.toStringAsFixed(2)} $moneda',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ColorSchema.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
