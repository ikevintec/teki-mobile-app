import 'package:teki_app/src/data/models/teki_model/online_order.dart';

const _notSet = Object();

class OnlineOrdersState {
  final List<OnlineOrder> orders;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool isDetailLoading;
  final int pageNumber;
  final int totalElements;
  final bool hasMore;
  final int? actionOrderId;
  final OnlineOrder? selectedOrder;
  final String? tipo;
  final String? estado;
  final String cliente;
  final String numeroPedido;
  final String? error;

  const OnlineOrdersState({
    this.orders = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.isDetailLoading = false,
    this.pageNumber = 0,
    this.totalElements = 0,
    this.hasMore = true,
    this.actionOrderId,
    this.selectedOrder,
    this.tipo,
    this.estado,
    this.cliente = '',
    this.numeroPedido = '',
    this.error,
  });

  OnlineOrdersState copyWith({
    List<OnlineOrder>? orders,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? isDetailLoading,
    int? pageNumber,
    int? totalElements,
    bool? hasMore,
    Object? actionOrderId = _notSet,
    Object? selectedOrder = _notSet,
    Object? tipo = _notSet,
    Object? estado = _notSet,
    String? cliente,
    String? numeroPedido,
    Object? error = _notSet,
  }) {
    return OnlineOrdersState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isDetailLoading: isDetailLoading ?? this.isDetailLoading,
      pageNumber: pageNumber ?? this.pageNumber,
      totalElements: totalElements ?? this.totalElements,
      hasMore: hasMore ?? this.hasMore,
      actionOrderId: identical(actionOrderId, _notSet)
          ? this.actionOrderId
          : actionOrderId as int?,
      selectedOrder: identical(selectedOrder, _notSet)
          ? this.selectedOrder
          : selectedOrder as OnlineOrder?,
      tipo: identical(tipo, _notSet) ? this.tipo : tipo as String?,
      estado: identical(estado, _notSet) ? this.estado : estado as String?,
      cliente: cliente ?? this.cliente,
      numeroPedido: numeroPedido ?? this.numeroPedido,
      error: identical(error, _notSet) ? this.error : error as String?,
    );
  }
}
