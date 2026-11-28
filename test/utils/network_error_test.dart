import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/shared/services/internet_monitor.dart';
import 'package:teki_app/src/utils/network_error.dart';

void main() {
  DioException failure(DioExceptionType type, {int? status}) {
    final request = RequestOptions(path: '/auth/login');
    return DioException(
      requestOptions: request,
      type: type,
      message: 'The connection errored: Connection reset by peer',
      response: status == null
          ? null
          : Response(requestOptions: request, statusCode: status),
    );
  }

  test('el reset sin Internet se diferencia del reset con Internet', () async {
    for (final connected in [false, true]) {
      final monitor = InternetMonitor(check: () async => connected);
      final error = failure(DioExceptionType.connectionError);
      expect(
        await networkErrorMessage(error, monitor),
        connected ? NetworkMessages.unreachable : NetworkMessages.offline,
      );
      monitor.dispose();
    }
  });

  test(
    '5xx muestra servicio no disponible incluso con estado offline previo',
    () async {
      var probes = 0;
      final monitor = InternetMonitor(
        check: () async {
          probes++;
          return false;
        },
      );
      addTearDown(monitor.dispose);
      await monitor.refresh();
      for (final status in [500, 502, 503, 504]) {
        expect(
          await networkErrorMessage(
            failure(DioExceptionType.badResponse, status: status),
            monitor,
          ),
          NetworkMessages.unavailable,
        );
        expect(monitor.value, InternetState.connected);
      }
      expect(probes, 1);
    },
  );

  test(
    'timeout no afirma caída del servicio y 4xx/cancelación conservan manejo',
    () async {
      final monitor = InternetMonitor(check: () async => true);
      addTearDown(monitor.dispose);
      for (final type in [
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
      ]) {
        expect(
          await networkErrorMessage(failure(type), monitor),
          NetworkMessages.timeout,
        );
      }
      for (final status in [400, 401, 403, 422]) {
        expect(
          await networkErrorMessage(
            failure(DioExceptionType.badResponse, status: status),
            monitor,
          ),
          isNull,
        );
      }
      expect(
        await networkErrorMessage(failure(DioExceptionType.cancel), monitor),
        isNull,
      );
    },
  );
}
