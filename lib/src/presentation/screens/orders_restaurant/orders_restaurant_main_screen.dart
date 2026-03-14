import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/main.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/sections/orders_restaurant_list_section.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/more_filters_bottom_sheet.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/orders_filter_bar.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/socket_service.dart';
import 'package:teki_app/src/utils/contstants.dart';

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

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    _orderSub = _socketService
        .on(SocketEvent.orderRestaurant)
        .listen((_) { if (mounted) _reload(); });

    Future.microtask(() {
      if (!mounted) return;
      _reload();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ordersRestaurantProvider);
    final isInitialLoading = state.isLoading && state.orders.isEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Pedidos'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Get.toNamed(
            AppRoutes.restaurantComanda,
            arguments: {'isPedidoSinMesa': true},
          );
        },
        backgroundColor: ColorSchema.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pedido',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
