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

  const InicioTab({
    super.key,
    required this.idPuntoVenta,
    required this.refreshNotifier,
  });

  @override
  ConsumerState<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends ConsumerState<InicioTab> {
  Key _todayReportKey = UniqueKey();

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
    setState(() => _todayReportKey = UniqueKey());
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
      ];

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Ventas del Día — fijo, no escrolea ───────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
          child: TodayReportsSection(
            key: _todayReportKey,
            idPuntoVenta: widget.idPuntoVenta,
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
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
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
                width: 40,
                height: 40,
              )
            else
              ImageIcon(
                AssetImage(icon),
                color: ColorSchema.primaryColor,
                size: 40,
              ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.nunito(
                fontSize: screenWidth * 0.028,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
