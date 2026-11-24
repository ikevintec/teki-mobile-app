import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/domain/datasource/replicador_app_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class RemoteReplicadorApp extends ReplicadorAppDatasource {
  final Dio dio;

  RemoteReplicadorApp({Dio? dio}) : dio = dio ?? ApiClient.dio;

  @override
  Future<List<ReplicadorApp>> getApps() async {
    final response = await dio.get('/replicador-notificaciones/apps');
    return _parse(response.data);
  }

  @override
  Future<List<ReplicadorApp>> updateApps(Set<NotificationAppType> types) async {
    final response = await dio.put(
      '/replicador-notificaciones/apps',
      data: {'tiposApp': types.map((type) => type.code).toList()},
    );
    return _parse(response.data);
  }

  List<ReplicadorApp> _parse(dynamic data) {
    final map = Map<String, dynamic>.from(data as Map);
    final apps = map['aplicaciones'] as List? ?? const [];
    return apps
        .whereType<Map>()
        .map((item) => ReplicadorApp.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
