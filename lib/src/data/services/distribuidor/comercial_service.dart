import 'package:dio/dio.dart';
import 'package:teki_app/src/domain/distribuidor/contexto_comercial.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

class ComercialService {
  final Dio dio;
  ComercialService({Dio? dio}) : dio = dio ?? ApiClient.dio;
  Future<ContextoComercial> cargar(int sede, {int? cliente}) async {
    Map<String, dynamic> cfg;
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

  Future<Map<String, dynamic>> evaluar(Map<String, dynamic> req) async =>
      Map<String, dynamic>.from(
        (await dio.post('/distribuidor/promociones/evaluar', data: req)).data,
      );

  /// Producto de compra → nombres de promociones vigentes en la sede.
  Future<Map<int, List<String>>> productosConPromocion(int? sede) async {
    final data = (await dio.get(
      '/distribuidor/promociones/productos-vigentes',
      queryParameters: {'idPuntoVenta': ?sede},
    )).data as Map;
    return {
      for (final e in data.entries)
        int.parse('${e.key}'): List<String>.from(e.value as List),
    };
  }
}
