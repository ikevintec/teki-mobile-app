import 'package:teki_app/src/data/models/company.dart';

abstract class CompanyDatasource {
  Future<Company> getCompanyById(int id);
}