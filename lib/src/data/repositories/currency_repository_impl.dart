
import 'package:teki_app/src/data/datasource/remote_currencies.dart';
import 'package:teki_app/src/data/models/teki_model/currency.dart';
import 'package:teki_app/src/domain/datasource/currency_datasource.dart';
import 'package:teki_app/src/domain/repositories/currency_repository.dart';

class CurrencyRepositoryImpl implements CurrencyRepository {
  final CurrencyDatasource currencyDatasource;
  CurrencyRepositoryImpl({CurrencyDatasource? currencyDatasource})
      : currencyDatasource = currencyDatasource ?? RemoteCurrencies();
  
  @override
  Future<List<Currency>> getCurrencies() async{
    return await currencyDatasource.getCurrencies();
  }
}