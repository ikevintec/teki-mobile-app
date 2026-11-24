import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/data/services/distribuidor/pedidos_service.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';

void main() {
  for (final dias in [-800, 800]) {
    testWidgets(
      'retomar entrega a $dias días permite abrir y cancelar calendario',
      (tester) async {
        Get.reset();
        SharedPreferences.setMockInitialValues({});
        final adapter = PedidosAdapter();
        ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
          ..httpClientAdapter = adapter;
        final entrega = DateTime.now().add(Duration(days: dias));
        await tester.runAsync(
          () => PedidosService('qa').guardarBorrador(
            'borrador-fecha-qa-0001',
            0,
            1,
            {
              'pedido': {
                'serie': 'P001',
                'tipoComprobanteDestino': 'NV',
                'codigoMoneda': 'PEN',
                'items': [],
                'adelanto': 0,
                'fechaEntrega': entrega.toIso8601String(),
              },
            },
            'Borrador con entrega',
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              sesionProvider.overrideWith(
                (_) => LoyaltySessionNotifier(pedidosSession()),
              ),
            ],
            child: ToastificationWrapper(
              child: GetMaterialApp(home: const PedidosScreen()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Borrador con entrega'));
        await tester.pumpAndSettle();
        final fecha = find.text(
          'Entrega: ${entrega.day}/${entrega.month}/${entrega.year}',
        );
        await tester.scrollUntilVisible(
          fecha,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.tap(fecha);
        await tester.pumpAndSettle();
        expect(find.byType(DatePickerDialog), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(fecha, findsOneWidget);
      },
    );
  }
}
