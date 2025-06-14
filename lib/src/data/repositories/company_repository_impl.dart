import 'package:teki_app/src/data/datasource/remote_company.dart';
import 'package:teki_app/src/data/models/teki_model/company.dart';
import 'package:teki_app/src/domain/datasource/company_datasource.dart';
import 'package:teki_app/src/domain/repositories/company_repository.dart';

class CompanyRepositoryImpl extends CompanyRepository {
  final CompanyDatasource companyDatasource;
  CompanyRepositoryImpl({CompanyDatasource? companyDatasource})
      : companyDatasource = companyDatasource ?? RemoteCompany();

  @override
  Future<Company> getCompanyById(int id) {
    return companyDatasource.getCompanyById(id);
  }
}
