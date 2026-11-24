import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/presentation/screens/kitchen/widgets/kitchen_order_card.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';

void main() {
  testWidgets('pinta borde redondeado con acento lateral sin excepción', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 22, 12);
    final command = Command(
      id: 10,
      numeroComanda: 24,
      fecha: now.subtract(const Duration(minutes: 20)),
      items: [
        CommandDetail(
          id: 100,
          cantidad: 2,
          estadoComandaDetalle: 'PENDIENTE',
          producto: Product(id: 1, nombre: 'Lomo saltado'),
        ),
      ],
    );
    final state = KitchenState(
      now: now,
      commands: [command],
      filters: const KitchenFilters(preparationMinutes: 15),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 406,
              child: KitchenOrderCard(
                command: command,
                state: state,
                onItemTap: (_, _) async {},
                onAdvanceAll: (_) async {},
                onCancellationsSeen: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Lomo saltado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('también pinta el acento rojo de una comanda atrasada', (
    tester,
  ) async {
    final now = DateTime(2026, 9, 22, 12);
    final command = Command(
      id: 11,
      fecha: now.subtract(const Duration(minutes: 35)),
      items: [CommandDetail(id: 101, estadoComandaDetalle: 'PENDIENTE')],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: KitchenOrderCard(
          command: command,
          state: KitchenState(now: now, commands: [command]),
          onItemTap: (_, _) async {},
          onAdvanceAll: (_) async {},
          onCancellationsSeen: (_) {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
  });
}
