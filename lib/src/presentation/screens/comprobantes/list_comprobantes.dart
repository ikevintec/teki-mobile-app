// ticket_list_section.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/repositories/ticket_sale_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/tickets_sale_repository.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobantes_detail_modal.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/ver_comprbantes.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/notifications.dart';
//import 'ver_comprobante_screen.dart';

final ticketsRepositoryProvider = Provider<TicketsSaleRepository>((ref) {
  return TicketSaleRepositoryImpl();
});

class TicketListSection extends ConsumerStatefulWidget {
  const TicketListSection({super.key});

  @override
  ConsumerState<TicketListSection> createState() => _TicketListSectionState();
}

class _TicketListSectionState extends ConsumerState<TicketListSection> {
  final ScrollController _scrollController = ScrollController();
  final DateFormat _urlFormatter = DateFormat('dd-MM-yyyy H:mm:ss');

  List<Ticket> _tickets = [];
  int _page = 0;
  final int _pageSize = 5;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isInitialLoading = true;

  DateTime? _currentDesde;
  DateTime? _currentHasta;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 300 &&
          !_isLoadingMore &&
          _hasMore) {
        _fetchComprobantes();
      }
    });
  }

  void _fetchComprobantes({bool reset = false}) async {
    final desde = ref.read(filtroDesdeProvider);
    final hasta = ref.read(filtroHastaProvider);

    if (desde == null || hasta == null) return;

    // Evita peticiones duplicadas si las fechas no han cambiado
    if (!reset &&
        desde == _currentDesde &&
        hasta == _currentHasta &&
        !_hasMore) {
      return;
    }

    if (_isLoadingMore) return;

    if (reset) {
      _tickets.clear();
      _page = 0;
      _hasMore = true;
      _isInitialLoading = true;
    }

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final repository = ref.read(ticketsRepositoryProvider);
      final config = ref.read(sesionProvider);
      final selectedCompany = config.companySelected;
      final selectedOffice = config.office;
      final user = ref.read(authStateProvider).user;

      final ruc = selectedCompany?.ruc ?? '';
      final idPuntoVenta = selectedOffice?.id ?? 0;
      final idVendedor = user?.id ?? 0;

      final filtroDesde = _urlFormatter.format(desde);
      final filtroHasta = _urlFormatter.format(hasta);

      final newTickets = await repository.getComprobantes(
        filtroDesde: filtroDesde,
        filtroHasta: filtroHasta,
        rucEmisor: ruc,
        idPuntoVenta: idPuntoVenta,
        idVendedor: idVendedor,
        page: _page,
        size: _pageSize,
      );

      setState(() {
        _tickets.addAll(newTickets);
        _hasMore = newTickets.length == _pageSize;
        _page++;
        _isInitialLoading = false;
        _isLoadingMore = false;
        _currentDesde = desde;
        _currentHasta = hasta;
      });
    } catch (e) {
      errorNotification("Error al obtener los comprobantes: $e");
      setState(() {
        _isInitialLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Escuchar cambios solo UNA VEZ por reconstrucción
    ref.listen<DateTime?>(filtroDesdeProvider, (_, __) {
      _fetchComprobantes(reset: true);
    });

    ref.listen<DateTime?>(filtroHastaProvider, (_, __) {
      _fetchComprobantes(reset: true);
    });

    if (_isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tickets.isEmpty) {
      return const Center(child: Text("No hay comprobantes por mostrar."));
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _tickets.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _tickets.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final ticket = _tickets[index];

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
              '${ticket.serie ?? '--'} - ${ticket.numero ?? '--'}',
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
                    print(
                        'Editar comprobante: ${ticket.serie}-${ticket.numero}');
                  },
                ),
              ],
            ),
            onTap: null, //    que todo el tile  no sea tocable
          ),
        );
        ;
      },
    );
  }
}
