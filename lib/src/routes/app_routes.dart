import 'package:get/get.dart';
import 'package:teki_app/src/presentation/screens/analytics/analytics_main_screen.dart';
import 'package:teki_app/src/presentation/screens/authentication/forgot_password_screen.dart';
import 'package:teki_app/src/presentation/screens/authentication/login_screen.dart';
import 'package:teki_app/src/presentation/screens/authentication/register_screen.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_main_screen.dart';
import 'package:teki_app/src/presentation/screens/customer/customer_sections/create_customer_section.dart';
import 'package:teki_app/src/presentation/screens/dashboard/dashboard_main_screen.dart';
import 'package:teki_app/src/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:teki_app/src/presentation/screens/product/product_screen.dart';
import 'package:teki_app/src/presentation/screens/sale/products/products_sale_screen.dart';
import 'package:teki_app/src/presentation/screens/products/products_main_screen.dart';
import 'package:teki_app/src/presentation/screens/profile/profile_main_screen.dart';
import 'package:teki_app/src/presentation/screens/settings/settings_screen.dart';
import 'package:teki_app/src/presentation/screens/splash_screen/splash_screen.dart';
import 'package:teki_app/src/presentation/screens/accounts_receivable/accounts_receivable_main_screen.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/ver_comprobantes.dart';
import 'package:teki_app/src/presentation/screens/cotizaciones/ver_quotations_screen.dart';
import 'package:teki_app/src/presentation/screens/orders_restaurant/orders_restaurant_main_screen.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/presentation/screens/inventory/inventory_main_screen.dart';
import 'package:teki_app/src/presentation/screens/inventory_adjustment/inventory_adjustment_screen.dart';
import 'package:teki_app/src/presentation/screens/inventory_transfer/inventory_transfer_main_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/cobrador/cobrador_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/comanda/comanda_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/dividir/dividir_screen.dart';
import 'package:teki_app/src/presentation/screens/restaurant/restaurant_mesas_screen.dart';
import 'package:teki_app/src/presentation/screens/push_notification_events/dish_desk_ready_screen.dart';
import 'package:teki_app/src/routes/middleware/auth_middleware.dart';

class AppRoutes {
  static const String comprobantesVer = "/ver_comprobantes";
  static const String quotationsVer = "/ver_cotizaciones";
  static const String onboarding = "/onboarding";
  static const String login = "/login";
  static const String register = "/register";
  static const String forgotPassword = "/forgotPassword";
  static const String dashboard = "/dashboard";
  static const String analytics = "/analytics";
  static const String products = "/products";
  static const String customer = "/customer";
  static const String purchaseReports = "/purchaseReports";
  static const String paymentReports = "/paymentReports";
  static const String productsReports = "/productsReports";
  static const String stockReports = "/stockReports";
  static const String expenseReports = "/expenseReports";
  static const String userReports = "/userReports";
  static const String customerReports = "/customerReports";
  static const String warehouseReports = "/warehouseReports";
  static const String supplierReports = "/supplierReports";
  static const String profile = "/profile";
  static const String addCustomer = "/addCustomer";
  static const String createSupplier = "/createSupplier";
  static const String createBiller = "/createBiller";
  static const String purchaseInvoice = "/purchaseInvoice";
  static const String addPurchaseInvoice = "/addPurchaseInvoice";
  static const String splashScreen = "/splashScreen";
  static const String settings = "/settingsScreen";
  // Productos
  static const String createProduct = "/product/create";
  static const String updateProduct = "/product/edit";
  //Ventas
  static const String productsSales = "/products_sale";
  // Inventario
  static const String inventory = "/inventory";
  static const String inventoryAdjustmentCreate = "/inventory-adjustment/create";
  static const String inventoryTransfers = "/inventory-transfers";
  // Restaurante
  static const String restaurantMesas = "/restaurant/mesas";
  static const String restaurantComanda = "/restaurant/comanda";
  static const String restaurantDividir = "/restaurant/dividir";
  static const String restaurantCobrador = "/restaurant/cobrador";
  static const String ordersRestaurant = "/restaurant/orders";
  static const String restaurantDishReady = "/restaurant/dish-ready";
  // Cuentas por cobrar / pagar
  static const String accountsReceivable = "/accounts-receivable";
  static const String accountsPayable = "/accounts-payable";

  static final List<GetPage> _rawPages = [
    GetPage(name: onboarding, page: () => const OnboardingScreen()),
    GetPage(name: login, page: () => const LoginScreen()),
    GetPage(name: register, page: () => const RegisterScreen()),
    GetPage(name: dashboard, page: () => const DashboardMainScreen()),
    GetPage(name: forgotPassword, page: () => const ForgotPasswordScreen()),

    GetPage(name: analytics, page: () => const AnalyticsMainScreen()),
//Route Comprobantes
    GetPage(name: comprobantesVer, page: () => const VerComprobanteScreen()),
    GetPage(name: quotationsVer, page: () => const VerQuotationsScreen()),
    
    
    GetPage(name: products, page: () => const ProductsMainScreen()),
    
    GetPage(name: customer, page: () => const CustomerMainScreen()),
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    GetPage(name: profile, page: () => const ProfileMainScreen()),
    
    
    
    
    
    
    
    GetPage(name: addCustomer, page: () => const AddCustomerSection()),
    
    
    
    
    
    
    
    
    
    
    GetPage(name: splashScreen, page: () => const SplashScreen()),
    GetPage(name: settings, page: () => const SettingsScreen()),
    //Pages for products
    GetPage(name: createProduct, page: () => const ProductScreen()),
    GetPage(
      name: updateProduct,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final productId = args?['id'] as int?;
        return ProductScreen(productId: productId);
      },
    ),
    GetPage(name: productsSales, page: () => const ProductsSaleScreen()),
    // Inventario
    GetPage(name: inventory, page: () => const InventoryMainScreen()),
    GetPage(
      name: inventoryTransfers,
      page: () => const InventoryTransferMainScreen(),
    ),
    GetPage(
      name: inventoryAdjustmentCreate,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final inventory = args?['inventory'] as Inventory?;
        return InventoryAdjustmentScreen(preSelectedInventory: inventory);
      },
    ),
    // Restaurante
    GetPage(name: restaurantMesas, page: () => const RestaurantMesasScreen()),
    GetPage(
      name: restaurantComanda,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final table = args?['table'] as Table?;
        final existingOrderId = args?['existingOrderId'] as int?;
        final isPedidoSinMesa = args?['isPedidoSinMesa'] as bool? ?? false;
        return ComandaScreen(
          table: table,
          existingOrderId: existingOrderId,
          isPedidoSinMesa: isPedidoSinMesa,
        );
      },
    ),
    GetPage(
      name: restaurantDividir,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final order = args?['order'] as OrderRestaurant;
        return DividirScreen(order: order);
      },
    ),
    GetPage(
      name: restaurantCobrador,
      page: () {
        final args = Get.arguments as Map<String, dynamic>?;
        final pvId = args?['pvId'] as int? ?? 0;
        return CobradorScreen(pvId: pvId);
      },
    ),
    GetPage(
      name: ordersRestaurant,
      page: () => const OrdersRestaurantMainScreen(),
    ),
    GetPage(
      name: restaurantDishReady,
      page: () {
        final args = Get.arguments as Map<String, dynamic>;
        return DishDeskReadyScreen(
          commandId: args['commandId'] as int,
          itemId: args['itemId'] as int,
        );
      },
    ),
    // Cuentas por cobrar / pagar
    GetPage(
      name: accountsReceivable,
      page: () => const AccountsReceivableMainScreen(tipoCuenta: 'CC'),
    ),
    GetPage(
      name: accountsPayable,
      page: () => const AccountsReceivableMainScreen(tipoCuenta: 'CP'),
    ),
  ];

  /// Retorna todas las rutas con el middleware aplicado
  static List<GetPage> get pages => _rawPages.map((page) {
        return GetPage(
          name: page.name,
          page: page.page,
          binding: page.binding,
          transition: page.transition,
          transitionDuration: page.transitionDuration,
          curve: page.curve,
          children: page.children,
          participatesInRootNavigator: page.participatesInRootNavigator,
          preventDuplicates: page.preventDuplicates,
          popGesture: page.popGesture,
          middlewares: [AuthMiddleware()], // aquí lo aplicamos a todas
        );
      }).toList();
}
