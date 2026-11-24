import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/inventory_sync_response.dart';
import 'package:teki_app/src/domain/datasource/inventory_sync_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteInventorySync implements InventorySyncDatasource {
  final Dio dio;

  RemoteInventorySync({Dio? dio}) : dio = dio ?? ApiClient.dio;

  Map<String, dynamic> _params({
    int? idPuntoVenta,
    String? search,
    int? pageNumber,
    int? perPage,
  }) {
    return <String, dynamic>{
      if (idPuntoVenta != null) 'idPuntoVenta': idPuntoVenta,
      if (search?.trim().isNotEmpty == true) 'clave': search!.trim(),
      if (pageNumber != null) 'pageNumber': pageNumber,
      if (perPage != null) 'perPage': perPage,
    };
  }

  @override
  Future<InventorySyncSummary> getSummary({
    int? idPuntoVenta,
    String? search,
  }) async {
    final response = await dio.get(
      '/inventory/sync-issues/summary',
      queryParameters: _params(idPuntoVenta: idPuntoVenta, search: search),
    );
    return InventorySyncSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<InventorySyncPage> getIssues({
    int? idPuntoVenta,
    String? search,
    required int pageNumber,
    required int perPage,
  }) async {
    final response = await dio.get(
      '/inventory/sync-issues',
      queryParameters: _params(
        idPuntoVenta: idPuntoVenta,
        search: search,
        pageNumber: pageNumber,
        perPage: perPage,
      ),
    );
    return InventorySyncPage.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  @override
  Future<InventorySyncFixResult> fixIssues(List<int> inventoryIds) async {
    final response = await dio.post(
      '/inventory/sync-issues/fix',
      data: inventoryIds,
      options: Options(contentType: Headers.jsonContentType),
    );
    return InventorySyncFixResult.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }
}
