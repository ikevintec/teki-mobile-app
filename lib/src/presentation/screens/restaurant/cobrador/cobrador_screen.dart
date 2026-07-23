import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/providers/restaurant/check_totals.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/cobrador_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'widgets/cobrador_filter_bar.dart';
import 'widgets/check_list_widget.dart';

class CobradorScreen extends ConsumerStatefulWidget {
  final int pvId;

  const CobradorScreen({super.key, required this.pvId});

  @override
  ConsumerState<CobradorScreen> createState() => _CobradorScreenState();
}

class _CobradorScreenState extends ConsumerState<CobradorScreen> {
  late int _currentPvId;

  @override
  void initState() {
    super.initState();
    _currentPvId = widget.pvId;
    Future.microtask(() {
      if (!mounted) return;
      ref.read(cobradorProvider.notifier).init(_currentPvId);
    });
  }

  void _reload() {
    ref.read(cobradorProvider.notifier).init(_currentPvId);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(sesionProvider).hasPermission('RESTAURANTE_COBRADOR_VER')) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cobrador')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline_rounded,
                    color: Colors.grey.shade400, size: 44),
                const SizedBox(height: 12),
                Text(
                  'No tienes permisos para ver el cobrador',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 14, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      );
    }
    ref.listen(sesionProvider, (prev, next) {
      final newPvId = next.office?.id;
      if (newPvId != null && newPvId != prev?.office?.id) {
        setState(() => _currentPvId = newPvId);
        ref.read(cobradorProvider.notifier).init(newPvId);
      }
    });

    final state = ref.watch(cobradorProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Cobrador',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () async {
              await Get.toNamed(AppRoutes.settings);
              if (mounted) _reload();
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
      body: Column(
        children: [
          CobradorFilterBar(pvId: _currentPvId),
          Expanded(
            child: CheckListWidget(
              pvId: _currentPvId,
              checks: state.checks,
              isLoading: state.isLoading,
              onTap: _showCheckDetail,
            ),
          ),
        ],
      ),
    );
  }

  void _showCheckDetail(Check check, int index) {
    final items = check.items ?? [];
    final total = checkItemsTotal(items);
    final hasMesa = check.pedido?.mesa != null;
    final title = hasMesa
        ? 'Mesa ${check.pedido?.mesa?.numero} · Cuenta ${index + 1}'
        : 'Cuenta ${index + 1}';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView.builder(
                shrinkWrap: true,
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final d = items[i];
                  return ListTile(
                    dense: true,
                    title: Text(d.producto?.nombre ?? '-'),
                    trailing: Text(
                      'x${d.cantidad?.toInt() ?? 1}  S/. ${((d.precioVenta ?? 0) * (d.cantidad ?? 1)).toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  );
                },
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    'S/. ${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.receipt_long, size: 18),
            label: const Text('Emitir Comprobante'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => _emitirComprobante(check),
          ),
        ],
      ),
    );
  }

  Future<void> _emitirComprobante(Check check) async {
    Navigator.pop(context); // cerrar el dialog
    if (check.id == null) return;

    try {
      // Cargar el check completo desde el backend para obtener todos los items
      final fullCheck =
          await ref.read(cobradorProvider.notifier).getCheckById(check.id!);

      // Pre-llenar los providers de venta con los datos del check
      await ref
          .read(productSaleProvider.notifier)
          .initFromCheck(fullCheck);

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProductsSaleScreen()),
      );
    } catch (e) {
      errorNotification('Error al cargar la cuenta: $e');
    }
  }
}
