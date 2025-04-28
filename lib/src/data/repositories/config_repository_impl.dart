import 'package:teki_app/src/data/datasource/remote_config.dart';
import 'package:teki_app/src/data/models/config.dart';
import 'package:teki_app/src/domain/datasource/config_datasource.dart';
import 'package:teki_app/src/domain/repositories/config_repository.dart';

class ConfigRepositoryImpl extends ConfigRepository {
  final ConfigDatasource configDatasource;

  ConfigRepositoryImpl({ConfigDatasource? configDatasource})
      : configDatasource = configDatasource ?? RemoteConfigDatasource();

  @override
  Future<ConfigCompany> getConfigValue() {
    return configDatasource.getConfigValue();
  }
}
