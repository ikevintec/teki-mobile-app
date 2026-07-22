# MEJORAS.md — Backlog de deuda técnica

Mapa priorizado de mejoras identificadas en el análisis del 2026-07-21. Cada ítem indica archivos afectados y el criterio para darlo por cerrado. Marcar con `[x]` al completar.

---

## P0 — Seguridad (atender primero)

### 1. Logs filtran token y credenciales en producción ✅ (2026-07-21)
- [x] `lib/src/utils/api_client.constant.dart` — `LogInterceptor` ahora dentro de `if (kDebugMode)` y con `debugPrint`.
- [x] `remote_whatsapp_datasource.dart` — usa los interceptores compartidos de `ApiClient` (ver ítem 4).

### 2. Token de sesión en texto plano ✅ (2026-07-21)
- [x] Nuevo `shared/services/token_storage.dart` (`TokenStorage`): guarda `access_token` en keychain/keystore vía `flutter_secure_storage` (^10.3.1), con caché en memoria y **migración automática** del token legado en SharedPreferences (los usuarios no pierden sesión al actualizar).
- [x] `api_client`, `socket_service` y `providers/auth/login.dart` leen/escriben solo vía `TokenStorage`.
- Pendiente menor: `login`, `roles` y `configCompany` siguen en SharedPreferences (datos de perfil/config, menos sensibles que el token).

### 3. Middleware no protege rutas privadas ✅ (2026-07-21)
- [x] `auth_middleware.dart` — sin sesión y ruta fuera de `_publicRoutes` (`/splashScreen`, `/onboarding`, `/login`, `/register`, `/forgotPassword`) → redirect a `/login`. Prints eliminados.

### 4. Clientes Dio paralelos sin manejo de 401 ✅ (2026-07-21)
- [x] Nueva factory `ApiClient.defaultInterceptors()` (auth + logout en 401 + logs solo en debug); `_whatsappClient` y `_wsClient` la usan en lugar de sus interceptores duplicados.

---

## P1 — Configuración y bugs latentes

### 5. Separación de entornos inexistente
- [ ] `Environment.intiEnvironment()` (en `lib/src/utils/contstants.dart`) siempre carga `.env`; `.env.production` nunca se usa y ambos apuntan a producción. Correr localmente pega contra producción.
- **Cierre**: `.env` apunta a dev/staging, release carga producción (por `kReleaseMode` o `--dart-define`), documentado en README.

### 6. `KeyValueStorageServiceImpl` solo soporta `int` y `String` ✅ (2026-07-21)
- [x] Agregados los casos `bool` y `double`; el default (llamadas sin tipo, `T = dynamic`) se mantiene como `String` por compatibilidad y quedó documentado. Cubierto con tests en `test/shared/key_value_storage_test.dart`.

### 7. Errores tragados silenciosamente ✅ (2026-07-21)
- [x] `command_print_service.dart` — el fallo al obtener la comanda ahora loguea con `debugPrint` y muestra `errorNotification` al usuario.
- [x] `comprobante_print_service.dart` (`_fetchTicketPrint`) y `notification_service.dart` (`_decodePayload`) — logs agregados. (`_getAndSaveToken` ya logueaba correctamente.)

### 8. `clientType` del socket hardcodeado como `'WEB'`
- [ ] `lib/src/shared/services/socket_service.dart` — la app móvil se identifica como `WEB`. Verificar con backend antes de cambiar (puede haber lógica dependiente).
- **Cierre**: identifica `MOBILE` (o el valor acordado con backend).

### 9. Duplicación de la clave `'access_token'` ✅ (2026-07-21)
- [x] Nuevo `lib/src/utils/storage_keys.dart` con `StorageKeys` (`accessToken`, `login`, `roles`, `configCompany`, `fcmToken`); reemplazados todos los literales en `api_client.constant.dart`, `socket_service.dart`, `notification_service.dart` y `providers/auth/login.dart`.

### 10. `checkAuthStatus` demasiado agresivo
- [ ] `lib/src/providers/auth/login.dart` — si hay token pero falta `roles` o `configCompany` en storage, hace logout completo en vez de recuperar los datos del backend.
- **Cierre**: re-fetch de roles/config con token válido antes de desloguear.

---

## P2 — Mantenibilidad

### 11. God widgets (descomponer)

Estrategia por archivo, en dos fases separadas (un PR cada una):
- **Fase A** (mecánica): mover cada clase privada a su archivo bajo una subcarpeta, sin tocar lógica.
- **Fase B** (riesgo medio): extraer lógica de negocio del widget al provider correspondiente.

- [x] `caja_tab.dart` — **Fase A hecha (2026-07-21)**: 1,134 → 500 líneas; `TipoSelector`, `HistorialItem`, `ImprimirCajaModal`, `MovimientoItem` y `CurrencySelector` extraídos a `dashboard_tabs/caja/`. **Fase B hecha (2026-07-21)**: `fetchAndLoadDetail`/`loadDetail` viven en `CashRegisterNotifier`; la selección de moneda activa (`monedas`/`monedaActiva`) es ahora parte de `CashRegisterState`, con tests en `test/providers/cash_register_state_test.dart`.
- [x] `screens/restaurant/widgets/order_options_sheet.dart` — **Fase A hecha (2026-07-21)**: 2,228 → 543 líneas. Extraídos a `widgets/order_options/`: `OrderDetailDialog` (741 líneas, con `showOrderDetailDialog`), `AnularOrdenDialog`, `ActionTile`, `CommandaItemRow`, `CancelledItemsBar` y `order_info_cards.dart` (6 cards/rows). El archivo principal re-exporta `AnularOrdenDialog` y `showOrderDetailDialog` para los consumidores existentes. **Fase B hecha (2026-07-21)**: `finalizarCuenta` vive en `RestaurantNotifier` (el widget ya no instancia repositorios), y el loop de impresión de anulaciones es `CommandPrintService.printCancellation()` (reutilizable; el mismo patrón existe inline en `order_detail_dialog.dart` y `comanda_provider.dart` como candidatos a migrar). Pendiente menor: los diálogos de confirmación inline (~230 líneas) podrían extraerse como widgets, y `order_detail_dialog.dart` admite otro split (vistas de tabs).
- [x] `screens/restaurant/comanda/product_detail_sheet.dart` — **Fase A hecha (2026-07-21)**: 1,208 → 720 líneas; `showProductPricePicker`, `PreparacionesSection`, `GruposSection` y los sub-widgets extraídos a `comanda/product_detail/`. **Fase B hecha (2026-07-22)**: validación, cálculo de extras y armado de opciones viven en `providers/restaurant/comanda_item_form.dart` (`ComandaItemForm`, lógica pura) con 12 tests en `test/providers/comanda_item_form_test.dart`. Archivo final: 643 líneas.
- [x] `screens/sale/sale_info/widget/payment_widget.dart` — **Fase A hecha (2026-07-21)**: 963 → 674 líneas; `PaymentEntry`, `PaymentMethodRow` y `CreditoTab` extraídos a `sale_info/widget/payment/`. **Fase B hecha (2026-07-22)**: `TicketNotifier.pagarCuentaRestaurante(checkId)` arma el Check y hace el `updateCheck`; `TicketNotifier.mergeTicketResponse(response)` combina el ticket local con la respuesta SUNAT. El widget solo navega, invalida providers y auto-imprime. Archivo final: 634 líneas. ⚠️ Smoke test obligatorio antes de release: pago de cuenta de restaurante y venta normal (contado + crédito).
- [x] `providers/formularios/product_form.dart` — **Fase A hecha (2026-07-21)**: 842 → ~460 líneas siguiendo el patrón del repo (Notifier + state separado): `product_form_state.dart` (`ProductFormState` + `ProductImageDraft`, re-exportado desde `product_form.dart`) y `product_form_images.dart` (mixin `ProductFormImages` con todo el manejo de imágenes, como `part` para conservar acceso a `state`). También se eliminó un `toString()` muerto con TODO.
- **Cierre**: ningún archivo de presentación > ~500 líneas; secciones extraídas a widgets.

### 12. Features duplicados / código muerto de plantilla ✅ (2026-07-22)

Contexto: la app se construyó sobre la plantilla Flutter "inventual"; quedaban restos inalcanzables.

- [x] **Eliminados 31 archivos / 5,345 líneas de plantilla muerta** (verificado: rutas jamás navegadas + cero importadores + fecha de alta en el commit inicial):
  - Pantallas completas: `pos_sales/`, `management/`, `warehouse/`, `notification/`, `support/` (con sus rutas `posSales`, `management`, `warehouse`, `addWarehouse`, `notification`, `notificationContent`, `support` quitadas de `app_routes.dart`)
  - Huérfanos en cascada: `support_discussion_model`, `notification_model`, `product_list_model`, `warehouse_model`, `user_list_model`, `customer_list_model`, `customer_list_section`, `update_customer_section`, `carousel_section`, `edit_profile_section`, `dropdown/drop_down`, `dropdown/expanden_list_animation`, `dropdown/scrolbar`
  - Bloques comentados del menú que referenciaban rutas eliminadas
- [x] Falsas alarmas (pares complementarios, ambos en uso): `sale/` (flujo de venta) vs `sales/` (historial/devoluciones); `product/` (form crear/editar) vs `products/` (listado); `ver_quotations_screen` (listado) vs `view_quotation_screen` (detalle).
- [ ] **Código Teki muerto** (no plantilla — sin referencias, decidir con el equipo si se elimina o es trabajo en progreso): `enums/client_whatsapp_type.dart`, `providers/files/image.dart`, `response/ticket_sale_serie_numero.dart`, `general/optional.dart`, `teki_model/totales_forma_pagos.dart`, `product/widget/expandable_price_card.dart`, `sale/products/widgets/quantity_selector.dart`, `widgets/text_field/quantity_field_selection.dart`, `sale_info/widget/payment_card_widget.dart`, `comprobantes/comprobante_screen/product_list.dart`.

### 13. `print()` de debug en producción ✅ (2026-07-21)
- [x] Los 24 `print` restantes en 8 archivos (remote_ticket_sale, whatsapp_provider, product_form, price, upload_image, comprobantes, products_sale_notifier_setters) → `debugPrint`; los del middleware y los interceptores se eliminaron en el PR de seguridad.
- [x] `avoid_print` elevado a **error** en `analysis_options.yaml` — un `print` nuevo ahora rompe `flutter analyze`.

### 14. Sin tests (1 archivo para ~86k líneas)
- [x] **Fase 1 hecha (2026-07-21)** — 52 tests en 6 archivos, todos en verde:
  - `test/shared/invoice_esc_pos_formatter_test.dart` — boleta completa, NV sin QR/IGV, modo lite, totales condicionales, columnas 58/80mm, apertura de gaveta
  - `test/shared/command_esc_pos_formatter_test.dart` — comanda completa, flags `ocultar*`, anulación con motivo, propina, logo, separadores por ancho
  - `test/utils/price_test.dart` — `getPriceProduct`: por defecto, IGV, tramos de mayoreo, precios por punto de venta, recargo por item
  - `test/utils/formats_test.dart`, `test/utils/price_formatter_test.dart`, `test/shared/key_value_storage_test.dart`
  - Se eliminó `test/widget_test.dart` (boilerplate del contador de Flutter, siempre fallaba)
- [ ] Fase 2: notifiers del flujo de venta (`sale_provider.dart`, `products_sale_notifier_setters.dart`).

### 15. Doble scope de providers en el arranque
- [ ] `main.dart` — `UncontrolledProviderScope(globalContainer)` + `ProviderScope` anidado puede crear dos instancias del mismo provider según desde dónde se lea.
- **Cierre**: un solo scope (el uncontrolled con `globalContainer`).

### 16. Comentario/código obsoleto
- [ ] `auth_repository_impl.dart` — comentario "Return a dummy user for demonstration purposes".
- [ ] `main.dart` — decidir sobre `firebase_options.dart` (generarlo con `flutterfire configure` o documentar que se usa config nativa).

---

## P3 — Nomenclatura (batch de renames — hacerlo en un solo PR)

> ✅ **Batch ejecutado el 2026-07-21**: 77 archivos y 5 directorios renombrados con `git mv` + fix de imports. `flutter analyze`: 0 errores; lints `file_names` pasaron de 69 a 0 (issues totales 329 → 260, el resto preexistente). Los **nombres de clase** dentro de los archivos NO se tocaron (p. ej. la clase de `cutomer.dart` conserva su nombre) — queda como tarea aparte.

### Typos en archivos/carpetas
- [x] `utils/contstants.dart` → `constants.dart`
- [ ] Separar `ColorSchema` de `Environment` en `utils/constants.dart` (pendiente — es cambio de estructura, no de nombre)
- [x] `providers/products/profucts.dart` → `products.dart`
- [x] `providers/sale/products/helpers/tciket_detail_helper.dart` → `ticket_detail_helper.dart`
- [x] `screens/comprobantes/ver_comprbantes.dart` → `ver_comprobantes.dart`
- [x] `screens/comprobantes/comprobante_screen.dart/` (directorio) → `comprobante_screen/`
- [x] `data/repositories/customer_repository_imp.dart` → `customer_repository_impl.dart`
- [x] `domain/repositories/sale_station_repositoy.dart` → `sale_station_repository.dart`
- [x] `screens/customer_reports/customer_reoprts_sections/` → `customer_reports_sections/`
- [x] `widgets/floating_aciton_button/` → `floating_action_button/`
- [x] `teki_model/openigHourDetail.dart` → `opening_hour_detail.dart`, `cutomer.dart` → `customer.dart`, `general/exhange.dart` → `exchange.dart`, `aditionalField.dart` → `additional_field.dart`
- [x] `Environment.intiEnvironment()` → `initEnvironment()`

### camelCase → snake_case
- [x] Todos los datasources/repositorios/modelos camelCase (~60 archivos en `teki_model/`, `remote_saleStation.dart`, `remote_monthlyMovement.dart`, `remote_monthlySales.dart`, `monthlyMovement_impl.dart`, `monthlysales_impl.dart`, domain `monthlyMovement_*`/`monthlySales_*`)
- [x] `screens/sales/salesSections/` → `sales_sections/`; `warehouse-reports_sections/` → `warehouse_reports_sections/`
- [x] `expense_category_main_Screen.dart`, `horizontal_customer_report_table_Section.dart`, `custom_search_Field.dart`, `updateSupplierSection.dart` → snake_case
- [x] Archivos con guion: `product-list_section.dart` → `product_list_section.dart`, `sale_generate_invoice-section.dart` → `sale_generate_invoice_section.dart`
- ~~`sale_station_Repository_impl.dart`~~ — no existía; ya estaba en snake_case

### Convenciones a unificar
- [x] Sufijos: `domain/datasource/sale_station.dart` → `sale_station_datasource.dart`
- [ ] Clases con typo dentro de archivos renombrados (p. ej. clase de `customer.dart`, `opening_hour_detail.dart`) — renombrar símbolos, no solo archivos
- [ ] Subcarpetas: estandarizar `*_sections/` y `widgets/` (hoy conviven `sections/`, `widget/`, `profile_section/`)
- [ ] Idioma: decidir política español/inglés para nombres de features (hoy conviven `cotizaciones`/`comprobantes`/`comanda` con el resto en inglés)

---

## Pendiente en backend (cbetfactback) — acordado atacar al final

- [ ] **Validar caja CERRADA en `saveCashRegisterDetailAsDto`** (crear y editar movimientos): hoy solo la UI lo impide; cualquier cliente puede inyectar movimientos en cajas arqueadas. Contemplar la excepción `CAJA_EDITAR_CIERRE` que la web usa para editar tras el cierre.
- [ ] **Reponer el `@PreAuthorize('CAJA_INGRESO_EGRESO_EDITAR')` comentado** en el PUT de `/cash-register-detail` (CashRegisterDetailApi.java:204): cualquier usuario autenticado puede editar movimientos.

## Orden sugerido de ataque

1. **P0 completo** (items 1–4): bajo riesgo, alto impacto, cambios pequeños.
2. **Item 5** (entornos) antes de cualquier desarrollo local nuevo.
3. **Items 6–10** según se toque cada área.
4. **Item 13 + regla `avoid_print`** (rápido, evita regresiones).
5. **Item 14 fase 1** (tests de formatters/utils) antes de refactors grandes.
6. **Item 11** (god widgets) por archivo, empezando por `order_options_sheet.dart`.
7. **P3** al final, en un PR mecánico único.
