import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen/view_comprobante_screen.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/form_anular_comprobante.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/shared/widgets/dismissible_action_widget.dart';
import 'package:teki_app/src/utils/constants.dart';
import 'package:teki_app/src/utils/formats.dart';
import 'package:teki_app/src/utils/notifications.dart';

class TicketListSection extends ConsumerStatefulWidget {
  const TicketListSection({super.key});

  @override
  ConsumerState<TicketListSection> createState() => _TicketListSectionState();
}

class _TicketListSectionState extends ConsumerState<TicketListSection> {
  final ScrollController _scrollController = ScrollController();
  OverlayEntry? _sunatOverlay;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      final state = ref.read(comprobantesSaleProvider);

      final reachedEnd =
          _scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 300;

      if (reachedEnd && state.hasMore && !state.isLoading) {
        ref.read(comprobantesSaleProvider.notifier).fetchMoreTickets();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _sunatOverlay?.remove();
    super.dispose();
  }

  void _showSunatOverlay() {
    _sunatOverlay = OverlayEntry(
      builder: (_) => const ColoredBox(
        color: Color(0xBB000000),
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 12),
                Text(
                  'Verificando estado SUNAT...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    decoration: TextDecoration.none,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_sunatOverlay!);
  }

  void _hideSunatOverlay() {
    _sunatOverlay?.remove();
    _sunatOverlay = null;
  }

  Future<void> _handleEdit(Ticket ticket) async {
    final requiereValidacion =
        ticket.tipoComprobante == '03' || ticket.tipoComprobante == '07';

    if (!requiereValidacion) {
      Get.to(() => ProductsSaleScreen(id: ticket.id));
      return;
    }

    if (ticket.estadoSunat == 'ACEPT') {
      Get.to(() => ProductsSaleScreen(id: ticket.id));
      return;
    }

    // Estado no aceptado — consultar en tiempo real
    _showSunatOverlay();
    try {
      final resultado = await ref
          .read(comprobanteProvider.notifier)
          .consultarEstadoSunat(ticket);

      if (resultado.codigo == 'ACEP') {
        Get.to(() => ProductsSaleScreen(id: ticket.id));
      } else {
        warningNotification(
          'El comprobante aún no ha sido aceptado por SUNAT. Estado actual: ${resultado.descripcion}',
          fromTop: false,
        );
      }
    } catch (_) {
      errorNotification(
        'No se pudo verificar el estado SUNAT. Intente nuevamente.',
        fromTop: false,
      );
    } finally {
      if (mounted) _hideSunatOverlay();
    }
  }

  void _handleAnular(Ticket ticket) {
    showCustomModal(
      context: context,
      child: FormAnularComprobante(
        ticket: ticket,
        onSuccess: _onRefresh,
      ),
      tittle: 'Anular comprobante',
      allowButtons: false,
      showButtoms: false,
    );
  }

  Future<void> _onRefresh() async {
    final state = ref.read(comprobantesSaleProvider);
    await ref
        .read(comprobantesSaleProvider.notifier)
        .loadFirstPage(
          desde: state.filtroDesde,
          hasta: state.filtroHasta,
          serie: state.filtroSerie,
          numero: state.filtroNumero,
          tiposComprobante: state.filtroTipoComprobante,
          metodosPago: state.idMetodoPago,
          estado: state.filtroEstado,
        );
  }

  // Abreviaturas de mes usadas en Perú (SET, no SEP).
  static const _meses = [
    'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
    'JUL', 'AGO', 'SET', 'OCT', 'NOV', 'DIC',
  ];

  /// Fecha de emisión al estilo de un icono (día grande + mes), en lugar del
  /// icono genérico de comprobante. Si la fecha no parsea, cae al icono.
  Widget _buildFechaTile(String? fechaEmision) {
    final fecha = DateTime.tryParse(fechaEmision ?? '');
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: ColorSchema.primaryColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: fecha == null
          ? const Icon(
              Icons.receipt_long_rounded,
              size: 26,
              color: ColorSchema.primaryColor,
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${fecha.day}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    color: ColorSchema.primaryColor,
                  ),
                ),
                Text(
                  _meses[fecha.month - 1],
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.6,
                    height: 1.1,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(comprobantesSaleProvider);
    final puedeAnular = ref.watch(puedeAnularProvider);
    final puedeEditar = ref.watch(puedeEditarProvider);
    final tickets = provider.tickets;
    final hasMore = provider.hasMore;
    final isLoading = provider.isLoading;

    final isInitialLoad = isLoading && tickets.isEmpty;

    if (isInitialLoad) {
      return const Center(child: CircularProgressIndicator());
    }

    if (tickets.isEmpty) {
      return RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            Padding(
              padding: EdgeInsets.only(top: 120),
              child: Center(child: Text("No hay comprobantes por mostrar.")),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
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
                onEdit: (ticket.anulado == true || !puedeEditar)
                    ? null
                    : () => _handleEdit(ticket),
                onAnular: (puedeAnular && canAnular(ticket))
                    ? () => _handleAnular(ticket)
                    : null,
                onRemision: () {
                  // Acción de remisión
                  debugPrint('Crear remisión para: ${ticket.id}');
                  // Aquí puedes agregar la lógica para crear una remisión
                },
                onGuia: () {
                  // Acción de guía
                  debugPrint('Crear guía para: ${ticket.id}');
                  // Aquí puedes agregar la lógica para crear una guía
                },
              ),
              child: Column(
                children: [
                  Container(
                    color: Colors.white,
                    child: ListTile(
                      leading: _buildFechaTile(ticket.fechaEmision),
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
                            (ticket.denominacionReceptor ?? '').isNotEmpty
                                ? ticket.denominacionReceptor!
                                : 'Sin cliente',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          // La línea de estado solo existe cuando hay algo
                          // que decir: Anulado (domina) o un estado SUNAT
                          // pendiente/rechazado. Lo aceptado lleva su sello
                          // junto al monto y lo demás no necesita etiqueta.
                          Builder(builder: (_) {
                            final String label;
                            final Color color;
                            if (ticket.anulado == true) {
                              label = 'Anulado';
                              color = Colors.red;
                            } else if (ticket.tipoComprobante == 'NV' ||
                                ticket.estadoSunat == 'ACEPT' ||
                                (ticket.estadoSunat ?? '').isEmpty) {
                              // Las notas de venta son documentos internos:
                              // nunca van a SUNAT, no llevan estado.
                              return const SizedBox.shrink();
                            } else if (ticket.estadoSunat == 'RECHA') {
                              label = 'SUNAT: Rechazado';
                              color = Colors.red.shade600;
                            } else {
                              label =
                                  'SUNAT: ${formatEstadoSunat(ticket.estadoSunat)}';
                              color = Colors.orange.shade800;
                            }
                            return Text(
                              label,
                              style: GoogleFonts.roboto(
                                fontSize: 11,
                                color: color,
                              ),
                            );
                          }),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Sello sutil de aceptación SUNAT, sobre el monto.
                          if (ticket.estadoSunat == 'ACEPT' &&
                              ticket.anulado != true) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2ECC71)
                                    .withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'SUNAT',
                                    style: GoogleFonts.roboto(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                      color: const Color(0xFF1565C0),
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    size: 11,
                                    color: Color(0xFF2ECC71),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 2),
                          ],
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
                        Get.to(
                          () => ViewComponentScreen(
                            ticket: ticket,
                            id: ticket.id ?? -1,
                          ),
                        );
                      }, // Deshabilita el tap
                    ),
                  ),
                  Divider(color: Colors.grey[300]!, height: 0.2),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
