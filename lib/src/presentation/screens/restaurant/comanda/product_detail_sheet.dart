import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_group_option.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail_preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/group.dart';
import 'package:teki_app/src/data/models/teki_model/group_option.dart';
import 'package:teki_app/src/data/models/teki_model/preparation_option.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/detail_sheet_components.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/grupos_section.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/preparaciones_section.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/product_detail/price_picker_sheet.dart';
import 'package:teki_app/src/providers/restaurant/comanda_provider.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';

// ---------------------------------------------------------------------------
// Helper to open the sheet
// ---------------------------------------------------------------------------

void showProductDetailSheet(
  BuildContext context, {
  required Product product,
  CartItem? existingItem,
  int? cartIndex,
  required void Function(CartItem item, int? index) onConfirm,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ProductDetailSheet(
      product: product,
      existingItem: existingItem,
      cartIndex: cartIndex,
      onConfirm: onConfirm,
    ),
  );
}

// ---------------------------------------------------------------------------
// Sheet widget
// ---------------------------------------------------------------------------

class ProductDetailSheet extends StatefulWidget {
  final Product product;
  final CartItem? existingItem;
  final int? cartIndex;
  final void Function(CartItem item, int? index) onConfirm;

  const ProductDetailSheet({
    super.key,
    required this.product,
    this.existingItem,
    this.cartIndex,
    required this.onConfirm,
  });

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  late int _quantity;
  late double _price;
  late bool _paraLlevar;
  late TextEditingController _notaController;
  late TextEditingController _priceController;

  // preparacionId -> opcionId
  final Map<int, int?> _prepSelections = {};
  // grupoId -> Set<opcionId>
  final Map<int, Set<int>> _groupSelections = {};
  // grupoId -> opcionId -> cantidad (solo para grupos con permitirCantidad=true)
  final Map<int, Map<int, int>> _groupQuantities = {};

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _notaController = TextEditingController();

    // Initialize group maps so they exist during build
    for (final g in widget.product.grupos ?? []) {
      if (g.id != null) _groupSelections[g.id!] = {};
    }

    final existing = widget.existingItem;
    if (existing != null) {
      _quantity = existing.quantity;
      _price = existing.price;
      _paraLlevar = existing.paraLlevar;
      _notaController.text = existing.nota ?? '';
      _priceController = TextEditingController(text: _price.toStringAsFixed(2));

      for (final po in existing.preparacionOpciones) {
        if (po.idPreparacion != null && po.idOpcion != null) {
          _prepSelections[po.idPreparacion!] = po.idOpcion;
        }
      }
      for (final go in existing.grupoOpciones) {
        if (go.idGrupo != null && go.idOpcion != null) {
          _groupSelections.putIfAbsent(go.idGrupo!, () => {}).add(go.idOpcion!);
          // Restore quantities for permitirCantidad groups
          final grupo = (widget.product.grupos ?? []).firstWhere(
            (g) => g.id == go.idGrupo,
            orElse: () => Group(),
          );
          if (grupo.permitirCantidad == true) {
            _groupQuantities
                .putIfAbsent(go.idGrupo!, () => {})[go.idOpcion!] =
                (go.cantidad ?? 1).toInt();
          }
        }
      }
    } else {
      _quantity = 1;
      _price = ComandaNotifier.computePrice(widget.product, 1);
      _paraLlevar = false;
      _priceController = TextEditingController(text: _price.toStringAsFixed(2));

      // Pre-select porDefecto options
      for (final g in widget.product.grupos ?? []) {
        if (g.id == null) continue;
        for (final op in g.opciones ?? []) {
          if (op.porDefecto == true && op.id != null) {
            _groupSelections[g.id!]!.add(op.id!);
            if (g.permitirCantidad == true) {
              _groupQuantities.putIfAbsent(g.id!, () => {})[op.id!] = 1;
            }
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _notaController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Price auto-update on quantity change
  // -------------------------------------------------------------------------

  void _onQuantityChanged(int newQty) {
    if (newQty < 1) return;
    final newPrice = ComandaNotifier.computePrice(widget.product, newQty);
    setState(() {
      _quantity = newQty;
      _price = newPrice;
    });
    _priceController.text = newPrice.toStringAsFixed(2);
  }

  // -------------------------------------------------------------------------
  // Extras total
  // -------------------------------------------------------------------------

  double get _extrasPrice {
    double extras = 0;
    for (final entry in _groupSelections.entries) {
      final grupo = (widget.product.grupos ?? []).firstWhere(
        (g) => g.id == entry.key,
        orElse: () => Group(),
      );
      for (final opId in entry.value) {
        final op = (grupo.opciones ?? []).firstWhere(
          (o) => o.id == opId,
          orElse: () => GroupOption(),
        );
        final qty = grupo.permitirCantidad == true
            ? (_groupQuantities[entry.key]?[opId] ?? 1)
            : 1;
        extras += (op.precio ?? 0) * qty;
      }
    }
    return extras;
  }

  double get _totalPrice => _price * _quantity + _extrasPrice;

  // -------------------------------------------------------------------------
  // Validation
  // -------------------------------------------------------------------------

  bool _validate() {
    for (final pp in widget.product.preparaciones ?? []) {
      if (pp.requerido == true) {
        final selected = _prepSelections[pp.preparacion?.id];
        if (selected == null) {
          _showError(
              '"${pp.preparacion?.nombre ?? 'Preparación'}" es obligatoria');
          return false;
        }
      }
    }
    for (final g in widget.product.grupos ?? []) {
      final label = g.etiqueta ?? g.nombre ?? 'Adicional';
      final min = g.forzarMinimo;
      final max = g.forzarMaximo;

      if (g.requerido != true) continue;

      if (g.permitirCantidad == true) {
        final totalQty = (_groupQuantities[g.id] ?? {})
            .values
            .fold<int>(0, (sum, q) => sum + q);
        if (min != null && totalQty < min) {
          _showError('"$label" requiere al menos $min unidad(es) en total');
          return false;
        }
        if (max != null && totalQty > max) {
          _showError('"$label" no puede superar $max unidad(es) en total');
          return false;
        }
      } else {
        final selected = _groupSelections[g.id] ?? {};
        final minCount = min ?? 1;
        if (selected.length < minCount) {
          _showError('"$label" requiere al menos $minCount selección(es)');
          return false;
        }
      }
    }
    return true;
  }

  void _showError(String message) {
    setState(() => _errorMessage = message);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) setState(() => _errorMessage = null);
    });
  }

  // -------------------------------------------------------------------------
  // Submit
  // -------------------------------------------------------------------------

  void _submit() {
    if (!_validate()) return;

    final preparacionOpciones = <CommandDetailPreparationOption>[];
    for (final pp in widget.product.preparaciones ?? []) {
      final prepId = pp.preparacion?.id;
      final opcionId = _prepSelections[prepId];
      if (prepId != null && opcionId != null) {
        final opcion = (pp.preparacion?.opciones ?? []).firstWhere(
          (o) => o.id == opcionId,
          orElse: () => PreparationOption(),
        );
        preparacionOpciones.add(CommandDetailPreparationOption(
          idPreparacion: prepId,
          nombrePreparacion: pp.preparacion?.nombre,
          idOpcion: opcionId,
          nombreOpcion: opcion.opcion,
        ));
      }
    }

    final grupoOpciones = <CommandDetailGroupOption>[];
    for (final g in widget.product.grupos ?? []) {
      final selectedIds = _groupSelections[g.id] ?? {};
      for (final opcionId in selectedIds) {
        final opcion = (g.opciones ?? []).firstWhere(
          (o) => o.id == opcionId,
          orElse: () => GroupOption(),
        );
        final qty = g.permitirCantidad == true
            ? (_groupQuantities[g.id]?[opcionId] ?? 1)
            : 1;
        grupoOpciones.add(CommandDetailGroupOption(
          idGrupo: g.id,
          nombreGrupo: g.nombre,
          idOpcion: opcionId,
          nombreOpcion: opcion.nombre,
          porcion: opcion.porcion ?? 1,
          precio: opcion.precio ?? 0,
          cantidad: qty.toDouble(),
          producto: opcion.producto,
        ));
      }
    }

    final nota = _notaController.text.trim();
    final item = widget.existingItem != null
        ? widget.existingItem!.copyWith(
            quantity: _quantity,
            price: _price,
            paraLlevar: _paraLlevar,
            nota: nota.isEmpty ? null : nota,
            clearNota: nota.isEmpty,
            grupoOpciones: grupoOpciones,
            preparacionOpciones: preparacionOpciones,
          )
        : CartItem.create(
            product: widget.product,
            quantity: _quantity,
            price: _price,
            paraLlevar: _paraLlevar,
            nota: nota.isEmpty ? null : nota,
            grupoOpciones: grupoOpciones,
            preparacionOpciones: preparacionOpciones,
          );

    Navigator.pop(context);
    widget.onConfirm(item, widget.cartIndex);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingItem != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.96,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Scrollable content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildParaLlevarYObservacion(),
                    const SizedBox(height: 12),
                    if ((widget.product.preparaciones ?? []).isNotEmpty) ...[
                      PreparacionesSection(
                        product: widget.product,
                        prepSelections: _prepSelections,
                        onSelected: (prepId, v) =>
                            setState(() => _prepSelections[prepId] = v),
                      ),
                      const SizedBox(height: 4),
                    ],
                    if ((widget.product.grupos ?? []).isNotEmpty) ...[
                      GruposSection(
                        product: widget.product,
                        groupSelections: _groupSelections,
                        groupQuantities: _groupQuantities,
                        onChanged: () => setState(() {}),
                      ),
                      const SizedBox(height: 4),
                    ],
                    const SizedBox(height: 80),
                  ],
                ),
              ),
              // Sticky bottom button
              _buildBottomButton(isEdit),
            ],
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Section builders
  // -------------------------------------------------------------------------

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Imagen
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 74,
            height: 74,
            child: _buildProductImage(),
          ),
        ),
        const SizedBox(width: 12),
        // Nombre + categoría + controles
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.product.nombre ?? '-',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Colors.black87,
                ),
              ),
              if (widget.product.categoria?.nombre != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    widget.product.categoria!.nombre!,
                    style: const TextStyle(
                      fontSize: 10,
                      color: ColorSchema.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              // Precio y cantidad compactos en fila
              _buildQuantityAndPrice(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductImage() {
    final url = widget.product.imagenPorDefecto?.imagen;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imagePlaceholder(),
      );
    }
    return _imagePlaceholder();
  }

  Widget _imagePlaceholder() => Container(
        color: Colors.grey.shade100,
        child: Center(
          child: Image.asset(
            'assets/images/products/icon.png',
            width: 40,
            fit: BoxFit.contain,
          ),
        ),
      );

  Widget _buildQuantityAndPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Precio: símbolo + input + botón picker
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatExchange(moneda: widget.product.moneda ?? 'PEN'),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 68,
              child: TextField(
                controller: _priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: ColorSchema.primaryColor,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 6, horizontal: 4),
                  filled: true,
                  fillColor:
                      ColorSchema.primaryColor.withValues(alpha: 0.07),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(7),
                    borderSide: const BorderSide(
                        color: ColorSchema.primaryColor, width: 1.5),
                  ),
                ),
                onChanged: (v) {
                  final parsed = double.tryParse(v);
                  if (parsed != null) setState(() => _price = parsed);
                },
              ),
            ),
            if ((widget.product.preciosVenta ?? []).isNotEmpty) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => showProductPricePicker(
                  context,
                  product: widget.product,
                  currentPrice: _price,
                  onSelected: (v) {
                    setState(() => _price = v);
                    _priceController.text = v.toStringAsFixed(2);
                  },
                ),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.local_offer_outlined,
                    size: 15,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        // Cantidad: stepper
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CompactStepButton(
              icon: Icons.remove_rounded,
              enabled: _quantity > 1,
              onTap: () => _onQuantityChanged(_quantity - 1),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                '$_quantity',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
            CompactStepButton(
              icon: Icons.add_rounded,
              enabled: true,
              onTap: () => _onQuantityChanged(_quantity + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildParaLlevarYObservacion() {
    return InfoBox(
      child: Column(
        children: [
          // Para llevar
          Row(
            children: [
              Icon(Icons.takeout_dining_outlined,
                  color: Colors.grey.shade500, size: 20),
              const SizedBox(width: 10),
              const Text(
                'Para llevar',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
              const Spacer(),
              Switch.adaptive(
                value: _paraLlevar,
                activeColor: ColorSchema.primaryColor,
                onChanged: (v) => setState(() => _paraLlevar = v),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          // Observación
          TextField(
            controller: _notaController,
            maxLines: 1,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Observación o nota (opcional)',
              hintStyle:
                  TextStyle(fontSize: 13, color: Colors.grey.shade400),
              prefixIcon: Icon(Icons.notes_outlined,
                  color: Colors.grey.shade400, size: 20),
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(bool isEdit) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_errorMessage != null) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded,
                      color: Colors.red.shade600, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isEdit
                        ? Icons.check_circle_outline_rounded
                        : Icons.add_shopping_cart_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isEdit ? 'Actualizar' : 'Agregar'}  ·  ${formatExchange(moneda: widget.product.moneda ?? 'PEN')}${_totalPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
