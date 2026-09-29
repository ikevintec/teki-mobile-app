import 'package:teki_app/src/data/datasource/remote_online_order.dart';
import 'package:teki_app/src/data/models/response/online_order_response.dart';
import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/datasource/online_order_datasource.dart';
import 'package:teki_app/src/domain/repositories/online_order_repository.dart';

class OnlineOrderRepositoryImpl implements OnlineOrderRepository {
  final OnlineOrderDatasource datasource;

  OnlineOrderRepositoryImpl({OnlineOrderDatasource? datasource})
    : datasource = datasource ?? RemoteOnlineOrder();

  @override
  Future<OnlineOrderResponse> getOrders(Map<String, dynamic> params) =>
      datasource.getOrders(params);

  @override
  Future<OnlineOrder> getOrder(int id) => datasource.getOrder(id);

  @override
  Future<Ticket> getSaleDraft(int id) => datasource.getSaleDraft(id);

  @override
  Future<OnlineOrder> changeStatus(int id, String status) =>
      datasource.changeStatus(id, status);
}
