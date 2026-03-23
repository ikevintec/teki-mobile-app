import 'package:teki_app/src/data/models/teki_model/currency.dart';

abstract class CurrencyRepository {
  Future<List<Currency>> getCurrencies();
}