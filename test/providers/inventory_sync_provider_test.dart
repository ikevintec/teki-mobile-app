import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/response/inventory_adjustment_response.dart';
import 'package:teki_app/src/data/models/response/inventory_sync_response.dart';
import 'package:teki_app/src/data/models/teki_model/inventory_adjustment.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/domain/repositories/inventory_adjustment_repository.dart';
import 'package:teki_app/src/domain/repositories/inventory_sync_repository.dart';
import 'package:teki_app/src/providers/inventory/inventory_sync_provider.dart';
import 'package:teki_app/src/providers/inventory_adjustment/inventory_adjustment_provider.dart';

void main() {
  group('InventorySyncNotifier', () {
    test(
      'refresca el resumen al abrir el panel pero no al paginar',
      () async {
        final repository = _FakeSyncRepository();
        final notifier = InventorySyncNotifier(
          officeId: 8,
          repository: repository,
        );

        await notifier.loadBadgeOnce();
        await notifier.loadBadgeOnce(); // memoizado: no vuelve a consultar
        await notifier.openPanel(); // opción A: fuerza un resumen fresco
        await notifier.loadIssues(reset: false); // paginar no toca el resumen

        expect(repository.summaryCalls, 2);
        expect(repository.summaryOfficeIds, [8, 8]);
        expect(repository.issueCalls, 2);
        expect(notifier.state.badgeSummary.total, 2);
      },
    );

    test('refreshBadge vuelve a consultar el resumen (opción B)', () async {
      final repository = _FakeSyncRepository();
      final notifier = InventorySyncNotifier(
        officeId: 8,
        repository: repository,
      );

      await notifier.loadBadgeOnce();
      await notifier.refreshBadge();

      expect(repository.summaryCalls, 2);
    });

    test('el resumen se refresca al abrir y tras corregir', () async {
      final repository = _FakeSyncRepository();
      final notifier = InventorySyncNotifier(
        officeId: 8,
        repository: repository,
      );

      await notifier.loadBadgeOnce(); // 1
      await notifier.openPanel(); // 2 (opción A)
      await notifier.fixBatch([1]); // 3 (refreshAfterCorrection)

      expect(repository.summaryCalls, 3);
      expect(repository.fixedIds, [1]);
    });
  });

  test(
    'el modo de corrección permite conservar el stock con lotes válidos',
    () {
      final notifier = InventoryAdjustmentNotifier(
        adjustmentRepository: _FakeAdjustmentRepository(),
      );
      final item = AdjustmentFormItem(
        product: Product(validacionLote: true, tipoLote: 'SERIE'),
        stockActual: 1,
        nuevoStock: 1,
        lotes: [
          AdjustmentLoteItem(
            nombre: 'SERIE-1',
            cantidad: 1,
            tipoLote: 'SERIE',
            isExisting: true,
          ),
        ],
      );

      expect(notifier.loteValidationError(item), isNotNull);
      expect(
        notifier.loteValidationError(item, allowUnchangedStockWithLotes: true),
        isNull,
      );
    },
  );
}

class _FakeSyncRepository implements InventorySyncRepository {
  int summaryCalls = 0;
  int issueCalls = 0;
  final List<int?> summaryOfficeIds = [];
  List<int> fixedIds = [];

  @override
  Future<InventorySyncSummary> getSummary({
    int? idPuntoVenta,
    String? search,
  }) async {
    summaryCalls++;
    summaryOfficeIds.add(idPuntoVenta);
    return const InventorySyncSummary(total: 2, productos: 2, unidades: 2);
  }

  @override
  Future<InventorySyncPage> getIssues({
    int? idPuntoVenta,
    String? search,
    required int pageNumber,
    required int perPage,
  }) async {
    issueCalls++;
    return InventorySyncPage(
      content: pageNumber == 0
          ? const [
              InventorySyncIssue(
                idInventory: 1,
                idProducto: 10,
                producto: 'Producto',
                tipoLote: 'SERIE',
                stock: 2,
                cantidadLotes: 1,
                diferencia: 1,
                lotesConSaldo: 1,
                lotesNegativos: 0,
              ),
            ]
          : const [],
      totalElements: 2,
      last: pageNumber > 0,
      number: pageNumber,
    );
  }

  @override
  Future<InventorySyncFixResult> fixIssues(List<int> inventoryIds) async {
    fixedIds = inventoryIds;
    return const InventorySyncFixResult(corregidos: 1);
  }
}

class _FakeAdjustmentRepository implements InventoryAdjustmentRepository {
  @override
  Future<InventoryAdjustmentResponse> getAdjustments(
    Map<String, dynamic> params,
  ) => throw UnimplementedError();

  @override
  Future<InventoryAdjustment> saveAdjustment(InventoryAdjustment adjustment) =>
      throw UnimplementedError();
}
