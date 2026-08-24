import 'package:teki_app/src/data/models/yape/pago_yape.dart';

abstract class PagoYapeRepository {
  Future<PagoYapePage> getPagos({required int pageNumber, int perPage = 20});

  Future<PagoYape> createPago({
    required String nombrePagador,
    required double monto,
    required String codigoOperacion,
  });
}
