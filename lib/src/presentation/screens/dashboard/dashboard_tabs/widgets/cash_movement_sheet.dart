import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';
import 'package:teki_app/src/data/repositories/cash_register_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/shared/payment/payment_method_picker.dart';
import 'package:teki_app/src/providers/cash_register/currencies_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Abre el sheet para registrar un ingreso o egreso externo de caja.
///
/// [tipo] debe ser 'INGRESO' o 'EGRESO'. Devuelve `true` si se registró.
Future<bool> showCashMovementSheet(
  BuildContext context, {
  required String tipo,
  required int idCaja,
  required int turno,
  String? monedaSugerida,
}) {
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
      child: _CashMovementSheet(
        tipo: tipo,
        idCaja: idCaja,
        turno: turno,
        monedaSugerida: monedaSugerida,
      ),
    ),
  ).then((v) => v ?? false);
}

class _CashMovementSheet extends ConsumerStatefulWidget {
  final String tipo;
  final int idCaja;
  final int turno;
  final String? monedaSugerida;

  const _CashMovementSheet({
    required this.tipo,
    required this.idCaja,
    required this.turno,
    this.monedaSugerida,
  });

  @override
  ConsumerState<_CashMovementSheet> createState() => _CashMovementSheetState();
}

class _CashMovementSheetState extends ConsumerState<_CashMovementSheet> {
  final _formKey = GlobalKey<FormState>();
  final _montoController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _detalleController = TextEditingController();
  final List<PaymentEntry> _entries = [];

  String? _moneda;
  bool _isLoading = false;
  bool _submitted = false;
  bool _validateMonto = false;

  bool get _esIngreso => widget.tipo == 'INGRESO';
  Color get _tipoColor =>
      _esIngreso ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
  String get _titulo => _esIngreso ? 'Nuevo ingreso' : 'Nuevo egreso';
  String get _accion => _esIngreso ? 'Registrar ingreso' : 'Registrar egreso';
  String get _concepto => _esIngreso ? 'OTROS_INGRESOS' : 'OTROS_EGRESOS';

  @override
  void initState() {
    super.initState();
    // Si aún no hay monedas, dispara la carga al abrir el modal.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(currenciesProvider.notifier).ensureLoaded();
    });
  }

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

  // ── Cálculos de pago (monto libre, sin tope) ──────────────────────────────
  double get _monto => double.tryParse(_montoController.text) ?? 0.0;
  double get _totalAsignado => _entries.fold(
      0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));
  double get _porAsignar =>
      (_monto - _totalAsignado).clamp(0.0, double.infinity);

  bool get _hasCash =>
      _entries.any((e) => (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO');
  bool get _hasNonCash =>
      _entries.any((e) => (e.method.formaPago ?? '').toUpperCase() != 'EFECTIVO');
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
    if (_entries.isEmpty) {
      return _submitted ? 'Selecciona al menos un método de pago' : null;
    }
    if (_totalAsignado < _monto - 0.005) return 'El monto asignado es menor al total';
    if (_hasNonCash && _totalAsignado > _monto + 0.005) {
      return 'Al usar métodos sin efectivo, el monto debe ser exacto';
    }
    return null;
  }

  bool get _amountsMatch =>
      _entries.isNotEmpty && _monto > 0 && _paymentError == null;

  /// Métodos de pago disponibles (desde la sesión), filtrados por el tipo de
  /// movimiento activo (INGRESO/EGRESO). El efectivo aplica a ambos.
  List<PaymentMethod> get _paymentMethods {
    final all = ref.read(sesionProvider).config?.formasPago ?? [];
    final tipoActivo = _esIngreso ? 'ingreso' : 'egreso';
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
      } else if (movimiento == tipoActivo) {
        uniqueMap.putIfAbsent(p.id!, () => p);
      }
    }
    return uniqueMap.values.toList();
  }

  void _addPayment(PaymentMethod method) {
    final n = double.tryParse(_montoController.text);
    final valid = n != null && n > 0;
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
    setState(() {
      _submitted = true;
      _validateMonto = true;
    });
    if (!_formKey.currentState!.validate()) return;
    if (_moneda == null || _entries.isEmpty || !_amountsMatch) {
      setState(() {});
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cambio = _cambio;
      final pagos = _entries.map((e) {
        final amount = double.tryParse(e.amountController.text) ?? 0.0;
        final isCash = (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO';
        final effectiveAmount =
            isCash ? (amount - cambio).clamp(0.0, amount) : amount;
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

      await CashRegisterRepositoryImpl().createCashMovement(
        idCaja: widget.idCaja,
        tipoMovimiento: widget.tipo,
        concepto: _concepto,
        moneda: _moneda!,
        monto: _monto,
        descripcion: _descripcionController.text.trim(),
        detalle: _detalleController.text.trim().isEmpty
            ? null
            : _detalleController.text.trim(),
        turno: widget.turno,
        pagos: pagos,
      );

      if (mounted) {
        successNotification(
            _esIngreso ? 'Ingreso registrado' : 'Egreso registrado');
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      errorNotification('No se pudo registrar el movimiento: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currenciesState = ref.watch(currenciesProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(titulo: _titulo, color: _tipoColor),
        const Divider(height: 1),
        Flexible(child: _buildBody(currenciesState)),
        // Botón fijo al fondo (siempre visible mientras la lista scrollea).
        if (currenciesState.hasCurrencies) _buildSubmitButton(),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: _tipoColor,
            disabledBackgroundColor: _tipoColor.withValues(alpha: 0.4),
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
                  _accion,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildBody(CurrenciesState currenciesState) {
    // ── Sin monedas: loader o error ─────────────────────────────────────────
    if (!currenciesState.hasCurrencies) {
      if (currenciesState.isLoading) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                color: ColorSchema.primaryColor,
                strokeWidth: 2,
              ),
              SizedBox(height: 14),
              Text(
                'Cargando monedas disponibles…',
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
            ],
          ),
        );
      }
      // Error: no se pudieron cargar las monedas.
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey.shade400, size: 44),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar las monedas.\nComuníquese con un administrador.',
              textAlign: TextAlign.center,
              style: GoogleFonts.roboto(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () =>
                  ref.read(currenciesProvider.notifier).reload(),
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Reintentar'),
              style: TextButton.styleFrom(
                  foregroundColor: ColorSchema.primaryColor),
            ),
          ],
        ),
      );
    }

    // ── Con monedas: formulario ─────────────────────────────────────────────
    final monedas =
        currenciesState.currencies.map((c) => c.codigoMoneda ?? '').where((c) => c.isNotEmpty).toList();
    // Autoselección inicial.
    _moneda ??= (widget.monedaSugerida != null &&
            monedas.contains(widget.monedaSugerida))
        ? widget.monedaSugerida
        : (monedas.contains('PEN') ? 'PEN' : monedas.first);

    final simbolo = formatExchange(moneda: _moneda!);
    final paymentMethods = _paymentMethods;
    final paymentsError = _paymentError;

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Moneda (chips) ──────────────────────────────────────────
            Text(
              'Moneda *',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: ColorSchema.primaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: monedas.map((m) {
                final selected = m == _moneda;
                return GestureDetector(
                  onTap: () => setState(() => _moneda = m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? _tipoColor.withValues(alpha: 0.12)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected
                            ? _tipoColor
                            : Colors.grey.shade300,
                        width: selected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      m,
                      style: GoogleFonts.roboto(
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        color: selected ? _tipoColor : Colors.grey.shade600,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // ── Monto + Descripción ─────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _montoController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
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
                      hint: 'Motivo del movimiento',
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Obligatorio';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // ── Detalle (opcional) ──────────────────────────────────────
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

            // ── Métodos de pago ─────────────────────────────────────────
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
                style: GoogleFonts.roboto(fontSize: 11, color: Colors.red[700]),
              ),
            ],
            const SizedBox(height: 8),
            ...List.generate(paymentMethods.length, (i) {
              final method = paymentMethods[i];
              final entryIndex =
                  _entries.indexWhere((e) => e.method.id == method.id);
              final entry = entryIndex >= 0 ? _entries[entryIndex] : null;
              return PaymentMethodRow(
                method: method,
                entry: entry,
                onTap: () => entry == null
                    ? _addPayment(method)
                    : _removePayment(entryIndex),
                onRemove:
                    entry != null ? () => _removePayment(entryIndex) : null,
                onAmountChanged: () => setState(() {}),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String titulo;
  final Color color;

  const _Header({required this.titulo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Text(
              titulo,
              style: GoogleFonts.roboto(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
