import 'package:teki_app/src/data/datasource/remote_replicador_app.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/domain/datasource/replicador_app_datasource.dart';
import 'package:teki_app/src/domain/repositories/replicador_app_repository.dart';

class ReplicadorAppRepositoryImpl extends ReplicadorAppRepository {
  final ReplicadorAppDatasource datasource;

  ReplicadorAppRepositoryImpl({ReplicadorAppDatasource? datasource})
    : datasource = datasource ?? RemoteReplicadorApp();

  @override
  Future<List<ReplicadorApp>> getApps() => datasource.getApps();

  @override
  Future<List<ReplicadorApp>> updateApps(Set<NotificationAppType> types) =>
      datasource.updateApps(types);
}
