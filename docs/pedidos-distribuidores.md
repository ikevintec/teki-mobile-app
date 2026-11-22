# Pedidos de venta: backend, web y app

**20/11/2026 · Implementado localmente; pendiente de publicación y despliegue.**
Alcance aprobado por Kevin: flujo y prevención de errores, captura rápida móvil y bonificaciones interactivas.
La web conserva su interfaz actual. Esta versión sustituye el plan previo, que figuraba como no implementado.

## Flujo y compatibilidad

Borrador → Enviado → En atención → Convertido. Anulado es terminal.

| Estado / acción | Comportamiento implementado |
| --- | --- |
| Borrador | Guardado explícito con internet, por empresa/usuario/sede, recuperable y paginado; sin numeración ni reserva |
| Enviado | Número asignado por servidor; editable según permisos y revisión mientras nadie lo atienda |
| Tomar | Asignación atómica de responsable; conserva vendedor principal |
| En atención | Solo el responsable puede editar/convertir y además debe tener los permisos correspondientes |
| Liberar | Vuelve a Enviado; motivo y auditoría; liberar atención ajena exige permiso específico |
| Convertir | Venta y cierre del pedido en la misma transacción; conserva vendedor, precios y reglas originales |
| Anular | Motivo y auditoría; libera reserva correspondiente y bloquea futuras ediciones/conversiones |

No hay devolución al vendedor, Observado, aprobación, facturación parcial, reparto, GPS, importador Excel nuevo,
registro offline ni envío automático al reconectar. Los borradores requieren guardado explícito y conexión;
un formulario no guardado no se presenta como recuperable tras cerrar la app.

**Decisión actualizada de Kevin:** el flujo es estándar para todos los pedidos de venta, nuevos e históricos,
sin activar distribuidores ni tipos comerciales. Los pedidos históricos con revisión nula se consultan como
revisión 0 y adoptan revisión/auditoría en la siguiente acción, sin reescritura masiva. `pedidoGestionado` es
solo un metadato de compatibilidad de la respuesta; no se consulta para habilitar reglas.
La captura web y la app usan el mismo flujo. Cotizaciones conservan su flujo y permisos actuales.
Los precios comerciales/tradicionales, promociones elegibles y reserva siguen su configuración independiente.
No se modifican catálogos públicos.

## Backend

- `Quotation` conserva el enum compartido PENDIENTE/CONCRETADA/ANULADA. Metadatos aditivos para gestión,
  revisión, responsable y fecha; DTO con estado legible, capacidades y comprobante relacionado.
- Idempotencia persistida por empresa/actor/clave y hash de comando. Misma clave y contenido devuelve el mismo
  resultado; contenido distinto se rechaza. Numeración serializada; envío y auditoría en la misma transacción.
- Revisión esperada obligatoria en todos los pedidos. Edición/conversión/anulación de una versión antigua
  devuelve conflicto; los endpoints antiguos tampoco pueden eludir responsable, revisión ni estado terminal.
- Auditoría de eventos con actor, fecha, motivo y antes/después de estado, atribución y líneas relevantes.
- Reserva usa el mecanismo y configuración existentes; tomar/liberar no mueve stock. Sin adelanto no se
  crea un cobro ficticio. Reintentar no duplica pedido, reserva ni conversión.
- Vista previa de promociones ampliada con nombres, unidades y disponibilidad de regalos; sin costos ni
  permisos administrativos. Motor de promociones y snapshots originales siguen siendo la autoridad.
- Frecuentes del propio vendedor/cliente/sede y última canasta autorizada; esta última solo aporta productos
  y cantidades. Reutilizarla consulta precios/promociones vigentes y no copia acuerdos de otro pedido.

### Contratos

Base `/api/ticket-order/gestion`:

| Método / ruta | Uso |
| --- | --- |
| POST base / PUT `/{id}` | Enviar / editar con `{clave, revision, pedido, borradorId}` |
| GET `/{id}` | Detalle vigente, capacidades y venta relacionada |
| POST `/{id}/tomar`, `/liberar`, `/anular` | Comando con clave/revisión y motivo cuando corresponda |
| GET `/{id}/historial` | Eventos autorizados, paginados |
| GET `/operaciones/{clave}` | CONFIRMADO, NO_REGISTRADO o EN_CURSO; resultado estable |
| GET `/borradores`; PUT `/borradores/{id}` | Propios, revisión y sede; consulta paginada |
| GET `/frecuentes`, `/ultima-canasta` | Propios por cliente/sede; productos sin precios históricos |

`/ticket-order` conserva POST/PUT como adaptadores del mismo servicio de gestión; el encabezado
`Idempotency-Key` identifica el envío recuperable del cliente. Si se omite se genera una clave en servidor,
sin prometer recuperación de respuesta perdida al consumidor antiguo. No hay ruta de guardado tradicional.
DELETE antiguo no permite eludir revisión/motivo: requiere usar el comando de anulación.
La conversión usa el servicio de venta existente, transportando la revisión del pedido de origen.

Permisos existentes de consulta/edición propia o ajena siguen separados. Nuevos `PEDIDOS_ATENDER` y
`PEDIDOS_REASIGNAR_ATENCION`; atender no concede editar pedidos ajenos ni emitir ventas.
Convertir exige también `VENTAS_CREAR` y acceso a la sede. No se cambian permisos de cotizaciones.

## Web: cambios mínimos

Tabla y calendario muestran estado/responsable y acciones según capacidades del servidor. Liberar/anular
usan motivo en diálogo PrimeNG. Al abrir el detalle del calendario se consulta la revisión vigente, evitando
acciones sobre una copia anterior a tomar/liberar desde la tabla. Se conserva el formulario de emisión.
Filtro opcional de pendientes de cualquier fecha, sin alterar los filtros iniciales de clientes básicos.
El stream de filtros sigue operativo después de un error.

Envío protegido contra doble registro, sesión de operación conservada por empresa/usuario/sede en sessionStorage,
y verificación explícita tras respuesta incierta. Nunca reenvía el comando bajo otra empresa si cambia la sesión
mientras se consulta el resultado. El formulario conserva trabajo ante error; no hay reintento ciego.

## App Flutter

- Acceso «Pedidos de venta», separado de restaurante. Mis pedidos, estados/responsable, borradores propios
  y consulta del comprobante resultante. Carrito de pedido aislado del de venta/cotización.
- Captura cliente → productos → cantidades decimales → revisión/envío, sin paso de caja. Dirección disponible,
  fecha de entrega, nota, total persistente, búsqueda con descarte de respuestas antiguas, frecuentes y repetir
  última canasta. Repetición acotada a 50 productos, carga en lote y recuperación del carrito si falla.
- Precios comerciales elegibles compartidos + sede; tradicionales solo sin tipo cuando están desactivados.
  Cabecera afecta productos nuevos, acciones por línea conservan atribución; precio manual según permisos.
  Mayoreo automático ignora mínimos inválidos sin romper el documento. Pactos persistidos no se reprician
  por cambiar la cantidad; nuevas líneas siguen la configuración vigente.
- DTOs/fromJson/toJson/copyWith y conversiones conservan tipos, origen, referencia, vendedor, revisión y
  bonificaciones. Cache de catálogo versionada y aislada por sesión/sede; cambiar configuración no destruye
  el carrito y cambiar sede/empresa crea otro contexto.
- Bonificaciones visibles con regalos identificados, elección manual de alternativa, conflictos excluyentes,
  bloqueos/avisos y motivos desplegables. Regalos no admiten edición libre de cantidad/precio.
  Evaluación con debounce y descarte de respuesta obsoleta; validación final antes de enviar/emitir.
- Operación persistida antes de enviar: doble toque bloqueado, resultado incierto verificable con misma clave
  y mismo contenido, incluso tras reapertura. Sin sincronización offline automática.
- Ventas/cotizaciones móviles comparten transporte comercial y panel de beneficios; mantenimiento/reportes
  siguen en web. Cotizaciones conservan sus permisos existentes.

## Comprobaciones realizadas

Ambiente local y datos ficticios. Sin SUNAT, mensajes, cobros ni cuentas productivas.

- Backend: **122 pruebas** aprobadas: PedidosInventarioIntegrationTest (24), DistribuidoresIntegrationTest (75), PedidoAccesoServiceTest (9),
  QuotationServiceImplTest (12), PedidosMigrationSqlTest (1), PackageBoundaryTest (1).
  Incluyen envío concurrente/idempotente, conflicto de revisión, toma/liberación/anulación, conversión real a
  nota de venta, segunda conversión rechazada, borradores y compatibilidad del flujo estándar con tipos apagados/encendidos y pedidos históricos.
- QA adicional de inventario: reserva ON/OFF y cambios con pedido abierto, anulación/reintentos/concurrencia,
  regalos, cajas de 6 unidades, venta con despacho posterior y rollback de stock/revisión/responsable.
  Sin fallos funcionales encontrados en esta matriz; solo pruebas y fixture de moneda nacional agregados.
- Migración SQL real ensayada sobre esquema descartable MySQL 8.0.46; columnas aditivas e índices separados,
  algoritmo explícito y perfiles existentes sin asignaciones automáticas.
  Regresión adicional: histórico sin marca/revisión usa atención estándar; alternar tipos comerciales no altera
  responsable/estado/revisión. Cotizaciones se editan, convierten y anulan por sus rutas anteriores.
- Flutter: suite completa **365 pruebas** aprobadas; casos de precios/pactos, respuesta perdida, cambio de
  contexto, widgets a 360/390/1024 px, regalos, repetición de canasta y rechazo de carga incompleta.
  Analyze sin errores ni advertencias; conserva avisos informativos de estilo preexistentes.
- Web: compilación de tipos/templates y **3 pruebas HTTP/Karma** de idempotencia, recuperación y aislamiento
  de sesión. Prueba con navegador sobre backend y MySQL efímeros: tabla/calendario, tomar/liberar con motivo,
  responsable y filtro de antigüedad; corrección de revisión obsoleta y unidad nula en detalle.
- iPhone 16 Pro / iOS 18.3 Simulator: recorrido nativo de captura, cantidad, elección de regalo, borrador y envío,
  con API simulada explícita. Android API 36: APK debug compilado, instalado y arrancado, captura inicial;
  interacción completa Android pendiente porque la herramienta de control no accedió a la ventana Qt.

Estas evidencias no equivalen a una prueba única app→backend real→web ni a UAT con el distribuidor.
Autorrevisión del diff, no revisión independiente. Evidencia temporal en
`Teki/output/pedidos-campo-2026-11-20/`; no contiene pruebas de despliegue.

## Habilitación y pendientes de release

1. Revisar y publicar cambios locales de backend/web y rama móvil `codex/pedidos-distribuidores`.
2. Aplicar por el procedimiento operativo autorizado `db/DISTRIB-11-pedidos-campo-2026-11-20.sql`, después de
   revisar el esquema/versión/índices reales según AGENTS. No aplicada a la BD del usuario ni a producción.
3. Asignar deliberadamente permisos de atención/liberación a los perfiles de oficina. No se conceden por migración.
4. Desplegar backend compatible antes que los consumidores. Verificar cuenta Teki/CBET y escenarios representativos.
5. UAT móvil con backend real en ambas plataformas, reconexión/suspensión y canasta realista; medir rendimiento
   y concurrencia del cliente. No se promete tiempo de captura ni volumen soportado sin esa medición.

Se difieren offline, venta parcial, devolución/Observado, logística, mantenimiento/reportes móvil y Excel.

## Comprobante previsto al registrar el pedido · 20/11/2026

Implementado localmente para todos los pedidos, independientemente de tipos comerciales. Web y Flutter permiten elegir **Factura (01), Boleta (03) o Nota de venta (NV)**; el nuevo formulario muestra NV inicialmente y conserva la elección en borradores, edición, listado y detalle. El backend persiste `Quotation.tipoComprobanteDestino` y lo incluye en la auditoría del pedido.

El destino es obligatorio al guardar/enviar. El backend reutiliza la validación del receptor de ventas (tipo de documento, número, RUC y denominación); los consumidores muestran el error antes de enviar. Un cliente persistido debe pertenecer a la empresa y coincidir con el documento del receptor. La conversión exige el tipo acordado: no se infiere de nuevo según DNI/RUC ni se permite emitir otro tipo sin editar antes el pedido. No se reserva serie ni correlativo fiscal desde el pedido.

Las cotizaciones conservan su flujo actual. Los pedidos históricos quedan con destino nulo: deben editarse y definirlo antes de convertir; no se inventa un comprobante por migración. La conversión masiva queda diferida, con este dato ya disponible para desarrollarla.

Migración preparada: `db/DISTRIB-12-comprobante-pedido-2026-11-20.sql`, columna nullable aditiva con `ALGORITHM=INSTANT` y espera de metadata limitada. Debe revisarse y aplicarse operativamente antes de desplegar el backend; no aplicada a la BD del usuario ni a producción. Durante QA web se detectó y corrigió un fallo de serialización de un movimiento de caja sin estado enviado al guardar el pedido sin adelanto; queda cubierto por integración. Además, un objeto de caja vacío en el alta sin adelanto se descarta para no crear movimientos ni exigir caja innecesariamente.

Validación del cambio (20/11/2026, ambiente local aislado): **203 pruebas backend** aprobadas (79 distribuidores, 24 inventario, 16 comprobante, 61 validador ventas, 12 cotizaciones, 9 acceso, migración y límites de paquetes), **11 web** y **368 Flutter**. `ngc` aprobado; Flutter analyze sin errores/advertencias, 81 avisos informativos. Navegador con backend real efímero: guardar Boleta, verla en listado, tomar pedido y abrir conversión conservando el tipo bloqueado; error Factura con DNI y formulario a 390 px comprobados. iOS Simulator: Factura con RUC, borrador y envío mediante API simulada. No se acredita una emisión SUNAT ni integración nativa app→backend real ni QA nativo Android del delta. Autorrevisión del código, sin revisor independiente. Evidencia `output/pedido-comprobante-2026-11-20/verification.json`; correcciones de caja incluidas en la corrida final.


## 21/11/2026 — Pedidos Flutter: identidad de ventas y filtros para vendedores

Implementado y probado localmente en `teki-mobile-app`, rama `codex/pedidos-distribuidores`, conservando el WIP anterior. Se mantiene organización y flujo de captura/edición/envío. Tema acotado `PedidosStyle`: azul `ColorSchema.primaryColor`, superficies neutras, botones/campos/tarjetas coherentes con ventas, sin el tinte morado Material genérico. Se aplica al listado, ruta del formulario, búsquedas, beneficios y diálogos que heredan ese contexto; no se modifica el tema global de ventas ni cotizaciones. Respeta tema oscuro heredado; la aplicación general no se rediseña para habilitarlo.

El listado permite buscar por nombre de cliente o DNI/RUC y filtrar pedidos enviados por estado (pendiente, convertido, anulado), fecha de emisión (Hoy/7 días/30 días/todas o rango), serie, número y orden reciente/antiguo. Muestra filtros activos, rango exacto y limpieza. Borradores se mantienen en su sección, fuera de estos filtros. Sede y vendedor continúan siendo los de la sesión; no se habilita consulta de vendedores ajenos. El contrato reutiliza GET /quotation con filtros de servidor, páginas de 20 y debounce de 350 ms; no se filtra solo lo descargado ni se vuelve a consultar borradores al escribir. Recarga y retorno del formulario conservan los filtros; cambiar contexto los limpia y descarta respuestas antiguas. Errores permiten reintentar sin un falso vacío. El teclado no autocorrige nombres ni series de búsqueda.

Corrección necesaria de backend (`feature/distribuidores`): cuando esPedido=true, el hasta incluye 23:59:59.999 del día elegido. Antes se interpretaba a medianoche y excluía pedidos posteriores de ese día. Cotizaciones conservan la condición anterior. Prueba HTTP/servicios/MySQL descartable: incluye 00:00 y 23:59:59, excluye 00:00 del día siguiente y compone estado; regresiones de permisos/cotizaciones/fronteras incluidas.

**Verificación:** 377 pruebas Flutter completas aprobadas; tras el ajuste de autocorrección detectado en teclado nativo se repitieron 24 focalizadas de distribuidores, todas aprobadas. Analyze: cero errores/advertencias, 81 infos existentes. Build debug de iOS Simulator correcto. Backend: 17 pruebas seleccionadas aprobadas (2 DistribuidoresIntegrationTest, 2 QuotationFindByIdIntegrationTest, 12 QuotationServiceImplTest, 1 PackageBoundaryTest); no nueva suite backend completa ni deploy. Autorrevisión del delta; el primer fallo de widget fue un finder que confundía texto editable/lista y otro que usaba first en un objetivo aún no construido al volver arriba; corregida automatización, manteniendo los criterios.

UI: pruebas widget a 360×640/390×844/1024×768, escala hasta 1,5 y oscuro; simuladores iPhone16Pro/iPadAir11 iOS18.3 (tablet vertical/horizontal), texto ampliado, búsqueda exacta Olivos, limpiar, Pendientes+Hoy, panel de filtros y entrada a Nuevo pedido. API simulada explícitamente en la copia nativa; sin tráfico a cuentas reales ni integración app→backend real acreditada. Copia instalada con ID QA separado y retirada después; app original conservada, ajustes de apariencia/tamaño restaurados e iPad propio apagado. Detector estático sin hallazgos, sin atribuirle validación nativa completa; corrección visual agrupada y confirmación, después solo el delta funcional del autocorrector. No prueba física ni QA nativo Android en este cambio. Evidencia y capturas originales: `Teki/output/pedidos-mobile-filtros-2026-11-21/`.

Solo implementado/probado localmente. Sin commit/push, migración ni despliegue en esta tarea. Los PRs backend/web publicados antes no contienen aún esta corrección de fecha; Flutter continúa pendiente de publicación y UAT con API real.


### 21/11/2026 — Corrección del listado móvil según el patrón real de ventas

El usuario comparó capturas de ventas y pedidos: el ajuste anterior de paleta no resolvía la diferencia de jerarquía. Implementado localmente `PedidoListItem`, tomando como referencia `TicketListSection` de `comprobantes/list_comprobantes.dart`: filas planas con fecha día/mes a la izquierda, Pedido y serie/número, cliente secundario, estado propio e importe azul con símbolo monetario y dos decimales a la derecha. Separadores y fuentes Poppins/Roboto coherentes con ventas. Sin tarjetas genéricas ni indicadores SUNAT en pedidos. Datos ausentes se muestran explícitamente, sin inventar fecha, cliente, importe o condición de pago. Acción Más filtros visible; se conservan consultas, filtros, paginación, borradores y apertura del detalle, sin cambiar captura ni contratos/backend.

Se incluyen las cuatro fuentes necesarias como assets, con hashes de la metadata de google_fonts 8.0.2 verificados y licencias OFL: evita depender de descargas al ejecutar y conserva los mismos archivos tipográficos que usa ventas. Procedencia en `Teki/output/pedidos-listado-venta-2026-11-21/fonts-provenance.json`.

Verificación: 381 pruebas Flutter completas aprobadas; después del último ajuste de grises/separadores, 28 focalizadas finales aprobadas. Analyze final: 0 errores, 0 advertencias y 81 infos existentes. Build final iOS Simulator correcto. Nuevas pruebas verifican fecha, moneda, ausencias, pulsación, cliente/importe largos a 320px y escala 2. Autorrevisión del delta; detector estático sin hallazgos. Confirmación nativa en iPhone16Pro/iPadAir11 iOS18.3 con API simulada y datos ficticios: listado, abrir detalle y filtros. No acredita app→backend real, Android nativo ni hardware. Se retiró la app QA de ID separado, se restauró la app original y se apagó el iPad iniciado para QA. Evidencia y capturas finales: `Teki/output/pedidos-listado-venta-2026-11-21/`.

Estado: implementado y probado localmente en `codex/pedidos-distribuidores`; sin commit/push ni despliegue. WIP previo conservado. No se modificó lógica de ventas, inventario ni SUNAT.


### 21/11/2026 — Cliente dentro de Más filtros móvil

Solicitud Kevin: filtrar pedidos por cliente como en web. Contraste con `tabla-pedidos.component.html` y QuotationRepository: la web usa texto `filtroRuc` sobre nombre/denominación o documento, no un selector por ID. Se agrega Cliente (Nombre, DNI o RUC) al panel Flutter, reutilizando ese contrato ya existente. Inicializa desde el buscador principal y al aplicar sincroniza ambos; recorta espacios. Cerrar sin aplicar descarta lo escrito; Limpiar filtros elimina también cliente. Se combina con estado/fecha/serie/número/orden y paginación remota; sin nueva lógica backend ni cambios de permisos/cotizaciones.

Pruebas locales: 29 de distribuidores aprobadas, incluyendo sincronización, cancelación, reapertura, limpieza y cliente combinado con los demás filtros a360×640/390×844/1024×768 (escala1,5 y oscuro en casos existentes). Dart analyze de los dos archivos modificados sin incidencias. Build iOS Simulator correcto. Prueba nativa iPhone16Pro con API simulada: buscar Olivos desde panel, verificar único resultado y búsqueda sincronizada, reabrir conservando valor y limpiar recuperando cuatro pedidos. Captura del panel inspeccionada. No nueva suite global, backend real, Android nativo ni tablet nativa en este delta. Autorrevisión; fuente/evidencia `Teki/output/pedidos-cliente-mobile-2026-11-21/`. App QA separada retirada y original restaurada. Solo implementado/probado localmente en `codex/pedidos-distribuidores`; sin commit/push/despliegue. WIP previo preservado.


### 21/11/2026 — Ítems compactos y resumen de lectura en pedido móvil

Implementado localmente por solicitud Kevin: las líneas del carrito reducen márgenes/relleno y reúnen descripción e importe en la cabecera, con cantidad y precio en la siguiente fila; se elimina la tercera línea de subtotal. Nombres largos se limitan a dos líneas en edición y se muestran completos en el resumen. Conserva acciones quitar, restar/sumar, editar cantidad y precio, restricciones al guardar/enviar y las líneas de bonificación.

Icono Ver resumen en la cabecera abre un modal de solo lectura con el cliente/documento, comprobante previsto, productos completos, cantidades/unidades, precio unitario/tipo de cada línea, importes, regalos identificados como Gratis, total, entrega/observación si existen y aviso de bonificaciones pendientes cuando corresponda. Usa una copia de la lista actual y los importes del carrito; no recalcula, guarda, envía ni permite editar. Cerrar vuelve al mismo pedido. Cabecera fija y contenido desplazable incluido el total/botón para soportar texto ampliado y pantallas pequeñas. Superficie del tema sin tinte Material genérico; conserva identidad de pedidos.

Verificación: 31 pruebas focalizadas de distribuidores aprobadas sobre la versión final; incluyen abrir/cerrar resumen sin registrar pedido y continuar guardando borrador/enviando a390×844/360×640/1024×768. Dos pruebas nuevas cubren resumen con texto largo, importe grande, regalos y escala2 a320×640/1024×768, con tema oscuro en tablet. La primera corrida detectó desbordamiento del pie fijo en320px/escala2; corregido haciendo desplazable el pie junto al contenido y repetido satisfactoriamente. Build final iOS Simulator correcto; análisis dirigido final sin incidencias. Autorrevisión del delta, sin revisión independiente ni nueva suite global.

iPhone16Pro/iOS18.3 con API ficticia y copia QA separada: canasta3unidades, elección de regalo, abrir/cerrar resumen y conservar carrito; cantidad3→2 y cambio Minorista6→Mayorista5,50 resultan en total11 y conservan el regalo. Confirmación final del modal con fondo corregido; se recuperó el control del simulador tras un reinicio de la herramienta, sin cambiar código para superar la prueba. Evidencia/capturas `Teki/output/pedido-compacto-resumen-2026-11-21/`. Sin QA nativo Android/tablet ni E2E backend real nuevos; API deliberadamente simulada. Copia QA retirada y app original restaurada. Sin modificación backend/web, reglas comerciales, inventario, cotizaciones, publicación ni despliegue. Rama `codex/pedidos-distribuidores`, WIP previo preservado; sin commit/push.


### 21/11/2026 — QA de múltiples productos, bonificaciones y recuperación de borrador

Solicitud Kevin comprobada con8productos distintos (incluye descripción extensa), cantidades3/2/4/6/2/5/1/3, precios6/12,50/4,80/4,20/8,90/3,60/9,50/3 y dos promociones:2jabones automáticos y1galleta elegida. Diez líneas, total PEN141,70. Nuevo escenario explícito en `test/support/pedidos_varios_fixture.dart` y preview opt-in `QA_VARIOS=true`; no afecta binario productivo.

Se encontró un defecto real al retomar borradores: `_payload` serializa adelanto como entero0 y `Ticket.fromJson` asignaba dinámicamente ese entero a `double?`, provocando TypeError y abortando la carga antes de restaurar las líneas. Los datos seguían guardados; no era pérdida en BD. Corregido en el decodificador con conversión nullable num→double, conservando nulos y valores decimales. La regresión guarda10líneas/selección, serializa/deserializa JSON, destruye ProviderScope/carrito y preferencias locales, reconstruye la sesión y recupera desde el servidor simulado. Verifica cada cantidad/precio, ambos regalos sin duplicación, total, revisión1 al segundo guardado y cero pedidos enviados.

Refinamiento del resumen tras inspección con8productos: se elimina la columna monetaria de ancho flexible1:1 que desaprovechaba ancho; el importe ocupa su ancho natural con límite y la descripción obtiene el resto. Cantidad/precio/tipo en una línea secundaria adaptable; separadores más ajustados. Descripciones completas siguen disponibles, los regalos continúan gratuitos y total/contenido son desplazables. Sin cambio de cálculo, selección comercial ni flujo del pedido.

Validación FINAL:386pruebas Flutter completas aprobadas después de la corrección y del refinamiento; análisis dirigido sin incidencias y build iOS Simulator `QA_VARIOS=true` correcto. Backend:1prueba `DistribuidoresIntegrationTest#borradoresPedidosSeguros` ampliada y aprobada contra MySQL8Testcontainers: guardar10líneas/selección, leer por HTTP y contrastar JSON directamente con la fila de `borrador_pedido`, rechazar revisión obsoleta409, guardar revisión2 sin duplicar y sin quotation/evento. Sin modificar lógica de backend ni BD del usuario; no usar aviso de JaCoCo acumulado como cobertura.

Recorrido nativo iPhone16Pro/iPadAir11 iOS18.3, vertical: crear canasta8, elegir segundo regalo, guardar, salir, retomar, consultar resumen y leer final con ambos regalos y PEN141,70. Confirmación final de distribución compacta; en iPad las10líneas y total caben en el modal, en teléfono se desplaza conservando cabecera/cierre. Widgets repiten recuperación a390×844/1024×768; pruebas existentes de resumen incluyen320px/escala2/oscuro. Native/API es deliberadamente simulada; la persistencia real MySQL se verifica por separado, no se acredita E2E Flutter→backend real, Android ni hardware. Autorrevisión del delta. Copias QA retiradas, app original restaurada e iPad iniciado para QA apagado.

Evidencia: `Teki/output/pedido-varios-borrador-2026-11-21/` (logs finales, XML contrastado, capturas originales, verification.json). Solo implementado/probado localmente; sin commit/push/despliegue, migración ni operación fiscal/inventario/caja. WIP anterior conservado. Esta evidencia sustituye la limitación previa de no haber probado guardar/salir/retomar en simulador, manteniendo pendiente la integración nativa contra backend real.


21/11/2026 — Resumen de pedido Flutter: icono Material card_giftcard de20px junto al nombre exclusivamente en líneas esBonificacion=true, conservando Gratis/Bonificación, importes y contenido.33pruebas focalizadas aprobadas (incluye regalo/escala2/320px y borrador múltiple), análisis dirigido sin incidencias y build iOS correcto. Confirmación visual iPhone con8productos+2regalos/API simulada; no nueva suite global ni Android/tablet nativa en este delta. Autorrevisión, solo local/sin commit/push/despliegue. Evidencia `Teki/output/resumen-icono-regalo-2026-11-21/`. Copia QA retirada y app original restaurada.


### 21/11/2026 — Filtro por cliente en ventas de la app

Implementado localmente para el listado general Ver Comprobante, sin bandera de distribuidores. Más filtros incorpora Cliente con ayuda Nombre, DNI o RUC, reutilizando TextFieldSection y el contrato backend existente `filtroRuc`. TicketApi/TicketRepository admiten coincidencia parcial sobre numeroDocumentoReceptor o denominacionReceptor; no se modifica backend ni se confunde con filtroRucEmisor.

ComprobantesState agrega filtroCliente vacío por defecto. Aplicar recorta espacios; la edición del panel permanece local hasta aplicar y Volver descarta lo no aplicado. Se conserva al reabrir, paginar, recargar y cambiar fechas. Vaciar el campo lo retira sin limpiar otros filtros. La limpieza general lo elimina y el contador lo incluye. Listado, totales por moneda y desglose por medio de pago comparten el mismo constructor de parámetros. Fechas, serie/número, comprobantes, pagos, estado y vendedor se conservan. Sin rol para todos los vendedores se sigue forzando el usuario de la sesión; con rol se conserva la selección. Permiso de totales intacto. TextFieldSection admite desactivar autocorrección/sugerencias solo en este campo mediante opción nullable; los consumidores anteriores conservan su comportamiento.

Pruebas:390Flutter completas aprobadas tras el cambio productivo.4casos focalizados finales repetidos con nombre, RUC11dígitos y DNI8dígitos, blancos/cancelación, reapertura, fechas, paginación, limpieza y parámetros consistentes de totales/desglose; perfiles restringido/amplio a390×844 y1024×768. Análisis dirigido sin incidencias, build iOS correcto y autorrevisión. Se corrigieron un acceso del robot a la propiedad del widget incorrecto y la inicialización dotenv del fixture para vendedores; no se alteró el criterio del producto para pasarlos.

iPhone16Pro/iOS18.3 con repositorio ficticio aislado: nombre Bodega Sur devuelve sus comprobantes; reapertura conserva el texto; RUC20123456789 devuelve Bodega Norte; limpiar retira el contador y recupera el conjunto. El vendedor permanece bloqueado sin permiso y los totales no aparecen sin VENTAS_VER_TOTALES. Captura del panel inspeccionada con identidad existente. No acceso a API/ventas reales ni emisión, no E2E Flutter→backend real ni nuevo QA Android/tablet nativa. Copia QA separada retirada y app original restaurada. Evidencia `Teki/output/ventas-filtro-cliente-mobile-2026-11-21/`. Sin commit/push/despliegue ni cambios a BD/contratos/backend. WIP anterior preservado. Sustituye el hallazgo de falta de filtro documentado antes en esta fecha.


## 21/11/2026 — QA integral del pedido móvil y correcciones

**Estado: implementado y probado localmente, sin commit/push ni despliegue.** Se conservó el WIP anterior.
Revisión motivada por la pantalla roja `_dependents.isEmpty` al aplicar el precio de un producto.
Se aplicaron desarrollo-local e Impeccable sobre la interfaz existente, con autorrevisión del delta.

### Fallos reproducidos y corregidos

- **Precio y cantidad:** el controlador se destruía al terminar el Future del diálogo, antes de desmontar
  el campo durante la animación de salida. `EntradaNumericaPedido` es un StatefulWidget que posee y libera
  su controlador al desmontarse. Aplicar, Cancelar y cierre del sistema funcionan con foco; valida vacíos,
  negativos, NaN/infinito y formato, admite coma decimal y explica el error. Cantidad positiva; precio puede
  ser cero como antes. Ayuda/errores admiten varias líneas para teléfono y texto ampliado.
- **Entrega guardada fuera del rango habitual:** el calendario incluye la fecha existente en sus límites;
  no altera el acuerdo al abrir/cancelar. Reproducción y regresión con fechas de ±800 días.
- **Recuperación de configuración:** `loadInitialData` limpia el error anterior; el estado permite borrarlo
  explícitamente sin cambiar el significado de omitirlo en copyWith. «Revisar» vuelve a cargar y recupera
  el formulario. El panel de beneficios no mantiene una animación de carga indefinida tras ese error.
- **Precio tradicional negociado:** en pedidos, cambiar cantidad conserva el precio manual; las líneas
  de un pedido enviado conservan su importe pactado al editarse. El borrador serializa/restaura precioManual.
  El nuevo argumento isPedido tiene false por defecto: no cambia el mayoreo automático de ventas o
  cotizaciones tradicionales. Cancelar un cambio de precio no marca el pedido como modificado.
- **Repetir última canasta:** el listado paginado real es ligero y omite datos como igv; usarlo directamente
  provocaba una excepción al calcular. Ahora se verifica disponibilidad y se obtienen detalles completos,
  con máximo 4 consultas simultáneas y 50 productos. Se agrega la canasta solo cuando todos están listos;
  el agregador conserva rollback ante fallo. Reutiliza productos/cantidades con precios actuales, no
  precios negociados de la venta/pedido anterior. Aumenta las lecturas HTTP respecto al listado único:
  es una decisión de corrección explícita, limitada; no se afirma haber hecho un benchmark de carga.

### Verificación automática y real

- **417 pruebas Flutter completas aprobadas** en `flutter-final-confirmado.log`, después del último cambio
  funcional y de adaptar la expectativa anterior de cero detalles HTTP al nuevo contrato de canasta.
  Antes falló esa expectativa de automatización; no se eliminó la validación de canasta incompleta.
  Análisis final de pantalla, modelos/proveedores modificados y tests: sin incidencias. El análisis más
  amplio también observa 2 infos antiguas de isNull deprecado en exchange, sin errores/advertencias.
- Matriz de UI: precio comercial/tradicional/manual/sin precio, permiso manual, cantidad decimal, quitar,
  resumen, cliente/comprobante (Factura con DNI bloqueada, Boleta válida), observación, borrador,
  salir/continuar, editar con revisión, error de configuración y borrador/reintento, promociones con error
  y recuperación. Se repiten filtros, estados, respuestas tardías, idempotencia/contexto, canasta incompleta,
  varios productos/bonificaciones y borrador existentes. Diálogo adicional a320px, texto×2 y teclado.
- **188 pruebas backend aprobadas**, Java25/MySQL Testcontainers: distribuidores80, inventario24,
  conversión43, consulta de pedido2, acceso9, comprobante16, servicio cotización12, migración1 y límites
  de paquetes1. Incluyen reserva/no reserva, inventario validado/desactivado y stock insuficiente,
  anulaciones y conversión individual/masiva según los casos de esas suites. Sin cambiar código productivo
  del backend. Avisos de JaCoCo acumulado no se presentan como cobertura de esta ejecución.
- **iPhone16Pro e iPadAir11/iOS18.3 con HTTP real contra API y MySQL efímeros:** crear, cliente/producto,
  precio manual7.25, cantidad2.5, guardar/salir/retomar borrador, resumen, enviar y editar el mismo pedido.
  Relectura API confirma P001-2, revisión2, cantidad3.5, unitario7.25, total25.375 (UI25.38), sin otro pedido
  duplicado. Base final:2pedidos (incluye el fixture inicial),1borrador y2detalles. Nueva sesión del iPad
  consulta lo guardado por iPhone. Repetir canasta final usa3.5×precio actual10=35, sin copiar7.25.
- El backend nativo corre con proveedores externos sustituidos en el fixture: no hubo emisión SUNAT real.
  Las bonificaciones múltiples se validaron con contratos ficticios en Flutter y con motor real en las
  pruebas backend; no se afirma que se hayan elegido regalos contra ese servidor nativo de un solo producto.
  No QA nuevo sobre hardware físico/Android nativo ni garantía de todos los escenarios posibles.

Evidencia local: `Teki/output/qa-pedidos-integral-2026-11-21/` (reproducciones, suites, build iOS,
`api-verificacion.json`, conteos de BD y capturas). `test/previews/pedidos_backend_preview.dart` es una
entrada solo QA, sin release y restringida a localhost/127.0.0.1 en puerto independiente de8080.
`PedidosBrowserFixtureTest` acepta directorio de salida explícito y registra conteos antes de cerrar.
Copia QA con ID distinto retirada de ambos dispositivos, iPad de QA apagado y API/BD efímeras cerradas.
Se reinició el proceso original para retirar la pantalla roja anterior; se conservó su instalación/datos.
El intento de attach no encontró la VM y se canceló. La instalación original **no se reemplazó**: requiere
volver a ejecutar Flutter con este código para incorporar las correcciones. No se escribieron pedidos en
la BD local del usuario ni se modificaron sus servidores8080/4200, catálogos públicos o producción.


## 21/11/2026 — Regresión de ventas del código compartido

QA solicitado por Kevin tras las correcciones de pedidos. Solo implementado/probado localmente,
sin commit/push/despliegue. Se corrigieron tres integraciones de Flutter: mayoreo con Inc. IGV No
que conservaba neto anterior; formulario que reenviaba importes viejos al perder foco/cerrar selector;
y sugerencia que mostraba precio tradicional con tipos comerciales activos.

Selección y conversión de cantidad ahora actualizan unitario/neto juntos y conservan acuerdos,
moneda y costos ajenos; el mayoreo tradicional sigue automático. El formulario escucha el estado
antes de reutilizar controles y los callbacks diferidos leen datos actuales. El buscador usa cabecera,
sede y segregación comercial/tradicional; sin elegible indica Sin precio. No cambios a catálogos públicos,
inventario/caja/backend productivo ni redondeo.

454Flutter completas aprobadas, con37casos nuevos de precios/IGV/PEN-USD/descuentos/bonificaciones,
pantalla390×844/1024×768 y búsqueda;8casos de pantalla usan fuente Roboto real. Análisis dirigido
sin incidencias, builds iOS QA/main correctos.252backend aprobadas (228ventas/validaciones/edición/
caja/distribuidores +24inventario). Suites existentes de pedidos y cotizaciones también pasan.

iPhone con API/MySQL efímeros verifica NV01-1 tradicional(3×8=24, efectivo24) y NV01-2 comercial
(2.5×manual7.25, Mayorista QA/origen MANUAL, UI/pago18.13), relectura sin duplicados. Base final
2ventas/3movimientos de caja incluida apertura. Configuración/medios de pago reales del fixture;
externos fiscales sustituidos. Edición/anulación/inventario acreditados por suites, no por edición o
anulación nativa de esas ventas; producto nativo es servicio. No SUNAT/Android/hardware/impresión/PDF
fiscal nuevos. Evidencia/alcance: Teki/output/qa-ventas-regresion-2026-11-21/REGISTRO.md.

Recursos QA cerrados y app original restaurada sin sustituir instalación/datos; requiere ejecutar
Flutter con código nuevo. Sin escritura en BD del usuario ni alteración de sus servidores locales.


### 2026-11-21 — Selector compacto de tipo de precio en Flutter

Implementado localmente en `teki-mobile-app`: la cabecera compartida de venta/cotización usa un botón compacto sobre el azul (etiqueta, nombre y flecha), con ancho máximo 240 y área táctil mínima 44. El menú marca el tipo actual; los nombres largos se truncan en cabecera y se muestran en el menú. Se conserva el filtro de tipos activos/compartidos/sede y el cambio solo afecta al predeterminado para nuevas líneas. El formulario de pedidos conserva su presentación anterior.

Verificación local: 13 pruebas existentes de ventas/pedidos y 2 nuevas de selección en teléfono/tablet pasan; las nuevas comprueban dimensiones y conservación íntegra del detalle ya agregado. Compilación iOS simulador y capturas iPhone/iPad con API sintética; no es una nueva emisión contra backend. CUA no pudo interactuar por bloqueo del Mac: el menú se verificó con widgets. Copia QA retirada y app original conservada. Evidencia: `output/selector-precio-compacto-2026-11-21/`. Sin publicación ni despliegue.


### 2026-11-22 — Disposición de cabecera comercial Flutter

Ajuste local tras revisión del usuario: selector de precio y menú «Agregar» en una sola barra bajo el buscador. El menú reúne Crear Producto y Producto Libre y elimina una fila de la cabecera. Solo se usa con tipos comerciales activos; modo tradicional conserva sus acciones previas y pedidos conserva su formulario. La selección sigue siendo predeterminada para líneas nuevas, sin cambiar líneas existentes.

Verificación: 15 pruebas dirigidas ventas/pedidos pasan; dos de ellas verifican también apertura/cierre del menú Agregar y conservación del detalle al cambiar tipo. Análisis dirigido sin incidencias y build iOS. iPhone con API sintética: selección de nombre largo y Agregar→Producto Libre ejecutados mediante CUA; capturas iPhone/iPad revisadas. Sin nueva prueba backend ni emisión. Evidencia: `Teki/output/selector-disposicion-2026-11-22/`. Autorrevisión local; sin commit/push/despliegue.
