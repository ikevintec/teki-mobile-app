import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/utils/notifications.dart';
import 'package:teki_app/src/utils/network_error.dart';

void main() {
  test('el texto técnico de Dio se cambia por un mensaje entendible', () {
    expect(
      mensajeErrorLegible(
        'DioException [bad response]: This exception was thrown because the response has a status code of 500',
      ),
      'No se pudo completar la operación. Inténtalo de nuevo.',
    );
    expect(
      mensajeErrorLegible('DioException [connection error]: SocketException'),
      NetworkMessages.unreachable,
    );
    expect(mensajeErrorLegible('El RUC no existe'), 'El RUC no existe');
  });

  test(
    'el reset de la captura no expone texto técnico ni acusa falta de Internet',
    () {
      expect(
        mensajeErrorLegible(
          'The connection errored: Connection reset by peer This indicates an error which mos...',
        ),
        NetworkMessages.unreachable,
      );
      expect(
        mensajeErrorLegible(
          'DioException [connection error]: ${NetworkMessages.offline}\nSocketException: reset',
        ),
        NetworkMessages.offline,
      );
      expect(
        mensajeErrorLegible('Exception: ${NetworkMessages.unavailable}'),
        NetworkMessages.unavailable,
      );
    },
  );
}
