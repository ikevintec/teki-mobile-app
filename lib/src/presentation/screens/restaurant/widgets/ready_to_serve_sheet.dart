import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/restaurant/ready_to_serve_provider.dart';
import 'package:teki_app/src/utils/constants.dart';

class ReadyToServeSheet extends ConsumerStatefulWidget {
  final int officeId;

  const ReadyToServeSheet({super.key, required this.officeId});

  static Future<void> show(BuildContext context, int officeId) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReadyToServeSheet(officeId: officeId),
    );
  }

  @override
  ConsumerState<ReadyToServeSheet> createState() => _ReadyToServeSheetState();
}

class _ReadyToServeSheetState extends ConsumerState<ReadyToServeSheet> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  String _waitingLabel(DateTime preparedAt) {
    final minutes = DateTime.now().difference(preparedAt).inMinutes;
    if (minutes < 1) return 'Recién';
    if (minutes < 60) return 'Hace $minutes min';
    final hours = minutes ~/ 60;
    final rest = minutes % 60;
    return 'Hace $hours h ${rest > 0 ? '$rest min' : ''}'.trim();
  }

  String _quantity(double value) =>
      value == value.roundToDouble() ? value.toInt().toString() : '$value';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readyToServeProvider);
    final notifier = ref.read(readyToServeProvider.notifier);

    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.88,
        decoration: const BoxDecoration(
          color: Color(0xFFF7F8FA),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 10, 8, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.room_service_rounded,
                    color: ColorSchema.primaryColor,
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Por servir',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (state.total > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade600,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${state.total}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    tooltip: 'Actualizar',
                    onPressed: state.isLoading
                        ? null
                        : () => notifier.refresh(widget.officeId),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            if (state.isLoading)
              const LinearProgressIndicator(
                minHeight: 2,
                color: ColorSchema.primaryColor,
              ),
            Expanded(
              child: state.groups.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => notifier.refresh(widget.officeId),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 110),
                          Icon(
                            Icons.check_circle_outline_rounded,
                            size: 56,
                            color: Colors.green,
                          ),
                          SizedBox(height: 12),
                          Center(
                            child: Text(
                              'Nada por servir. Todo está en las mesas.',
                              style: TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () => notifier.refresh(widget.officeId),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
                        itemCount: state.groups.length,
                        itemBuilder: (context, index) {
                          final group = state.groups[index];
                          final servingTable = state.processingOrderIds
                              .contains(group.orderId);
                          return Card(
                            color: Colors.white,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.table_restaurant_rounded,
                                        color: ColorSchema.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              group.title,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            if (group.subtitle.isNotEmpty)
                                              Text(
                                                group.subtitle,
                                                style: const TextStyle(
                                                  color: Colors.black54,
                                                  fontSize: 12,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      if (group.dishes.length > 1)
                                        FilledButton.icon(
                                          onPressed: servingTable
                                              ? null
                                              : () => notifier.serveTable(
                                                  group,
                                                  widget.officeId,
                                                ),
                                          icon: servingTable
                                              ? const SizedBox(
                                                  width: 14,
                                                  height: 14,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        color: Colors.white,
                                                      ),
                                                )
                                              : const Icon(
                                                  Icons.room_service_rounded,
                                                  size: 17,
                                                ),
                                          label: const Text('Servir todo'),
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  ...group.dishes.map((dish) {
                                    final serving = state.processingItemIds
                                        .contains(dish.itemId);
                                    final delayed =
                                        DateTime.now()
                                            .difference(dish.preparedAt)
                                            .inMinutes >=
                                        5;
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 38,
                                            height: 38,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: delayed
                                                  ? Colors.red.shade50
                                                  : Colors.green.shade50,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              '${_quantity(dish.quantity)}x',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: delayed
                                                    ? Colors.red.shade700
                                                    : Colors.green.shade700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  dish.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                                if (dish.note?.isNotEmpty ==
                                                    true)
                                                  Text(
                                                    dish.note!,
                                                    style: const TextStyle(
                                                      color: Colors.black54,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                Text(
                                                  'Listo · ${_waitingLabel(dish.preparedAt)}',
                                                  style: TextStyle(
                                                    color: delayed
                                                        ? Colors.red.shade700
                                                        : Colors.black45,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          OutlinedButton(
                                            onPressed: serving || servingTable
                                                ? null
                                                : () => notifier.serveDish(
                                                    dish,
                                                    widget.officeId,
                                                  ),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.green,
                                              side: const BorderSide(
                                                color: Colors.green,
                                              ),
                                            ),
                                            child: serving
                                                ? const SizedBox(
                                                    width: 15,
                                                    height: 15,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                        ),
                                                  )
                                                : const Text('Servir'),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
