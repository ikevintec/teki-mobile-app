import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/providers/inventory_adjustment/inventory_adjustment_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class BatchLotesSection extends ConsumerWidget {
  final int itemIndex;
  final AdjustmentFormItem item;

  const BatchLotesSection({
    super.key,
    required this.itemIndex,
    required this.item,
  });

  String _generateLoteName() {
    final today = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(today);
    final prefix = 'Lote $dateStr - ';
    final count = item.lotes.where((l) => l.nombre.startsWith(prefix)).length;
    return '$prefix${count + 1}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(inventoryAdjustmentProvider.notifier);
    final lotes = item.lotes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Row(
          children: [
            const Icon(Icons.layers_outlined,
                size: 16, color: ColorSchema.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Lotes',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Botón agregar lote
        OutlinedButton.icon(
          onPressed: () {
            notifier.addLote(
              itemIndex,
              AdjustmentLoteItem(
                nombre: _generateLoteName(),
                cantidad: 0,
                tipoLote: 'LOTE',
                isExisting: false,
              ),
            );
          },
          icon: const Icon(Icons.add, size: 15),
          label: Text('Agregar lote',
              style: GoogleFonts.nunito(fontSize: 12)),
          style: OutlinedButton.styleFrom(
            foregroundColor: ColorSchema.primaryColor,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            side: const BorderSide(color: ColorSchema.primaryColor),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
        ),

        const SizedBox(height: 8),

        // Lotes nuevos (editables + eliminables)
        ...lotes.asMap().entries.where((e) => !e.value.isExisting).map(
              (e) => _BatchLoteRow(
                key: ValueKey('new_${e.value.nombre}'),
                itemIndex: itemIndex,
                loteIndex: e.key,
                lote: e.value,
                canDelete: true,
              ),
            ),

        // Lotes existentes (editables, sin eliminar)
        ...lotes.asMap().entries.where((e) => e.value.isExisting).map(
              (e) => _BatchLoteRow(
                key: ValueKey('existing_${e.value.id ?? e.value.nombre}'),
                itemIndex: itemIndex,
                loteIndex: e.key,
                lote: e.value,
                canDelete: false,
              ),
            ),
      ],
    );
  }
}

class _BatchLoteRow extends ConsumerStatefulWidget {
  final int itemIndex;
  final int loteIndex;
  final AdjustmentLoteItem lote;
  final bool canDelete;

  const _BatchLoteRow({
    super.key,
    required this.itemIndex,
    required this.loteIndex,
    required this.lote,
    required this.canDelete,
  });

  @override
  ConsumerState<_BatchLoteRow> createState() => _BatchLoteRowState();
}

class _BatchLoteRowState extends ConsumerState<_BatchLoteRow> {
  late final TextEditingController _nombreController;
  late final TextEditingController _cantidadController;
  late final TextEditingController _precioController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.lote.nombre);
    _cantidadController = TextEditingController(
      text: widget.lote.cantidad > 0 ? formatDouble(widget.lote.cantidad) : '',
    );
    _precioController = TextEditingController(
      text: widget.lote.precioCompra != null
          ? formatDouble(widget.lote.precioCompra!)
          : '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  InputDecoration _compact(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 10, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1.2),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(inventoryAdjustmentProvider.notifier);
    final isExisting = widget.lote.isExisting;

    final accentColor =
        isExisting ? Colors.grey.shade400 : ColorSchema.primaryColor;
    final borderColor =
        isExisting ? Colors.grey.shade200 : Colors.blue.shade100;
    final bgColor = isExisting
        ? Colors.grey.shade50
        : Colors.blue.withValues(alpha: 0.03);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
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
              // Acento lateral
              Container(width: 3, color: accentColor),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nombre + delete
                      Row(
                        children: [
                          Icon(
                            isExisting
                                ? Icons.label_outline
                                : Icons.fiber_new_outlined,
                            size: 13,
                            color: isExisting
                                ? Colors.black38
                                : ColorSchema.primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: TextField(
                              controller: _nombreController,
                              style: GoogleFonts.nunito(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                              onChanged: (v) => notifier.updateLoteNombre(
                                  widget.itemIndex, widget.loteIndex, v),
                              decoration: _compact('Nombre del lote'),
                            ),
                          ),
                          if (widget.canDelete) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => notifier.removeLote(
                                  widget.itemIndex, widget.loteIndex),
                              child: const Padding(
                                padding: EdgeInsets.all(3),
                                child: Icon(Icons.close,
                                    size: 14, color: Colors.black38),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Cantidad + Precio
                      Row(
                        children: [
                          // Cantidad
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Cantidad',
                                    style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        color: Colors.black45)),
                                const SizedBox(height: 3),
                                TextField(
                                  controller: _cantidadController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.nunito(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null) {
                                      notifier.updateLoteCantidad(
                                          widget.itemIndex,
                                          widget.loteIndex,
                                          val);
                                    }
                                  },
                                  decoration: _compact('0'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Precio compra
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Precio compra',
                                    style: GoogleFonts.nunito(
                                        fontSize: 10,
                                        color: Colors.black45)),
                                const SizedBox(height: 3),
                                TextField(
                                  controller: _precioController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: true),
                                  textAlign: TextAlign.center,
                                  style:
                                      GoogleFonts.nunito(fontSize: 11),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    notifier.updateLotePrecio(
                                        widget.itemIndex,
                                        widget.loteIndex,
                                        val);
                                  },
                                  decoration: _compact('0.00'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
