import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/payment_detail.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/presentation/screens/sale/widgets/restaurant_tip_summary.dart';

void main() {
  for (final width in [320.0, 820.0]) {
    testWidgets(
      'propina visible, pago separado y eliminación explícita a $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var ticket = Ticket(
          totalVenta: 19.43,
          propina: 5,
          codigoMoneda: 'PEN',
          mozoResponsable: User(id: 3, nombreCompleto: 'Responsable QA'),
          pagosPropina: [PaymentDetail(nombre: 'Yape', monto: 5)],
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) => RestaurantTipSummary(
                  ticket: ticket,
                  onRemove: () => setState(() {
                    ticket = ticket.copyWith(propina: 0, pagosPropina: []);
                  }),
                ),
              ),
            ),
          ),
        );
        expect(find.text('Propina: S/ 5.00'), findsOneWidget);
        expect(find.text('Responsable QA'), findsOneWidget);
        expect(find.text('Yape: S/ 5.00'), findsOneWidget);
        expect(
          find.text('Pago separado del total de la venta.'),
          findsOneWidget,
        );
        await tester.tap(find.text('Quitar propina'));
        await tester.pumpAndSettle();
        expect(find.text('Propina: S/ 5.00'), findsNothing);
        expect(ticket.totalVenta, 19.43);
        expect(ticket.propina, 0);
        expect(ticket.pagosPropina, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
