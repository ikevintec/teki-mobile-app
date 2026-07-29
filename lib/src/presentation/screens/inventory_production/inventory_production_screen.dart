import 'package:flutter/material.dart';
import 'package:teki_app/src/presentation/widgets/floating_action_button/custom_floating_action_button.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_production.dart';
import 'package:teki_app/src/presentation/screens/inventory_production/create_production_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/inventory_production/inventory_production_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';

class InventoryProductionScreen extends ConsumerStatefulWidget {
  const InventoryProductionScreen({super.key});

  @override
  ConsumerState<InventoryProductionScreen> createState() =>
      _InventoryProductionScreenState();
}

class _InventoryProductionScreenState
    extends ConsumerState<InventoryProductionScreen> {
  final _scrollController = ScrollController();
  static final _fmtFecha = DateFormat('dd/MM/yyyy hh:mm a', 'es_PE');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(inventoryProductionListProvider.notifier).loadFirstPage();
    });
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(inventoryProductionListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _crearNueva() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CreateProductionScreen()),
    );
  }

  Future<void> _anular(InventoryProduction order) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Anular producción'),
        content: Text(
            '¿Anular la orden #${order.numero}? Se revertirán los movimientos de inventario.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('No')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Anular')),
        ],
      ),
    );
    if (confirmar != true) return;
    try {
      await ref
          .read(inventoryProductionListProvider.notifier)
          .voidOrder(order.id!);
      successNotification('Orden anulada', fromTop: false);
    } catch (e) {
      errorNotification(e.toString(), fromTop: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryProductionListProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Órdenes de producción'),
      ),
      floatingActionButton: CustomFloatingActionButton(
        buttonName: 'Nueva',
        onPressed: _crearNueva,
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(inventoryProductionListProvider.notifier).refresh(),
        child: state.loading && state.orders.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.orders.isEmpty
                ? _emptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
                    itemCount: state.orders.length + (state.hasMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i >= state.orders.length) {
                        return const Padding(
                          padding: EdgeInsets.all(16),
                          child: Center(
                              child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))),
                        );
                      }
                      return _orderCard(state.orders[i]);
                    },
                  ),
      ),
    );
  }

  Widget _emptyState() {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.precision_manufacturing_outlined,
            size: 54, color: Colors.grey.shade400),
        const SizedBox(height: 12),
        Center(
          child: Text('No hay órdenes de producción',
              style: TextStyle(color: Colors.grey.shade500)),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text('Desliza hacia abajo para actualizar',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _orderCard(InventoryProduction order) {
    final anulado = order.anulado == true;
    final totalItems = order.producciones.fold<double>(
        0, (s, d) => s + (d.cantidad ?? 0));
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          title: Row(
            children: [
              Icon(Icons.precision_manufacturing_outlined,
                  size: 20, color: ColorSchema.primaryColor),
              const SizedBox(width: 8),
              Text('Producción #${order.numero ?? '-'}',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w700, fontSize: 14)),
              const Spacer(),
              if (anulado)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFCDD2),
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('ANULADO',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFC63737))),
                ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '${order.fecha != null ? _fmtFecha.format(order.fecha!) : '-'} · '
              '${order.producciones.length} producto(s)'
              '${totalItems > 0 ? ' · ${_qty(totalItems)} und' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
          children: [
            if ((order.observacion ?? '').isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Obs.: ${order.observacion}',
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey.shade600)),
              ),
              const SizedBox(height: 6),
            ],
            ...order.producciones.map((d) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(
                            '${_qty(d.cantidad ?? 0)} ${d.producto?.unidad?.abreviatura ?? ''}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(d.producto?.nombre ?? '-',
                              style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                )),
            if (!anulado) ...[
              const Divider(height: 18),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => _anular(order),
                  icon: Icon(Icons.block, size: 16, color: Colors.red.shade400),
                  label: Text('Anular',
                      style: TextStyle(color: Colors.red.shade400)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
