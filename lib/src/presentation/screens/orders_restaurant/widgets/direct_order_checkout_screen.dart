import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_entry.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_method_row.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_controller.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'package:teki_app/src/providers/sale/cash_payment_validation.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_style.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/estilo_accion_principal.dart';

/// One native, scrollable form. The three actions remain visible above the safe
/// area and keyboard; fiscal amounts always come from the web's backend builder.
class DirectOrderCheckoutScreen extends ConsumerStatefulWidget {
  final OrderRestaurant order;
  final Map<String, dynamic>? initialQuote;
  const DirectOrderCheckoutScreen({
    super.key,
    required this.order,
    this.initialQuote,
  });
  @override
  ConsumerState<DirectOrderCheckoutScreen> createState() =>
      _DirectOrderCheckoutScreenState();
}

class _DirectOrderCheckoutScreenState
    extends ConsumerState<DirectOrderCheckoutScreen> {
  late final DirectCheckoutController checkout;
  late final SesionState session;
  late final String initialContext;
  final name = TextEditingController();
  final document = TextEditingController();
  final address = TextEditingController();
  final email = TextEditingController();
  final phone = TextEditingController();
  final deliveryAddress = TextEditingController();
  final delivery = TextEditingController(text: '0');
  final tip = TextEditingController(text: '0');
  final payments = <PaymentEntry>[];
  final tipPayments = <PaymentEntry>[];
  List<PaymentMethod> methods = [];
  List<String> series = [];
  List<Map<String, dynamic>> users = [];
  String orderType = 'PEDIDO_LOCAL_INTERNO';
  String documentType = '1';
  String type = 'NV';
  String? serie;
  int? waiter;
  bool exclude = false;
  bool loadingSeries = true;
  String? metadataError;
  String? validationError;
  Customer? selectedCustomer;
  OrderRestaurant? restoredOrder;
  double _previousTotal = 0;
  double _previousTip = 0;
  Timer? _debounce;
  int _seriesRevision = 0;
  final formKey = GlobalKey<FormState>();

  bool get locked =>
      checkout.busy || checkout.uncertain || !checkout.contextValid;
  bool get isDelivery => orderType == 'PEDIDO_FORANEO';
  double get tipAmount => double.tryParse(tip.text) ?? 0;
  String get symbol => checkout.currency == 'USD' ? r'$ ' : 'S/ ';
  String _context(SesionState s) => jsonEncode([
    s.companySelected?.id ?? s.company?.id,
    s.login.user?.id,
    s.office?.id,
    s.saleStation?.id,
    s.config?.toJson(),
  ]);

  @override
  void initState() {
    super.initState();
    session = ref.read(sesionProvider);
    initialContext = _context(session);
    type =
        ['01', '03', 'NV'].contains(session.config?.tipoComprobantePorDefecto)
        ? session.config!.tipoComprobantePorDefecto!
        : 'NV';
    orderType =
        session.config?.tipoPedidoRestaurantePorDefecto ??
        'PEDIDO_LOCAL_INTERNO';
    if (![
      'PEDIDO_LOCAL_INTERNO',
      'PEDIDO_LOCAL',
      'PEDIDO_FORANEO',
    ].contains(orderType)) {
      orderType = 'PEDIDO_LOCAL_INTERNO';
    }
    final customer = session.config?.clientePorDefecto == true
        ? session.config?.clientePorDefectoData
        : null;
    if (widget.order.cliente != null) {
      _fillCustomer(widget.order.cliente!);
    } else if (customer != null) {
      _fillCustomer(customer);
    }
    name.text = widget.order.denominacionReceptor ?? widget.order.nombreCliente ?? name.text;
    document.text = widget.order.numeroDocumentoReceptor ?? document.text;
    documentType = widget.order.tipoDocumentoReceptor ?? documentType;
    address.text = widget.order.direccionReceptor ?? address.text;
    email.text = widget.order.emailReceptor ?? email.text;
    phone.text = widget.order.telefonoReceptor ?? phone.text;
    final seen = <int?>{};
    methods = (session.config?.formasPago ?? [])
        .where(
          (m) =>
              m.id != null &&
              m.tipoMovimiento == 'INGRESO' &&
              m.eliminado != true &&
              seen.add(m.id),
        )
        .toList();
    checkout = DirectCheckoutController(
      service: ref.read(directCheckoutServiceProvider),
      scope:
          '${session.companySelected?.id ?? session.company?.id}:${session.login.user?.id}:${session.office?.id}:${session.saleStation?.id}',
      draft: _request(),
    );
    if (widget.initialQuote != null) {
      checkout.quote = widget.initialQuote;
      checkout.quoteKey = checkout.signature;
      _adjustSinglePayment(payments, checkout.total, 0);
      _previousTotal = checkout.total;
    }
    checkout.addListener(_changed);
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    await checkout.initialize();
    if (!mounted) return;
    if (checkout.uncertain) {
      final draft = checkout.draft;
      final order = draft['pedido'];
      restoredOrder = OrderRestaurant.fromJson(
        Map<String, dynamic>.from(order),
      );
      type = draft['tipoComprobante'];
      serie = draft['serie'];
      exclude = draft['excluirIgv'] == true;
      orderType = order['tipo'];
      documentType = order['tipoDocumentoReceptor'] ?? '1';
      name.text = order['denominacionReceptor'] ?? '';
      document.text = order['numeroDocumentoReceptor'] ?? '';
      address.text = order['direccionReceptor'] ?? '';
      deliveryAddress.text = order['direccionCompleta'] ?? '';
      delivery.text = '${order['montoDelivery'] ?? 0}';
      email.text = order['emailReceptor'] ?? '';
      phone.text = order['telefonoReceptor'] ?? '';
      tip.text = '${draft['propina'] ?? 0}';
      waiter = draft['idMozo'];
      _restorePayments(payments, draft['pagos'] as List? ?? []);
      _restorePayments(tipPayments, draft['pagosPropina'] as List? ?? []);
    } else {
      await _loadSeries();
    }
    try {
      final available = await checkout.service.users();
      if (mounted) setState(() => users = available);
    } catch (_) {
      /* Only needed when assigning a tip; retry stays available. */
    }
  }

  void _restorePayments(List<PaymentEntry> entries, List values) {
    for (final entry in entries) {
      entry.dispose();
    }
    entries.clear();
    for (final payment in values) {
      final id = payment['metodoPago']?['id'];
      final method =
          methods.where((m) => m.id == id).firstOrNull ??
          PaymentMethod.fromJson({
            ...Map<String, dynamic>.from(payment),
            'id': id,
          });
      if (!methods.any((m) => m.id == id)) methods.add(method);
      entries.add(
        PaymentEntry.fromExisting(
          method: method,
          amount: ((payment['montoPagado'] ?? payment['monto'] ?? 0) as num)
              .toStringAsFixed(2),
          operation: payment['numeroOperacion'] ?? '',
        ),
      );
    }
  }

  void _fillCustomer(Customer customer) {
    selectedCustomer = customer;
    name.text = customer.razonSocial ?? '';
    document.text = customer.numeroDocumento ?? '';
    address.text = customer.direccionCompleta ?? customer.direccion ?? '';
    email.text = customer.email ?? '';
    phone.text = customer.telefono ?? '';
    documentType = customer.tipoDocumento ?? '1';
  }

  double _finiteAmount(String value) {
    final amount = double.tryParse(value);
    return amount != null && amount.isFinite && amount >= 0 ? amount : 0;
  }

  Map<String, dynamic> _request() {
    final order = widget.order.toJson();
    final anonymous = document.text.trim().isEmpty && type != '01';
    final customerName = name.text.trim();
    final defaultCustomer = selectedCustomer != null &&
        (selectedCustomer?.porDefecto == true ||
            (session.config?.clientePorDefectoData?.id != null &&
                selectedCustomer?.id == session.config?.clientePorDefectoData?.id));
    final sameCustomer = selectedCustomer != null &&
        selectedCustomer?.numeroDocumento == document.text.trim() &&
        selectedCustomer?.tipoDocumento == documentType;
    final recipientName = customerName.isEmpty && anonymous
        ? 'Clientes varios'
        : customerName;
    final recipientType = anonymous ? '0' : documentType;
    final recipientNumber = anonymous ? '-' : document.text.trim();
    order.addAll({
      'puntoVenta': {'id': session.office?.id},
      'tipo': orderType,
      'nombreCliente': recipientName,
      'tipoDocumentoReceptor': recipientType,
      'numeroDocumentoReceptor': recipientNumber,
      'denominacionReceptor': recipientName,
      'direccionReceptor': address.text.trim(),
      'emailReceptor': email.text.trim(),
      'telefonoReceptor': phone.text.trim(),
      'direccionCompleta': isDelivery ? deliveryAddress.text.trim() : null,
      'direccion': isDelivery ? deliveryAddress.text.trim() : null,
      'montoDelivery': isDelivery ? _finiteAmount(delivery.text) : 0,
      'cliente': {
        'id':
            sameCustomer &&
                (defaultCustomer || selectedCustomer?.razonSocial == name.text.trim())
            ? selectedCustomer?.id
            : null,
        'razonSocial': anonymous
            ? 'Clientes varios'
            : defaultCustomer && sameCustomer
                ? selectedCustomer?.razonSocial
                : recipientName,
        'tipoDocumento': recipientType,
        'numeroDocumento': recipientNumber,
        'direccionCompleta': anonymous ? null : address.text.trim(),
        'direccion': anonymous ? null : address.text.trim(),
        'email': anonymous ? null : email.text.trim(),
        'telefono': anonymous ? null : phone.text.trim(),
      },
    });
    return {
      'pedido': order,
      'idEstacionVenta': session.saleStation?.id,
      'tipoComprobante': type,
      'serie': serie,
      'excluirIgv': exclude,
      'propina': tipAmount.isFinite ? tipAmount : 0,
      'idMozo': waiter,
    };
  }

  void _changed() {
    if (!mounted) return;
    final next = checkout.total;
    if (next != _previousTotal && checkout.quoteKey != null) {
      _adjustSinglePayment(payments, next, _previousTotal);
      _previousTotal = next;
    }
    setState(() {});
  }

  void _adjustSinglePayment(
    List<PaymentEntry> entries,
    double amount,
    double previous,
  ) {
    if (entries.isEmpty) {
      final cash = methods.where((m) => m.formaPago == 'EFECTIVO').firstOrNull;
      if (cash != null && amount > 0) {
        entries.add(PaymentEntry(method: cash, initialAmount: amount));
      }
    } else if (entries.length == 1) {
      final entry = entries.single;
      final current = double.tryParse(entry.amountController.text) ?? 0;
      if (current == previous ||
          entry.method.formaPago == 'EFECTIVO' && current > previous) {
        entry.amountController.text =
            (current > previous ? math.max(current, amount) : amount)
                .toStringAsFixed(2);
      }
    }
  }

  void _update({bool quote = false}) {
    if (locked) return;
    validationError = null;
    checkout.update(_request());
    if (quote) {
      _debounce?.cancel();
      _debounce = Timer(
        const Duration(milliseconds: 250),
        () => checkout.refresh(),
      );
    }
  }

  Future<void> _loadSeries() async {
    final revision = ++_seriesRevision;
    setState(() {
      loadingSeries = true;
      metadataError = null;
    });
    try {
      final list = await checkout.service.series(session.office!.id!, type);
      if (!mounted || revision != _seriesRevision) return;
      setState(() {
        series = list;
        if (!list.contains(serie)) serie = list.firstOrNull;
        if (list.isEmpty) {
          metadataError = 'No hay series disponibles en esta sede.';
        }
      });
      _update();
    } catch (_) {
      if (mounted && revision == _seriesRevision) {
        setState(() {
          serie = null;
          metadataError = 'No se pudieron cargar las series.';
        });
      }
    } finally {
      if (mounted && revision == _seriesRevision) {
        setState(() => loadingSeries = false);
      }
    }
  }

  List<Map<String, dynamic>> _paymentPayload(
    List<PaymentEntry> entries,
    double total,
  ) {
    if (entries.isEmpty) {
      throw StateError('Seleccione al menos una forma de pago.');
    }
    double cents(double n) => (n * 100).round() / 100;
    final amounts = entries
        .map((e) => double.tryParse(e.amountController.text) ?? -1)
        .toList();
    if (amounts.any((n) => !n.isFinite || n <= 0)) {
      throw StateError('Revise los importes de pago.');
    }
    final nonCash = cents(
      entries.indexed
          .where((e) => e.$2.method.formaPago != 'EFECTIVO')
          .fold(0.0, (sum, e) => sum + amounts[e.$1]),
    );
    final cash = cents(
      entries.indexed
          .where((e) => e.$2.method.formaPago == 'EFECTIVO')
          .fold(0.0, (sum, e) => sum + amounts[e.$1]),
    );
    final error = validateCashPayment(
      total: total,
      cash: cash,
      nonCash: nonCash,
    );
    if (error != null) throw StateError(error);
    return entries.indexed.map((entry) {
      final method = entry.$2.method;
      final received = cents(amounts[entry.$1]);
      final amount = method.formaPago == 'EFECTIVO'
          ? cents(total - nonCash)
          : received;
      if (amount <= 0) {
        throw StateError('Quite la forma de pago sin importe asignado.');
      }
      return {
        'metodoPago': {'id': method.id},
        'formaPago': method.formaPago,
        'tipoTarjeta': method.tipoTarjeta,
        'nombre': method.nombre,
        'numeroOperacion': entry.$2.operationController.text.trim(),
        'monto': amount,
        'montoPagado': received,
        'cambio': method.formaPago == 'EFECTIVO' ? cents(received - amount) : 0,
      };
    }).toList();
  }

  Future<void> _submit(String action) async {
    FocusScope.of(context).unfocus();
    if (!checkout.uncertain) {
      setState(() => validationError = null);
      if (!formKey.currentState!.validate()) return;
      try {
        _update();
        if (action != 'DRAFT' &&
            tipAmount.isFinite &&
            ((tipAmount * 100) - (tipAmount * 100).round()).abs() > 0.000001) {
          throw StateError('Ingrese la propina con hasta dos decimales.');
        }
        if (action == 'INVOICE') {
          if (type == '03' &&
              checkout.total >= 700 &&
              (name.text.trim().isEmpty ||
                  document.text.trim().isEmpty ||
                  documentType == '0')) {
            throw StateError(
              'Para esta boleta complete el nombre y documento del cliente.',
            );
          }
          if (document.text.trim().isNotEmpty &&
              documentType != '0' &&
              name.text.trim().isEmpty) {
            throw StateError('Complete el nombre del cliente.');
          }
          if (document.text.trim().isNotEmpty &&
              documentType == '1' &&
              !RegExp(r'^\d{8}$').hasMatch(document.text.trim())) {
            throw StateError('Ingrese un DNI de 8 dígitos.');
          }
          if (type == '01' &&
              (name.text.trim().isEmpty ||
                  documentType != '6' ||
                  !RegExp(r'^\d{11}$').hasMatch(document.text.trim()) ||
                  address.text.trim().isEmpty)) {
            throw StateError(
              'La factura requiere RUC de 11 dígitos, razón social y dirección fiscal.',
            );
          }
          if (!tipAmount.isFinite || tipAmount < 0) {
            throw StateError('La propina no puede ser negativa.');
          }
          if (tipAmount > 0 && waiter == null) {
            throw StateError('Seleccione al responsable de la propina.');
          }
          checkout.update({
            ...checkout.draft,
            'pagos': _paymentPayload(payments, checkout.total),
            'pagosPropina': tipAmount > 0
                ? _paymentPayload(tipPayments, tipAmount)
                : [],
          });
        }
        if (action == 'EDIT') {
          List<Map<String, dynamic>> salePayments = [];
          try {
            salePayments = _paymentPayload(payments, checkout.total);
          } on StateError {
            /* The full editor can finish payment. */
          }
          if (!tipAmount.isFinite ||
              tipAmount < 0 ||
              tipAmount > 0 && waiter == null) {
            throw StateError('Revise la propina y seleccione su responsable.');
          }
          checkout.update({
            ...checkout.draft,
            'pagos': salePayments,
            'pagosPropina': tipAmount > 0
                ? _paymentPayload(tipPayments, tipAmount)
                : [],
          });
        }
      } on StateError catch (e) {
        setState(() => validationError = e.message.toString());
        return;
      }
    }
    final result = await checkout.submit(action);
    if (mounted && result != null) {
      final assigned = users
          .where((u) => u['id'] == result.checkoutData['idMozo'])
          .firstOrNull;
      Navigator.of(context).pop(
        DirectCheckoutResult(
          result.order,
          result.check,
          result.replayed,
          result.action,
          automaticPrinting: result.automaticPrinting,
          checkoutData: {
            ...result.checkoutData,
            'nombreMozo': assigned?['nombreCompleto'] ?? assigned?['nombres'],
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    checkout.removeListener(_changed);
    checkout.dispose();
    for (final c in [
      name,
      document,
      address,
      email,
      phone,
      deliveryAddress,
      delivery,
      tip,
    ]) {
      c.dispose();
    }
    for (final entry in [...payments, ...tipPayments]) {
      entry.dispose();
    }
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    TextInputType? keyboard,
    ValueChanged<String>? onChanged,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      enabled: !locked,
      decoration: InputDecoration(labelText: label),
      onChanged: onChanged ?? (_) => _update(),
      validator: validator,
    ),
  );

  Widget _paymentFeedback(List<PaymentEntry> entries, double total) {
    var cash = 0.0;
    var other = 0.0;
    for (final entry in entries) {
      final value = double.tryParse(entry.amountController.text) ?? 0;
      if (!value.isFinite || value < 0) continue;
      if (entry.method.formaPago == 'EFECTIVO') {
        cash += value;
      } else {
        other += value;
      }
    }
    final remaining = math.max(0, total - cash - other);
    final change = math.max(0, cash - math.max(0, total - other));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 20,
        runSpacing: 8,
        children: [
          Text('Recibido: $symbol${(cash + other).toStringAsFixed(2)}'),
          if (remaining > 0.005)
            Text('Falta: $symbol${remaining.toStringAsFixed(2)}'),
          if (cash > 0)
            Text(
              'Vuelto: $symbol${change.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _payments(List<PaymentEntry> entries, double amount) => Column(
    children: [
      for (final method in methods)
        PaymentMethodRow(
          method: method,
          entry: entries.where((e) => e.method.id == method.id).firstOrNull,
          onAmountChanged: () => setState(() => validationError = null),
          onTap: () {
            if (locked || entries.any((e) => e.method.id == method.id)) return;
            // One cash row avoids assigning the same change to multiple entries.
            if (method.formaPago == 'EFECTIVO' &&
                entries.any((e) => e.method.formaPago == 'EFECTIVO')) {
              return;
            }
            setState(
              () => entries.add(
                PaymentEntry(
                  method: method,
                  initialAmount: math.max(
                    0,
                    amount -
                        entries.fold(
                          0.0,
                          (sum, e) =>
                              sum +
                              (double.tryParse(e.amountController.text) ?? 0),
                        ),
                  ),
                ),
              ),
            );
          },
          onRemove: () {
            if (locked) return;
            setState(() {
              final e = entries.firstWhere((e) => e.method.id == method.id);
              entries.remove(e);
              e.dispose();
            });
          },
        ),
      if (entries.isNotEmpty) _paymentFeedback(entries, amount),
    ],
  );

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (previous, next) {
      if (_context(next) != initialContext) checkout.invalidateContext();
    });
    return PedidosStyle(child: Builder(builder: _buildCheckout));
  }

  Widget _buildCheckout(BuildContext context) {
    final quoted = checkout.quote;
    final presentedOrder = restoredOrder ?? widget.order;
    final error = validationError ?? checkout.error ?? metadataError;
    final estimate =
        presentedOrder.comandas
            ?.expand((c) => c.items ?? [])
            .fold<double>(
              0,
              (sum, item) =>
                  sum + (item.precioVenta ?? 0) * (item.cantidad ?? 0),
            ) ??
        0;
    final displayed = quoted != null ? checkout.total : estimate;
    return PopScope(
      canPop: !checkout.busy,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Completar pedido'),
          backgroundColor: ColorSchema.primaryColor,
          foregroundColor: Colors.white,
          automaticallyImplyLeading: !checkout.busy,
        ),
        body: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Entrega',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in {
                          'PEDIDO_LOCAL_INTERNO': 'Interno',
                          'PEDIDO_LOCAL': 'Para llevar',
                          'PEDIDO_FORANEO': 'Delivery',
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: orderType == entry.key,
                            onSelected: locked
                                ? null
                                : (_) {
                                    setState(() => orderType = entry.key);
                                    _update(quote: true);
                                  },
                          ),
                      ],
                    ),
                    if (isDelivery) ...[
                      const SizedBox(height: 16),
                      _field(
                        'Dirección de entrega',
                        deliveryAddress,
                        validator: (v) => v?.trim().isEmpty != false
                            ? 'Ingrese la dirección de entrega'
                            : null,
                      ),
                      _field(
                        'Costo de delivery',
                        delivery,
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        onChanged: (_) => _update(quote: true),
                        validator: (v) {
                          final amount = double.tryParse(v ?? '');
                          return amount == null ||
                                  !amount.isFinite ||
                                  amount < 0
                              ? 'Ingrese un importe válido'
                              : null;
                        },
                      ),
                    ],
                    const SizedBox(height: 18),
                    const Text(
                      'Comprobante',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final entry in {
                          '03': 'Boleta',
                          '01': 'Factura',
                          'NV': 'Nota de venta',
                        }.entries)
                          ChoiceChip(
                            label: Text(entry.value),
                            selected: type == entry.key,
                            onSelected: locked
                                ? null
                                : (_) {
                                    setState(() {
                                      type = entry.key;
                                      serie = null;
                                      if (type == '01') documentType = '6';
                                    });
                                    _update(quote: true);
                                    unawaited(_loadSeries());
                                  },
                          ),
                      ],
                    ),
                    if (series.length == 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text('Serie ${series.first} · Automática'),
                      ),
                    if (series.length > 1)
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: serie,
                        decoration: const InputDecoration(labelText: 'Serie'),
                        items: series
                            .map(
                              (s) => DropdownMenuItem(value: s, child: Text(s)),
                            )
                            .toList(),
                        onChanged: locked
                            ? null
                            : (v) {
                                setState(() => serie = v);
                                _update();
                              },
                      ),
                    if (type == 'NV' &&
                        session.config?.excluirIgvNotaVenta == true)
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Excluir IGV en la nota de venta'),
                        value: exclude,
                        onChanged: locked
                            ? null
                            : (v) {
                                setState(() => exclude = v ?? false);
                                _update(quote: true);
                              },
                      ),
                    const SizedBox(height: 18),
                    Text(
                      type == '01' || type == '03' && checkout.total >= 700
                          ? 'Cliente'
                          : 'Cliente (opcional)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Autocomplete<Customer>(
                      key: ValueKey('customer-${checkout.uncertain}'),
                      initialValue: TextEditingValue(text: name.text),
                      optionsBuilder: (text) async =>
                          text.text.trim().length < 3 || locked
                          ? []
                          : await ref
                                .read(customerSaleProvider.notifier)
                                .getCustomerss(text.text.trim()),
                      displayStringForOption: (c) => c.razonSocial ?? '',
                      onSelected: (c) {
                        setState(() => _fillCustomer(c));
                        _update();
                      },
                      fieldViewBuilder: (context, text, focus, submit) =>
                          TextFormField(
                            controller: text,
                            focusNode: focus,
                            onTap: () {
                              text.selection = TextSelection(baseOffset: 0, extentOffset: text.text.length);
                            },
                            enabled: !locked,
                            decoration: const InputDecoration(
                              labelText: 'Nombre o documento',
                            ),
                            onChanged: (v) {
                              name.text = v;
                              _update();
                            },
                          ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: documentType,
                      key: ValueKey(documentType),
                      decoration: const InputDecoration(
                        labelText: 'Tipo de documento',
                      ),
                      items:
                          {
                                '0': 'Sin documento',
                                '1': 'DNI',
                                '4': 'Carnet de extranjería',
                                '6': 'RUC',
                                '7': 'Pasaporte',
                                'A': 'Cédula diplomática',
                              }.entries
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e.key,
                                  child: Text(e.value),
                                ),
                              )
                              .toList(),
                      onChanged: locked
                          ? null
                          : (v) {
                              setState(() => documentType = v!);
                              _update();
                            },
                    ),
                    const SizedBox(height: 14),
                    _field(
                      'Número de documento',
                      document,
                      keyboard: TextInputType.text,
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      key: ValueKey('contact-${type == '01'}'),
                      initiallyExpanded: type == '01',
                      title: const Text('Dirección y contacto'),
                      children: [
                        _field('Dirección fiscal', address),
                        _field(
                          'Email',
                          email,
                          keyboard: TextInputType.emailAddress,
                        ),
                        _field(
                          'Teléfono',
                          phone,
                          keyboard: TextInputType.phone,
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    const Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    for (final item
                        in (quoted?['items'] as List? ??
                            presentedOrder.comandas
                                ?.expand((c) => c.items ?? [])
                                .indexed
                                .map(
                                  (entry) => {
                                    'cantidad': entry.$2.cantidad,
                                    'descripcion': entry.$2.producto?.nombre,
                                    'precioTotal':
                                        (quoted?['totalesPedido'] as List?)
                                            ?.elementAtOrNull(entry.$1) ??
                                        (entry.$2.precioVenta ?? 0) *
                                            (entry.$2.cantidad ?? 0),
                                  },
                                )
                                .toList() ??
                            []))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          '${item['cantidad']} × ${item['descripcion']}',
                        ),
                        trailing: Text(
                          '$symbol${(item['precioTotal'] as num? ?? 0).toStringAsFixed(2)}',
                        ),
                      ),
                    if ((quoted?['otrosCargos'] as num? ?? 0) > 0)
                      Text(
                        'Recargo: $symbol${(quoted!['otrosCargos'] as num).toStringAsFixed(2)}',
                      ),
                    const Divider(height: 28),
                    const Text(
                      'Pago',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AbsorbPointer(
                      absorbing: locked,
                      child: _payments(payments, checkout.total),
                    ),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        tipAmount > 0
                            ? 'Propina: $symbol${tipAmount.toStringAsFixed(2)}'
                            : 'Agregar propina',
                      ),
                      children: [
                        _field(
                          'Propina',
                          tip,
                          keyboard: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          onChanged: (_) {
                            _adjustSinglePayment(
                              tipPayments,
                              tipAmount,
                              _previousTip,
                            );
                            _previousTip = tipAmount;
                            _update();
                            setState(() {});
                          },
                        ),
                        if (tipAmount > 0) ...[
                          DropdownButtonFormField<int>(
                            isExpanded: true,
                            initialValue: waiter,
                            decoration: const InputDecoration(
                              labelText: 'Responsable',
                            ),
                            items: users
                                .map(
                                  (u) => DropdownMenuItem<int>(
                                    value: u['id'],
                                    child: Text(
                                      u['nombreCompleto'] ??
                                          u['nombres'] ??
                                          'Usuario ${u['id']}',
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: locked
                                ? null
                                : (v) {
                                    setState(() => waiter = v);
                                    _update();
                                  },
                          ),
                          if (users.isEmpty)
                            TextButton(
                              onPressed: () async {
                                try {
                                  final loaded = await checkout.service.users();
                                  if (mounted) setState(() => users = loaded);
                                } catch (_) {
                                  if (mounted) {
                                    setState(
                                      () => validationError =
                                          'No se pudieron cargar los responsables.',
                                    );
                                  }
                                }
                              },
                              child: const Text('Cargar responsables'),
                            ),
                          AbsorbPointer(
                            absorbing: locked,
                            child: _payments(tipPayments, tipAmount),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Align(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  MediaQuery.viewInsetsOf(context).bottom + 8,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 16,
                      children: [
                        const Text('Total a pagar'),
                        Text(
                          '$symbol${displayed.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    if (checkout.uncertain && !checkout.busy)
                      const Text(
                        'Puedes salir y recuperar este pedido después sin volver a cobrar.',
                      ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    if (!checkout.uncertain &&
                        (checkout.error != null || metadataError != null))
                      TextButton(
                        onPressed: checkout.busy
                            ? null
                            : () {
                                unawaited(checkout.refresh(force: true));
                                unawaited(_loadSeries());
                              },
                        child: const Text('Actualizar total'),
                      ),
                    FilledButton(
                      style: estiloAccionPrincipal,
                      onPressed:
                          checkout.contextValid &&
                              (checkout.uncertain
                                  ? !checkout.busy
                                  : checkout.ready && !loadingSeries)
                          ? () => _submit('INVOICE')
                          : null,
                      child: Text(
                        checkout.busy
                            ? 'Guardando…'
                            : checkout.uncertain
                            ? 'Recuperar pedido'
                            : 'Emitir comprobante',
                      ),
                    ),
                    if (checkout.uncertain)
                      TextButton(
                        onPressed: checkout.busy
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Continuar después'),
                      ),
                    if (!checkout.uncertain)
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: locked || !checkout.initialized
                                  ? null
                                  : () => _submit('DRAFT'),
                              child: const Text('Guardar borrador'),
                            ),
                          ),
                          Expanded(
                            child: TextButton(
                              onPressed: locked || !checkout.initialized
                                  ? null
                                  : () => _submit('EDIT'),
                              child: const Text('Facturación completa'),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
