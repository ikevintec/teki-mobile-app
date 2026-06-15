import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen.dart/view_comprobante_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/shared/widgets/dismissible_action_widget.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

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
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleEdit(Ticket ticket) async {
    final requiereValidacion = ticket.tipoComprobante == '03' || ticket.tipoComprobante == '07';

    if (!requiereValidacion) {
      Get.to(() => ProductsSaleScreen(id: ticket.id));
      return;
    }

    if (ticket.estadoSunat == 'ACEPT') {
      Get.to(() => ProductsSaleScreen(id: ticket.id));
      return;
    }

    // Estado no aceptado — consultar en tiempo real
    try {
      final resultado = await ref.read(comprobanteProvider.notifier).consultarEstadoSunat(ticket);

      if (resultado.codigo == 'ACEP') {
        Get.to(() => ProductsSaleScreen(id: ticket.id));
      } else {
        warningNotification(
          'El comprobante aún no ha sido aceptado por SUNAT. Estado actual: ${resultado.descripcion}',
          fromTop: false,
        );
      }
    } catch (_) {
      errorNotification('No se pudo verificar el estado SUNAT. Intente nuevamente.', fromTop: false);
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: DismissibleActionWidget(
            actions: createComprobanteActions(
              onEdit: () => _handleEdit(ticket),
              onRemision: () {
                // Acción de remisión
                print('Crear remisión para: ${ticket.id}');
                // Aquí puedes agregar la lógica para crear una remisión
              },
              onGuia: () {
                // Acción de guía
                print('Crear guía para: ${ticket.id}');
                // Aquí puedes agregar la lógica para crear una guía
              },
            ),
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  child: ListTile(
                    leading: const Icon(
                      Icons.receipt_long_rounded,
                      size: 35,
                      color: ColorSchema.primaryColor,
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${formatTipoComprobante(ticket.tipoComprobante ?? '')} ',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: Colors
                                .black, // Color fijo para el tipo de comprobante
                          ),
                        ),
                        Text(
                          '${ticket.serie ?? '--'} - ${ticket.numero ?? '--'}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 4),
                        Text(
                          'Fecha de emisión: ${ticket.fechaEmision?.toString() ?? "--"}',
                          style: GoogleFonts.roboto(fontSize: 11),
                        ),
                        Text(
                          'SUNAT: ${formatEstadoSunat(ticket.estadoSunat ?? '')}',
                          style: GoogleFonts.roboto(fontSize: 11),
                        ),
                        //texto to show if its Anulado or nor
                        Text(
                          ticket.anulado == true ? 'Anulado' : 'Emitido',
                          style: GoogleFonts.roboto(
                            fontSize: 11,
                            color: ticket.anulado == true
                                ? Colors.red
                                : ColorSchema.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${formatExchange(moneda: ticket.codigoMoneda ?? "PEN")}${ticket.totalVenta?.toStringAsFixed(2) ?? "--"}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: ColorSchema.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (ticket.totalValorVentaGratuita != null &&
                            ticket.totalValorVentaGratuita! > 0)
                          Text(
                            '(${formatExchange(moneda: ticket.codigoMoneda ?? "PEN")}${ticket.totalValorVentaGratuita?.toStringAsFixed(2) ?? "--"})',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: ColorSchema.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        //Texto para poner si es al contado o a credito
                        Text(
                          ticket.tipoVenta == 'CONTADO'
                              ? 'Al contado'
                              : 'Al crédito',
                          style: GoogleFonts.roboto(fontSize: 11),
                        ),
                      ],
                    ),
                    onTap: () {
                      //navigate to ViewComponentScreen
                      Get.to(() => ViewComponentScreen(
                          ticket: ticket, id: ticket.id ?? -1));
                    }, // Deshabilita el tap
                  ),
                ),
                Divider(
                  color: Colors.grey[300]!,
                  height: 0.2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
