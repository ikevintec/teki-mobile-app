import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedido_list_item.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_style.dart';

void main() {
  testWidgets(
    'lista del pedido usa fecha, serie, moneda y acción sin estados SUNAT',
    (tester) async {
      var abierto = false;
      await tester.pumpWidget(
        MaterialApp(
          home: PedidosStyle(
            child: Scaffold(
              body: PedidoListItem(
                pedido: {
                  'fechaEmision': '2026-09-21',
                  'serie': 'PE01',
                  'numero': 4,
                  'denominacionReceptor': 'Bodega Norte',
                  'codigoMoneda': 'PEN',
                  'totalVenta': 30,
                  'tipoVenta': 'CONTADO',
                  'estadoCotizacion': 'CONCRETADA',
                },
                onTap: () => abierto = true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('21'), findsOneWidget);
      expect(find.text('SET'), findsOneWidget);
      expect(find.text('PE01 - 4'), findsOneWidget);
      expect(find.text('S/ 30.00'), findsOneWidget);
      expect(find.text('Al contado'), findsOneWidget);
      expect(find.text('Convertido en venta'), findsOneWidget);
      expect(find.textContaining('SUNAT'), findsNothing);
      expect(find.byType(Card), findsNothing);
      await tester.tap(find.text('PE01 - 4'));
      expect(abierto, isTrue);
    },
  );

  testWidgets('datos faltantes no inventan fecha, cliente o un importe cero', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PedidosStyle(
          child: Scaffold(
            body: PedidoListItem(
              pedido: const {'fechaEmision': 'no-fecha'},
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Sin cliente'), findsOneWidget);
    expect(find.text('Sin importe'), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    expect(find.text('Al contado'), findsNothing);
  });

  for (final escala in [1.0, 2.0]) {
    testWidgets(
      'cliente e importe largos conservan acceso a 320px y escala $escala',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: PedidosStyle(
              child: Scaffold(
                body: PedidoListItem(
                  pedido: {
                    'fechaEmision': '2026-11-21',
                    'serie': 'PE01',
                    'numero': 1234567,
                    'denominacionReceptor':
                        'COMERCIALIZADORA DE PRODUCTOS PARA BODEGAS CON NOMBRE LARGO',
                    'codigoMoneda': 'USD',
                    'totalVenta': 123456789.99,
                    'estadoCotizacion': 'ANULADA',
                  },
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Anulado'), findsOneWidget);
        expect(find.text('\$ 123,456,789.99'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
