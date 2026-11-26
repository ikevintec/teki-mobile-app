import 'package:toastification/toastification.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import '../support/pedidos_fixture.dart';
import '../support/loyalty_fixture.dart';

void main() {
  for (final size in [
    const Size(390, 844),
    const Size(360, 640),
    const Size(1024, 768),
  ]) {
    testWidgets('pedido: búsqueda, cantidad, borrador y envío a $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Get.reset();
      SharedPreferences.setMockInitialValues({});
      final adapter = PedidosAdapter()..conPromocion = size.width == 390;
      ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = adapter;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith(
              (_) => LoyaltySessionNotifier(pedidosSession()),
            ),
          ],
          child: ToastificationWrapper(
            child: GetMaterialApp(
              theme: ThemeData(useMaterial3: true),
              home: const PedidosScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nuevo pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Seleccionar cliente'), findsOneWidget);
      await tester.tap(find.text('Seleccionar cliente'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Bodega Los Olivos').last);
      await tester.pumpAndSettle();
      if (size.width == 390) {
        await tester.tap(find.byType(DropdownButtonFormField<String>).first);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Factura').last);
        await tester.pumpAndSettle();
      }
      await tester.scrollUntilVisible(
        find.text('Agregar productos'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Agregar productos'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Arroz extra 1 kg').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listo').last);
      await tester.pumpAndSettle();
      expect(find.text('Arroz extra 1 kg'), findsWidgets);
      await tester.ensureVisible(find.byTooltip('Sumar una unidad'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Sumar una unidad'));
      await tester.pumpAndSettle();
      expect(find.text('2 und'), findsOneWidget);
      if (size.width == 390) {
        await tester.ensureVisible(find.text('Elegir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elegir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Galletas de vainilla'));
        await tester.pumpAndSettle();
        expect(find.textContaining('1 und de regalo'), findsOneWidget);
      }
      final registrosAntes = adapter.registros;
      await tester.tap(find.byTooltip('Ver resumen'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen del pedido'), findsOneWidget);
      expect(find.text('Bodega Los Olivos'), findsWidgets);
      expect(adapter.registros, registrosAntes);
      if (size.width == 390) expect(find.text('Gratis'), findsOneWidget);
      await tester.tap(find.text('Volver al pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen del pedido'), findsNothing);
      await tester.tap(find.text('Guardar borrador'));
      await tester.pumpAndSettle();
      expect(
        adapter.requests
            .where((r) => r.path.contains('/borradores/') && r.method == 'PUT')
            .length,
        1,
      );
      await tester.tap(find.text('Enviar pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Pedido enviado'), findsOneWidget);
      expect(adapter.registros, 1);
      final envio = adapter.requests.firstWhere(
        (r) => r.path == '/ticket-order/gestion' && r.method == 'POST',
      );
      expect(
        envio.data['pedido']['tipoComprobanteDestino'],
        size.width == 390 ? '01' : 'NV',
      );
      final borrador = adapter.requests.firstWhere(
        (r) => r.path.contains('/borradores/') && r.method == 'PUT',
      );
      expect(
        borrador.data['datos']['pedido']['tipoComprobanteDestino'],
        size.width == 390 ? '01' : 'NV',
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final incompleta in [false, true]) {
    testWidgets(
      'canasta actual en lote, sin aplicar una canasta incompleta: $incompleta',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        Get.reset();
        final adapter = PedidosAdapter()..canastaIncompleta = incompleta;
        ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
          ..httpClientAdapter = adapter;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sesionProvider.overrideWith(
                (_) => LoyaltySessionNotifier(pedidosSession()),
              ),
            ],
            child: ToastificationWrapper(
              child: GetMaterialApp(
                theme: ThemeData(useMaterial3: true),
                home: const PedidosScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Nuevo pedido'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Seleccionar cliente'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Bodega Los Olivos').last);
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Repetir'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(find.text('Repetir'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Agregar productos'));
        await tester.pumpAndSettle();
        if (incompleta) {
          expect(
            find.textContaining('Algunos productos ya no están disponibles'),
            findsWidgets,
          );
        } else {
          expect(find.text('3 und'), findsOneWidget);
          expect(find.text('Total S/ 18.00'), findsOneWidget);
        }
        expect(adapter.requests.where((r) => r.path == '/products').length, 1);
        expect(
          adapter.requests.where((r) => r.path == '/products/1').length,
          incompleta ? 0 : 1,
        );
        expect(adapter.registros, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
