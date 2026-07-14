import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/presentation/screens/inventory/widgets/inventory_movements_sheet.dart';
import 'package:teki_app/src/providers/inventory/inventory_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class InventoryListSection extends ConsumerStatefulWidget {
  final List<Inventory> items;

  const InventoryListSection({super.key, required this.items});

  @override
  ConsumerState<InventoryListSection> createState() =>
      _InventoryListSectionState();
}

class _InventoryListSectionState extends ConsumerState<InventoryListSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    Future.microtask(() {
      if (!ref.read(inventoryProvider).isLoading) {
        ref.read(inventoryProvider.notifier).loadNextPage();
      }
    });
  }

  void _openMovementsSheet(Inventory inventory) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.75,
        child: InventoryMovementsSheet(inventory: inventory),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = ref.watch(inventoryProvider).last;

    if (widget.items.isEmpty) {
      return ListView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Center(
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  'No se encontraron ítems de inventario',
                  style: GoogleFonts.raleway(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF333333),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.zero,
      itemCount: widget.items.length + 1,
      itemBuilder: (context, index) {
        if (index == widget.items.length) {
          if (isLast) {
            return const SizedBox(
              height: 50,
              child: Center(
                child: Text(
                  'No hay más ítems',
                  style: TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ),
            );
          } else {
            _loadMore();
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: ColorSchema.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            );
          }
        }

        final item = widget.items[index];
        return _InventoryCard(
          inventory: item,
          onMovementsPressed: () => _openMovementsSheet(item),
          onAdjustPressed: item.producto != null
              ? () async {
                  await Get.toNamed(
                    AppRoutes.inventoryAdjustmentCreate,
                    arguments: {'inventory': item},
                  );
                  if (!mounted) return;
                  final idPuntoVenta = ref.read(inventoryProvider).idPuntoVenta;
                  if (idPuntoVenta != null) {
                    ref
                        .read(inventoryProvider.notifier)
                        .loadInventory(idPuntoVenta);
                  }
                }
              : null,
        );
      },
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final Inventory inventory;
  final VoidCallback onMovementsPressed;
  final VoidCallback? onAdjustPressed;

  const _InventoryCard({
    required this.inventory,
    required this.onMovementsPressed,
    this.onAdjustPressed,
  });

  @override
  Widget build(BuildContext context) {
    final stock = inventory.stock ?? 0;

    final fechaActualizacion = inventory.fechaActualizacion != null
        ? DateFormat('dd/MM/yy HH:mm').format(inventory.fechaActualizacion!)
        : null;

    return Card(
      elevation: 0.1,
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Imagen del producto
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 52,
                height: 52,
                child: () {
                  final url = inventory.producto?.imagenPorDefecto?.imagen;
                  if (url != null && url.isNotEmpty) {
                    return Image.network(
                      url,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Image.asset(
                          'assets/images/gif/loader.gif',
                          fit: BoxFit.cover,
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          Image.asset(
                        'assets/images/products/icon.png',
                        fit: BoxFit.contain,
                      ),
                    );
                  }
                  return Image.asset(
                    'assets/images/products/icon.png',
                    fit: BoxFit.contain,
                  );
                }(),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    inventory.producto?.nombre ?? '-',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (fechaActualizacion != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Act: $fechaActualizacion',
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: Colors.black38),
                    ),
                  ],
                ],
              ),
            ),
            // Stock + botones apilados
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stock destacado
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      formatDouble(stock),
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.black54,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      inventory.producto?.unidad?.abreviatura?.isNotEmpty == true
                          ? inventory.producto!.unidad!.abreviatura!
                          : inventory.producto?.unidad?.codigo?.isNotEmpty == true
                          ? inventory.producto!.unidad!.codigo!
                          : '',
                      style: GoogleFonts.roboto(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Colors.black38,
                      ),
                    ),
                  ],
                ),
                // Botones
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'Ver historial',
                      onPressed: onMovementsPressed,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: Icon(
                        Icons.sync_alt_rounded,
                        size: 24,
                        color: ColorSchema.primaryColor.withValues(alpha: 0.8),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ajustar inventario',
                      onPressed: onAdjustPressed,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      icon: Icon(
                        Icons.edit_note_rounded,
                        size: 28,
                        color: onAdjustPressed != null
                            ? ColorSchema.primaryColor.withValues(alpha: 0.8)
                            : Colors.black26,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
