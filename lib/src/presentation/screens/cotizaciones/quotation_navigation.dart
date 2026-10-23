import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
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

  // Si lo que hay en curso es una venta normal, no tiene sentido preguntar
  // "continuar cotización": se reinicia directo en modo cotización.
  if (!ticketState.isQuotation) {
    resetAndNavigate();
    return;
  }

  // Si lo en curso es la edición de una cotización ya existente, "Nueva
  // cotización" debe forzar una creación nueva, nunca continuar esa edición.
  if (ticketState.isEdit) {
    resetAndNavigate();
    return;
  }

  if (!context.mounted) return;
  final continuar = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Venta en progreso',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
      ),
      content: const Text('Ya tienes una venta en curso. ¿Qué deseas hacer?'),
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
