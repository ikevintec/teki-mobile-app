# Integración de Socket.IO — Teki Mobile App

## Descripción

El proyecto usa Socket.IO para recibir actualizaciones en tiempo real desde el servidor.
Cuando cocina o el sistema hace un cambio en una comanda, el servidor emite el evento
`commandRestaurant`; la app lo escucha y recarga las mesas automáticamente, sin necesidad
de hacer pull-to-refresh.

---

## Librería usada

**`socket_io_client` (Dart)** — cliente oficial de Socket.IO para Dart/Flutter.

| Paquete | Versión | Compatible con |
|---------|---------|----------------|
| `socket_io_client` | `^2.0.3+1` | Socket.IO v4.x |

> Se eligió por ser el cliente oficial, estar activamente mantenido y tener soporte
> nativo para las mismas opciones de configuración que el cliente JS (`transports`,
> `path`, `query`, `timeout`).

---

## Configuración de entorno

Las variables de conexión viven en el archivo `.env` (desarrollo) y `.env.production` (producción).

```
# .env (desarrollo)
API_URL=http://localhost:8080/api
WS_URL=https://sock.teki.pe
WS_PATH=/tekiwss

# .env.production (producción — completar con credenciales reales)
API_URL=https://your-api-url.com/api
WS_URL=https://sock.teki.pe
WS_PATH=/tekiwss
```

Estas variables se leen automáticamente a través de `flutter_dotenv` desde `lib/src/utils/contstants.dart`:

```dart
static String wsUrl  = dotenv.env['WS_URL']  ?? 'https://sock.teki.pe';
static String wsPath = dotenv.env['WS_PATH'] ?? '/tekiwss';
```

---

## Arquitectura

```
SocketService (singleton)
│
├── connect(officeCode)          — abre conexión con auth token + officeCode
├── on(SocketEvent)              — devuelve Stream<dynamic> para ese evento
└── disconnect()                 — cierra el socket

RestaurantMesasScreen
│
├── initState  → SocketService.connect() + suscribirse a commandRestaurant
├── listener   → _reload() cada vez que llega el evento
└── dispose    → cancelar suscripción + SocketService.disconnect()
```

### Parámetros de autenticación enviados al servidor

```dart
{
  'auth_token': '<JWT token desde SharedPreferences, sin el prefijo "Bearer ">',
  'officeCode': '<código del punto de venta activo>',
  'clientType': 'WEB',   // IMPORTANTE: el servidor filtra por 'WEB' para emitir eventos
}
```

> **¿Por qué `clientType: 'WEB'`?**
> En `sqs.js` el servidor filtra los sockets destino así:
> ```javascript
> clients.filter(s => s.handshake.query.clientType === 'WEB')
> ```
> Si se envía `'MOBILE'`, el servidor nunca emitirá `commandRestaurant` ni `orderRestaurant`
> a ese cliente. Cambiar este valor requeriría modificar el servidor.

---

## Eventos disponibles

Definidos en el enum `SocketEvent` (`lib/src/shared/services/socket_service.dart`):

| Enum | Valor en servidor | Descripción |
|------|------------------|-------------|
| `SocketEvent.commandRestaurant` | `commandRestaurant` | Cambio en una comanda (cocina, mozo) |
| `SocketEvent.orderRestaurant` | `orderRestaurant` | Cambio de estado en un pedido |

Para agregar un nuevo evento basta con añadirlo al enum:

```dart
enum SocketEvent {
  commandRestaurant('commandRestaurant'),
  orderRestaurant('orderRestaurant'),
  nuevoEvento('nuevoEvento');   // ← agregar aquí

  const SocketEvent(this.value);
  final String value;
}
```

---

## Cómo usar el servicio en una nueva pantalla

La suscripción debe crearse **síncronamente** en `initState`, antes de cualquier `await`.
Esto garantiza que el listener esté activo cuando llegue el evento — los `StreamController.broadcast()`
descartan eventos si no hay listeners en ese instante.

```dart
class _MiScreenState extends ConsumerState<MiScreen> {
  final _socketService = SocketService();
  StreamSubscription<dynamic>? _sub;

  @override
  void initState() {
    super.initState();

    // 1. Suscribirse primero, de forma síncrona
    _sub = _socketService
        .on(SocketEvent.commandRestaurant)
        .listen((_) { if (mounted) _recargar(); });

    // 2. Conectar después, en microtask
    Future.microtask(() {
      if (!mounted) return;
      _socketService.connect(officeCode: ref.read(sesionProvider).office?.codigo ?? '');
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _socketService.disconnect();
    super.dispose();
  }
}
```

### Referencia contada en `disconnect()`

`SocketService` lleva un contador interno de pantallas conectadas. Cuando varias
pantallas llaman a `connect()`, el socket no se cierra hasta que todas llaman a
`disconnect()`. Esto permite compartir la misma conexión sin cortes inesperados.

```
Pantalla A → connect()     → _connectionCount = 1, socket abre
Pantalla B → connect()     → _connectionCount = 2, socket reutilizado
Pantalla A → dispose/disconnect() → _connectionCount = 1, socket sigue activo
Pantalla B → dispose/disconnect() → _connectionCount = 0, socket se cierra
```

---

## Archivos clave

| Archivo | Descripción |
|---------|-------------|
| `lib/src/shared/services/socket_service.dart` | Servicio singleton de Socket.IO |
| `lib/src/utils/contstants.dart` | Variables de entorno (`wsUrl`, `wsPath`) |
| `lib/src/presentation/screens/restaurant/restaurant_mesas_screen.dart` | Pantalla de mesas con integración del socket |
| `.env` | Variables de desarrollo |
| `.env.production` | Variables de producción (completar) |

---

## Escalabilidad

- Para extender a más pantallas: instanciar `SocketService()` (singleton) y suscribirse al evento deseado.
- Para gestión global del socket (mantener conexión en toda la app): inicializar en el widget raíz y desconectar en el evento de logout.
- Para más eventos: agregar al enum `SocketEvent` y el servidor los emitirá automáticamente.
