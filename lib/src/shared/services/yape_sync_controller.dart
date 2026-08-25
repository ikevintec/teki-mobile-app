import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/repositories/pago_yape_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/pago_yape_repository.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/shared/services/token_storage.dart';
import 'package:teki_app/src/shared/services/yape_notification_service.dart';

/// Se incrementa cada vez que se registra un Yape nuevo; las pantallas que
/// muestran la lista pueden escucharlo para refrescarse.
final yapeSyncRevisionProvider = StateProvider<int>((ref) => 0);

/// Registra en el backend los Yapes capturados por el servicio nativo, de forma
/// global a la app: drena la cola al iniciar y al volver del fondo, y escucha
/// las capturas en vivo. Funciona en cualquier pantalla mientras la app esté
/// viva (no requiere que la pantalla de Yapes esté abierta).
class YapeSyncController with WidgetsBindingObserver {
  YapeSyncController._();
  static final YapeSyncController instance = YapeSyncController._();

  PagoYapeRepository _repository = PagoYapeRepositoryImpl();
  YapeNotificationService _service = YapeNotificationService.instance;
  ProviderContainer? _container;

  bool _started = false;
  bool _draining = false;
  bool _enabled = false;

  /// Permite inyectar dependencias en tests.
  @visibleForTesting
  void configureForTest({
    required PagoYapeRepository repository,
    required YapeNotificationService service,
  }) {
    _repository = repository;
    _service = service;
  }

  void start(ProviderContainer container) {
    if (_started) return;
    _started = true;
    _container = container;
    WidgetsBinding.instance.addObserver(this);
    _service.onCapture.listen((_) => drainNow());
    container.listen<AuthState>(
      authStateProvider,
      (_, _) => _syncEnabledState(),
      fireImmediately: true,
    );
    container.listen<SesionState>(
      sesionProvider,
      (_, _) => _syncEnabledState(),
      fireImmediately: true,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _syncEnabledState();
  }

  Future<void> _syncEnabledState() async {
    final container = _container;
    if (container == null) return;
    final enabled = container.read(authStateProvider).isLoggedIn &&
        container.read(sesionProvider).config?.verNotificacionYape == true;
    if (_enabled != enabled) {
      _enabled = enabled;
      await _service.setListenerEnabled(enabled);
    }
    if (enabled) await drainNow();
  }

  /// Drena la cola nativa y registra cada pago pendiente. Reentrante-seguro.
  Future<void> drainNow() async {
    if (_draining || !_enabled) return;
    _draining = true;
    try {
      // Sin sesión no registramos: un POST sin token dispararía el logout global.
      final token = await TokenStorage.getToken();
      if (token == null) return;

      final captures = await _service.peekQueue();
      if (captures.isEmpty) return;

      final ackIds = <String>[];
      var posted = 0;
      for (final capture in captures) {
        final data = capture.parse();
        if (data == null) {
          debugPrint('[Yape] Ignorada (sin monto): "${capture.text}"');
          ackIds.add(capture.id); // no es un pago: fuera de la cola
          continue;
        }
        try {
          await _repository.createPago(
            nombrePagador: data.nombrePagador,
            monto: data.monto,
            codigoOperacion: data.codigoOperacion,
          );
          debugPrint(
            '[Yape] Registrado: ${data.nombrePagador} S/ ${data.monto} (op ${data.codigoOperacion})',
          );
          ackIds.add(capture.id);
          posted++;
        } catch (e) {
          // Falla de red: se deja en la cola para reintentar luego.
          debugPrint('[Yape] Error registrando, se reintentará: $e');
        }
      }
      await _service.ackItems(ackIds);
      if (posted > 0) {
        final revision = _container?.read(yapeSyncRevisionProvider.notifier);
        if (revision != null) revision.state++;
      }
    } finally {
      _draining = false;
    }
  }
}
