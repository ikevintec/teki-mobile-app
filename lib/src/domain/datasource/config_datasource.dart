import 'package:teki_app/src/data/models/teki_model/config.dart';

abstract class ConfigDatasource {
  Future<ConfigCompany> getConfigValue();
}