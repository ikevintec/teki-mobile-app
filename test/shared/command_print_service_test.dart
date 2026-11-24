import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:toastification/toastification.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/shared/services/command_print_service.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/command_print_fixture.dart';

void main() {
  late CommandPrintFixtureAdapter adapter;
  setUp(() {
    dotenv.loadFromString(
      envString:
          'API_URL=https://example.invalid/api\nPRINT_URL=https://print.example.invalid',
    );
    adapter = CommandPrintFixtureAdapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter;
  });
  Future<void> printCommand({String? client = 'COFFE', bool escPos = false}) =>
      CommandPrintService().processCommand(
        commandId: 501,
        puntoVenta: Office(id: 1, codigo: 'QA'),
        escPos: escPos,
        clientPrinter: client,
        idCompany: 77,
      );

  test(
    'PDF: área primaria/secundaria, combos y extras sin duplicar ni cruzar sede',
    () async {
      final first = adapter.items.first['producto'] as Map<String, dynamic>;
      (first['categoria'] as Map)['areaProduccionSecundaria'] =
          commandPrintArea(4, 'PLANCHA');
      adapter.items.add({
        'id': 5,
        'cantidad': 1.0,
        'producto': {
          'id': 5,
          'tipoProducto': 'COMBO',
          'comboPlatillos': [commandPrintProduct(6, 2, 'BAR')],
        },
        'grupoProductoOpciones': [
          {'producto': commandPrintProduct(7, 4, 'PLANCHA')},
          {
            'producto': {'id': 8},
          },
        ],
      });
      await printCommand();
      expect(adapter.jobs, hasLength(3));
      expect(adapter.jobs.map((j) => j['printerName']).toSet(), {
        'COCINA',
        'BAR',
        'PLANCHA',
      });
      expect(adapter.jobs.map((j) => j['officeCode']).toSet(), {
        'QA_COCINA',
        'QA_BAR',
        'QA_PLANCHA',
      });
      expect(
        adapter.jobs.every(
          (j) => j['event'] == 'printPdf' && j['idCompany'] == 77,
        ),
        isTrue,
      );
      expect(
        adapter.jobs
            .map((j) => Uri.parse(j['url'] as String).queryParameters['idArea'])
            .toSet(),
        {'1', '2', '4'},
      );
    },
  );
  test('ESC/POS: genera órdenes para cada área con modo GLOBAL', () async {
    for (final item in adapter.items) {
      final printer =
          ((item['producto']
                          as Map)['categoria']['areaProduccion']['impresoras']
                      as List)
                  .single
              as Map;
      printer['tipoImpresion'] = 'GLOBAL';
    }
    await printCommand(escPos: true);
    expect(adapter.jobs, hasLength(2));
    expect(
      adapter.jobs.every(
        (j) => j['event'] == 'printEscPos' && (j['orders'] as List).isNotEmpty,
      ),
      isTrue,
    );
    expect(
      adapter.requests.where((r) => r.path.startsWith('/ticket-esc-pos/')),
      hasLength(2),
    );
  });
  test('cliente no COFFE no consulta ni imprime', () async {
    await printCommand(client: 'BLUETOOTH_BLE');
    expect(adapter.requests, isEmpty);
  });
  test('sin impresora ticketera de la sede no envía trabajo', () async {
    adapter.items = [
      {'producto': commandPrintProduct(1, 3, 'OTRA', office: 2)},
    ];
    await printCommand();
    expect(adapter.jobs, isEmpty);
  });
  test(
    'modo explícito de impresora prevalece sobre configuración global',
    () async {
      for (final entry in {'PDF': true, 'ESCPOS': false}.entries) {
        adapter.jobs.clear();
        for (final item in adapter.items) {
          final printer =
              ((item['producto']
                              as Map)['categoria']['areaProduccion']['impresoras']
                          as List)
                      .single
                  as Map;
          printer['tipoImpresion'] = entry.key;
        }
        await printCommand(escPos: entry.value);
        expect(adapter.jobs, hasLength(2));
        expect(
          adapter.jobs.every(
            (j) =>
                j['event'] == (entry.key == 'PDF' ? 'printPdf' : 'printEscPos'),
          ),
          isTrue,
        );
      }
    },
  );
  test(
    'anulación conserva IDs afectados para cada área sin duplicar',
    () async {
      await CommandPrintService().processCommand(
        commandId: 501,
        puntoVenta: Office(id: 1, codigo: 'QA'),
        escPos: false,
        clientPrinter: 'COFFE',
        idCompany: 77,
        anulacion: true,
        itemAfectado: [11, 12],
      );
      expect(adapter.jobs, hasLength(2));
      for (final job in adapter.jobs) {
        final query = Uri.parse(job['url'] as String).queryParametersAll;
        expect(query['anulacion'], ['true']);
        expect(query['itemAfectado'], ['11', '12']);
      }
    },
  );
  testWidgets('comanda no disponible muestra aviso sin enviar impresión', (
    t,
  ) async {
    await t.pumpWidget(
      ToastificationWrapper(child: MaterialApp(home: Scaffold())),
    );
    await t.pumpAndSettle();
    adapter.failCommand = true;
    await t.runAsync(() => printCommand());
    await t.pumpAndSettle();
    expect(adapter.jobs, isEmpty);
    expect(find.text('No se pudo imprimir la comanda'), findsOneWidget);
    toastification.dismissAll(delayForAnimation: false);
    await t.pump(const Duration(seconds: 1));
    await t.pumpWidget(const SizedBox());
    await t.pumpAndSettle();
  });
  for (final falseResult in [false, true]) {
    testWidgets(
      'fallo ${falseResult ? "printed=false" : "HTTP503"} de cocina no impide bar y muestra aviso',
      (t) async {
        await t.pumpWidget(
          ToastificationWrapper(child: MaterialApp(home: Scaffold())),
        );
        await t.pumpAndSettle();
        (falseResult ? adapter.offlinePrinters : adapter.failPrinters).add(
          'COCINA',
        );
        await t.runAsync(() => printCommand());
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpAndSettle();
        expect(adapter.jobs.map((j) => j['printerName']), ['COCINA', 'BAR']);
        expect(
          find.text(
            falseResult
                ? 'Agente QA no disponible'
                : 'Impresora QA sin conexión',
          ),
          findsOneWidget,
        );
        toastification.dismissAll(delayForAnimation: false);
        await t.pump(const Duration(seconds: 1));
        await t.pumpWidget(const SizedBox());
        await t.pump();
        await t.pump(const Duration(milliseconds: 500));
        await t.pumpAndSettle();
      },
    );
  }
}
