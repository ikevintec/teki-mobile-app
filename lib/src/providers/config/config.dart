import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/companySummary.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/saleStation.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/repositories/sale_station_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repositoy.dart';
import 'package:teki_app/src/utils/notifications.dart';

final sesionProvider = StateNotifierProvider<SesionNotifier, SesionState>((ref) {
  final SaleStationRepository saleStationRepository = SaleStationRepositoryImpl();
  return SesionNotifier(
    saleStationRepository: saleStationRepository,
  );
});

class SesionNotifier extends StateNotifier<SesionState> {
  final SaleStationRepository saleStationRepository;
  SesionNotifier({
   required this.saleStationRepository, 
  })
      : super(SesionState(
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

  List<SaleStation> _applyEstacionFilter(List<SaleStation> saleStations) {
    final estacionAsignada = state.login.user?.estacionVenta;
    if (estacionAsignada == null) return saleStations;
    final filtered = saleStations.where((se) => se.id == estacionAsignada.id).toList();
    return filtered;
  }

  void setFullConfig(LoginResponse login, List<SaleStation> saleStations, Office? defaultPv) async {
    
    Office? oficinaEncontrada = defaultPv ?? login.user?.puntosVenta?.firstWhere(
      (office) => office.rucAsignado == login.user?.rucAsignado,
      orElse: () => login.user?.puntosVenta?[0] ?? Office(),
    );

    final estacionAsignada = login.user?.estacionVenta;
    final List<SaleStation> filteredStations;
    if (estacionAsignada != null) {
      final matched = saleStations.where((se) => se.id == estacionAsignada.id).toList();
      filteredStations = matched.isNotEmpty ? matched : saleStations;
    } else {
      filteredStations = saleStations;
    }

    final selectedSaleStation = filteredStations.isNotEmpty ? filteredStations.first : SaleStation();

    state = state.copyWith(
      company: login.user?.empresa,
      companySelected: login.user?.empresa,
      office: oficinaEncontrada,
      roles: login.roles ?? [],
      saleStation: selectedSaleStation,
      saleStations: filteredStations,
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
      companySelected: company,
    );
    if (oficinaEncontrada?.rucAsignado != null) {
      changeOffice(oficinaEncontrada!, false);
    }
  }

  void changeOffice(Office office, bool changeCompany) async{
    List<SaleStation> saleStations = [];
    try {
      saleStations = await saleStationRepository.getSaleStations(office.id ?? 0);
    } catch (e) {
      errorNotification(e.toString());
    }
    final filtered = _applyEstacionFilter(saleStations);
    state = state.copyWith(
      office: office,
      saleStation: filtered.isNotEmpty ? filtered.first : SaleStation(),
      saleStations: filtered,
    );

    if (changeCompany) {
      Companysummary? company = state.companies?.firstWhere(
        (company) => company.ruc == office.rucAsignado,
        orElse: () => Companysummary(),
      );
      if (company?.ruc != null) {
        state = state.copyWith(
          companySelected: company,
        );
      }
    }
  }
  void changeSaleStation(SaleStation saleStation) {
    state = state.copyWith(
      saleStation: saleStation,
    );
  }
  void setConfigCompany(ConfigCompany configCompany) {
    state = state.copyWith(
      config: configCompany,
    );
  }
  void set(User user) {
    state = state.copyWith(
      saleStation: SaleStation(),
      login: LoginResponse(
        accessToken: state.login.accessToken,
        tokenType: state.login.tokenType,
        user: user,
        roles: state.login.roles,
      ),
    );
  }

}

class SesionState {
  final Companysummary? company;
  final Companysummary? companySelected;
  final List<Companysummary>? companies;
  final Office? office;
  final List<String>? roles;
  final SaleStation? saleStation;
  final List<SaleStation>? saleStations;
  final List<Office>? offices;
  final LoginResponse login;
  final ConfigCompany? config;

  SesionState({
    required this.login,
    this.company,
    this.companySelected,
    this.office,
    this.roles,
    this.saleStation,
    this.saleStations,
    this.companies,
    this.offices,
    this.config,
  });
  SesionState copyWith({
    Companysummary? company,
    Companysummary? companySelected,
    Office? office,
    List<String>? roles,
    List<SaleStation>? saleStations,
    SaleStation? saleStation,
    LoginResponse? login,
    List<Companysummary>? companies,
    List<Office>? offices,
    ConfigCompany? config,
  }) {
    return SesionState(
      company: company ?? this.company,
      companySelected: companySelected ?? this.companySelected,
      office: office ?? this.office,
      roles: roles ?? this.roles,
      saleStation: saleStation ?? this.saleStation,
      login: login ?? this.login,
      saleStations: saleStations ?? this.saleStations,
      companies: companies ?? this.companies,
      offices: offices ?? this.offices,
      config: config ?? this.config,
    );
  }
}
