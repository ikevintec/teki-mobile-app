import 'package:dio/dio.dart';
import 'package:teki_app/src/data/models/teki_model/check.dart';
import 'package:teki_app/src/data/models/teki_model/command.dart';
import 'package:teki_app/src/data/models/teki_model/lounge.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant.dart';
import 'package:teki_app/src/data/models/teki_model/order_restaurant_change_status_items.dart';
import 'package:teki_app/src/data/models/teki_model/production_area.dart';
import 'package:teki_app/src/data/models/teki_model/table.dart';
import 'package:teki_app/src/domain/datasource/restaurant_datasource.dart';
import 'package:teki_app/src/utils/api_client.constant.dart';
import 'package:teki_app/src/utils/notifications.dart';

class RemoteRestaurant extends RestaurantDatasource {
  Dio dio = ApiClient.dio;

  @override
  Future<List<Lounge>> getLounges(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/lounges', queryParameters: params);
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      return list.map((e) => Lounge.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(msg);
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  @override
  Future<List<Table>> getTables(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/tables', queryParameters: params);
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      return list.map((e) => Table.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(msg);
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  @override
  Future<void> attendTableCall(int tableId) async {
    try {
      await dio.post('/tables/$tableId/atender-llamada');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final data = e.response?.data;
      final message =
          (data is Map ? (data['mensaje'] ?? data['message']) : null) ??
          e.message ??
          'No se pudo atender la llamada';
      throw Exception(message);
    }
  }

  @override
  Future<void> attendTable(int tableId) async {
    try {
      await dio.post('/tables/$tableId/atender');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final data = e.response?.data;
      final message =
          (data is Map ? (data['mensaje'] ?? data['message']) : null) ??
          e.message ??
          'No se pudo asignar la mesa';
      throw Exception(message);
    }
  }

  @override
  Future<List<OrderRestaurant>> getOrders(Map<String, dynamic> params) async {
    try {
      final response = await dio.get(
        '/orders-restaurant',
        queryParameters: params,
      );
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      return list.map((e) => OrderRestaurant.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(msg);
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  @override
  Future<List<Command>> getCommands(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/commands', queryParameters: params);
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      return list.map((e) => Command.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'No se pudieron cargar las comandas';
      throw Exception(msg);
    }
  }

  @override
  Future<List<Command>> getPendingQrCommands(int officeId) async {
    try {
      final response = await dio.get(
        '/commands/qr-pendientes',
        queryParameters: {'idPuntoVenta': officeId},
      );
      final data = response.data;
      final List list = data is List
          ? data
          : data is Map
          ? (data['content'] as List? ?? const [])
          : const [];
      return list.map((entry) => Command.fromJson(entry)).toList();
    } on DioException catch (error) {
      if (error.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final responseData = error.response?.data;
      final message =
          (responseData is Map
              ? (responseData['mensaje'] ?? responseData['message'])
              : null) ??
          error.message ??
          'No se pudieron cargar las comandas QR';
      throw Exception(message);
    }
  }

  @override
  Future<void> reviewQrCommands(
    List<int> commandIds,
    String status, {
    bool attend = false,
  }) async {
    try {
      await dio.patch(
        '/commands/aprobacion',
        queryParameters: {'estado': status, 'atender': attend},
        data: commandIds,
        // Dio no puede inferir el content-type de un List<int> (lo enviaría
        // como application/octet-stream → 415). Forzar JSON.
        options: Options(contentType: Headers.jsonContentType),
      );
    } on DioException catch (error) {
      if (error.message == 'SESSION_EXPIRED') {
        throw Exception('Sesión expirada');
      }
      final responseData = error.response?.data;
      final message =
          (responseData is Map
              ? (responseData['mensaje'] ?? responseData['message'])
              : null) ??
          error.message ??
          'No se pudo revisar la comanda QR';
      throw Exception(message);
    }
  }

  @override
  Future<List<ProductionArea>> getProductionAreas() async {
    try {
      final response = await dio.get(
        '/production-area',
        queryParameters: {'paginacion': false},
      );
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      return list.map((e) => ProductionArea.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'No se pudieron cargar las zonas';
      throw Exception(msg);
    }
  }

  @override
  Future<OrderRestaurant> createOrder(OrderRestaurant order) async {
    try {
      final response = await dio.post(
        '/orders-restaurant',
        data: order.toJson(),
      );
      try {
        return OrderRestaurant.fromJson(response.data);
      } catch (_) {
        return OrderRestaurant();
      }
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final data = e.response?.data;
      final msg =
          (data is Map ? (data['mensaje'] ?? data['message']) : null) ??
          'Error al crear orden';
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<Command> addCommand(int orderId, Command command) async {
    try {
      final response = await dio.post(
        '/orders-restaurant/$orderId/commands',
        data: command.toJson(),
      );
      return Command.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final data = e.response?.data;
      final msg =
          (data is Map ? (data['mensaje'] ?? data['message']) : null) ??
          'Error al agregar comanda';
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<Check>> saveChecks(int orderId, List<Check> checks) async {
    try {
      final response = await dio.post(
        '/orders-restaurant/$orderId/cuentas',
        data: checks.map((c) => c.toJson()).toList(),
      );
      final List data = response.data is List ? response.data : [];
      return data.map((e) => Check.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al guardar cuentas';
      throw Exception(msg);
    }
  }

  @override
  Future<void> deleteOrderChecks(int orderId) async {
    try {
      await dio.post(
        '/orders-restaurant/$orderId/operations/delete-order-check',
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al eliminar precuentas';
      throw Exception(msg);
    }
  }

  @override
  Future<List<OrderRestaurantChangeStatusItems>> updateOrderStatus(
    int orderId,
    String estado, {
    bool updateInventory = true,
    String? observacion,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'estado': estado,
        'updateInventory': updateInventory,
      };
      if (observacion != null && observacion.isNotEmpty) {
        queryParams['observacion'] = observacion;
      }
      final response = await dio.patch(
        '/orders-restaurant/$orderId/estado',
        queryParameters: queryParams,
      );
      final List data = response.data is List ? response.data : [];
      return data
          .map((e) => OrderRestaurantChangeStatusItems.fromJson(e))
          .toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final data = e.response?.data;
      final msg =
          (data is Map ? (data['mensaje'] ?? data['message']) : null) ??
          e.message ??
          'Error al actualizar estado';
      return Future.error(msg);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<Check>> getChecks(Map<String, dynamic> params) async {
    try {
      final response = await dio.get('/checks', queryParameters: params);
      final data = response.data;
      final List list = data is List ? data : (data['content'] ?? []);
      return list.map((e) => Check.fromJson(e)).toList();
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      if (e.response == null) {
        errorNotification('Sin conexión a internet');
        return Future.error('Sin conexión a internet');
      }
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error de conexión';
      errorNotification(msg);
      return [];
    } catch (e) {
      errorNotification(e.toString());
      return [];
    }
  }

  @override
  Future<Check> getCheckById(int id) async {
    try {
      final response = await dio.get('/checks/$id');
      return Check.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al cargar la cuenta';
      throw Exception(msg);
    }
  }

  @override
  Future<Check> updateCheck(int id, Check check) async {
    try {
      final response = await dio.put('/checks/$id', data: check.toJson());
      return Check.fromJson(response.data);
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al actualizar la cuenta';
      throw Exception(msg);
    }
  }

  @override
  Future<void> updateCommandItemStatus(
    int commandId,
    int itemId,
    String status, {
    String? motivoAnulacion,
    double? cantidad,
  }) async {
    try {
      await dio.patch(
        '/commands/$commandId/items/$itemId/estadoComandaDetalle',
        data: {
          'estadoComandaDetalle': status,
          // null = afecta toda la línea; N < cantidad de la línea = el backend
          // divide la línea y solo N unidades cambian de estado.
          'cantidad': cantidad,
          'updateInventory': true,
          if (motivoAnulacion != null) 'motivoAnulacion': motivoAnulacion,
        },
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al actualizar el item';
      throw Exception(msg);
    }
  }

  @override
  Future<void> updateCommandItemsStatus(
    int commandId,
    List<int> itemIds,
    String status,
  ) async {
    try {
      await dio.patch(
        '/commands/$commandId/items/estadoComandaDetalle',
        data: {'idItems': itemIds, 'estadoComandaDetalle': status},
      );
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al actualizar los platos';
      throw Exception(msg);
    }
  }

  @override
  Future<void> expandCommandItem(int itemId) async {
    try {
      await dio.patch('/commands/items/$itemId/expand');
    } on DioException catch (e) {
      if (e.message == 'SESSION_EXPIRED') throw Exception('Sesión expirada');
      final rd = e.response?.data;
      final msg =
          (rd is Map ? (rd['mensaje'] ?? rd['message']) : null) ??
          e.message ??
          'Error al separar el item';
      throw Exception(msg);
    }
  }
}
