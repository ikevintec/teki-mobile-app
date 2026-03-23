import 'package:teki_app/src/data/models/teki_model/company.dart';

abstract class CompanyRepository {
  Future<Company> getCompanyById(int id);
}