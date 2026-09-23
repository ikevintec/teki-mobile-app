import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/response/inventory_sync_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/presentation/screens/inventory_adjustment/inventory_adjustment_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/inventory/inventory_provider.dart';
import 'package:teki_app/src/providers/inventory/inventory_sync_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class InventorySyncAction extends ConsumerWidget {
  final int idPuntoVenta;

  const InventorySyncAction({super.key, required this.idPuntoVenta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (idPuntoVenta <= 0) return const SizedBox.shrink();
    final state = ref.watch(inventorySyncProvider(idPuntoVenta));
    final total = state.badgeSummary.total;
    if (!state.badgeLoaded || total <= 0) return const SizedBox.shrink();

    // Barra compacta alineada a la derecha, bajo el buscador. Se colapsa sola
    // (SizedBox.shrink) cuando no hay diferencias, así no ocupa espacio.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 6),
      child: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          onPressed: () => _openSheet(context),
          icon: const Icon(Icons.sync_problem_rounded, size: 18),
          label: Text(
            'Corregir ($total)',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFF57C00),
            foregroundColor: Colors.white,
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            visualDensity: VisualDensity.compact,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) => InventorySyncSheet(idPuntoVenta: idPuntoVenta),
    );
  }
}

class InventorySyncSheet extends ConsumerStatefulWidget {
  final int idPuntoVenta;

  const InventorySyncSheet({super.key, required this.idPuntoVenta});

  @override
  ConsumerState<InventorySyncSheet> createState() => _InventorySyncSheetState();
}

class _InventorySyncSheetState extends ConsumerState<InventorySyncSheet> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _searchDebounce;
  int? _openingInventoryId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      if (mounted) {
        ref
            .read(inventorySyncProvider(widget.idPuntoVenta).notifier)
            .openPanel();
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter > 240) return;
    ref
        .read(inventorySyncProvider(widget.idPuntoVenta).notifier)
        .loadIssues(reset: false);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      ref
          .read(inventorySyncProvider(widget.idPuntoVenta).notifier)
          .setSearch(value);
    });
  }

  Future<void> _refreshInventoryList() async {
    final inventory = ref.read(inventoryProvider);
    await ref
        .read(inventoryProvider.notifier)
        .searchInventory(
          inventory.filterGlobal ?? '',
          idPuntoVenta: widget.idPuntoVenta,
        );
  }

  Future<void> _regularize() async {
    final notifier = ref.read(
      inventorySyncProvider(widget.idPuntoVenta).notifier,
    );
    InventorySyncFixBatch batch;
    try {
      batch = await notifier.prepareFixBatch();
    } catch (error) {
      errorNotification(_errorText(error));
      return;
    }
    if (!mounted || batch.ids.isEmpty) return;

    final zeroWarning = batch.zeroStockWarnings > 0
        ? '\n\nAtención: ${batch.zeroStockWarnings} '
              '${batch.zeroStockWarnings == 1 ? 'producto quedará' : 'productos quedarán'} '
              'con stock 0 porque no tienen series o lotes registrados.'
        : '';
    final batchWarning = batch.hasMore
        ? '\n\nSe corregirán ${batch.ids.length} de ${batch.requestedTotal}. '
              'Luego podrá continuar con la siguiente tanda.'
        : '';

    final accepted = await showDialog<bool>(
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
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.sync_problem_rounded,
                color: Colors.orange.shade800,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Regularizar inventario',
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
          'El stock quedará igual al conteo de series/lotes en '
          '${batch.ids.length} ${batch.ids.length == 1 ? 'producto' : 'productos'}. '
          'El cambio quedará registrado en el kardex.$zeroWarning$batchWarning',
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
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              textStyle: GoogleFonts.roboto(fontWeight: FontWeight.w700),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Regularizar'),
          ),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    try {
      final result = await notifier.fixBatch(batch.ids);
      await _refreshInventoryList();
      if (!mounted) return;
      if (result.corregidos > 0) {
        successNotification(
          '${result.corregidos} '
          '${result.corregidos == 1 ? 'producto corregido' : 'productos corregidos'}',
        );
      } else {
        infoNotification('No hubo diferencias que corregir');
      }
      if (result.errores.isNotEmpty) {
        warningNotification(
          result.errores.take(3).join('\n'),
          duration: const Duration(seconds: 6),
        );
      }
    } catch (error) {
      errorNotification(_errorText(error));
    }
  }

  Future<void> _adjustSeries(InventorySyncIssue issue) async {
    if (_openingInventoryId != null) return;
    setState(() => _openingInventoryId = issue.idInventory);
    try {
      final product = await ProductsRepositoryImpl().getProductById(
        issue.idProducto,
      );
      final found = product.inventarios
          ?.where((inventory) => inventory.id == issue.idInventory)
          .firstOrNull;
      if (found == null) {
        warningNotification(
          'No se encontró el inventario del producto. Actualice e inténtelo nuevamente.',
        );
        return;
      }
      final inventory = _inventoryWithProduct(found, product);
      if (!mounted) return;
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => InventoryAdjustmentScreen(
            preSelectedInventory: inventory,
            allowUnchangedStockWithLotes: true,
          ),
        ),
      );
      if (changed == true && mounted) {
        await ref
            .read(inventorySyncProvider(widget.idPuntoVenta).notifier)
            .refreshAfterCorrection();
        await _refreshInventoryList();
      }
    } catch (error) {
      errorNotification(_errorText(error));
    } finally {
      if (mounted) setState(() => _openingInventoryId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = inventorySyncProvider(widget.idPuntoVenta);
    final state = ref.watch(provider);
    final canAdjust = ref
        .watch(sesionProvider)
        .hasPermission('INVENTARIO_AJUSTAR');
    final officeName = ref.watch(sesionProvider).office?.nombre ?? 'Esta sede';

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.92,
      child: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 8, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sync_problem_rounded,
                    color: Colors.orange.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock por corregir',
                        style: GoogleFonts.raleway(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Diferencias con sus series o lotes',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          _SummaryRow(summary: state.panelSummary),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    _segmentChip(
                      label: officeName,
                      selected: state.currentOfficeOnly,
                      onTap: () => ref
                          .read(provider.notifier)
                          .setCurrentOfficeOnly(true),
                    ),
                    const SizedBox(width: 8),
                    _segmentChip(
                      label: 'Todas las sedes',
                      selected: !state.currentOfficeOnly,
                      onTap: () => ref
                          .read(provider.notifier)
                          .setCurrentOfficeOnly(false),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar por producto o código',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                              ref.read(provider.notifier).setSearch('');
                            },
                          ),
                    isDense: true,
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                state.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          Expanded(
            child: ColoredBox(
              color: Colors.grey.shade100,
              child: _buildIssues(state, canAdjust),
            ),
          ),
          if (canAdjust && state.totalRecords > 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: FilledButton.icon(
                  onPressed: state.isFixing ? null : _regularize,
                  icon: state.isFixing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    state.selectedIds.isEmpty
                        ? 'Regularizar ${state.totalRecords.clamp(0, inventorySyncMaxBatch)}'
                        : 'Regularizar ${state.selectedIds.length.clamp(0, inventorySyncMaxBatch)} seleccionados',
                  ),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                    backgroundColor: ColorSchema.primaryColor,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Chip de segmento con el estilo del sistema (ver `_buildFiltros`).
  Widget _segmentChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? ColorSchema.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? ColorSchema.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey.shade700,
          ),
        ),
      ),
    );
  }

  Widget _buildIssues(InventorySyncState state, bool canAdjust) {
    if (state.isLoadingIssues && state.issues.isEmpty) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (state.issues.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 54,
              color: Colors.green.shade400,
            ),
            const SizedBox(height: 10),
            const Text(
              'Todo cuadra',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'El stock coincide con las series y lotes registrados.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await ref
            .read(inventorySyncProvider(widget.idPuntoVenta).notifier)
            .refreshAfterCorrection();
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
        itemCount: state.issues.length + (state.last ? 0 : 1),
        itemBuilder: (context, index) {
          if (index == state.issues.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final issue = state.issues[index];
          return _IssueCard(
            issue: issue,
            canAdjust: canAdjust,
            selected: state.selectedIds.contains(issue.idInventory),
            opening: _openingInventoryId == issue.idInventory,
            onSelected: () => ref
                .read(inventorySyncProvider(widget.idPuntoVenta).notifier)
                .toggleSelection(issue.idInventory),
            onAdjust: () => _adjustSeries(issue),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final InventorySyncSummary summary;

  const _SummaryRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _SummaryItem(value: '${summary.total}', label: 'inventarios'),
          const SizedBox(width: 8),
          _SummaryItem(value: '${summary.productos}', label: 'productos'),
          const SizedBox(width: 8),
          _SummaryItem(
            value: formatDouble(summary.unidades),
            label: 'unidades',
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String value;
  final String label;

  const _SummaryItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.raleway(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: ColorSchema.primaryColor,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.roboto(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  final InventorySyncIssue issue;
  final bool canAdjust;
  final bool selected;
  final bool opening;
  final VoidCallback onSelected;
  final VoidCallback onAdjust;

  const _IssueCard({
    required this.issue,
    required this.canAdjust,
    required this.selected,
    required this.opening,
    required this.onSelected,
    required this.onAdjust,
  });

  @override
  Widget build(BuildContext context) {
    final missing = issue.diferencia > 0;
    final amount = formatDouble(issue.diferencia.abs());
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black.withValues(alpha: 0.15),
      color: selected ? const Color(0xFFF4F7FE) : Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? ColorSchema.primaryColor : Colors.grey.shade200,
        ),
      ),
      child: InkWell(
        onTap: canAdjust ? onSelected : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canAdjust)
                    Checkbox(
                      value: selected,
                      onChanged: (_) => onSelected(),
                      visualDensity: VisualDensity.compact,
                      activeColor: ColorSchema.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          issue.producto,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.raleway(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          [
                            if (issue.codigoProducto?.isNotEmpty == true)
                              issue.codigoProducto!,
                            if (issue.puntoVenta?.isNotEmpty == true)
                              issue.puntoVenta!,
                            issue.tipoLote == 'SERIE' ? 'Series' : 'Lotes',
                          ].join(' · '),
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canAdjust)
                    TextButton(
                      onPressed: opening ? null : onAdjust,
                      style: TextButton.styleFrom(
                        foregroundColor: ColorSchema.primaryColor,
                        textStyle: GoogleFonts.roboto(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: opening
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: ColorSchema.primaryColor,
                              ),
                            )
                          : Text(
                              issue.tipoLote == 'SERIE'
                                  ? 'Ajustar series'
                                  : 'Ajustar lotes',
                            ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _ValueColumn(
                      label: 'Stock',
                      value: formatDouble(issue.stock),
                    ),
                  ),
                  Expanded(
                    child: _ValueColumn(
                      label: 'Series/lotes',
                      value: formatDouble(issue.cantidadLotes),
                    ),
                  ),
                  Expanded(
                    child: _ValueColumn(
                      label: 'Diferencia',
                      value: missing ? 'Faltan $amount' : 'Sobran $amount',
                      color: Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
              if (issue.lotesNegativos > 0 || issue.quedariaEnCero) ...[
                const SizedBox(height: 8),
                Text(
                  issue.quedariaEnCero
                      ? 'El stock quedará en 0: no hay series/lotes registrados.'
                      : '${issue.lotesNegativos} series/lotes tienen saldo negativo.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ValueColumn extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _ValueColumn({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(fontSize: 10, color: Colors.black45),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color ?? Colors.black87,
          ),
        ),
      ],
    );
  }
}

Inventory _inventoryWithProduct(Inventory inventory, Product product) =>
    Inventory(
      id: inventory.id,
      puntoVenta: inventory.puntoVenta,
      producto: product,
      stock: inventory.stock,
      stockAnterior: inventory.stockAnterior,
      usuarioActualizacion: inventory.usuarioActualizacion,
      fechaActualizacion: inventory.fechaActualizacion,
      registros: inventory.registros,
      lotes: inventory.lotes,
      empresa: inventory.empresa,
    );

String _errorText(Object error) =>
    error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
