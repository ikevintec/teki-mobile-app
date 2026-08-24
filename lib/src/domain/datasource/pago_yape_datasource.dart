import 'package:teki_app/src/data/models/yape/pago_yape.dart';

abstract class PagoYapeDatasource {
  Future<PagoYapePage> getPagos({required int pageNumber, int perPage = 20});
}
