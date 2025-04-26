import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/dropdown/scrolbar.dart';

class DropDown extends StatefulWidget {
  final List<dynamic>? items;
  final String? label;
  final dynamic value;
  final String displayField;
  final Function(dynamic)? onChanged;
  final String Function(dynamic)? itemAsString;

  const DropDown({
    super.key,
    this.items,
    this.label,
    this.value,
    required this.displayField,
    this.onChanged,
    required this.itemAsString,
  });

  @override
  State<DropDown> createState() => _DropDownState();
}

class _DropDownState extends State<DropDown> {
  bool isExpanded = false;
  dynamic selectedValue;
  int groupValue = -1;

  @override
  void initState() {
    super.initState();
    groupValue = widget.items?.indexWhere((item) => item == widget.value) ?? -1;
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.items ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => isExpanded = !isExpanded),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    selectedValue != null
                        ? widget.itemAsString?.call(selectedValue) ?? '' ?? 'Seleccionar'
                        : widget.label ?? 'Seleccionar',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
              ],
            ),
          ),
        ),
        if (isExpanded)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: MyScrollbar(
              scrollController: ScrollController(),
              builder: (context, scrollController) => ListView.builder(
                controller: scrollController,
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return RadioListTile<int>(
                    title: Text(item[widget.displayField] ?? ''),
                    value: index,
                    groupValue: groupValue,
                    onChanged: (val) {
                      setState(() {
                        groupValue = val!;
                        selectedValue = item;
                        isExpanded = false;
                      });
                      if (widget.onChanged != null) {
                        widget.onChanged!(item);
                      }
                    },
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
