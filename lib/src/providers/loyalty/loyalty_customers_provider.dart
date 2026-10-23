import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_points_movement.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_provider.dart';
import 'package:teki_app/src/providers/loyalty/loyalty_page_notifier.dart';

typedef LoyaltyCardKey = ({int companyId, int cardId});
typedef LoyaltyCustomerKey = ({int companyId, int cardId, int enrollmentId});

bool canViewLoyaltyCustomers(SesionState session) =>
    canViewLoyalty(session) &&
    (session.hasPermission('LOYALTI_CUSTOMERS_VER') ||
        session.hasPermission('SUPER_USUARIO'));

final loyaltyCustomersScopeProvider = Provider((ref) {
  final allowed = canViewLoyaltyCustomers(ref.watch(sesionProvider));
  return allowed ? ref.watch(loyaltyScopeProvider) : null;
});

final loyaltyCustomersProvider = StateNotifierProvider.autoDispose
    .family<
      LoyaltyPageNotifier<LoyaltyCustomer>,
      LoyaltyPageState<LoyaltyCustomer>,
      LoyaltyCardKey
    >((ref, key) {
      final scope = ref.watch(loyaltyCustomersScopeProvider);
      final repository = ref.watch(loyaltyRepositoryProvider);
      final notifier = LoyaltyPageNotifier<LoyaltyCustomer>(
        enabled: scope != null && scope.companyId == key.companyId,
        loader: (page, filter, token) async {
          final result = await repository.getCustomers(
            key.cardId,
            filter: filter,
            page: page,
            cancelToken: token,
          );
          if (result.items.any((customer) => customer.cardId != key.cardId)) {
            throw Exception(
              'La respuesta no corresponde a esta tarjeta. Vuelve a intentar.',
            );
          }
          return result;
        },
      );
      Future.microtask(notifier.load);
      return notifier;
    });

final loyaltyCustomerProvider = FutureProvider.autoDispose
    .family<
      ({LoyaltyCustomer customer, DateTime consultedAt})?,
      LoyaltyCustomerKey
    >((ref, key) async {
      final scope = ref.watch(loyaltyCustomersScopeProvider);
      if (scope == null || scope.companyId != key.companyId) return null;
      final token = CancelToken();
      ref.onDispose(token.cancel);
      final customer = await ref
          .watch(loyaltyRepositoryProvider)
          .getCustomer(key.enrollmentId, cancelToken: token);
      if (customer.id != key.enrollmentId || customer.cardId != key.cardId) {
        throw Exception('La inscripción no corresponde a esta tarjeta.');
      }
      return (customer: customer, consultedAt: DateTime.now());
    });

final loyaltyMovementsProvider = StateNotifierProvider.autoDispose
    .family<
      LoyaltyPageNotifier<LoyaltyPointsMovement>,
      LoyaltyPageState<LoyaltyPointsMovement>,
      LoyaltyCustomerKey
    >((ref, key) {
      final scope = ref.watch(loyaltyCustomersScopeProvider);
      final repository = ref.watch(loyaltyRepositoryProvider);
      final notifier = LoyaltyPageNotifier<LoyaltyPointsMovement>(
        enabled: scope != null && scope.companyId == key.companyId,
        loader: (page, _, token) async {
          // Validar inscripción/programa también al abrir el historial directamente.
          final enrollment = await repository.getCustomer(
            key.enrollmentId,
            cancelToken: token,
          );
          if (enrollment.cardId != key.cardId ||
              enrollment.id != key.enrollmentId) {
            throw Exception('La inscripción no corresponde a esta tarjeta.');
          }
          return repository.getMovements(
            key.enrollmentId,
            page: page,
            cancelToken: token,
          );
        },
      );
      Future.microtask(notifier.load);
      return notifier;
    });

bool canViewLoyaltyCoupons(SesionState session) =>
    canViewLoyaltyCustomers(session) &&
    (session.hasPermission('LOYALTI_COUPONS_VER') ||
        session.hasPermission('SUPER_USUARIO'));

final loyaltyCouponsScopeProvider = Provider(
  (ref) => canViewLoyaltyCoupons(ref.watch(sesionProvider))
      ? ref.watch(loyaltyCustomersScopeProvider)
      : null,
);

final loyaltyCouponsProvider = StateNotifierProvider.autoDispose
    .family<
      LoyaltyPageNotifier<LoyaltyCoupon>,
      LoyaltyPageState<LoyaltyCoupon>,
      LoyaltyCustomerKey
    >((ref, key) {
      final scope = ref.watch(loyaltyCouponsScopeProvider);
      final repository = ref.watch(loyaltyRepositoryProvider);
      final notifier = LoyaltyPageNotifier<LoyaltyCoupon>(
        enabled: scope != null && scope.companyId == key.companyId,
        loader: (page, _, token) async {
          final enrollment = await repository.getCustomer(
            key.enrollmentId,
            cancelToken: token,
          );
          if (enrollment.cardId != key.cardId ||
              enrollment.id != key.enrollmentId) {
            throw Exception('La inscripción no corresponde a esta tarjeta.');
          }
          final result = await repository.getCoupons(
            key.enrollmentId,
            page: page,
            cancelToken: token,
          );
          if (result.items.any(
            (coupon) =>
                coupon.enrollmentId != key.enrollmentId ||
                coupon.cardId != key.cardId,
          )) {
            throw Exception('Los cupones no corresponden a esta inscripción.');
          }
          return result;
        },
      );
      Future.microtask(notifier.load);
      return notifier;
    });
