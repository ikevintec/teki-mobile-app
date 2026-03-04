import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';

class ServicesSection extends ConsumerStatefulWidget {
  // Parámetro dinámico para controlar las columnas del grid
  static const int gridColumnsCount = 2;
  // Prop para mostrar/ocultar el navigation bar
  final bool showNavigationBar;
  
  const ServicesSection({super.key, this.showNavigationBar = false});

  @override
  ConsumerState<ServicesSection> createState() => _ServicesSectionState();
}

class _ServicesSectionState extends ConsumerState<ServicesSection> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> openNewSale(WidgetRef ref) async {
    final ticketState = ref.read(ticketProvider);
    final ticket = ticketState.ticket;
    final productState = ref.read(productSaleProvider);
    final customerState = ref.read(customerSaleProvider);

    final hasData = (ticket.items?.isNotEmpty ?? false) ||
        ticketState.isEdit ||
        productState.productsSales.isNotEmpty ||
        (customerState.customer.razonSocial?.isNotEmpty ?? false);

    // "De orden" si el ticket lo indica o si hay productos bloqueados (de un check de restaurante)
    final fromOrder = ticket.pedidoRestaurante != null ||
        productState.productsSales.any((td) => td.comandaDetalle != null);

    void resetAndNavigate() {
      ref.invalidate(ticketProvider);
      ref.invalidate(productSaleProvider);
      ref.invalidate(customerSaleProvider);
      Get.toNamed(AppRoutes.productsSales);
    }

    // Si viene de una orden de restaurante: siempre reiniciar sin preguntar
    if (hasData && fromOrder) {
      resetAndNavigate();
      return;
    }

    // Sin datos: navegar directo
    if (!hasData) {
      Get.toNamed(AppRoutes.productsSales);
      return;
    }

    // Hay datos pero no es de orden: preguntar al usuario
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

  // Lista de servicios para Venta
  List<Map<String, dynamic>> getVentaServicesList(WidgetRef ref) {
    return [
      {
        'title': 'Nueva Venta',
        'icon': 'assets/icons/icon_svg/purchase_service_icon.svg',
        'action': () => openNewSale(ref),
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
  }

  // Lista de servicios para Restaurant
  List<Map<String, dynamic>> getRestaurantServicesList(WidgetRef ref) {
    return [
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
  }

  // Método para construir una página de servicios
  Widget _buildServicesPage(List<Map<String, dynamic>> services) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: ServicesSection.gridColumnsCount,
          crossAxisSpacing: 15,
          mainAxisSpacing: 13,
          childAspectRatio: 1.3,
        ),
        itemCount: services.length,
        itemBuilder: (context, index) {
          final service = services[index];
          return buildServices(
            context,
            service['title'],
            service['icon'],
            Colors.white,
            ColorSchema.primaryColor,
            service['action'],
          );
        },
      ),
    );
  }

  // Navegar a página específica
  void _navigateToPage(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Área scrolleable de servicios con PageView
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            child: widget.showNavigationBar 
                ? PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    children: [
                      // Página de Venta
                      SingleChildScrollView(
                        child: _buildServicesPage(getVentaServicesList(ref)),
                      ),
                      // Página de Restaurant
                      SingleChildScrollView(
                        child: _buildServicesPage(getRestaurantServicesList(ref)),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    child: _buildServicesPage(getVentaServicesList(ref)),
                  ),
          ),
        ),
        // Bottom Navigation Bar (solo si showNavigationBar es true)
        if (widget.showNavigationBar)
          Container(
            height: 70,
            margin: const EdgeInsets.fromLTRB(25, 0, 25, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 14,
                  offset: const Offset(0, 4), // changes position of shadow
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(
                  icon: Icons.store,
                  label: 'Venta',
                  isSelected: _selectedIndex == 0,
                  onTap: () => _navigateToPage(0),
                ),
                _buildNavItem(
                  icon: Icons.restaurant,
                  label: 'Restaurante',
                  isSelected: _selectedIndex == 1,
                  onTap: () => _navigateToPage(1),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 55,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: isSelected 
                ? ColorSchema.primaryColor.withOpacity(0.1) 
                : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected 
                    ? ColorSchema.primaryColor 
                    : Colors.grey.shade500,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.nunito(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected 
                      ? ColorSchema.primaryColor 
                      : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InkWell buildServices(context, String service, String serviceIcon,
      Color serviceColor, Color serviceImageColor, Function onPressed) {
    return InkWell(
      onTap: () => onPressed(),
      child: Container(
        margin: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.grey.shade200,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(alignment: Alignment.center, children: [
              const SizedBox(height: 70),
              if (serviceIcon.endsWith('.svg'))
                SvgPicture.asset(
                  serviceIcon,
                  colorFilter: ColorFilter.mode(serviceImageColor, BlendMode.srcIn),
                  width: 55,
                  height: 55,
                )
              else
                ImageIcon(
                  AssetImage(serviceIcon),
                  color: serviceImageColor,
                  size: 55,
                ),
            ]),
            Text(
              service,
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.035,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }

  GestureDetector buildReports(
    String title,
    Color reportColor,
    IconData reportIcon,
    double screenWidth,
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(AppRoutes.analytics);
      },
      child: Container(
        width: screenWidth * 0.42,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: reportColor,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3), // changes position of shadow
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white54,
                borderRadius: BorderRadius.circular(50),
              ),
              child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    reportIcon,
                    color: ColorSchema.primaryColor,
                    size: 30,
                  )),
            ),
            const SizedBox(
              height: 4,
            ),
            Text.rich(
              TextSpan(
                style: GoogleFonts.nunito(
                    textStyle: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: MediaQuery.of(context).size.width * 0.045,
                  color: const Color(0xFF333333),
                )),
                children: [
                  TextSpan(text: title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
