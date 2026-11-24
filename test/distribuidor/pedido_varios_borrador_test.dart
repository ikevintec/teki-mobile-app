import 'dart:convert';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/presentation/screens/pedidos/resumen_pedido.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/pedidos_fixture.dart';
import '../support/pedidos_varios_fixture.dart';
import '../support/loyalty_fixture.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets(
      '8 productos, 2 regalos y borrador recuperado del servidor a $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});
        final api = PedidosVariosAdapter();
        Future<void> montar() async {
          Get.reset();
          ApiClient.dio = Dio(
            BaseOptions(baseUrl: 'https://example.invalid/api'),
          )..httpClientAdapter = api;
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
        }

        Future<void> resumen() async {
          await tester.tap(find.byTooltip('Ver resumen'));
          await tester.pumpAndSettle();
          final modal = tester.widget<ResumenPedido>(
            find.byType(ResumenPedido),
          );
          expect(modal.lineas.length, 10);
          expect(modal.total, closeTo(141.70, .001));
          expect(modal.bonificacionesPendientes, isFalse);
          for (var i = 0; i < 8; i++) {
            final l = modal.lineas.singleWhere((l) => l.producto?.id == 10 + i);
            expect(l.cantidad, PedidosVariosAdapter.cantidades[i]);
            expect(
              l.precioVentaUnitario,
              closeTo(PedidosVariosAdapter.precios[i], .001),
            );
            final texto = find.descendant(
              of: find.byType(Dialog),
              matching: find.text(PedidosVariosAdapter.nombres[i]),
            );
            await tester.scrollUntilVisible(
              texto,
              160,
              scrollable: find
                  .descendant(
                    of: find.byType(Dialog),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(texto, findsOneWidget);
          }
          final regalos = modal.lineas
              .where((l) => l.esBonificacion == true)
              .toList();
          expect(regalos.length, 2);
          expect(regalos.singleWhere((l) => l.producto?.id == 90).cantidad, 1);
          expect(regalos.singleWhere((l) => l.producto?.id == 91).cantidad, 2);
          for (final nombre in [
            'Jabón de regalo',
            'Galletas de vainilla de regalo',
            'Total PEN 141.70',
          ]) {
            final texto = find.descendant(
              of: find.byType(Dialog),
              matching: find.text(nombre),
            );
            await tester.scrollUntilVisible(
              texto,
              100,
              scrollable: find
                  .descendant(
                    of: find.byType(Dialog),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
            expect(texto, findsOneWidget);
          }
          expect(api.registros, 0);
          await tester.tap(find.byTooltip('Cerrar resumen'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }

        await montar();
        await tester.tap(find.text('Nuevo pedido'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Seleccionar cliente'));
        await tester.pumpAndSettle();
        await tester.tap(find.textContaining('Bodega Los Olivos').last);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Repetir'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(TextButton, 'Agregar productos'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Elegir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Elegir'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Galletas de vainilla de regalo'));
        await tester.pumpAndSettle();
        await resumen();
        await tester.tap(find.text('Guardar borrador'));
        await tester.pumpAndSettle();
        final primero = api.requests.lastWhere(
          (r) => r.method == 'PUT' && r.path.contains('/borradores/'),
        );
        final guardado = jsonDecode(jsonEncode(primero.data)) as Map;
        expect((guardado['datos']['pedido']['items'] as List).length, 10);
        expect(guardado['datos']['selecciones']['10'], 90);
        expect(
          Ticket.fromJson(
            Map<String, dynamic>.from(guardado['datos']['pedido']),
          ).items!.length,
          10,
        );
        // Nueva sesión de widgets sin estado del carrito; solo el servidor simulado conserva el borrador.
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pumpAndSettle();
        SharedPreferences.setMockInitialValues({});
        await montar();
        await tester.tap(find.widgetWithText(ListTile, 'Bodega Los Olivos'));
        await tester.pumpAndSettle();
        await resumen();
        await tester.tap(find.text('Guardar borrador'));
        await tester.pumpAndSettle();
        final segundo = api.requests.lastWhere(
          (r) => r.method == 'PUT' && r.path.contains('/borradores/'),
        );
        expect(segundo.path, primero.path);
        expect(segundo.data['revision'], 1);
        expect(
          (segundo.data['datos']['pedido']['totalVenta'] as num).toDouble(),
          closeTo(141.70, .001),
        );
        expect((segundo.data['datos']['pedido']['items'] as List).length, 10);
        expect(api.registros, 0);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
