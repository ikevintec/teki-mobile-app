import 'package:teki_app/src/domain/distribuidor/filtros_pedidos.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';

/// Estado incierto persistido por identidad de sesión. No hay cola offline ni envío automático.
class PedidosService {
  final Dio dio;
  final String contexto;
  final bool Function()? sigueEnContexto;
  static final Set<String> _enviando = {};
  PedidosService(this.contexto, {Dio? dio, this.sigueEnContexto})
    : dio = dio ?? ApiClient.dio;
  void _validarContexto() {
    if (sigueEnContexto?.call() == false) {
      throw StateError('La sesión cambió. Abre el pedido en la sede original.');
    }
  }

  String get _key => 'pedido_operacion_$contexto';
  Future<List<Map<String, dynamic>>> listar(
    int sede,
    int usuario, {
    int pagina = 0,
    FiltrosPedidos filtros = const FiltrosPedidos(),
  }) async {
    final r = await dio.get(
      '/quotation',
      queryParameters: {
        'esPedido': true,
        'pageNumber': pagina,
        'perPage': 20,
        'idPuntoVenta': sede,
        'idVendedor': usuario,
        ...filtros.parametros,
      },
    );
    return (r.data['content'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> obtener(int id) async =>
      Map<String, dynamic>.from(
        (await dio.get('/ticket-order/gestion/$id')).data,
      );
  Future<List<Map<String, dynamic>>> borradores({
    int? sede,
    int pagina = 0,
  }) async {
    final r = await dio.get(
      '/ticket-order/gestion/borradores',
      queryParameters: {
        if (sede != null) 'idPuntoVenta': sede,
        'pagina': pagina,
      },
    );
    return (r.data['content'] as List)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Future<Map<String, dynamic>> guardarBorrador(
    String id,
    int revision,
    int sede,
    Map<String, dynamic> datos,
    String nombre,
  ) async => Map<String, dynamic>.from(
    (await dio.put(
      '/ticket-order/gestion/borradores/$id',
      data: {
        'revision': revision,
        'idPuntoVenta': sede,
        'datos': datos,
        'nombre': nombre,
      },
    )).data,
  );
  Future<void> eliminarBorrador(String id, int revision, int sede) async {
    _validarContexto();
    await dio.delete(
      '/ticket-order/gestion/borradores/$id',
      queryParameters: {'revision': revision, 'idPuntoVenta': sede},
    );
    _validarContexto();
  }

  Future<bool> get hayPendiente async =>
      (await SharedPreferences.getInstance()).containsKey(_key);
  Future<Map<String, dynamic>?> pendiente() async {
    final raw = (await SharedPreferences.getInstance()).getString(_key);
    return raw == null ? null : Map<String, dynamic>.from(jsonDecode(raw));
  }

  Future<Map<String, dynamic>> enviar(
    Map<String, dynamic> comando, {
    int? id,
  }) async {
    _validarContexto();
    if (!_enviando.add(contexto)) {
      throw StateError('El pedido se está enviando.');
    }
    try {
      if (await hayPendiente) {
        throw StateError(
          'Verifica el envío pendiente antes de registrar otro pedido.',
        );
      }
      final prefs = await SharedPreferences.getInstance();
      _validarContexto();
      final op = {'id': id, 'comando': comando};
      if (!await prefs.setString(_key, jsonEncode(op))) {
        throw StateError(
          'No se pudo conservar la identidad del envío. Reintenta.',
        );
      }
      _validarContexto();
      return await _transmitir(op);
    } finally {
      _enviando.remove(contexto);
    }
  }

  Future<Map<String, dynamic>> _transmitir(Map<String, dynamic> op) async {
    try {
      _validarContexto();
      final id = op['id'];
      final r = await dio.request(
        '/ticket-order/gestion${id == null ? '' : '/$id'}',
        data: op['comando'],
        options: Options(method: id == null ? 'POST' : 'PUT'),
      );
      await (await SharedPreferences.getInstance()).remove(_key);
      return Map<String, dynamic>.from(r.data);
    } on DioException catch (e) {
      // Un 4xx inequívoco no registró el comando. Errores de transporte/5xx conservan identidad y contenido.
      if (e.response != null &&
          e.response!.statusCode! >= 400 &&
          e.response!.statusCode! < 500) {
        await (await SharedPreferences.getInstance()).remove(_key);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> verificarYReintentar() async {
    final op = await pendiente();
    _validarContexto();
    if (op == null) return null;
    final r = await dio.get(
      '/ticket-order/gestion/operaciones/${op['comando']['clave']}',
    );
    if (r.data['estado'] == 'CONFIRMADO') {
      await (await SharedPreferences.getInstance()).remove(_key);
      return Map<String, dynamic>.from(r.data['pedido']);
    }
    if (r.data['estado'] == 'NO_REGISTRADO') return _transmitir(op);
    throw StateError('El pedido sigue procesándose. Vuelve a verificar.');
  }
}
