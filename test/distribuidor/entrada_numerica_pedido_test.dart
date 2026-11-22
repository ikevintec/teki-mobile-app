import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/screens/pedidos/precio_linea.dart';
import 'package:teki_app/src/presentation/screens/pedidos/entrada_numerica_pedido.dart';

void main() {
  testWidgets(
    'precio en teléfono pequeño, texto ampliado y teclado permite aplicar',
    (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      double? resultado;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  resultado = await ingresarPrecio(context, actual: 6);
                },
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.enterText(find.byType(TextField), '7.25');
      await tester.ensureVisible(find.text('Aplicar'));
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(resultado, 7.25);
      expect(tester.takeException(), isNull);
    },
  );

  for (final aplicar in [true, false]) {
    testWidgets(
      'precio enfocado: ${aplicar ? 'aplicar' : 'cancelar'} sin romper cierre animado',
      (tester) async {
        double? resultado;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    resultado = await ingresarPrecio(context, actual: 6);
                  },
                  child: const Text('Abrir precio'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir precio'));
        await tester.pumpAndSettle();
        await tester.showKeyboard(find.byType(TextField));
        await tester.enterText(find.byType(TextField), '7,25');
        await tester.tap(find.text(aplicar ? 'Aplicar' : 'Cancelar'));
        await tester.pumpAndSettle();
        expect(resultado, aplicar ? 7.25 : isNull);
        expect(find.text('Precio manual'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final permitirCero in [true, false]) {
    for (final invalido in [
      '',
      '-1',
      'NaN',
      'Infinity',
      '1.2.3',
      if (!permitirCero) '0',
    ]) {
      testWidgets(
        '${permitirCero ? 'precio' : 'cantidad'} inválido "$invalido" explica y permite corregir',
        (tester) async {
          double? resultado;
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder: (context) => TextButton(
                    onPressed: () async {
                      resultado = await showDialog<double>(
                        context: context,
                        builder: (_) => EntradaNumericaPedido(
                          titulo: 'Número de prueba',
                          etiqueta: 'Valor',
                          accion: 'Aceptar',
                          permitirCero: permitirCero,
                        ),
                      );
                    },
                    child: const Text('Abrir'),
                  ),
                ),
              ),
            ),
          );
          await tester.tap(find.text('Abrir'));
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), invalido);
          await tester.tap(find.text('Aceptar'));
          await tester.pumpAndSettle();
          expect(find.text('Número de prueba'), findsOneWidget);
          expect(
            find.textContaining(
              invalido == '-1' || invalido == '0'
                  ? (permitirCero ? 'negativo' : 'mayor a cero')
                  : 'número válido',
            ),
            findsOneWidget,
          );
          expect(resultado, isNull);
          await tester.enterText(find.byType(TextField), ' 2,5 ');
          await tester.testTextInput.receiveAction(TextInputAction.done);
          await tester.pumpAndSettle();
          expect(resultado, 2.5);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'precio cero es válido y volver del sistema cancela sin cambios',
    (tester) async {
      double? resultado;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async =>
                    resultado = await ingresarPrecio(context, actual: 6),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '6.00',
      );
      await tester.enterText(find.byType(TextField), '0');
      await tester.tap(find.text('Aplicar'));
      await tester.pumpAndSettle();
      expect(resultado, 0);
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      await tester.showKeyboard(find.byType(TextField));
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(resultado, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
