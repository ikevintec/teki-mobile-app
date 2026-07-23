# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Teki mobile app (`teki_app`) is the Flutter client of the Teki ecosystem — a business management app for the Peruvian market: POS/sales, electronic invoicing (comprobantes), restaurant management, inventory, purchases, expenses, accounts receivable/payable, and reporting. It consumes the `cbetfactback` Spring Boot API.

- ~527 Dart files: presentation (231), data (197), domain (42), providers (33), shared (12), utils (9)
- Primary locale: Spanish (`es`); English supported as secondary

## Development Commands

```bash
flutter pub get                              # Install dependencies
flutter run                                  # Run the application
flutter build apk                            # Android production build
flutter build ios                            # iOS production build
flutter analyze                              # Static analysis
dart format .                                # Format code
flutter test                                 # Run tests (currently only 1 test file exists)
flutter pub run flutter_launcher_icons:main  # Regenerate launcher icons
```

## Architecture

Clean Architecture with three layers plus providers:

- `lib/src/data/` — remote datasources (`datasource/remote_*.dart`), repository implementations, models
- `lib/src/domain/` — abstract datasources and repositories (interfaces)
- `lib/src/presentation/` — screens, sections, widgets
- `lib/src/providers/` — Riverpod state, grouped by feature (19 folders)
- `lib/src/shared/services/` — cross-cutting services (socket, notifications, printing, storage)
- `lib/src/routes/` — GetX routes and middleware
- `lib/src/utils/` — API client, constants, formatters, helpers

Datasources and repositories are symmetric: each `data/datasource/remote_X.dart` implements a `domain/datasource/X_datasource.dart` interface, wrapped by `data/repositories/X_repository_impl.dart`.

### State Management
- **Riverpod** (`flutter_riverpod` + `hooks_riverpod`) is the state solution.
- A global `ProviderContainer` (`globalContainer` in `main.dart`) is used outside the widget tree (API client 401 handler, notification service, auth middleware).
- Mature pattern to follow for new features: Notifier + separate `_state.dart` file (see `providers/sale/customer/` and `providers/tickets_sale/`).

### Navigation
- **GetX** is used for navigation only (`Get.toNamed`), NOT for state.
- All routes are defined in `lib/src/routes/app_routes.dart`; every page gets `AuthMiddleware` applied.
- NOTE: `AuthMiddleware` only redirects logged-in users away from `/login`, `/splashScreen`, `/onboarding`. It does NOT block unauthenticated access to private routes — session enforcement relies on the API returning 401.
- Initial route is `/splashScreen`, which restores the session via `checkAuthStatus()`.

### API Client (`lib/src/utils/api_client.constant.dart`)
- Static Dio singleton `ApiClient.dio`, base URL from `Environment.apiUrl`, 30s timeouts.
- Request interceptor injects `Authorization: Bearer <token>` (read from SharedPreferences key `access_token`) and header `PlatformRequest: mobile`.
- On 401: global logout via `authStateProvider` with an anti-reentry flag; call `ApiClient.resetLogoutFlag()` after successful login (already done in `providers/auth/login.dart`).
- CAUTION: the WhatsApp datasource (`remote_whatsapp_datasource.dart`) builds its own Dio clients that do NOT share this 401 handling.

### Auth Flow
- `POST /auth/login` → `LoginResponse`; roles from `GET /auth/account/roles`.
- Session persisted in SharedPreferences under keys: `access_token`, `login`, `roles`, `configCompany` (plain text — see MEJORAS.md).
- `logout()` clears those keys, disposes notifications, and navigates to `/login`.
- Storage goes through `KeyValueStorageService` (`shared/services/`). Its impl only supports `int` and `String` — do not store other types.

### Realtime (Socket.IO)
- `shared/services/socket_service.dart` — singleton, connects to `Environment.wsUrl` + `Environment.wsPath`.
- Listened events: `commandRestaurant`, `orderRestaurant` (restaurant realtime flows). Connection is refcounted; `disconnect()` only closes at count 0.

### Push Notifications
- Firebase Messaging + `flutter_local_notifications` in `shared/services/notification_service.dart`.
- Token registered at `POST /notifications/register-token`. Tap navigation is dispatched by `data['type']`: `dish_desk_ready`, `order_ready`, `sale_update`.
- `firebase_options.dart` is not generated; Firebase init relies on native config files.

### Printing
- No direct Bluetooth printing. All physical printing is delegated over HTTP to an external print agent called **"Coffe"** (`Environment.printUrl`, `shared/services/print_coffe_service.dart`).
- Commands (restaurant) and comprobantes (invoices/boletas) are formatted as ESC/POS (`command_esc_pos_formatter.dart`, `invoice_esc_pos_formatter.dart`) or rendered as backend PDFs, depending on printer config per sale station.
- Auto-print behavior is controlled by `ConfigCompany` (`impresionAutomatica`, `clienteImpresion == 'COFFE'`, `imprimirBoletaLite`).

## Environment Configuration

- `flutter_dotenv`; `Environment.initEnvironment()` in `lib/src/utils/constants.dart` loads by build mode: **release → `.env.production`** (always production URLs), **debug/profile → `.env`** (developer's local config, gitignored).
- Variables: `API_URL`, `WS_URL`, `WS_PATH`, `PRINT_URL`.

## Feature Map (presentation/screens/)

- **Auth/boot**: splash_screen, onboarding, authentication (login/register/forgot)
- **Core**: dashboard (tabs: inicio, caja, balance, movimientos), management, analytics, settings, profile, notification, support, viewer (PDF)
- **Sales**: `sale` (current modular sale flow), `sales`, `pos_sales` (older flows — check MEJORAS.md before touching), invoice, comprobantes, cotizaciones, accounts_receivable (single screen parameterized `tipoCuenta: 'CC' | 'CP'`)
- **Products**: product/products/add_product, category, brand, unit
- **Restaurant**: restaurant (mesas, comanda, dividir, cobrador), orders_restaurant, push_notification_events
- **Purchases**: purchase, purchase_invoice, supplier, biller
- **Inventory**: inventory, inventory_adjustment, warehouse
- **Customers/users**: customer, add_user, user_role
- **Expenses**: expense, expense_list, expense_category, expense_payment, expense_invoice
- **Reports**: reports hub + ~11 domain-specific report screens

## Coding Conventions

- New screens: `feature_name/feature_name_main_screen.dart` with `feature_name_sections/` and `widgets/` subfolders, snake_case everywhere.
- New state: Riverpod Notifier + separate `_state.dart` file.
- All HTTP through `ApiClient.dio` (never create ad-hoc Dio instances).
- Use `debugPrint` (never `print`) and gate verbose logging behind `kDebugMode`.
- Spanish for user-facing strings; follow existing es-PE currency/date formats (`utils/formats.dart`, `utils/price_formatter.dart`).

## Known Gotchas

- File/directory names were normalized to snake_case in the 2026-07 naming batch (see MEJORAS.md P3). Class names inside those files were NOT renamed and may still carry typos (e.g. class in `teki_model/customer.dart` files).
- `lib/src/utils/constants.dart` holds two responsibilities: `ColorSchema` and `Environment` (split pending).
- Subfolder conventions are still mixed (`sections/` vs `*_sections/`, `widget/` vs `widgets/`) and feature names mix Spanish/English — policy pending in MEJORAS.md.

## Improvement Backlog

Known issues (security, env separation, god widgets, missing tests, naming cleanup) are mapped with priorities in [MEJORAS.md](MEJORAS.md). Check it before starting refactors to avoid duplicating planned work.
