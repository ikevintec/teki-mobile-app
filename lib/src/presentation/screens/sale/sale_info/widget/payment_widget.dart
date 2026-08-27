import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/payment_method.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_fee.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen/view_comprobante_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/credito_tab.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_entry.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment/payment_method_row.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/summary_bar.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/credito_cuotas.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/notifications.dart';

// ─── Widget principal ─────────────────────────────────────────────────────────

class PaymentWidget extends ConsumerStatefulWidget {
  const PaymentWidget({super.key});

  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (_, _, _) => const PaymentWidget(),
      transitionBuilder: (_, animation, _, child) {
        final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
        return Stack(
          fit: StackFit.expand,
          children: [
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 6 * animation.value,
                sigmaY: 6 * animation.value,
              ),
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.65 * animation.value),
              ),
            ),
            FadeTransition(
              opacity: curved,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.95, end: 1.0).animate(curved),
                child: child,
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  ConsumerState<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends ConsumerState<PaymentWidget>
    with SingleTickerProviderStateMixin {
  final ComprobantePrintService _printService = ComprobantePrintService();

  late TabController _tabController;
  List<PaymentMethod> paymentMethods = [];
  final List<PaymentEntry> _paymentEntries = [];

  TextEditingController diasCredito = TextEditingController();
  List<TextEditingController> fechaCredito = [];
  List<TextEditingController> montoCredito = [];

  double total = 0;
  String currency = '';

  final formKeyCredito = GlobalKey<FormState>();
  bool _submitAttempted = false;
  bool _isSubmitting = false;

  double get _totalPaid => _paymentEntries.fold(
      0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));

  double get _remaining => (total - _totalPaid).clamp(0.0, double.infinity);

  bool get _hasCash => _paymentEntries.any(
      (e) => (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO');

  bool get _hasNonCash => _paymentEntries.any(
      (e) => (e.method.formaPago ?? '').toUpperCase() != 'EFECTIVO');

  double get _cashTotal => _paymentEntries
      .where((e) => (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO')
      .fold(0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));

  double get _nonCashTotal => _paymentEntries
      .where((e) => (e.method.formaPago ?? '').toUpperCase() != 'EFECTIVO')
      .fold(0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));

  double get _cambio {
    if (!_hasCash) return 0.0;
    final cashNeeded = (total - _nonCashTotal).clamp(0.0, double.infinity);
    return (_cashTotal - cashNeeded).clamp(0.0, double.infinity);
  }

  String? get _contadoError {
    if (_paymentEntries.isEmpty) {
      return _submitAttempted ? "Debe seleccionar al menos un método de pago" : null;
    }
    // FIX CC/CP: comparación en céntimos; los doubles con error binario
    // (33.33+33.33+33.34) ya no bloquean una suma exacta en decimal.
    final paidCent = (_totalPaid * 100).round();
    final totalCent = (total * 100).round();
    if (paidCent < totalCent) {
      return "El monto pagado es menor al total de la venta";
    }
    if (_hasNonCash && paidCent > totalCent) {
      return "Al usar métodos de pago sin efectivo, el monto debe ser exacto.";
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerTicket = ref.watch(ticketProvider);
      final ticket = providerTicket.ticket;
      final isEdit = providerTicket.isEdit;

      total = double.parse((ticket.totalVenta ?? 0).toStringAsFixed(2));
      currency = ticket.codigoMoneda ?? 'PEN';
      final sesion = ref.read(sesionProvider);
      paymentMethods = sesion.config?.formasPago ?? [];

      if (isEdit) {
        _loadExistingPaymentData(ticket);
      } else {
        diasCredito.text = "30";
      }

      setState(() {});
    });
  }

  @override
  void dispose() {
    for (final e in _paymentEntries) {
      e.dispose();
    }
    diasCredito.dispose();
    super.dispose();
  }

  void _autoprint(Ticket ticket) {
    if (ticket.id == null ||
        ticket.uuid == null ||
        ticket.identificadorDocumento == null) {
      return;
    }

    final session = ref.read(sesionProvider);
    final printer = session.saleStation?.impresoraComprobante;
    final config = session.config;
    if (printer == null || config == null) return;

    final escPos = config.imprimeTicketsEscPos ?? false;
    final tipo = config.tipoImpresion ?? 'A4';
    final pdfUrl =
        '${Environment.apiUrl}/public/pdf/tickets/${ticket.uuid}/${ticket.identificadorDocumento}?tipo=$tipo';

    unawaited(() async {
      try {
        await _printService.autoprint(
          ticketId: ticket.id!,
          pdfUrl: pdfUrl,
          printer: printer,
          escPos: escPos,
          officeCode: session.office?.codigo ?? '',
          idCompany: session.companySelected?.id,
          config: config,
        );
      } on PrintCoffeException catch (_) {
      } catch (_) {}
    }());
  }

  void _loadExistingPaymentData(Ticket ticket) {
    if (ticket.movimientoCaja?.pagos?.isNotEmpty == true) {
      for (final pago in ticket.movimientoCaja!.pagos!) {
        final method = paymentMethods.firstWhere(
          (p) => p.id == pago.metodoPago?.id,
          orElse: () => pago.metodoPago ?? PaymentMethod(),
        );
        if (method.id == null) continue;
        _paymentEntries.add(PaymentEntry.fromExisting(
          method: method,
          amount: (pago.montoPagado ?? pago.monto ?? 0).toStringAsFixed(2),
          operation: pago.numeroOperacion ?? '',
        ));
      }
      _tabController.index = 0;
    }

    if (ticket.cuotas?.isNotEmpty == true) {
      diasCredito.text = (ticket.diasCredito ?? 0).toString();
      fechaCredito.clear();
      montoCredito.clear();
      for (final cuota in ticket.cuotas!) {
        fechaCredito.add(TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(cuota.fecha ?? DateTime.now()),
        ));
        montoCredito.add(TextEditingController(
          text: (cuota.monto ?? 0).toStringAsFixed(2),
        ));
      }
      _tabController.index = 1;
    }

    if (ticket.movimientoCaja == null && (ticket.cuotas?.isEmpty ?? true)) {
      diasCredito.text = (ticket.diasCredito ?? 30).toString();
    }
  }

  List<PaymentMethod> getFilteredPaymentMethods() {
    final Map<int, PaymentMethod> uniqueMap = {};
    bool efectivoAdded = false;
    for (final p in paymentMethods) {
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
    if (method.id == null) return;
    if (_paymentEntries.any((e) => e.method.id == method.id)) return;
    setState(() {
      _paymentEntries
          .add(PaymentEntry(method: method, initialAmount: _remaining));
    });
  }

  void _removePayment(int index) {
    _paymentEntries[index].dispose();
    setState(() => _paymentEntries.removeAt(index));
  }

  void addCuota() {
    final dias = int.tryParse(diasCredito.text) ?? 0;
    DateTime fechaBase;
    if (fechaCredito.isNotEmpty) {
      fechaBase =
          DateTime.parse(fechaCredito.last.text).add(Duration(days: dias));
    } else {
      fechaBase = DateTime.now().add(Duration(days: dias));
    }
    fechaCredito.add(
        TextEditingController(text: DateFormat('yyyy-MM-dd').format(fechaBase)));
    montoCredito.add(TextEditingController());
    redistribuirMontos();
    setState(() {});
  }

  void eliminarCuota(int index) {
    fechaCredito.removeAt(index);
    montoCredito.removeAt(index);
    redistribuirMontos();
  }

  void redistribuirMontos() {
    // Reparto que suma exacto: la última cuota absorbe el residuo de centavos.
    final montos = CreditoCuotas.repartir(total, montoCredito.length);
    for (var i = 0; i < montoCredito.length; i++) {
      montoCredito[i].text = montos[i].toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _selectDate(int index) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today,
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Colors.blue,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      fechaCredito[index].text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  bool procesoCredito() {
    final provider = ref.read(ticketProvider.notifier);
    final List<TicketFee> cuotas = [];
    for (int i = 0; i < fechaCredito.length; i++) {
      final fecha = fechaCredito[i].text;
      final monto = montoCredito[i].text;
      if (fecha.isNotEmpty && monto.isNotEmpty) {
        cuotas.add(TicketFee(
          fecha: DateTime.parse(fecha),
          monto: CreditoCuotas.round2(double.tryParse(monto) ?? 0.0),
        ));
      }
    }
    if (cuotas.isEmpty) {
      errorNotification("Debe agregar al menos una cuota");
      return false;
    }
    if (cuotas.any((c) => c.monto! <= 0)) {
      errorNotification("Todos los montos de las cuotas deben ser mayores a cero");
      return false;
    }
    // FIX CC/CP: la suma de cuotas debe igualar el total (el backend ahora
    // rechaza cualquier descuadre con 412).
    if (CreditoCuotas.descuadraTotal(
        cuotas.map((c) => c.monto ?? 0).toList(), total)) {
      final suma = cuotas.fold<double>(0, (a, c) => a + (c.monto ?? 0));
      errorNotification(
          "Las cuotas suman S/. ${suma.toStringAsFixed(2)} y deben sumar el total de la venta (S/. ${total.toStringAsFixed(2)})");
      return false;
    }
    provider.setCuotas(cuotas, diasCredito: int.tryParse(diasCredito.text));
    return true;
  }

  void procesoContado() {
    final provider = ref.read(ticketProvider.notifier);
    final pagos = _paymentEntries
        .where((e) => (double.tryParse(e.amountController.text) ?? 0.0) > 0)
        .map((e) {
      final amount = double.tryParse(e.amountController.text) ?? 0.0;
      final isCash = (e.method.formaPago ?? '').toUpperCase() == 'EFECTIVO';
      final effectiveAmount = isCash ? (amount - _cambio).clamp(0.0, amount) : amount;
      return PaymentDetail(
        formaPago: e.method.formaPago,
        // Paridad web: monto = neto aplicado a la venta; montoPagado = lo
        // que el cliente ENTREGÓ. Ambos redondeados a 2 decimales (FIX CC/CP:
        // los doubles crudos persistían colas binarias en caja).
        monto: CreditoCuotas.round2(effectiveAmount),
        montoPagado: CreditoCuotas.round2(amount),
        metodoPago: e.method,
        numeroOperacion: e.operationController.text.isNotEmpty
            ? e.operationController.text
            : null,
        nombre: e.method.nombre,
        tipoTarjeta: e.method.tipoTarjeta,
      );
    }).toList();

    provider.setMovimientoCaja(
      total: total,
      pagos: pagos,
      cambio: _cambio,
      // Efectivo crudo recibido (paridad web: ticket.efectivo).
      efectivo: _cashTotal,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePaymentMethods = getFilteredPaymentMethods();
    final ticket = ref.watch(ticketProvider).ticket;
    final notifier = ref.read(ticketProvider.notifier);
    final ticketP = ref.watch(ticketProvider);
    final canAgrupar = ref.read(sesionProvider).config?.agruparItemsVenta ?? false;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      clipBehavior: Clip.hardEdge,
      backgroundColor: Colors.grey.shade100,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────
            Container(
              color: ColorSchema.primaryColor,
              padding: const EdgeInsets.fromLTRB(4, 8, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Pago',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (canAgrupar)
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: CustomSwitch(
                          small: true,
                          title: "Agrupar ítems",
                          rightAlign: false,
                          border: false,
                          textColor: Colors.white,
                          activeColor: Colors.white,
                          activeToggleColor: ColorSchema.primaryColor,
                          activeTextColor: ColorSchema.primaryColor,
                          value: ticket.agruparItems ?? false,
                          onChanged: notifier.setAgruparItems,
                        ),
                      ),
                    ),
                  if (!canAgrupar) const Spacer(),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: ColorSchema.primaryColor,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: ColorSchema.primaryColor,
                dividerColor: Colors.grey.shade200,
                tabs: const [
                  Tab(text: "Contado"),
                  Tab(text: "Crédito"),
                ],
              ),
            ),
            // ── Tabs ────────────────────────────────────────────────────────
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  // ── Tab Contado ──────────────────────────────────────────
                  ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                    itemCount: visiblePaymentMethods.length,
                    itemBuilder: (_, index) {
                      final payment = visiblePaymentMethods[index];
                      final entryIndex = _paymentEntries
                          .indexWhere((e) => e.method.id == payment.id);
                      final entry =
                          entryIndex >= 0 ? _paymentEntries[entryIndex] : null;
                      return PaymentMethodRow(
                        method: payment,
                        entry: entry,
                        onTap: () => entry == null
                            ? _addPayment(payment)
                            : _removePayment(entryIndex),
                        onRemove: entry != null
                            ? () => _removePayment(entryIndex)
                            : null,
                        onAmountChanged: () => setState(() {}),
                      );
                    },
                  ),
                  // ── Tab Crédito ──────────────────────────────────────────
                  CreditoTab(
                    formKey: formKeyCredito,
                    diasCredito: diasCredito,
                    fechaCredito: fechaCredito,
                    montoCredito: montoCredito,
                    onAddCuota: addCuota,
                    onRemoveCuota: eliminarCuota,
                    onSelectDate: _selectDate,
                  ),
                ],
              ),
            ),
            // ── Error inline (contado) ────────────────────────────────────
            if (_tabController.index == 0)
              Builder(builder: (_) {
                final error = _contadoError;
                if (error == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade600, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            error,
                            style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            // ── Total ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Builder(builder: (_) {
                final isContado = _tabController.index == 0;
                final hasEntries = _paymentEntries.isNotEmpty;
                return SummaryBarSales(
                  showOnlyTotal: true,
                  showCambio: isContado && hasEntries && _hasCash,
                  montoPagado: _totalPaid,
                  showMontoPagado: isContado && hasEntries,
                  cambio: _cambio,
                );
              }),
            ),
            // ── Botón finalizar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final notifier = ref.read(ticketProvider.notifier);
                          final isContado = _tabController.index == 0;

                          if (isContado) {
                            setState(() => _submitAttempted = true);
                            final error = _contadoError;
                            if (error != null) return;
                            procesoContado();
                          } else {
                            final isValid =
                                formKeyCredito.currentState?.validate() ?? false;
                            if (!isValid) return;
                            if (!procesoCredito()) return;
                          }

                          setState(() => _isSubmitting = true);
                          try {
                            final ticketState = ref.read(ticketProvider);
                            final checkId = ticketState.ticket.cuentaRestaurante;

                            if (checkId != null && !ticketState.isEdit) {
                              try {
                                final comprobante =
                                    await notifier.pagarCuentaRestaurante(checkId);
                                ref.invalidate(ticketProvider);
                                ref.invalidate(productSaleProvider);
                                ref.invalidate(customerSaleProvider);
                                if (comprobante != null) {
                                  _autoprint(comprobante);
                                  Get.off(() => ViewComponentScreen(
                                        ticket: comprobante,
                                        id: comprobante.id,
                                        fromSale: true,
                                      ));
                                } else {
                                  Get.back();
                                }
                              } catch (e) {
                                errorNotification("Error al registrar el pago: $e");
                                if (mounted) setState(() => _isSubmitting = false);
                              }
                            } else {
                              final Ticket? ticketResponse =
                                  await notifier.proceessTicket();
                              if (ticketResponse != null) {
                                final ticketToShow =
                                    notifier.mergeTicketResponse(ticketResponse);
                                ref.invalidate(ticketProvider);
                                ref.invalidate(productSaleProvider);
                                ref.invalidate(customerSaleProvider);
                                _autoprint(ticketResponse);
                                Get.off(() => ViewComponentScreen(
                                      ticket: ticketToShow,
                                      fromSale: true,
                                    ));
                              } else {
                                if (mounted) setState(() => _isSubmitting = false);
                              }
                            }
                          } catch (e) {
                            errorNotification("Error inesperado: $e");
                            if (mounted) setState(() => _isSubmitting = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorSchema.primaryColor,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        ColorSchema.primaryColor.withValues(alpha: 0.5),
                    disabledForegroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(ticketP.isEdit ? 'Finalizar Edición' : 'Finalizar Pago'),
                            const SizedBox(width: 8),
                            const Icon(Icons.check_circle),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
