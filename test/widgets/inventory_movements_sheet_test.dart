import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// Google Fonts expone assetManifest para pruebas sin solicitudes de fuentes.
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:teki_app/src/data/models/response/inventory_detail_page.dart';
import 'package:teki_app/src/data/models/response/inventory_record_response.dart';
import 'package:teki_app/src/data/models/teki_model/batch_product.dart';
import 'package:teki_app/src/data/models/teki_model/inventory.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_record.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/repositories/inventory_repository.dart';
import 'package:teki_app/src/presentation/screens/inventory/widgets/inventory_movements_sheet.dart';
import 'package:teki_app/src/providers/inventory/inventory_details_provider.dart';
import 'package:teki_app/src/providers/inventory/inventory_logs_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    fonts.assetManifest = _TestFontManifest();
    // Fuente local para probar interacción; no se evalúa la tipografía.
    final data = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async => data);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    fonts.assetManifest = null;
  });

  Future<void> showSheet(
    WidgetTester tester,
    _Repository repository, {
    String? tipo = 'SERIE',
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          inventoryDetailRepositoryProvider.overrideWithValue(repository),
          inventoryLogsProvider(9).overrideWith(
            (ref) => InventoryLogsNotifier(
              idInventory: 9,
              inventoryRepository: repository,
            ),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: InventoryMovementsSheet(
              inventory: Inventory(
                id: 9,
                producto: Product(id: 1, nombre: 'Teléfono', tipoLote: tipo),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'sin datos anidados, carga lotes al abrir y movimientos al seleccionar',
    (tester) async {
      final repository = _Repository();
      await showSheet(tester, repository);
      expect(repository.batchPages, isEmpty);
      expect(repository.recordIds, isEmpty);
      expect(find.text('Lotes'), findsOneWidget);
      await tester.tap(find.text('Lotes'));
      await tester.pumpAndSettle();
      expect(repository.batchPages, [0]);
      expect(repository.recordIds, isEmpty);
      expect(find.text('SERIE-1'), findsOneWidget);
      await tester.tap(find.text('Cargar más'));
      await tester.pumpAndSettle();
      expect(repository.batchPages, [0, 1]);
      await tester.tap(find.text('SERIE-1'));
      await tester.pumpAndSettle();
      expect(repository.recordIds, [42]);
      expect(find.text('COMPRA'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(repository.batchPages, [0, 1]);
      expect(find.text('SERIE-2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'un producto sin lotes no consulta detalles ni muestra la pestaña',
    (tester) async {
      final repository = _Repository();
      await showSheet(tester, repository, tipo: null);
      expect(find.text('Lotes'), findsNothing);
      expect(repository.batchPages, isEmpty);
      expect(repository.recordIds, isEmpty);
    },
  );

  testWidgets(
    'una consulta fallida muestra reintento y no un inventario vacío',
    (tester) async {
      final repository = _Repository()..failBatches = true;
      await showSheet(tester, repository, tipo: 'LOTE');
      await tester.tap(find.text('Lotes'));
      await tester.pumpAndSettle();
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Sin lotes registrados'), findsNothing);
      repository.failBatches = false;
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(repository.batchPages, [0, 0]);
      expect(find.text('SERIE-1'), findsOneWidget);
    },
  );
}

class _TestFontManifest extends Fake implements AssetManifest {
  @override
  List<String> listAssets() => [
    for (final family in ['Roboto', 'Raleway'])
      for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold'])
        '$family-$weight.ttf',
  ];
}

class _Repository extends Fake implements InventoryRepository {
  final batchPages = <int>[];
  final recordIds = <int>[];
  bool failBatches = false;

  @override
  Future<InventoryRecordResponse> getInventoryLogs(
    int idInventory,
    Map<String, dynamic> params,
  ) async => InventoryRecordResponse(
    content: [],
    empty: true,
    first: true,
    last: true,
    number: 0,
    size: 15,
    totalElements: 0,
    totalPages: 0,
    sort: null,
    pageable: null,
  );

  @override
  Future<InventoryDetailPage<BatchProduct>> getInventoryBatches(
    int idInventory,
    int pageNumber,
    int perPage, {
    CancelToken? cancelToken,
  }) async {
    expect(idInventory, 9);
    batchPages.add(pageNumber);
    if (failBatches) throw Exception('offline');
    return InventoryDetailPage(
      items: [
        BatchProduct(
          id: 42 + pageNumber,
          tipoLote: 'SERIE',
          serie: 'SERIE-${pageNumber + 1}',
          cantidad: 0,
        ),
      ],
      last: pageNumber == 1,
    );
  }

  @override
  Future<InventoryDetailPage<InventoryRecord>> getBatchRecords(
    int idBatch,
    int pageNumber,
    int perPage, {
    CancelToken? cancelToken,
  }) async {
    recordIds.add(idBatch);
    return InventoryDetailPage(
      items: [
        InventoryRecord(
          id: 1,
          tipo: 'ENTRADA',
          concepto: 'COMPRA',
          cantidad: 1,
        ),
      ],
      last: true,
    );
  }
}
