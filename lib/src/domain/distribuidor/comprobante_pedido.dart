/// Validación inmediata del receptor del pedido. El backend vuelve a validar con la política de venta.
String? validarComprobantePedido(Map<String, dynamic> pedido) {
  final destino = pedido['tipoComprobanteDestino'];
  if (!['01', '03', 'NV'].contains(destino)) {
    return 'Selecciona el comprobante a emitir.';
  }
  final cliente = pedido['cliente'] as Map? ?? {};
  final tipo =
      '${pedido['tipoDocumentoReceptor'] ?? cliente['tipoDocumento'] ?? ''}'
          .trim();
  final numero =
      '${pedido['numeroDocumentoReceptor'] ?? cliente['numeroDocumento'] ?? ''}'
          .trim();
  final nombre =
      '${pedido['denominacionReceptor'] ?? cliente['razonSocial'] ?? ''}'
          .trim();
  if (numero.isEmpty || nombre.isEmpty) {
    return 'Selecciona un cliente con documento y nombre.';
  }
  if (destino == '01' && tipo != '6') {
    return 'La factura requiere un cliente con RUC.';
  }
  if (!['0', '1', '4', '6', '7', 'A'].contains(tipo)) {
    return 'El tipo de documento del cliente no es válido.';
  }
  if (tipo == '1' && !RegExp(r'^\d{8}$').hasMatch(numero)) {
    return 'El DNI debe tener 8 dígitos.';
  }
  if (tipo == '6') {
    if (!RegExp(r'^(10|15|16|17|20)\d{9}$').hasMatch(numero)) {
      return 'El RUC del cliente no es válido.';
    }
    const pesos = [5, 4, 3, 2, 7, 6, 5, 4, 3, 2];
    var suma = 0;
    for (var i = 0; i < 10; i++) {
      suma += int.parse(numero[i]) * pesos[i];
    }
    if ((11 - suma % 11) % 10 != int.parse(numero[10])) {
      return 'El RUC del cliente no es válido.';
    }
  } else if (tipo != '0' && !RegExp(r'^[a-zA-Z0-9]{1,15}$').hasMatch(numero)) {
    return 'El documento del cliente debe tener hasta 15 caracteres alfanuméricos.';
  }
  if (destino == '03' &&
      (pedido['codigoMoneda'] ?? 'PEN') == 'PEN' &&
      ((pedido['totalVenta'] as num?) ?? 0) >= 700 &&
      cliente['porDefecto'] == true) {
    return 'Boleta desde S/ 700: identifica al cliente con su documento y nombre.';
  }
  return null;
}
