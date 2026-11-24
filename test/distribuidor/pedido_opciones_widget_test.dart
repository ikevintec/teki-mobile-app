import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedidos_screen.dart';
import 'package:teki_app/src/presentation/screens/pedidos/pedido_list_item.dart';
import 'package:teki_app/src/presentation/screens/pedidos/resumen_pedido.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/loyalty_fixture.dart';
import '../support/pedidos_fixture.dart';
import '../support/pedidos_opciones_fixture.dart';

Future<void> abrirOpciones(
  WidgetTester t,
  PedidosOpcionesAdapter api, {
  bool permiso = true,
}) async {
  Get.reset();
  SharedPreferences.setMockInitialValues({});
  ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
    ..httpClientAdapter = api;
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        sesionProvider.overrideWith(
          (_) => LoyaltySessionNotifier(
            pedidosSession().copyWith(roles: permiso ? ['SUPER_USUARIO'] : []),
          ),
        ),
      ],
      child: ToastificationWrapper(
        child: GetMaterialApp(home: const PedidosScreen()),
      ),
    ),
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Nuevo pedido'));
  await t.pumpAndSettle();
}

Future<void> agregar(WidgetTester t) async {
  await t.scrollUntilVisible(
    find.text('Agregar productos'),
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pumpAndSettle();
  await t.tap(find.text('Agregar productos'));
  await t.pumpAndSettle();
  await t.tap(find.textContaining('Arroz extra 1 kg').last);
  // Con precio manual la hoja sigue cargando hasta responder el diálogo.
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
  if (find.byType(AlertDialog).evaluate().isEmpty) {
    await t.pumpAndSettle();
    await cerrarBusqueda(t);
  }
}

/// La búsqueda de productos queda abierta para agregar varios; se cierra con Listo.
Future<void> cerrarBusqueda(WidgetTester t) async {
  final listo = find.textContaining('Listo (');
  await t.tap(
    listo.evaluate().isNotEmpty ? listo.last : find.text('Cerrar').last,
  );
  await t.pumpAndSettle();
}

Future<void> cliente(WidgetTester t, String nombre) async {
  await t.tap(find.text('Seleccionar cliente'));
  await t.pumpAndSettle();
  await t.tap(find.textContaining(nombre).last);
  await t.pumpAndSettle();
}

Future<void> visible(WidgetTester t, Finder f, {double direccion = 200}) async {
  await t.scrollUntilVisible(
    f,
    direccion,
    scrollable: find.byType(Scrollable).first,
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets(
    'repetir canasta obtiene detalle completo desde listado ligero y usa precio actual',
    (t) async {
      final api = PedidosOpcionesAdapter()..comercial = false;
      await abrirOpciones(t, api);
      await cliente(t, 'Bodega Los Olivos');
      await t.tap(find.text('Repetir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Agregar productos').last);
      await t.pumpAndSettle();
      expect(api.requests.where((r) => r.path == '/products/1'), hasLength(1));
      expect(find.text('Total S/ 18.00'), findsOneWidget);
      await t.tap(find.byTooltip('Ver resumen'));
      await t.pumpAndSettle();
      final resumen = t.widget<ResumenPedido>(find.byType(ResumenPedido));
      expect(resumen.lineas.single.cantidad, 3);
      expect(resumen.lineas.single.precioVentaUnitario, closeTo(6, .001));
      expect(api.registros, 0);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'fallo de promociones bloquea envío, mantiene productos y recupera con Reintentar',
    (t) async {
      final api = PedidosOpcionesAdapter()..fallarPromos = true;
      await abrirOpciones(t, api);
      await cliente(t, 'Bodega Los Olivos');
      await agregar(t);
      // Enviar no se registra y explica el motivo en lugar de quedar gris.
      await t.tap(find.text('Enviar pedido'));
      await t.pumpAndSettle();
      expect(api.registros, 0);
      expect(find.text('Total S/ 6.00'), findsOneWidget);
      await visible(
        t,
        find
            .text(
              'No se pudo actualizar las bonificaciones. Reintenta antes de enviar.',
            )
            .first,
        direccion: -200,
      );
      api.fallarPromos = false;
      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();
      // El aviso inferior puede seguir unos segundos; el panel ya no muestra el error.
      expect(
        find.descendant(
          of: find.byType(ListView),
          matching: find.text(
            'No se pudo actualizar las bonificaciones. Reintenta antes de enviar.',
          ),
        ),
        findsNothing,
      );
      await t.tap(find.text('Enviar pedido'));
      await t.pumpAndSettle();
      expect(api.registros, 1);
      expect(find.text('Pedido enviado'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('salida con cambios permite continuar y luego salir sin enviar', (
    t,
  ) async {
    final api = PedidosOpcionesAdapter();
    await abrirOpciones(t, api);
    await agregar(t);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('¿Salir del pedido?'), findsOneWidget);
    await t.tap(find.text('Continuar pedido'));
    await t.pumpAndSettle();
    expect(find.text('Total S/ 6.00'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    await t.tap(find.text('Salir sin guardar'));
    await t.pumpAndSettle();
    expect(find.text('Mis pedidos'), findsOneWidget);
    expect(api.registros, 0);
    expect(api.requests.where((r) => r.method == 'PUT'), isEmpty);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'pedido tradicional conserva precio manual al cambiar cantidad y en borrador',
    (t) async {
      final api = PedidosOpcionesAdapter()..comercial = false;
      await abrirOpciones(t, api);
      await agregar(t);
      await visible(t, find.text('S/ 6.00 c/u'));
      await t.tap(find.text('S/ 6.00 c/u'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ingresar precio manual'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '7.25');
      await t.tap(find.text('Aplicar'));
      await t.pumpAndSettle();
      await t.tap(find.text('1 und'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '2.5');
      await t.tap(find.text('Aceptar'));
      await t.pumpAndSettle();
      expect(find.text('S/ 7.25 c/u'), findsOneWidget);
      expect(find.text('Total S/ 18.13'), findsOneWidget);
      await t.tap(find.text('Guardar borrador'));
      await t.pumpAndSettle();
      final datos = api.requests
          .lastWhere((r) => r.method == 'PUT')
          .data['datos'];
      final recuperado = Ticket.fromJson(
        Map<String, dynamic>.from(datos['pedido']),
      );
      expect(recuperado.items!.single.precioManual, isTrue);
      expect(recuperado.items!.single.precioVentaUnitario, 7.25);
      expect(recuperado.items!.single.cantidad, 2.5);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets(
    'producto sin precio: cancelar, ingresar manual y cantidad decimal; resumen y borrar',
    (t) async {
      final api = PedidosOpcionesAdapter()..sinPrecio = true;
      await abrirOpciones(t, api);
      await cliente(t, 'Bodega Los Olivos');
      await agregar(t);
      expect(find.text('Precio manual'), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      await cerrarBusqueda(t);
      expect(find.text('Total S/ 0.00'), findsOneWidget);
      await agregar(t);
      await t.enterText(find.byType(TextField).last, '7,25');
      await t.tap(find.text('Aplicar'));
      await t.pumpAndSettle();
      await cerrarBusqueda(t);
      await visible(t, find.text('1 und'));
      await t.tap(find.text('1 und'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '2,5');
      await t.tap(find.text('Aceptar'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Ver resumen'));
      await t.pumpAndSettle();
      final r = t.widget<ResumenPedido>(find.byType(ResumenPedido));
      expect(r.lineas.single.precioVentaUnitario, 7.25);
      expect(r.lineas.single.cantidad, 2.5);
      expect(r.total, closeTo(18.125, .001));
      await t.tap(find.byTooltip('Cerrar resumen'));
      await t.pumpAndSettle();
      await visible(t, find.byTooltip('Quitar producto'));
      await t.tap(find.byTooltip('Quitar producto'));
      await t.pumpAndSettle();
      expect(find.text('Total S/ 0.00'), findsOneWidget);
      expect(api.registros, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'sin permiso no pide precio manual ni agrega producto sin precio',
    (t) async {
      final api = PedidosOpcionesAdapter()..sinPrecio = true;
      await abrirOpciones(t, api, permiso: false);
      await agregar(t);
      expect(find.text('Precio manual'), findsNothing);
      expect(find.text('Total S/ 0.00'), findsOneWidget);
      expect(api.registros, 0);
      await t.pump(const Duration(seconds: 4));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'precio declarado: cambiar tipo, manual, cancelar y guardar edición con revisión',
    (t) async {
      final api = PedidosOpcionesAdapter();
      await abrirOpciones(t, api);
      await cliente(t, 'Bodega Los Olivos');
      await agregar(t);
      await visible(t, find.text('S/ 6.00 c/u'));
      await t.tap(find.text('S/ 6.00 c/u'));
      await t.pumpAndSettle();
      await t.tap(find.text('Mayorista'));
      await t.pumpAndSettle();
      await t.tap(find.text('S/ 5.50 c/u · Mayorista'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ingresar precio manual'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextField).last, '4.75');
      await t.tap(find.text('Aplicar'));
      await t.pumpAndSettle();
      await t.tap(find.text('Enviar pedido'));
      await t.pumpAndSettle();
      expect(api.registros, 1);
      await t.tap(find.text('Volver a mis pedidos'));
      await t.pumpAndSettle();
      await t.tap(find.byType(PedidoListItem));
      await t.pumpAndSettle();
      expect(find.text('Editar pedido'), findsOneWidget);
      await visible(t, find.text('S/ 4.75 c/u · Mayorista'));
      await t.tap(find.text('S/ 4.75 c/u · Mayorista'));
      await t.pumpAndSettle();
      await t.tap(find.text('Ingresar precio manual'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Back'));
      await t.pumpAndSettle();
      expect(find.text('¿Salir del pedido?'), findsNothing);
      expect(find.text('Mis pedidos'), findsOneWidget);
      await t.tap(find.byType(PedidoListItem));
      await t.pumpAndSettle();
      await visible(t, find.byTooltip('Sumar una unidad'));
      await t.tap(find.byTooltip('Sumar una unidad'));
      await t.pumpAndSettle();
      await t.tap(find.text('Enviar cambios'));
      await t.pumpAndSettle();
      expect(api.registros, 1);
      final put = api.requests.lastWhere(
        (r) => r.method == 'PUT' && RegExp(r'/gestion/\d+$').hasMatch(r.path),
      );
      expect(put.data['revision'], 1);
      final line = put.data['pedido']['items'].first;
      expect(line['tipoComercialId'], 2);
      expect(line['precioVentaUnitario'], 4.75);
      expect(line['cantidad'], 2);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'factura con DNI bloquea; boleta permite y conserva observación',
    (t) async {
      final api = PedidosOpcionesAdapter()..clienteDni = true;
      await abrirOpciones(t, api);
      await cliente(t, 'Cliente DNI QA');
      await agregar(t);
      await visible(
        t,
        find.byType(DropdownButtonFormField<String>),
        direccion: -200,
      );
      await t.tap(find.byType(DropdownButtonFormField<String>).first);
      await t.pumpAndSettle();
      // Con DNI la factura aparece deshabilitada: tocarla no la elige.
      await t.tap(find.text('Factura (requiere RUC)').last);
      await t.pumpAndSettle();
      expect(api.registros, 0);
      await t.tap(find.text('Boleta').last);
      await t.pumpAndSettle();
      // Observaciones empieza como fila compacta y se abre al tocarla.
      final abrir = find.text('Agregar observación (opcional)');
      await visible(t, abrir);
      await t.tap(abrir);
      await t.pumpAndSettle();
      final obs = find.widgetWithText(TextField, 'Observaciones para atención');
      await visible(t, obs);
      await t.enterText(obs, 'Entrega QA');
      await t.tap(find.text('Enviar pedido'));
      await t.pumpAndSettle();
      expect(api.registros, 1);
      final p = api.requests
          .lastWhere(
            (r) => r.path == '/ticket-order/gestion' && r.method == 'POST',
          )
          .data['pedido'];
      expect(p['tipoComprobanteDestino'], '03');
      expect(p['observacion'], 'Entrega QA');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'borrador falla, mantiene carrito y permite guardar al reintentar',
    (t) async {
      final api = PedidosOpcionesAdapter()..fallarBorrador = true;
      await abrirOpciones(t, api);
      await agregar(t);
      await t.tap(find.text('Guardar borrador'));
      await t.pumpAndSettle();
      await visible(
        t,
        find.text('Error QA recuperable').first,
        direccion: -200,
      );
      expect(find.text('Error QA recuperable'), findsWidgets);
      expect(find.text('Total S/ 6.00'), findsOneWidget);
      api.fallarBorrador = false;
      await t.tap(find.text('Guardar borrador'));
      await t.pumpAndSettle();
      expect(
        find.text('Borrador guardado. Todavía no se envió el pedido.'),
        findsOneWidget,
      );
      expect(api.registros, 0);
      expect(t.takeException(), isNull);
    },
  );
  testWidgets(
    'configuración falla cerrada y Revisar recupera sin perder el flujo',
    (t) async {
      final api = PedidosOpcionesAdapter()..fallarConfig = true;
      await abrirOpciones(t, api);
      expect(
        find.textContaining('No se pudo cargar la configuración'),
        findsOneWidget,
      );
      api.fallarConfig = false;
      await t.tap(find.text('Reintentar'));
      await t.pumpAndSettle();
      await agregar(t);
      expect(find.text('Total S/ 6.00'), findsOneWidget);
      expect(t.takeException(), isNull);
    },
  );
}
