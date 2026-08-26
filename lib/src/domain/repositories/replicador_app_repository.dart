import 'package:teki_app/src/data/models/replicador/replicador_app.dart';

abstract class ReplicadorAppRepository {
  Future<List<ReplicadorApp>> getApps();

  Future<List<ReplicadorApp>> updateApps(Set<NotificationAppType> types);
}
