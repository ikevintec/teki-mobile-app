import 'package:teki_app/src/providers/sale/products/helpers/ticket_detail_helper.dart';
import '../../support/envase_sale_fixture.dart' show testSesion;
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/models/teki_model/product.dart';
import 'package:teki_app/src/data/models/teki_model/product_price.dart';
import 'package:teki_app/src/data/models/teki_model/office.dart';
import 'package:teki_app/src/data/models/teki_model/quotation.dart';
import 'package:teki_app/src/utils/distribuidor/precios_comerciales.dart';

void main() {
  final tipos = <Map<String, dynamic>>[
    {
      'id': 1,
      'estado': true,
      'categoria': 'POR_DEFECTO',
      'principal': true,
      'nombre': 'Minorista',
    },
    {'id': 2, 'estado': true, 'categoria': 'MAYOREO', 'nombre': 'Mayorista'},
    {
      'id': 3,
      'estado': true,
      'categoria': 'ESPECIAL',
      'nombre': 'Guadalupe',
      'idPuntoVenta': 2,
    },
  ];
  final producto = Product(
    id: 10,
    preciosVenta: [
      ProductPrice(id: 1, tipoComercialId: 1, precio: 30),
      ProductPrice(id: 2, tipoComercialId: 2, precio: 27, unidadesMayoreo: 12),
      ProductPrice(
        id: 3,
        tipoComercialId: 2,
        precio: 26,
        puntoVenta: Office(id: 1),
        unidadesMayoreo: 12,
      ),
      ProductPrice(
        id: 4,
        tipoComercialId: 3,
        precio: 20,
        puntoVenta: Office(id: 2),
      ),
    ],
  );
  test('mayoreo manual no exige cantidad y prioriza sede sobre compartido', () {
    final r = resolverPrecioComercial(producto, tipos, 1, 2, 1, true);
    expect(r.precio?.id, 3);
    expect(r.atribucion['tipoComercialId'], 2);
    expect(
      resolverPrecioComercial(producto, tipos, 2, 2, 1, true).precio?.id,
      2,
    );
  });
  test('otro punto de venta queda excluido y no se inventa un importe', () {
    expect(
      resolverPrecioComercial(producto, tipos, 1, 3, 1, true).precio?.id,
      1,
    );
    final sinMayorista = Product(
      id: 11,
      preciosVenta: [ProductPrice(id: 5, tipoComercialId: 1, precio: 30)],
    );
    expect(
      resolverPrecioComercial(sinMayorista, tipos, 1, 2, 1, true).aviso,
      contains('Minorista'),
    );
    final vacio = resolverPrecioComercial(
      Product(id: 12),
      tipos,
      1,
      2,
      1,
      true,
    );
    expect(vacio.precio, isNull);
    expect(vacio.atribucion['origenPrecio'], 'MANUAL');
    expect(vacio.atribucion['tipoComercialCategoria'], 'POR_DEFECTO');
  });
  test('la modalidad automática conserva la escala por cantidad', () {
    expect(
      resolverPrecioComercial(producto, tipos, 1, 1, 1, false).precio?.id,
      1,
    );
    expect(
      resolverPrecioComercial(producto, tipos, 1, 1, 12, false).precio?.precio,
      26,
    );
    expect(
      resolverPrecioComercial(producto, tipos, 1, 1, 12, true).precio?.id,
      1,
    );
  });
  test(
    'cambiar cantidad vuelve del mayoreo automático sin adoptar otra cabecera posterior',
    () {
      final sesion = testSesion.copyWith(
        distribuidor: {
          'preciosComerciales': true,
          'mayoreoManual': false,
          'tipos': tipos,
          'tipoPrecioCabeceraId': 1,
        },
      );
      var linea = getTicketDetail(
        product: producto.copyWith(igv: true),
        sesion: sesion,
        quantity: 1,
      );
      linea = changeQtyTicketDetail(
        ticketDetail: linea,
        quantity: 12,
        sesion: sesion,
      );
      expect(linea.precioVentaUnitario, 26);
      final otroDefault = sesion.copyWith(
        distribuidor: {...sesion.distribuidor, 'tipoPrecioCabeceraId': 3},
      );
      linea = changeQtyTicketDetail(
        ticketDetail: linea,
        quantity: 1,
        sesion: otroDefault,
      );
      expect(linea.precioVentaUnitario, closeTo(30, 1e-8));
      expect(linea.comercial['tipoComercialId'], 1);
      expect(linea.toJson().containsKey('tipoPrecioInicialId'), false);
    },
  );

  test(
    'pedido conserva vendedor, cabecera y detalle original al editar y convertir',
    () {
      final q = Quotation.fromJson({
        'id': 20,
        'isQuotation': false,
        'tipoPrecioCabeceraId': 2,
        'vendedor': {'id': 7},
        'items': [
          {
            'id': 31,
            'cantidad': 2,
            'precioVentaUnitario': 26,
            'tipoComercialId': 2,
            'tipoComercialCategoria': 'MAYOREO',
            'productoPrecioId': 3,
            'proveedorDefectoId': 5,
            'producto': {'id': 10},
          },
        ],
      });
      final venta = q.toTicketForSale();
      expect(q.toTicketForEdit().tipoComprobante, 'PE');
      expect(venta.vendedor?.id, 7);
      expect(venta.toJson()['tipoPrecioCabeceraId'], 2);
      final d = venta.items!.single;
      expect(d.id, isNull);
      expect(d.toJson()['detalleOrigenId'], 31);
      expect(d.toJson()['origenPrecio'], 'PACTADO');
      expect(d.toJson()['productoPrecioId'], 3);
      expect(d.copyWith(cantidad: 3).toJson()['tipoComercialId'], 2);
    },
  );
}
