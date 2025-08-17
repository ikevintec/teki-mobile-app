import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticketDetail.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ProductList extends StatelessWidget {
  final List<TicketDetail> detalles;
  final bool incIgv;
  const ProductList({super.key, required this.detalles, required this.incIgv});

  @override
  Widget build(BuildContext context) {
    if (detalles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          'No hay productos en este comprobante',
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
    Color colorBorderTable = ColorSchema.primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: colorBorderTable.withOpacity(0.5)),
            color: Colors.blueAccent.withOpacity(0.1),
            borderRadius: const BorderRadius.only(
              
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Nombre',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Cant.',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ColorSchema.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  'Precio unit.',
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: ColorSchema.primaryColor,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),
        // Product items
        Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: colorBorderTable.withOpacity(0.8)),
              right: BorderSide(color: colorBorderTable.withOpacity(0.8)),
              bottom: BorderSide(color: colorBorderTable.withOpacity(0.8)),
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: detalles.asMap().entries.map((entry) {
              final index = entry.key;
              final detalle = entry.value;
              final isLast = index == detalles.length - 1;
              
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: !isLast ? Border(
                    bottom: BorderSide(
                      color: colorBorderTable.withOpacity(0.25),
                      width: 1,
                    ),
                  ) : null,
                ),
                child: Row(
                  children: [
                    // Product name and details
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            detalle.producto?.nombre ?? 'Producto sin nombre',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (detalle.producto?.codigo?.isNotEmpty == true)
                            Text(
                              'Código: ${detalle.producto!.codigo}',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Quantity
                    Expanded(
                      flex: 1,
                      child: Text(
                        (detalle.cantidad ?? 0).toString(),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // Total price
                    Expanded(
                      flex: 1,
                      child: Text(
                        _formatPrice(detalle.valorUnitario ?? 0),
                        style: GoogleFonts.nunito(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(2);
  }
}
