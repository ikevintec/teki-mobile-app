import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/repositories/products_repository_impl.dart';
import 'package:teki_app/src/providers/products/products.dart';
import 'package:teki_app/src/utils/constants.dart';

/// Bottom sheet reutilizable para buscar y elegir un producto. Devuelve el
/// producto COMPLETO (findById) para tener sus relaciones (receta, stock).
/// [tiposPermitidos] filtra por tipoProducto si se especifica.
class ProductPickerSheet extends ConsumerStatefulWidget {
  final String titulo;
  final Set<String>? tiposPermitidos;

  const ProductPickerSheet({super.key, required this.titulo, this.tiposPermitidos});

  static Future<Product?> show(
    BuildContext context, {
    required String titulo,
    Set<String>? tiposPermitidos,
  }) {
    return showModalBottomSheet<Product>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ProductPickerSheet(
          titulo: titulo, tiposPermitidos: tiposPermitidos),
    );
  }

  @override
  ConsumerState<ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends ConsumerState<ProductPickerSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // El provider arranca con isLoading=true: sin esta carga inicial el sheet
    // se queda en spinner hasta que el usuario escribe.
    Future.microtask(
        () => ref.read(productsProvider.notifier).searchProducts(''));
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String v) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(productsProvider.notifier).searchProducts(v.trim());
    });
  }

  Future<void> _select(Product p) async {
    setState(() => _loading = true);
    try {
      final full = await ProductsRepositoryImpl().getProductById(p.id!);
      if (mounted) Navigator.of(context).pop(full);
    } catch (_) {
      if (mounted) Navigator.of(context).pop(p);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productsProvider);
    var resultados = state.products;
    if (widget.tiposPermitidos != null) {
      resultados = resultados
          .where((p) => widget.tiposPermitidos!.contains(p.tipoProducto))
          .toList();
    }

    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.titulo,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.bold)),
                  ),
                  IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 20)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: _onChanged,
                decoration: InputDecoration(
                  hintText: 'Buscar producto…',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                ),
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: state.isLoading && resultados.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : resultados.isEmpty
                      ? Center(
                          child: Text('Busca un producto',
                              style: TextStyle(color: Colors.grey.shade500)))
                      : ListView.separated(
                          itemCount: resultados.length,
                          separatorBuilder: (_, i) =>
                              Divider(height: 1, color: Colors.grey.shade200),
                          itemBuilder: (_, i) {
                            final p = resultados[i];
                            return ListTile(
                              title: Text(p.nombre ?? '-',
                                  style: const TextStyle(fontSize: 14)),
                              subtitle: p.codigo != null && p.codigo!.isNotEmpty
                                  ? Text(p.codigo!,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500))
                                  : null,
                              trailing: Icon(Icons.add,
                                  color: ColorSchema.primaryColor),
                              onTap: () => _select(p),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
