import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/response/login.dart';
import 'package:teki_app/src/data/models/teki_model/company_summary.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/loyalty_card.dart';
import 'package:teki_app/src/data/models/teki_model/user.dart';
import 'package:teki_app/src/domain/repositories/loyalty_repository.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/providers/config/config.dart';

const demoCard = LoyaltyCard(
  id: 1,
  nombre: 'Recargas de prueba',
  slug: 'programa-demo',
  activo: true,
  principal: true,
  permitirSellos: true,
  textoRecompensa: 'Beneficio configurado para esta tarjeta',
);
const secondCard = LoyaltyCard(
  id: 2,
  nombre: 'Puntos de prueba',
  slug: 'puntos-demo',
  activo: true,
  permitirPuntos: true,
);

SesionState loyaltySession({
  bool enabled = true,
  bool containers = false,
  List<String> roles = const ['LOYALTI_CONFIG_VER'],
  int companyId = 1,
}) {
  final company = Companysummary(
    id: companyId,
    nombreComercial: 'Negocio de demostración',
  );
  return SesionState(
    login: LoginResponse(
      accessToken: 'synthetic-token-$companyId',
      user: User(id: 1, empresa: company),
    ),
    company: company,
    companySelected: company,
    roles: roles,
    config: ConfigCompany(
      permitirFidelizacion: enabled,
      permitirRetornoEnvase: containers,
    ),
  );
}

class LoyaltySessionNotifier extends SesionNotifier {
  LoyaltySessionNotifier(SesionState value)
    : super(saleStationRepository: _Stations()) {
    state = value;
  }
  void replace(SesionState value) {
    state = value;
  }
}

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DemoLoyaltyRepository implements LoyaltyRepository {
  List<LoyaltyCard> cards;
  Object? failure;
  int listCalls = 0;
  final detailCalls = <int>[];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  DemoLoyaltyRepository({this.cards = const [demoCard, secondCard]});

  @override
  Future<List<LoyaltyCard>> getCards({CancelToken? cancelToken}) async {
    listCalls++;
    if (failure != null) throw failure!;
    return cards;
  }

  @override
  Future<LoyaltyCard> getCard(int id, {CancelToken? cancelToken}) async {
    detailCalls.add(id);
    if (failure != null) throw failure!;
    return cards.firstWhere((c) => c.id == id);
  }
}
