# Teki Mobile App

Aplicación móvil Flutter del ecosistema **Teki** — sistema de punto de venta (POS) y facturación electrónica para el mercado peruano. Es el cliente móvil del backend `cbetfactback` (Spring Boot).

## Funcionalidades

- **Ventas / POS**: flujo de venta con múltiples métodos de pago, descuentos y devoluciones
- **Comprobantes electrónicos**: boletas y facturas (SUNAT), cotizaciones
- **Restaurante**: mesas, comandas, división de cuenta, cobro y notificaciones de cocina en tiempo real
- **Inventario**: stock, ajustes de inventario, almacenes
- **Compras y gastos**: compras, proveedores, gastos con categorías y pagos
- **Clientes y cuentas**: CRM básico, cuentas por cobrar y por pagar
- **Reportes**: dashboard con caja/balance/movimientos y ~11 reportes por dominio
- **Impresión**: comandas y comprobantes vía agente de impresión "Coffe" (ESC/POS o PDF)
- **Notificaciones push**: Firebase Messaging (platillo listo, pedido por cobrar, ventas)
- **WhatsApp**: envío de comprobantes y cotizaciones (Evolution API)

## Stack

| Área | Tecnología |
|------|-----------|
| Framework | Flutter (Dart ≥ 3.9) |
| Estado | Riverpod (`flutter_riverpod` + `hooks_riverpod`) |
| Navegación | GetX (solo rutas) |
| HTTP | Dio (interceptores de token y 401) |
| Tiempo real | Socket.IO (`socket_io_client`) |
| Push | Firebase Messaging + `flutter_local_notifications` |
| PDF / impresión | `pdf`, `printing`, `syncfusion_flutter_pdfviewer`, ESC/POS propio |

## Arquitectura

Clean Architecture en `lib/src/`:

```
lib/src/
├── data/            # Datasources remotos, repositorios (impl), modelos
├── domain/          # Interfaces de datasources y repositorios
├── presentation/    # Pantallas, secciones y widgets (55 features)
├── providers/       # Estado Riverpod agrupado por feature
├── shared/          # Servicios: socket, notificaciones, impresión, storage
├── routes/          # Rutas GetX + middleware de autenticación
└── utils/           # Cliente API, constantes, formateadores
```

Más detalle de arquitectura y convenciones en [CLAUDE.md](CLAUDE.md). El backlog de deuda técnica está en [MEJORAS.md](MEJORAS.md).

## Requisitos

- Flutter SDK (canal stable, Dart ≥ 3.9)
- Archivo `.env` en la raíz del proyecto:

```
API_URL=https://api.teki.pe/api
WS_URL=https://sock.teki.pe
WS_PATH=/tekiwss
PRINT_URL=<url del agente de impresión Coffe>
```

> ⚠️ Actualmente `.env` y `.env.production` apuntan ambos a **producción** y solo se carga `.env`. No existe entorno de desarrollo separado (ver MEJORAS.md).

- Configuración nativa de Firebase (`google-services.json` / `GoogleService-Info.plist`); `firebase_options.dart` no está generado.

## Comandos

```bash
flutter pub get          # Instalar dependencias
flutter run              # Ejecutar en modo desarrollo
flutter analyze          # Análisis estático
dart format .            # Formatear código
flutter test             # Tests
flutter build apk        # Build Android
flutter build ios        # Build iOS (ver TESTFLIGHT_GUIDE.md)
```

## Documentación adicional

- [CLAUDE.md](CLAUDE.md) — guía de arquitectura y convenciones para desarrollo
- [MEJORAS.md](MEJORAS.md) — backlog priorizado de deuda técnica y mejoras
- [TESTFLIGHT_GUIDE.md](TESTFLIGHT_GUIDE.md) — publicación en TestFlight
- [README_SOCKET.md](README_SOCKET.md) — detalle de la integración Socket.IO
