import 'package:teki_app/src/data/models/company.dart';

abstract class CompanyRepository {
  Future<Company> getCompanyById(int id);
}