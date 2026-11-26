# Impresión de comandas en la app móvil

**Guardar borrador** y **Facturación completa** usan la misma condición de la web: después de guardar la orden, imprime su comanda si `imprimirPedidoComandaSinComprobante` está activado. La condición se aplica antes de regresar a pedidos o abrir la preparación del comprobante; el nombre del flag no limita su uso a pedidos sin comprobante. Si el flag llega ausente o apagado, no se imprime al registrar la orden; el envío se difiere hasta el cobro.

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


## Cierre directo nativo (25/11/2026)

La pantalla **Completar pedido** sustituye los modales de cliente/pedido. Permite guardar borrador, abrir facturación completa o emitir directamente; la emisión directa usa `/orders-restaurant/direct-checkout` y su preview del mismo backend web. No registra otra orden/cuenta/venta desde el cliente. Los precios editados y adicionales se envían como precios de comanda; el backend extrae recargo y construye las líneas y redondeos mediante el servicio de emisión existente.

En emisión directa, la comanda se imprime después de confirmar la operación, independientemente del flag de impresión anticipada. El comprobante sigue `impresionAutomatica`, formato A4/TICKET, PDF/ESC-POS y cliente COFFE/BLE. Tras emitir se abre el detalle del comprobante sobre el listado de pedidos, con check y confeti; **Nuevo pedido** inicia una canasta nueva sin mesa, **Pedidos** abre el listado de restaurante e **Inicio** vuelve al dashboard. Atrás conserva el listado subyacente. El PDF se abre solo desde su acción explícita; la impresión automática configurada sigue a cargo de `DirectCheckoutPrinting`. Mesa y cobro posterior conservan sus rutas existentes.

Cada intento persiste UUID y solicitud completa antes del POST, por empresa/usuario/sede/estación. Ante timeout o respuesta incompleta se recupera el mismo intento y se bloquea otra emisión. La recuperación consulta un marcador local de despacho por contexto y UUID: si la instalación aún no intentó imprimir esa operación, continúa la impresión configurada. El marcador se persiste antes de contactar impresoras; si ya existe, evita el envío automático repetido y solicita revisar/reimprimir manualmente. No acredita entrega física única ni resuelve la ventana de cierre abrupto entre guardar el marcador y contactar la impresora. Un fallo de impresora no reintenta la venta.

Los importes del carrito y del cierre usan la cotización del backend. Solo cambian los cálculos al cambiar productos, tipo, exclusión de IGV, contexto o costo de delivery; cambiar entrega sin costo no provoca otro cálculo. Mientras llega una cotización nueva se conserva el importe visible y se bloquea emitir con una cotización anterior. El cambio de empresa/configuración exige reabrir el cierre.

Pagos mixtos distinguen monto asignado, efectivo recibido y vuelto. La propina tiene responsable y pagos separados. Al abrir el editor completo se conservan tipo, serie, pagos y propina; estos campos sobreviven a la construcción del payload de venta. El selector de cantidades del carrito conserva su alcance anterior de cantidades enteras; el contrato de backend admite fracciones.

Pruebas nuevas: `test/providers/direct_checkout_test.dart`, `test/widgets/direct_order_checkout_screen_test.dart`, `test/shared/direct_checkout_printing_test.dart` y regresión de propina/vuelto en `sale_emission_recovery_test.dart`. Cubren las tres acciones, doble toque, recuperación/reinicio, series, respuestas tardías, contexto, pagos mixtos, propina y configuración de impresión. No acreditan entrega física del papel ni emisión fiscal externa.

Los DTO de pedido, líneas y comprobante normalizan números JSON a double: un importe entero como efectivo20 o delivery0 es válido y no debe convertir una emisión confirmada en un fallo al leer la respuesta.


## Correcciones de revisión móvil

Se puede salir de una recuperación con **Continuar después** o Atrás: el intento sigue persistido, los datos permanecen congelados y al volver se usa el mismo UUID. Solo se bloquea la salida mientras se envía el POST. El carrito actualiza el estado pendiente al regresar.

En NV/boleta de importes que admiten cliente no identificado, los campos de cliente son opcionales. Se envía receptor tipo0/número«-» y cliente genérico compatible con el backend; no se inventa un DNI. Factura mantiene RUC/nombre/dirección obligatorios y boleta de importe alto exige identificación. La validación final sigue siendo del servidor. El contacto ingresado se conserva en el pedido, sin volcar datos personales al cliente genérico.

El cierre y su visor reutilizan `PedidosStyle`, fondo blanco, selección azul, bordes y acciones de pedidos; formulario y pie limitan su ancho en tablet. El pago distingue efectivo recibido y muestra vuelto/pendiente. La propina permanece visible en cierre, editor completo y pago final mediante `RestaurantTipSummary`; se puede quitar antes de emitir y se conservan los pagos de propina separados del total de venta. Los importes de propina admiten hasta dos decimales. El editor conserva una serie seleccionada si sigue disponible.

Al abrir facturación completa con búsqueda local y caché vacía, la precarga se difiere hasta después de construir la pantalla. El pago final restaura los importes preparados para cuentas nuevas de restaurante, incluidos efectivo recibido y vuelto.


## Selección de productos antes del cierre

El menú móvil separa Favoritos (orden compartido `numeroOrdenFavorito`, hasta30) y Más vendidos (hasta10 no favoritos por `numeroVentas`). La consulta online reutiliza `favorito=true` del backend y combina el resultado con el menú para conservar categorías. El catálogo local conserva ambos campos y selecciona favoritos antes de limitar resultados. Escribir sale del filtro Favoritos; volver a Favoritos limpia la búsqueda. Limpiar cancela el debounce y las respuestas anteriores no reemplazan una consulta nueva.


Los mensajes de validación del cierre se limpian al corregir los datos, cambiar el tipo de comprobante o editar un importe de pago. Una factura inválida o un pago insuficiente siguen bloqueando la emisión sin guardar otro pedido.


## 26/11/2026 — Final de pedido sin PDF automático

La emisión directa sin mesa reutiliza `ViewComponentScreen` con callback `onNewOrder`.
El comprobante confirmado se presenta sin recargarlo por ID. El callback distingue el final de
pedido del final de venta (`fromSale`); ambos contextos son excluyentes. La celebración, resumen
y acciones Enviar/Imprimir/PDF/Compartir son los mismos del detalle existente. Ventas conserva
Nueva venta, Comprobantes, permiso VENTAS_CREAR e invalidación/navegación anteriores. El histórico
no añade celebración ni barra de continuación. Borrador/editar/con mesa no cambian.

11 regresiones nuevas de widgets verifican menú→checkout→detalle, canasta nueva, navegación,
confeti, PDF manual, permisos de venta y contexto histórico.648 pruebas completas correctas;
54 focalizadas de cierre/venta/recuperación/impresión también correctas (subconjunto). Análisis
sin errores nuevos/76 avisos heredados. Datos y servicios ficticios; no emisión fiscal ni
impresión física. Evidencia: `Teki/output/final-pedido-sin-mesa-2026-11-26/`.
Implementado/probado localmente; sin publicación ni distribución.

QA nativo final: iPhoneSE3/iPadAir11 M3 iOS18.3, detalle/confeti visible, PDF manual, canasta nueva,
regreso a Pedidos y continuidad de ventas comprobados; All tests passed sin excepciones en ambos.
Servicios y destinos de navegación ficticios. Capturas/logs en el expediente; QA separada retirada,
entrypoint lib/main.dart restaurado. Compilación ARM64 correcta, sin cambios de backend.
