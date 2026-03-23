import 'package:teki_app/src/routes/app_routes.dart';

final List<Map<String, dynamic>> customerRouteModel = [
  {
    'icon': "assets/icons/icon_svg/dashboard.svg",
    'label': 'Dashboard',
    'route': AppRoutes.dashboard
  },
  {
    'icon': "assets/icons/icon_svg/customer_icon.svg",
    'label': 'Customer',
    'route': AppRoutes.customer
  },
  {
    'icon': "assets/icons/icon_svg/supplier_icon.svg",
    'label': 'Supplier',
    'route': AppRoutes.supplier
  },
  {
    'icon': "assets/icons/icon_svg/biller_icon.svg",
    'label': 'Biller',
    'route': AppRoutes.biller
  },
];
