import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/inventory_adjustment/widgets/batch_lotes_section.dart';
import 'package:teki_app/src/presentation/screens/inventory_adjustment/widgets/serie_lotes_section.dart';
import 'package:teki_app/src/providers/inventory_adjustment/inventory_adjustment_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

/// Chip resumen que se muestra en la pantalla principal.
/// Al tocarlo abre el bottom sheet de gestión de lotes/series.
class LotesSummaryChip extends ConsumerWidget {
  final int itemIndex;

  const LotesSummaryChip({super.key, required this.itemIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryAdjustmentProvider);
    if (state.items.length <= itemIndex) return const SizedBox.shrink();

    final item = state.items[itemIndex];
    final notifier = ref.read(inventoryAdjustmentProvider.notifier);
    final loteError =
        state.showValidation ? notifier.loteValidationError(item) : null;

    final isSerie = item.product.tipoLote == 'SERIE';
    final loteCount = item.lotes.length;
    final sum = item.sumAllLotes;
    final expected = item.stockNuevo;
    final isMatch = (sum - expected).abs() <= 0.001 && loteCount > 0;

    final Color accentColor;
    final Color borderColor;
    final Color bgColor;

    if (loteError != null) {
      accentColor = Colors.red;
      borderColor = Colors.red.shade200;
      bgColor = Colors.red.shade50;
    } else if (isMatch) {
      accentColor = Colors.green;
      borderColor = Colors.green.shade200;
      bgColor = Colors.green.shade50;
    } else {
      accentColor = ColorSchema.primaryColor;
      borderColor = Colors.grey.shade200;
      bgColor = Colors.white;
    }

    final label = loteCount == 0
        ? 'Gestionar ${isSerie ? 'series' : 'lotes'}'
        : '$loteCount ${isSerie ? (loteCount == 1 ? 'serie' : 'series') : (loteCount == 1 ? 'lote' : 'lotes')}';

    final sumLabel = 'Suma: ${_fmt(sum)}  ·  Esp: ${_fmt(expected)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _openSheet(context),
            child: Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Acento lateral
                      Container(width: 3, color: accentColor),
                      // Contenido
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 11),
                          child: Row(
                            children: [
                              Icon(
                                isSerie
                                    ? Icons.qr_code_2_outlined
                                    : Icons.layers_outlined,
                                size: 16,
                                color: accentColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                label,
                                style: GoogleFonts.nunito(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  loteCount > 0 ? sumLabel : '',
                                  style: GoogleFonts.nunito(
                                    fontSize: 11,
                                    color: isMatch
                                        ? Colors.green.shade700
                                        : Colors.black38,
                                  ),
                                  textAlign: TextAlign.end,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: accentColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        // Error inline debajo del chip (visible tras intento de guardar)
        if (loteError != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  loteError,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.45,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scrollController) => _LotesSheetContent(
          itemIndex: itemIndex,
          scrollController: scrollController,
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ---------------------------------------------------------------------------
// Contenido del bottom sheet
// ---------------------------------------------------------------------------
class _LotesSheetContent extends ConsumerWidget {
  final int itemIndex;
  final ScrollController scrollController;

  const _LotesSheetContent({
    required this.itemIndex,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(inventoryAdjustmentProvider);
    if (state.items.length <= itemIndex) return const SizedBox.shrink();

    final item = state.items[itemIndex];
    final isSerie = item.product.tipoLote == 'SERIE';
    final sum = item.sumAllLotes;
    final expected = item.stockNuevo;
    final isMatch = (sum - expected).abs() <= 0.001 && item.lotes.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10, bottom: 4),
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSerie
                      ? Icons.qr_code_2_outlined
                      : Icons.layers_outlined,
                  size: 18,
                  color: ColorSchema.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  isSerie ? 'Series' : 'Lotes',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 8),
                // Badge con conteo
                if (item.lotes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ColorSchema.primaryColor
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${item.lotes.length}',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ColorSchema.primaryColor,
                      ),
                    ),
                  ),
                const Spacer(),
                // Indicador suma vs esperado
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isMatch
                        ? Colors.green.shade50
                        : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isMatch
                          ? Colors.green.shade200
                          : Colors.orange.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMatch
                            ? Icons.check_circle_outline
                            : Icons.pending_outlined,
                        size: 15,
                        color: isMatch
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${_fmt(sum)} / ${_fmt(expected)}',
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isMatch
                              ? Colors.green.shade700
                              : Colors.orange.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Contenido scrollable
          Expanded(
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                isSerie
                    ? SerieLotesSection(itemIndex: itemIndex, item: item)
                    : BatchLotesSection(itemIndex: itemIndex, item: item),
                // Espacio para el teclado
                SizedBox(
                  height: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toStringAsFixed(2);
}
