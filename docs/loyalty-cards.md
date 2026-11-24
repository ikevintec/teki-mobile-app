# Tarjetas de fidelización en móvil — P1 y P2

Acceso: **Inicio → Fidelización** (`/loyalty/cards`).

P1 incluye las tarjetas activas, detalle, QR público local, compartir enlace con el menú nativo y copiar enlace. El detalle vuelve a consultar la tarjeta antes de mostrar el QR. P2 incluye clientes por tarjeta, búsqueda y paginación, detalle de saldos, movimientos de puntos y cupones emitidos. Compartir imagen del QR queda pendiente como mejora opcional.

## Configuración y acceso

- `/companies/config` debe devolver `permitirFidelizacion: true`.
- P1 requiere `LOYALTI_CONFIG_VER` o `SUPER_USUARIO`. P2 agrega `LOYALTI_CUSTOMERS_VER` para los inscritos y `LOYALTI_COUPONS_VER` para consultar cupones. No requiere edición ni concede permisos automáticamente.
- El backend usa la empresa autenticada. Si la empresa seleccionada no coincide con la del usuario autenticado, el visor se bloquea para evitar consultar con el token de otra empresa.
- Los cambios de empresa, usuario, token o permisos invalidan los providers; las solicitudes se cancelan al destruirlos. Cerrar sesión revoca la configuración y los permisos locales.
- Backend requerido: protección de lectura y flag en tarjetas, clientes y cupones; detalle de inscripción enriquecido con identidad de cliente y programa. No hay endpoints ni migraciones nuevos.

### Origen público

`LOYALTY_PUBLIC_BASE_URL` es independiente de `API_URL`. Se lee de `.env` en desarrollo y `.env.production` en release. También admite `--dart-define=LOYALTY_PUBLIC_BASE_URL=...` con prioridad.

Producción: `https://app.teki.pe`, confirmado por el dueño con el enlace `https://app.teki.pe/fidelizacion/aguanevai`.

En desarrollo, configurar en `.env` el origen público del frontend de pruebas accesible desde otro teléfono de la misma red. No usar `localhost`, la URL de `/api` ni copiar el origen de producción para apuntar registros de pruebas a clientes reales. Si falta una base válida, se conserva la consulta y se deshabilita la invitación.

El enlace resultante es `{base}/fidelizacion/{slug}`. QR, compartir y copiar usan el mismo valor. No contiene JWT ni identificadores de inscripción o Wallet. Las tarjetas inactivas o sin slug válido no permiten invitar.

## API reutilizada

- `GET /companies/config` (carga de configuración existente).
- `GET /loyalty/config/cards` (incluye inactivas; el móvil filtra activas).
- `GET /loyalty/config/cards/{id}` (detalle restringido por empresa).

- `GET /loyalty/customers?idLoyaltyConfig={tarjeta}&filtro={texto}&pageNumber={pagina}&perPage=20`.
- `GET /loyalty/customers/{idInscripcion}`. Devuelve identidad y saldos de esa inscripción.
- `GET /loyalty/customers/{idInscripcion}/movimientos?pageNumber={pagina}&perPage=20`.
- `GET /loyalty/coupons?idLoyaltyCustomer={idInscripcion}&esGlobal=false&pageNumber={pagina}&perPage=20`.

No se llama a servicios de acumulación, canje, registro público ni mensajería al consultar.

## Lectura de P2

Ruta: **Tarjeta → Clientes de esta tarjeta → Cliente**. La consulta y la caché distinguen empresa, tarjeta e inscripción (`LoyaltyCustomer.id`); no utilizan solo `Customer.id`.

- Búsqueda por nombre, documento o teléfono, con espera de 350 ms, cancelación y descarte de respuestas anteriores. Páginas de 20 y total informado por el servidor.
- El nombre del cliente y de su tarjeta quedan visibles al desplazar el detalle. Refrescar vuelve a leer los saldos; la hora indicada es de consulta, no una fecha de actualización inventada del servidor.
- Los sellos son históricos. El avance del ciclo es `sellos % sellosParaPremio`, solo para presentación y si ambos datos son válidos. Al completar 10 de 10, el siguiente ciclo empieza en 0; no implica un cupón disponible.
- Los puntos disponibles y los acumulados históricos se muestran separados. Los campos no informados se indican como no disponibles, sin convertirlos en cero.
- Movimientos muestra exclusivamente puntos, con signo, tipo, proceso, fecha y referencia disponible. No es una auditoría completa de sellos ni de todos los canjes.
- Cupones emitidos consulta únicamente los personales de esa inscripción, con su permiso separado. Muestra el estado registrado y sus fechas. Si un cupón pendiente tiene una fecha de vencimiento ya superada, lo indica sin modificar el estado ni confirmar disponibilidad de canje.
- No hay emisión manual, ajustes ni canjes desde estas pantallas.

La auditoría individual de sellos/compras no está expuesta por el contrato actual y requiere un trabajo separado de backend.

## Pruebas reproducibles

```sh
flutter test test/datasources/remote_loyalty_test.dart test/providers/loyalty_provider_test.dart test/services/loyalty_link_service_test.dart test/widgets/loyalty_cards_screen_test.dart
flutter test test/providers/loyalty_customers_provider_test.dart test/widgets/loyalty_customers_screen_test.dart
flutter run -t test/previews/loyalty_preview.dart -d <simulador>
flutter run -t test/previews/loyalty_p2_preview.dart -d <simulador>
LOYALTY_QA_OUTPUT=/tmp/teki-loyalty-qa flutter drive --driver=test_driver/loyalty_p1_driver.dart --target=integration_test/loyalty_p1_test.dart -d <emulador>
LOYALTY_QA_OUTPUT=/tmp/teki-loyalty-qa flutter drive --driver=test_driver/loyalty_p1_driver.dart --target=integration_test/loyalty_p2_test.dart -d <emulador>
```

La vista de prueba y la prueba nativa usan datos sintéticos y `example.com`, con un rótulo visible. La vista de prueba rechaza release. No prueban una cuenta real de Nevai ni el registro/Wallet del cliente.

En Android se verificó el recorrido P2 con `flutter drive --no-dds` para evitar un bloqueo de conexión del depurador del emulador.

## Demostración real pendiente de hardware/cuenta

1. Usar backend con el control de lectura instalado, usuario con permiso y empresa con fidelización habilitada.
2. Confirmar desde web que la tarjeta Nevai está activa y su slug es `aguanevai`.
3. En móvil, abrir el visor y Mostrar QR. Comprobar el enlace de producción indicado arriba.
4. Escanear con otro teléfono físico y comprobar el registro de esa tarjeta. Si se completa un registro real, hacerlo con autorización del dueño y datos destinados a la demostración.
5. La compra asociada, los sellos y Wallet pertenecen al flujo existente; abrir el visor no altera saldos ni garantiza actualización inmediata de Wallet.

No se publica ni despliega la app como parte de estas entregas.
