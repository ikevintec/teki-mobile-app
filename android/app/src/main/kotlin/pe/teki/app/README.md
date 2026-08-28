# Replicador de pagos Yape / Plin (código nativo Android)

Captura las notificaciones de las apps de pago y registra cada pago en el
backend (`POST /pagos-yape`), **incluso con la app Teki cerrada** (deslizada
desde recientes).

Solo aplica a Android: iOS no permite leer notificaciones de otras apps.

## Archivos

| Archivo | Rol |
|---|---|
| `YapeNotificationListenerService.kt` | `NotificationListenerService`: captura y encola en SharedPreferences |
| `YapePaymentParser.kt` | Extrae `{nombrePagador, monto, codigoOperacion, tipoApp}` del texto de la notificación |
| `YapeSyncWorker.kt` | `CoroutineWorker` que hace el POST con la app cerrada |
| `MainActivity.kt` | `MethodChannel` / `EventChannel` hacia Flutter |

Contraparte en Dart:

- `lib/src/shared/services/yape_notification_service.dart` — puente al canal + parseo Dart
- `lib/src/shared/services/yape_sync_controller.dart` — drena la cola con la app viva
- `lib/src/presentation/screens/replicador/replicador_screen.dart` — pantalla de configuración

## Flujo

```
notificación de Yape/BBVA/Interbank
  └─ YapeNotificationListenerService.onNotificationPosted
       ├─ enqueue() en SharedPreferences "yape_listener_prefs" / "queue"
       ├─ YapeSyncWorker.schedule()      → POST aunque la app esté cerrada
       └─ eventSink.success()            → aviso en vivo a Flutter (solo app abierta)
```

La cola es un `JSONArray` de
`{id, package, title, text, bigText, tipoApp, postTime}`. El `id` es
`package:key:postTime`, estable por notificación, y es lo que evita reencolar
la misma captura.

Apps soportadas (`APP_PACKAGES`):

| Paquete | tipoApp |
|---|---|
| `com.bcp.innovacxion.yapeapp` | `YAPE` |
| `com.bbva.nxt_peru` | `BBVA` |
| `pe.com.interbank.mobilebanking` | `INTERBANK` |

Solo se encolan las apps que el usuario activó, guardadas como CSV en
`enabled_apps`.

## Dos consumidores de la misma cola

| Consumidor | Cuándo corre |
|---|---|
| `YapeSyncController` (Dart) | App viva: al iniciar, al volver del fondo y ante cada captura en vivo |
| `YapeSyncWorker` (nativo) | Siempre, también con la app cerrada |

Ambos confirman por id (`ackItems`), así que el que llegue primero se lleva el
item y el otro ya no lo encuentra. El worker **no reemplaza** al drenaje Dart:
es un respaldo y ambos deben seguir funcionando.

### Invariante: `QUEUE_LOCK`

El servicio, el worker y Flutter corren en el **mismo proceso** y comparten el
archivo de preferencias. **Toda lectura o escritura de la cola debe ir dentro de
`synchronized(YapeNotificationListenerService.QUEUE_LOCK)`**: `enqueue`,
`peekQueue`, `ackItems`, `filterQueueLocked` y la lectura inicial del worker.
El sufijo `Locked` marca los métodos que asumen el lock ya tomado.

## Credenciales espejadas

El worker nativo no puede leer `flutter_secure_storage` (token) ni el `.env`
(baseUrl). Por eso Dart los **espeja** en las mismas preferencias:

| Clave | Origen |
|---|---|
| `sync_token` | `TokenStorage.getToken()` |
| `sync_base_url` | `Environment.apiUrl` |

`YapeSyncController._syncNativeCredentials()` los escribe vía
`setSyncCredentials` en cada cambio de sesión (así el token nuevo pisa al
anterior) y los borra con `clearSyncCredentials` al desloguear o apagar el
replicador. Sin credenciales, el worker termina en `success()` sin tocar la cola:
la app enviará el backlog al abrirse.

Es un JWT de sesión en preferencias privadas de la app; aceptable para este uso.

## Parseo

`YapePaymentParser` es un **puerto literal** de `YapeCapture.parse` en
`yape_notification_service.dart`. Reglas:

- `source` = `[text, bigText, title]` no vacíos, unidos por espacio.
- **Monto**: primer match de `S/\.?\s*([\d.,]+)`. Sin match ⇒ `null` (no es un
  pago). Normalización: se quitan separadores colgantes (`"1."` → `"1"`); con
  coma **y** punto la coma es de miles (`"1,234.50"`); solo con coma, es decimal
  (`"25,50"`). Si el resultado es `null` o `<= 0` ⇒ `null`.
- **Nombre**, según `tipoApp` (case-insensitive, sobre `source.trim()`):
  - `YAPE`: `^(.*?)\s+te\s+(?:envió|envio|pagó|pago)(?:\s|$)`
  - `INTERBANK`: `^(.*?)\s+te\s+ha\s+plineado\b`
  - `BBVA`: `^(.*?)\s+te\s+pline[oó](?:\s|$)`

  Si queda vacío y `title` no está vacío ni contiene `"yape"`, se usa `title`.
- **codigoOperacion**: `"-"` por defecto. Solo para `YAPE` se busca
  `(?:operaci[oó]n|seguridad)\D*(\d+)`, con `""` si no hay match.

> Si cambias una regla, cámbiala en los **tres** sitios: el parser Kotlin, el
> parseo Dart y los dos tests espejo (`YapePaymentParserTest.kt` y
> `test/services/yape_notification_parser_test.dart`).

## Programación del worker

`YapeSyncWorker.schedule()` se llama desde `onNotificationPosted` y desde
`onListenerConnected` (al re-enlazar puede haber backlog de cuando el proceso
estaba muerto).

- `OneTimeWorkRequest`, constraint `NetworkType.CONNECTED`, backoff exponencial
  desde 10 s.
- `enqueueUniqueWork("yape-sync", APPEND_OR_REPLACE, …)`: los trabajos se
  encadenan y cada uno drena la cola completa, así que los sobrantes son no-ops
  baratos.
- **`setExpedited` solo desde API 31.** Por debajo, WorkManager ejecuta el
  trabajo expedited como foreground service y exige `getForegroundInfo()` más
  una notificación; sin eso el worker fallaría en runtime. En API < 31 el
  one-time igual se ejecuta apenas se cumplen las constraints.
- `MainActivity.configureFlutterEngine` registra además un `PeriodicWorkRequest`
  de respaldo cada 15 min (`"yape-sync-periodic"`, `KEEP`) que recupera el
  backlog si un one-time se perdió al morir el proceso.

WorkManager se inicializa solo vía `androidx.startup.InitializationProvider`
(viene en el manifiesto de `work-runtime`); no hace falta un `Application`
propio.

## Manejo de respuestas del POST

| Respuesta | Acción |
|---|---|
| `2xx` | Ack: fuera de la cola |
| `401` | Borra `sync_token`, corta el barrido y termina en `success()` — **no** reintenta en bucle ni pierde el item; la app reenviará tras el re-login |
| `5xx`, `408`, `429`, error de red / timeout | Deja el item en la cola y termina en `retry()` |
| Otro `4xx` | Deja el item en la cola pero **sin** `retry()`: reintentar el mismo body no cambiaría el resultado y entraría en un bucle de backoff. Lo resuelve la app al abrirse |

Un item cuyo `tipoApp` ya no está habilitado, o que no parsea como pago, se
saca de la cola sin postear.

El POST usa `HttpURLConnection` (sin OkHttp), timeouts de 15 s, con los mismos
headers que el interceptor de Dio: `Authorization: Bearer <token>` y
`PlatformRequest: mobile`.

## Batería y OEMs

`REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` en el manifiesto permite ofrecer al
usuario la exención de optimizaciones. La pantalla del replicador muestra la
tarjeta **solo** si ya concedió el acceso a notificaciones y aún no está exento;
nunca se fuerza en el arranque. Algunos OEM no exponen
`ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` y se cae a los ajustes generales.

En OEMs muy agresivos (MIUI, Huawei, Oppo, Vivo) y tras un "Forzar detención",
la entrega inmediata **no está garantizada**; el worker periódico la recupera al
reconectar.

## Pendiente conocido: duplicados en Plin

El backend (`PagoYapeServiceImpl.save`) deduplica por
`(empresa, codigoOperacion)` y devuelve el registro existente, **pero solo
cuando el código no es `"-"`**. Los Plin de BBVA e Interbank siempre llegan con
`"-"`, así que si el drenaje Dart y el worker postean el mismo item a la vez
(app en primer plano) el pago podría duplicarse.

El ack sincronizado por id reduce la ventana pero no la elimina: entre el
`peek` y el `ack` ambos pueden tener el mismo item en la mano. La solución
definitiva es deduplicar en el backend, por ejemplo por empresa + nombre +
monto + ventana de tiempo. **No** deduplicar en el cliente más allá del ack.

## Depuración

```bash
adb logcat -s YapeSyncWorker:D YapeListener:D
```

Pruebas físicas mínimas tras tocar este flujo:

1. Con permiso y captura activados, deslizar la app desde recientes; generar un
   pago: el POST debe llegar en segundos sin abrir la app.
2. Con el WiFi apagado, generar un pago y volver a encender: el worker debe
   reintentar y entregar.
3. Reabrir la app: el pago ya enviado no debe duplicarse.

Tests unitarios del parser:

```bash
android/gradlew -p android :app:testDebugUnitTest
```

El wrapper de Gradle necesita JDK 17 (`JAVA_HOME`), no el JDK por defecto del
sistema si es más nuevo.
