import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'direct_checkout_service.dart';

class DirectCheckoutController extends ChangeNotifier {
  final DirectCheckoutService service;
  final String scope;
  Map<String, dynamic> draft;
  Map<String, dynamic>? quote;
  Map<String, dynamic>? attempt;
  DirectCheckoutResult? result;
  bool loading = false;
  bool busy = false;
  bool initialized = false;
  bool restoredAttempt = false;
  bool contextValid = true;
  String? error;
  String? quoteKey;
  int _revision = 0;
  bool _disposed = false;

  DirectCheckoutController({
    required this.service,
    required this.scope,
    required this.draft,
  });
  bool get uncertain => attempt != null;
  double get total => (quote?['totalVenta'] as num?)?.toDouble() ?? 0;
  String get currency => quote?['codigoMoneda'] ?? 'PEN';
  bool get ready =>
      initialized &&
      contextValid &&
      !busy &&
      !loading &&
      !uncertain &&
      quote != null &&
      quoteKey == signature &&
      (draft['serie'] as String?)?.isNotEmpty == true;

  String get signature => jsonEncode({
    'items': draft['pedido']['comandas'],
    'delivery': draft['pedido']['montoDelivery'],
    'office': draft['pedido']['puntoVenta'],
    'station': draft['idEstacionVenta'],
    'type': draft['tipoComprobante'],
    'exclude': draft['excluirIgv'],
  });

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> initialize() async {
    try {
      attempt = await service.pending(scope);
      if (attempt != null) {
        restoredAttempt = true;
        draft = jsonDecode(jsonEncode(attempt));
        quote = {
          'totalVenta': attempt!['montoEsperado'],
          'codigoMoneda': attempt!['codigoMoneda'],
        };
        error = 'Hay un pedido por confirmar. Recupérelo antes de continuar.';
      }
      initialized = true;
      _notify();
      if (!uncertain) await refresh();
    } catch (_) {
      error =
          'No se pudo recuperar el estado del pedido. Cierre y vuelva a intentarlo.';
      _notify();
    }
  }

  void update(Map<String, dynamic> value) {
    if (busy || uncertain || result != null) return;
    final before = signature;
    draft = value;
    if (before != signature) {
      ++_revision;
      loading = false;
      quoteKey = null;
    }
    _notify();
  }

  void invalidateContext() {
    contextValid = false;
    ++_revision;
    loading = false;
    quoteKey = null;
    error =
        'Cambió la empresa, sede o estación. Cierre y vuelva a completar el pedido.';
    _notify();
  }

  Future<void> refresh({bool force = false}) async {
    if (_disposed || busy || uncertain || result != null || !contextValid) {
      return;
    }
    final key = signature;
    if (!force && quote != null && quoteKey == key) return;
    final revision = ++_revision;
    final request = jsonDecode(jsonEncode(draft)) as Map<String, dynamic>;
    loading = true;
    quoteKey = null;
    error = null;
    _notify();
    try {
      final preview = await service.preview(request);
      if (_disposed || revision != _revision || key != signature) return;
      quote = preview;
      quoteKey = key;
    } catch (e) {
      if (_disposed || revision != _revision) return;
      error = message(e);
    } finally {
      if (!_disposed && revision == _revision) {
        loading = false;
        _notify();
      }
    }
  }

  Future<DirectCheckoutResult?> submit(String action) async {
    if (busy || !initialized || result != null || !contextValid) return null;
    if (!uncertain && action == 'INVOICE' && !ready) {
      error = 'Actualice el total y seleccione una serie antes de emitir.';
      _notify();
      return null;
    }
    busy = true;
    error = null;
    _notify();
    var sent = false;
    try {
      final request =
          attempt ??
          Map<String, dynamic>.from(
            jsonDecode(
              jsonEncode({
                ...draft,
                'action': action,
                'operationId': const Uuid().v4(),
                'montoEsperado': total,
                'codigoMoneda': currency,
              }),
            ),
          );
      await service.remember(scope, request);
      attempt = request;
      sent = true;
      final response = await service.submit(request);
      result = DirectCheckoutResult(
        response.order,
        response.check,
        response.replayed,
        response.action,
        // A replay may have been saved before any printer was contacted.
        // The printing coordinator claims the persisted operation before dispatch.
        automaticPrinting: true,
        checkoutData: response.checkoutData,
      );
      // A failed cleanup must never turn an acknowledged save into another save.
      try {
        await service.forget(scope);
      } catch (_) {
        /* Safe replay next time. */
      }
      attempt = null;
      return result;
    } catch (e) {
      final status = e is DioException ? e.response?.statusCode : null;
      if (sent &&
          status != null &&
          status >= 400 &&
          status < 500 &&
          ![408, 409, 429].contains(status)) {
        try {
          await service.forget(scope);
          attempt = null;
        } catch (_) {
          /* Keep the frozen attempt. */
        }
      }
      error = uncertain
          ? 'No se pudo confirmar el pedido. Pulse Recuperar pedido; no se cobrará dos veces.'
          : message(e);
      return null;
    } finally {
      busy = false;
      _notify();
    }
  }

  static String message(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        return (data['mensaje'] ??
                data['message'] ??
                'No se pudo completar el pedido.')
            .toString();
      }
      return 'Sin conexión. Puede reintentar, guardar borrador o abrir facturación completa.';
    }
    return 'No se pudo completar el pedido. Intente nuevamente.';
  }

  @override
  void dispose() {
    _disposed = true;
    ++_revision;
    super.dispose();
  }
}
