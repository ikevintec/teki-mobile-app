import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/command_detail.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/providers/restaurant/ready_to_serve_provider.dart';

void main() {
  test('agrupa solo platos preparados de pedidos locales con mesa', () {
    final now = DateTime(2026, 9, 28, 12);
    final commands = [
      Command(
        id: 20,
        fecha: now,
        pedido: OrderRestaurant(
          id: 2,
          tipo: 'LOCAL',
          mesa: Table(id: 2, numero: 8, salon: Lounge(nombre: 'Terraza')),
        ),
        items: [
          CommandDetail(
            id: 201,
            cantidad: 1,
            estadoComandaDetalle: 'PREPARADO',
            fechaPreparado: now.add(const Duration(minutes: 10)),
            producto: Product(nombre: 'Café'),
          ),
        ],
      ),
      Command(
        id: 10,
        pedido: OrderRestaurant(
          id: 1,
          tipo: 'LOCAL',
          mesa: Table(id: 1, numero: 3, salon: Lounge(nombre: 'Principal')),
        ),
        items: [
          CommandDetail(
            id: 101,
            cantidad: 2,
            estadoComandaDetalle: 'PREPARADO',
            fechaPreparado: now.add(const Duration(minutes: 5)),
            producto: Product(nombre: 'Ceviche'),
          ),
          CommandDetail(
            id: 102,
            cantidad: 1,
            estadoComandaDetalle: 'PENDIENTE',
            producto: Product(nombre: 'Sopa'),
          ),
          CommandDetail(
            id: 103,
            cantidad: 1,
            estadoComandaDetalle: 'PREPARADO',
            eliminado: true,
            producto: Product(nombre: 'Anulado'),
          ),
        ],
      ),
      Command(
        id: 30,
        pedido: OrderRestaurant(id: 3, tipo: 'DELIVERY'),
        items: [
          CommandDetail(
            id: 301,
            estadoComandaDetalle: 'PREPARADO',
            producto: Product(nombre: 'Delivery'),
          ),
        ],
      ),
    ];

    final result = groupReadyCommands(commands, fallbackDate: now);

    expect(result, hasLength(2));
    expect(result.first.orderId, 1);
    expect(result.first.title, 'Mesa 3');
    expect(result.first.subtitle, 'Principal');
    expect(result.first.dishes, hasLength(1));
    expect(result.first.dishes.single.name, 'Ceviche');
    expect(result.first.dishes.single.quantity, 2);
    expect(result.last.orderId, 2);
  });

  test('ordena platos de una mesa por el que más espera', () {
    final now = DateTime(2026, 9, 28, 12);
    final order = OrderRestaurant(
      id: 1,
      tipo: 'LOCAL',
      mesa: Table(id: 1, numero: 3),
    );
    final result = groupReadyCommands([
      Command(
        id: 1,
        pedido: order,
        items: [
          CommandDetail(
            id: 2,
            estadoComandaDetalle: 'PREPARADO',
            fechaPreparado: now.add(const Duration(minutes: 8)),
          ),
          CommandDetail(
            id: 1,
            estadoComandaDetalle: 'PREPARADO',
            fechaPreparado: now.add(const Duration(minutes: 2)),
          ),
        ],
      ),
    ]);

    expect(result.single.dishes.map((dish) => dish.itemId), [1, 2]);
  });
}
