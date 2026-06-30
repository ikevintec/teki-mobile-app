import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/accountReceivable.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';
import 'package:teki_app/src/data/repositories/accounts_receivable_repository_impl.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';
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

// ─── Entry model ─────────────────────────────────────────────────────────────

class _PaymentEntry {
  final PaymentMethod method;
  final TextEditingController amountController;

  _PaymentEntry({required this.method, required double initialAmount})
      : amountController = TextEditingController(
            text: initialAmount > 0 ? initialAmount.toStringAsFixed(2) : '');

  void dispose() => amountController.dispose();
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
  final List<_PaymentEntry> _entries = [];
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
      _entries.add(_PaymentEntry(method: method, initialAmount: _porAsignar));
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
                          decoration: _inputDecoration(
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
                          decoration: _inputDecoration(
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
                    decoration: _inputDecoration(
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
                        _AssignedBadge(
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
                    return _PaymentMethodRow(
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

  InputDecoration _inputDecoration({String? label, required String hint, String? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.roboto(fontSize: 13, color: Colors.black54),
      hintText: hint,
      prefixText: prefix,
      hintStyle: GoogleFonts.roboto(color: Colors.black26, fontSize: 14),
      prefixStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.black87),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: ColorSchema.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.grey[50],
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

// ─── Assigned badge ───────────────────────────────────────────────────────────

class _AssignedBadge extends StatelessWidget {
  final double asignado;
  final double total;
  final String simbolo;
  final double cambio;

  const _AssignedBadge({
    required this.asignado,
    required this.total,
    required this.simbolo,
    this.cambio = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (cambio > 0.005) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 13, color: Colors.green[700]!),
          const SizedBox(width: 4),
          Text(
            'Cambio: $simbolo${cambio.toStringAsFixed(2)}',
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: Colors.green[700]!,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final exact = (asignado - total).abs() < 0.005;
    final over = asignado > total + 0.005;
    final color = exact
        ? Colors.green[700]!
        : over
            ? Colors.red[700]!
            : Colors.orange[700]!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          exact ? Icons.check_circle_outline : Icons.info_outline,
          size: 13,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$simbolo${asignado.toStringAsFixed(2)} / $simbolo${total.toStringAsFixed(2)}',
          style: GoogleFonts.roboto(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ─── Payment method row ───────────────────────────────────────────────────────

class _PaymentMethodRow extends StatelessWidget {
  final PaymentMethod method;
  final _PaymentEntry? entry;
  final VoidCallback onTap;
  final VoidCallback? onRemove;
  final VoidCallback onAmountChanged;

  const _PaymentMethodRow({
    required this.method,
    required this.entry,
    required this.onTap,
    required this.onAmountChanged,
    this.onRemove,
  });

  bool get _isSelected => entry != null;
  bool get _isCash => (method.formaPago ?? '').toUpperCase() == 'EFECTIVO';
  Color get _activeColor =>
      _isCash ? Colors.green.shade600 : ColorSchema.primaryColor;

  Widget _buildIcon() {
    const double size = 26;
    final url = method.imagenUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (_, e, s) => _fallbackIcon(size),
      );
    }
    return _fallbackIcon(size);
  }

  Widget _fallbackIcon(double size) => Icon(
        _isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
        color: _isSelected ? _activeColor : Colors.grey.shade400,
        size: size,
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _isSelected ? _activeColor.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _isSelected ? _activeColor : Colors.grey.shade200,
            width: _isSelected ? 1.5 : 1,
          ),
          boxShadow: _isSelected
              ? [
                  BoxShadow(
                    color: _activeColor.withValues(alpha: 0.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(width: 26, child: Center(child: _buildIcon())),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      method.nombre ?? '',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            _isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: _isSelected
                            ? _activeColor
                            : Colors.grey.shade800,
                      ),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 160),
                    child: _isSelected
                        ? Container(
                            key: const ValueKey('check'),
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: _activeColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded,
                                color: Colors.white, size: 11),
                          )
                        : const SizedBox(key: ValueKey('empty'), width: 18),
                  ),
                ],
              ),
            ),
            if (_isSelected) ...[
              Divider(
                height: 1,
                indent: 12,
                endIndent: 12,
                color: _activeColor.withValues(alpha: 0.2),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: entry!.amountController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _activeColor,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 8),
                          hintText: '0.00',
                          hintStyle: const TextStyle(
                              fontSize: 13, color: Colors.black26),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                                color: _activeColor.withValues(alpha: 0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: _activeColor, width: 1.5),
                          ),
                          filled: true,
                          fillColor: _activeColor.withValues(alpha: 0.03),
                        ),
                        onChanged: (_) => onAmountChanged(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.redAccent, size: 18),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

