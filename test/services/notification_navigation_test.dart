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

  testWidgets(
    'un push de pedido reemplaza la pila por Dashboard > Pedidos online',
    (tester) async {
      await tester.pumpWidget(_testApp());
      await tester.pumpAndSettle();
      Get.toNamed('/detalle');
      await tester.pumpAndSettle();

      resetToOnlineOrdersFromNotification(41);
      await tester.pumpAndSettle();

      expect(Get.currentRoute, AppRoutes.onlineOrders);
      expect((Get.arguments as Map<String, dynamic>)['onlineOrderId'], 41);
      Get.back();
      await tester.pumpAndSettle();
      expect(Get.currentRoute, AppRoutes.dashboard);
      expect(find.text('Anterior'), findsNothing);
    },
  );

  test('obtiene el id de pedido desde los formatos enviados por FCM', () {
    expect(onlineOrderIdFromNotificationData({'relatedId': '41'}), 41);
    expect(onlineOrderIdFromNotificationData({'idPedido': 42}), 42);
    expect(
      onlineOrderIdFromNotificationData({
        'payload': '{"idPedido":43,"numeroPedido":7}',
      }),
      43,
    );
    expect(
      onlineOrderIdFromNotificationData({
        'payload': {'idPedido': '44'},
      }),
      44,
    );
  });

  test('ignora ids de pedido ausentes o invalidos', () {
    expect(onlineOrderIdFromNotificationData({}), isNull);
    expect(
      onlineOrderIdFromNotificationData({'payload': 'no-es-json'}),
      isNull,
    );
    expect(onlineOrderIdFromNotificationData({'relatedId': '0'}), isNull);
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
      GetPage(
        name: AppRoutes.onlineOrders,
        page: () => const Scaffold(body: Text('Pedidos online')),
      ),
    ],
  );
}
