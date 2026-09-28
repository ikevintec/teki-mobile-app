import 'dart:async';
import 'package:flutter/material.dart' hide Table;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/restaurant_event.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/order_options_sheet.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/qr_command_review/qr_command_review_area.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/restaurant_table_palette.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/table_card.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/restaurant/restaurant_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/restaurant_events_service.dart';
import 'package:teki_app/src/shared/services/socket_service.dart';
import 'package:teki_app/src/utils/constants.dart';

class RestaurantMesasScreen extends ConsumerStatefulWidget {
  const RestaurantMesasScreen({super.key});

  @override
  ConsumerState<RestaurantMesasScreen> createState() =>
      _RestaurantMesasScreenState();
}

class _RestaurantMesasScreenState
    extends ConsumerState<RestaurantMesasScreen> {
  final _socketService = SocketService();
  late final RestaurantEventsService _restaurantEvents;

  @override
  void initState() {
    super.initState();

    _restaurantEvents = RestaurantEventsService(socketService: _socketService);
    _restaurantEvents.listen((event) {
      if (!mounted ||
          !event.belongsToOffice(ref.read(sesionProvider).office?.id) ||
          event.type == RestaurantEventType.onlineOrder) {
        return;
      }
      unawaited(_reload(silent: true));
    });

    Future.microtask(() {
      if (!mounted) return;
      final session = ref.read(sesionProvider);
      final pvId = session.office?.id;
      if (pvId != null) ref.read(restaurantProvider.notifier).loadData(pvId);
      _socketService.connect(officeCode: session.office?.codigo ?? 'PV001');
    });

    // If opened from a dish_desk_ready notification, navigate to the ready screen
    // after the first frame is rendered so mesas is visible underneath.
    final args = Get.arguments as Map<String, dynamic>?;
    final notifCommandId = args?['commandId'] as int?;
    final notifItemId = args?['itemId'] as int?;
    if (notifCommandId != null && notifItemId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Get.toNamed(
          AppRoutes.restaurantDishReady,
          arguments: {'commandId': notifCommandId, 'itemId': notifItemId},
        );
      });
    }
  }

  @override
  void dispose() {
    unawaited(_restaurantEvents.dispose());
    _socketService.disconnect();
    super.dispose();
  }

  /// Recarga rápida (socket): solo mesas + órdenes, conserva salones.
  Future<void> _reload({bool silent = false}) async {
    final pvId = ref.read(sesionProvider).office?.id;
    if (pvId != null) {
      await ref
          .read(restaurantProvider.notifier)
          .reload(pvId, silent: silent);
    }
  }

  /// Recarga completa desde salones (volver de ajustes / cambio de PV).
  void _reloadFull() {
    final pvId = ref.read(sesionProvider).office?.id;
    if (pvId != null) {
      ref.read(restaurantProvider.notifier).loadData(pvId);
    }
  }

  Future<void> _onTableTap(Table table) async {
    final order = table.pedidoActual;
    final tableId = table.id;

    // La llamada tiene prioridad. Si la mesa tampoco tiene mozo, el endpoint
    // de atender mesa resuelve ambos estados en una sola operación.
    if (tableId != null && table.llamadaEn != null) {
      await _offerAttendCall(table, order);
      return;
    }

    if (tableId != null && order?.sinMozoAsignado == true) {
      await _offerTakeTable(table);
      return;
    }

    if (order != null && order.id != null) {
      OrderOptionsSheet.show(context, order);
    } else {
      Get.toNamed(
        AppRoutes.restaurantComanda,
        arguments: {'table': table},
      )?.then((_) => _reload());
    }
  }

  Future<void> _offerAttendCall(
    Table table,
    OrderRestaurant? order,
  ) async {
    final alsoTakesOwnership = order?.sinMozoAsignado == true;
    final confirmed = await _confirmTableAttention(
      title: 'Mesa ${table.numero ?? table.id} está llamando',
      message: alsoTakesOwnership
          ? 'El comensal llamó al camarero y este pedido entró por el QR sin que nadie lo atienda. '
              '¿Vas tú? Quedarás como responsable de la mesa.'
          : 'El comensal llamó al camarero. ¿Vas tú a atenderla?',
      icon: Icons.notifications_active_rounded,
      iconColor: const Color(0xFFB91C1C),
      acceptLabel: 'Voy yo',
    );
    if (!confirmed || !mounted || table.id == null) return;

    await ref.read(restaurantProvider.notifier).atenderLlamada(
          table.id!,
          takeOwnership: alsoTakesOwnership,
        );
  }

  Future<void> _offerTakeTable(Table table) async {
    final confirmed = await _confirmTableAttention(
      title: 'Mesa ${table.numero ?? table.id}',
      message: 'Este pedido entró por el QR y todavía no lo atiende nadie. '
          '¿Quieres hacerte responsable de la mesa?',
      icon: Icons.person_add_alt_1_rounded,
      iconColor: const Color(0xFF1D4ED8),
      acceptLabel: 'Sí, la atiendo',
    );
    if (!confirmed || !mounted || table.id == null) return;

    await ref.read(restaurantProvider.notifier).atenderMesa(table.id!);
  }

  Future<bool> _confirmTableAttention({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required String acceptLabel,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 10),
        contentPadding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.raleway(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: ColorSchema.titleTextColor,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: GoogleFonts.roboto(
            fontSize: 13,
            height: 1.4,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.black54,
              textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w600),
            ),
            child: const Text('Ahora no'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: iconColor,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(acceptLabel),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  List<String> _mesasConTodosItemsAnulados(List<OrderRestaurant> orders) {
    final result = <String>[];
    for (final order in orders) {
      final allItems = (order.comandas ?? [])
          .expand((c) => c.items ?? [])
          .toList();
      if (allItems.isEmpty) continue;
      final todosCancelados = allItems.every(
        (item) =>
            item.eliminado == true ||
            const {'CANCELADO', 'RECHAZADO'}.contains(
              item.estadoComandaDetalle?.toUpperCase(),
            ),
      );
      if (todosCancelados) {
        final numero = order.mesa?.numero?.toString() ??
            order.mesa?.id?.toString();
        if (numero != null) result.add(numero);
      }
    }
    return result;
  }

  List<String> _mesasConItemsSinCuenta(List<OrderRestaurant> orders) {
    final result = <String>[];
    for (final order in orders) {
      if (order.estado != 'PRECUENTA') continue;
      final hasSinCuenta = (order.comandas ?? []).any(
        (c) => (c.items ?? []).any(
          (item) =>
              item.cuenta == null &&
              !const {'CANCELADO', 'RECHAZADO'}.contains(
                item.estadoComandaDetalle?.toUpperCase(),
              ),
        ),
      );
      if (hasSinCuenta) {
        final numero = order.mesa?.numero?.toString() ?? order.mesa?.id?.toString();
        if (numero != null) result.add(numero);
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sesionProvider, (prev, next) {
      if (next.office?.id != prev?.office?.id) _reloadFull();
    });

    final state = ref.watch(restaurantProvider);
    final notifier = ref.read(restaurantProvider.notifier);
    final tables = notifier.tablesWithOrders;
    final mesasSinCuenta = _mesasConItemsSinCuenta(state.orders);
    final mesasTodosAnulados = _mesasConTodosItemsAnulados(state.orders);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: ColorSchema.primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Restaurante - Mesas',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: 'Ajustes',
            onPressed: () async {
              await Get.toNamed(AppRoutes.settings);
              if (mounted) _reloadFull();
            },
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
          ),
        ],
      ),
      bottomNavigationBar: const SafeArea(
        child: _StatusLegend(),
      ),
      floatingActionButton: const QrCommandReviewArea(),
      body: state.isLoading && state.lounges.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: ColorSchema.primaryColor),
            )
          : Column(
              children: [
                if (mesasSinCuenta.isNotEmpty)
                  _WarningBanner(mesas: mesasSinCuenta),
                if (mesasTodosAnulados.isNotEmpty)
                  _AllCancelledBanner(mesas: mesasTodosAnulados),
                if (state.lounges.isNotEmpty)
                  _LoungeTabBar(
                    lounges: state.lounges,
                    selectedId: state.selectedLoungeId,
                    onSelect: (id) => ref
                        .read(restaurantProvider.notifier)
                        .selectLounge(id),
                    onSelectAll: () => ref
                        .read(restaurantProvider.notifier)
                        .selectAll(),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    color: ColorSchema.primaryColor,
                    onRefresh: () async => _reload(),
                    child: state.isLoading && tables.isEmpty
                        ? const Center(
                            child: CircularProgressIndicator(
                                color: ColorSchema.primaryColor),
                          )
                        : tables.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: const [
                                  SizedBox(height: 80),
                                  Center(
                                    child: Text(
                                      'No hay mesas en este salón',
                                      style: TextStyle(
                                          color: Colors.grey, fontSize: 14),
                                    ),
                                  ),
                                ],
                              )
                            : GridView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.05,
                                ),
                                itemCount: tables.length,
                                itemBuilder: (_, i) => TableCard(
                                  table: tables[i],
                                  onTap: () => unawaited(_onTableTap(tables[i])),
                                  showLounge: state.selectedLoungeId == RestaurantState.kAllSelected,
                                ),
                              ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatusLegend extends StatelessWidget {
  const _StatusLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 14, bottom: 0),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _LegendItem(
            color: RestaurantTablePalette.free,
            textColor: RestaurantTablePalette.legendText,
            label: 'Libre',
          ),
          SizedBox(width: 20),
          _LegendItem(
            color: RestaurantTablePalette.order,
            textColor: RestaurantTablePalette.legendText,
            label: 'Pedido',
          ),
          SizedBox(width: 20),
          _LegendItem(
            color: RestaurantTablePalette.prepared,
            textColor: RestaurantTablePalette.legendText,
            label: 'Preparado',
          ),
          SizedBox(width: 20),
          _LegendItem(
            color: RestaurantTablePalette.paying,
            textColor: RestaurantTablePalette.legendText,
            label: 'Pagando',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final Color textColor;
  final String label;

  const _LegendItem({
    required this.color,
    required this.textColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: color),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _WarningBanner extends StatelessWidget {
  final List<String> mesas;

  const _WarningBanner({required this.mesas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFF3CD),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFF856404), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Advertencia: La mesa ${mesas.join(', ')} tiene pedidos sin pre cuenta y/o sin pagar.',
              style: const TextStyle(
                color: Color(0xFF856404),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AllCancelledBanner extends StatelessWidget {
  final List<String> mesas;

  const _AllCancelledBanner({required this.mesas});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFFE0E0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, color: Color(0xFFC62828), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Atención: La mesa ${mesas.join(', ')} tiene todos sus items anulados.',
              style: const TextStyle(
                color: Color(0xFFC62828),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoungeTabBar extends StatelessWidget {
  final List<dynamic> lounges;
  final int selectedId;
  final ValueChanged<int> onSelect;
  final VoidCallback onSelectAll;

  const _LoungeTabBar({
    required this.lounges,
    required this.selectedId,
    required this.onSelect,
    required this.onSelectAll,
  });

  @override
  Widget build(BuildContext context) {
    final isAllSelected = selectedId == RestaurantState.kAllSelected;

    final chips = <Widget>[
      GestureDetector(
        onTap: onSelectAll,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: isAllSelected ? ColorSchema.primaryColor : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Todos',
            style: TextStyle(
              color: isAllSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
      ...lounges.map((lounge) {
        final isSelected = lounge.id == selectedId;
        return GestureDetector(
          onTap: () => onSelect(lounge.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? ColorSchema.primaryColor : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              lounge.nombre ?? 'Salón',
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        );
      }),
    ];

    return Container(
      color: Colors.white,
      height: 48,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.of(context).size.width - 24,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: chips,
          ),
        ),
      ),
    );
  }
}
