import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/presentation/screens/pedidos/busqueda_pedido.dart';

void main() {
  late Completer<void> enCamino;

  /// Abre la hoja, busca y toca "Arroz": queda un agregado pendiente.
  Future<void> abrirConPendiente(WidgetTester t) async {
    enCamino = Completer<void>();
    await t.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => buscarEnPedido<String>(
              context,
              'Buscar producto',
              (_) async => ['Arroz'],
              (s) => s,
              lateral: (_) => ('S/ 5.00', 'Stock 10'),
              etiqueta: (_) => 'Promo QA',
              agregar: (_) => enCamino.future,
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField), 'arr');
    await t.pump(const Duration(milliseconds: 300));
    await t.pumpAndSettle();
    await t.tap(find.text('Arroz'));
    await t.pump();
  }

  Finder hoja() => find.text('Buscar producto');

  // Con un agregado pendiente la barra de progreso no se detiene:
  // pumpAndSettle no terminaría, así que se deja correr un tiempo fijo.
  Future<void> esperar(WidgetTester t) async {
    for (var i = 0; i < 10; i++) {
      await t.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('no se cierra con el botón mientras un producto se agrega', (
    t,
  ) async {
    await abrirConPendiente(t);
    expect(find.text('S/ 5.00'), findsOneWidget);
    expect(find.text('Stock 10'), findsOneWidget);
    expect(find.text('🎁 Promo QA'), findsOneWidget);
    final boton = find.widgetWithText(FilledButton, 'Agregando…');
    expect(t.widget<FilledButton>(boton).onPressed, isNull);

    enCamino.complete();
    await t.pumpAndSettle();
    await t.tap(find.text('Listo (1)'));
    await t.pumpAndSettle();
    expect(hoja(), findsNothing);
  });

  testWidgets('tocar fuera no la cierra con un agregado pendiente', (t) async {
    await abrirConPendiente(t);
    await t.tapAt(const Offset(20, 20));
    await esperar(t);
    expect(hoja(), findsOneWidget);

    enCamino.complete();
    await t.pumpAndSettle();
    await t.tapAt(const Offset(20, 20));
    await t.pumpAndSettle();
    expect(hoja(), findsNothing);
  });

  testWidgets('el gesto atrás no la cierra con un agregado pendiente', (
    t,
  ) async {
    await abrirConPendiente(t);
    await t.binding.handlePopRoute();
    await esperar(t);
    expect(hoja(), findsOneWidget);

    enCamino.complete();
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(hoja(), findsNothing);
  });

  testWidgets('arrastrar hacia abajo no la cierra con un agregado pendiente', (
    t,
  ) async {
    await abrirConPendiente(t);
    // Desde el borde superior de la hoja (fuera de la lista, que tiene su
    // propio scroll), como lo haría el usuario.
    final borde = t.getTopLeft(find.byType(BottomSheet)) + const Offset(200, 4);
    await t.flingFrom(borde, const Offset(0, 500), 2000);
    await esperar(t);
    expect(hoja(), findsOneWidget);
    enCamino.complete();
    await t.pumpAndSettle();
  });
}
