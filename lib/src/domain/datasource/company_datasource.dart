import 'package:teki_app/src/data/models/teki_model/company.dart';

abstract class CompanyDatasource {
  Future<Company> getCompanyById(int id);
}