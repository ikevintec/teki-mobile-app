import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Error reporting must never send customer, payment, auth or request payloads.
class ErrorReporting {
  static const dsn = String.fromEnvironment(
    'GLITCHTIP_DSN',
    defaultValue:
        'https://1016560479184e16a8aa5644158db724@glitchtip.cbetcloud.com/8',
  );
  static final _recent = <String, DateTime>{};

  static void configure(SentryFlutterOptions options) {
    options
      ..dsn = dsn
      ..environment = const String.fromEnvironment(
        'GLITCHTIP_ENVIRONMENT',
        defaultValue: kReleaseMode ? 'production' : 'development',
      )
      ..sendDefaultPii = false
      ..enableAutoSessionTracking = false
      ..tracesSampleRate = 0
      ..attachScreenshot = false;
    options.beforeBreadcrumb = (breadcrumb, hint) => null;
    options.beforeSend = (event, hint) => sanitize(event);
    options.replay.sessionSampleRate = 0;
    options.replay.onErrorSampleRate = 0;
  }

  static SentryEvent sanitize(SentryEvent event) {
    // Rebuild from an allow-list. copyWith(null) would retain sensitive fields.
    return SentryEvent(
      eventId: event.eventId,
      timestamp: event.timestamp,
      platform: event.platform,
      level: event.level,
      release: event.release,
      dist: event.dist,
      environment: event.environment,
      sdk: event.sdk,
      debugMeta: event.debugMeta,
      fingerprint: event.fingerprint,
      tags: {
        'application': 'teki-mobile',
        for (final entry in (event.tags ?? <String, String>{}).entries)
          if ([
            'operation',
            'http.status_code',
            'http.method',
          ].contains(entry.key))
            entry.key: entry.value,
      },
      exceptions: event.exceptions?.map((exception) {
        return SentryException(
          type: exception.type,
          value: exception.type ?? 'Error',
          module: exception.module,
          mechanism: exception.mechanism == null
              ? null
              : Mechanism(
                  type: exception.mechanism!.type,
                  handled: exception.mechanism!.handled,
                ),
          stackTrace: exception.stackTrace == null
              ? null
              : SentryStackTrace(
                  frames: [
                    for (final frame in exception.stackTrace!.frames)
                      SentryStackFrame(
                        fileName: frame.fileName?.split(RegExp(r'[?#]')).first,
                        function: frame.function,
                        module: frame.module,
                        lineNo: frame.lineNo,
                        colNo: frame.colNo,
                        inApp: frame.inApp,
                        package: frame.package,
                        instructionAddr: frame.instructionAddr,
                        imageAddr: frame.imageAddr,
                        symbolAddr: frame.symbolAddr,
                      ),
                  ],
                ),
        );
      }).toList(),
    );
  }

  static Future<void> capture(
    Object error,
    StackTrace? stackTrace,
    String operation, {
    int? status,
    String? method,
  }) async {
    try {
      final key = '$operation:${error.runtimeType}:$status:$method';
      final now = DateTime.now();
      final last = _recent[key];
      if (last != null && now.difference(last).inSeconds < 60) return;
      if (_recent.length >= 100) _recent.clear();
      _recent[key] = now;
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          scope.setTag('application', 'teki-mobile');
          scope.setTag('operation', operation);
          if (status != null) scope.setTag('http.status_code', '$status');
          if (method != null) scope.setTag('http.method', method);
          scope.fingerprint = [
            'teki-mobile',
            operation,
            '$status',
            method ?? '',
          ];
        },
      );
    } catch (_) {
      // Telemetry failures cannot interrupt a sale or mask the original error.
    }
  }

  static Future<void> captureHttpFailure(DioException error) async {
    final status = error.response?.statusCode;
    if (status != null && status >= 500) {
      await capture(
        StateError('HTTP_$status'),
        error.stackTrace,
        'http.server',
        status: status,
        method: error.requestOptions.method,
      );
    }
  }
}
