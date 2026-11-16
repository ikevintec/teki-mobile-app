# Distribuidores en Flutter

Implementación local 16/11/2026. Rama local `feature/distribuidores` creada desde develop `39ab0fe`:
no existía rama móvil remota del desarrollador para este alcance al iniciar. La publicación Git no acredita release móvil.

La app requiere internet. Solo ventas, cotizaciones y pedidos; mantenimiento, recomendaciones y reportes quedan en web.
Configuración de empresa ausente o apagada conserva el flujo anterior y no muestra los controles nuevos.
Session carga configuración/tipos por empresa y sede, ignora respuestas atrasadas y resuelve cabecera cliente→vendedor→Minorista.
Cambiar cabecera afecta únicamente líneas nuevas. Las líneas conservan su tipo inicial y Acciones/manual según permisos;
las cantidades automáticas respetan escalas y las elecciones pactadas no se reemplazan por precios actuales.

`Ticket`, `Quotation` y sus detalles conservan metadatos comerciales, vendedor y vínculo de origen.
`tipoPrecioInicialId` es estado interno de edición: no se serializa a la API. Normalización de impuestos/recargo
usa el comportamiento existente antes de aplicar el importe. Al editar desde un documento se carga el producto completo
para que Acciones disponga de todos sus precios elegibles.

`beneficios_venta_provider` usa preview backend, debounce y revisión de contexto; permite regalo manual/excluyente,
sincroniza líneas gratuitas y valida antes de confirmar. Regalos aplicables tienen cantidad/precio protegidos.
Se conservan las reglas originales al retomar pedido/cotización, incluso vencidas. No hay cálculo offline.

Pedidos usa `/ticket-order` (alta, edición, siguiente número) y listado `/quotation?esPedido=true`.
Cotizaciones conserva sus rutas anteriores. Consultar pedidos ajenos (`PEDIDOS_VER_AJENOS`) y editarlos
(`PEDIDOS_EDITAR_AJENOS`) son permisos independientes; no se cambia el alcance de acceso de cotizaciones.

Verificación: 354 pruebas correctas, incluyendo resolución, contrato de pedidos y visibilidad optativa.
`flutter analyze --no-pub`: sin errores ni warnings; 83 avisos informativos de estilo/deprecación en el repositorio.
No se probó en dispositivo físico ni se distribuyó APK/IPA. Revisar endpoints antes de probar operaciones reales:
los entornos móviles históricos pueden apuntar a producción. No se modificó el pubspec.yaml ajeno de esta sesión.
