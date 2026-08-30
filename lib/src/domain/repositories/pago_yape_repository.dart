import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';

/// El backend rechazó el pago de forma permanente (validación 4xx):
/// reintentarlo no lo va a arreglar, hay que descartarlo de la cola.
class PagoYapeRechazadoException implements Exception {
  final String message;

  PagoYapeRechazadoException(this.message);

  @override
  String toString() => message;
}

abstract class PagoYapeRepository {
  Future<PagoYapePage> getPagos({required int pageNumber, int perPage = 20});

  Future<PagoYape> createPago({
    required String nombrePagador,
    required double monto,
    required String codigoOperacion,
    required NotificationAppType tipoApp,
  });
}
