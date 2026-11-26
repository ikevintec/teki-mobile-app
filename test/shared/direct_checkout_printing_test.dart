import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/printer.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_service.dart';
import 'package:teki_app/src/shared/services/comprobante_print_service.dart';
import 'package:teki_app/src/shared/services/direct_checkout_printing.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import '../support/command_print_fixture.dart';

class Receipts extends ComprobantePrintService {
  final jobs = <Map<String, dynamic>>[];
  bool fail = false;
  @override
  Future<void> autoprint({
    required int ticketId,
    required String pdfUrl,
    required Printer printer,
    required bool escPos,
    required String officeCode,
    required int? idCompany,
    required ConfigCompany config,
  }) async {
    jobs.add({
      'id': ticketId,
      'url': pdfUrl,
      'escPos': escPos,
      'office': officeCode,
      'company': idCompany,
    });
    if (fail) throw StateError('offline');
  }
}

void main() {
  late CommandPrintFixtureAdapter adapter;
  late Receipts receipts;
  late DirectCheckoutPrinting printing;
  late ConfigCompany config;
  final office = Office(id: 1, codigo: 'QA');
  final station = SaleStation(
    id: 2,
    impresoraComprobante: Printer(nombre: 'CAJA'),
  );
  DirectCheckoutResult result(String action, {bool auto = true}) =>
      DirectCheckoutResult(
        OrderRestaurant(id: 7, comandas: [Command(id: 501), Command(id: 501)]),
        Check(
          id: 8,
          comprobante: Ticket(
            id: 9,
            uuid: 'qa',
            identificadorDocumento: 'N001-1',
          ),
        ),
        !auto,
        action,
        automaticPrinting: auto,
      );
  setUp(() {
    dotenv.loadFromString(
      envString:
          'API_URL=https://example.invalid/api\nPRINT_URL=https://print.example.invalid',
    );
    adapter = CommandPrintFixtureAdapter();
    ApiClient.dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
      ..httpClientAdapter = adapter;
    receipts = Receipts();
    printing = DirectCheckoutPrinting(receipts: receipts);
    config = ConfigCompany(
      clienteImpresion: 'COFFE',
      impresionAutomatica: true,
      tipoImpresion: 'A4',
    );
  });
  for (final early in [false, true]) {
    for (final action in ['DRAFT', 'EDIT', 'INVOICE']) {
      test(
        '$action cocina temprana=$early y comprobante solo después de emitir',
        () async {
          config.imprimirPedidoComandaSinComprobante = early;
          await printing.process(
            result(action),
            config: config,
            office: office,
            station: station,
            company: 77,
          );
          expect(adapter.jobs.length, early || action == 'INVOICE' ? 2 : 0);
          expect(adapter.jobs.every((j) => j['idCompany'] == 77), isTrue);
          expect(
            adapter.jobs.every((j) => j['printerName'] != 'OTRA_SEDE'),
            isTrue,
          );
          expect(receipts.jobs.length, action == 'INVOICE' ? 1 : 0);
        },
      );
    }
  }
  for (final format in ['A4', 'TICKET']) {
    test(
      'respeta formato $format y modo ESC/POS sin duplicar guardado',
      () async {
        config.tipoImpresion = format;
        config.imprimeTicketsEscPos = true;
        await printing.process(
          result('INVOICE'),
          config: config,
          office: office,
          station: station,
          company: 77,
        );
        expect(receipts.jobs.single['url'], endsWith('tipo=$format'));
        expect(receipts.jobs.single['escPos'], isTrue);
      },
    );
  }
  test(
    'impresión apagada mantiene cocina sin emitir trabajo de comprobante',
    () async {
      config.impresionAutomatica = false;
      await printing.process(
        result('INVOICE'),
        config: config,
        office: office,
        station: station,
      );
      expect(adapter.jobs, hasLength(2));
      expect(receipts.jobs, isEmpty);
    },
  );
  test(
    'replay restaurado no duplica impresión y ofrece recuperación manual',
    () async {
      final warnings = await printing.process(
        result('INVOICE', auto: false),
        config: config,
        office: office,
        station: station,
      );
      expect(adapter.jobs, isEmpty);
      expect(receipts.jobs, isEmpty);
      expect(warnings, isNotEmpty);
    },
  );
  test(
    'reinicio imprime operación no despachada y otro reinicio no duplica papel',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = DirectCheckoutService(dio: Dio());
      Future<bool> claim() =>
          service.claimPrinting('empresa:sede:estacion', 'operation-1');
      await printing.process(
        result('INVOICE'),
        config: config,
        office: office,
        station: station,
        claimPrinting: claim,
      );
      expect(adapter.jobs, hasLength(2));
      expect(receipts.jobs, hasLength(1));
      final restarted = DirectCheckoutService(dio: Dio());
      final warnings = await printing.process(
        result('INVOICE'),
        config: config,
        office: office,
        station: station,
        claimPrinting: () =>
            restarted.claimPrinting('empresa:sede:estacion', 'operation-1'),
      );
      expect(adapter.jobs, hasLength(2));
      expect(receipts.jobs, hasLength(1));
      expect(warnings.single, contains('ya se intentó'));
      await printing.process(
        result('INVOICE'),
        config: config,
        office: office,
        station: station,
        claimPrinting: () =>
            restarted.claimPrinting('empresa:sede:estacion', 'operation-2'),
      );
      expect(receipts.jobs, hasLength(2));
    },
  );
  test(
    'si no se puede persistir reclamo no imprime ni altera la venta',
    () async {
      final warnings = await printing.process(
        result('INVOICE'),
        config: config,
        office: office,
        station: station,
        claimPrinting: () async => throw StateError('storage'),
      );
      expect(adapter.jobs, isEmpty);
      expect(receipts.jobs, isEmpty);
      expect(warnings, isNotEmpty);
    },
  );
  test(
    'fallo de comprobante es aviso después de la venta confirmada',
    () async {
      receipts.fail = true;
      expect(
        await printing.process(
          result('INVOICE'),
          config: config,
          office: office,
          station: station,
        ),
        isNotEmpty,
      );
      expect(receipts.jobs, hasLength(1));
    },
  );
  test('BLE respeta configuración y no envía el recibo a Coffe', () async {
    config.tipoImpresionMovil = 'BLUETOOTH_BLE';
    var called = 0;
    await printing.process(
      result('INVOICE'),
      config: config,
      office: office,
      station: station,
      printBle: (t) async {
        expect(t.id, 9);
        called++;
      },
    );
    expect(called, 1);
    expect(receipts.jobs, isEmpty);
  });
}
