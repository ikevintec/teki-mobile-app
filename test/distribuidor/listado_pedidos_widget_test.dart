import 'dart:async';
import 'package:teki_app/src/presentation/screens/pedidos/pedido_list_item.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/constants.dart';
import '../support/pedidos_fixture.dart';
import '../support/loyalty_fixture.dart';

Map<String, dynamic> fila(int id, String cliente) => {
  'id': id,
  'denominacionReceptor': cliente,
  'numeroDocumentoReceptor': '20123456789',
  'serie': 'PE01',
  'numero': id,
  'codigoMoneda': 'PEN',
  'totalVenta': 30,
  'estadoCotizacion': 'PENDIENTE',
  'estadoPedido': 'ENVIADO',
};

Future<void> abrir(
  WidgetTester tester,
  PedidosAdapter adapter, {
  bool oscuro = false,
  double escala = 1,
}) async {
  Get.reset();
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
    ..httpClientAdapter = adapter;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          (_) => LoyaltySessionNotifier(pedidosSession()),
        ),
      ],
      child: GetMaterialApp(
        theme: ThemeData(
          brightness: oscuro ? Brightness.dark : Brightness.light,
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(escala)),
          child: child!,
        ),
        home: const PedidosScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'búsqueda remota con debounce, limpiar y no recargar borradores al escribir',
    (tester) async {
      final adapter = PedidosAdapter()
        ..pedidosIniciales.addAll([
          fila(1, 'Bodega Norte'),
          fila(2, 'Bodega Sur'),
        ]);
      await abrir(tester, adapter);
      expect(find.text('Bodega Norte'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Cliente o documento'),
            )
            .autocorrect,
        isFalse,
      );
      final antes = adapter.requests
          .where((r) => r.path.endsWith('/borradores'))
          .length;
      await tester.enterText(
        find.widgetWithText(TextField, 'Cliente o documento'),
        'Norte',
      );
      await tester.pump(const Duration(milliseconds: 200));
      expect(
        adapter.requests.where(
          (r) => r.queryParameters['filtroRuc'] == 'Norte',
        ),
        isEmpty,
      );
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      expect(find.text('Bodega Norte'), findsOneWidget);
      expect(find.text('Bodega Sur'), findsNothing);
      expect(
        adapter.requests.where((r) => r.path.endsWith('/borradores')).length,
        antes,
      );
      await tester.tap(find.text('Limpiar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Bodega Sur'), findsOneWidget);
    },
  );

  testWidgets(
    'cliente del panel aplica, sincroniza búsqueda y se conserva al reabrir',
    (tester) async {
      final adapter = PedidosAdapter()
        ..pedidosIniciales.addAll([
          fila(1, 'Bodega Norte'),
          fila(2, 'Bodega Sur'),
        ]);
      await abrir(tester, adapter);
      await tester.tap(find.byTooltip('Filtros de pedidos'));
      await tester.pumpAndSettle();
      final cliente = find.widgetWithText(TextFormField, 'Cliente');
      await tester.enterText(cliente, '  Norte  ');
      await tester.ensureVisible(find.text('Aplicar filtros'));
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Bodega Norte'), findsOneWidget);
      expect(find.text('Bodega Sur'), findsNothing);
      expect(
        tester
            .widget<TextField>(
              find.widgetWithText(TextField, 'Cliente o documento'),
            )
            .controller!
            .text,
        'Norte',
      );
      expect(
        adapter.requests
            .lastWhere((r) => r.path == '/quotation')
            .queryParameters['filtroRuc'],
        'Norte',
      );
      await tester.tap(find.byTooltip('Filtros de pedidos'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(cliente).controller!.text, 'Norte');
      await tester.enterText(cliente, 'Sur');
      await tester.tap(find.byTooltip('Cerrar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('Bodega Norte'), findsOneWidget);
      expect(find.text('Bodega Sur'), findsNothing);
      await tester.tap(find.byTooltip('Filtros de pedidos'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(cliente).controller!.text, 'Norte');
      await tester.ensureVisible(find.text('Limpiar filtros').last);
      await tester.tap(find.text('Limpiar filtros').last);
      await tester.pumpAndSettle();
      expect(find.text('Bodega Sur'), findsOneWidget);
      expect(
        adapter.requests
            .lastWhere((r) => r.path == '/quotation')
            .queryParameters
            .containsKey('filtroRuc'),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('una búsqueda anterior tardía no reemplaza el nuevo resultado', (
    tester,
  ) async {
    final adapter = PedidosAdapter()
      ..pedidosIniciales.addAll([fila(1, 'Norte'), fila(2, 'Sur')]);
    await abrir(tester, adapter);
    final pendiente = Completer<void>();
    adapter.antesListado = (r) async {
      if (r.queryParameters['filtroRuc'] == 'Norte') await pendiente.future;
    };
    await tester.enterText(find.byType(TextField).first, 'Norte');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField).first, 'Sur');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PedidoListItem, 'Sur'), findsOneWidget);
    pendiente.complete();
    await tester.pumpAndSettle();
    expect(find.widgetWithText(PedidoListItem, 'Sur'), findsOneWidget);
    expect(find.text('Norte'), findsNothing);
  });

  testWidgets(
    'paginación conserva filtros y reinicia página al cambiar búsqueda',
    (tester) async {
      final adapter = PedidosAdapter()
        ..pedidosIniciales.addAll(
          List.generate(25, (i) => fila(i + 1, 'Bodega ${i + 1}')),
        );
      await abrir(tester, adapter);
      await tester.enterText(find.byType(TextField).first, 'Bodega');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Ver más pedidos'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Ver más pedidos'));
      await tester.pumpAndSettle();
      var q = adapter.requests
          .lastWhere((r) => r.path == '/quotation')
          .queryParameters;
      expect(q['pageNumber'], 1);
      expect(q['filtroRuc'], 'Bodega');
      await tester.scrollUntilVisible(
        find.widgetWithText(TextField, 'Cliente o documento'),
        -500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(find.byType(TextField).first, 'Bodega 25');
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      q = adapter.requests
          .lastWhere((r) => r.path == '/quotation')
          .queryParameters;
      expect(q['pageNumber'], 0);
      expect(q['filtroRuc'], 'Bodega 25');
    },
  );

  testWidgets(
    'un error permite reintentar sin mostrar un falso listado vacío',
    (tester) async {
      final adapter = PedidosAdapter()..fallarListado = true;
      await abrir(tester, adapter);
      expect(find.text('Listado temporalmente no disponible'), findsOneWidget);
      expect(find.textContaining('Aún no tienes pedidos'), findsNothing);
      adapter.fallarListado = false;
      adapter.pedidosIniciales.add(fila(1, 'Bodega recuperada'));
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Bodega recuperada'), findsOneWidget);
      expect(find.text('Listado temporalmente no disponible'), findsNothing);
    },
  );

  for (final size in [
    const Size(360, 640),
    const Size(390, 844),
    const Size(1024, 768),
  ]) {
    testWidgets(
      'filtros, teclado y azul de ventas sin desbordamientos a $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final adapter = PedidosAdapter();
        await abrir(
          tester,
          adapter,
          oscuro: size.width == 1024,
          escala: size.width == 390 ? 1.5 : 1,
        );
        final appbar = tester.widget<AppBar>(find.byType(AppBar));
        expect(
          Theme.of(
            tester.element(find.byType(AppBar)),
          ).appBarTheme.backgroundColor,
          ColorSchema.primaryColor,
        );
        expect(appbar.title, isA<Text>());
        await tester.tap(find.byTooltip('Filtros de pedidos'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Cliente'),
          '20123456789',
        );
        await tester.tap(
          find.widgetWithText(
            DropdownButtonFormField<String>,
            'Estado del pedido',
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Pendientes').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Hoy'));
        await tester.tap(find.text('Hoy'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Serie del pedido'),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Serie del pedido'),
          'pe01',
        );
        await tester.ensureVisible(
          find.widgetWithText(TextFormField, 'Número del pedido'),
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Número del pedido'),
          '123',
        );
        await tester.ensureVisible(find.text('Aplicar filtros'));
        await tester.tap(find.text('Aplicar filtros'));
        await tester.pumpAndSettle();
        final q = adapter.requests
            .lastWhere((r) => r.path == '/quotation')
            .queryParameters;
        expect(q['filtroRuc'], '20123456789');
        expect(q['estadoCotizacion'], 'PENDIENTE');
        expect(q['filtroSerie'], 'PE01');
        expect(q['filtroNumero'], 123);
        expect(q['filtroDesde'], isNotNull);
        expect(q['filtroHasta'], q['filtroDesde']);
        expect(
          find.textContaining('No hay pedidos para estos filtros'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
