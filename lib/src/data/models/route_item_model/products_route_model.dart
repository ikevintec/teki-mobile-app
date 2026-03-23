import 'package:teki_app/src/routes/app_routes.dart';

final List<Map<String, dynamic>> ProductsRouteModel = <Map<String, dynamic>>[
  {
    'icon': "assets/icons/icon_svg/dashboard.svg",
    'label': 'Dashboard',
    'route': AppRoutes.dashboard
  },
  {
    'icon': "assets/icons/icon_svg/product_list.svg",
    'label': 'Product List',
    'route': AppRoutes.products
  },
  {
    'icon': "assets/icons/icon_svg/add_product.svg",
    'label': 'Add Product',
    'route': AppRoutes.addProduct
  },
  {
    'icon': "assets/icons/icon_svg/category.svg",
    'label': 'Category',
    'route': AppRoutes.category
  },
  {
    'icon': "assets/icons/icon_svg/brand.svg",
    'label': 'Brand',
    'route': AppRoutes.brand
  },
  {
    'icon': "assets/icons/icon_svg/unit_management.svg",
    'label': 'Unit Management',
    'route': AppRoutes.unit
  },
];
