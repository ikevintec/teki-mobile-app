import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/today_reports_section.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class InicioTab extends ConsumerStatefulWidget {
  final int idPuntoVenta;
  final ValueNotifier<int> refreshNotifier;
  final VoidCallback? onConnectionError;
  final VoidCallback? onConnectionResolved;

  const InicioTab({
    super.key,
    required this.idPuntoVenta,
    required this.refreshNotifier,
    this.onConnectionError,
    this.onConnectionResolved,
  });

  @override
  ConsumerState<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends ConsumerState<InicioTab> {
  Key _todayReportKey = UniqueKey();
  bool _hasConnectionError = false;
  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    widget.refreshNotifier.addListener(_onRefresh);
  }

  @override
  void dispose() {
    widget.refreshNotifier.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    setState(() {
      _hasConnectionError = false;
      _isRetrying = false;
      _todayReportKey = UniqueKey();
    });
  }

  void _retry() {
    setState(() {
      _hasConnectionError = false;
      _isRetrying = true;
      _todayReportKey = UniqueKey();
    });
  }

  void _onConnectionError() {
    setState(() {
      _hasConnectionError = true;
      _isRetrying = false;
    });
    widget.onConnectionError?.call();
  }

  void _onLoadSuccess() {
    setState(() => _isRetrying = false);
    widget.onConnectionResolved?.call();
  }

  Future<void> _openNewSale() async {
    final ticketState = ref.read(ticketProvider);
    final ticket = ticketState.ticket;
    final productState = ref.read(productSaleProvider);
    final customerState = ref.read(customerSaleProvider);

    final hasData = (ticket.items?.isNotEmpty ?? false) ||
        ticketState.isEdit ||
        productState.productsSales.isNotEmpty ||
        (customerState.customer.razonSocial?.isNotEmpty ?? false);

    final fromOrder = ticket.pedidoRestaurante != null ||
        productState.productsSales.any((td) => td.comandaDetalle != null);

    void resetAndNavigate() {
      ref.invalidate(ticketProvider);
      ref.invalidate(productSaleProvider);
      ref.invalidate(customerSaleProvider);
      Get.toNamed(AppRoutes.productsSales);
    }

    if (hasData && fromOrder) {
      resetAndNavigate();
      return;
    }

    if (!hasData) {
      Get.toNamed(AppRoutes.productsSales);
      return;
    }

    if (!mounted) return;
    final continuar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Venta en progreso',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: const Text('Ya tienes una venta en curso. ¿Qué deseas hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nueva venta'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (continuar == true) {
      Get.toNamed(AppRoutes.productsSales);
    } else if (continuar == false) {
      resetAndNavigate();
    }
  }

  Future<void> _openNewQuotation() async {
    final ticketState = ref.read(ticketProvider);
    final ticket = ticketState.ticket;
    final productState = ref.read(productSaleProvider);
    final customerState = ref.read(customerSaleProvider);

    final hasData = (ticket.items?.isNotEmpty ?? false) ||
        ticketState.isEdit ||
        productState.productsSales.isNotEmpty ||
        (customerState.customer.razonSocial?.isNotEmpty ?? false);

    void resetAndNavigate() {
      ref.invalidate(ticketProvider);
      ref.invalidate(productSaleProvider);
      ref.invalidate(customerSaleProvider);
      ref.read(ticketProvider.notifier).startNewQuotation();
      Get.toNamed(AppRoutes.productsSales);
    }

    if (!hasData) {
      ref.read(ticketProvider.notifier).startNewQuotation();
      Get.toNamed(AppRoutes.productsSales);
      return;
    }

    if (!mounted) return;
    final continuar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Venta en progreso',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: const Text('Ya tienes una venta en curso. ¿Qué deseas hacer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Nueva cotización'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorSchema.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (continuar == false) {
      resetAndNavigate();
    }
  }

  List<Map<String, dynamic>> get _ventaServices => [
        {
          'title': 'Nueva\nVenta',
          'icon': 'assets/icons/icon_svg/purchase_service_icon.svg',
          'action': () => _openNewSale(),
        },
        {
          'title': 'Comprobantes',
          'icon': 'assets/icons/icon_image/voucher_list.png',
          'action': () => Get.toNamed(AppRoutes.comprobantesVer),
        },
        {
          'title': 'Productos',
          'icon': 'assets/icons/icon_image/products_basket.png',
          'action': () => Get.toNamed(AppRoutes.products),
        },
        {
          'title': 'Clientes',
          'icon': 'assets/icons/icon_svg/customer.svg',
          'action': () => Get.toNamed(AppRoutes.customer),
        },
        {
          'title': 'Inventario',
          'icon': 'assets/icons/icon_image/inventory_list.png',
          'action': () => Get.toNamed(AppRoutes.inventory),
        },
        {
          'title': 'Más\nOpciones',
          'icon': 'assets/icons/icon_svg/dots-three.svg',
          'action': () => _showMoreOptionsSheet(),
        },
      ];

  List<Map<String, dynamic>> get _documentosServices => [
        {
          'title': 'Crear Cotización',
          'icon': 'assets/icons/icon_svg/generate_invoice.svg',
          'action': () => _openNewQuotation(),
        },
        {
          'title': 'Ver Cotizaciones',
          'icon': 'assets/icons/icon_svg/invoice_icon.svg',
          'action': () => Get.toNamed(AppRoutes.quotationsVer),
        },
      ];

  List<Map<String, dynamic>> get _cuentasServices => [
        {
          'title': 'Cuentas por Cobrar',
          'icon': 'assets/icons/icon_svg/add_payment.svg',
          'action': () {},
        },
        {
          'title': 'Cuentas por Pagar',
          'icon': 'assets/icons/icon_svg/expense_payment.svg',
          'action': () {},
        },
      ];

  void _showMoreOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Más opciones',
                  style: GoogleFonts.raleway(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: Colors.grey.shade200),
              _buildSheetSectionLabel('Cotizaciones'),
              ..._documentosServices.map(_buildSheetOptionRow),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.raleway(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade500,
          ),
        ),
      ),
    );
  }

  Widget _buildSheetOptionRow(Map<String, dynamic> service) {
    final icon = service['icon'] as String;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        (service['action'] as VoidCallback)();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: ColorSchema.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: SvgPicture.asset(
                  icon,
                  colorFilter: const ColorFilter.mode(
                    ColorSchema.primaryColor,
                    BlendMode.srcIn,
                  ),
                  width: 18,
                  height: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              service['title'] as String,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: ColorSchema.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _generalServices => [
        {
          'title': 'Estadísticas',
          'icon': 'assets/icons/icon_image/stats.png',
          'action': () => Get.toNamed(AppRoutes.analytics),
        },
        {
          'title': 'Ajustes',
          'icon': 'assets/icons/icon_image/settings.png',
          'action': () => Get.toNamed(AppRoutes.settings),
        },
      ];

  List<Map<String, dynamic>> get _restauranteServices => [
        {
          'title': 'Mesas',
          'icon': 'assets/icons/icon_image/dinner-table.png',
          'action': () => Get.toNamed(AppRoutes.restaurantMesas),
        },
        {
          'title': 'Cobrador',
          'icon': 'assets/icons/icon_image/bill_restaurant.png',
          'action': () {
            final pvId = ref.read(sesionProvider).office?.id ?? 0;
            Get.toNamed(AppRoutes.restaurantCobrador, arguments: {'pvId': pvId});
          },
        },
        {
          'title': 'Pedidos',
          'icon': 'assets/icons/icon_image/pedido_add.png',
          'action': () => Get.toNamed(AppRoutes.ordersRestaurant),
        },
      ];

  @override
  Widget build(BuildContext context) {
    if (_hasConnectionError) return _buildNoConnectionScreen();

    final dashboardContent = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ventas del Día — fijo, no escrolea ───────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 30, 0, 0),
          child: TodayReportsSection(
            key: _todayReportKey,
            idPuntoVenta: widget.idPuntoVenta,
            onConnectionError: _onConnectionError,
            onLoadSuccess: _onLoadSuccess,
          ),
        ),
        const SizedBox(height: 24),
        // ── Opciones — escroleable ────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('Venta'),
                const SizedBox(height: 12),
                _buildServicesGrid(_ventaServices),
                const SizedBox(height: 24),
                _buildSectionLabel('Restaurante'),
                const SizedBox(height: 12),
                _buildServicesGrid(_restauranteServices),
                const SizedBox(height: 24),
                _buildSectionLabel('Operaciones'),
                const SizedBox(height: 12),
                _buildServicesGrid(_cuentasServices),
                const SizedBox(height: 24),
                _buildSectionLabel('General'),
                const SizedBox(height: 12),
                _buildServicesGrid(_generalServices),
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );

    // Durante el reintento mantenemos TodayReportsSection montado (para que
    // ejecute las peticiones) pero lo cubrimos con el spinner.
    if (_isRetrying) {
      return Stack(
        children: [
          dashboardContent,
          Positioned.fill(
            child: ColoredBox(
              color: const Color.fromARGB(255, 246, 248, 255),
              child: _buildRetryingScreen(),
            ),
          ),
        ],
      );
    }

    return dashboardContent;
  }

  Widget _buildNoConnectionScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 80,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 20),
            Text(
              'Sin conexión a internet',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica tu conexión e intenta nuevamente',
              textAlign: TextAlign.center,
              style: GoogleFonts.raleway(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(
                'Reintentar',
                style: GoogleFonts.raleway(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorSchema.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRetryingScreen() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: ColorSchema.primaryColor,
            strokeWidth: 2,
          ),
          const SizedBox(height: 16),
          Text(
            'Conectando...',
            style: GoogleFonts.raleway(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: ColorSchema.primaryColor.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.raleway(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: ColorSchema.primaryColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 3),
            height: 1,
            color: ColorSchema.primaryColor.withValues(alpha: 0.15),
          ),
        ),
      ],
    );
  }

  Widget _buildServicesGrid(List<Map<String, dynamic>> services) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final s = services[index];
        return _ServiceCard(
          title: s['title'] as String,
          icon: s['icon'] as String,
          onTap: s['action'] as VoidCallback,
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String icon;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon.endsWith('.svg'))
              SvgPicture.asset(
                icon,
                colorFilter: const ColorFilter.mode(
                  ColorSchema.primaryColor,
                  BlendMode.srcIn,
                ),
                width: 28,
                height: 28,
              )
            else
              ImageIcon(
                AssetImage(icon),
                color: ColorSchema.primaryColor,
                size: 28,
              ),
            const SizedBox(height: 6),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.roboto(
                fontSize: screenWidth * 0.026,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
