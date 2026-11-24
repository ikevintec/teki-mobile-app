import 'dart:async';
import 'package:teki_app/src/presentation/widgets/floating_action_button/custom_floating_action_button.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/sections/orders_restaurant_list_section.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/more_filters_bottom_sheet.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/orders_filter_bar.dart';
import 'package:teki_app/src/presentation/screens/push_notification_events/order_ready_to_pay_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/socket_service.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class OrdersRestaurantMainScreen extends ConsumerStatefulWidget {
  const OrdersRestaurantMainScreen({super.key});

  @override
  ConsumerState<OrdersRestaurantMainScreen> createState() =>
      _OrdersRestaurantMainScreenState();
}

class _OrdersRestaurantMainScreenState
    extends ConsumerState<OrdersRestaurantMainScreen> with RouteAware {
  late final TextEditingController _searchController;
  Timer? _debounce;
  bool _subscribed = false;
  final _socketService = SocketService();
  StreamSubscription<dynamic>? _orderSub;

  /// Se pone en true cuando GetX navega a una pantalla nombrada encima de esta.
  /// Dialogs y dropdowns NO cambian Get.currentRoute, por lo que nunca lo activan.
  bool _pendingReload = false;

  /// true cuando llegamos desde una notificación order_ready con args.
  bool _isNotificationNav = false;

  /// Último [notificationTrigger] del provider que ya se manejó con auto-nav.
  /// Si el trigger del estado es mayor, es una notificación nueva → navegar.
  /// Si es igual, ya se navegó para este trigger → no re-navegar (ej: back).
  int _lastHandledTrigger = 0;


  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _orderSub = _socketService
        .on(SocketEvent.orderRestaurant)
        .listen((_) { if (mounted) _reload(); });

    final args = Get.arguments as Map<String, dynamic>?;
    _isNotificationNav = args != null && args.containsKey('orderNumber');

    Future.microtask(() {
      if (!mounted) return;
      final idPuntoVenta = ref.read(sesionProvider).office?.id ?? 0;
      if (_isNotificationNav) {
        final orderNumber = args!['orderNumber'] as String? ?? '';
        final typeOrder = args['typeOrder'] as String? ?? '';
        final paid = args['paid'] as bool?;
        if (orderNumber.isNotEmpty) {
          _searchController.text = orderNumber;
        }
        ref.read(ordersRestaurantProvider.notifier).applyNotificationFilters(
              idPuntoVenta: idPuntoVenta,
              searchTerm: orderNumber.isNotEmpty ? orderNumber : null,
              tipo: typeOrder.isNotEmpty ? typeOrder : null,
              paid: paid,
            );
      } else {
        _reload();
      }
      _socketService.connect(officeCode: ref.read(sesionProvider).office?.codigo ?? '');
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_subscribed) {
      final route = ModalRoute.of(context);
      if (route != null) {
        routeObserver.subscribe(this, route);
        _subscribed = true;
      }
    }
  }

  void _reload() {
    final idPuntoVenta = ref.read(sesionProvider).office?.id ?? 0;
    ref.read(ordersRestaurantProvider.notifier).initialize(idPuntoVenta);
  }

  /// Llamado cuando cualquier ruta se apila encima.
  /// Solo activa el flag si GetX registró una ruta nombrada (pantalla completa).
  /// Dialogs y dropdowns no modifican Get.currentRoute, así que no activan el flag.
  @override
  void didPushNext() {
    if (Get.currentRoute != AppRoutes.ordersRestaurant) {
      _pendingReload = true;
    }
  }

  /// Llamado cuando la ruta de encima se cierra.
  /// Solo recarga si fue una pantalla real la que se cerró (flag activo).
  @override
  void didPopNext() {
    if (_pendingReload) {
      _pendingReload = false;
      _reload();
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _orderSub?.cancel();
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      ref.read(ordersRestaurantProvider.notifier).updateSearch(value);
    });
  }

  void _openMoreFilters() {
    final state = ref.read(ordersRestaurantProvider);
    // Parse stored api-format strings back to DateTime for the picker
    final formatter = RegExp(r'^\d{2}-\d{2}-\d{4}$');
    DateTime? desdeDate;
    DateTime? hastaDate;
    if (state.desde != null && formatter.hasMatch(state.desde!)) {
      final parts = state.desde!.split('-');
      desdeDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    }
    if (state.hasta != null && formatter.hasMatch(state.hasta!)) {
      final parts = state.hasta!.split('-');
      hastaDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    }

    MoreFiltersBottomSheet.show(
      context,
      selectedEstados: state.estados,
      desde: desdeDate,
      hasta: hastaDate,
      onApply: (estados, desde, hasta) {
        ref.read(ordersRestaurantProvider.notifier).updateEstados(estados);
        ref.read(ordersRestaurantProvider.notifier).updateFechas(
              desde: desde,
              hasta: hasta,
              clearDesde: desde == null,
              clearHasta: hasta == null,
            );
      },
    );
  }

  bool get _hasNonDefaultFilters {
    final state = ref.watch(ordersRestaurantProvider);
    return state.estados.length < kAllEstados.length ||
        state.desde != null ||
        state.hasta != null;
  }

  /// Devuelve el par (order, cuenta) si se cumple la condición de auto-pago,
  /// o null en caso contrario.
  (OrderRestaurant, Check)? _readyToPayTarget(OrdersRestaurantState state) {
    if (state.orders.length != 1) return null;
    final order = state.orders.first;
    final cuentas = order.cuentas;
    if (cuentas == null || cuentas.length != 1) return null;
    final cuenta = cuentas.first;
    if (cuenta.pagado == true) return null;
    if (order.comandas == null || order.comandas!.isEmpty) return null;
    if ((order.comandas ?? []).length > 1) return null;

    final items = (order.comandas?[0].items ?? []).where((i) => i.eliminado != true).toList();
    if (items.isEmpty) return null;
    if (!items.every((i) => i.estadoComandaDetalle == 'PREPARADO')) {
      infoNotification("La orden tiene items sin preparar.",duration: const Duration(seconds: 4));
      return null;
    }
    return (order, cuenta);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersRestaurantProvider);
    final isInitialLoading = state.isLoading && state.orders.isEmpty;

    // Auto-navegar al pay screen cuando venimos de una notificación y se cumple
    // la condición: 1 resultado, 1 cuenta, todos los items en PREPARADO.
    // Auto-navegar al pay screen cuando:
    // • hay un trigger de notificación nuevo (mayor que el último manejado),
    // • la carga terminó, y • la condición de pago se cumple.
    // Guardar el trigger evita re-navegar si el usuario vuelve atrás con el
    // mismo estado de resultados.
    ref.listen<OrdersRestaurantState>(ordersRestaurantProvider, (_, next) {
      if (next.isLoading) return;
      if (next.notificationTrigger <= _lastHandledTrigger) return;
      final target = _readyToPayTarget(next);
      if (target == null) return;
      _lastHandledTrigger = next.notificationTrigger;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OrderReadyToPayScreen(
              order: target.$1,
              cuenta: target.$2,
            ),
          ),
        );
      });
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Pedidos'),
      ),
      floatingActionButton: CustomFloatingActionButton(
        buttonName: 'Pedido',
        onPressed: () {
          Get.toNamed(
            AppRoutes.restaurantComanda,
            arguments: {'isPedidoSinMesa': true},
          );
        },
      ),
      body: Column(
        children: [
          _buildFilters(),
          Expanded(
            child: isInitialLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: ColorSchema.primaryColor,
                      strokeWidth: 2,
                    ),
                  )
                : RefreshIndicator(
                    color: ColorSchema.primaryColor,
                    onRefresh: () async {
                      _searchController.clear();
                      await ref
                          .read(ordersRestaurantProvider.notifier)
                          .refresh();
                    },
                    child: OrdersRestaurantListSection(orders: state.orders),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    final state = ref.watch(ordersRestaurantProvider);

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      child: Column(
        children: [
          OrdersSearchBar(
            controller: _searchController,
            onChanged: _onSearchChanged,
            onFilterTap: _openMoreFilters,
            hasActiveFilters: _hasNonDefaultFilters,
          ),
          const SizedBox(height: 8),
          OrdersDropdownRow(
            selectedTipo: state.selectedTipo,
            selectedEstadoPago: state.selectedEstadoPago,
            onTipoChanged: (v) =>
                ref.read(ordersRestaurantProvider.notifier).updateTipo(v),
            onEstadoPagoChanged: (v) =>
                ref.read(ordersRestaurantProvider.notifier).updateEstadoPago(v),
          ),
        ],
      ),
    );
  }
}
