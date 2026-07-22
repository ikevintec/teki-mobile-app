import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/inventory_adjustment/widgets/lotes_summary_chip.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/barcode_scanner/barcode_scanner_sheet.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/inventory_adjustment/inventory_adjustment_provider.dart';
import 'package:teki_app/src/providers/products/products.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

class InventoryAdjustmentScreen extends ConsumerStatefulWidget {
  final Inventory? preSelectedInventory;

  const InventoryAdjustmentScreen({super.key, this.preSelectedInventory});

  @override
  ConsumerState<InventoryAdjustmentScreen> createState() =>
      _InventoryAdjustmentScreenState();
}

class _InventoryAdjustmentScreenState
    extends ConsumerState<InventoryAdjustmentScreen> {
  final _motivoController = TextEditingController();
  final _observacionController = TextEditingController();
  final _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _showSearchResults = false;

  bool get _isSingleProductMode => widget.preSelectedInventory != null;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final notifier = ref.read(inventoryAdjustmentProvider.notifier);
      notifier.reset();
      if (widget.preSelectedInventory != null) {
        final inventory = widget.preSelectedInventory!;
        notifier.addItem(
          inventory.producto!,
          existingLotes: inventory.lotes ?? [],
          stockActual: inventory.stock ?? 0,
        );
      }
    });
  }

  @override
  void dispose() {
    _motivoController.dispose();
    _observacionController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> _onScanBarcode() async {
    final code = await BarcodeScannerSheet.show(context);
    if (code != null && code.isNotEmpty) {
      _searchController.text = code;
      _onSearchChanged(code);
    }
  }

  void _onSearchChanged(String value) {
    if (_searchDebounce?.isActive ?? false) _searchDebounce!.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 600), () {
      if (value.isEmpty) {
        setState(() => _showSearchResults = false);
        ref.read(productsProvider.notifier).searchProducts('');
      } else {
        setState(() => _showSearchResults = true);
        ref.read(productsProvider.notifier).searchProducts(value);
      }
    });
  }

  void _selectProduct(Product product) {
    ref.read(inventoryAdjustmentProvider.notifier).addItem(product);
    _searchController.clear();
    setState(() => _showSearchResults = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final adjustmentState = ref.watch(inventoryAdjustmentProvider);
    final productsState = ref.watch(productsProvider);
    final idPuntoVenta = ref.read(sesionProvider).office?.id;

    final appBarTitle = _isSingleProductMode ? 'Ajuste de inventario' : 'Nuevo Ajuste';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(navigateName: appBarTitle),
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _showSearchResults = false);
            },
            child: Container(
              color: Colors.grey.shade100,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
          Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Buscador de productos (solo en modo multi-producto)
                  if (!_isSingleProductMode) ...[
                  Text(
                    'Agregar productos',
                    style: GoogleFonts.raleway(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.07),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: _onSearchChanged,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Buscar producto por nombre...',
                              hintStyle: const TextStyle(
                                  fontSize: 13, color: Colors.black38),
                              prefixIcon: const Icon(Icons.search,
                                  color: ColorSchema.primaryColor, size: 22),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded,
                                          size: 18, color: Colors.black38),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() =>
                                            _showSearchResults = false);
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 14, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: ColorSchema.primaryColor,
                                    width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ScannerButton(onTap: _onScanBarcode),
                    ],
                  ),
                  // Resultados de búsqueda
                  if (_showSearchResults) ...[
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: productsState.isLoading
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorSchema.primaryColor,
                                  strokeWidth: 2,
                                ),
                              ),
                            )
                          : productsState.products.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search_off,
                                          color: Colors.black26, size: 18),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Sin resultados',
                                        style: GoogleFonts.roboto(
                                            color: Colors.black45,
                                            fontSize: 13),
                                      ),
                                    ],
                                  ),
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount:
                                        productsState.products.length > 6
                                            ? 6
                                            : productsState.products.length,
                                    separatorBuilder: (_, __) => Divider(
                                        height: 1,
                                        color: Colors.grey.shade100),
                                    itemBuilder: (context, i) {
                                      final p = productsState.products[i];
                                      return InkWell(
                                        onTap: () => _selectProduct(p),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 10),
                                          child: Row(
                                            children: [
                                              Container(
                                                width: 32,
                                                height: 32,
                                                decoration: BoxDecoration(
                                                  color: ColorSchema
                                                      .primaryColor
                                                      .withValues(alpha: 0.08),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: const Icon(
                                                  Icons.inventory_2_outlined,
                                                  size: 16,
                                                  color:
                                                      ColorSchema.primaryColor,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      p.nombre ?? '-',
                                                      style: GoogleFonts.roboto(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 13),
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                    if (p.codigo != null &&
                                                        p.codigo!.isNotEmpty)
                                                      Text(
                                                        p.codigo!,
                                                        style: GoogleFonts.roboto(
                                                            fontSize: 11,
                                                            color:
                                                                Colors.black45),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                              const Icon(Icons.add_circle_outline,
                                                  size: 18,
                                                  color:
                                                      ColorSchema.primaryColor),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                  ], // fin if (!_isSingleProductMode)

                  const SizedBox(height: 16),

                  // Lista de ítems agregados
                  if (adjustmentState.items.isEmpty && !_isSingleProductMode)
                    Container(
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Center(
                        child: Text(
                          'Busca y selecciona los productos a ajustar',
                          style: GoogleFonts.roboto(
                              color: Colors.black38, fontSize: 13),
                        ),
                      ),
                    )
                  else
                    ...List.generate(
                      adjustmentState.items.length,
                      (i) => _AdjustmentItemWidget(
                        key: ValueKey(adjustmentState.items[i].product.id ?? adjustmentState.items[i].product.nombre ?? i),
                        index: i,
                        item: adjustmentState.items[i],
                        showRemove: !_isSingleProductMode,
                        showValidation: adjustmentState.showValidation,
                      ),
                    ),



                  const SizedBox(height: 20),

                  // Motivo
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'Motivo',
                          style: GoogleFonts.raleway(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Colors.black87),
                        ),
                        const TextSpan(
                          text: ' *',
                          style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _motivoController,
                    onChanged: (v) =>
                        ref.read(inventoryAdjustmentProvider.notifier).setMotivo(v),
                    decoration: _inputDecoration('Ej: Conteo físico, merma...'),
                    maxLines: 2,
                    maxLength: 200,
                  ),

                  // Chip de lotes/series (solo single-product mode)
                  if (_isSingleProductMode &&
                      adjustmentState.items.isNotEmpty &&
                      adjustmentState.items.first.product.validacionLote == true) ...[
                    const SizedBox(height: 16),
                    LotesSummaryChip(itemIndex: 0),
                  ],

                  const SizedBox(height: 80), // espacio para el botón
                ],
              ),
            ),
          ],
        ),
        ],
      ),
      // Botón guardar flotante en la parte inferior
      bottomNavigationBar: Container(
        color: Colors.grey.shade100,
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: adjustmentState.isSubmitting || idPuntoVenta == null
                ? null
                : () {
                    FocusScope.of(context).unfocus();
                    ref
                        .read(inventoryAdjustmentProvider.notifier)
                        .submit(idPuntoVenta);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: adjustmentState.isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Guardar Ajuste',
                    style: GoogleFonts.raleway(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
          ),
        ),
      ),
    ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: ColorSchema.primaryColor, width: 1.5),
        ),
      );
}

// Widget para cada producto en el formulario de ajuste
class _AdjustmentItemWidget extends ConsumerStatefulWidget {
  final int index;
  final AdjustmentFormItem item;
  final bool showRemove;
  final bool showValidation;

  const _AdjustmentItemWidget({
    super.key,
    required this.index,
    required this.item,
    this.showRemove = true,
    this.showValidation = false,
  });

  @override
  ConsumerState<_AdjustmentItemWidget> createState() =>
      _AdjustmentItemWidgetState();
}

class _AdjustmentItemWidgetState
    extends ConsumerState<_AdjustmentItemWidget> {
  late final TextEditingController _nuevoStockController;

  @override
  void initState() {
    super.initState();
    _nuevoStockController = TextEditingController(
      text: formatDouble(widget.item.nuevoStock),
    );
  }

  @override
  void dispose() {
    _nuevoStockController.dispose();
    super.dispose();
  }

  void _stepStock(double delta) {
    final notifier = ref.read(inventoryAdjustmentProvider.notifier);
    final current =
        double.tryParse(_nuevoStockController.text) ?? widget.item.nuevoStock;
    final newVal = (current + delta).clamp(0.0, double.infinity);
    _nuevoStockController.text = formatDouble(newVal);
    notifier.updateNuevoStock(widget.index, newVal);
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(inventoryAdjustmentProvider.notifier);
    final delta = widget.item.delta;
    final accentColor = delta > 0
        ? Colors.green
        : delta < 0
            ? Colors.red
            : Colors.grey.shade400;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Acento lateral de color
              Container(width: 4, color: accentColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: nombre + eliminar
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.item.product.nombre ?? '-',
                              style: GoogleFonts.raleway(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (widget.showRemove)
                            GestureDetector(
                              onTap: () => notifier.removeItem(widget.index),
                              child: const Icon(Icons.close,
                                  size: 18, color: Colors.black38),
                            ),
                        ],
                      ),
                      // Stock actual (todos los productos)
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Stock actual: ',
                            style: GoogleFonts.roboto(
                                fontSize: 11, color: Colors.black45),
                          ),
                          Text(
                            formatDouble(widget.item.stockActual),
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Nuevo stock + indicador de delta
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label + delta badge en la misma fila
                          Row(
                            children: [
                              Text(
                                'Nuevo stock',
                                style: GoogleFonts.roboto(
                                    fontSize: 11, color: Colors.black54),
                              ),
                              const Spacer(),
                              if (delta != 0) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 9, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: delta > 0
                                        ? Colors.green.withValues(alpha: 0.1)
                                        : Colors.red.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: delta > 0
                                          ? Colors.green.shade200
                                          : Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        delta > 0
                                            ? Icons.arrow_upward_rounded
                                            : Icons.arrow_downward_rounded,
                                        size: 14,
                                        color: delta > 0
                                            ? Colors.green.shade700
                                            : Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        '${delta > 0 ? '+' : ''}${formatDouble(delta)}',
                                        style: GoogleFonts.roboto(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: delta > 0
                                              ? Colors.green.shade700
                                              : Colors.red.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Input con botones +/-
                          Row(
                            children: [
                              _StepButton(
                                icon: Icons.remove,
                                onTap: () => _stepStock(-1),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: _nuevoStockController,
                                  keyboardType: const TextInputType
                                      .numberWithOptions(decimal: true),
                                  onChanged: (v) {
                                    final val = double.tryParse(v);
                                    if (val != null) {
                                      notifier.updateNuevoStock(
                                          widget.index, val);
                                    }
                                  },
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.raleway(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: Colors.black87,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0',
                                    hintStyle: const TextStyle(
                                        color: Colors.black26, fontSize: 14),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 10, horizontal: 8),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                          color: Colors.grey.shade300),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                          color: ColorSchema.primaryColor,
                                          width: 1.5),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              _StepButton(
                                icon: Icons.add,
                                onTap: () => _stepStock(1),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Error inline para productos con validacionLote (modo multi-producto)
                      if (widget.showValidation &&
                          widget.item.product.validacionLote == true) ...[
                        const SizedBox(height: 6),
                        Builder(builder: (context) {
                          final error = ref
                              .read(inventoryAdjustmentProvider.notifier)
                              .loteValidationError(widget.item);
                          if (error == null) return const SizedBox.shrink();
                          return Row(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: Colors.red, size: 13),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  error,
                                  style: const TextStyle(
                                    color: Colors.red,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }),
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

class _ScannerButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ScannerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: ColorSchema.primaryColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: ColorSchema.primaryColor.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }
}
