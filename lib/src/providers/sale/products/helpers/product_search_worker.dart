import 'dart:async';
import 'dart:isolate';

import 'package:teki_app/src/providers/sale/products/helpers/product_local_search.dart';

/// Isolate de larga vida que guarda el índice de búsqueda en su propia memoria.
///
/// No se usa `compute` porque levanta un isolate por llamada y copia los
/// argumentos: buscar sobre ~20k productos serializaría la lista entera en cada
/// tecleo. Acá el índice viaja una sola vez y cada búsqueda solo manda un String
/// y recibe una lista de posiciones.
class ProductSearchWorker {
  Isolate? _isolate;
  SendPort? _commands;
  ReceivePort? _responses;
  Future<bool>? _spawning;

  final Map<int, Completer<List<int>>> _pending = {};
  int _nextRequestId = 0;

  /// Publica el índice en el isolate; lo levanta en la primera llamada.
  Future<void> setIndex(List<ProductSearchEntry> index) async {
    if (!await _ensureSpawned()) return;
    _commands?.send(_IndexMessage(index));
  }

  /// Devuelve `null` si el isolate no está disponible, para que el llamador
  /// resuelva la búsqueda en el hilo principal.
  Future<List<int>?> search(
    String query, {
    int limit = kLocalSearchMaxResults,
  }) async {
    if (!await _ensureSpawned()) return null;

    final id = _nextRequestId++;
    final completer = Completer<List<int>>();
    _pending[id] = completer;
    _commands!.send(_SearchMessage(id, query, limit));
    return completer.future;
  }

  /// Apaga el isolate. Se puede volver a levantar con [setIndex] o [search].
  void shutdown() {
    for (final completer in _pending.values) {
      if (!completer.isCompleted) completer.complete(const []);
    }
    _pending.clear();
    _responses?.close();
    _responses = null;
    _commands = null;
    _isolate?.kill(priority: Isolate.immediate);
    _isolate = null;
  }

  Future<bool> _ensureSpawned() {
    if (_commands != null) return Future.value(true);
    return _spawning ??= _spawn().whenComplete(() => _spawning = null);
  }

  Future<bool> _spawn() async {
    final responses = ReceivePort();
    final handshake = Completer<SendPort>();

    responses.listen((message) {
      if (message is SendPort) {
        if (!handshake.isCompleted) handshake.complete(message);
        return;
      }
      if (message is _SearchResponse) {
        final completer = _pending.remove(message.id);
        if (completer != null && !completer.isCompleted) {
          completer.complete(message.positions);
        }
      }
    });

    try {
      _isolate = await Isolate.spawn(
        _productSearchIsolate,
        responses.sendPort,
        debugName: 'product-search',
      );
      _responses = responses;
      _commands = await handshake.future;
      return true;
    } catch (_) {
      responses.close();
      _isolate?.kill(priority: Isolate.immediate);
      _isolate = null;
      _responses = null;
      _commands = null;
      return false;
    }
  }
}

class _IndexMessage {
  final List<ProductSearchEntry> entries;
  const _IndexMessage(this.entries);
}

class _SearchMessage {
  final int id;
  final String query;
  final int limit;
  const _SearchMessage(this.id, this.query, this.limit);
}

class _SearchResponse {
  final int id;
  final List<int> positions;
  const _SearchResponse(this.id, this.positions);
}

void _productSearchIsolate(SendPort mainSendPort) {
  final commands = ReceivePort();
  mainSendPort.send(commands.sendPort);

  var index = const <ProductSearchEntry>[];

  commands.listen((message) {
    if (message is _IndexMessage) {
      index = message.entries;
      return;
    }
    if (message is _SearchMessage) {
      mainSendPort.send(_SearchResponse(
        message.id,
        runProductSearch(index, message.query, limit: message.limit),
      ));
    }
  });
}
