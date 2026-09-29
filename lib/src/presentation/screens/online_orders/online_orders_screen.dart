import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/presentation/screens/online_orders/widgets/online_order_detail_widget.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/online_orders/online_orders_provider.dart';
import 'package:teki_app/src/providers/online_orders/online_orders_state.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class OnlineOrdersScreen extends ConsumerStatefulWidget {
  const OnlineOrdersScreen({super.key});

  @override
  ConsumerState<OnlineOrdersScreen> createState() => _OnlineOrdersScreenState();
}

class _OnlineOrdersScreenState extends ConsumerState<OnlineOrdersScreen> {
  final _scrollController = ScrollController();
  final _customerController = TextEditingController();
  Timer? _searchDebounce;

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_canAccess) {
        ref.read(onlineOrdersProvider.notifier).loadFirstPage();
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
              DropdownButtonFormField<String>(
                initialValue: tipo,
                decoration: _filterDecoration('Origen'),
                items: const [
                  DropdownMenuItem(value: 'CATALOGO', child: Text('Catálogo')),
                  DropdownMenuItem(value: 'MENU', child: Text('Menú')),
                ],
                onChanged: (value) => setModalState(() => tipo = value),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: estado,
                decoration: _filterDecoration('Estado'),
                items: const [
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
                    child: OutlinedButton(
                      onPressed: () {
                        _customerController.clear();
                        ref.read(onlineOrdersProvider.notifier).applyFilters();
                        Navigator.pop(sheetContext);
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorSchema.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aplicar'),
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
            return SingleChildScrollView(
              controller: sheetScrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: OnlineOrderDetailWidget(
                order: selected,
                actionLoading: state.actionOrderId == selected.id,
                onAccept: selected.estado == 'PENDIENTE'
                    ? () => _updateStatus(selected, 'ACEPTADO')
                    : null,
                onCancel: _canCancel(selected)
                    ? () => _confirmCancel(selected)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _confirmCancel(OnlineOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Anular pedido'),
        content: Text(
          '¿Desea anular el pedido #${formatOrderNumber(order.numeroPedido ?? order.id)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
            child: const Text('Sí, anular'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _updateStatus(order, 'ANULADO');
  }

  Future<void> _updateStatus(OnlineOrder order, String status) async {
    try {
      final result = await ref
          .read(onlineOrdersProvider.notifier)
          .changeStatus(order, status);
      if (!mounted) return;
      successNotification(
        status == 'ACEPTADO' ? 'Pedido aceptado' : 'Pedido anulado',
        fromTop: false,
      );
      final notificationMessage = result.notification.message;
      if (notificationMessage?.isNotEmpty == true) {
        if (result.notification.success) {
          infoNotification(notificationMessage!, fromTop: false);
        } else {
          warningNotification(notificationMessage!, fromTop: false);
        }
      }
    } catch (error) {
      if (!mounted) return;
      errorNotification(
        error.toString().replaceFirst(RegExp(r'^Exception:\s*'), ''),
        fromTop: false,
      );
    }
  }

  bool _canCancel(OnlineOrder order) =>
      !const ['ANULADO', 'ATENDIDO', 'FINALIZADO'].contains(order.estado);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onlineOrdersProvider);
    final session = ref.watch(sesionProvider);
    final canAccess =
        session.hasPermission('SUPER_USUARIO') ||
        session.hasPermission('CATALOGO_VER') ||
        session.hasPermission('MENU_CLIENTE_VER');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FF),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: state.isDetailLoading ? null : () => _openDetail(order),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Pedido #${formatOrderNumber(order.numeroPedido ?? order.id)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _statusBadge(order.estado),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                date,
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
              const Divider(height: 20),
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    '${formatExchange(moneda: order.moneda ?? 'PEN')}${(order.total ?? 0).toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 7),
              Row(
                children: [
                  _meta(Icons.storefront_outlined, _typeLabel(order.tipo)),
                  const SizedBox(width: 12),
                  _meta(
                    Icons.inventory_2_outlined,
                    '${order.items.length} producto${order.items.length == 1 ? '' : 's'}',
                  ),
                  const SizedBox(width: 12),
                  _meta(
                    Icons.local_shipping_outlined,
                    order.tipoEntrega == 'DELIVERY' ? 'Delivery' : 'Recojo',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: state.isDetailLoading
                          ? null
                          : () => _openDetail(order),
                      icon: const Icon(Icons.visibility_outlined, size: 18),
                      label: const Text('Detalle'),
                    ),
                  ),
                  if (order.estado == 'PENDIENTE') ...[
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Aceptar',
                      onPressed: loading
                          ? null
                          : () => _updateStatus(order, 'ACEPTADO'),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                      ),
                      icon: loading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_rounded),
                    ),
                  ],
                  if (_canCancel(order)) ...[
                    const SizedBox(width: 5),
                    IconButton(
                      tooltip: 'Anular',
                      onPressed: loading ? null : () => _confirmCancel(order),
                      color: const Color(0xFFDC2626),
                      icon: const Icon(Icons.block_rounded),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String label) => Expanded(
    child: Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
          ),
        ),
      ],
    ),
  );

  Widget _statusBadge(String? status) {
    final color = switch (status) {
      'PENDIENTE' => const Color(0xFFD97706),
      'ACEPTADO' => const Color(0xFF2563EB),
      'ANULADO' => const Color(0xFFDC2626),
      _ => const Color(0xFF16A34A),
    };
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
