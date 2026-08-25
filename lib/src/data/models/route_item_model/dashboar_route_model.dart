import 'package:teki_app/src/routes/app_routes.dart';

final List<Map<String, dynamic>> DashboardRouteModel = <Map<String, dynamic>>[
  {
    'icon': "assets/icons/icon_svg/dashboard.svg",
    'label': 'Dashboard',
    'route': AppRoutes.dashboard,
  },
  {
    'icon': "assets/icons/icon_svg/profile.svg",
    'label': 'Perfil',
    'route': AppRoutes.profile,
  },
  {
    'icon': "assets/icons/icon_svg/view_payment.svg",
    'label': 'Pagos Yape',
    'route': AppRoutes.pagosYape,
  },
];
