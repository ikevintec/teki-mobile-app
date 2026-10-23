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
}
