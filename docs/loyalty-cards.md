# Tarjetas de fidelización en móvil — P1

Acceso: **Inicio → Más Opciones → Tarjetas de fidelización** (`/loyalty/cards`).

P1 incluye las tarjetas activas, detalle, QR público local, compartir enlace con el menú nativo y copiar enlace. El detalle vuelve a consultar la tarjeta antes de mostrar el QR. P2 (clientes, saldos e historial) queda pendiente. Compartir imagen del QR queda pendiente como mejora opcional.

## Configuración y acceso

- `/companies/config` debe devolver `permitirFidelizacion: true`.
- Permisos: `LOYALTI_CONFIG_VER` o `SUPER_USUARIO`. No requiere edición.
- El backend usa la empresa autenticada. Si la empresa seleccionada no coincide con la del usuario autenticado, el visor se bloquea para evitar consultar con el token de otra empresa.
- Los cambios de empresa, usuario, token o permisos invalidan los providers; las solicitudes se cancelan al destruirlos. Cerrar sesión revoca la configuración y los permisos locales.
- Backend requerido: protección de lectura y flag en `LoyaltyConfigApi` / `LoyaltyConfigServiceImpl`. No hay endpoints ni migraciones nuevos.

### Origen público

`LOYALTY_PUBLIC_BASE_URL` es independiente de `API_URL`. Se lee de `.env` en desarrollo y `.env.production` en release. También admite `--dart-define=LOYALTY_PUBLIC_BASE_URL=...` con prioridad.

Producción: `https://app.teki.pe`, confirmado por el dueño con el enlace `https://app.teki.pe/fidelizacion/aguanevai`.

En desarrollo, configurar en `.env` el origen público del frontend de pruebas accesible desde otro teléfono de la misma red. No usar `localhost`, la URL de `/api` ni copiar el origen de producción para apuntar registros de pruebas a clientes reales. Si falta una base válida, se conserva la consulta y se deshabilita la invitación.

El enlace resultante es `{base}/fidelizacion/{slug}`. QR, compartir y copiar usan el mismo valor. No contiene JWT ni identificadores de inscripción o Wallet. Las tarjetas inactivas o sin slug válido no permiten invitar.

## API reutilizada

- `GET /companies/config` (carga de configuración existente).
- `GET /loyalty/config/cards` (incluye inactivas; el móvil filtra activas).
- `GET /loyalty/config/cards/{id}` (detalle restringido por empresa).

No se llama a servicios de acumulación, canje, registro público ni mensajería al consultar.

## Pruebas reproducibles

```sh
flutter test test/datasources/remote_loyalty_test.dart test/providers/loyalty_provider_test.dart test/services/loyalty_link_service_test.dart test/widgets/loyalty_cards_screen_test.dart
flutter run -t test/previews/loyalty_preview.dart -d <simulador>
LOYALTY_QA_OUTPUT=/tmp/teki-loyalty-qa flutter drive --driver=test_driver/loyalty_p1_driver.dart --target=integration_test/loyalty_p1_test.dart -d <emulador>
```

La vista de prueba y la prueba nativa usan datos sintéticos y `example.com`, con un rótulo visible. La vista de prueba rechaza release. No prueban una cuenta real de Nevai ni el registro/Wallet del cliente.

## Demostración real pendiente de hardware/cuenta

1. Usar backend con el control de lectura instalado, usuario con permiso y empresa con fidelización habilitada.
2. Confirmar desde web que la tarjeta Nevai está activa y su slug es `aguanevai`.
3. En móvil, abrir el visor y Mostrar QR. Comprobar el enlace de producción indicado arriba.
4. Escanear con otro teléfono físico y comprobar el registro de esa tarjeta. Si se completa un registro real, hacerlo con autorización del dueño y datos destinados a la demostración.
5. La compra asociada, los sellos y Wallet pertenecen al flujo existente; abrir el visor no altera saldos ni garantiza actualización inmediata de Wallet.

No se publica ni despliega la app como parte de P1.
