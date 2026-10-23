import 'container_form_style.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/presentation/screens/container_loans/widgets/customer_filter_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

/// Carga los envases que un cliente ya tenía antes de usar el módulo.
/// No genera venta ni cambia la utilidad de ventas anteriores (paridad web).
class ContainerOpeningSheet extends ConsumerStatefulWidget {
  final Customer? customer;

  const ContainerOpeningSheet({super.key, this.customer});

  static Future<void> show(BuildContext context, {Customer? customer}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ContainerOpeningSheet(customer: customer),
    );
  }

  @override
  ConsumerState<ContainerOpeningSheet> createState() =>
      _ContainerOpeningSheetState();
}

class _ContainerOpeningSheetState extends ConsumerState<ContainerOpeningSheet> {
  // Un id por apertura: reintentar con los mismos datos no duplica el saldo.
  final String _requestId = ContainerLoansNotifier.newRequestId();
  final TextEditingController _quantity = TextEditingController(text: '1');
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _note = TextEditingController();
  Customer? _customer;
  ContainerOpeningProduct? _product;
  DateTime _loanedOn = DateUtils.dateOnly(DateTime.now());
  int? _officeId;
  bool? _stockAlreadyDeducted;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _customer = widget.customer;
    _officeId = ref.read(sesionProvider).office?.id;
  }

  @override
  void dispose() {
    _quantity.dispose();
    _cost.dispose();
    _note.dispose();
    super.dispose();
  }

  int get _qty => int.tryParse(_quantity.text) ?? 0;
  double get _unitCost => double.tryParse(_cost.text.replaceAll(',', '.')) ?? 0;

  bool get _valid =>
      _customer?.id != null &&
      _product != null &&
      _officeId != null &&
      _qty > 0 &&
      _qty <= 9999999999 &&
      _unitCost > 0 &&
      _stockAlreadyDeducted != null &&
      !_loanedOn.isAfter(DateTime.now());

  Future<void> _pickCustomer() async {
    final selected = await CustomerFilterSheet.show(context);
    if (selected != null) setState(() => _customer = selected);
  }

  Future<void> _pickProduct() async {
    final selected = await _OpeningProductSheet.show(context);
    if (selected == null) return;
    setState(() {
      _product = selected;
      _cost.text = selected.unitCost == null ? '' : '${selected.unitCost}';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loanedOn,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _loanedOn = DateUtils.dateOnly(picked));
  }

  Future<void> _submit() async {
    if (!_valid || _saving) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(containerLoansProvider.notifier)
          .registerOpening(
            ContainerOpening(
              customerId: _customer!.id!,
              officeId: _officeId!,
              productId: _product!.id,
              quantity: _qty,
              unitCost: _unitCost,
              loanedOn: _loanedOn,
              stockAlreadyDeducted: _stockAlreadyDeducted!,
              requestId: _requestId,
              note: _note.text,
            ),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      successNotification('Listo. Se registraron $_qty envases por devolver.');
    } catch (error) {
      if (mounted) setState(() => _saving = false);
      errorNotification(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Widget _picker({
    required String label,
    required String? value,
    required String placeholder,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: _saving ? null : onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.chevron_right),
        ),
        child: Text(
          value ?? placeholder,
          style: TextStyle(color: value == null ? Colors.grey.shade500 : null),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final offices = ref.watch(sesionProvider).offices ?? const [];
    final currency = _product?.currency ?? 'PEN';
    final pendingValue = _qty * _unitCost;
    final hint = TextStyle(fontSize: 13, color: Colors.grey.shade700);

    return ContainerFormStyle(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ContainerSheetHeader(
                    title: 'Registrar envases pendientes',
                    saving: _saving,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Anota los envases que ya entregaste y el cliente aún debe devolver. No registra una venta.',
                    style: hint,
                  ),
                  const SizedBox(height: 12),
                  _picker(
                    label: 'Cliente',
                    value: _customer == null
                        ? null
                        : '${_customer!.razonSocial ?? ''} · ${_customer!.numeroDocumento ?? ''}',
                    placeholder: 'Busca un cliente registrado',
                    onTap: _pickCustomer,
                  ),
                  const SizedBox(height: 16),
                  _picker(
                    label: 'Producto que entregaste',
                    value: _product?.name,
                    placeholder: 'Busca el producto lleno',
                    onTap: _pickProduct,
                  ),
                  if (_product != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Envase por recuperar: ${_product!.container ?? ''}',
                        style: hint,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _quantity,
                          enabled: !_saving,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Envases por devolver',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _picker(
                          label: 'Fecha de entrega',
                          value: DateFormat('dd/MM/yyyy').format(_loanedOn),
                          placeholder: '',
                          onTap: _pickDate,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<int>(
                    isExpanded: true,
                    initialValue: offices.any((o) => o.id == _officeId)
                        ? _officeId
                        : null,
                    decoration: const InputDecoration(
                      labelText: 'Sede de la entrega',
                    ),
                    items: [
                      for (final office in offices)
                        DropdownMenuItem(
                          value: office.id,
                          child: Text(office.nombre ?? '-'),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (id) => setState(() => _officeId = id),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '¿Tu stock ya refleja la entrega?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  RadioGroup<bool>(
                    groupValue: _stockAlreadyDeducted,
                    onChanged: (value) {
                      if (!_saving) {
                        setState(() => _stockAlreadyDeducted = value);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          value: true,
                          title: const Text('Sí, ya los desconté'),
                          subtitle: const Text('Mantener el stock actual.'),
                        ),
                        RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          value: false,
                          title: const Text('No, todavía aparecen en stock'),
                          subtitle: Text(
                            'Descontar $_qty ${_qty == 1 ? 'envase vacío' : 'envases vacíos'} de la sede elegida.',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    key: ValueKey(_product?.id),
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 8),
                    title: const Text(
                      'Valor y observación',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text('Revisar costo o agregar una nota'),
                    initiallyExpanded: _product != null && _unitCost <= 0,
                    children: [
                      TextField(
                        controller: _cost,
                        enabled: !_saving && _product != null,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Costo por envase ($currency)',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Se sugiere el costo actual del envase vacío. Puedes corregirlo si era distinto al entregarlo. No se cobra al cliente.',
                          style: hint,
                        ),
                      ),
                      if (_product != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'Valor de referencia: '),
                                TextSpan(
                                  text:
                                      '${formatExchange(moneda: currency)}${pendingValue.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      '. Corresponde a envases por recuperar.',
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _note,
                        enabled: !_saving,
                        maxLength: 250,
                        decoration: const InputDecoration(
                          labelText: 'Observación (opcional)',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: ColorSchema.primaryColor,
                      ),
                      onPressed: _valid && !_saving ? _submit : null,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Registrar pendientes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Busca productos llenos configurados con envase retornable.
class _OpeningProductSheet extends ConsumerStatefulWidget {
  const _OpeningProductSheet();

  static Future<ContainerOpeningProduct?> show(BuildContext context) {
    return showModalBottomSheet<ContainerOpeningProduct>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const _OpeningProductSheet(),
    );
  }

  @override
  ConsumerState<_OpeningProductSheet> createState() =>
      _OpeningProductSheetState();
}

class _OpeningProductSheetState extends ConsumerState<_OpeningProductSheet> {
  Timer? _debounce;
  List<ContainerOpeningProduct> _results = const [];
  bool _loading = false;
  String? _error;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    // Lista inicial: los configurados suelen ser pocos.
    _search('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _search(String term) async {
    final version = ++_version;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await ref
          .read(containerLoansProvider.notifier)
          .openingProducts(term.trim());
      if (!mounted || version != _version) return;
      setState(() => _results = rows);
    } catch (error) {
      if (!mounted || version != _version) return;
      setState(() {
        _results = const [];
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted && version == _version) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  autofocus: true,
                  onChanged: (value) {
                    _debounce?.cancel();
                    _debounce = Timer(
                      const Duration(milliseconds: 400),
                      () => _search(value),
                    );
                  },
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Nombre o código del producto lleno',
                  ),
                ),
              ),
              if (_loading)
                const LinearProgressIndicator(color: ColorSchema.primaryColor),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_error!),
                ),
              if (!_loading && _error == null && _results.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'No hay productos configurados con envase retornable '
                    'que coincidan.',
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, i) {
                    final p = _results[i];
                    return ListTile(
                      title: Text(p.name ?? '-'),
                      subtitle: Text('Envase: ${p.container ?? '-'}'),
                      onTap: () => Navigator.of(context).pop(p),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
