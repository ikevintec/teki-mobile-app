import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:teki_app/src/data/services/distribuidor/pedidos_service.dart';
import 'package:teki_app/src/domain/distribuidor/filtros_pedidos.dart';
import '../support/pedidos_fixture.dart';

void main() {
  test(
    'serializa filtros de servidor sin perder sede, vendedor ni paginación',
    () async {
      final adapter = PedidosAdapter();
      final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid/api'))
        ..httpClientAdapter = adapter;
      await PedidosService('prueba', dio: dio).listar(
        10,
        20,
        pagina: 2,
        filtros: FiltrosPedidos(
          cliente: 'Bodega',
          estado: 'PENDIENTE',
          serie: 'PE01',
          numero: 123,
          desde: DateTime(2026, 11, 1),
          hasta: DateTime(2026, 11, 21),
          recientesPrimero: false,
        ),
      );
      expect(adapter.requests.single.queryParameters, {
        'esPedido': true,
        'idPuntoVenta': 10,
        'idVendedor': 20,
        'pageNumber': 2,
        'perPage': 20,
        'filtroRuc': 'Bodega',
        'estadoCotizacion': 'PENDIENTE',
        'filtroSerie': 'PE01',
        'filtroNumero': 123,
        'filtroDesde': '01-11-2026',
        'filtroHasta': '21-11-2026',
        'sortField': 'id',
        'sortOrder': 1,
      });
    },
  );
  test(
    'sin filtros conserva todos los pedidos y no agrega un rango implícito',
    () {
      expect(const FiltrosPedidos().cantidad, 0);
      expect(const FiltrosPedidos().parametros, {
        'sortField': 'id',
        'sortOrder': -1,
      });
    },
  );
}
