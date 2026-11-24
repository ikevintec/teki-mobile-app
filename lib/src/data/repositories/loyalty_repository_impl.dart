import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_page.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_points_movement.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/datasource/remote_loyalty.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/domain/datasource/loyalty_datasource.dart';
import 'package:teki_app/src/domain/repositories/loyalty_repository.dart';

class LoyaltyRepositoryImpl implements LoyaltyRepository {
  final LoyaltyDatasource datasource;
  LoyaltyRepositoryImpl({LoyaltyDatasource? datasource})
    : datasource = datasource ?? RemoteLoyalty();

  @override
  Future<List<LoyaltyCard>> getCards({CancelToken? cancelToken}) =>
      datasource.getCards(cancelToken: cancelToken);

  @override
  Future<LoyaltyCard> getCard(int id, {CancelToken? cancelToken}) =>
      datasource.getCard(id, cancelToken: cancelToken);
  @override
  Future<LoyaltyPage<LoyaltyCustomer>> getCustomers(
    int cardId, {
    String filter = '',
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) => datasource.getCustomers(
    cardId,
    filter: filter,
    page: page,
    size: size,
    cancelToken: cancelToken,
  );
  @override
  Future<LoyaltyCustomer> getCustomer(int id, {CancelToken? cancelToken}) =>
      datasource.getCustomer(id, cancelToken: cancelToken);
  @override
  Future<LoyaltyPage<LoyaltyPointsMovement>> getMovements(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) => datasource.getMovements(
    enrollmentId,
    page: page,
    size: size,
    cancelToken: cancelToken,
  );
  @override
  Future<LoyaltyPage<LoyaltyCoupon>> getCoupons(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  }) => datasource.getCoupons(
    enrollmentId,
    page: page,
    size: size,
    cancelToken: cancelToken,
  );
}
