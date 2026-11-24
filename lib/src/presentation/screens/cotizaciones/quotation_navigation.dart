import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/trabajo_en_curso_dialog.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/presentation/screens/dashboard/navigation/dashboard_navigation.dart';

Future<void> openNewQuotation(BuildContext context, WidgetRef ref) async {
  if (!dashboardAllows(ref.read(sesionProvider), 'VENTAS_CREAR')) return;
  final ticketState = ref.read(ticketProvider);
  final ticket = ticketState.ticket;
  final productState = ref.read(productSaleProvider);
  final customerState = ref.read(customerSaleProvider);

  final hasData =
      (ticket.items?.isNotEmpty ?? false) ||
      ticketState.isEdit ||
      productState.productsSales.isNotEmpty ||
      (customerState.customer.razonSocial?.isNotEmpty ?? false);

  void resetAndNavigate() {
    ref.invalidate(ticketProvider);
    ref.invalidate(productSaleProvider);
    ref.invalidate(customerSaleProvider);
    ref.read(ticketProvider.notifier).startNewQuotation();
    Get.toNamed(AppRoutes.productsSales);
  }

  if (!hasData) {
    ref.read(ticketProvider.notifier).startNewQuotation();
    Get.toNamed(AppRoutes.productsSales);
    return;
  }

  // Una venta o una edición en curso no se continúa como cotización nueva,
  // pero tampoco se descarta sin avisar: el usuario elige retomarla o descartarla.
  if (!ticketState.isQuotation || ticketState.isEdit) {
    if (!context.mounted) return;
    final decision = await preguntarTrabajoEnCurso(
      context,
      enCurso: describirEnCurso(
        esCotizacion: ticketState.isQuotation,
        esEdicion: ticketState.isEdit,
      ),
      productos: productState.productsSales.length,
      nuevo: 'una cotización nueva',
    );
    if (decision == DecisionEnCurso.retomar) {
      Get.toNamed(AppRoutes.productsSales);
    } else if (decision == DecisionEnCurso.descartar) {
      resetAndNavigate();
    }
    return;
  }

  if (!context.mounted) return;
  final continuar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Cotización en progreso',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: const Text('Ya tienes una cotización en curso. ¿Qué deseas hacer?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Nueva cotización'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorSchema.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Continuar'),
        ),
      ],
    ),
  );

  if (continuar == true) {
    Get.toNamed(AppRoutes.productsSales);
  } else if (continuar == false) {
    resetAndNavigate();
  }
}
