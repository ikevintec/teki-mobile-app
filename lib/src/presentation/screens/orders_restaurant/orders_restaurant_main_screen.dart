import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/sections/orders_restaurant_list_section.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/more_filters_bottom_sheet.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/orders_filter_bar.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OrdersRestaurantMainScreen extends ConsumerStatefulWidget {
  const OrdersRestaurantMainScreen({super.key});

  @override
  ConsumerState<OrdersRestaurantMainScreen> createState() =>
      _OrdersRestaurantMainScreenState();
}

class _OrdersRestaurantMainScreenState
    extends ConsumerState<OrdersRestaurantMainScreen> {
  late final TextEditingController _searchController;
  Timer? _debounce;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final idPuntoVenta =
          ref.read(sesionProvider).office?.id ?? 0;
      Future.microtask(() {
        ref
            .read(ordersRestaurantProvider.notifier)
            .initialize(idPuntoVenta);
      });
      _initialized = true;
    }
  }

  @override
  void dispose() {
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
        onPressed: null,
        backgroundColor: ColorSchema.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Pedido', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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
