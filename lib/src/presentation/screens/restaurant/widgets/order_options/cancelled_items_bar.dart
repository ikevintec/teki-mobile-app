import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options/comanda_item_row.dart';

// ─── Cancelled items collapsible bar ─────────────────────────────────────────

class CancelledItemsBar extends StatefulWidget {
  final List<CommandDetail> items;
  final bool showStatus;

  const CancelledItemsBar({super.key, required this.items, this.showStatus = true});

  @override
  State<CancelledItemsBar> createState() => CancelledItemsBarState();
}

class CancelledItemsBarState extends State<CancelledItemsBar> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final count = widget.items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.red.shade300, width: 3),
                bottom: BorderSide(color: Colors.grey.shade300, width: 1.0),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
            child: Row(
              children: [
                Text(
                  '$count ${count == 1 ? 'item anulado' : 'items anulados'}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade300,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _expanded ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  size: 13,
                  color: Colors.red.shade300,
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.items.map(
            (item) => CommandaItemRow(item: item, showStatus: widget.showStatus),
          ),
      ],
    );
  }
}
