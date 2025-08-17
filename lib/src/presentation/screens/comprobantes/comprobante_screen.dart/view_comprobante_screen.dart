import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/comprobante_screen.dart/product_list.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/comprobante_summary.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/form_send_whatsapp.dart';
import 'package:teki_app/src/presentation/screens/viewer/pdf_viewer_screen.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/presentation/widgets/loader/screen_loader.dart';
import 'package:teki_app/src/presentation/widgets/dropdown_action_button/dropdown_action_button.dart';
import 'package:teki_app/src/presentation/widgets/modal/custom_modal.dart';
import 'package:teki_app/src/providers/comprobantes/comprobante.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

class ViewComponentScreen extends ConsumerStatefulWidget {
  final Ticket ticket;
  final int? id;

  const ViewComponentScreen({super.key, required this.ticket, this.id});

  @override
  ConsumerState<ViewComponentScreen> createState() => _ViewComponentScreenState();
}

class _ViewComponentScreenState extends ConsumerState<ViewComponentScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch data if ID is provided
    if (widget.id != null && widget.id! > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(comprobanteProvider.notifier).fetchComprobanteById(widget.id!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(comprobanteProvider);
    
    final ticketToShow = _getTicketToDisplay(provider, widget.ticket, widget.id);

    if (widget.id != null && provider.isLoading) {
      return const ScreenLoader(message: 'Cargando Comprobante...');
    }

    if (widget.id != null && !provider.isLoading && (provider.ticket.id ?? 0) <= 0) {
      return _buildErrorScreen("Comprobante no encontrado.");
    }

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: CustomAppBar(
          navigateName: "Detalle del comprobante",
        ),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 16,bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _buildSendDropdown(ticketToShow, context),
                  const SizedBox(width: 12),
                  _buildDocsDropdown(ticketToShow, context),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    _buildComprobanteSection(ticketToShow),
                    const SizedBox(height: 16),
                    _buildClienteSection(ticketToShow),
                    const SizedBox(height: 16),
                    _buildEmisorSection(ticketToShow),
                    const SizedBox(height: 16),
                    _buildProductsSection(ticketToShow),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              child: _buildComprobanteSummary(ticketToShow),
            ),
          ],
        ),
      ),
    );
  }
}


Ticket _getTicketToDisplay(ComprobanteState provider, Ticket defaultTicket, int? id) {
  if (id != null && (provider.ticket.id ?? 0) > 0) {
    return provider.ticket;
  }
  return defaultTicket;
}

// Helper method to build error screen
Widget _buildErrorScreen(String message) {
  return Scaffold(
    appBar: PreferredSize(
      preferredSize: const Size.fromHeight(60),
      child: CustomAppBar(
        navigateName: "Detalle del comprobante",
      ),
    ),
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.nunito(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            child: const Text('Volver'),
          ),
        ],
      ),
    ),
  );
}

  // Widget methods for better organization
  Widget _buildComprobanteSummary(Ticket ticket) {
    return ComprobanteSummaryWidget(ticket: ticket);
  }

  Widget _buildComprobanteSection(Ticket ticket) {
    return _buildInfoCard(
      title: "Comprobante",
      icon: Icons.receipt_long,
      children: [
        _buildInfoGrid([
          _buildInfoItem("Tipo", formatTipoComprobante(ticket.tipoComprobante ?? ''), Icons.description),
          _buildInfoItem("Serie", ticket.serie ?? '--', Icons.numbers),
          _buildInfoItem("Número", ticket.numero?.toString() ?? '--', Icons.tag),
          _buildInfoItem("Fecha", ticket.fechaEmision ?? '--', Icons.calendar_today),
          _buildInfoItem("Hora", ticket.horaEmision ?? '--', Icons.access_time),
          _buildInfoItem("Tipo Pago", ticket.tipoVenta ?? '--', Icons.payment),
        ]),
      ],
    );
  }

  Widget _buildClienteSection(Ticket ticket) {
    return _buildInfoCard(
      title: "Cliente",
      icon: Icons.person,
      children: [
        _buildFullWidthInfoItem("Nombre", ticket.denominacionReceptor ?? "Sin nombre", Icons.person_outline),
        const SizedBox(height: 12),
        _buildInfoGrid([
          _buildInfoItem("Género", ticket.cliente?.genero ?? "--", Icons.wc),
          _buildInfoItem("Teléfono", ticket.telefonoReceptor ?? '--', Icons.phone),
        ]),
        const SizedBox(height: 12),
        _buildFullWidthInfoItem("Email", ticket.emailReceptor?.isNotEmpty == true ? ticket.emailReceptor! : "--", Icons.email),
        const SizedBox(height: 12),
        _buildFullWidthInfoItem("Dirección", ticket.cliente?.direccion ?? "--", Icons.location_on),
      ],
    );
  }

  Widget _buildEmisorSection(Ticket ticket) {
    return _buildInfoCard(
      title: "Emisor",
      icon: Icons.business,
      children: [
        _buildFullWidthInfoItem("Razón Social", ticket.razonSocialEmisor ?? "--", Icons.business_center),
        const SizedBox(height: 12),
        _buildFullWidthInfoItem("RUC", ticket.rucEmisor ?? "--", Icons.assignment_ind),
      ],
    );
  }

  Widget _buildProductsSection(Ticket ticket) {
    return         ProductList(
          detalles: ticket.items ?? [],
          incIgv: ticket.incIgv ?? false,
        );
  }

  Widget _buildSendDropdown(Ticket ticket, BuildContext context) {
    final List<DropdownActionOption> options = [];
    
    options.add(DropdownActionOption(
      label: 'Vía Whatsapp',
      icon: Icons.chat,
      iconColor: Colors.blue[600],
      onPressed: () {
        showCustomModal(
          context: context, 
          child: FormSendWhatsapp(
            ticket: ticket,
          ), 
          tittle: 'Enviar por Whatsapp', 
          allowButtons: false, 
          showButtoms: false,
        );
      },
    ));
    
    // If no contact options available, show disabled dropdown
    if (options.isEmpty) {
      options.add(DropdownActionOption(
        label: 'Sin datos de contacto',
        icon: Icons.info,
        enabled: false,
      ));
    }
    
    return DropdownActionButton(
      options: options,
      label: 'Enviar',
      icon: Icons.share,
      style: DropdownActionButtonStyle.elevated,
      enabled: options.any((option) => option.enabled),
    );
  }
  
  Widget _buildDocsDropdown(Ticket ticket, BuildContext context) {
    final List<DropdownActionOption> options = [];
    
    options.add(DropdownActionOption(
      label: 'Ver PDF',
      icon: Icons.description,
      iconColor: Colors.blue[600],
      onPressed: () {
        Get.to(() => PdfViewerScreen(
              uuid: ticket.uuid!,
              fileName: ticket.identificadorDocumento!,
            ));
      },
    ));
    
    options.add(DropdownActionOption(
      label: 'Ver Ticket',
      icon: Icons.confirmation_number,
      iconColor: Colors.blue[600],
      onPressed: () {
        Get.to(() => PdfViewerScreen(
              uuid: ticket.uuid!,
              fileName: ticket.identificadorDocumento!,
              fileSize: 'TICKET',
            ));
      },
    ));
    
    return DropdownActionButton(
      options: options,
      label: 'Ver Docs',
      icon: Icons.description,
      style: DropdownActionButtonStyle.elevated,
      enabled: true,
    );
  }

  // Helper widgets
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color:  Colors.blueAccent.withOpacity(0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: ColorSchema.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: ColorSchema.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(List<Widget> items) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 3.0, // Adjusted for more compact height
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      children: items,
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.start,
          ),
        ],
      ),
    );
  }
  Widget _buildFullWidthInfoItem(String label, String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
