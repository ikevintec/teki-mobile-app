import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/inventory_production/inventory_production_provider.dart';
import 'package:teki_app/src/providers/products/products.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/production_preview.dart';

/// Tipos de producto que se pueden producir (paridad con la web).
const _tiposProducibles = {
  'PAQUETE_PRODUCIDO',
  'PLATILLO_PRODUCIDO',
  'PAQUETE',
  'PLATILLO',
};

class CreateProductionScreen extends ConsumerStatefulWidget {
  const CreateProductionScreen({super.key});

  @override
  ConsumerState<CreateProductionScreen> createState() =>
      _CreateProductionScreenState();
}

class _CreateProductionScreenState
    extends ConsumerState<CreateProductionScreen> {
  final _searchController = TextEditingController();
  // Un controller de cantidad por producto (id estable), para que +/- y el
  // texto se mantengan sincronizados.
  final Map<int, TextEditingController> _qtyControllers = {};
  Timer? _debounce;
  bool _showResults = false;
  bool _loadingProduct = false;

  static final _fmt = NumberFormat('#,##0.00', 'es_PE');

  @override
  void dispose() {
    _searchController.dispose();
    for (final c in _qtyControllers.values) {
      c.dispose();
    }
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim().isEmpty) {
        setState(() => _showResults = false);
        ref.read(productsProvider.notifier).searchProducts('');
      } else {
        setState(() => _showResults = true);
        ref.read(productsProvider.notifier).searchProducts(value.trim());
      }
    });
  }

  Future<void> _selectProduct(Product product) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _showResults = false;
      _loadingProduct = true;
    });
    try {
      // El buscador devuelve un producto liviano; necesitamos el completo
      // (receta + stock de insumos) para el preview de consumo.
      final full = await ProductsRepositoryImpl().getProductById(product.id!);
      final added = ref.read(productionFormProvider.notifier).addProduct(full);
      if (!added) {
        warningNotification('${full.nombre} ya está agregado', fromTop: false);
      }
      _searchController.clear();
    } catch (_) {
      errorNotification('No se pudo cargar el producto', fromTop: false);
    } finally {
      if (mounted) setState(() => _loadingProduct = false);
    }
  }

  Future<void> _registrar(int idPuntoVenta) async {
    final form = ref.read(productionFormProvider);
    if (form.items.isEmpty) {
      warningNotification('Agrega al menos un producto', fromTop: false);
      return;
    }
    // Advierte si algún item deja stock negativo de insumos.
    final conFaltante = form.items.where((it) =>
        ProductionPreview.faltantes(it.product, it.cantidad, idPuntoVenta)
            .isNotEmpty);
    if (conFaltante.isNotEmpty) {
      final continuar = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Stock insuficiente'),
          content: Text(
              'Algunos insumos no alcanzan y se generará stock negativo:\n\n'
              '${conFaltante.map((it) => '• ${it.product.nombre}').join('\n')}\n\n¿Registrar de todos modos?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar')),
            TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Registrar')),
          ],
        ),
      );
      if (continuar != true) return;
    }
    try {
      await ref.read(productionFormProvider.notifier).submit(idPuntoVenta);
      ref.read(inventoryProductionListProvider.notifier).refresh();
      if (mounted) {
        successNotification('Orden de producción registrada', fromTop: false);
        Navigator.of(context).pop();
      }
    } catch (e) {
      errorNotification(e.toString(), fromTop: false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(productionFormProvider);
    final productsState = ref.watch(productsProvider);
    final idPuntoVenta = ref.read(sesionProvider).office?.id;

    final resultados = productsState.products
        .where((p) => _tiposProducibles.contains(p.tipoProducto))
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Nueva producción'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildBuscador(productsState.isLoading, resultados),
                if (_loadingProduct)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(
                        child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                const SizedBox(height: 12),
                _buildObservacion(),
                const SizedBox(height: 12),
                if (form.items.isEmpty)
                  _emptyState()
                else
                  ...List.generate(form.items.length,
                      (i) => _itemCard(i, idPuntoVenta)),
                const SizedBox(height: 90),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: form.items.isEmpty
          ? null
          : _buildBottomBar(form, idPuntoVenta),
    );
  }

  // ── Buscador ──────────────────────────────────────────────────────────
  Widget _buildBuscador(bool loading, List<Product> resultados) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Agregar producto a producir',
            style: GoogleFonts.roboto(
                fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Buscar producto producible…',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey.shade300)),
          ),
        ),
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 6),
            constraints: const BoxConstraints(maxHeight: 260),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2))))
                : resultados.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('Sin productos producibles',
                            style: TextStyle(color: Colors.grey.shade500)))
                    : ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: resultados.length,
                        separatorBuilder: (_, i) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (_, i) {
                          final p = resultados[i];
                          return ListTile(
                            dense: true,
                            title: Text(p.nombre ?? '-',
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(p.tipoProducto ?? '',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade500)),
                            trailing: const Icon(Icons.add, size: 18),
                            onTap: () => _selectProduct(p),
                          );
                        },
                      ),
          ),
      ],
    );
  }

  Widget _buildObservacion() {
    return TextField(
      onChanged: (v) =>
          ref.read(productionFormProvider.notifier).setObservacion(v),
      decoration: InputDecoration(
        labelText: 'Observación (opcional)',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
    );
  }

  Widget _emptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.precision_manufacturing_outlined,
              size: 46, color: Colors.grey.shade400),
          const SizedBox(height: 10),
          Text('Busca y agrega los productos a producir',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  // ── Card de item con preview de consumo ──────────────────────────────
  Widget _itemCard(int index, int? idPuntoVenta) {
    final item = ref.watch(productionFormProvider).items[index];
    final product = item.product;
    final receta = ProductionPreview.recetaItems(product);
    final hayFaltante =
        ProductionPreview.faltantes(product, item.cantidad, idPuntoVenta)
            .isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: hayFaltante ? const Color(0xFFE57373) : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(product.nombre ?? '-',
                    style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600, fontSize: 14)),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: () =>
                    ref.read(productionFormProvider.notifier).removeAt(index),
              ),
            ],
          ),
          // Cantidad a producir
          Row(
            children: [
              Text('Producir',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
              const Spacer(),
              _stepper(index, item.cantidad, product.id!),
            ],
          ),
          if (receta.isNotEmpty) ...[
            const Divider(height: 20),
            Text('CONSUMIRÁ',
                style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey.shade500)),
            const SizedBox(height: 6),
            ...receta.map((pi) {
              final req = ProductionPreview.requerido(pi, item.cantidad);
              final disp = ProductionPreview.disponible(pi, idPuntoVenta);
              final ok = disp >= req;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.arrow_right_alt,
                        size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Expanded(
                        child: Text(pi.productoItem?.nombre ?? '-',
                            style: const TextStyle(fontSize: 12))),
                    Text('nec. ${_qty(req)} · hay ${_qty(disp)}  ',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600)),
                    _pill(ok, req - disp),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Producirá ${_qty(item.cantidad)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                Text(
                    'Costo S/ ${_fmt.format(ProductionPreview.costoLote(product, item.cantidad))}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _stepper(int index, double cantidad, int productId) {
    final notifier = ref.read(productionFormProvider.notifier);
    final ctrl = _qtyControllers.putIfAbsent(
        productId, () => TextEditingController(text: _qty(cantidad)));

    void setValue(double v) {
      notifier.setCantidad(index, v);
      // Sincroniza el texto sin perder el cursor.
      final text = _qty(v);
      ctrl.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    return Row(
      children: [
        _roundBtn(Icons.remove, () {
          if (cantidad > 1) setValue(cantidad - 1);
        }),
        SizedBox(
          width: 56,
          child: TextField(
            controller: ctrl,
            textAlign: TextAlign.center,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))
            ],
            decoration: const InputDecoration(
                isDense: true, border: InputBorder.none),
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            onChanged: (v) {
              // Al tipear solo actualizamos el estado (no el controller,
              // para no mover el cursor).
              final parsed = double.tryParse(v);
              if (parsed != null && parsed > 0) {
                notifier.setCantidad(index, parsed);
              }
            },
          ),
        ),
        _roundBtn(Icons.add, () => setValue(cantidad + 1)),
      ],
    );
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 18, color: ColorSchema.primaryColor),
      ),
    );
  }

  Widget _pill(bool ok, double faltan) {
    final bg = ok ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final fg = ok ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(ok ? 'alcanza' : 'faltan ${_qty(faltan)}',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  Widget _buildBottomBar(ProductionFormState form, int? idPuntoVenta) {
    final totalCosto = form.items.fold<double>(
        0, (s, it) => s + ProductionPreview.costoLote(it.product, it.cantidad));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${form.items.length} producto(s)',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  Text('Costo total S/ ${_fmt.format(totalCosto)}',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: form.submitting || idPuntoVenta == null
                  ? null
                  : () => _registrar(idPuntoVenta),
              icon: form.submitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.check),
              label: const Text('Registrar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _qty(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toString();
}
