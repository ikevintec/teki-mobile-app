import 'package:teki_app/src/data/models/teki_model/loyalty_coupon.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_customer.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_page.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_points_movement.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';

abstract class LoyaltyDatasource {
  Future<List<LoyaltyCard>> getCards({CancelToken? cancelToken});
  Future<LoyaltyCard> getCard(int id, {CancelToken? cancelToken});
  Future<LoyaltyPage<LoyaltyCustomer>> getCustomers(
    int cardId, {
    String filter = '',
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });
  Future<LoyaltyCustomer> getCustomer(int id, {CancelToken? cancelToken});
  Future<LoyaltyPage<LoyaltyPointsMovement>> getMovements(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });
  Future<LoyaltyPage<LoyaltyCoupon>> getCoupons(
    int enrollmentId, {
    int page = 0,
    int size = 20,
    CancelToken? cancelToken,
  });
}
