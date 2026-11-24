import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_page.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_points_movement.dart';
import 'loyalty_fixture.dart';

const p2Roles = [
  'LOYALTI_CONFIG_VER',
  'LOYALTI_CUSTOMERS_VER',
  'LOYALTI_COUPONS_VER',
];
const p2Card = LoyaltyCard(
  id: 1,
  nombre: 'Recargas de prueba',
  slug: 'programa-demo',
  activo: true,
  principal: true,
  permitirSellos: true,
  permitirPuntos: true,
  sellosParaPremio: 10,
  textoRecompensa: 'Beneficio configurado para esta tarjeta',
);
const p2OtherCard = LoyaltyCard(
  id: 2,
  nombre: 'Puntos de prueba',
  slug: 'puntos-demo',
  activo: true,
  permitirPuntos: true,
);
const p2Member = LoyaltyCustomer(
  id: 11,
  cardId: 1,
  customerId: 900,
  name: 'María de prueba',
  cardName: 'Recargas de prueba',
  document: '12345678',
  phone: '900000001',
  stamps: 14,
  availablePoints: 40,
  historicalPoints: 50,
  visits: 4,
  active: true,
);
const p2OtherMember = LoyaltyCustomer(
  id: 21,
  cardId: 2,
  customerId: 900,
  name: 'María de prueba',
  cardName: 'Puntos de prueba',
  document: '12345678',
  stamps: 3,
  availablePoints: 90,
  historicalPoints: 100,
  visits: 2,
  active: true,
);

class DemoLoyaltyP2Repository extends DemoLoyaltyRepository {
  List<LoyaltyCustomer> enrollments;
  Object? customerFailure;
  Object? movementFailure;
  Object? couponFailure;
  int? totalOverride;
  final customerCalls = <({int cardId, String filter, int page, int size})>[];
  final enrollmentCalls = <int>[];
  final movementCalls = <int>[];
  final couponCalls = <int>[];
  DemoLoyaltyP2Repository({List<LoyaltyCustomer>? enrollments})
    : enrollments =
          enrollments ??
          [
            p2Member,
            const LoyaltyCustomer(
              id: 12,
              cardId: 1,
              customerId: 901,
              name: 'Luis de prueba',
              cardName: 'Recargas de prueba',
              document: '87654321',
              stamps: 5,
              availablePoints: 15,
              historicalPoints: 20,
              active: false,
            ),
            p2OtherMember,
          ],
      super(cards: const [p2Card, p2OtherCard]);

  @override
  Future<LoyaltyPage<LoyaltyCustomer>> getCustomers(
    int cardId, {
    String filter = '',
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    customerCalls.add((cardId: cardId, filter: filter, page: page, size: size));
    if (customerFailure != null) throw customerFailure!;
    final selected = enrollments
        .where(
          (c) =>
              c.cardId == cardId &&
              [
                c.name,
                c.document ?? '',
                c.phone ?? '',
              ].any((v) => v.toLowerCase().contains(filter.toLowerCase())),
        )
        .toList();
    final total = totalOverride ?? selected.length;
    return LoyaltyPage(
      items: selected.skip(page * size).take(size).toList(),
      total: total,
      hasMore: (page + 1) * size < total,
    );
  }

  @override
  Future<LoyaltyCustomer> getCustomer(
    int id, {
    CancelToken? cancelToken,
  }) async {
    enrollmentCalls.add(id);
    if (customerFailure != null) throw customerFailure!;
    return enrollments.firstWhere((c) => c.id == id);
  }

  @override
  Future<LoyaltyPage<LoyaltyPointsMovement>> getMovements(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    movementCalls.add(enrollmentId);
    if (movementFailure != null) throw movementFailure!;
    final values = [
      LoyaltyPointsMovement(
        id: 2,
        points: -10,
        type: 'CANJE',
        process: 'CANJE_CUPON',
        description: 'Canje de prueba',
        date: DateTime(2026, 10, 23, 12),
      ),
      LoyaltyPointsMovement(
        id: 1,
        points: 50,
        type: 'ACUMULACION',
        process: 'VENTA',
        description: 'Compra de prueba',
        ticketId: 42,
        date: DateTime(2026, 10, 22, 12),
      ),
    ];
    return LoyaltyPage(
      items: values.skip(page * size).take(size).toList(),
      total: values.length,
      hasMore: (page + 1) * size < values.length,
    );
  }

  @override
  Future<LoyaltyPage<LoyaltyCoupon>> getCoupons(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) async {
    couponCalls.add(enrollmentId);
    if (couponFailure != null) throw couponFailure!;
    final cardId = enrollments.firstWhere((c) => c.id == enrollmentId).cardId;
    final values = [
      LoyaltyCoupon(
        id: 3,
        enrollmentId: enrollmentId,
        cardId: cardId,
        name: 'Premio de demostración',
        code: 'DEMO-USADO',
        status: 'USADO',
        usedAt: DateTime(2026, 10, 22),
      ),
      LoyaltyCoupon(
        id: 2,
        enrollmentId: enrollmentId,
        cardId: cardId,
        name: 'Premio anterior de prueba',
        code: 'DEMO-VENCIDO',
        status: 'VENCIDO',
        expiresAt: DateTime(2020, 1, 1),
      ),
      LoyaltyCoupon(
        id: 1,
        enrollmentId: enrollmentId,
        cardId: cardId,
        name: 'Premio pendiente de prueba',
        code: 'DEMO-PENDIENTE',
        status: 'PENDIENTE',
        expiresAt: DateTime(2030, 1, 1),
      ),
    ];
    return LoyaltyPage(
      items: values.skip(page * size).take(size).toList(),
      total: values.length,
      hasMore: (page + 1) * size < values.length,
    );
  }
}
