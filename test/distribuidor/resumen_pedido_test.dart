import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/ticket_detail.dart';
import 'package:teki_app/src/presentation/screens/pedidos/resumen_pedido.dart';

void main() {
  for (final size in [const Size(320, 640), const Size(1024, 768)]) {
    testWidgets('resumen de lectura, nombres largos y escala 2 a $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            brightness: size.width > 320 ? Brightness.dark : Brightness.light,
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => ResumenPedido(
                    cliente: Customer(
                      razonSocial: 'Bodega de demostración con nombre largo',
                      numeroDocumento: '20000000001',
                    ),
                    comprobante: '01',
                    moneda: 'PEN',
                    total: 12345678.90,
                    observacion: 'Entregar en el local indicado',
                    bonificacionesPendientes: true,
                    lineas: [
                      TicketDetail(
                        descripcion:
                            'Producto con una descripción extensa para comprobar la lectura',
                        cantidad: 2,
                        codigoUnidadMedida: 'UND',
                        precioVentaUnitario: 5.5,
                        precioTotal: 11,
                        tipoComercialNombre: 'Mayorista',
                      ),
                      TicketDetail(
                        descripcion: 'Galletas de regalo',
                        cantidad: 1,
                        esBonificacion: true,
                      ),
                    ],
                  ),
                ),
                child: const Text('Abrir'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen del pedido'), findsOneWidget);

      expect(find.text('Enviar pedido'), findsNothing);
      expect(find.byType(TextField), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Gratis'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Gratis'), findsOneWidget);
      expect(find.byIcon(Icons.card_giftcard), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Volver al pedido'),
        180,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Total PEN 12345678.90'), findsOneWidget);
      await tester.tap(find.text('Volver al pedido'));
      await tester.pumpAndSettle();
      expect(find.text('Resumen del pedido'), findsNothing);
    });
  }
}
