import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/providers/cash_register/cash_register_provider.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/contstants.dart';
import 'package:teki_app/src/utils/formats.dart';

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
  String? _selectedMoneda;

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
    // Si el salto es de más de 1 página, usar jumpToPage para evitar
    // el barrido visual por páginas intermedias
    final distance = (index - _pageController.page!.round()).abs();
    if (distance > 1) {
      _pageController.jumpToPage(index);
    } else {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    }

    if (index == 2) {
      _selectedMoneda = null; // reset sin setState — build ya fue disparado arriba
      _fetchCashRegister();
    }
  }

  void _fetchCashRegister() {
    final sesion = ref.read(sesionProvider);
    final idPV = sesion.office?.id ?? 0;
    final idEV = sesion.saleStation?.id ?? 0;
    ref.read(cashRegisterProvider.notifier).fetch(
          idPuntoVenta: idPV,
          idEstacionVenta: idEV,
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
                      // Página de Caja
                      SingleChildScrollView(
                        child: _buildCajaPage(),
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
                  _buildNavItem(
                  icon: Icons.point_of_sale,
                  label: 'Caja',
                  isSelected: _selectedIndex == 2,
                  onTap: () => _navigateToPage(2),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCajaPage() {
    final cajaState = ref.watch(cashRegisterProvider);
    final balance = cajaState.balancePorMoneda;
    final ingresos = cajaState.totalIngresosPorMoneda;
    final egresos = cajaState.totalEgresosPorMoneda;
    final efectivo = cajaState.totalEfectivoPorMoneda;

    final monedas = {...balance.keys}.toList()
      ..sort((a, b) => a == 'PEN' ? -1 : 1);

    // Moneda activa: la seleccionada, o PEN, o la primera disponible
    final monedaActiva = (_selectedMoneda != null && monedas.contains(_selectedMoneda))
        ? _selectedMoneda!
        : (monedas.contains('PEN') ? 'PEN' : (monedas.isNotEmpty ? monedas.first : 'PEN'));

    String fmt(Map<String, double> map, String moneda) {
      final symbol = formatExchange(moneda: moneda);
      final v = map[moneda] ?? 0.0;
      return '$symbol${v.toStringAsFixed(2)}';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 65, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: cajaState.isLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : cajaState.error != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        child: Text(
                          'No se pudo cargar la caja',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            color: Colors.grey.shade400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : Column(
                        children: [
                          // ── Fila 1: Balance + selector de moneda + monto ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Label + dropdown
                                Row(
                                  children: [
                                    Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: ColorSchema.primaryColor
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: ColorSchema.primaryColor,
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Balance',
                                        style: GoogleFonts.nunito(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                    if (monedas.length > 1)
                                      _buildMonedaDropdown(
                                          monedas, monedaActiva),
                                  ],
                                ),
                                // Monto balance
                                Padding(
                                  padding: const EdgeInsets.only(
                                      top: 10, left: 2, bottom: 2),
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      monedas.isEmpty
                                          ? '${formatExchange(moneda: 'PEN')}0.00'
                                          : fmt(balance, monedaActiva),
                                      style: GoogleFonts.nunito(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Divider(
                              height: 1,
                              color: Colors.grey.shade200,
                              indent: 20,
                              endIndent: 20),

                          // ── Fila 2: Ingresos / Egresos ──
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 18),
                            child: monedas.isEmpty
                                ? Text(
                                    'Sin movimientos hoy',
                                    style: GoogleFonts.nunito(
                                      fontSize: 13,
                                      color: Colors.grey.shade400,
                                    ),
                                    textAlign: TextAlign.center,
                                  )
                                : Row(
                                    children: [
                                      // Ingresos
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF22C55E),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  'Ingresos',
                                                  style: GoogleFonts.nunito(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.grey.shade500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              fmt(ingresos, monedaActiva),
                                              style: GoogleFonts.nunito(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color:
                                                    const Color(0xFF16A34A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey.shade200,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 8),
                                      ),
                                      // Egresos
                                      Expanded(
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 8,
                                                    height: 8,
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFEF4444),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Text(
                                                    'Egresos',
                                                    style: GoogleFonts.nunito(
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color:
                                                          Colors.grey.shade500,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                fmt(egresos, monedaActiva),
                                                style: GoogleFonts.nunito(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      const Color(0xFFDC2626),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),

                          // ── Fila 3: Efectivo en caja ──
                          if (monedas.isNotEmpty) ...[
                            Divider(
                                height: 1,
                                color: Colors.grey.shade200,
                                indent: 20,
                                endIndent: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A)
                                          .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.payments_rounded,
                                      size: 15,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Efectivo en caja',
                                      style: GoogleFonts.nunito(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    fmt(efectivo, monedaActiva),
                                    style: GoogleFonts.nunito(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
          ),
          const SizedBox(height: 16),
          // Botón vista completa
          GestureDetector(
            onTap: () {
              // TODO: navegar a la pantalla completa de caja
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: ColorSchema.primaryColor.withOpacity(0.35),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorSchema.primaryColor.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_rounded,
                    size: 18,
                    color: ColorSchema.primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ver detalle de caja',
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: ColorSchema.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonedaDropdown(List<String> monedas, String monedaActiva) {
    return _CurrencySelector(
      monedas: monedas,
      value: monedaActiva,
      onChanged: (v) => setState(() => _selectedMoneda = v),
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

/// Selector de moneda mediante OverlayEntry — no usa Navigator, evita
/// disparar didPopNext en pantallas padres suscritas a RouteObserver.
class _CurrencySelector extends StatefulWidget {
  final List<String> monedas;
  final String value;
  final ValueChanged<String> onChanged;

  const _CurrencySelector({
    required this.monedas,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_CurrencySelector> createState() => _CurrencySelectorState();
}

class _CurrencySelectorState extends State<_CurrencySelector> {
  final _link = LayerLink();
  OverlayEntry? _entry;
  bool _open = false;

  void _toggle() => _open ? _close() : _show();

  void _show() {
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(builder: (_) => _buildOverlay());
    overlay.insert(_entry!);
    setState(() => _open = true);
  }

  void _close() {
    _entry?.remove();
    _entry = null;
    if (mounted) setState(() => _open = false);
  }

  void _select(String moneda) {
    _close();
    widget.onChanged(moneda);
  }

  Widget _buildOverlay() {
    return Stack(
      children: [
        // Barrera transparente — cierra al tocar fuera
        Positioned.fill(
          child: GestureDetector(
            onTap: _close,
            behavior: HitTestBehavior.opaque,
            child: const SizedBox.expand(),
          ),
        ),
        // Menú anclado al botón
        CompositedTransformFollower(
          link: _link,
          showWhenUnlinked: false,
          targetAnchor: Alignment.bottomLeft,
          followerAnchor: Alignment.topLeft,
          offset: const Offset(0, 6),
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: widget.monedas.map((m) {
                    final isSelected = m == widget.value;
                    return InkWell(
                      onTap: () => _select(m),
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            if (isSelected)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(Icons.check_rounded,
                                    size: 13, color: ColorSchema.primaryColor),
                              ),
                            Text(
                              m,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: isSelected
                                    ? ColorSchema.primaryColor
                                    : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _entry?.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _link,
      child: GestureDetector(
        onTap: _toggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _open
                ? ColorSchema.primaryColor.withOpacity(0.12)
                : ColorSchema.primaryColor.withOpacity(0.07),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorSchema.primaryColor.withOpacity(0.25),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.value,
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: ColorSchema.primaryColor,
                ),
              ),
              const SizedBox(width: 2),
              AnimatedRotation(
                turns: _open ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 15,
                  color: ColorSchema.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
