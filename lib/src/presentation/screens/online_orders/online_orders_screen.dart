import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/data/repositories/restaurant_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/online_orders/widgets/online_order_detail_widget.dart';
import 'package:teki_app/src/presentation/screens/online_orders/widgets/online_order_confirm_dialog.dart';
import 'package:teki_app/src/presentation/screens/online_orders/widgets/order_action_button.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/comanda_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/order_detail_dialog.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/online_orders/online_orders_provider.dart';
import 'package:teki_app/src/providers/online_orders/online_orders_state.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/shared/services/online_order_workflow_service.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/whatsapp_helper.dart';
import 'package:url_launcher/url_launcher.dart';

class OnlineOrdersScreen extends ConsumerStatefulWidget {
  final int? initialOrderId;

  const OnlineOrdersScreen({super.key, this.initialOrderId});

  @override
  ConsumerState<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends ConsumerState<OnlineOrdersScreen> {
  final _scrollController = ScrollController();
  final _customerController = TextEditingController();
  Timer? _searchDebounce;
  int? _restaurantOrderLoadingId;
  int? _workflowLoadingOrderId;
  final _restaurantRepository = RestaurantRepositoryImpl();

  bool get _canAccess {
    final session = ref.read(sesionProvider);
    return session.hasPermission('SUPER_USUARIO') ||
        session.hasPermission('CATALOGO_VER') ||
        session.hasPermission('MENU_CLIENTE_VER');
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_canAccess) {
        final notifier = ref.read(onlineOrdersProvider.notifier);
        await notifier.loadFirstPage();
        if (!mounted) return;
        final orderId = widget.initialOrderId;
        if (orderId != null) {
          await _openDetail(OnlineOrder(id: orderId));
        }
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _customerController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 220) {
      ref.read(onlineOrdersProvider.notifier).loadMore();
    }
  }

  void _onCustomerChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final state = ref.read(onlineOrdersProvider);
      ref
          .read(onlineOrdersProvider.notifier)
          .applyFilters(
            tipo: state.tipo,
            estado: state.estado,
            cliente: value,
            numeroPedido: state.numeroPedido,
          );
    });
  }

  Future<void> _openFilters() async {
    final current = ref.read(onlineOrdersProvider);
    String? tipo = current.tipo;
    String? estado = current.estado;
    final numberController = TextEditingController(text: current.numeroPedido);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).viewInsets.bottom + 18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Filtrar pedidos',
                style: GoogleFonts.raleway(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              DropdownButtonFormField<String?>(
                initialValue: tipo,
                decoration: _filterDecoration('Origen'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(value: 'CATALOGO', child: Text('Catálogo')),
                  DropdownMenuItem(value: 'MENU', child: Text('Menú')),
                ],
                onChanged: (value) => setModalState(() => tipo = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: estado,
                decoration: _filterDecoration('Estado'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Todos')),
                  DropdownMenuItem(
                    value: 'PENDIENTE',
                    child: Text('Pendiente'),
                  ),
                  DropdownMenuItem(value: 'ACEPTADO', child: Text('Aceptado')),
                  DropdownMenuItem(value: 'ATENDIDO', child: Text('Atendido')),
                  DropdownMenuItem(value: 'ANULADO', child: Text('Anulado')),
                  DropdownMenuItem(
                    value: 'FINALIZADO',
                    child: Text('Finalizado'),
                  ),
                ],
                onChanged: (value) => setModalState(() => estado = value),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: numberController,
                keyboardType: TextInputType.number,
                decoration: _filterDecoration(
                  'Número de pedido',
                ).copyWith(prefixIcon: const Icon(Icons.tag_rounded)),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _customerController.clear();
                        ref.read(onlineOrdersProvider.notifier).applyFilters();
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.filter_alt_off_outlined, size: 18),
                      label: const Text('Limpiar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF64748B),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ref
                            .read(onlineOrdersProvider.notifier)
                            .applyFilters(
                              tipo: tipo,
                              estado: estado,
                              cliente: _customerController.text,
                              numeroPedido: numberController.text,
                            );
                        Navigator.pop(sheetContext);
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Aplicar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorSchema.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    numberController.dispose();
  }

  InputDecoration _filterDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: const Color(0xFFF8FAFC),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
  );

  Future<void> _openDetail(OnlineOrder summary) async {
    final id = summary.id;
    if (id == null) return;
    final order = await ref.read(onlineOrdersProvider.notifier).loadDetail(id);
    if (!mounted) return;
    if (order == null) {
      errorNotification('No se pudo cargar el detalle del pedido');
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF8FAFC),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, sheetScrollController) => Consumer(
          builder: (context, ref, child) {
            final state = ref.watch(onlineOrdersProvider);
            final selected = state.selectedOrder ?? order;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: sheetScrollController,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: OnlineOrderDetailWidget(order: selected),
                  ),
                ),
                OnlineOrderDetailActions(
                  order: selected,
                  actionLoading: state.actionOrderId == selected.id,
                  onAccept: selected.estado == 'PENDIENTE'
                      ? () => _updateStatus(selected, 'ACEPTADO')
                      : null,
                  onCancel: _canCancel(selected)
                      ? () => _confirmCancel(selected)
                      : null,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmCancel(OnlineOrder order) async {
    final confirmed = await showOnlineOrderConfirmDialog(
      context,
      icon: Icons.cancel_outlined,
      title: 'Anular pedido',
      orderLabel:
          'Pedido #${formatOrderNumber(order.numeroPedido ?? order.id)}',
      message: '¿Desea anular este pedido?',
      confirmLabel: 'Sí, anular',
      confirmIcon: Icons.block_rounded,
      kind: OrderActionKind.danger,
    );
    if (confirmed) await _updateStatus(order, 'ANULADO');
  }

  Future<void> _updateStatus(OnlineOrder order, String status) async {
    final accepted = status == 'ACEPTADO';
    final OnlineOrder updated;
    try {
      updated = await ref
          .read(onlineOrdersProvider.notifier)
          .changeStatus(order, status);
    } catch (error) {
      if (!mounted) return;
      errorNotification(
        error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        fromTop: false,
      );
      return;
    }
    if (!mounted) return;
    successNotification(
      accepted ? 'Pedido aceptado' : 'Pedido anulado',
      fromTop: false,
    );
    final notify = await _confirmNotifyCustomer(updated, accepted);
    if (!notify || !mounted) return;
    final result = await ref
        .read(onlineOrdersProvider.notifier)
        .notifyCustomer(updated, status);
    if (!mounted) return;
    final message = result.message;
    if (message?.isNotEmpty == true) {
      if (result.success) {
        infoNotification(message!, fromTop: false);
      } else {
        warningNotification(message!, fromTop: false);
      }
    }
  }

  Future<bool> _confirmNotifyCustomer(OnlineOrder order, bool accepted) {
    final customer = order.nombreCliente?.trim();
    return showOnlineOrderConfirmDialog(
      context,
      icon: Icons.chat_rounded,
      title: 'Avisar al cliente',
      orderLabel:
          'Pedido #${formatOrderNumber(order.numeroPedido ?? order.id)}',
      message:
          '¿Desea avisarle a ${customer?.isNotEmpty == true ? customer : 'su cliente'} '
          'por WhatsApp que su pedido fue ${accepted ? 'aceptado' : 'anulado'}?',
      confirmLabel: 'Sí, avisar',
      confirmIcon: Icons.send_rounded,
    );
  }

  bool _canCancel(OnlineOrder order) =>
      !const ['ANULADO', 'ATENDIDO', 'FINALIZADO'].contains(order.estado);

  String? _comprobantePdfUrl(OnlineOrder order) {
    final ticket = order.comprobante;
    if (ticket == null ||
        ticket.uuid?.trim().isNotEmpty != true ||
        ticket.identificadorDocumento?.trim().isNotEmpty != true) {
      return null;
    }
    return WhatsappHelper.getUrlPdf(ticket, 'A4');
  }

  Future<void> _openExternalPdf(String url, String fileName) async {
    try {
      final opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        errorNotification('No se pudo abrir el archivo de $fileName');
      }
    } catch (_) {
      errorNotification('No se pudo abrir el archivo de $fileName');
    }
  }

  Future<void> _openRestaurantOrder(OnlineOrder onlineOrder) async {
    final orderId = onlineOrder.idOrderRestaurant;
    if (orderId == null || _restaurantOrderLoadingId != null) return;

    setState(() => _restaurantOrderLoadingId = orderId);
    try {
      final order = await RestaurantRepositoryImpl().getOrderById(orderId);
      if (!mounted) return;
      showOrderDetailDialog(context, order, readOnly: true);
    } catch (error) {
      if (!mounted) return;
      errorNotification(
        error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        fromTop: false,
      );
    } finally {
      if (mounted) {
        setState(() => _restaurantOrderLoadingId = null);
      }
    }
  }

  bool get _canCreateSales =>
      ref.read(sesionProvider).hasPermission('VENTAS_CREAR');

  Future<void> _generateCatalogSale(OnlineOrder order) async {
    final id = order.id;
    if (id == null || _workflowLoadingOrderId != null) return;
    if (!_canCreateSales) {
      warningNotification('No tiene permiso para generar ventas.');
      return;
    }
    setState(() => _workflowLoadingOrderId = id);
    try {
      final draft = await ref
          .read(onlineOrderRepositoryProvider)
          .getSaleDraft(id);
      await ref.read(productSaleProvider.notifier).initFromTicketDraft(draft);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductsSaleScreen()),
      );
      await ref.read(onlineOrdersProvider.notifier).refresh();
    } catch (error) {
      if (mounted) _showWorkflowError(error);
    } finally {
      if (mounted) setState(() => _workflowLoadingOrderId = null);
    }
  }

  Future<void> _editCommand(OnlineOrder order) async {
    final id = order.id;
    if (id == null || _workflowLoadingOrderId != null) return;
    setState(() => _workflowLoadingOrderId = id);
    try {
      final created = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (_) => ComandaScreen(
            isPedidoSinMesa: true,
            onlineOrderId: id,
            onlineOrderNumber: order.numeroPedido ?? id,
          ),
        ),
      );
      if (created == true) {
        await ref.read(onlineOrdersProvider.notifier).refresh();
      }
    } finally {
      if (mounted) setState(() => _workflowLoadingOrderId = null);
    }
  }

  Future<void> _invoiceMenuOrder(OnlineOrder onlineOrder) async {
    final id = onlineOrder.id;
    if (id == null || _workflowLoadingOrderId != null) return;
    if (!_canCreateSales) {
      warningNotification('No tiene permiso para generar comprobantes.');
      return;
    }
    final session = ref.read(sesionProvider);
    final office = session.office;
    if (office == null) {
      warningNotification('Debe seleccionar un punto de venta.');
      return;
    }
    setState(() => _workflowLoadingOrderId = id);
    try {
      final restaurantOrder = onlineOrder.idOrderRestaurant != null
          ? await _restaurantRepository.getOrderById(
              onlineOrder.idOrderRestaurant!,
            )
          : await OnlineOrderWorkflowService().createDirectOrder(
              id,
              office,
              session.config,
            );
      if (onlineOrder.idOrderRestaurant == null &&
          session.config?.imprimirPedidoComandaSinComprobante == true) {
        final commandId = restaurantOrder.comandas?.firstOrNull?.id;
        if (commandId != null) {
          await CommandPrintService().processCommand(
            commandId: commandId,
            puntoVenta: office,
            escPos: session.config?.imprimeTicketsEscPos ?? false,
            clientPrinter: session.config?.clienteImpresion,
            idCompany: session.company?.id,
          );
        }
      }
      final account = restaurantOrder.cuentas
          ?.where((check) => check.pagado != true)
          .firstOrNull;
      if (account?.id == null) {
        throw StateError(
          'La orden no tiene una cuenta pendiente para facturar.',
        );
      }
      final fullCheck = await _restaurantRepository.getCheckById(account!.id!);
      await ref.read(productSaleProvider.notifier).initFromCheck(fullCheck);
      // Solo para mostrar el número en el flujo de venta: el backend vincula
      // el pedido online desde la cuenta (CheckServiceImpl).
      final ticketNotifier = ref.read(ticketProvider.notifier);
      ticketNotifier.updateTicket(
        ref
            .read(ticketProvider)
            .ticket
            .copyWith(numeroPedidoOnline: onlineOrder.numeroPedido ?? id),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductsSaleScreen()),
      );
      await ref.read(onlineOrdersProvider.notifier).refresh();
    } catch (error) {
      if (mounted) _showWorkflowError(error);
    } finally {
      if (mounted) setState(() => _workflowLoadingOrderId = null);
    }
  }

  void _showWorkflowError(Object error) {
    errorNotification(
      error
          .toString()
          .replaceFirst(RegExp(r'^Exception:\s*'), '')
          .replaceFirst('Bad state: ', ''),
      fromTop: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineOrdersProvider);
    final session = ref.watch(sesionProvider);
    final canAccess =
        session.hasPermission('SUPER_USUARIO') ||
        session.hasPermission('CATALOGO_VER') ||
        session.hasPermission('MENU_CLIENTE_VER');

    return Scaffold(
      backgroundColor: const Color(0xFFEBEEF5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: 'Pedidos online',
          actions: [
            IconButton(
              tooltip: 'Recargar',
              onPressed: state.isLoading || state.isRefreshing
                  ? null
                  : () => ref.read(onlineOrdersProvider.notifier).refresh(),
              icon: state.isRefreshing
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
            ),
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  tooltip: 'Filtros',
                  onPressed: _openFilters,
                  icon: const Icon(
                    Icons.filter_alt_outlined,
                    color: Colors.white,
                  ),
                ),
                if (_activeFilterCount(state) > 0)
                  Positioned(
                    top: 9,
                    right: 7,
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFC107),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${_activeFilterCount(state)}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      body: !canAccess ? _noPermission() : _body(state),
    );
  }

  Widget _body(OnlineOrdersState state) {
    return Column(
      children: [
        _searchAndSummary(state),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref.read(onlineOrdersProvider.notifier).refresh(),
            child: _ordersList(state),
          ),
        ),
      ],
    );
  }

  Widget _searchAndSummary(OnlineOrdersState state) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        children: [
          TextField(
            controller: _customerController,
            onChanged: _onCustomerChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Buscar por cliente',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _customerController.text.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _customerController.clear();
                        _onCustomerChanged('');
                        setState(() {});
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                '${state.totalElements} pedido${state.totalElements == 1 ? '' : 's'}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const Spacer(),
              if (state.tipo != null) _smallChip(_typeLabel(state.tipo)),
              if (state.tipo != null && state.estado != null)
                const SizedBox(width: 5),
              if (state.estado != null) _smallChip(_statusLabel(state.estado)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ordersList(OnlineOrdersState state) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 110),
          Icon(Icons.cloud_off_rounded, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Text(
                state.error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(onlineOrdersProvider.notifier).loadFirstPage(),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ),
        ],
      );
    }
    if (state.orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.receipt_long_outlined,
            size: 58,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'No hay pedidos para los filtros seleccionados',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 5),
          Center(
            child: Text(
              'Desliza hacia abajo para actualizar',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 34),
      itemCount:
          state.orders.length + (state.hasMore || state.error != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.orders.length) {
          if (state.error != null) {
            return Center(
              child: TextButton.icon(
                onPressed: () =>
                    ref.read(onlineOrdersProvider.notifier).loadMore(),
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar carga'),
              ),
            );
          }
          return const Padding(
            padding: EdgeInsets.all(18),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return _orderCard(state.orders[index], state);
      },
    );
  }

  Widget _orderCard(OnlineOrder order, OnlineOrdersState state) {
    final date = order.createdOn == null
        ? '-'
        : DateFormat('dd/MM/yyyy · hh:mm a', 'es_PE').format(order.createdOn!);
    final loading = state.actionOrderId == order.id;
    final statusColor = _statusColor(order.estado);
    final comprobantePdfUrl = _comprobantePdfUrl(order);
    final restaurantOrderLoading =
        order.idOrderRestaurant != null &&
        _restaurantOrderLoadingId == order.idOrderRestaurant;
    final workflowLoading = _workflowLoadingOrderId == order.id;
    final canGenerateSale =
        order.tipo == 'CATALOGO' &&
        order.estado == 'ACEPTADO' &&
        _canCreateSales;
    final canEditCommand = order.tipo == 'MENU' && order.estado == 'ACEPTADO';
    final canInvoiceCommand =
        order.tipo == 'MENU' &&
        _canCreateSales &&
        order.comprobante == null &&
        (order.estado == 'ACEPTADO' ||
            (order.estado == 'ATENDIDO' && order.idOrderRestaurant != null));
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE3EE)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F1E293B),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
          BoxShadow(
            color: Color(0x24263238),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: state.isDetailLoading ? null : () => _openDetail(order),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera: número de pedido + estado
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                border: Border(
                  bottom: BorderSide(
                    color: statusColor.withValues(alpha: 0.18),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${formatOrderNumber(order.numeroPedido ?? order.id)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  _statusBadge(order.estado),
                  if (order.tipo == 'MENU' && order.estado == 'ATENDIDO') ...[
                    const SizedBox(width: 6),
                    _invoiceBadge(order.facturado),
                  ],
                ],
              ),
            ),
            // Cuerpo
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline_rounded,
                        size: 18,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          order.nombreCliente?.isNotEmpty == true
                              ? order.nombreCliente!
                              : 'Sin nombre',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${formatExchange(moneda: order.moneda ?? 'PEN')}${(order.total ?? 0).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.schedule_rounded,
                        size: 15,
                        color: Colors.grey.shade500,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        date,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _meta(Icons.storefront_outlined, _typeLabel(order.tipo)),
                      _meta(
                        Icons.inventory_2_outlined,
                        '${order.items.length} producto${order.items.length == 1 ? '' : 's'}',
                      ),
                      _meta(
                        Icons.local_shipping_outlined,
                        order.tipoEntrega == 'DELIVERY' ? 'Delivery' : 'Recojo',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(height: 1, color: Color(0xFFEEF2F7)),
                  const SizedBox(height: 12),
                  _orderActionsRow(
                    order: order,
                    state: state,
                    loading: loading,
                    workflowLoading: workflowLoading,
                    restaurantOrderLoading: restaurantOrderLoading,
                    comprobantePdfUrl: comprobantePdfUrl,
                    canGenerateSale: canGenerateSale,
                    canEditCommand: canEditCommand,
                    canInvoiceCommand: canInvoiceCommand,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Todas las acciones de la tarjeta en una sola fila. Las acciones con
  /// texto van en orden de importancia y la última (la principal: Generar
  /// venta / Facturar) toma el ancho libre; el resto se ajusta a su contenido.
  /// Ver detalle, Aceptar y Anular quedan como íconos compactos cuando hay
  /// otras acciones, para que la fila no se amontone.
  Widget _orderActionsRow({
    required OnlineOrder order,
    required OnlineOrdersState state,
    required bool loading,
    required bool workflowLoading,
    required bool restaurantOrderLoading,
    required String? comprobantePdfUrl,
    required bool canGenerateSale,
    required bool canEditCommand,
    required bool canInvoiceCommand,
  }) {
    final workflowBusy = _workflowLoadingOrderId != null;
    final labeled = <_CardAction>[
      if (order.idOrderRestaurant != null)
        _CardAction(
          icon: Icons.shopping_bag_outlined,
          label: 'Pedido',
          loading: restaurantOrderLoading,
          onTap: _restaurantOrderLoadingId != null
              ? null
              : () => _openRestaurantOrder(order),
        ),
      if (comprobantePdfUrl != null)
        _CardAction(
          icon: Icons.picture_as_pdf_outlined,
          label: 'Comprobante',
          onTap: () => _openExternalPdf(comprobantePdfUrl, 'comprobante'),
        ),
      if (canEditCommand)
        _CardAction(
          icon: Icons.edit_note_rounded,
          label: 'Editar',
          loading: workflowLoading,
          onTap: workflowBusy ? null : () => _editCommand(order),
        ),
      if (canInvoiceCommand)
        _CardAction(
          icon: Icons.receipt_rounded,
          label: 'Facturar',
          kind: OrderActionKind.primary,
          loading: workflowLoading,
          onTap: workflowBusy ? null : () => _invoiceMenuOrder(order),
        ),
      if (canGenerateSale)
        _CardAction(
          icon: Icons.point_of_sale_rounded,
          label: 'Generar venta',
          kind: OrderActionKind.primary,
          loading: workflowLoading,
          onTap: workflowBusy ? null : () => _generateCatalogSale(order),
        ),
    ];
    final detailButton = OrderActionButton(
      icon: Icons.receipt_long_outlined,
      label: labeled.isEmpty ? 'Ver detalle' : null,
      kind: OrderActionKind.brand,
      onTap: state.isDetailLoading ? null : () => _openDetail(order),
    );

    // En pantallas muy angostas (~320 px) las acciones secundarias con texto
    // pasan a solo ícono para que la principal no se recorte.
    List<Widget> labeledButtons(bool compact) => [
      for (var i = 0; i < labeled.length; i++)
        if (i == labeled.length - 1)
          Expanded(child: labeled[i].build())
        else if (compact)
          Tooltip(
            message: labeled[i].label,
            child: labeled[i].build(showLabel: false),
          )
        else
          Flexible(child: labeled[i].build()),
    ];

    Widget buildRow(bool compact) {
      final children = <Widget>[
        if (labeled.isEmpty)
          Expanded(child: detailButton)
        else ...[
          Tooltip(message: 'Ver detalle', child: detailButton),
          ...labeledButtons(compact),
        ],
        if (order.estado == 'PENDIENTE')
          Tooltip(
            message: 'Aceptar pedido',
            child: OrderActionButton(
              icon: Icons.check_rounded,
              kind: OrderActionKind.primary,
              loading: loading,
              onTap: loading ? null : () => _updateStatus(order, 'ACEPTADO'),
            ),
          ),
        if (_canCancel(order))
          Tooltip(
            message: 'Anular pedido',
            child: OrderActionButton(
              icon: Icons.close_rounded,
              kind: OrderActionKind.danger,
              loading: loading && order.estado != 'PENDIENTE',
              onTap: loading ? null : () => _confirmCancel(order),
            ),
          ),
      ];
      return Row(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            children[i],
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) =>
          buildRow(labeled.length > 1 && constraints.maxWidth < 290),
    );
  }

  Widget _meta(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    ),
  );

  Color _statusColor(String? status) => switch (status) {
    'PENDIENTE' => const Color(0xFFD97706),
    'ACEPTADO' => const Color(0xFF2563EB),
    'ANULADO' => const Color(0xFFDC2626),
    _ => const Color(0xFF16A34A),
  };

  Widget _statusBadge(String? status) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _invoiceBadge(bool invoiced) {
    final color = invoiced ? const Color(0xFF2563EB) : const Color(0xFFD97706);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        invoiced ? 'Facturado' : 'No facturado',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _smallChip(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: ColorSchema.primaryColor.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: ColorSchema.primaryColor,
      ),
    ),
  );

  Widget _noPermission() => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline_rounded,
            size: 56,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'No tienes permiso para ver los pedidos online',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  int _activeFilterCount(OnlineOrdersState state) =>
      (state.tipo != null ? 1 : 0) +
      (state.estado != null ? 1 : 0) +
      (state.numeroPedido.isNotEmpty ? 1 : 0) +
      (state.cliente.isNotEmpty ? 1 : 0);

  String _typeLabel(String? type) => switch (type) {
    'MENU' => 'Menú',
    'CATALOGO' => 'Catálogo',
    _ => 'Todos',
  };

  String _statusLabel(String? status) => switch (status) {
    'PENDIENTE' => 'Pendiente',
    'ACEPTADO' => 'Aceptado',
    'ATENDIDO' => 'Atendido',
    'ANULADO' => 'Anulado',
    'FINALIZADO' => 'Finalizado',
    _ => normalizeEnumLabel(status),
  };
}

/// Acción con texto de la tarjeta de pedido; se construye con o sin label
/// según el ancho disponible.
class _CardAction {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final OrderActionKind kind;

  const _CardAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.loading = false,
    this.kind = OrderActionKind.ghost,
  });

  OrderActionButton build({bool showLabel = true}) => OrderActionButton(
    icon: icon,
    label: showLabel ? label : null,
    kind: kind,
    loading: loading,
    onTap: onTap,
  );
}
