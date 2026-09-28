import 'package:flutter/material.dart' hide Table;
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/presentation/screens/restaurant/widgets/table_card.dart';

void main() {
  test('deserializa y conserva los avisos del comensal', () {
    final table = Table.fromJson({
      'id': 1,
      'numero': 4,
      'llamadaEn': '2026-09-24T10:15:00-05:00',
      'pedidoActual': {
        'id': 10,
        'estado': 'PENDIENTE',
        'cuentaSolicitadaEn': '2026-09-24T10:16:00-05:00',
      },
    });

    expect(table.llamadaEn, isNotNull);
    expect(table.pedidoActual?.cuentaSolicitadaEn, isNotNull);
    expect(table.toJson()['llamadaEn'], isNotNull);
    expect(table.pedidoActual?.toJson()['cuentaSolicitadaEn'], isNotNull);
  });

  testWidgets('anima llamada y cuenta solicitada en una mesa pendiente', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tableCard(
        Table(
          id: 1,
          numero: 4,
          llamadaEn: DateTime(2026, 9, 24, 10, 15),
          pedidoActual: OrderRestaurant(
            id: 10,
            estado: 'PENDIENTE',
            fecha: DateTime.now(),
            cuentaSolicitadaEn: DateTime(2026, 9, 24, 10, 16),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 325));

    expect(find.byKey(const Key('table-call-alert')), findsOneWidget);
    expect(find.text('LLAMANDO'), findsOneWidget);
    expect(find.byKey(const Key('table-account-alert')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _tableCard(
        Table(
          id: 1,
          numero: 4,
          pedidoActual: OrderRestaurant(
            id: 10,
            estado: 'PENDIENTE',
            fecha: DateTime.now(),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('table-call-alert')), findsNothing);
    expect(find.byKey(const Key('table-account-alert')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('oculta el aviso de cuenta cuando ya esta en precuenta', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tableCard(
        Table(
          id: 1,
          numero: 4,
          pedidoActual: OrderRestaurant(
            id: 10,
            estado: 'PRECUENTA',
            fecha: DateTime.now(),
            cuentaSolicitadaEn: DateTime(2026, 9, 24, 10, 16),
          ),
        ),
      ),
    );

    expect(find.byKey(const Key('table-call-alert')), findsNothing);
    expect(find.byKey(const Key('table-account-alert')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra toca para atender cuando el pedido no tiene mozo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _tableCard(
        Table(
          id: 1,
          numero: 4,
          pedidoActual: OrderRestaurant(
            id: 10,
            estado: 'PENDIENTE',
            fecha: DateTime.now(),
            sinMozoAsignado: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 325));

    expect(find.byKey(const Key('table-unassigned-alert')), findsOneWidget);
    expect(find.text('TOCA PARA ATENDER'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Widget _tableCard(Table table) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 190,
          height: 190,
          child: TableCard(table: table, onTap: () {}),
        ),
      ),
    ),
  );
}
