import 'package:teki_app/src/data/models/replicador/replicador_app.dart';

abstract class ReplicadorAppDatasource {
  Future<List<ReplicadorApp>> getApps();

  Future<List<ReplicadorApp>> updateApps(Set<NotificationAppType> types);
}
