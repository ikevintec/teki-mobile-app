import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobantes_detail_modal.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/utils/contstants.dart';


class TicketListSection extends ConsumerStatefulWidget {
  const TicketListSection({super.key});

  @override
  ConsumerState<TicketListSection> createState() => _TicketListSectionState();
}

class _TicketListSectionState extends ConsumerState<TicketListSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final state = ref.read(comprobantesSaleProvider);

      final reachedEnd = _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300;

      if (reachedEnd && state.hasMore && !state.isLoading) {
        ref.read(comprobantesSaleProvider.notifier).fetchMoreTickets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose(); // Limpieza necesaria
    super.dispose();
  }

  String getNombreComprobante(String? tipo) {
    switch (tipo) {
      case '01':
        return 'FACTURA';
      case '03':
        return 'BOLETA';
      case 'NV':
        return 'NOTA DE VENTA';
      default:
        return 'COMPROBANTE';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(comprobantesSaleProvider);
    final tickets = provider.tickets;
    final hasMore = provider.hasMore;
    final isLoading = provider.isLoading;

    final isInitialLoad = isLoading && tickets.isEmpty;

    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return const Center(child: Text("No hay comprobantes por mostrar."));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: tickets.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        // Loader al final
        if (index == tickets.length && hasMore) {
          // Esto garantiza que incluso sin hacer scroll se dispare la siguiente carga
          final state = ref.read(comprobantesSaleProvider);
          if (!state.isLoading) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(comprobantesSaleProvider.notifier).fetchMoreTickets();
            });
          }

          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final ticket = tickets[index];

        return Card(
          elevation: 0.2,
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: Colors.white,
          child: ListTile(
            leading: const Icon(
              Icons.receipt_long_rounded,
              size: 30,
              color: ColorSchema.primaryColor,
            ),
            title: Text(
              '${ticket.serie ?? '--'} - ${ticket.numero ?? '--'} - ${getNombreComprobante(ticket.tipoComprobante)}',
              style: GoogleFonts.raleway(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cliente: ${ticket.denominacionReceptor ?? "Sin nombre"}',
                  style: GoogleFonts.nunito(fontSize: 11),
                ),
                Text(
                  'Emisor: ${ticket.razonSocialEmisor ?? "Sin nombre"}',
                  style: GoogleFonts.nunito(fontSize: 11),
                ),
                Text(
                  'Total: ${ticket.totalVenta?.toStringAsFixed(2) ?? "--"} ${ticket.codigoMoneda ?? ""}',
                  style: GoogleFonts.nunito(fontSize: 11),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined,
                      color: ColorSchema.primaryColor),
                  tooltip: 'Ver comprobante',
                  onPressed: () {
                    showTicketDetailsCustomModal(context, ticket);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.black),
                  tooltip: 'Editar comprobante',
                  onPressed: () {
                    print('Editar comprobante: ${ticket.serie}-${ticket.numero}');
                  },
                ),
              ],
            ),
            onTap: null, // Deshabilita el tap
          ),
        );
      },
    );
  }
}
