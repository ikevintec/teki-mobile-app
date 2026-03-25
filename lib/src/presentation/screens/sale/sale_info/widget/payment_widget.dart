import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/commandDetail.dart';
import 'package:teki_app/src/data/models/teki_model/paymentMethod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/ticketFee.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen.dart/view_comprobante_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/sale_info/widget/payment_card_widget.dart';
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
  PaymentMethod? selectedPaymentMethod;
  TextEditingController montoPagadoController = TextEditingController();
  TextEditingController numeroOperacion = TextEditingController();
  TextEditingController diasCredito = TextEditingController();
  List<TextEditingController> fechaCredito = [];
  List<TextEditingController> montoCredito = [];

  int selectedPaymentId = -1;
  double total = 0;
  String currency = '';

  final formKeyContado = GlobalKey<FormState>();
  final formKeyCredito = GlobalKey<FormState>();
  
  // FocusNodes para detectar cuando hay inputs enfocados
  final FocusNode montoPagadoFocus = FocusNode();
  final FocusNode numeroOperacionFocus = FocusNode();
  final FocusNode diasCreditoFocus = FocusNode();
  bool _hasInputFocus = false;
  Timer? _expandTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    
    // Agregar listeners a los FocusNodes
    montoPagadoFocus.addListener(_onFocusChange);
    numeroOperacionFocus.addListener(_onFocusChange);
    diasCreditoFocus.addListener(_onFocusChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerTicket = ref.watch(ticketProvider);
      final ticket = providerTicket.ticket;
      final isEdit = providerTicket.isEdit;
      
      total = double.parse(
          (ticket.totalVenta ?? 0).toStringAsFixed(2));
      montoPagadoController.text = total.toStringAsFixed(2);
      currency = ticket.codigoMoneda ?? 'PEN';
      final sesion = ref.read(sesionProvider);
      paymentMethods = sesion.config?.formasPago ?? [];
      
      // Si es edición, cargar datos existentes
      if (isEdit) {
        _loadExistingPaymentData(ticket);
      } else {
        // Valores por defecto para nueva venta
        diasCredito.text = "30";
      }
      
      setState(() {});
    });
  }

  @override
  void dispose() {
    _expandTimer?.cancel();
    montoPagadoFocus.removeListener(_onFocusChange);
    numeroOperacionFocus.removeListener(_onFocusChange);
    diasCreditoFocus.removeListener(_onFocusChange);
    
    montoPagadoFocus.dispose();
    numeroOperacionFocus.dispose();
    diasCreditoFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    final hasAnyFocus = montoPagadoFocus.hasFocus || 
                       numeroOperacionFocus.hasFocus || 
                       diasCreditoFocus.hasFocus;
    
    if (_hasInputFocus != hasAnyFocus) {
      if (hasAnyFocus) {
        // Si gana focus, cambiar inmediatamente (contraer)
        _expandTimer?.cancel();
        setState(() {
          _hasInputFocus = true;
        });
      } else {
        // Si pierde focus, esperar antes de expandir
        _expandTimer?.cancel();
        _expandTimer = Timer(const Duration(milliseconds: 150), () {
          if (mounted) {
            setState(() {
              _hasInputFocus = false;
            });
          }
        });
      }
    }
  }

  double get cambioDisponible =>
      (double.tryParse(montoPagadoController.text) ?? 0) - total;

  void _autoprint(Ticket ticket) {
    if (ticket.id == null || ticket.uuid == null || ticket.identificadorDocumento == null) return;

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
    // Cargar datos de pago al contado si existe movimientoCaja
    if (ticket.movimientoCaja != null && ticket.movimientoCaja!.pagos != null && ticket.movimientoCaja!.pagos!.isNotEmpty) {
      final pago = ticket.movimientoCaja!.pagos!.first;
      
      // Buscar el método de pago correspondiente
      selectedPaymentMethod = paymentMethods.firstWhere(
        (p) => p.id == pago.metodoPago?.id,
        orElse: () => pago.metodoPago ?? PaymentMethod(),
      );
      
      if (selectedPaymentMethod != null) {
        selectedPaymentId = selectedPaymentMethod!.id ?? -1;
        montoPagadoController.text = (pago.montoPagado ?? pago.monto ?? 0).toStringAsFixed(2);
        numeroOperacion.text = pago.numeroOperacion ?? '';
      }
      
      // Mantener en tab de contado
      _tabController.index = 0;
    }
    
    // Cargar datos de crédito si existen cuotas
    if (ticket.cuotas != null && ticket.cuotas!.isNotEmpty) {
      diasCredito.text = (ticket.diasCredito ?? 0).toString();
      
      // Cargar cuotas existentes
      fechaCredito.clear();
      montoCredito.clear();
      
      for (var cuota in ticket.cuotas!) {
        fechaCredito.add(TextEditingController(
          text: DateFormat('yyyy-MM-dd').format(cuota.fecha ?? DateTime.now())
        ));
        montoCredito.add(TextEditingController(
          text: (cuota.monto ?? 0).toStringAsFixed(2)
        ));
      }
      
      // Cambiar a tab de crédito
      _tabController.index = 1;
    }
    
    // Si no hay ningún dato de pago, establecer valores por defecto
    if (ticket.movimientoCaja == null && (ticket.cuotas == null || ticket.cuotas!.isEmpty)) {
      diasCredito.text = (ticket.diasCredito ?? 30).toString();
    }
  }

  List<PaymentMethod> getFilteredPaymentMethods() {
    final efectivo = paymentMethods.firstWhere(
      (p) => (p.formaPago ?? '').toUpperCase() == 'EFECTIVO',
      orElse: () => PaymentMethod(),
    );

    final filtered = paymentMethods.where(
      (p) =>
          (p.tipoMovimiento ?? '').toLowerCase() == 'ingreso' &&
          (p.tipoTarjeta != null),
    );

    final Map<int, PaymentMethod> uniqueMap = {};
    if (efectivo.id != null) uniqueMap[efectivo.id!] = efectivo;
    for (var p in filtered) {
      if (!uniqueMap.containsKey(p.id)) uniqueMap[p.id!] = p;
    }
    return uniqueMap.values.toList();
  }

  void addCuota() {
    final dias = int.tryParse(diasCredito.text) ?? 0;

    // Obtener la fecha base: última fecha o fecha actual
    DateTime fechaBase;
    if (fechaCredito.isNotEmpty) {
      // Tomar la última fecha existente y sumarle los días
      fechaBase =
          DateTime.parse(fechaCredito.last.text).add(Duration(days: dias));
    } else {
      // No hay cuotas aún, partir desde hoy
      fechaBase = DateTime.now().add(Duration(days: dias));
    }

    // Insertar al final
    fechaCredito.add(
      TextEditingController(text: DateFormat('yyyy-MM-dd').format(fechaBase)),
    );
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
    for (var controller in montoCredito) {
      controller.text = montoEquitativo.toStringAsFixed(2);
    }
    setState(() {});
  }

  Future<void> _selectDate(int index) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    DateTime? picked = await showDatePicker(
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
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
              ),
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
    List<TicketFee> cuotas = [];
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
    if (cuotas.any((c) => c.fecha == null)) {
      errorNotification("Todas las fechas de las cuotas deben ser válidas");
      return;
    }
    provider.setCuotas(cuotas);
  }

  void procesoContado() {
    final provider = ref.read(ticketProvider.notifier);
    provider.setMovimientoCaja(
      total: total,
      pagado: montoPagadoController.text,
      cambio: cambioDisponible.toStringAsFixed(2),
      numOperacion: numeroOperacion.text,
      metodoPago: selectedPaymentMethod ?? PaymentMethod(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final visiblePaymentMethods = getFilteredPaymentMethods();
    final ticket = ref.watch(ticketProvider).ticket;
    final notifier = ref.read(ticketProvider.notifier);
    final ticketP = ref.watch(ticketProvider);
    
    // Usar detección de focus en lugar de teclado
    final containerHeight = _hasInputFocus ? size.height * 0.5 : size.height * 0.7;
    
    return Center(
      child: Container(
        width: size.width * 1,
        height: containerHeight,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomSwitch(
                  small: true,
                  title: "   Agrupar",
                  rightAlign: true,
                  border: false,
                  value: ticket.agruparItems ?? false,
                  onChanged: notifier.setAgruparItems,
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    alignment: Alignment.bottomRight,
                    child: Icon(Icons.close, color: ColorSchema.primaryColor),
                  ),
                ),
              ],
            ),
            TabBar(
              controller: _tabController,
              labelColor: ColorSchema.primaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: ColorSchema.primaryColor,
              tabs: const [
                Tab(text: "Contado"),
                Tab(text: "Crédito"),
              ],
            ),
            if (selectedPaymentId != -1 && _tabController.index == 0)
              SizedBox(height: 25),
            Expanded(
              child: IndexedStack(
                index: _tabController.index,
                children: [
                  Form(
                    key: formKeyContado,
                    child: Column(
                      children: [
                        if (selectedPaymentId != -1 &&
                            _tabController.index == 0)
                          Row(
                            children: [
                              Expanded(
                                flex: (selectedPaymentMethod?.formaPago !=
                                        'EFECTIVO')
                                    ? 1
                                    : 2,
                                child: TextFieldSection(
                                  borderColor:
                                      ColorSchema.primaryColor.withOpacity(0.8),
                                  label:
                                      "${selectedPaymentMethod?.formaPago == 'EFECTIVO' ? selectedPaymentMethod?.formaPago : selectedPaymentMethod?.nombre} (*)",
                                  hint: 'Cantidad pagado',
                                  inputType: TextInputType.number,
                                  controller: montoPagadoController,
                                  focusNode: montoPagadoFocus,
                                  onChanged: (value) => setState(() {}),
                                  validator: (p0) {
                                    if (p0 == null || p0.isEmpty) {
                                      return 'Monto requerido';
                                    }
                                    final value = double.tryParse(p0);
                                    if (value == null || value < 0) {
                                      return 'Monto invalido';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              if (selectedPaymentMethod?.formaPago !=
                                  'EFECTIVO') ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 1,
                                  child: TextFieldSection(
                                    borderColor: ColorSchema.primaryColor
                                        .withOpacity(0.8),
                                    label: "# Operación",
                                    hint: 'Número de operación',
                                    inputType: TextInputType.number,
                                    controller: numeroOperacion,
                                    focusNode: numeroOperacionFocus,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        SizedBox(height: 10),
                        Expanded(
                          child: GridView.builder(
                            padding:
                                const EdgeInsets.only(top: 12.0, bottom: 16.0),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                            itemCount: visiblePaymentMethods.length,
                            itemBuilder: (context, index) {
                              final payment = visiblePaymentMethods[index];
                              final isSelected =
                                  selectedPaymentId == payment.id;
                              return PaymentCardWidget(
                                paymentMethod: payment,
                                isSelecelted: isSelected,
                                onTap: () => setState(() {
                                  selectedPaymentId = payment.id ?? -1;
                                  selectedPaymentMethod = payment;
                                }),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Form(
                    key: formKeyCredito,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 0, vertical: 15),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextFieldSection(
                                    label: 'Días de crédito (*)',
                                    hint: 'Ingrese días',
                                    inputType: TextInputType.text,
                                    controller: diasCredito,
                                    focusNode: diasCreditoFocus,
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
                                  icon: Icon(Icons.add_circle,
                                      color: ColorSchema.primaryColor),
                                ),
                              ],
                            ),
                          ),
                          Text("------ Cuotas de crédito ------",
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: ColorSchema.primaryColor)),
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
                                  SizedBox(width: 12),
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
                                              : (double.tryParse(p0) == null ||
                                                      double.parse(p0) <= 0)
                                                  ? 'Monto invalido'
                                                  : null,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.remove_circle,
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
                  )
                ],
              ),
            ),
            SummaryBarSales(showOnlyTotal: true,),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      final notifier = ref.read(ticketProvider.notifier);
                      final isContado = _tabController.index == 0;
                      if (isContado && selectedPaymentMethod == null) {
                        errorNotification("Debe seleccionar un método de pago");
                        return;
                      }
                      final isValid = isContado
                          ? (formKeyContado.currentState?.validate() ?? false)
                          : (formKeyCredito.currentState?.validate() ?? false);
                      if (!isValid) return;

                      if (isContado) {
                        procesoContado();
                      } else {
                        procesoCredito();
                      }

                      final ticketState = ref.read(ticketProvider);
                      final checkId = ticketState.ticket.cuentaRestaurante;

                      if (checkId != null) {
                        // ── Flujo cobrador: PUT /checks/{id} ──────────────────
                        final ticketPayload = notifier.getTicketPayload();
                        final customer = ref.read(customerSaleProvider).customer;
                        final originalItems = ref
                            .read(productSaleProvider)
                            .productsSales
                            .map((td) => td.comandaDetalle)
                            .whereType<CommandDetail>()
                            .toList();
                        final checkPayload = Check(
                          cliente: (customer.razonSocial?.isNotEmpty ?? false)
                              ? customer
                              : null,
                          pagado: true,
                          items: originalItems,
                          comprobante: ticketPayload,
                        );
                        try {
                          final checkResult = await RestaurantRepositoryImpl()
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
                          errorNotification("Error al registrar el pago: $e");
                        }
                      } else {
                        // ── Flujo normal: POST /tickets ───────────────────────
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
                        Text( ticketP.isEdit ? 'Finalizar Edición' : 'Finalizar Pago'),
                        SizedBox(width: 8),
                        Icon(Icons.check_circle),
                      ],
                    ),
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
