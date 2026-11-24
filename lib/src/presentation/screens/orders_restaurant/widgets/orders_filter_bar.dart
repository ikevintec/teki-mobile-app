import 'package:flutter/material.dart';
import 'package:teki_app/src/utils/constants.dart';

class OrdersSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String) onChanged;
  final VoidCallback onFilterTap;
  final bool hasActiveFilters;

  const OrdersSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onFilterTap,
    this.hasActiveFilters = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Buscar cliente o nro. de orden',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[500],
                ),
                prefixIcon: const Icon(Icons.search,
                    size: 20, color: ColorSchema.subTitleTextColor),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear,
                            size: 18, color: ColorSchema.subTitleTextColor),
                        onPressed: () {
                          controller.clear();
                          onChanged('');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _FilterButton(
          onTap: onFilterTap,
          hasActive: hasActiveFilters,
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasActive;

  const _FilterButton({required this.onTap, required this.hasActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: hasActive
              ? ColorSchema.primaryColor
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 20,
              color: hasActive ? Colors.white : ColorSchema.subTitleTextColor,
            ),
            if (hasActive)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class OrdersDropdownRow extends StatelessWidget {
  final String selectedTipo;
  final String selectedEstadoPago;
  final void Function(String?) onTipoChanged;
  final void Function(String?) onEstadoPagoChanged;

  const OrdersDropdownRow({
    super.key,
    required this.selectedTipo,
    required this.selectedEstadoPago,
    required this.onTipoChanged,
    required this.onEstadoPagoChanged,
  });

  static const List<DropOption> tipoOptions = [
    DropOption('TODOS', 'Todos'),
    DropOption('LOCAL', 'Mesa'),
    DropOption('PEDIDO_LOCAL_INTERNO', 'Interno'),
    DropOption('PEDIDO_LOCAL', 'Para llevar'),
    DropOption('PEDIDO_FORANEO', 'Delivery'),
    DropOption('PEDIDO_ONLINE', 'Pedido online'),
  ];

  static const List<DropOption> estadoPagoOptions = [
    DropOption('TODOS', 'Todos'),
    DropOption('PAGADOS', 'Pagados'),
    DropOption('NO_PAGADOS', 'No pagados'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StyledDropdown(
            value: selectedTipo,
            items: tipoOptions,
            hint: 'Tipo',
            onChanged: onTipoChanged,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StyledDropdown(
            value: selectedEstadoPago,
            items: estadoPagoOptions,
            hint: 'Estado pago',
            onChanged: onEstadoPagoChanged,
          ),
        ),
      ],
    );
  }
}

class _StyledDropdown extends StatelessWidget {
  final String value;
  final List<DropOption> items;
  final String hint;
  final void Function(String?) onChanged;

  const _StyledDropdown({
    required this.value,
    required this.items,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 18, color: ColorSchema.subTitleTextColor),
          style: const TextStyle(
            fontSize: 13,
            color: ColorSchema.titleTextColor,
          ),
          items: items
              .map(
                (opt) => DropdownMenuItem<String>(
                  value: opt.value,
                  child: Text(opt.label, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class DropOption {
  final String value;
  final String label;

  const DropOption(this.value, this.label);
}
