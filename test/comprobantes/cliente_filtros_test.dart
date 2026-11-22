import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/filter_actions.dart';
import 'package:teki_app/src/presentation/screens/comprobantes/widgets/clean_filters_button.dart';
import 'package:teki_app/src/providers/comprobantes/comprobantes_notifier.dart';
import 'package:teki_app/src/providers/config/config.dart';
import '../support/loyalty_fixture.dart';

import '../support/ventas_filtros_fixture.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() {
  setUpAll(
    () =>
        dotenv.loadFromString(envString: 'API_URL=https://example.invalid/api'),
  );
  for (final permitido in [false, true]) {
    for (final size in [const Size(390, 844), const Size(1024, 768)]) {
      testWidgets('cliente, filtros y permisos todos=$permitido a $size', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        Get.reset();
        final api = VentasPrueba();
        final session = loyaltySession(
          roles: permitido ? [kRoleVerTodosVendedores] : [],
        );
        final container = ProviderContainer(
          overrides: [
            sesionProvider.overrideWith((_) => LoyaltySessionNotifier(session)),
            comprobantesSaleProvider.overrideWith(
              (ref) => ComprobantesNotifier(repository: api, ref: ref),
            ),
          ],
        );
        addTearDown(container.dispose);
        final notifier = container.read(comprobantesSaleProvider.notifier);
        await notifier.loadFirstPage(
          desde: '01-11-2026',
          hasta: '21-11-2026',
          serie: 'F001',
          numero: '44',
          tiposComprobante: ['01'],
          metodosPago: ['1'],
          estado: 'Activos',
          idVendedor: 2,
        );
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: GetMaterialApp(
              home: const Scaffold(
                body: Row(children: [FilterActions(), CleanFiltersButton()]),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        Future<void> abrir() async {
          await tester.tap(find.text('Mas filtros'));
          await tester.pumpAndSettle();
        }

        Future<void> aplicar() async {
          await tester.ensureVisible(find.text('Aplicar'));
          await tester.pumpAndSettle();
          await tester.tap(find.text('Aplicar'));
          await tester.pumpAndSettle();
        }

        final cliente = find.widgetWithText(TextFormField, 'Nombre, DNI o RUC');
        await abrir();
        expect(
          tester
              .widget<TextField>(
                find.descendant(of: cliente, matching: find.byType(TextField)),
              )
              .autocorrect,
          isFalse,
        );
        await tester.enterText(cliente, '  Bodega Norte  ');
        await aplicar();
        final q = api.consultas.last;
        expect(q['filtroRuc'], 'Bodega Norte');
        expect(q['filtroSerie'], 'F001');
        expect(q['filtroNumero'], '44');
        expect(q['filtroTipoComprobante'], ['01']);
        expect(q['idMetodoPago'], ['1']);
        expect(q['filtroEstadoAnulacion'], false);
        expect(q['idVendedor'], permitido ? 2 : session.login.user!.id);
        expect(api.totales.last['filtroRuc'], 'Bodega Norte');
        await notifier.fetchTotalesFormaPago();
        expect(api.pagos.last['filtroRuc'], 'Bodega Norte');
        await notifier.fetchMoreTickets();
        expect(api.consultas.last['pageNumber'], 1);
        expect(api.consultas.last['filtroRuc'], 'Bodega Norte');
        await abrir();
        expect(
          tester.widget<TextFormField>(cliente).controller!.text,
          'Bodega Norte',
        );
        await tester.enterText(cliente, 'Cambio sin aplicar');
        await tester.ensureVisible(find.text('Volver'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Volver'));
        await tester.pumpAndSettle();
        expect(
          container.read(comprobantesSaleProvider).filtroCliente,
          'Bodega Norte',
        );
        await abrir();
        await tester.enterText(cliente, '   ');
        await aplicar();
        expect(api.consultas.last.containsKey('filtroRuc'), false);
        expect(api.consultas.last['filtroSerie'], 'F001');
        await abrir();
        await tester.enterText(cliente, '20123456789');
        await aplicar();
        expect(api.consultas.last['filtroRuc'], '20123456789');
        expect(api.consultas.last['pageNumber'], 0);
        await abrir();
        await tester.enterText(cliente, '87654321');
        await aplicar();
        expect(api.consultas.last['filtroRuc'], '87654321');
        await notifier.loadFirstPage(desde: '01-10-2026', hasta: '31-10-2026');
        expect(api.consultas.last['filtroRuc'], '87654321');
        await tester.tap(find.byIcon(Icons.cleaning_services_outlined));
        await tester.pumpAndSettle();
        expect(api.consultas.last.containsKey('filtroRuc'), false);
        expect(api.consultas.last['filtroDesde'], '01-10-2026');
        expect(
          api.consultas.last['idVendedor'],
          permitido ? isNull : session.login.user!.id,
        );
        expect(container.read(comprobantesSaleProvider).filtroCliente, '');
        expect(find.byIcon(Icons.cleaning_services_outlined), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
