import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/providers/restaurant/direct_checkout/direct_checkout_controller.dart';

import '../support/direct_checkout_fixture.dart';

void main() {
  test(
    'DTO de pedido acepta ceros y cantidades enteras de JSON del backend',
    () {
      final order = OrderRestaurant.fromJson({
        'montoDelivery': 0,
        'comandas': [
          {
            'items': [
              {'cantidad': 1, 'precioVenta': 5},
            ],
          },
        ],
      });
      expect(order.montoDelivery, 0.0);
      expect(order.comandas?.single.items?.single.cantidad, 1.0);
      expect(order.comandas?.single.items?.single.precioVenta, 5.0);
    },
  );

  late Service service;
  late DirectCheckoutController controller;
  setUp(() {
    service = Service();
    controller = DirectCheckoutController(
      service: service,
      scope: '1:2:1:2',
      draft: draft(),
    );
  });
  tearDown(() => controller.dispose());

  test(
    'usa los céntimos y subtotales del backend sin multiplicar otra vez',
    () async {
      await controller.initialize();
      expect(controller.total, 19.43);
      expect(controller.quote!['totalesPedido'], [19.43]);
      expect(controller.ready, isTrue);
      await controller.refresh();
      expect(service.previewCount, 1);
    },
  );

  for (final action in ['DRAFT', 'EDIT', 'INVOICE']) {
    test('$action usa un solo guardado y evita doble tap', () async {
      await controller.initialize();
      service.wait = Completer<void>();
      final first = controller.submit(action);
      await Future<void>.delayed(Duration.zero);
      await controller.submit(action);
      expect(service.sent, hasLength(1));
      service.wait!.complete();
      expect((await first)!.action, action);
      expect(service.stored, isNull);
      await controller.submit(action);
      expect(service.sent, hasLength(1));
    });
  }

  test('cambiar entrega sin costo mantiene el importe y no recotiza', () async {
    await controller.initialize();
    for (final type in [
      'PEDIDO_LOCAL',
      'PEDIDO_FORANEO',
      'PEDIDO_LOCAL_INTERNO',
    ]) {
      final next = draft();
      next['pedido']['tipo'] = type;
      controller.update(next);
      await controller.refresh();
      expect(controller.total, 19.43);
      expect(controller.ready, isTrue);
    }
    expect(service.previewCount, 1);
  });

  test(
    'delivery conserva total visible pero bloquea emitir hasta el nuevo total',
    () async {
      await controller.initialize();
      final response = Completer<Map<String, dynamic>>();
      service.previews = [Completer(), response];
      controller.update(draft(delivery: 3));
      final refresh = controller.refresh();
      expect(controller.total, 19.43);
      expect(controller.ready, isFalse);
      await controller.submit('INVOICE');
      expect(service.sent, isEmpty);
      response.complete({'totalVenta': 22.43});
      await refresh;
      expect(controller.total, 22.43);
      expect(controller.ready, isTrue);
    },
  );

  test('respuestas antiguas no reemplazan otro pedido/contexto', () async {
    final first = Completer<Map<String, dynamic>>(),
        second = Completer<Map<String, dynamic>>();
    service.previews = [first, second];
    final initial = controller.initialize();
    await Future<void>.delayed(Duration.zero);
    controller.update(draft(delivery: 2));
    final latest = controller.refresh();
    second.complete({'totalVenta': 21.43});
    await latest;
    first.complete({'totalVenta': 19.43});
    await initial;
    expect(controller.total, 21.43);
    controller.invalidateContext();
    expect(controller.ready, isFalse);
    await controller.refresh(force: true);
    await controller.submit('DRAFT');
    expect(service.sent, isEmpty);
  });

  test(
    'error de preview permite borrador y editor pero bloquea emisión',
    () async {
      service.previews = [Completer()];
      final pending = controller.initialize();
      await Future<void>.delayed(Duration.zero);
      service.previews.single.completeError(StateError('PLAN'));
      await pending;
      expect(controller.ready, isFalse);
      await controller.submit('INVOICE');
      expect(service.sent, isEmpty);
      expect((await controller.submit('EDIT'))!.action, 'EDIT');
    },
  );

  test('timeout congela UUID, acción y todos los pagos al recuperar', () async {
    await controller.initialize();
    service.loseResponse = true;
    await controller.submit('INVOICE');
    final frozen = jsonEncode(service.sent.single);
    expect(controller.uncertain, isTrue);
    controller.update(draft(delivery: 999));
    service.loseResponse = false;
    final result = await controller.submit('DRAFT');
    expect(result!.action, 'INVOICE');
    expect(jsonEncode(service.sent.last), frozen);
    expect(result.automaticPrinting, isTrue);
  });

  test(
    'reinicio recupera el intento persistido y permite reclamar su impresión pendiente',
    () async {
      await controller.initialize();
      service.loseResponse = true;
      await controller.submit('INVOICE');
      final restored = DirectCheckoutController(
        service: service,
        scope: '1:2:1:2',
        draft: draft(delivery: 999),
      );
      await restored.initialize();
      expect(service.previewCount, 1);
      expect(restored.uncertain, isTrue);
      service.loseResponse = false;
      final result = await restored.submit('EDIT');
      expect(service.sent[0], service.sent[1]);
      expect(result!.automaticPrinting, isTrue);
      restored.dispose();
    },
  );

  test(
    'rechazo confirmado libera intento y permite corregir sin recuperar',
    () async {
      await controller.initialize();
      service.reject = true;
      await controller.submit('INVOICE');
      expect(controller.uncertain, isFalse);
      expect(service.stored, isNull);
      expect(controller.error, 'El total cambió');
      service.reject = false;
      await controller.submit('INVOICE');
      expect(
        service.sent[0]['operationId'],
        isNot(service.sent[1]['operationId']),
      );
    },
  );

  test(
    'persistencia falla antes de enviar, limpieza falla después de éxito sin repetir cobro',
    () async {
      await controller.initialize();
      service.storageFails = true;
      await controller.submit('INVOICE');
      expect(service.sent, isEmpty);
      service.storageFails = false;
      service.cleanupFails = true;
      expect(await controller.submit('INVOICE'), isNotNull);
      await controller.submit('INVOICE');
      expect(service.sent, hasLength(1));
    },
  );

  test('respuesta incompleta mantiene la operación recuperable', () async {
    await controller.initialize();
    service.malformed = true;
    await controller.submit('INVOICE');
    expect(controller.uncertain, isTrue);
  });
}
