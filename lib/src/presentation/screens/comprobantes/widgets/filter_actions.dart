import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/other_filters.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/utils/contstants.dart';

class FilterActions extends ConsumerWidget {
  final String? filtroDesde;
  final String? filtroHasta;
  
  const FilterActions({
    super.key,
    this.filtroDesde,
    this.filtroHasta,
  });


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Botón de más filtros
        TextButton.icon(
          onPressed: () {
            showCustomModal(
              context: context, 
              child: OtherFilters(
                onApplyFilters: () {
                  Navigator.pop(context);
                  // Obtener el estado actual del provider para usar los filtros guardados
                  final currentState = ref.read(comprobantesSaleProvider);
                  
                  // Usar los valores del provider si no se proporcionaron desde fuera
                  final desde = filtroDesde ?? currentState.filtroDesde;
                  final hasta = filtroHasta ?? currentState.filtroHasta;
                  
                  // Solo hacer la búsqueda si tenemos fechas válidas
                  if (desde.isNotEmpty && hasta.isNotEmpty) {
                    ref.read(comprobantesSaleProvider.notifier).loadFirstPage(
                      desde: desde,
                      hasta: hasta,
                      serie: currentState.filtroSerie,
                      numero: currentState.filtroNumero,
                      tiposComprobante: currentState.filtroTipoComprobante,
                      metodosPago: currentState.idMetodoPago,
                      estado: currentState.filtroEstado,
                    );
                  }
                },
              ), 
              tittle: 'Filtros Adicionales',
              allowButtons: false, 
              showButtoms: false,
            );
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