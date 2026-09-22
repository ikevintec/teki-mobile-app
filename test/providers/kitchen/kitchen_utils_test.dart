import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/category.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/production_area.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_state.dart';
import 'package:teki_app/src/providers/kitchen/kitchen_utils.dart';

CommandDetail item({
  required int id,
  required String status,
  int areaId = 1,
  bool takeaway = false,
  DateTime? cancelledAt,
  bool deleted = false,
}) {
  return CommandDetail(
    id: id,
    cantidad: 1,
    estadoComandaDetalle: status,
    paraLlevar: takeaway,
    eliminado: deleted,
    fechaAnulacion: cancelledAt,
    producto: Product(
      id: id,
      nombre: 'Producto $id',
      categoria: Category(
        id: areaId,
        areaProduccion: ProductionArea(id: areaId, nombre: 'Zona $areaId'),
      ),
    ),
  );
}

void main() {
  group('flujo de estados de Cocina', () {
    test('avanza y deshace un solo estado por toque', () {
      expect(kitchenNextStatus['PENDIENTE'], 'PREPARACION');
      expect(kitchenNextStatus['PREPARACION'], 'PREPARADO');
      expect(kitchenNextStatus['PREPARADO'], 'DESPACHADO');
      expect(kitchenNextStatus['DESPACHADO'], isNull);

      expect(kitchenPreviousStatus['PREPARACION'], 'PENDIENTE');
      expect(kitchenPreviousStatus['PREPARADO'], 'PREPARACION');
      expect(kitchenPreviousStatus['DESPACHADO'], 'PREPARADO');
    });

    test('clasifica los estados en las cuatro vistas', () {
      expect(kitchenViewForStatus('PENDIENTE'), KitchenView.pending);
      expect(kitchenViewForStatus('PREPARACION'), KitchenView.pending);
      expect(kitchenViewForStatus('PREPARADO'), KitchenView.ready);
      expect(kitchenViewForStatus('DESPACHADO'), KitchenView.served);
      expect(kitchenViewForStatus('CANCELADO'), KitchenView.cancelled);
    });
  });

  group('filtros del tablero', () {
    final now = DateTime(2026, 9, 22, 12);
    final command = Command(
      id: 10,
      fecha: now.subtract(const Duration(minutes: 20)),
      items: [
        item(id: 1, status: 'PENDIENTE', areaId: 1),
        item(id: 2, status: 'PREPARADO', areaId: 2, takeaway: true),
        item(id: 3, status: 'DESPACHADO', areaId: 1),
        item(
          id: 4,
          status: 'CANCELADO',
          areaId: 1,
          cancelledAt: now.subtract(const Duration(hours: 1)),
        ),
        item(
          id: 5,
          status: 'CANCELADO',
          areaId: 1,
          cancelledAt: now.subtract(const Duration(days: 1)),
        ),
        item(id: 6, status: 'PENDIENTE', areaId: 1, deleted: true),
      ],
    );

    test('muestra solo los estados de la vista activa', () {
      final state = KitchenState(now: now, commands: [command]);

      expect(kitchenItemsForView(command, state).map((value) => value.id), [1]);
      expect(
        kitchenItemsForView(
          command,
          state,
          view: KitchenView.ready,
        ).map((value) => value.id),
        [2],
      );
      expect(
        kitchenItemsForView(
          command,
          state,
          view: KitchenView.served,
        ).map((value) => value.id),
        [3],
      );
      expect(
        kitchenItemsForView(
          command,
          state,
          view: KitchenView.cancelled,
        ).map((value) => value.id),
        [4],
      );
    });

    test('combina zona y modalidad para llevar', () {
      final state = KitchenState(
        now: now,
        commands: [command],
        filters: const KitchenFilters(
          view: KitchenView.ready,
          mode: KitchenOrderMode.takeaway,
          productionAreaIds: [2],
        ),
      );

      expect(kitchenItemsForView(command, state).map((value) => value.id), [2]);
    });

    test('mantiene una anulación visible en su pestaña anterior', () {
      final state = KitchenState(
        now: now,
        commands: [command],
        cancellationNotices: {
          4: KitchenCancellationNotice(
            itemId: 4,
            commandId: 10,
            previousView: KitchenView.pending,
            createdAt: now,
          ),
        },
      );

      expect(kitchenItemsForView(command, state).map((value) => value.id), [
        1,
        4,
      ]);
    });

    test('respeta el área de producción secundaria', () {
      final product = Product(
        categoria: Category(
          areaProduccion: ProductionArea(id: 1),
          areaProduccionSecundaria: ProductionArea(id: 8),
        ),
      );

      expect(kitchenProductInAreas(product, [8]), isTrue);
      expect(kitchenProductInAreas(product, [9]), isFalse);
    });
  });

  group('tiempos y preferencias', () {
    test('calcula tramos normal, ámbar y rojo', () {
      final now = DateTime(2026, 9, 22, 12);

      expect(
        kitchenTimeBand(
          Command(fecha: now.subtract(const Duration(minutes: 14))),
          15,
          now,
        ),
        'ok',
      );
      expect(
        kitchenTimeBand(
          Command(fecha: now.subtract(const Duration(minutes: 15))),
          15,
          now,
        ),
        'warn',
      );
      expect(
        kitchenTimeBand(
          Command(fecha: now.subtract(const Duration(minutes: 30))),
          15,
          now,
        ),
        'late',
      );
    });

    test('restaura preferencias y limita minutos inválidos', () {
      final filters = KitchenFilters.fromJson({
        'view': 'ready',
        'mode': 'takeaway',
        'preparationMinutes': 999,
        'productionAreaIds': [2, 4],
        'soundEnabled': false,
        'alertTone': 'bell',
      });

      expect(filters.view, KitchenView.ready);
      expect(filters.mode, KitchenOrderMode.takeaway);
      expect(filters.preparationMinutes, 240);
      expect(filters.productionAreaIds, [2, 4]);
      expect(filters.soundEnabled, isFalse);
      expect(filters.alertTone, KitchenAlertTone.bell);
      expect(filters.lateAlertEnabled, isTrue);
    });

    test('parsea las fechas de estado y el área secundaria del backend', () {
      final parsed = CommandDetail.fromJson({
        'id': 1,
        'fechaPreparacion': '2026-09-22T10:00:00',
        'fechaPreparado': '2026-09-22T10:05:00',
        'fechaDespachado': '2026-09-22T10:06:00',
        'fechaAnulacion': '2026-09-22T10:07:00',
      });
      final category = Category.fromJson({
        'id': 1,
        'areaProduccionSecundaria': {'id': 8, 'nombre': 'Barra'},
      });

      expect(parsed.fechaPreparacion?.minute, 0);
      expect(parsed.fechaPreparado?.minute, 5);
      expect(parsed.fechaDespachado?.minute, 6);
      expect(parsed.fechaAnulacion?.minute, 7);
      expect(category.areaProduccionSecundaria?.id, 8);
    });
  });
}
