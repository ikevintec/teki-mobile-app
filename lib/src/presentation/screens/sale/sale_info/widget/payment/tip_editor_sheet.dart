import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/seller.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_entry.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_method_row.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class TipEditorResult {
  final double amount;
  final User? responsible;
  final List<PaymentDetail> payments;

  const TipEditorResult({
    required this.amount,
    required this.responsible,
    required this.payments,
  });

  const TipEditorResult.empty()
    : amount = 0,
      responsible = null,
      payments = const [];
}

class TipEditorSheet extends StatefulWidget {
  final String currency;
  final List<Seller> sellers;
  final List<PaymentMethod> paymentMethods;
  final double initialAmount;
  final int? initialResponsibleId;
  final List<PaymentDetail> initialPayments;

  const TipEditorSheet({
    super.key,
    required this.currency,
    required this.sellers,
    required this.paymentMethods,
    required this.initialAmount,
    required this.initialResponsibleId,
    required this.initialPayments,
  });

  static Future<TipEditorResult?> show(
    BuildContext context, {
    required String currency,
    required List<Seller> sellers,
    required List<PaymentMethod> paymentMethods,
    required double initialAmount,
    required int? initialResponsibleId,
    required List<PaymentDetail> initialPayments,
  }) {
    return showModalBottomSheet<TipEditorResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TipEditorSheet(
        currency: currency,
        sellers: sellers,
        paymentMethods: paymentMethods,
        initialAmount: initialAmount,
        initialResponsibleId: initialResponsibleId,
        initialPayments: initialPayments,
      ),
    );
  }

  @override
  State<TipEditorSheet> createState() => _TipEditorSheetState();
}

class _TipEditorSheetState extends State<TipEditorSheet> {
  late final TextEditingController _amountController;
  final List<PaymentEntry> _entries = [];
  int? _responsibleId;
  String? _error;

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _paid => _entries.fold(
    0,
    (sum, entry) => sum + (double.tryParse(entry.amountController.text) ?? 0),
  );
  double get _remaining => (_amount - _paid).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialAmount > 0
          ? widget.initialAmount.toStringAsFixed(2)
          : '',
    );
    _responsibleId =
        widget.sellers.any((seller) => seller.id == widget.initialResponsibleId)
        ? widget.initialResponsibleId
        : null;
    for (final payment in widget.initialPayments) {
      final method = widget.paymentMethods.firstWhere(
        (candidate) => candidate.id == payment.metodoPago?.id,
        orElse: () => payment.metodoPago ?? PaymentMethod(),
      );
      if (method.id == null) continue;
      _entries.add(
        PaymentEntry.fromExisting(
          method: method,
          amount: (payment.montoPagado ?? payment.monto ?? 0).toStringAsFixed(
            2,
          ),
          operation: payment.numeroOperacion ?? '',
        ),
      );
    }
    if (_amount > 0 && _entries.isEmpty) _initializeCashPayment();
  }

  @override
  void dispose() {
    _amountController.dispose();
    for (final entry in _entries) {
      entry.dispose();
    }
    super.dispose();
  }

  List<PaymentMethod> get _visibleMethods {
    final unique = <int, PaymentMethod>{};
    var cashAdded = false;
    for (final method in widget.paymentMethods) {
      if (method.id == null) continue;
      final type = (method.formaPago ?? '').toUpperCase();
      final movement = (method.tipoMovimiento ?? '').toLowerCase();
      if (type == 'EFECTIVO') {
        if (!cashAdded) {
          unique[method.id!] = method;
          cashAdded = true;
        }
      } else if (movement == 'ingreso') {
        unique.putIfAbsent(method.id!, () => method);
      }
    }
    return unique.values.toList();
  }

  void _initializeCashPayment() {
    final cash = widget.paymentMethods.where(
      (method) => (method.formaPago ?? '').toUpperCase() == 'EFECTIVO',
    );
    if (cash.isEmpty || _amount <= 0) return;
    _entries.add(PaymentEntry(method: cash.first, initialAmount: _amount));
  }

  void _amountChanged() {
    for (final entry in _entries) {
      entry.dispose();
    }
    _entries.clear();
    _initializeCashPayment();
    setState(() => _error = null);
  }

  void _addPayment(PaymentMethod method) {
    if (method.id == null ||
        _entries.any((entry) => entry.method.id == method.id)) {
      return;
    }
    setState(() {
      _entries.add(PaymentEntry(method: method, initialAmount: _remaining));
      _error = null;
    });
  }

  void _removePayment(int index) {
    _entries[index].dispose();
    setState(() {
      _entries.removeAt(index);
      _error = null;
    });
  }

  List<PaymentDetail> _buildPayments() {
    return _entries
        .where(
          (entry) => (double.tryParse(entry.amountController.text) ?? 0) > 0,
        )
        .map((entry) {
          final amount = double.tryParse(entry.amountController.text) ?? 0;
          return PaymentDetail(
            formaPago: entry.method.formaPago,
            monto: double.parse(amount.toStringAsFixed(2)),
            montoPagado: double.parse(amount.toStringAsFixed(2)),
            metodoPago: entry.method,
            numeroOperacion: entry.operationController.text.isEmpty
                ? null
                : entry.operationController.text,
            nombre: entry.method.nombre,
            tipoTarjeta: entry.method.tipoTarjeta,
          );
        })
        .toList();
  }

  void _save() {
    final amount = _amount;
    if (amount < 0) {
      setState(() => _error = 'La propina debe ser mayor o igual a cero.');
      return;
    }
    if (amount == 0) {
      Navigator.pop(context, const TipEditorResult.empty());
      return;
    }
    if (_responsibleId == null) {
      setState(() => _error = 'Seleccione el mozo responsable.');
      return;
    }
    if ((_paid * 100).round() != (amount * 100).round()) {
      setState(() => _error = 'Los pagos deben sumar exactamente la propina.');
      return;
    }
    final seller = widget.sellers.firstWhere(
      (candidate) => candidate.id == _responsibleId,
    );
    Navigator.pop(
      context,
      TipEditorResult(
        amount: double.parse(amount.toStringAsFixed(2)),
        responsible: User(
          id: seller.id,
          nombreCompleto:
              seller.nombreCompleto ??
              '${seller.nombres ?? ''} ${seller.apellidos ?? ''}'.trim(),
        ),
        payments: _buildPayments(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbol = formatExchange(moneda: widget.currency);
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.volunteer_activism_rounded,
                    color: ColorSchema.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Gestionar propina',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    onChanged: (_) => _amountChanged(),
                    decoration: InputDecoration(
                      labelText: 'Cantidad propina',
                      prefixText: '$symbol ',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: _responsibleId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Responsable (*)',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    items: widget.sellers
                        .where((seller) => seller.id != null)
                        .map(
                          (seller) => DropdownMenuItem<int>(
                            value: seller.id,
                            child: Text(
                              seller.nombreCompleto ??
                                  '${seller.nombres ?? ''} ${seller.apellidos ?? ''}'
                                      .trim(),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() {
                      _responsibleId = value;
                      _error = null;
                    }),
                  ),
                  if (_amount > 0) ...[
                    const SizedBox(height: 18),
                    const Text(
                      'Método de pago de la propina',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._visibleMethods.map((method) {
                      final index = _entries.indexWhere(
                        (entry) => entry.method.id == method.id,
                      );
                      return PaymentMethodRow(
                        method: method,
                        entry: index >= 0 ? _entries[index] : null,
                        onTap: () => index >= 0
                            ? _removePayment(index)
                            : _addPayment(method),
                        onRemove: index >= 0
                            ? () => _removePayment(index)
                            : null,
                        onAmountChanged: () => setState(() => _error = null),
                      );
                    }),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Asignado'),
                        Text('$symbol ${_paid.toStringAsFixed(2)}'),
                      ],
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: TextStyle(color: Colors.red.shade700)),
                  ],
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () =>
                          Navigator.pop(context, const TipEditorResult.empty()),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: ColorSchema.primaryColor,
                        side: const BorderSide(
                          color: ColorSchema.primaryColor,
                        ),
                      ),
                      child: const Text('Quitar propina'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorSchema.primaryColor,
                      ),
                      child: const Text('Guardar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
