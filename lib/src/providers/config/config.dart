import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/sale_station.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/data/repositories/sale_station_repository_impl.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/utils/notifications.dart';

final sesionProvider = StateNotifierProvider<SesionNotifier, SesionState>((
  ref,
) {
  final SaleStationRepository saleStationRepository =
      SaleStationRepositoryImpl();
  return SesionNotifier(saleStationRepository: saleStationRepository);
});

class SesionNotifier extends StateNotifier<SesionState> {
  final SaleStationRepository saleStationRepository;
  SesionNotifier({required this.saleStationRepository})
    : super(
        SesionState(
          company: Companysummary(),
          companySelected: Companysummary(),
          office: Office(),
          roles: [],
          saleStation: SaleStation(),
          login: LoginResponse(),
          saleStations: [],
          companies: [],
          offices: [],
        ),
      );

  String? _contextoDistribuidor;
  int _peticionCabecera = 0;
  Future<void> cargarDistribuidor() async {
    final contexto = '${state.company?.id}:${state.office?.id}';
    if (_contextoDistribuidor == contexto) return;
    _contextoDistribuidor = contexto;
    state = state.copyWith(distribuidor: {});
    try {
      final config = Map<String, dynamic>.from(
        (await ApiClient.dio.get('/distribuidor/configuracion')).data,
      );
      if (_contextoDistribuidor != contexto) return;
      var tipos = <Map<String, dynamic>>[];
      if (config['preciosComerciales'] == true) {
        tipos =
            ((await ApiClient.dio.get('/distribuidor/tipos-precio')).data
                    as List)
                .map((t) => Map<String, dynamic>.from(t))
                .toList();
      }
      if (_contextoDistribuidor != contexto) return;
      state = state.copyWith(distribuidor: {...config, 'tipos': tipos});
      await recordarCabeceraCliente(null);
    } catch (_) {
      if (_contextoDistribuidor == contexto) {
        state = state.copyWith(distribuidor: {});
      }
      _contextoDistribuidor =
          null; // Un fallo se puede reintentar, no se almacena como configuración válida.
    }
  }

  Future<void> recordarCabeceraCliente(int? cliente) async {
    if (state.distribuidor['preciosComerciales'] != true ||
        state.office?.id == null) {
      return;
    }
    final numero = ++_peticionCabecera, contexto = _contextoDistribuidor;
    final r = await ApiClient.dio.get(
      '/distribuidor/precios/cabecera',
      queryParameters: {
        'idPuntoVenta': state.office!.id,
        if (cliente != null) 'idCliente': cliente,
      },
    );
    if (numero == _peticionCabecera && contexto == _contextoDistribuidor) {
      state = state.copyWith(
        distribuidor: {
          ...state.distribuidor,
          'tipoPrecioCabeceraId': r.data['idTipoComercial'],
        },
      );
    }
  }

  void elegirTipoComercial(int? tipo) {
    _peticionCabecera++;
    state = state.copyWith(
      distribuidor: {...state.distribuidor, 'tipoPrecioCabeceraId': tipo},
    );
  }

  List<SaleStation> _applyEstacionFilter(List<SaleStation> saleStations) {
    final estacionAsignada = state.login.user?.estacionVenta;
    if (estacionAsignada == null) return saleStations;
    final filtered = saleStations
        .where((se) => se.id == estacionAsignada.id)
        .toList();
    return filtered.isNotEmpty
        ? filtered
        : [SaleStation(id: -1, nombre: 'Estación no asignada')];
  }

  void setFullConfig(
    LoginResponse login,
    List<SaleStation> saleStations,
    Office? defaultPv,
  ) async {
    Office? oficinaEncontrada =
        defaultPv ??
        login.user?.puntosVenta?.firstWhere(
          (office) => office.rucAsignado == login.user?.rucAsignado,
          orElse: () => login.user?.puntosVenta?[0] ?? Office(),
        );

    final estacionAsignada = login.user?.estacionVenta;
    final List<SaleStation> filteredStations;
    if (estacionAsignada != null) {
      final matched = saleStations
          .where((se) => se.id == estacionAsignada.id)
          .toList();
      filteredStations = matched.isNotEmpty ? matched : saleStations;
    } else {
      filteredStations = saleStations;
    }

    final selectedSaleStation = filteredStations.isNotEmpty
        ? filteredStations.first
        : SaleStation();

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
        ...?login.user?.empresasAdjuntas,
      ],
      offices: login.user?.puntosVenta,
    );
  }

  void changeCompany(Companysummary company) async {
    Office? oficinaEncontrada = state.offices?.firstWhere(
      (office) => office.rucAsignado == company.ruc,
      orElse: () => Office(),
    );
    state = state.copyWith(companySelected: company);
    if (oficinaEncontrada?.rucAsignado != null) {
      changeOffice(oficinaEncontrada!, false);
    }
  }

  void changeOffice(Office office, bool changeCompany) async {
    List<SaleStation> saleStations = [];
    try {
      saleStations = await saleStationRepository.getSaleStations(
        office.id ?? 0,
      );
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
        state = state.copyWith(companySelected: company);
      }
    }
  }

  void changeSaleStation(SaleStation saleStation) {
    state = state.copyWith(saleStation: saleStation);
  }

  void setConfigCompany(ConfigCompany configCompany) {
    state = state.copyWith(config: configCompany);
  }

  void setRoles(List<String> roles) {
    state = state.copyWith(roles: roles);
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
  final Map<String, dynamic> distribuidor;

  /// True si el usuario tiene el permiso/rol indicado (p. ej. 'CAJA_VER',
  /// 'CAJA_INGRESO_EGRESO_CREAR'). Mismos códigos que los @PreAuthorize
  /// del backend y el hasPermission de la web.
  bool hasPermission(String permission) => roles?.contains(permission) ?? false;

  SesionState({
    this.distribuidor = const {},
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
    Map<String, dynamic>? distribuidor,
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
      distribuidor: distribuidor ?? this.distribuidor,
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
