import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFee.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen.dart/view_comprobante_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/summary_bar.dart';
import 'package:teki_app/src/presentation/widgets/switch/custom_switch.dart';
import 'package:teki_app/src/presentation/widgets/text_field/text_field_section.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/print_coffe_service.dart';
import 'package:teki_app/src/utils/notifications.dart';

// ─── Entrada de pago individual ──────────────────────────────────────────────

class _PaymentEntry {
  final PaymentMethod method;
  final TextEditingController amountController;
  final TextEditingController operationController;

  _PaymentEntry({required this.method, required double initialAmount})
      : amountController =
            TextEditingController(text: initialAmount.toStringAsFixed(2)),
        operationController = TextEditingController();

  _PaymentEntry.fromExisting({
    required this.method,
    required String amount,
    required String operation,
  })  : amountController = TextEditingController(text: amount),
        operationController = TextEditingController(text: operation);

  void dispose() {
    amountController.dispose();
    operationController.dispose();
  }
}

// ─── Widget principal ─────────────────────────────────────────────────────────

class PaymentWidget extends ConsumerStatefulWidget {
  const PaymentWidget({super.key});

  @override
  ConsumerState<PaymentWidget> createState() => _PaymentWidgetState();
}

class _PaymentWidgetState extends ConsumerState<PaymentWidget>
    with SingleTickerProviderStateMixin {
  final ComprobantePrintService _printService = ComprobantePrintService();

  late TabController _tabController;
  List<PaymentMethod> paymentMethods = [];
  final List<_PaymentEntry> _paymentEntries = [];

  TextEditingController diasCredito = TextEditingController();
  List<TextEditingController> fechaCredito = [];
  List<TextEditingController> montoCredito = [];

  double total = 0;
  String currency = '';

  final formKeyCredito = GlobalKey<FormState>();

  double get _totalPaid => _paymentEntries.fold(
      0.0, (sum, e) => sum + (double.tryParse(e.amountController.text) ?? 0.0));

  double get _remaining => (total - _totalPaid).clamp(0.0, double.infinity);

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
        _paymentEntries.add(_PaymentEntry.fromExisting(
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
          text: DateFormat('yyyy-MM-dd')
              .format(cuota.fecha ?? DateTime.now()),
        ));
        montoCredito.add(TextEditingController(
          text: (cuota.monto ?? 0).toStringAsFixed(2),
        ));
      }
      _tabController.index = 1;
    }

    if (ticket.movimientoCaja == null &&
        (ticket.cuotas?.isEmpty ?? true)) {
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
      _paymentEntries.add(_PaymentEntry(method: method, initialAmount: _remaining));
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
      fechaBase = DateTime.parse(fechaCredito.last.text)
          .add(Duration(days: dias));
    } else {
      fechaBase = DateTime.now().add(Duration(days: dias));
    }
    fechaCredito.add(TextEditingController(
      text: DateFormat('yyyy-MM-dd').format(fechaBase),
    ));
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
    final montoEquitativo =
        total / (montoCredito.isNotEmpty ? montoCredito.length : 1);
    for (var c in montoCredito) {
      c.text = montoEquitativo.toStringAsFixed(2);
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
      builder: (context, child) {
        return Theme(
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
        );
      },
    );
    if (picked != null) {
      fechaCredito[index].text = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {});
    }
  }

  void procesoCredito() {
    final provider = ref.read(ticketProvider.notifier);
    final List<TicketFee> cuotas = [];
    for (int i = 0; i < fechaCredito.length; i++) {
      final fecha = fechaCredito[i].text;
      final monto = montoCredito[i].text;
      if (fecha.isNotEmpty && monto.isNotEmpty) {
        cuotas.add(TicketFee(
          fecha: DateTime.parse(fecha),
          monto: double.tryParse(monto) ?? 0.0,
        ));
      }
    }
    if (cuotas.isEmpty) {
      errorNotification("Debe agregar al menos una cuota");
      return;
    }
    if (cuotas.any((c) => c.monto! <= 0)) {
      errorNotification(
          "Todos los montos de las cuotas deben ser mayores a cero");
      return;
    }
    provider.setCuotas(cuotas);
  }

  void procesoContado() {
    final provider = ref.read(ticketProvider.notifier);
    final pagos = _paymentEntries
        .where((e) => (double.tryParse(e.amountController.text) ?? 0.0) > 0)
        .map((e) {
      final amount = double.tryParse(e.amountController.text) ?? 0.0;
      return PaymentDetail(
        formaPago: e.method.formaPago,
        monto: amount,
        montoPagado: amount,
        metodoPago: e.method,
        numeroOperacion: e.operationController.text.isNotEmpty
            ? e.operationController.text
            : null,
        nombre: e.method.nombre,
        tipoTarjeta: e.method.tipoTarjeta,
      );
    }).toList();

    final cambio = (_totalPaid - total).clamp(0.0, double.infinity);
    provider.setMovimientoCaja(
      total: total,
      pagos: pagos,
      cambio: cambio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final visiblePaymentMethods = getFilteredPaymentMethods();
    final ticket = ref.watch(ticketProvider).ticket;
    final notifier = ref.read(ticketProvider.notifier);
    final ticketP = ref.watch(ticketProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Pago', style: TextStyle(fontSize: 17)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: "Contado"),
            Tab(text: "Crédito"),
          ],
        ),
      ),
      body: Column(
        children: [
          // ── Switch Agrupar ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: CustomSwitch(
              small: true,
              title: "Agrupar ítems",
              rightAlign: false,
              border: false,
              value: ticket.agruparItems ?? false,
              onChanged: notifier.setAgruparItems,
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Expanded(
            child: IndexedStack(
              index: _tabController.index,
              children: [
                // ── Tab Contado ─────────────────────────────────────────────
                Column(
                  children: [
                    // Lista de pagos seleccionados
                    if (_paymentEntries.isNotEmpty) ...[
                      ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        itemCount: _paymentEntries.length,
                        itemBuilder: (_, i) => _buildPaymentEntryRow(i),
                      ),
                      Divider(height: 1, color: Colors.grey.shade200),
                    ],
                    // Grid de métodos disponibles
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                        itemCount: visiblePaymentMethods.length,
                        itemBuilder: (_, index) {
                          final payment = visiblePaymentMethods[index];
                          final isSelected = _paymentEntries
                              .any((e) => e.method.id == payment.id);
                          return _PaymentMethodRow(
                            method: payment,
                            isSelected: isSelected,
                            onTap: () => _addPayment(payment),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                  // ── Tab Crédito ───────────────────────────────────────────
                  Form(
                    key: formKeyCredito,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 15),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFieldSection(
                                    label: 'Días de crédito (*)',
                                    hint: 'Ingrese días',
                                    inputType: TextInputType.text,
                                    controller: diasCredito,
                                    onChanged: (_) {},
                                    validator: (p0) =>
                                        (p0 == null || p0.isEmpty)
                                            ? 'Ingrese un número válido'
                                            : (int.tryParse(p0) == null ||
                                                    int.parse(p0) <= 0)
                                                ? 'Debe ser mayor a cero'
                                                : null,
                                  ),
                                ),
                                IconButton(
                                  onPressed: addCuota,
                                  icon: const Icon(Icons.add_circle,
                                      color: ColorSchema.primaryColor),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "------ Cuotas de crédito ------",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: ColorSchema.primaryColor,
                            ),
                          ),
                          ...List.generate(fechaCredito.length, (index) {
                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: GestureDetector(
                                      onTap: () => _selectDate(index),
                                      child: AbsorbPointer(
                                        child: TextFieldSection(
                                          label: 'Fecha',
                                          hint: 'Seleccione fecha',
                                          inputType: TextInputType.text,
                                          controller: fechaCredito[index],
                                          isReadOnly: true,
                                          onChanged: (_) {},
                                          validator: (p0) =>
                                              (p0 == null || p0.isEmpty)
                                                  ? 'Seleccione una fecha'
                                                  : null,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    flex: 2,
                                    child: TextFieldSection(
                                      label: 'Monto cuota',
                                      hint: 'Monto',
                                      controller: montoCredito[index],
                                      inputType: TextInputType.number,
                                      validator: (p0) =>
                                          (p0 == null || p0.isEmpty)
                                              ? 'Monto requerido'
                                              : (double.tryParse(p0) ==
                                                          null ||
                                                      double.parse(p0) <= 0)
                                                  ? 'Monto invalido'
                                                  : null,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle,
                                        color: Colors.red),
                                    onPressed: () => eliminarCuota(index),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SummaryBarSales(showOnlyTotal: true),
            ),
            // ── Botón finalizar ───────────────────────────────────────────────
            SafeArea(
              top: false,
              child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                    onPressed: () async {
                      final notifier = ref.read(ticketProvider.notifier);
                      final isContado = _tabController.index == 0;

                      if (isContado) {
                        if (_paymentEntries.isEmpty) {
                          errorNotification(
                              "Debe seleccionar al menos un método de pago");
                          return;
                        }
                        if (_totalPaid < total - 0.009) {
                          errorNotification(
                              "El monto pagado es menor al total de la venta");
                          return;
                        }
                        procesoContado();
                      } else {
                        final isValid =
                            formKeyCredito.currentState?.validate() ?? false;
                        if (!isValid) return;
                        procesoCredito();
                      }

                      final ticketState = ref.read(ticketProvider);
                      final checkId = ticketState.ticket.cuentaRestaurante;

                      if (checkId != null) {
                        final ticketPayload = notifier.getTicketPayload();
                        final customer =
                            ref.read(customerSaleProvider).customer;
                        final originalItems = ref
                            .read(productSaleProvider)
                            .productsSales
                            .map((td) => td.comandaDetalle)
                            .whereType<CommandDetail>()
                            .toList();
                        final checkPayload = Check(
                          cliente:
                              (customer.razonSocial?.isNotEmpty ?? false)
                                  ? customer
                                  : null,
                          pagado: true,
                          items: originalItems,
                          comprobante: ticketPayload,
                        );
                        try {
                          final checkResult =
                              await RestaurantRepositoryImpl()
                                  .updateCheck(checkId, checkPayload);
                          ref.invalidate(ticketProvider);
                          ref.invalidate(productSaleProvider);
                          ref.invalidate(customerSaleProvider);
                          final comprobante = checkResult.comprobante;
                          if (comprobante != null) {
                            _autoprint(comprobante);
                            Get.off(() => ViewComponentScreen(
                                  ticket: comprobante,
                                  fromSale: true,
                                ));
                          } else {
                            Get.back();
                          }
                        } catch (e) {
                          errorNotification(
                              "Error al registrar el pago: $e");
                        }
                      } else {
                        final Ticket? ticketResponse =
                            await notifier.proceessTicket();
                        if (ticketResponse != null) {
                          ref.invalidate(ticketProvider);
                          ref.invalidate(productSaleProvider);
                          ref.invalidate(customerSaleProvider);
                          _autoprint(ticketResponse);
                          Get.off(() => ViewComponentScreen(
                                ticket: ticketResponse,
                                fromSale: true,
                              ));
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorSchema.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(ticketP.isEdit
                            ? 'Finalizar Edición'
                            : 'Finalizar Pago'),
                        const SizedBox(width: 8),
                        const Icon(Icons.check_circle),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
            ),
          ],
        ),
    );
  }

  Widget _buildPaymentEntryRow(int index) {
    final entry = _paymentEntries[index];
    final isCash =
        (entry.method.formaPago ?? '').toUpperCase() == 'EFECTIVO';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Campo monto con nombre del método como label
          Expanded(
            flex: 2,
            child: TextFieldSection(
              label: entry.method.nombre ?? 'Monto',
              hint: '0.00',
              inputType: TextInputType.number,
              controller: entry.amountController,
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Campo # operación (solo tarjetas)
          if (!isCash) ...[
            const SizedBox(width: 6),
            Expanded(
              flex: 2,
              child: TextFieldSection(
                label: '# Op.',
                hint: 'Número',
                inputType: TextInputType.number,
                controller: entry.operationController,
              ),
            ),
          ],
          // Botón eliminar
          IconButton(
            onPressed: () => _removePayment(index),
            icon: const Icon(Icons.delete_outline_rounded,
                color: Colors.redAccent, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─── Fila de método de pago ───────────────────────────────────────────────────

class _PaymentMethodRow extends StatelessWidget {
  final PaymentMethod method;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentMethodRow({
    required this.method,
    required this.isSelected,
    required this.onTap,
  });

  Widget _buildIcon() {
    const double size = 32;
    final url = method.imagenUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.contain,
        errorBuilder: (context, e, stack) => _buildFallbackIcon(size),
      );
    }
    return _buildFallbackIcon(size);
  }

  Widget _buildFallbackIcon(double size) {
    final isCash = (method.formaPago ?? '').toUpperCase() == 'EFECTIVO';
    return Icon(
      isCash ? Icons.payments_rounded : Icons.credit_card_rounded,
      color: isSelected ? ColorSchema.primaryColor : Colors.grey.shade500,
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? ColorSchema.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? ColorSchema.primaryColor
                : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Ícono / imagen
            SizedBox(width: 36, child: Center(child: _buildIcon())),
            const SizedBox(width: 14),
            // Nombre
            Expanded(
              child: Text(
                method.nombre ?? '',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? ColorSchema.primaryColor
                      : Colors.grey.shade800,
                ),
              ),
            ),
            // Checkmark
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: isSelected
                  ? Container(
                      key: const ValueKey('check'),
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: ColorSchema.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    )
                  : const SizedBox(key: ValueKey('empty'), width: 24),
            ),
          ],
        ),
      ),
    );
  }
}
