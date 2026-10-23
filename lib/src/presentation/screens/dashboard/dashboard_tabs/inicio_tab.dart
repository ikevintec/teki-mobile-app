import 'package:teki_app/src/presentation/screens/cotizaciones/quotation_navigation.dart';
import 'package:flutter/material.dart';
import '../navigation/dashboard_navigation.dart';
import '../navigation/dashboard_menu.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/presentation/screens/container_loans/container_loans_main_screen.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_sections/today_reports_section.dart';
import 'package:teki_app/src/presentation/screens/purchases/purchases_main_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/utils/constants.dart';

class InicioTab extends ConsumerStatefulWidget {
  final int idPuntoVenta;
  final ValueNotifier<int> refreshNotifier;
  final VoidCallback? onConnectionError;
  final VoidCallback? onConnectionResolved;

  /// Navega al tab de Caja (lo resuelve el dashboard, dueño de los tabs).
  final VoidCallback? onIrACaja;
  final VoidCallback? onIrAClientes;
  final VoidCallback? onIrAInventario;

  const InicioTab({
    super.key,
    required this.idPuntoVenta,
    required this.refreshNotifier,
    this.onConnectionError,
    this.onConnectionResolved,
    this.onIrACaja,
    this.onIrAClientes,
    this.onIrAInventario,
  });

  @override
  ConsumerState<InicioTab> createState() => _InicioTabState();
}

class _InicioTabState extends ConsumerState<InicioTab> {
  /// Crear una venta requiere permiso (paridad web: VENTAS_CREAR).
  void _irANuevaVenta() {
    if (!dashboardAllows(ref.read(sesionProvider), 'VENTAS_CREAR')) {
      warningNotification('No tienes permiso para crear ventas');
      return;
    }
    Get.toNamed(AppRoutes.productsSales);
  }

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

    final hasData =
        (ticket.items?.isNotEmpty ?? false) ||
        ticketState.isEdit ||
        productState.productsSales.isNotEmpty ||
        (customerState.customer.razonSocial?.isNotEmpty ?? false);

    final fromOrder =
        ticket.pedidoRestaurante != null ||
        productState.productsSales.any((td) => td.comandaDetalle != null);

    void resetAndNavigate() {
      ref.invalidate(ticketProvider);
      ref.invalidate(productSaleProvider);
      ref.invalidate(customerSaleProvider);
      _irANuevaVenta();
    }

    if (hasData && fromOrder) {
      resetAndNavigate();
      return;
    }

    // Sin datos reales en curso: igual hay que garantizar el modo venta,
    // por si quedó en modo cotización de un intento previo sin completar.
    if (!hasData) {
      if (ticketState.isQuotation) {
        resetAndNavigate();
      } else {
        _irANuevaVenta();
      }
      return;
    }

    // Si lo que hay en curso es una cotización, no tiene sentido preguntar
    // "continuar venta": se reinicia directo en modo venta.
    if (ticketState.isQuotation) {
      resetAndNavigate();
      return;
    }

    // Si lo en curso es la edición de una venta ya existente, "Nueva venta"
    // debe forzar una creación nueva, nunca continuar esa edición.
    if (ticketState.isEdit) {
      resetAndNavigate();
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (continuar == true) {
      _irANuevaVenta();
    } else if (continuar == false) {
      resetAndNavigate();
    }
  }

  void _openAction(DashboardAction action) {
    final allowed = dashboardGroups(
      ref.read(sesionProvider),
    ).any((group) => group.actions.contains(action));
    if (!allowed) return;
    switch (action) {
      case DashboardAction.newQuotation:
        openNewQuotation(context, ref);
      case DashboardAction.sale:
        _openNewSale();
      case DashboardAction.customers:
        if (widget.onIrAClientes != null) {
          widget.onIrAClientes!();
        } else {
          Get.toNamed(AppRoutes.customer);
        }
      case DashboardAction.inventory:
        if (widget.onIrAInventario != null) {
          widget.onIrAInventario!();
        } else {
          Get.toNamed(AppRoutes.inventory);
        }
      case DashboardAction.containers:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ContainerLoansMainScreen()),
        );
      case DashboardAction.purchases:
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PurchasesMainScreen()));
      case DashboardAction.collector:
        Get.toNamed(
          AppRoutes.restaurantCobrador,
          arguments: {'pvId': ref.read(sesionProvider).office?.id ?? 0},
        );
      default:
        final route = switch (action) {
          DashboardAction.vouchers => AppRoutes.comprobantesVer,
          DashboardAction.quotations => AppRoutes.quotationsVer,
          DashboardAction.loyalty => AppRoutes.loyaltyCards,
          DashboardAction.products => AppRoutes.products,
          DashboardAction.transfers => AppRoutes.inventoryTransfers,
          DashboardAction.receivable => AppRoutes.accountsReceivable,
          DashboardAction.payable => AppRoutes.accountsPayable,
          DashboardAction.yape => AppRoutes.pagosYape,
          DashboardAction.analytics => AppRoutes.analytics,
          DashboardAction.settings => AppRoutes.settings,
          DashboardAction.tables => AppRoutes.restaurantMesas,
          DashboardAction.orders => AppRoutes.ordersRestaurant,
          DashboardAction.kitchen => AppRoutes.restaurantKitchen,
          _ => null,
        };
        if (route != null) Get.toNamed(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasConnectionError) return _buildNoConnectionScreen();

    final session = ref.watch(sesionProvider);
    final canReadSales = dashboardAllows(session, 'VENTAS_VER');
    final canReadCash = dashboardAllows(session, 'CAJA_VER');
    final dashboardContent = SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (canReadSales || canReadCash) ...[
            TodayReportsSection(
              key: ValueKey((
                _todayReportKey,
                session.companySelected?.id,
                session.login,
                session.roles?.join(','),
              )),
              idPuntoVenta: widget.idPuntoVenta,
              onConnectionError: _onConnectionError,
              onLoadSuccess: _onLoadSuccess,
              onIrACaja: canReadCash ? widget.onIrACaja : null,
            ),
            const SizedBox(height: 24),
          ],
          DashboardMenu(session: session, onAction: _openAction),
        ],
      ),
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
            Icon(Icons.wifi_off_rounded, size: 80, color: Colors.grey.shade300),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
}
