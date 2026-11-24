import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teki_app/src/data/services/distribuidor/comercial_service.dart';

/// Responde según la ruta y registra cada petición.
class _Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final Map<String, Object> respuestas;
  final Set<String> fallan;
  _Adapter(this.respuestas, {this.fallan = const {}});

  int llamadas(String ruta) => requests.where((r) => r.path == ruta).length;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final falla = fallan.contains(options.path);
    return ResponseBody.fromString(
      jsonEncode(falla ? {'mensaje': 'Error'} : respuestas[options.path] ?? {}),
      falla ? 500 : 200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _vigentes = '/distribuidor/promociones/productos-vigentes';
const _evaluar = '/distribuidor/promociones/evaluar';
const _config = '/distribuidor/configuracion';

Map<String, dynamic> _req(int sede, List<int> productos) => {
  'documento': 'VENTA',
  'idPuntoVenta': sede,
  'items': [
    for (final p in productos) {'ref': '$p', 'idProducto': p, 'cantidad': 1},
  ],
  'selecciones': <String, int>{},
  'excluyentesElegidas': <int>[],
};

void main() {
  late Dio dio;
  tearDown(() => dio.close(force: true));

  ComercialService servicio(_Adapter adapter) {
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com/api'))
      ..httpClientAdapter = adapter;
    return ComercialService(dio: dio);
  }

  test('sin productos en promoción no llama a evaluar', () async {
    final adapter = _Adapter({_vigentes: {}});
    final r = await servicio(adapter).evaluar(_req(101, [7]));
    expect(r['aplicadas'], isEmpty);
    expect(adapter.llamadas(_evaluar), 0);
  });

  test('evalúa si algún producto del carrito tiene promoción', () async {
    final adapter = _Adapter({
      _vigentes: {
        '7': ['2x1'],
      },
      _evaluar: {
        'aplicadas': [
          {'idPromocion': 1},
        ],
      },
    });
    final r = await servicio(adapter).evaluar(_req(102, [5, 7]));
    expect((r['aplicadas'] as List).length, 1);
    expect(adapter.llamadas(_evaluar), 1);
  });

  test(
    'reutiliza los productos con promoción durante la vigencia de la caché',
    () async {
      final adapter = _Adapter({_vigentes: {}});
      final s = servicio(adapter);
      await s.evaluar(_req(103, [1]));
      await s.evaluar(_req(103, [1, 2]));
      await s.productosConPromocion(103);
      expect(adapter.llamadas(_vigentes), 1);
    },
  );

  test(
    'si no se sabe qué productos tienen promoción, evalúa como antes',
    () async {
      final adapter = _Adapter(
        {
          _evaluar: {'aplicadas': []},
        },
        fallan: {_vigentes},
      );
      final s = servicio(adapter);
      await s.evaluar(_req(104, [1]));
      expect(adapter.llamadas(_evaluar), 1);
      // El fallo no se cachea: el siguiente intento vuelve a consultar.
      await s.evaluar(_req(104, [1]));
      expect(adapter.llamadas(_vigentes), 2);
    },
  );

  test('pedidos existentes o con elecciones se evalúan siempre', () async {
    final adapter = _Adapter({
      _vigentes: {},
      _evaluar: {'aplicadas': []},
    });
    final s = servicio(adapter);
    await s.evaluar({
      ..._req(105, [1]),
      'idCotizacion': 9,
    });
    await s.evaluar({
      ..._req(105, [1]),
      'excluyentesElegidas': [3],
    });
    expect(adapter.llamadas(_evaluar), 2);
    expect(adapter.llamadas(_vigentes), 0);
  });

  test(
    'usa la configuración de /companies/config sin consultar el endpoint',
    () async {
      final adapter = _Adapter({});
      final c = await servicio(
        adapter,
      ).cargar(1, config: {'preciosComerciales': false});
      expect(c.activo, isFalse);
      expect(adapter.llamadas(_config), 0);
    },
  );

  test('sin configuración en la sesión consulta el endpoint', () async {
    final adapter = _Adapter({
      _config: {'preciosComerciales': false},
    });
    final c = await servicio(adapter).cargar(1);
    expect(c.activo, isFalse);
    expect(adapter.llamadas(_config), 1);
  });
}
