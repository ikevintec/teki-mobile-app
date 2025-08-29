import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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

  void openNewSale(WidgetRef ref) {
    final ticket = ref.read(ticketProvider);
    if (ticket.isEdit) {
      // Limpiar completamente todos los providers para nueva venta
      ref.invalidate(ticketProvider);
      ref.invalidate(productSaleProvider);
      ref.invalidate(customerSaleProvider);
    }
    Get.toNamed(AppRoutes.productsSales);
  }

  // Lista de servicios para Venta
  List<Map<String, dynamic>> getVentaServicesList(WidgetRef ref) {
    return [
      {
        'title': 'Productos',
        'icon': 'assets/icons/icon_image/products.png',
        'action': () => Get.toNamed(AppRoutes.products),
      },
      {
        'title': 'Comprobantes',
        'icon': 'assets/icons/icon_image/expense_list.png',
        'action': () => Get.toNamed(AppRoutes.comprobantesVer),
      },
      {
        'title': 'Nueva Ventas',
        'icon': 'assets/icons/icon_image/pos.png',
        'action': () => openNewSale(ref),
      },
      {
        'title': 'Clientes',
        'icon': 'assets/icons/icon_image/customer.png',
        'action': () => Get.toNamed(AppRoutes.customer),
      },
      {
        'title': 'Stats',
        'icon': 'assets/icons/icon_image/trading.png',
        'action': () => Get.toNamed(AppRoutes.analytics),
      },
      {
        'title': 'Ajustes',
        'icon': 'assets/icons/icon_image/user_management.png',
        'action': () => Get.toNamed(AppRoutes.settings),
      },
    ];
  }

  // Lista de servicios para Restaurant
  List<Map<String, dynamic>> getRestaurantServicesList(WidgetRef ref) {
    return [
      {
        'title': 'Pedidos',
        'icon': 'assets/icons/icon_image/pos.png',
        'action': () => openNewSale(ref), // Placeholder
      },
      {
        'title': 'Cocina',
        'icon': 'assets/icons/icon_image/expense_list.png',
        'action': () => Get.toNamed(AppRoutes.comprobantesVer), // Placeholder
      },
      {
        'title': 'Reportes',
        'icon': 'assets/icons/icon_image/trading.png',
        'action': () => Get.toNamed(AppRoutes.analytics),
      },
      {
        'title': 'Config',
        'icon': 'assets/icons/icon_image/user_management.png',
        'action': () => Get.toNamed(AppRoutes.settings),
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
                  offset: const Offset(0, -2),
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
          height: 50,
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
        margin: const EdgeInsets.all(4),
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
              SizedBox(
                height: 70,
              ),
              ImageIcon(
                AssetImage(serviceIcon),
                color: serviceImageColor,
                size: 45,
              )
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
