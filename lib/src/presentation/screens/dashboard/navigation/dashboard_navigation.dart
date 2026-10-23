import 'package:flutter/material.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';

bool dashboardAllows(SesionState session, String permission) =>
    session.hasPermission('SUPER_USUARIO') || session.hasPermission(permission);

enum DashboardDestination {
  home('Inicio', Icons.home_rounded),
  customers('Clientes', Icons.people_outline_rounded),
  inventory('Inventario', Icons.inventory_2_outlined),
  cash('Caja', Icons.point_of_sale_rounded);

  const DashboardDestination(this.label, this.icon);
  final String label;
  final IconData icon;
}

List<DashboardDestination> dashboardDestinations(SesionState session) => [
  DashboardDestination.home,
  if (dashboardAllows(session, 'CLIENTES_VER')) DashboardDestination.customers,
  if (dashboardAllows(session, 'INVENTARIO_VER'))
    DashboardDestination.inventory,
  if (dashboardAllows(session, 'CAJA_VER')) DashboardDestination.cash,
];

enum DashboardAction {
  sale('Nueva venta', Icons.add_shopping_cart_rounded),
  vouchers('Comprobantes', Icons.receipt_long_outlined),
  newQuotation('Nueva cotización', Icons.add_chart_outlined),
  quotations('Cotizaciones', Icons.request_quote_outlined),
  customers('Clientes', Icons.people_outline_rounded),
  loyalty('Tarjetas de fidelización', Icons.loyalty_outlined),
  containers('Envases pendientes', Icons.recycling_rounded),
  products('Productos', Icons.shopping_bag_outlined),
  inventory('Inventario', Icons.inventory_2_outlined),
  transfers('Traslados', Icons.local_shipping_outlined),
  purchases('Compras', Icons.shopping_cart_outlined),
  receivable('Cuentas por cobrar', Icons.payments_outlined),
  payable('Cuentas por pagar', Icons.account_balance_wallet_outlined),
  yape('Pagos Yape', Icons.phone_android_rounded),
  analytics('Estadísticas', Icons.bar_chart_rounded),
  settings('Ajustes', Icons.settings_outlined),
  tables('Mesas', Icons.table_restaurant_outlined),
  orders('Pedidos', Icons.restaurant_menu_rounded),
  kitchen('Cocina', Icons.soup_kitchen_outlined),
  collector('Cobrador', Icons.point_of_sale_rounded);

  const DashboardAction(this.label, this.icon);
  final String label;
  final IconData icon;
}

class DashboardGroup {
  const DashboardGroup(this.label, this.actions);
  final String label;
  final List<DashboardAction> actions;
}

List<DashboardGroup> dashboardGroups(SesionState session) {
  bool can(String permission) => dashboardAllows(session, permission);
  final groups = [
    DashboardGroup('Ventas', [
      if (can('VENTAS_CREAR')) DashboardAction.sale,
      if (can('VENTAS_VER')) DashboardAction.vouchers,
      if (can('COTIZACION_VER')) DashboardAction.quotations,
      if (can('VENTAS_CREAR') && !can('COTIZACION_VER'))
        DashboardAction.newQuotation,
    ]),
    DashboardGroup('Clientes y fidelización', [
      if (can('CLIENTES_VER')) DashboardAction.customers,
      if (canViewLoyalty(session)) DashboardAction.loyalty,
      if (session.config?.permitirRetornoEnvase == true &&
          session.config?.inventario == true &&
          can('INVENTARIO_VER'))
        DashboardAction.containers,
    ]),
    DashboardGroup('Inventario y abastecimiento', [
      if (can('PRODUCTOS_VER')) DashboardAction.products,
      if (can('INVENTARIO_VER')) DashboardAction.inventory,
      if (can('INVENTARIO_TRASLADO_RAPIDOS')) DashboardAction.transfers,
      if (can('COMPRAS_VER')) DashboardAction.purchases,
    ]),
    DashboardGroup('Cobros y pagos', [
      if (can('CUENTAS_POR_COBRAR_VER')) DashboardAction.receivable,
      if (can('CUENTAS_POR_PAGAR_VER')) DashboardAction.payable,
      // Este módulo usa el flag de empresa; su middleware no exige otro rol.
      if (session.config?.verNotificacionYape == true) DashboardAction.yape,
    ]),
    if (session.config?.esRestaurante == true)
      DashboardGroup('Restaurante', [
        if (can('RESTAURANTE_MESAS_VER')) DashboardAction.tables,
        if (can('RESTAURANTE_PEDIDOS_VER')) DashboardAction.orders,
        if (can('RESTAURANTE_COCINA_VER')) DashboardAction.kitchen,
        if (can('RESTAURANTE_COMANDAS_VER')) DashboardAction.collector,
      ]),
    DashboardGroup('Administración', [
      if (can('REPORTE_VENTAS')) DashboardAction.analytics,
      DashboardAction.settings,
    ]),
  ];
  return groups.where((group) => group.actions.isNotEmpty).toList();
}

List<DashboardAction> dashboardQuickActions(SesionState session) {
  final available = dashboardGroups(session).expand((g) => g.actions).toSet();
  return [
    DashboardAction.sale,
    DashboardAction.vouchers,
    DashboardAction.receivable,
    DashboardAction.containers,
    DashboardAction.loyalty,
    DashboardAction.quotations,
  ].where(available.contains).toList();
}
