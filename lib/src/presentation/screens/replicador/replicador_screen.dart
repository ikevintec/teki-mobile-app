import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/presentation/widgets/app_bar/custom_app_bar.dart';
import 'package:teki_app/src/providers/replicador/replicador_app_provider.dart';
import 'package:teki_app/src/shared/services/yape_notification_service.dart';
import 'package:teki_app/src/utils/notifications.dart';

class ReplicadorScreen extends ConsumerStatefulWidget {
  const ReplicadorScreen({super.key});

  @override
  ConsumerState<ReplicadorScreen> createState() => _ReplicadorScreenState();
}

class _ReplicadorScreenState extends ConsumerState<ReplicadorScreen>
    with WidgetsBindingObserver {
  final _notificationService = YapeNotificationService.instance;
  bool _notificationAccess = false;
  bool _batteryOptimized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshNativeState();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshNativeState();
  }

  Future<void> _refreshNativeState() async {
    final granted = await _notificationService.isPermissionGranted();
    final exempt = await _notificationService.isIgnoringBatteryOptimizations();
    if (!mounted) return;
    setState(() {
      _notificationAccess = granted;
      _batteryOptimized = !exempt;
    });
  }

  Future<void> _requestBatteryExemption() async {
    final alreadyExempt = await _notificationService
        .requestIgnoreBatteryOptimizations();
    if (alreadyExempt && mounted) setState(() => _batteryOptimized = false);
  }

  Future<void> _toggle(NotificationAppType type, bool selected) async {
    final current = ref.read(replicadorAppProvider).selectedTypes;
    final next = {...current};
    selected ? next.add(type) : next.remove(type);
    try {
      await ref.read(replicadorAppProvider.notifier).updateSelection(next);
    } catch (e) {
      errorNotification(e.toString());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(replicadorAppProvider);
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(navigateName: 'Gestionar replicador'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _notificationAccessCard(),
          if (_notificationAccess && _batteryOptimized) ...[
            const SizedBox(height: 8),
            _batteryOptimizationCard(),
          ],
          const SizedBox(height: 16),
          const Text(
            'Aplicaciones',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (state.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (state.apps.isEmpty)
            _errorCard(state.error)
          else
            ...state.apps.map(
              (app) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: SwitchListTile(
                  value: app.selected,
                  onChanged: state.updating
                      ? null
                      : (value) => _toggle(app.type, value),
                  title: Text(app.name),
                  secondary: const Icon(Icons.notifications_active_outlined),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _notificationAccessCard() {
    final color = _notificationAccess ? Colors.green : Colors.orange;
    return Card(
      child: ListTile(
        onTap: _notificationService.openSettings,
        leading: Icon(
          _notificationAccess
              ? Icons.notifications_active
              : Icons.notifications_off,
          color: color,
        ),
        title: Text(
          _notificationAccess
              ? 'Acceso a notificaciones activado'
              : 'Acceso a notificaciones desactivado',
        ),
        subtitle: const Text('Toca para abrir la configuración del celular'),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  /// Sin la exención, Android puede retrasar el envío de los pagos capturados
  /// mientras la app está cerrada.
  Widget _batteryOptimizationCard() {
    return Card(
      child: ListTile(
        onTap: _requestBatteryExemption,
        leading: const Icon(Icons.battery_alert, color: Colors.orange),
        title: const Text('Optimización de batería activa'),
        subtitle: const Text(
          'Permite que Teki funcione sin restricciones para registrar los '
          'pagos aunque la app esté cerrada.',
        ),
        trailing: const Icon(Icons.chevron_right),
        isThreeLine: true,
      ),
    );
  }

  Widget _errorCard(String? message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(message ?? 'No se pudo cargar la configuración'),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: () => ref
                  .read(replicadorAppProvider.notifier)
                  .initialize(enabled: true),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
