import 'package:teki_app/src/routes/app_routes.dart';

final List<Map<String, dynamic>> invoiceRouteModel = [
  {
    'icon': "assets/icons/icon_svg/dashboard.svg",
    'label': 'Dashboard',
    'route': AppRoutes.dashboard
  },
  {
    'icon': "assets/icons/icon_svg/sale_invoice_icon.svg",
    'label': 'Sale Invoice',
    'route': AppRoutes.invoice
  },
  {
    'icon': "assets/icons/icon_svg/purchase_invoice_icon.svg",
    'label': 'Purchase Invoice',
    'route': AppRoutes.purchaseInvoice
  },
  {
    'icon': "assets/icons/icon_svg/expense_invoice_icon.svg",
    'label': 'Expense Invoice',
    'route': AppRoutes.expenseInvoice
  },
];
