import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
import 'package:teki_app/src/providers/inventory_adjustment/inventory_adjustment_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class SerieLotesSection extends ConsumerStatefulWidget {
  final int itemIndex;
  final AdjustmentFormItem item;

  const SerieLotesSection({
    super.key,
    required this.itemIndex,
    required this.item,
  });

  @override
  ConsumerState<SerieLotesSection> createState() => _SerieLotesSectionState();
}

class _SerieLotesSectionState extends ConsumerState<SerieLotesSection> {
  final _serieController = TextEditingController();
  String? _serieError;

  @override
  void dispose() {
    _serieController.dispose();
    super.dispose();
  }

  Future<void> _onScan() async {
    final code = await BarcodeScannerSheet.show(context);
    if (code == null || code.trim().isEmpty) return;
    final nombre = code.trim();
    final exists = widget.item.lotes
        .any((l) => l.nombre.toLowerCase() == nombre.toLowerCase());
    if (exists) {
      setState(() => _serieError = 'Esta serie ya existe');
      return;
    }
    ref.read(inventoryAdjustmentProvider.notifier).addLote(
      widget.itemIndex,
      AdjustmentLoteItem(
        nombre: nombre,
        cantidad: 1,
        tipoLote: 'SERIE',
        isExisting: false,
      ),
    );
    setState(() => _serieError = null);
  }

  void _addSerie() {
    final nombre = _serieController.text.trim();
    if (nombre.isEmpty) {
      setState(() => _serieError = 'Ingresa un nombre de serie');
      return;
    }
    final exists = widget.item.lotes
        .any((l) => l.nombre.toLowerCase() == nombre.toLowerCase());
    if (exists) {
      setState(() => _serieError = 'Esta serie ya existe');
      return;
    }
    ref.read(inventoryAdjustmentProvider.notifier).addLote(
      widget.itemIndex,
      AdjustmentLoteItem(
        nombre: nombre,
        cantidad: 1,
        tipoLote: 'SERIE',
        isExisting: false,
      ),
    );
    _serieController.clear();
    setState(() => _serieError = null);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título
        Row(
          children: [
            const Icon(Icons.qr_code_2_outlined,
                size: 16, color: ColorSchema.primaryColor),
            const SizedBox(width: 6),
            Text(
              'Series',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Input + escáner + botón agregar
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _serieController,
                onChanged: (_) => setState(() => _serieError = null),
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Nombre / código de serie...',
                  hintStyle:
                      const TextStyle(fontSize: 12, color: Colors.black38),
                  errorText: _serieError,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 10, horizontal: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                        color: ColorSchema.primaryColor, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        const BorderSide(color: Colors.red, width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: _onScan,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: ColorSchema.primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: ColorSchema.primaryColor.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.qr_code_scanner,
                    color: Colors.white, size: 18),
              ),
            ),
            if (_serieController.text.isNotEmpty) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: _addSerie,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ],
        ),

        const SizedBox(height: 8),

        // Series nuevas (editables + eliminables)
        ...widget.item.lotes.asMap().entries.where((e) => !e.value.isExisting).map(
              (e) => _LoteEditableRow(
                key: ValueKey('new_${e.value.nombre}'),
                itemIndex: widget.itemIndex,
                loteIndex: e.key,
                lote: e.value,
                canDelete: true,
              ),
            ),

        // Series existentes (editables, sin eliminar)
        ...widget.item.lotes.asMap().entries.where((e) => e.value.isExisting).map(
              (e) => _LoteEditableRow(
                key: ValueKey('existing_${e.value.id ?? e.value.nombre}'),
                itemIndex: widget.itemIndex,
                loteIndex: e.key,
                lote: e.value,
                canDelete: false,
              ),
            ),
      ],
    );
  }
}

class _LoteEditableRow extends ConsumerStatefulWidget {
  final int itemIndex;
  final int loteIndex;
  final AdjustmentLoteItem lote;
  final bool canDelete;

  const _LoteEditableRow({
    super.key,
    required this.itemIndex,
    required this.loteIndex,
    required this.lote,
    required this.canDelete,
  });

  @override
  ConsumerState<_LoteEditableRow> createState() => _LoteEditableRowState();
}

class _LoteEditableRowState extends ConsumerState<_LoteEditableRow> {
  late final TextEditingController _nombreController;
  late final TextEditingController _cantidadController;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.lote.nombre);
    _cantidadController = TextEditingController(
      text: widget.lote.cantidad > 0 ? formatDouble(widget.lote.cantidad) : '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadController.dispose();
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

    final accentColor = isExisting ? Colors.grey.shade400 : Colors.green;
    final borderColor =
        isExisting ? Colors.grey.shade200 : Colors.green.shade200;
    final bgColor = isExisting
        ? Colors.grey.shade50
        : Colors.green.withValues(alpha: 0.04);

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
                  child: Row(
                    children: [
                      Icon(
                        isExisting
                            ? Icons.label_outline
                            : Icons.fiber_new_outlined,
                        size: 13,
                        color: isExisting ? Colors.black38 : Colors.green,
                      ),
                      const SizedBox(width: 5),
                      // Nombre
                      Expanded(
                        child: TextField(
                          controller: _nombreController,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          onChanged: (v) => notifier.updateLoteNombre(
                              widget.itemIndex, widget.loteIndex, v),
                          decoration: _compact('Nombre de serie'),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Cantidad (solo 0 o 1 para series)
                      SizedBox(
                        width: 64,
                        child: TextField(
                          controller: _cantidadController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          onChanged: (v) {
                            final raw = double.tryParse(v);
                            if (raw == null) return;
                            final clamped = raw.clamp(0.0, 1.0);
                            if (clamped != raw) {
                              final text = clamped.toInt().toString();
                              _cantidadController.value = TextEditingValue(
                                text: text,
                                selection: TextSelection.collapsed(
                                    offset: text.length),
                              );
                            }
                            notifier.updateLoteCantidad(
                                widget.itemIndex, widget.loteIndex, clamped);
                          },
                          decoration: _compact('0 / 1'),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
