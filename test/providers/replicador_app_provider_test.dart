import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/domain/repositories/replicador_app_repository.dart';
import 'package:teki_app/src/providers/replicador/replicador_app_provider.dart';

class _FakeRepository extends ReplicadorAppRepository {
  Set<NotificationAppType> selected = {NotificationAppType.yape};

  @override
  Future<List<ReplicadorApp>> getApps() async => _apps();

  @override
  Future<List<ReplicadorApp>> updateApps(Set<NotificationAppType> types) async {
    selected = {...types};
    return _apps();
  }

  List<ReplicadorApp> _apps() => NotificationAppType.values
      .map(
        (type) => ReplicadorApp(
          type: type,
          name: type.label,
          selected: selected.contains(type),
        ),
      )
      .toList();
}

void main() {
  test('carga y reemplaza la selección del replicador', () async {
    final repository = _FakeRepository();
    final notifier = ReplicadorAppNotifier(repository);

    await notifier.initialize(enabled: true);
    expect(notifier.state.selectedTypes, {NotificationAppType.yape});

    await notifier.updateSelection({
      NotificationAppType.bbva,
      NotificationAppType.interbank,
    });
    expect(notifier.state.selectedTypes, {
      NotificationAppType.bbva,
      NotificationAppType.interbank,
    });

    notifier.clear();
    expect(notifier.state.selectedTypes, isEmpty);
    notifier.dispose();
  });
}
