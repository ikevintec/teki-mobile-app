import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'pedidos_fixture.dart';

/// Escenario QA aislado: ocho productos y dos bonificaciones distintas.
class PedidosVariosAdapter extends PedidosAdapter {
  static final nombres = [
    'Arroz extra 1 kg',
    'Aceite vegetal botella 1 litro',
    'Azúcar rubia bolsa 1 kg',
    'Leche evaporada lata 400 g',
    'Atún en conserva presentación familiar con descripción extensa',
    'Fideos tallarín 500 g',
    'Detergente bolsa 800 g',
    'Agua mineral 2.5 litros',
  ];
  static final cantidades = [3, 2, 4, 6, 2, 5, 1, 3];
  static final precios = [6.0, 12.5, 4.8, 4.2, 8.9, 3.6, 9.5, 3.0];
  static final catalogo = [
    for (var i = 0; i < nombres.length; i++)
      {
        ...PedidosAdapter.product,
        'id': 10 + i,
        'nombre': nombres[i],
        'codigo': 'QA${10 + i}',
        'preciosVenta': [
          {
            'id': 100 + i,
            'tipoComercialId': 1,
            'tipoPrecio': 'POR_DEFECTO',
            'precio': precios[i],
          },
          {
            'id': 200 + i,
            'tipoComercialId': 2,
            'tipoPrecio': 'MAYOREO',
            'precio': precios[i] - .5,
          },
        ],
      },
    {
      ...PedidosAdapter.product,
      'id': 90,
      'nombre': 'Galletas de vainilla de regalo',
    },
    {...PedidosAdapter.product, 'id': 91, 'nombre': 'Jabón de regalo'},
  ];

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    dynamic data;
    if (o.path == '/ticket-order/gestion/ultima-canasta') {
      data = [
        for (var i = 0; i < nombres.length; i++)
          {'idProducto': 10 + i, 'cantidad': cantidades[i]},
      ];
    } else if (o.path == '/products') {
      data = {'content': catalogo.take(8).toList()};
    } else if (o.path == '/products/search') {
      data = catalogo.take(8).toList();
    } else if (RegExp(r'^/products/\d+$').hasMatch(o.path)) {
      final id = int.parse(o.path.split('/').last);
      data = catalogo.firstWhere((p) => p['id'] == id);
    } else if (o.path == '/distribuidor/promociones/evaluar') {
      final items = o.data['items'] as List;
      final activo = items.length >= 2;
      final elegido = (o.data['selecciones'] as Map?)?['10'];
      data = {
        'aplicadas': [
          if (activo)
            {
              'idPromocion': 11,
              'nombre': 'Canasta: jabón gratis',
              'idProductoRegalo': 91,
              'cantidadRegalo': 2,
              'explicacion': 'Dos jabones por la canasta.',
            },
          if (activo && elegido != null)
            {
              'idPromocion': 10,
              'nombre': 'Canasta: elige galletas',
              'idProductoRegalo': elegido,
              'cantidadRegalo': 1,
              'explicacion': 'Un regalo a elección.',
            },
        ],
        'eleccionesPendientes': [
          if (activo && elegido == null)
            {
              'idPromocion': 10,
              'nombre': 'Canasta: elige galletas',
              'cantidad': 1,
              'opciones': [90],
            },
        ],
        'conflictos': [],
        'bloqueos': [],
        'noAplicadas': [],
        'regalos': {
          '90': {
            'nombre': 'Galletas de vainilla de regalo',
            'unidad': 'UND',
            'disponible': 50,
          },
          '91': {
            'nombre': 'Jabón de regalo',
            'unidad': 'UND',
            'disponible': 50,
          },
        },
      };
    } else {
      return super.fetch(o, body, cancel);
    }
    requests.add(o);
    return ResponseBody.fromString(
      jsonEncode(data),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
