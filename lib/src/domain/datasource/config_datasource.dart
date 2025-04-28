import 'package:teki_app/src/data/models/config.dart';

abstract class ConfigDatasource {
  Future<ConfigCompany> getConfigValue();
}