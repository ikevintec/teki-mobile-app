import 'package:teki_app/src/data/models/config.dart';

abstract class ConfigRepository{
  Future<ConfigCompany> getConfigValue();
}