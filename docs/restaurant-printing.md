# Impresión de comandas en la app móvil

La creación de un pedido sin mesa usa la misma condición de la web: después de guardar la orden, imprime su comanda si `imprimirPedidoComandaSinComprobante` está activado. La condición se aplica antes de regresar a pedidos o abrir la preparación del comprobante; el nombre del flag no limita su uso a pedidos sin comprobante. Si el flag llega ausente o apagado, no se imprime al registrar la orden; el envío se difiere hasta el cobro.

La app conserva ese flag al cargar y serializar `ConfigCompany`. La pantalla entrega configuración, empresa y punto de venta al notifier. El servicio compartido atiende el cliente `COFFE`, como el flujo móvil de mesa existente. Otros clientes no generan solicitudes COFFE. Las comandas con mesa mantienen su impresión independiente del flag de pedidos sin mesa.

Si el flag está apagado o ausente, la comanda del pedido sin mesa se envía después de registrar correctamente el cobro y su comprobante, igual que `registrarPagoCuentaRestaurante` en la web. `pagarCuentaRestaurante` usa el pedido y las comandas devueltos por la actualización de la cuenta. Envía cada ID una vez y conserva la configuración de empresa/sede del cobro. Con el flag activo no vuelve a imprimir al cobrar; con mesa tampoco repite la impresión inicial. Un error de impresión posterior no convierte un cobro exitoso en un pago fallido ni vuelve a registrar el pago.

`CommandPrintService` consulta la comanda guardada y reúne las áreas primaria y secundaria de la categoría, incluidas las de componentes de combos y productos adicionales. Por cada ID de área envía un trabajo a la primera ticketera configurada para el punto de venta actual. No duplica áreas ni utiliza impresoras de otra sede. El modo explícito PDF/ESC-POS de la impresora tiene prioridad sobre el modo global; `GLOBAL` o modo ausente usa `imprimeTicketsEscPos`.

Durante el guardado y el envío inicial, el notifier conserva `isSubmitting`; una segunda confirmación pendiente no crea otra orden. Si el usuario sale durante el guardado, la respuesta guardada puede imprimirse sin acceder al estado de un notifier destruido.

Un fallo al consultar la comanda, un error del servicio de impresión o una respuesta `printed:false` muestran un aviso. El error de una impresora no impide intentar las otras áreas. La orden guardada conserva su éxito y no se vuelve a crear por el fallo de impresión. El detalle del pedido permite **Reimprimir en cocina**; esa acción vuelve a enviar las áreas de esa comanda y no registra una nueva orden. Es una reimpresión explícita, no una garantía de entrega única del papel.

## Pruebas

```sh
flutter test test/providers/pedido_sin_mesa_print_test.dart test/shared/command_print_service_test.dart
flutter test test/providers/restaurant_payment_print_test.dart
flutter test
flutter analyze
```

Las regresiones usan un adaptador HTTP sin acceso externo y datos ficticios. Cubren flag activo/apagado/ausente, guardado único, cierre de pantalla, HTTP503, agente desconectado, reimpresión, áreas/sede, combos/extras, PDF/ESC-POS y parámetros de anulación. Estas pruebas no acreditan impresión física. Los stickers usan un flujo separado en la web y no se implementan en este arreglo de comandas para ticketeras.

Las pruebas de cobro cubren el `PUT /checks/{id}` y la impresión posterior, incluidas varias comandas, IDs repetidos/ausentes, pago rechazado y fallo HTTP/agente de impresión. Abrir la preparación del comprobante sin completar el cobro no verifica este flujo.
