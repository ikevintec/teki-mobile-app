import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';

abstract class LoyaltyDatasource {
  Future<List<LoyaltyCard>> getCards({CancelToken? cancelToken});
  Future<LoyaltyCard> getCard(int id, {CancelToken? cancelToken});
}
