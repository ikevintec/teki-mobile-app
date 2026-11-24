import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/utils/notifications.dart';

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
      contains('No hay conexión'),
    );
    expect(mensajeErrorLegible('El RUC no existe'), 'El RUC no existe');
  });
}
