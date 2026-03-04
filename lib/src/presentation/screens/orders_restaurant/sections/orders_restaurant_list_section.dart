import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/orderRestaurant.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/widgets/order_restaurant_card.dart';
import 'package:teki_app/src/providers/orders_restaurant/orders_restaurant_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class OrdersRestaurantListSection extends ConsumerStatefulWidget {
  final List<OrderRestaurant> orders;

  const OrdersRestaurantListSection({super.key, required this.orders});

  @override
  ConsumerState<OrdersRestaurantListSection> createState() =>
      _OrdersRestaurantListSectionState();
}

class _OrdersRestaurantListSectionState
    extends ConsumerState<OrdersRestaurantListSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    Future.microtask(() {
      if (!ref.read(ordersRestaurantProvider).isLoading) {
        ref.read(ordersRestaurantProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLast = ref.watch(ordersRestaurantProvider).last;

    if (widget.orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 64, color: ColorSchema.subTitleTextColor),
                SizedBox(height: 12),
                Text(
                  'No hay órdenes',
                  style: TextStyle(
                    fontSize: 15,
                    color: ColorSchema.subTitleTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: widget.orders.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.orders.length) {
          if (isLast) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'No hay más órdenes',
                  style: TextStyle(
                    fontSize: 12,
                    color: ColorSchema.subTitleTextColor,
                  ),
                ),
              ),
            );
          }
          _loadMore();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: CircularProgressIndicator(
                color: ColorSchema.primaryColor,
                strokeWidth: 2,
              ),
            ),
          );
        }

        return OrderRestaurantCard(order: widget.orders[index]);
      },
    );
  }
}
