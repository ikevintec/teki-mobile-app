import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:teki_app/src/providers/config/config.dart';
import 'dashboard_fixture.dart';

SesionState pedidosSession() {
  final s = dashboardSession(features: false);
  s.config!.igv = .18;
  s.config!.porcentajeRecargoPorItem = 0;
  s.config!.porcentajeRetencion = 0;
  return s;
}

/// Fixture explícito: cero red externa, datos ficticios y contrato HTTP verificable.
class PedidosAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final Map<String, dynamic> _operaciones = {};
  final Map<String, dynamic> _borradores = {};
  bool perderRespuesta = false;
  bool conPromocion = false;
  bool canastaIncompleta = false;
  int registros = 0;
  final List<Map<String, dynamic>> pedidosIniciales = [];
  Future<void> Function(RequestOptions)? antesListado;
  bool fallarListado = false;

  static final product = {
    'id': 1,
    'nombre': 'Arroz extra 1 kg',
    'codigo': 'ARR01',
    'tipoProducto': 'ARTICULO',
    'moneda': 'PEN',
    'igv': true,
    'tipoAfectacion': '10',
    'preciosPorPuntoVenta': false,
    'precioCompra': 4.0,
    'unidad': {
      'id': 1,
      'codigo': 'NIU',
      'abreviatura': 'UND',
      'descripcion': 'Unidad',
    },
    'preciosVenta': [
      {
        'id': 1,
        'tipoComercialId': 1,
        'tipoPrecio': 'POR_DEFECTO',
        'precio': 6.0,
      },
      {'id': 2, 'tipoComercialId': 2, 'tipoPrecio': 'MAYOREO', 'precio': 5.5},
    ],
  };
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? body,
    Future<void>? cancel,
  ) async {
    requests.add(o);
    dynamic result;
    final path = o.path;
    if (path == '/distribuidor/configuracion') {
      result = {'preciosComerciales': true, 'mayoreoManual': true};
    } else if (path == '/distribuidor/tipos-precio') {
      result = [
        {
          'id': 1,
          'nombre': 'Minorista',
          'categoria': 'POR_DEFECTO',
          'principal': true,
          'estado': true,
        },
        {
          'id': 2,
          'nombre': 'Mayorista',
          'categoria': 'MAYOREO',
          'estado': true,
        },
      ];
    } else if (path == '/distribuidor/precios/cabecera') {
      result = {'idTipoComercial': 1, 'origen': 'PRINCIPAL'};
    } else if (path == '/distribuidor/promociones/evaluar') {
      final req = Map<String, dynamic>.from(o.data);
      final cantidad = (req['items'] as List).fold<double>(
        0,
        (n, l) => n + (l['cantidad'] as num).toDouble(),
      );
      final alcanza = conPromocion && cantidad >= 2;
      final elegido = (req['selecciones'] as Map?)?['10'];
      result = {
        'aplicadas': [
          if (alcanza && elegido != null)
            {
              'idPromocion': 10,
              'nombre': 'Compra 2 y elige un regalo',
              'idProductoRegalo': elegido,
              'cantidadRegalo': 1,
              'explicacion': 'Por cada 2 unidades, un regalo a elección.',
            },
        ],
        'eleccionesPendientes': [
          if (alcanza && elegido == null)
            {
              'idPromocion': 10,
              'nombre': 'Compra 2 y elige un regalo',
              'cantidad': 1,
              'opciones': [2, 3],
            },
        ],
        'conflictos': [],
        'bloqueos': [],
        'noAplicadas': [],
        'regalos': {
          '2': {
            'nombre': 'Galletas de vainilla',
            'unidad': 'UND',
            'disponible': 50,
          },
          '3': {
            'nombre': 'Galletas de chocolate',
            'unidad': 'UND',
            'disponible': 25,
          },
        },
      };
    } else if (path == '/ticket-order/gestion/ultima-canasta') {
      result = [
        {'idProducto': 1, 'cantidad': 3},
      ];
    } else if (path == '/products') {
      result = {
        'content': canastaIncompleta ? [] : [product],
      };
    } else if (path == '/currencies') {
      result = [
        {'id': 1, 'codigoMoneda': 'PEN', 'tipoCambio': 1, 'descripcion': 'Sol'},
      ];
    } else if (path.startsWith('/series/office/')) {
      result = [
        {'numero': 'P001'},
      ];
    } else if (path == '/customers') {
      result = [
        {
          'id': 1,
          'razonSocial': 'Bodega Los Olivos',
          'numeroDocumento': '20000000001',
          'tipoDocumento': '6',
          'direccion': 'Av. Principal 123',
        },
      ];
    } else if (path == '/products/search') {
      result = [product];
    } else if (path == '/products/1') {
      result = product;
    } else if (path == '/products/2' || path == '/products/3') {
      result = {
        ...product,
        'id': int.parse(path.split('/').last),
        'nombre': path.endsWith('2')
            ? 'Galletas de vainilla'
            : 'Galletas de chocolate',
      };
    } else if (path.endsWith('/frecuentes')) {
      result = [
        {'idProducto': 1, 'nombre': 'Arroz extra 1 kg'},
      ];
    } else if (path == '/quotation') {
      await antesListado?.call(o);
      if (fallarListado) {
        throw DioException(
          requestOptions: o,
          response: Response(
            requestOptions: o,
            statusCode: 503,
            data: {'mensaje': 'Listado temporalmente no disponible'},
          ),
        );
      }
      final q = o.queryParameters;
      final lista =
          [...pedidosIniciales, ..._operaciones.values].where((p) {
            final cliente =
                '${p['denominacionReceptor']} ${p['numeroDocumentoReceptor']}'
                    .toLowerCase();
            final fecha = '${p['fechaEmision'] ?? ''}'.split('T').first;
            String iso(dynamic valor) => '$valor'.split('-').reversed.join('-');
            final enFecha =
                q['filtroDesde'] == null ||
                q['filtroHasta'] == null ||
                (fecha.compareTo(iso(q['filtroDesde'])) >= 0 &&
                    fecha.compareTo(iso(q['filtroHasta'])) <= 0);
            return enFecha &&
                (q['filtroRuc'] == null ||
                    cliente.contains('${q['filtroRuc']}'.toLowerCase())) &&
                (q['estadoCotizacion'] == null ||
                    p['estadoCotizacion'] == q['estadoCotizacion']) &&
                (q['filtroSerie'] == null ||
                    '${p['serie']}'.contains('${q['filtroSerie']}')) &&
                (q['filtroNumero'] == null || p['numero'] == q['filtroNumero']);
          }).toList()..sort(
            (a, b) =>
                (q['sortOrder'] == 1 ? 1 : -1) *
                (a['id'] as int).compareTo(b['id'] as int),
          );
      final pagina = (q['pageNumber'] as int? ?? 0);
      result = {'content': lista.skip(pagina * 20).take(20).toList()};
    } else if (path == '/ticket-order/gestion/borradores') {
      result = {'content': _borradores.values.toList()};
    } else if (path.startsWith('/ticket-order/gestion/borradores/')) {
      final m = Map<String, dynamic>.from(o.data);
      final id = path.split('/').last;
      result = {
        ...m,
        'id': id,
        'revision': (m['revision'] as int) + 1,
        'datos': jsonEncode(m['datos']),
      };
      _borradores[id] = result;
    } else if (path.startsWith('/ticket-order/gestion/operaciones/')) {
      final p = _operaciones[path.split('/').last];
      result = {
        'estado': p == null ? 'NO_REGISTRADO' : 'CONFIRMADO',
        if (p != null) 'pedido': p,
      };
    } else if (RegExp(r'^/ticket-order/gestion/\d+$').hasMatch(path)) {
      final id = int.parse(path.split('/').last);
      final actual = [
        ...pedidosIniciales,
        ..._operaciones.values,
      ].firstWhere((p) => p['id'] == id);
      if (o.method == 'PUT') {
        final req = Map<String, dynamic>.from(o.data);
        if (req['revision'] != actual['revisionPedido']) {
          return ResponseBody.fromString(
            '{"mensaje":"El pedido cambió"}',
            409,
            headers: {
              Headers.contentTypeHeader: [Headers.jsonContentType],
            },
          );
        }
        result = {
          ...actual,
          ...Map<String, dynamic>.from(req['pedido']),
          'id': id,
          'revisionPedido': (actual['revisionPedido'] as int) + 1,
          'puedeEditarPedido': true,
          'pedidoGestionado': true,
        };
        final clave = _operaciones.keys.firstWhere(
          (k) => _operaciones[k]['id'] == id,
        );
        _operaciones[clave] = result;
      } else {
        result = actual;
      }
    } else if (path == '/ticket-order/gestion' && o.method == 'POST') {
      final m = Map<String, dynamic>.from(o.data);
      if (!_operaciones.containsKey(m['clave'])) {
        registros++;
        _operaciones[m['clave']] = {
          ...m['pedido'],
          'id': registros,
          'numero': registros,
          'estadoPedido': 'ENVIADO',
          'pedidoGestionado': true,
          'revisionPedido': 1,
          'puedeEditarPedido': true,
        };
      }
      result = _operaciones[m['clave']];
      if (perderRespuesta) {
        perderRespuesta = false;
        throw DioException(
          requestOptions: o,
          type: DioExceptionType.receiveTimeout,
        );
      }
    } else {
      return ResponseBody.fromString(
        '{"mensaje":"Ruta no prevista en fixture"}',
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(result),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
