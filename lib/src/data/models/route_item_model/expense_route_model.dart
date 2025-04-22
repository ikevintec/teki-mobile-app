import 'package:teki_app/src/routes/app_routes.dart';

final List<Map<String, dynamic>> expenseRouteModel = [
  {
    'icon': "assets/icons/icon_svg/dashboard.svg",
    'label': 'Dashboard',
    'route': AppRoutes.dashboard
  },
  {
    'icon': "assets/icons/icon_svg/add_expense.svg",
    'label': 'Add Expense',
    'route': AppRoutes.expense
  },
  {
    'icon': "assets/icons/icon_svg/expense_list.svg",
    'label': 'Expense List',
    'route': AppRoutes.expenseList
  },
  {
    'icon': "assets/icons/icon_svg/expense_category.svg",
    'label': 'Expense Category',
    'route': AppRoutes.expenseCategory
  },
  {
    'icon': "assets/icons/icon_svg/expense_payment.svg",
    'label': 'Expense Payment',
    'route': AppRoutes.expensePayment
  },
];
