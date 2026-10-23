import 'package:flutter/material.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_page_notifier.dart';
import 'package:teki_app/src/presentation/screens/loyalty/widgets/loyalty_shell.dart';

class LoyaltyPagedList<T> extends StatelessWidget {
  final LoyaltyPageState<T> state;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function() onRefresh;
  final VoidCallback onLoadMore;
  final String emptyText;
  final List<Widget> header;
  const LoyaltyPagedList({
    super.key,
    this.header = const [],
    required this.state,
    required this.itemBuilder,
    required this.onRefresh,
    required this.onLoadMore,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (state.loading) return const Center(child: CircularProgressIndicator());
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        itemCount: header.length + state.items.length + 1,
        itemBuilder: (context, index) {
          if (index < header.length) return header[index];
          final itemIndex = index - header.length;
          if (itemIndex < state.items.length) {
            return itemBuilder(state.items[itemIndex]);
          }
          if (state.items.isEmpty) {
            return LoyaltyMessage(
              icon: state.error == null
                  ? Icons.people_outline
                  : Icons.cloud_off_outlined,
              text: state.error ?? emptyText,
              retry: state.error == null ? null : () => onRefresh(),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Column(
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(state.error!, textAlign: TextAlign.center),
                  ),
                if (state.loadingMore)
                  const CircularProgressIndicator()
                else if (state.hasMore)
                  OutlinedButton(
                    onPressed: onLoadMore,
                    child: Text(
                      state.error == null
                          ? 'Cargar más'
                          : 'Reintentar cargar más',
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
