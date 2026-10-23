import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reactive_forms/reactive_forms.dart';
import 'package:teki_app/src/data/models/teki_model/config.dart';
import 'package:teki_app/src/data/models/teki_model/customer.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/ticket.dart';
import 'package:teki_app/src/domain/repositories/sale_station_repository.dart';
import 'package:teki_app/src/presentation/screens/sale/products/widgets/product_item_card.dart';
import 'package:teki_app/src/presentation/screens/container_loans/container_loans_main_screen.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'package:teki_app/src/providers/sale/sale_provider.dart';
import 'package:teki_app/src/providers/sale/products/products_sales_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_provider.dart';
import 'package:teki_app/src/providers/sale/customer/customer_sale_state.dart';
import '../support/envase_sale_fixture.dart';

class _Stations implements SaleStationRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Session extends SesionNotifier {
  _Session(SesionState value) : super(saleStationRepository: _Stations()) {
    state = value;
  }
}

class _Sale extends StateNotifier<TicketProvider> implements TicketNotifier {
  _Sale(SaleMode mode)
    : super(
        TicketProvider(
          ticket: Ticket(tipoComprobante: 'NV'),
          mode: mode,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Products extends StateNotifier<ProductsSaleState>
    implements ProductsSaleNotifier {
  _Products(super.state);
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Customer extends StateNotifier<CustomerSaleState>
    implements CustomerSaleNotifier {
  _Customer()
    : super(
        CustomerSaleState(
          customer: Customer(id: 9, numeroDocumento: '12345678'),
          customers: [],
          selectedCustomer: null,
          isLoading: false,
          error: null,
          pageNumber: 0,
          perPage: 20,
          filterGlobal: '',
          totalElements: null,
          paginacion: false,
        ),
      );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  for (final enabled in [false, true]) {
    for (final configuration in [0, 1, 2]) {
      final configured = configuration != 0;
      final linked = configuration != 2;
      for (final quotation in [false, true]) {
        testWidgets(
          'interfaz: retorno=$enabled producto=$configured vinculado=$linked cotización=$quotation',
          (tester) async {
            final session = testSesion.copyWith(
              roles: ['SUPER_USUARIO'],
              config: ConfigCompany(
                permitirRetornoEnvase: enabled,
                inventario: true,
                igv: .18,
              ),
            );
            final line = testLine().copyWith(
              producto: product.copyWith(
                nombre: 'Producto de prueba',
                envaseRetornable: configured,
                productoEnvase: linked ? product.productoEnvase : Product(),
              ),
            );
            final form = FormGroup({
              'price': FormControl<double>(value: 11),
              'description': FormControl<String>(value: 'Producto de prueba'),
              'quantity': FormControl<double>(value: 1),
            });
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  sesionProvider.overrideWith((ref) => _Session(session)),
                  ticketProvider.overrideWith(
                    (ref) => _Sale(
                      quotation
                          ? SaleMode.createCotizacion
                          : SaleMode.createVenta,
                    ),
                  ),
                  productSaleProvider.overrideWith(
                    (ref) => _Products(initial(line)),
                  ),
                  customerSaleProvider.overrideWith((ref) => _Customer()),
                ],
                child: MaterialApp(
                  home: Scaffold(
                    body: ProductItemCard(
                      productTicketDetail: line,
                      index: 0,
                      formGroup: form,
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle(const Duration(seconds: 2));
            final visible = enabled && configured && linked && !quotation;
            expect(
              find.textContaining('Envase:'),
              visible ? findsOneWidget : findsNothing,
            );
            expect(
              find.text('Ver pendientes'),
              visible ? findsOneWidget : findsNothing,
            );
            expect(
              find.textContaining('El precio incluye el envase.'),
              visible ? findsOneWidget : findsNothing,
            );
            expect(ContainerLoansMainScreen.isAvailable(session), enabled);
            expect(tester.takeException(), isNull);
            await tester.pumpWidget(const SizedBox());
            form.dispose();
          },
        );
      }
    }
  }
}
