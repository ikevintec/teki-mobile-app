import 'package:dio/dio.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class ComercialService {
  final Dio dio;
  ComercialService({Dio? dio}) : dio = dio ?? ApiClient.dio;

  /// [config] es la configuración de distribuidor que llega en /companies/config (tras el login);
  /// solo se consulta el endpoint si no vino (sesión anterior o backend sin el campo).
  Future<ContextoComercial> cargar(
    int sede, {
    int? cliente,
    Map<String, dynamic>? config,
  }) async {
    Map<String, dynamic> cfg;
    if (config != null) {
      cfg = config;
    } else {
      try {
        cfg = Map<String, dynamic>.from(
          (await dio.get('/distribuidor/configuracion')).data,
        );
      } on DioException catch (e) {
        // Solo un backend anterior sin contrato permite el flujo tradicional por compatibilidad.
        if (e.response?.statusCode == 404) {
          return const ContextoComercial(promocionesDisponibles: false);
        }
        rethrow;
      }
    }
    if (cfg['preciosComerciales'] != true) return const ContextoComercial();
    final tipos = (await dio.get('/distribuidor/tipos-precio')).data as List;
    final cabecera =
        (await dio.get(
              '/distribuidor/precios/cabecera',
              queryParameters: {
                'idPuntoVenta': sede,
                if (cliente != null) 'idCliente': cliente,
              },
            )).data
            as Map;
    return ContextoComercial(
      activo: true,
      mayoreoManual: cfg['mayoreoManual'] == true,
      cabecera: (cabecera['idTipoComercial'] as num?)?.toInt(),
      tipos: tipos.map((e) => Map<String, dynamic>.from(e)).toList(),
    );
  }

  /// Evalúa en el backend solo si algún producto del carrito tiene promoción vigente en la sede.
  /// Pedidos/cotizaciones existentes o con elecciones hechas se evalúan siempre: pueden traer regalos.
  /// Si no se puede saber qué productos tienen promoción, evalúa como antes.
  Future<Map<String, dynamic>> evaluar(Map<String, dynamic> req) async {
    final siempre =
        req['idCotizacion'] != null ||
        (req['selecciones'] as Map?)?.isNotEmpty == true ||
        (req['excluyentesElegidas'] as List?)?.isNotEmpty == true;
    if (!siempre) {
      Map<int, List<String>>? vigentes;
      try {
        vigentes = await productosConPromocion(req['idPuntoVenta'] as int?);
      } catch (_) {
        vigentes = null;
      }
      final items = req['items'] as List? ?? const [];
      if (vigentes != null &&
          !items.any((i) => vigentes!.containsKey(i['idProducto']))) {
        return _sinPromociones();
      }
    }
    return Map<String, dynamic>.from(
      (await dio.post('/distribuidor/promociones/evaluar', data: req)).data,
    );
  }

  static Map<String, dynamic> _sinPromociones() => {
    'aplicadas': <dynamic>[],
    'noAplicadas': <dynamic>[],
    'conflictos': <dynamic>[],
    'eleccionesPendientes': <dynamic>[],
    'bloqueos': <dynamic>[],
    'nombresPromociones': <String, dynamic>{},
    'regalos': <String, dynamic>{},
  };

  // Caché corta por sede: el carrito cambia seguido y las promociones casi nunca.
  static const _vigenciaCache = Duration(seconds: 30);
  static final Map<
    int?,
    ({DateTime hasta, Future<Map<int, List<String>>> datos})
  >
  _cacheVigentes = {};

  /// Producto de compra → nombres de promociones vigentes en la sede (caché de 30 s).
  Future<Map<int, List<String>>> productosConPromocion(int? sede) {
    final guardado = _cacheVigentes[sede];
    if (guardado != null && DateTime.now().isBefore(guardado.hasta)) {
      return guardado.datos;
    }
    final datos = _consultarProductosConPromocion(sede);
    _cacheVigentes[sede] = (
      hasta: DateTime.now().add(_vigenciaCache),
      datos: datos,
    );
    // Un fallo no se cachea: el siguiente intento vuelve a consultar.
    datos.catchError((Object _) {
      if (identical(_cacheVigentes[sede]?.datos, datos)) {
        _cacheVigentes.remove(sede);
      }
      return const <int, List<String>>{};
    });
    return datos;
  }

  Future<Map<int, List<String>>> _consultarProductosConPromocion(
    int? sede,
  ) async {
    final data =
        (await dio.get(
              '/distribuidor/promociones/productos-vigentes',
              queryParameters: {'idPuntoVenta': ?sede},
            )).data
            as Map;
    return {
      for (final e in data.entries)
        int.parse('${e.key}'): List<String>.from(e.value as List),
    };
  }
}
