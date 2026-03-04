import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/productPrice.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ModalProductView extends ConsumerWidget {
  final Product product;
  final int index;
  const ModalProductView({super.key, required this.product, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(productSaleProvider.notifier);

    // Sort prices: POR_DEFECTO first, then ESPECIAL, then MAYOREO
    final allPrices = List<ProductPrice>.from(product.preciosVenta ?? []);
    allPrices.sort((a, b) {
      int order(String? tipo) {
        if (tipo == 'POR_DEFECTO') return 0;
        if (tipo == 'ESPECIAL') return 1;
        return 2; // MAYOREO
      }
      return order(a.tipoPrecio).compareTo(order(b.tipoPrecio));
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        // Image
        Center(
          child: product.imagenUrl != null && product.imagenUrl!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    product.imagenUrl!,
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_outlined,
                      size: 60,
                      color: Colors.grey,
                    ),
                  ),
                )
              : const Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            product.nombre ?? '',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 5),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Text(
                product.detalle ?? '',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: 'Código de barras: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: product.codigoBarra ?? ''),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: 'Código: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: product.codigo ?? ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: 'Tipo de lote: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: product.tipoLote ?? ''),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: 'Unidad: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: product.unidad?.descripcion ?? ''),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: 'Moneda: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: product.moneda ?? ''),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style: const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: 'IGV: ',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                              text: product.igv == true ? 'Sí' : 'No'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 25),
          child: Divider(),
        ),
        const SizedBox(height: 10),
        const Center(
          child: Text(
            'Precios de venta',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: allPrices.map((precio) {
              final isMayoreo = precio.tipoPrecio == 'MAYOREO';
              final label = precio.nombre?.isNotEmpty == true
                  ? precio.nombre!
                  : (precio.tipoPrecio ?? '');

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600),
                            ),
                            if (isMayoreo && precio.unidadesMayoreo != null)
                              Text(
                                'Desde ${precio.unidadesMayoreo} unidades',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        precio.precio?.toStringAsFixed(2) ?? '—',
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      if (!isMayoreo) ...[
                        const SizedBox(width: 10),
                        InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () {
                            if (precio.precio != null) {
                              notifier.applySpecificPrice(
                                  index, precio.precio!);
                              Navigator.of(context).pop();
                            }
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: ColorSchema.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
