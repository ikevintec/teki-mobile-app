import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:teki_app/src/shared/services/error_reporting.dart';

void main() {
  test('removes customer, request, breadcrumb and exception message data', () {
    final event = SentryEvent(
      user: SentryUser(email: 'private@example.com'),
      request: SentryRequest(
        url: 'https://test/?token=secret',
        headers: {'Authorization': 'secret'},
        data: {'password': 'secret'},
      ),
      message: SentryMessage('private invoice'),
      // Verify that legacy payloads are also scrubbed.
      // ignore: deprecated_member_use
      extra: {'invoice': 'private'},
      breadcrumbs: [Breadcrumb(message: 'secret')],
      tags: {
        'operation': 'http.server',
        'http.status_code': '500',
        'token': 'secret',
      },
      exceptions: [
        SentryException(
          type: 'StateError',
          value: 'private',
          stackTrace: SentryStackTrace(
            frames: [
              SentryStackFrame(
                fileName: 'main.dart?token=secret',
                function: 'save',
                lineNo: 42,
                vars: {'password': 'secret'},
              ),
            ],
          ),
        ),
      ],
    );
    final clean = ErrorReporting.sanitize(event);
    expect(clean.user, isNull);
    expect(clean.request, isNull);
    expect(clean.message, isNull);
    expect(clean.breadcrumbs, isNull);
    expect(clean.tags!['token'], isNull);
    expect(clean.exceptions!.single.value, 'StateError');
    expect(clean.exceptions!.single.stackTrace!.frames.single.lineNo, 42);
    expect(clean.toJson().toString(), isNot(contains('private')));
    expect(clean.toJson().toString(), isNot(contains('secret')));
  });

  test(
    'telemetry is safe before initialization and skips ordinary HTTP errors',
    () async {
      await ErrorReporting.captureHttpFailure(
        DioException(
          requestOptions: RequestOptions(path: '/api'),
          response: Response(
            requestOptions: RequestOptions(path: '/api'),
            statusCode: 400,
          ),
        ),
      );
      await ErrorReporting.capture(
        StateError('test'),
        StackTrace.current,
        'test.before-init',
      );
    },
  );
}
