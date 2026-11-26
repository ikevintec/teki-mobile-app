import 'package:teki_app/src/presentation/screens/pedidos/pedido_form.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import '../support/loyalty_fixture.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/services/distribuidor/pedidos_service.dart';
import 'package:dio/dio.dart';
import '../support/borradores_pedidos_fixture.dart';
import 'listado_pedidos_widget_test.dart' as listado;

Finder fila(int i) => find.byKey(
  ValueKey('borrador-borrador-prueba-${i.toString().padLeft(4, '0')}'),
);
Future<void> deslizar(WidgetTester t, int i) async {
  await t.drag(fila(i), const Offset(-400, 0));
  await t.pumpAndSettle();
}

Future<void> tocarEliminar(WidgetTester t, int i) =>
    t.tap(find.descendant(of: fila(i), matching: find.text('Eliminar')));

void main() {
  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets('deslizar y eliminar sin abrir ni confirmar $size', (t) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      final api = BorradoresPedidosAdapter();
      await listado.abrir(t, api);
      await deslizar(t, 1);
      await tocarEliminar(t, 1);
      await t.pumpAndSettle();
      expect(find.text('Borrador QA 1'), findsNothing);
      expect(find.text('Borrador QA 2'), findsOneWidget);
      expect(find.text('Borrador eliminado.'), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(PedidoForm), findsNothing);
      expect(api.eliminaciones, 1);
      final req = api.requests.singleWhere((r) => r.method == 'DELETE');
      expect(req.queryParameters, {'revision': 3, 'idPuntoVenta': 1});
      expect(
        api.requests.where((r) => r.method == 'PUT' || r.method == 'POST'),
        isEmpty,
      );
      await t.tap(find.byTooltip('Actualizar'));
      await t.pumpAndSettle();
      expect(find.text('Borrador QA 1'), findsNothing);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    });
  }
  testWidgets('fallo conserva borrador y permite reintentar', (t) async {
    final api = BorradoresPedidosAdapter()..fallar = true;
    await listado.abrir(t, api);
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pumpAndSettle();
    expect(find.text('Borrador QA 1'), findsOneWidget);
    api.fallar = false;
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pumpAndSettle();
    expect(find.text('Borrador QA 1'), findsNothing);
    expect(api.eliminaciones, 2);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('revisión vieja no elimina el borrador editado', (t) async {
    final api = BorradoresPedidosAdapter();
    await listado.abrir(t, api);
    api.borradores.first['revision'] = 4;
    // El JSON del listado ya capturó revisión3, no cambia con el servidor.
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pumpAndSettle();
    expect(find.text('Borrador QA 1'), findsOneWidget);
    expect(
      find.text('El borrador cambió. Actualiza la lista.'),
      findsOneWidget,
    );
    expect(api.borradores, hasLength(2));
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('operación pendiente no abre editor ni duplica eliminación', (
    t,
  ) async {
    final espera = Completer<void>();
    final api = BorradoresPedidosAdapter()
      ..antesEliminar = (_) => espera.future;
    await listado.abrir(t, api);
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Borrador QA 1'));
    await t.pump();
    expect(api.eliminaciones, 1);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      api.requests.where((r) => r.method == 'PUT' || r.method == 'POST'),
      isEmpty,
    );
    espera.complete();
    await t.pumpAndSettle();
    expect(find.text('Borrador QA 1'), findsNothing);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets('respuesta perdida se recupera con el mismo borrado', (t) async {
    final api = BorradoresPedidosAdapter()..perderRespuestaEliminar = true;
    await listado.abrir(t, api);
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pumpAndSettle();
    expect(find.text('Borrador QA 1'), findsOneWidget);
    expect(api.borradores, hasLength(1));
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pumpAndSettle();
    expect(find.text('Borrador QA 1'), findsNothing);
    expect(api.eliminaciones, 2);
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
  testWidgets(
    'al borrar reinicia paginación y no omite el siguiente registro',
    (t) async {
      final api = BorradoresPedidosAdapter(cantidad: 21);
      await listado.abrir(t, api);
      await deslizar(t, 1);
      await tocarEliminar(t, 1);
      await t.pumpAndSettle();
      expect(
        api.requests
            .where((r) => r.path.endsWith('/borradores'))
            .last
            .queryParameters['pagina'],
        0,
      );
      await t.scrollUntilVisible(
        find.text('Borrador QA 21'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Borrador QA 21'), findsOneWidget);
      expect(api.borradores, hasLength(20));
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  test('servicio no envía DELETE si ya cambió la sesión', () async {
    final api = BorradoresPedidosAdapter();
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = api;
    final servicio = PedidosService(
      'contexto-qa',
      dio: dio,
      sigueEnContexto: () => false,
    );
    await expectLater(
      servicio.eliminarBorrador('borrador-prueba-0001', 3, 1),
      throwsStateError,
    );
    expect(api.eliminaciones, 0);
  });
  testWidgets('respuesta de borrado anterior no cambia la nueva sede', (
    t,
  ) async {
    final espera = Completer<void>();
    final api = BorradoresPedidosAdapter()
      ..antesEliminar = (_) => espera.future;
    await listado.abrir(t, api);
    await deslizar(t, 1);
    await tocarEliminar(t, 1);
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    final container = ProviderScope.containerOf(
      t.element(find.byType(PedidosScreen)),
    );
    final session = container.read(sesionProvider);
    api.borradores.first['idPuntoVenta'] = 2;
    api.borradores.first['nombre'] = 'Borrador nueva sede';
    (container.read(sesionProvider.notifier) as LoyaltySessionNotifier).replace(
      session.copyWith(office: Office(id: 2)),
    );
    await t.pumpAndSettle();
    expect(find.text('Borrador nueva sede'), findsOneWidget);
    espera.complete();
    await t.pumpAndSettle();
    expect(find.text('Borrador nueva sede'), findsOneWidget);
    expect(find.text('Borrador eliminado.'), findsNothing);
    expect(api.borradores.where((b) => b['idPuntoVenta'] == 2), hasLength(1));
    await t.pump(const Duration(seconds: 5));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });
}
