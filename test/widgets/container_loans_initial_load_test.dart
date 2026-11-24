import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
// ignore: implementation_imports
import 'package:google_fonts/src/google_fonts_base.dart' as fonts;
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/container_loan.dart';
import 'package:teki_app/src/domain/repositories/auth_repository.dart';
import 'package:teki_app/src/domain/repositories/config_repository.dart';
import 'package:teki_app/src/domain/repositories/container_loan_repository.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/shared/services/key_values_storage_impl.dart';
import 'package:teki_app/src/providers/auth/login.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/container_loans/container_loans_provider.dart';
import 'package:teki_app/src/presentation/screens/container_loans/container_loans_main_screen.dart';
import '../support/envase_sale_fixture.dart';

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _AuthRepository implements AuthRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _ConfigRepository implements ConfigRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Storage implements KeyValueStorageServiceImpl {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends SesionNotifier {
  _Session() : super(saleStationRepository: _Stations()) {
    state = testSesion.copyWith(roles: ['SUPER_USUARIO']);
  }
}

class _Auth extends AuthStateNotifier {
  final Completer<ConfigCompany?> ready;
  _Auth(Ref ref, this.ready)
    : super(
        ref: ref,
        authRepository: _AuthRepository(),
        saleStationRepository: _Stations(),
        configRepository: _ConfigRepository(),
        keyvalueStorage: _Storage(),
      );
  @override
  Future<ConfigCompany?> refreshConfigCompany() => ready.future;
}

class _Repository implements ContainerLoanRepository {
  final response = Completer<(List<ContainerLoan>, int)>();
  int calls = 0;
  @override
  Future<(List<ContainerLoan>, int)> getLoans({
    int? customerId,
    int? officeId,
    required bool pending,
    required int page,
    required int size,
  }) {
    calls++;
    return response.future;
  }

  @override
  Future<List<ContainerLoanTotal>> getTotals({
    int? customerId,
    int? officeId,
  }) async => [];
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Manifest implements AssetManifest {
  @override
  List<String> listAssets() => [];
  @override
  List<AssetMetadata>? getAssetVariants(String key) => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    fonts.assetManifest = _Manifest();
    final data = await rootBundle.load(
      'packages/cupertino_icons/assets/CupertinoIcons.ttf',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async => data);
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
    fonts.assetManifest = null;
  });
  testWidgets(
    'al abrir conserva y muestra la consulta inicial sin cambiar filtros',
    (tester) async {
      final ready = Completer<ConfigCompany?>();
      final repo = _Repository();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sesionProvider.overrideWith((ref) => _Session()),
            authStateProvider.overrideWith((ref) => _Auth(ref, ready)),
            containerLoanRepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(home: ContainerLoansMainScreen()),
        ),
      );
      ready.complete(testSesion.config);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      repo.response.complete((
        [
          const ContainerLoan(
            id: 10,
            customer: 'Cliente prueba',
            container: 'Bidón vacío',
            pendingQuantity: 2,
          ),
        ],
        1,
      ));
      await tester.pumpAndSettle();
      expect(repo.calls, 1);
      expect(find.text('Cliente prueba'), findsOneWidget);
      expect(find.text('Sin envases pendientes'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
