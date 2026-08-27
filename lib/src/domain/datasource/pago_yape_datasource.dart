import 'package:teki_app/src/data/models/replicador/replicador_app.dart';
import 'package:teki_app/src/data/models/yape/pago_yape.dart';

abstract class PagoYapeDatasource {
  Future<PagoYapePage> getPagos({required int pageNumber, int perPage = 20});

  Future<PagoYape> createPago({
    required String nombrePagador,
    required double monto,
    required String codigoOperacion,
    required NotificationAppType tipoApp,
  });
}
