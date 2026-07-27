import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/providers/inventory/inventory_logs_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class InventoryMovementsSheet extends ConsumerStatefulWidget {
  final Inventory inventory;

  const InventoryMovementsSheet({super.key, required this.inventory});

  @override
  ConsumerState<InventoryMovementsSheet> createState() =>
      _InventoryMovementsSheetState();
}

class _InventoryMovementsSheetState
    extends ConsumerState<InventoryMovementsSheet> {
  late final ScrollController _scrollController;
  int _activeTab = 0; // 0 = Movimientos, 1 = Lotes
  BatchProduct? _selectedLote;

  bool get _inLoteDetail => _selectedLote != null;
  bool get _hasLotes => widget.inventory.lotes?.isNotEmpty ?? false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    Future.microtask(() {
      ref
          .read(inventoryLogsProvider(widget.inventory.id!).notifier)
          .loadLogs();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMore() {
    Future.microtask(() {
      ref
          .read(inventoryLogsProvider(widget.inventory.id!).notifier)
          .loadNextPage();
    });
  }

  String _loteName(BatchProduct lote) {
    if (lote.tipoLote == 'SERIE' &&
        lote.serie != null &&
        lote.serie!.isNotEmpty) {
      return lote.serie!;
    }
    if (lote.fechaVencimiento != null) {
      return 'Lote · Vence ${DateFormat('dd/MM/yy').format(lote.fechaVencimiento!)}';
    }
    if (lote.fechaFabricacion != null) {
      return 'Lote · ${DateFormat('dd/MM/yy').format(lote.fechaFabricacion!)}';
    }
    return 'Lote #${lote.id ?? ''}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inventoryLogsProvider(widget.inventory.id!));
    final productName = widget.inventory.producto?.nombre ?? 'Movimientos';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 8, 4),
            child: Row(
              children: [
                if (_inLoteDetail)
                  GestureDetector(
                    onTap: () => setState(() => _selectedLote = null),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 15,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _inLoteDetail
                            ? _loteName(_selectedLote!)
                            : 'Movimientos',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _inLoteDetail
                            ? 'Historial · $productName'
                            : productName,
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: Colors.black45,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),

          // Tab bar con underline animado (oculto en detalle de lote)
          if (!_inLoteDetail && _hasLotes)
            _TabBar(
              activeIndex: _activeTab,
              onTap: (i) => setState(() => _activeTab = i),
            )
          else
            const Divider(height: 1),

          // Contenido
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildContent(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(dynamic state) {
    if (_inLoteDetail) {
      return _LoteMovementsView(
        key: ValueKey('lote_${_selectedLote!.id}'),
        lote: _selectedLote!,
      );
    }
    if (_activeTab == 1) {
      return _LotesListView(
        key: const ValueKey('lotes'),
        lotes: widget.inventory.lotes ?? [],
        loteName: _loteName,
        onTap: (lote) => setState(() => _selectedLote = lote),
      );
    }
    return _MovementsListView(
      key: const ValueKey('movements'),
      state: state,
      scrollController: _scrollController,
      onLoadMore: _loadMore,
    );
  }
}

// ─── Tab bar con underline animado ─────────────────────────────────────────

class _TabBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _TabBar({required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _TabButton(
              label: 'Movimientos',
              icon: Icons.swap_vert_rounded,
              active: activeIndex == 0,
              onTap: () => onTap(0),
            ),
            _TabButton(
              label: 'Lotes',
              icon: Icons.layers_outlined,
              active: activeIndex == 1,
              onTap: () => onTap(1),
            ),
          ],
        ),
        // Indicador deslizante
        Stack(
          children: [
            Container(height: 2, color: Colors.grey.shade100),
            AnimatedAlign(
              alignment: activeIndex == 0
                  ? Alignment.centerLeft
                  : Alignment.centerRight,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: FractionallySizedBox(
                widthFactor: 0.5,
                child: Container(
                  height: 2,
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 180),
          style: GoogleFonts.roboto(
            fontSize: 13,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active ? ColorSchema.primaryColor : Colors.black45,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 15,
                  color: active ? ColorSchema.primaryColor : Colors.black38,
                ),
                const SizedBox(width: 6),
                Text(label),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Vista movimientos del producto ────────────────────────────────────────

class _MovementsListView extends StatelessWidget {
  final dynamic state;
  final ScrollController scrollController;
  final VoidCallback onLoadMore;

  const _MovementsListView({
    super.key,
    required this.state,
    required this.scrollController,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.logs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
            color: ColorSchema.primaryColor, strokeWidth: 2),
      );
    }
    if (state.logs.isEmpty) {
      return Center(
        child: Text('Sin movimientos registrados',
            style: GoogleFonts.roboto(color: Colors.black45)),
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: state.logs.length + 1,
      itemBuilder: (context, index) {
        if (index == state.logs.length) {
          if (state.last) {
            return const SizedBox(
              height: 40,
              child: Center(
                child: Text('No hay más movimientos',
                    style: TextStyle(color: Colors.black38, fontSize: 12)),
              ),
            );
          } else {
            onLoadMore();
            return const Padding(
              padding: EdgeInsets.all(12),
              child: Center(
                child: CircularProgressIndicator(
                    color: ColorSchema.primaryColor, strokeWidth: 2),
              ),
            );
          }
        }
        return _LogItem(record: state.logs[index]);
      },
    );
  }
}

// ─── Vista lista de lotes ───────────────────────────────────────────────────

class _LotesListView extends StatelessWidget {
  final List<BatchProduct> lotes;
  final String Function(BatchProduct) loteName;
  final ValueChanged<BatchProduct> onTap;

  const _LotesListView({
    super.key,
    required this.lotes,
    required this.loteName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (lotes.isEmpty) {
      return Center(
        child: Text('Sin lotes registrados',
            style: GoogleFonts.roboto(color: Colors.black45)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: lotes.length,
      itemBuilder: (context, i) => _LoteCard(
        lote: lotes[i],
        name: loteName(lotes[i]),
        onTap: () => onTap(lotes[i]),
      ),
    );
  }
}

class _LoteCard extends StatelessWidget {
  final BatchProduct lote;
  final String name;
  final VoidCallback onTap;

  const _LoteCard({
    required this.lote,
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSerie = lote.tipoLote == 'SERIE';
    final accentColor =
        isSerie ? Colors.purple.shade400 : ColorSchema.primaryColor;
    final stock = lote.cantidad ?? 0;
    final stockColor = stock <= 0
        ? Colors.red
        : stock < 3
            ? Colors.orange
            : Colors.green;
    final hasMovements = lote.registros?.isNotEmpty ?? false;

    return GestureDetector(
      onTap: hasMovements ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 3, color: accentColor),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isSerie ? 'SERIE' : 'LOTE',
                            style: GoogleFonts.roboto(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (lote.fechaVencimiento != null &&
                                  !isSerie)
                                Text(
                                  'Vence: ${DateFormat('dd/MM/yyyy').format(lote.fechaVencimiento!)}',
                                  style: GoogleFonts.roboto(
                                      fontSize: 11, color: Colors.black45),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formatDouble(stock),
                            style: GoogleFonts.raleway(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: stockColor,
                            ),
                          ),
                        ),
                        if (hasMovements) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded,
                              size: 18, color: Colors.black26),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Vista movimientos de un lote ──────────────────────────────────────────

class _LoteMovementsView extends StatelessWidget {
  final BatchProduct lote;

  const _LoteMovementsView({super.key, required this.lote});

  @override
  Widget build(BuildContext context) {
    final registros = lote.registros ?? [];

    if (registros.isEmpty) {
      return Center(
        child: Text('Sin movimientos para este lote',
            style: GoogleFonts.roboto(color: Colors.black45)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 16),
      itemCount: registros.length,
      itemBuilder: (context, i) => _LoteLogItem(record: registros[i]),
    );
  }
}

// ─── Item movimiento del producto (con stock anterior/actual) ───────────────

class _LogItem extends StatelessWidget {
  final InventoryRecord record;
  const _LogItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final isEntrada = record.tipo == 'ENTRADA';
    final color = isEntrada ? Colors.green : Colors.red;
    final icon = isEntrada ? Icons.arrow_downward : Icons.arrow_upward;
    final fecha = record.fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(record.fecha!)
        : '-';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.concepto ?? record.tipo ?? '-',
                  style: GoogleFonts.roboto(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
                if (record.detalle != null && record.detalle!.isNotEmpty)
                  Text(
                    record.detalle!,
                    style:
                        GoogleFonts.roboto(fontSize: 11, color: Colors.black54),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                Text(
                  fecha,
                  style:
                      GoogleFonts.roboto(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.cantidadAnterior ?? '-'} → ${record.cantidadActual ?? '-'}',
                style:
                    GoogleFonts.roboto(fontSize: 11, color: Colors.black54),
              ),
              Text(
                record.cantidad != null
                    ? '${isEntrada ? '+' : '-'}${formatDouble(record.cantidad!.abs())}'
                    : '-',
                style: GoogleFonts.raleway(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Item movimiento de lote (tipo, concepto, cantidad, fecha, responsable) ─

class _LoteLogItem extends StatelessWidget {
  final InventoryRecord record;
  const _LoteLogItem({required this.record});

  @override
  Widget build(BuildContext context) {
    final isEntrada = record.tipo == 'ENTRADA';
    final color = isEntrada ? Colors.green : Colors.red;
    final icon = isEntrada ? Icons.arrow_downward : Icons.arrow_upward;
    final fecha = record.fecha != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(record.fecha!)
        : '-';
    final responsable = record.responsable?.nombreCompleto;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icono tipo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          // Info central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.concepto ?? record.tipo ?? '-',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.schedule_outlined,
                        size: 11, color: Colors.black38),
                    const SizedBox(width: 3),
                    Text(
                      fecha,
                      style: GoogleFonts.roboto(
                          fontSize: 11, color: Colors.black45),
                    ),
                  ],
                ),
                if (responsable != null && responsable.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 11, color: Colors.black38),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          responsable,
                          style: GoogleFonts.roboto(
                              fontSize: 11, color: Colors.black45),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Cantidad
          Text(
            record.cantidad != null
                ? '${isEntrada ? '+' : '-'}${formatDouble(record.cantidad!.abs())}'
                : '-',
            style: GoogleFonts.raleway(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
