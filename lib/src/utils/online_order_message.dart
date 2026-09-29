import 'package:teki_app/src/data/models/teki_model/online_order.dart';
import 'package:teki_app/src/utils/formats.dart';

String buildOnlineOrderStatusMessage(
  OnlineOrder order,
  String status,
  String? companyName,
) {
  final customerName = order.nombreCliente?.trim();
  final company = companyName?.trim();
  final greeting = customerName?.isNotEmpty == true
      ? 'Hola $customerName'
      : 'Hola';
  final sender = company?.isNotEmpty == true
      ? ', le saludamos de $company'
      : '';
  final orderNumber = formatOrderNumber(order.numeroPedido ?? order.id);
  final orderType = order.tipo == 'MENU' ? 'menú' : 'catálogo';
  final template = status == 'ACEPTADO'
      ? order.mensajeAceptacionPedido
      : order.mensajeRechazoPedido;

  if (template?.trim().isNotEmpty == true) {
    return template!
        .trim()
        .replaceAll('{{nombreCliente}}', customerName ?? '')
        .replaceAll('{{nombreEmpresa}}', company ?? '')
        .replaceAll('{{numeroPedido}}', orderNumber);
  }

  if (status == 'ACEPTADO') {
    return '$greeting$sender. Su pedido #$orderNumber de $orderType ha sido '
        'aceptado y ya se encuentra en proceso. Le avisaremos cuando esté '
        'listo. Gracias por su compra.';
  }
  return '$greeting$sender. Lamentamos informarle que su pedido '
      '#$orderNumber de $orderType ha sido cancelado. Si desea más '
      'información, puede responder a este mensaje.';
}
