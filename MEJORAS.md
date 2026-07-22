# MEJORAS.md — Backlog de deuda técnica

Mapa priorizado de mejoras identificadas en el análisis del 2026-07-21. Cada ítem indica archivos afectados y el criterio para darlo por cerrado. Marcar con `[x]` al completar.

---

## P0 — Seguridad (atender primero)

### 1. Logs filtran token y credenciales en producción
- [ ] `lib/src/utils/api_client.constant.dart` — `LogInterceptor` con `requestHeader`, `requestBody` y `responseBody` activos, sin condicionar a `kDebugMode`. Imprime el Bearer token y el body del login.
- [ ] `lib/src/data/datasource/remote_whatsapp_datasource.dart` — mismo problema en sus clientes Dio propios.
- **Cierre**: interceptores de log envueltos en `if (kDebugMode)`; ningún `print` crudo de requests.

### 2. Token de sesión en texto plano
- [ ] `access_token`, `login`, `roles`, `configCompany` se guardan en `SharedPreferences` sin cifrar.
- **Cierre**: migrar al menos `access_token` a `flutter_secure_storage`, encapsulado en `KeyValueStorageService`.

### 3. Middleware no protege rutas privadas
- [ ] `lib/src/routes/middleware/auth_middleware.dart` — solo redirige usuarios logueados fuera de login/splash/onboarding; un usuario sin sesión puede navegar a rutas internas (la protección real depende del 401 del backend). Además tiene `print()` de debug.
- **Cierre**: sin sesión y ruta privada → redirect a `/login`; prints eliminados.

### 4. Clientes Dio paralelos sin manejo de 401
- [ ] `remote_whatsapp_datasource.dart` crea `_whatsappClient` y `_wsClient` propios que no comparten el logout automático en 401 del `ApiClient`.
- **Cierre**: reutilizar `ApiClient.dio` o extraer los interceptores compartidos a una factory común.

---

## P1 — Configuración y bugs latentes

### 5. Separación de entornos inexistente
- [ ] `Environment.intiEnvironment()` (en `lib/src/utils/contstants.dart`) siempre carga `.env`; `.env.production` nunca se usa y ambos apuntan a producción. Correr localmente pega contra producción.
- **Cierre**: `.env` apunta a dev/staging, release carga producción (por `kReleaseMode` o `--dart-define`), documentado en README.

### 6. `KeyValueStorageServiceImpl` solo soporta `int` y `String`
- [ ] `lib/src/shared/services/key_values_storage_impl.dart` — cualquier otro tipo cae al default como `String` y revienta con cast error en runtime.
- **Cierre**: soporte de `bool`/`double` o error explícito en tiempo de desarrollo.

### 7. Errores tragados silenciosamente
- [ ] `command_print_service.dart` — `catch (_) { return; }` al obtener la comanda: los fallos de impresión desaparecen sin rastro.
- [ ] `comprobante_print_service.dart` (`_fetchTicketPrint`) y `notification_service.dart` (`_getAndSaveToken`) — capturas silenciosas similares.
- **Cierre**: log del error (aunque el flujo continúe) y, en impresión, feedback al usuario.

### 8. `clientType` del socket hardcodeado como `'WEB'`
- [ ] `lib/src/shared/services/socket_service.dart` — la app móvil se identifica como `WEB`. Verificar con backend antes de cambiar (puede haber lógica dependiente).
- **Cierre**: identifica `MOBILE` (o el valor acordado con backend).

### 9. Duplicación de la clave `'access_token'`
- [ ] Literal repetido en `api_client.constant.dart`, `socket_service.dart`, `notification_service.dart` y `remote_whatsapp_datasource.dart`.
- **Cierre**: constante única compartida (p. ej. `StorageKeys.accessToken`).

### 10. `checkAuthStatus` demasiado agresivo
- [ ] `lib/src/providers/auth/login.dart` — si hay token pero falta `roles` o `configCompany` en storage, hace logout completo en vez de recuperar los datos del backend.
- **Cierre**: re-fetch de roles/config con token válido antes de desloguear.

---

## P2 — Mantenibilidad

### 11. God widgets (descomponer)
- [ ] `screens/restaurant/widgets/order_options_sheet.dart` — **2,228 líneas**
- [ ] `screens/restaurant/comanda/product_detail_sheet.dart` — 1,208
- [ ] `screens/dashboard/dashboard_tabs/caja_tab.dart` — 1,134
- [ ] `screens/sale/sale_info/widget/payment_widget.dart` — 963
- [ ] `providers/formularios/product_form.dart` — 842
- **Cierre**: ningún archivo de presentación > ~500 líneas; secciones extraídas a widgets.

### 12. Features duplicados / migraciones a medias
- [ ] Determinar cuál es legacy entre `sale` vs `sales` vs `pos_sales`, y entre `product` vs `products`.
- [ ] `cotizaciones` tiene dos pantallas de ver: `ver_quotations_screen.dart` y `view_quotation_screen.dart`.
- **Cierre**: legacy identificado, marcado como deprecated y con plan de eliminación.

### 13. `print()` de debug en producción
- [ ] `remote_ticket_sale.dart` (líneas ~180–255, prints con emojis), `utils/price.dart:48`, `auth_middleware.dart`, `api_client.constant.dart:67`, `remote_whatsapp_datasource.dart:49`.
- **Cierre**: `print` → `debugPrint` o eliminados; regla `avoid_print` activada en `analysis_options.yaml`.

### 14. Sin tests (1 archivo para ~86k líneas)
- [ ] Empezar por lógica pura sin UI: `invoice_esc_pos_formatter.dart` (516 líneas), `command_esc_pos_formatter.dart` (327), `utils/price.dart`, `utils/formats.dart`, `KeyValueStorageServiceImpl`.
- [ ] Luego: notifiers del flujo de venta (`sale_provider.dart`, `products_sale_notifier_setters.dart`).
- **Cierre (fase 1)**: formatters ESC/POS y utils de precio con cobertura de casos principales.

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

## Orden sugerido de ataque

1. **P0 completo** (items 1–4): bajo riesgo, alto impacto, cambios pequeños.
2. **Item 5** (entornos) antes de cualquier desarrollo local nuevo.
3. **Items 6–10** según se toque cada área.
4. **Item 13 + regla `avoid_print`** (rápido, evita regresiones).
5. **Item 14 fase 1** (tests de formatters/utils) antes de refactors grandes.
6. **Item 11** (god widgets) por archivo, empezando por `order_options_sheet.dart`.
7. **P3** al final, en un PR mecánico único.
