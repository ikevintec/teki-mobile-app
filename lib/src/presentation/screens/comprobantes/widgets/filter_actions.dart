import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/other_filters.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/utils/contstants.dart';

class FilterActions extends StatelessWidget {
  const FilterActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: () {
            showCustomModal(context: context, child: OtherFilters(onFiltersChanged: (p0) {
              print(p0);
            },), tittle: 'Filtros Adicionales',allowButtons: false, showButtoms: false);
          },
          icon: const Icon(Icons.filter_list_outlined, color: ColorSchema.primaryColor),
          label: const Text(
            'Mas filtros',
            style: TextStyle(
              color: ColorSchema.primaryColor,
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ColorSchema.primaryColor,
          ),
        ),
      ],
    );
  }
}