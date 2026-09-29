import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/data/models/whatsapp/whatsapp_response.dart';
import 'package:teki_app/src/data/repositories/online_order_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/online_order_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/online_orders/online_orders_state.dart';
import 'package:teki_app/src/providers/whatsapp/whatsapp_provider.dart';
import 'package:teki_app/src/utils/online_order_message.dart';

final onlineOrderRepositoryProvider = Provider<OnlineOrderRepository>(
  (ref) => OnlineOrderRepositoryImpl(),
);

final onlineOrdersProvider =
    StateNotifierProvider.autoDispose<OnlineOrdersNotifier, OnlineOrdersState>((
      ref,
    ) {
      return OnlineOrdersNotifier(
        repository: ref.watch(onlineOrderRepositoryProvider),
        ref: ref,
      );
    });

class OnlineOrdersNotifier extends StateNotifier<OnlineOrdersState> {
  final OnlineOrderRepository repository;
  final Ref ref;
  static const int _perPage = 15;
  int _requestGeneration = 0;

  OnlineOrdersNotifier({required this.repository, required this.ref})
    : super(const OnlineOrdersState());

  Future<void> loadFirstPage({bool silent = false}) async {
    final generation = ++_requestGeneration;
    state = state.copyWith(
      isLoading: !silent,
      isRefreshing: silent,
      isLoadingMore: false,
      pageNumber: 0,
      hasMore: true,
      orders: silent ? state.orders : const [],
      error: null,
    );

    try {
      final response = await repository.getOrders(_buildParams(0));
      if (generation != _requestGeneration) return;
      state = state.copyWith(
        orders: response.content,
        isLoading: false,
        isRefreshing: false,
        pageNumber: response.number,
        totalElements: response.totalElements,
        hasMore: !response.last,
      );
    } catch (error) {
      if (generation != _requestGeneration) return;
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        error: _cleanError(error),
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    final generation = _requestGeneration;
    final nextPage = state.pageNumber + 1;
    state = state.copyWith(isLoadingMore: true, error: null);

    try {
      final response = await repository.getOrders(_buildParams(nextPage));
      if (generation != _requestGeneration) return;
      final existingIds = state.orders.map((order) => order.id).toSet();
      final newOrders = response.content
          .where((order) => !existingIds.contains(order.id))
          .toList();
      state = state.copyWith(
        orders: [...state.orders, ...newOrders],
        isLoadingMore: false,
        pageNumber: response.number,
        totalElements: response.totalElements,
        hasMore: !response.last,
      );
    } catch (error) {
      if (generation != _requestGeneration) return;
      state = state.copyWith(isLoadingMore: false, error: _cleanError(error));
    }
  }

  Future<void> refresh() => loadFirstPage(silent: true);

  Future<void> applyFilters({
    String? tipo,
    String? estado,
    String cliente = '',
    String numeroPedido = '',
  }) async {
    state = state.copyWith(
      tipo: tipo,
      estado: estado,
      cliente: cliente.trim(),
      numeroPedido: numeroPedido.replaceAll(RegExp(r'\D'), ''),
    );
    await loadFirstPage();
  }

  Future<OnlineOrder?> loadDetail(int id) async {
    state = state.copyWith(isDetailLoading: true, selectedOrder: null);
    try {
      final order = await repository.getOrder(id);
      state = state.copyWith(isDetailLoading: false, selectedOrder: order);
      return order;
    } catch (error) {
      state = state.copyWith(isDetailLoading: false, error: _cleanError(error));
      return null;
    }
  }

  /// Cambia el estado del pedido. El aviso al cliente por WhatsApp es un
  /// paso aparte ([notifyCustomer]) que la vista ofrece tras confirmar.
  Future<OnlineOrder> changeStatus(OnlineOrder current, String status) async {
    if (current.id == null) {
      throw Exception('El pedido no tiene un identificador válido');
    }
    state = state.copyWith(actionOrderId: current.id, error: null);
    try {
      final updated = await repository.changeStatus(current.id!, status);
      _replaceOrder(updated);

      // La recarga respeta los filtros activos: por ejemplo, un pedido deja de
      // aparecer inmediatamente si la vista está filtrada por PENDIENTE.
      await loadFirstPage(silent: true);

      state = state.copyWith(actionOrderId: null);
      return updated;
    } catch (error) {
      state = state.copyWith(actionOrderId: null, error: _cleanError(error));
      rethrow;
    }
  }

  /// Avisa al cliente del nuevo [status] por el flujo de WhatsApp configurado
  /// (Evolution API o WhatsApp público como respaldo).
  Future<WhatsappResponse> notifyCustomer(OnlineOrder order, String status) {
    final session = ref.read(sesionProvider);
    final message = buildOnlineOrderStatusMessage(
      order,
      status,
      session.companySelected?.nombreComercial ??
          session.companySelected?.razonSocial ??
          session.company?.nombreComercial ??
          session.company?.razonSocial,
    );
    return ref
        .read(whatsappProvider.notifier)
        .sendOrderStatusMessage(
          phoneNumber: order.telefonoCliente ?? '',
          message: message,
        );
  }

  Map<String, dynamic> _buildParams(int pageNumber) {
    return {
      'pageNumber': pageNumber,
      'perPage': _perPage,
      'sortField': 'createdOn',
      'sortOrder': -1,
      if (state.tipo != null) 'tipo': state.tipo,
      if (state.estado != null) 'estado': state.estado,
      if (state.cliente.isNotEmpty) 'cliente': state.cliente,
      if (state.numeroPedido.isNotEmpty) 'numeroPedido': state.numeroPedido,
    };
  }

  void _replaceOrder(OnlineOrder updated) {
    state = state.copyWith(
      orders: state.orders
          .map((order) => order.id == updated.id ? updated : order)
          .toList(),
      selectedOrder: state.selectedOrder?.id == updated.id
          ? updated
          : state.selectedOrder,
    );
  }

  String _cleanError(Object error) =>
      error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
}
