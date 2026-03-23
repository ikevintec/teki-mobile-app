import 'package:teki_app/src/routes/app_routes.dart';

final List<Map<String, dynamic>> tradingRouteModel = [
  {
    'icon': "assets/icons/icon_svg/dashboard.svg",
    'label': 'Dashboard',
    'route': AppRoutes.dashboard
  },
  {
    'icon': "assets/icons/icon_svg/sale_icon.svg",
    'label': 'Sale',
    'route': AppRoutes.sales
  },
  {
    'icon': "assets/icons/icon_svg/purchase_icon.svg",
    'label': 'Purchase',
    'route': AppRoutes.purchase
  },
  {
    'icon': "assets/icons/icon_svg/invoice_icon.svg",
    'label': 'Invoice',
    'route': AppRoutes.invoice
  },
];
