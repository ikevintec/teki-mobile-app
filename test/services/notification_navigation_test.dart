import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/routes/app_routes.dart';
import 'package:teki_app/src/shared/services/notification_service.dart';

void main() {
  setUp(() {
    Get.testMode = true;
  });

  tearDown(Get.reset);

  testWidgets('un push de carta reemplaza la pila por Dashboard > Mesas', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();
    Get.toNamed('/detalle');
    await tester.pumpAndSettle();

    resetToRestaurantMesasFromNotification();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.restaurantMesas);
    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.dashboard);
    expect(find.text('Anterior'), findsNothing);
  });

  testWidgets('varios taps seguidos no apilan la pantalla de Mesas', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp());
    await tester.pumpAndSettle();

    resetToRestaurantMesasFromNotification();
    resetToRestaurantMesasFromNotification();
    resetToRestaurantMesasFromNotification();
    await tester.pumpAndSettle();

    expect(Get.currentRoute, AppRoutes.restaurantMesas);
    Get.back();
    await tester.pumpAndSettle();
    expect(Get.currentRoute, AppRoutes.dashboard);
  });
}

Widget _testApp() {
  return GetMaterialApp(
    initialRoute: '/anterior',
    getPages: [
      GetPage(
        name: '/anterior',
        page: () => const Scaffold(body: Text('Anterior')),
      ),
      GetPage(
        name: '/detalle',
        page: () => const Scaffold(body: Text('Detalle')),
      ),
      GetPage(
        name: AppRoutes.dashboard,
        page: () => const Scaffold(body: Text('Dashboard')),
      ),
      GetPage(
        name: AppRoutes.restaurantMesas,
        page: () => const Scaffold(body: Text('Mesas')),
      ),
    ],
  );
}
