import 'package:flutter/material.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/widgets/upload_image/upload_image.dart';

class ModalProductView extends StatefulWidget {
  final Product product;
  const ModalProductView({super.key, required this.product});

  @override
  State<ModalProductView> createState() => _ModalProductViewState();
}

class _ModalProductViewState extends State<ModalProductView> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10),
        UploadImage(image: "", showButtons: false, onImageSelected: null),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.product.nombre!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 5),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: const Divider(),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              Text(
                widget.product.detalle ?? "",
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: "Código de barras: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: widget.product.codigoBarra ?? ""),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: "Código: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: widget.product.codigo ?? ""),
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
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: "Tipo de lote: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: widget.product.tipoLote ?? ""),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: "Unidad: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: widget.product.unidad?.descripcion ?? ""),
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
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: "Moneda: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: widget.product.moneda ?? ""),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: RichText(
                      textAlign: TextAlign.end,
                      text: TextSpan(
                        style:
                            const TextStyle(fontSize: 12, color: Colors.black),
                        children: [
                          const TextSpan(
                              text: "IGV: ",
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: widget.product.igv == true ? "Sí" : "No"),
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: const Divider(),
        ),
        const SizedBox(height: 10),
        Text(
          "Precios de venta",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: widget.product.preciosVenta!.map((precio) {
              return Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(precio.tipoPrecio ?? "",
                              style: const TextStyle(fontSize: 12)),
                          SizedBox(height: 20),
                          Text(
                            "${precio.precio}",
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
