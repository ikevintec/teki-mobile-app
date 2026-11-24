import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:teki_app/src/data/models/replicador/replicador_app.dart';

/// Notificación de Yape capturada por el servicio nativo de Android.
class YapeCapture {
  final String id;
  final String title;
  final String text;
  final String bigText;
  final NotificationAppType typeApp;

  const YapeCapture({
    required this.id,
    required this.title,
    required this.text,
    required this.bigText,
    this.typeApp = NotificationAppType.yape,
  });

  factory YapeCapture.fromMap(Map<String, dynamic> map) => YapeCapture(
    id: map['id']?.toString() ?? '',
    title: map['title']?.toString() ?? '',
    text: map['text']?.toString() ?? '',
    bigText: map['bigText']?.toString() ?? '',
    typeApp: NotificationAppType.fromCode(
      map['tipoApp']?.toString() ?? NotificationAppType.yape.code,
    ),
  );

  /// Todo el texto disponible de la notificación, para parsear.
  String get _source => [text, bigText, title].where((s) => s.isNotEmpty).join(' ');

  /// Intenta extraer los datos del pago. Devuelve `null` si no encuentra monto
  /// (es decir, no parece una notificación de pago recibido).
  ///
  /// Formato típico de la notificación de Yape:
  ///   "Luis Alb* te envió un pago por S/ 1. El cod. de seguridad es: 984"
  YapePaymentData? parse() {
    final source = _source;

    // Monto: captura el número tras "S/" sin arrastrar el punto de fin de frase.
    final montoMatch = RegExp(r'S/\.?\s*([\d.,]+)').firstMatch(source);
    if (montoMatch == null) return null;
    final monto = _normalizeMonto(montoMatch.group(1)!);
    if (monto == null || monto <= 0) return null;

    String nombre = '';
    final nombrePattern = switch (typeApp) {
      NotificationAppType.yape =>
        r'^(.*?)\s+te\s+(?:envió|envio|pagó|pago)(?:\s|$)',
      NotificationAppType.interbank => r'^(.*?)\s+te\s+ha\s+plineado\b',
      NotificationAppType.bbva => r'^(.*?)\s+te\s+pline[oó](?:\s|$)',
    };
    final nombreMatch = RegExp(
      nombrePattern,
      caseSensitive: false,
    ).firstMatch(source.trim());
    if (nombreMatch != null) {
      nombre = nombreMatch.group(1)!.trim();
    }
    if (nombre.isEmpty &&
        title.isNotEmpty &&
        !title.toLowerCase().contains('yape')) {
      nombre = title.trim();
    }

    String codigo = '-';
    if (typeApp == NotificationAppType.yape) {
      final codigoMatch = RegExp(
        r'(?:operaci[oó]n|seguridad)\D*(\d+)',
        caseSensitive: false,
      ).firstMatch(source);
      if (codigoMatch != null) {
        codigo = codigoMatch.group(1)!.trim();
      } else if (nombreMatch == null) {
        // Sin código y sin la frase "te envió un pago": promoción u otro
        // aviso de Yape con monto, no un pago recibido.
        return null;
      }
    }

    return YapePaymentData(
      nombrePagador: nombre,
      monto: monto,
      codigoOperacion: codigo,
      tipoApp: typeApp,
    );
  }

  /// Normaliza un monto peruano ("1", "1.", "25,50", "1,234.50") a double.
  static double? _normalizeMonto(String raw) {
    // Quita separadores colgantes ("1." -> "1").
    var value = raw.replaceAll(RegExp(r'[.,]+$'), '');
    if (value.contains(',') && value.contains('.')) {
      // "1,234.50": la coma es separador de miles.
      value = value.replaceAll(',', '');
    } else if (value.contains(',')) {
      // "25,50": la coma es separador decimal.
      value = value.replaceAll(',', '.');
    }
    return double.tryParse(value);
  }
}

/// Datos de pago ya parseados listos para enviar al backend.
class YapePaymentData {
  final String nombrePagador;
  final double monto;
  final String codigoOperacion;
  final NotificationAppType tipoApp;

  const YapePaymentData({
    required this.nombrePagador,
    required this.monto,
    required this.codigoOperacion,
    required this.tipoApp,
  });
}

/// Puente hacia el `NotificationListenerService` nativo de Android.
class YapeNotificationService {
  YapeNotificationService._();
  static final YapeNotificationService instance = YapeNotificationService._();

  static const MethodChannel _method = MethodChannel('pe.teki.app/yape');
  static const EventChannel _events = EventChannel('pe.teki.app/yape/events');

  Stream<YapeCapture>? _stream;

  /// El replicador solo existe en Android: iOS no deja leer notificaciones de
  /// otras apps, así que allí no hay nada que capturar ni que configurar.
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// ¿El usuario habilitó el acceso a notificaciones para Teki?
  Future<bool> isPermissionGranted() async {
    if (!isSupported) return false;
    try {
      return await _method.invokeMethod<bool>('isPermissionGranted') ?? false;
    } catch (e) {
      debugPrint('[Yape] isPermissionGranted error: $e');
      return false;
    }
  }

  /// Abre la pantalla de sistema para conceder el acceso a notificaciones.
  Future<void> openSettings() async {
    if (!isSupported) return;
    try {
      await _method.invokeMethod('openSettings');
    } catch (e) {
      debugPrint('[Yape] openSettings error: $e');
    }
  }

  Future<void> setEnabledApps(Set<NotificationAppType> types) async {
    if (!isSupported) return;
    try {
      await _method.invokeMethod(
        'setEnabledApps',
        types.map((type) => type.code).toList(),
      );
    } catch (e) {
      debugPrint('[Replicador] setEnabledApps error: $e');
    }
  }

  /// Lee (sin borrar) las notificaciones de Yape encoladas por el nativo.
  Future<List<YapeCapture>> peekQueue() async {
    if (!isSupported) return const [];
    try {
      final raw = await _method.invokeMethod<String>('peekQueue') ?? '[]';
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => YapeCapture.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('[Yape] peekQueue error: $e');
      return const [];
    }
  }

  /// Confirma (elimina de la cola) los items ya registrados en el backend.
  Future<void> ackItems(List<String> ids) async {
    if (!isSupported || ids.isEmpty) return;
    try {
      await _method.invokeMethod('ackItems', ids);
    } catch (e) {
      debugPrint('[Yape] ackItems error: $e');
    }
  }

  /// Espeja token y baseUrl en las preferencias nativas: el worker de Android
  /// no puede leer `flutter_secure_storage` ni el `.env`, y los necesita para
  /// enviar los pagos con la app cerrada.
  Future<void> setSyncCredentials({
    required String token,
    required String baseUrl,
  }) async {
    if (!isSupported) return;
    try {
      await _method.invokeMethod('setSyncCredentials', {
        'token': token,
        'baseUrl': baseUrl,
      });
    } catch (e) {
      debugPrint('[Yape] setSyncCredentials error: $e');
    }
  }

  Future<void> clearSyncCredentials() async {
    if (!isSupported) return;
    try {
      await _method.invokeMethod('clearSyncCredentials');
    } catch (e) {
      debugPrint('[Yape] clearSyncCredentials error: $e');
    }
  }

  Future<bool> isIgnoringBatteryOptimizations() async {
    if (!isSupported) return true;
    try {
      return await _method.invokeMethod<bool>(
            'isIgnoringBatteryOptimizations',
          ) ??
          true;
    } catch (e) {
      debugPrint('[Yape] isIgnoringBatteryOptimizations error: $e');
      return true;
    }
  }

  /// Devuelve `true` si ya estaba excluida (en ese caso no abre nada).
  Future<bool> requestIgnoreBatteryOptimizations() async {
    if (!isSupported) return true;
    try {
      return await _method.invokeMethod<bool>(
            'requestIgnoreBatteryOptimizations',
          ) ??
          false;
    } catch (e) {
      debugPrint('[Yape] requestIgnoreBatteryOptimizations error: $e');
      return false;
    }
  }

  /// Stream de capturas en vivo mientras la app está abierta.
  Stream<YapeCapture> get onCapture {
    if (!isSupported) return const Stream.empty();
    _stream ??= _events.receiveBroadcastStream().map((event) {
      final map = jsonDecode(event as String) as Map;
      return YapeCapture.fromMap(Map<String, dynamic>.from(map));
    });
    return _stream!;
  }
}
