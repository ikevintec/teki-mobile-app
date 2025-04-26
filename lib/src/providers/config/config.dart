import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/companySummary.dart';
import 'package:teki_app/src/data/models/office.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/saleStation.dart';
import 'package:teki_app/src/data/repositories/sale_station_repository.impl.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repositoy.dart';

final configProvider = StateNotifierProvider<ConfigNotifier, ConfigState>((ref) {
  final SaleStationRepository saleStationRepository = SaleStationRepositoryImpl();
  return ConfigNotifier(
    saleStationRepository: saleStationRepository,
  );
});

class ConfigNotifier extends StateNotifier<ConfigState> {
  final SaleStationRepository saleStationRepository;
  ConfigNotifier({
   required this.saleStationRepository, 
  })
      : super(ConfigState(
          company: Companysummary(),
          companySelected: Companysummary(),
          office: Office(),
          roles: [],
          saleStation: SaleStation(),
          login: LoginResponse(),
          saleStations: [],
          companies: [],
          offices: [],
        ));

  void setFullConfig(LoginResponse login, List<SaleStation> saleStations) {
    Office? oficinaEncontrada = login.user?.puntosVenta?.firstWhere(
      (office) => office.rucAsignado == login.user?.rucAsignado,
      orElse: () => Office(),
    );
    state = state.copyWith(
      company: login.user?.empresa,
      companySelected: login.user?.empresa,
      office: oficinaEncontrada,
      roles: login.roles ?? [],
      saleStation: saleStations.isNotEmpty ? saleStations.first : SaleStation(),
      saleStations: saleStations,
      login: login,
      companies: [
        login.user?.empresa ?? Companysummary(),
        ...?login.user?.empresasAdjuntas
      ],
      offices: login.user?.puntosVenta,
    );
  }

  void changeCompany(Companysummary company) async{
    Office? oficinaEncontrada = state.offices?.firstWhere(
      (office) => office.rucAsignado == company.ruc,
      orElse: () => Office(),
    );
    state = state.copyWith(
      company: company,
    );
    if (oficinaEncontrada?.rucAsignado != null) {
      changeOffice(oficinaEncontrada!, false);
    }
  }
  void changeOffice(Office office, bool changeCompany) async{
    List<SaleStation> saleStations = await saleStationRepository.getSaleStations(office.id ?? 0);
    state = state.copyWith(
      office: office,
      saleStation: saleStations.isNotEmpty ? saleStations.first : SaleStation(),
      saleStations: saleStations,
    );

    if (changeCompany) {
      Companysummary? company = state.companies?.firstWhere(
        (company) => company.ruc == office.rucAsignado,
        orElse: () => Companysummary(),
      );
      if (company?.ruc != null) {
        state = state.copyWith(
          company: company,
        );
      }
    }
  }
  void changeSaleStation(SaleStation saleStation) {
    state = state.copyWith(
      saleStation: saleStation,
    );
  }
}

class ConfigState {
  final Companysummary? company;
  final Companysummary? companySelected;
  final List<Companysummary>? companies;
  final Office? office;
  final List<String>? roles;
  final SaleStation? saleStation;
  final List<SaleStation>? saleStations;
  final LoginResponse login;
  final List<Office>? offices;

  ConfigState({
    required this.login,
    this.company,
    this.companySelected,
    this.office,
    this.roles,
    this.saleStation,
    this.saleStations,
    this.companies,
    this.offices,
  });
  ConfigState copyWith({
    Companysummary? company,
    Companysummary? companySelected,
    Office? office,
    List<String>? roles,
    List<SaleStation>? saleStations,
    SaleStation? saleStation,
    LoginResponse? login,
    List<Companysummary>? companies,
    List<Office>? offices,
  }) {
    return ConfigState(
      company: company ?? this.company,
      companySelected: companySelected ?? this.companySelected,
      office: office ?? this.office,
      roles: roles ?? this.roles,
      saleStation: saleStation ?? this.saleStation,
      login: login ?? this.login,
      saleStations: saleStations ?? this.saleStations,
      companies: companies ?? this.companies,
      offices: offices ?? this.offices,
    );
  }
}
