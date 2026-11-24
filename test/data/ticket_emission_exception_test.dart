import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/datasource/remote_ticket_sale.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/errors/ticket_emission_exception.dart';

void main() {
  test('timeout y fallo 500 conservan el resultado como desconocido', () async {
    for (final status in [null, 500]) {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.reject(
              DioException(
                requestOptions: options,
                type: status == null
                    ? DioExceptionType.receiveTimeout
                    : DioExceptionType.badResponse,
                response: status == null
                    ? null
                    : Response(requestOptions: options, statusCode: status),
              ),
            );
          },
        ),
      );
      final datasource = RemoteTicketSaleDatasource(dio: dio);
      await expectLater(
        datasource.createTicket(Ticket()),
        throwsA(isA<TicketEmissionException>()),
      );
    }
  });
  test(
    'una respuesta inválida después del POST tampoco permite reemitir a ciegas',
    () async {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
      addTearDown(() => dio.close(force: true));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: <String, dynamic>{},
              ),
            );
          },
        ),
      );
      await expectLater(
        RemoteTicketSaleDatasource(dio: dio).createTicket(Ticket()),
        throwsA(isA<TicketEmissionException>()),
      );
    },
  );
  test('un rechazo explícito de validación conserva su mensaje', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com/api'));
    addTearDown(() => dio.close(force: true));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.reject(
            DioException(
              requestOptions: options,
              type: DioExceptionType.badResponse,
              response: Response(
                requestOptions: options,
                statusCode: 412,
                data: {'mensaje': 'Seleccione un cliente'},
              ),
            ),
          );
        },
      ),
    );
    await expectLater(
      RemoteTicketSaleDatasource(dio: dio).createTicket(Ticket()),
      throwsA('Seleccione un cliente'),
    );
  });
}
