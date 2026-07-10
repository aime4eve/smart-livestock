# AGENTS.md — Guidance for Agentic Coding Agents

## Project Overview

Smart Livestock (智慧畜牧) is a Flutter mobile app for ranchers to manage cattle/sheep
via IoT devices (GPS trackers, rumen capsules, accelerometers). The app communicates with
a **Spring Boot 3 backend** (`smart-livestock-server/`) via a stateless REST API using JWT
authentication. A separate **Vue 3 developer portal** (`developer-portal/`) serves API consumers.

Current stage: **Phase 2b in progress** — multi-farm, subscription, B2B admin, platform admin
all functional against the real backend.

## Build / Lint / Test Commands

### Flutter app — run from `mobile_app/`

```bash
flutter pub get
flutter analyze
flutter test
flutter test test/features/fence/fence_hit_detection_test.dart   # single file
flutter test --name="owner"                                       # by pattern
flutter run
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:18080/api/v1
flutter build web
```

### Developer Portal — run from `developer-portal/`

```bash
npm install
npm run dev          # Vite dev server
npm run build        # production build → dist/
npm test             # vitest
```

### Spring Boot backend — run from `smart-livestock-server/`

```bash
./gradlew test
./gradlew bootRun                     # :8080
docker compose up                     # nginx :18080 → app :8080 + PG + Redis + RocketMQ
```

## Architecture Overview

```
mobile_app/lib/
├── app/
│   ├── app_route.dart          # AppRoute enum — 36 routes (single source of truth)
│   ├── app_router.dart         # GoRouter config with auth redirect guard
│   ├── demo_app.dart           # Root widget (ProviderScope + MaterialApp.router)
│   ├── demo_shell.dart         # Shell with role-based bottom nav + B2B admin rail
│   ├── expiry_popup_handler.dart
│   ├── session/
│   │   ├── app_session.dart    # AppSession value object
│   │   └── session_controller.dart  # Riverpod Notifier, calls ApiClient.login
│   ├── url_strategy.dart       # Web URL strategy (# vs path)
│   ├── url_strategy_stub.dart
│   └── url_strategy_web.dart
├── core/
│   ├── api/
│   │   ├── api_client.dart     # ApiClient singleton (base URL, JWT, farm-scoped CRUD)
│   │   ├── api_exception.dart  # Sealed ApiException hierarchy
│   │   └── jwt_storage.dart    # JWT persistence (flutter_secure_storage / shared_preferences)
│   ├── map/
│   │   ├── coord_transform.dart       # WGS84 ↔ GCJ-02
│   │   ├── map_config.dart            # Leaflet config
│   │   ├── map_constants.dart
│   │   ├── mbtiles_tile_provider.dart # Offline MBTiles support
│   │   ├── smart_tile_provider.dart   # Online + offline fallback
│   │   ├── mbtiles_tile_provider_io.dart
│   │   └── mbtiles_tile_provider_stub.dart
│   ├── models/
│   │   ├── core_models.dart     # FencePolygon, DashboardMetric, LivestockInfo, AlertItem, etc.
│   │   ├── subscription_tier.dart  # SubscriptionTier enum (basic/standard/premium/enterprise)
│   │   ├── twin_models.dart
│   │   ├── user_role.dart       # UserRole enum (owner/worker/platformAdmin/b2bAdmin/apiConsumer)
│   │   └── view_state.dart      # ViewState enum (normal/loading/empty/error/forbidden/offline)
│   ├── permissions/
│   │   └── role_permission.dart # Static permission checks per UserRole
│   ├── theme/
│   │   ├── app_colors.dart
│   │   ├── app_spacing.dart
│   │   ├── app_theme.dart       # Material 3 light theme
│   │   └── app_typography.dart
│   └── utils/
│       └── currency_formatter.dart
├── features/
│   ├── pages/                  # Top-level page widgets (dashboard, alerts, fence, twin, etc.)
│   │   └── widgets/            # Page-specific widgets (twin_scene_card)
│   ├── admin/                  # Platform admin (domain/data/presentation)
│   ├── alerts/                 # Alert list (domain/data/presentation)
│   ├── api_authorization/      # API key auth management
│   ├── auth/                   # Login page
│   ├── b2b_admin/              # B2B admin dashboard, farms, contract, revenue, workers
│   ├── contract_management/    # Contract CRUD
│   ├── dashboard/              # Dashboard metrics (domain/data/presentation)
│   ├── devices/                # Device management
│   ├── digestive/              # Digestive health
│   ├── epidemic/               # Epidemic prevention
│   ├── estrus/                 # Estrus detection
│   ├── farm_creation/          # Farm creation wizard (multi-step)
│   ├── farm_switcher/          # Farm switcher widget + controller
│   ├── fence/                  # Electronic fence management (domain/data/presentation)
│   ├── fever_warning/          # Fever warning
│   ├── highfi/                 # High-fidelity UI widgets (card, chart, device tile, stat tile, etc.)
│   ├── livestock/              # Livestock CRUD + map repository
│   ├── mine/                   # "My" profile page + API auth
│   ├── revenue/                # Revenue/billing
│   ├── stats/                  # Data statistics
│   ├── subscription/           # Subscription plans, checkout, locked overlay, tier card
│   ├── subscription_service_management/
│   ├── tenant/                 # Tenant CRUD, detail, edit, create pages
│   ├── twin_overview/          # Digital twin overview
│   └── worker_management/      # Subfarm worker management
└── widgets/                    # Shared widgets (metric_card, empty_state, status_tag, pagination_bar, coming_soon_page)
```

### Key Files

| File | Purpose |
|------|---------|
| `app/app_route.dart` | `AppRoute` enum — single source of truth for paths, names, labels (36 routes) |
| `app/app_router.dart` | GoRouter config with auth redirect guard, role-based routing |
| `app/demo_app.dart` | Root widget, injects `ProviderScope` + `MaterialApp.router` |
| `app/demo_shell.dart` | Shell with role-based bottom nav (owner/worker) + NavigationRail (b2bAdmin) |
| `app/session/app_session.dart` | `AppSession` immutable value object |
| `app/session/session_controller.dart` | `SessionController` Riverpod notifier, calls `ApiClient.login` |
| `core/api/api_client.dart` | `ApiClient` singleton — base URL, JWT headers, farm-scoped `farmGet/farmPost/farmPut/farmDelete` |
| `core/api/api_exception.dart` | Sealed `ApiException` hierarchy (Auth, Forbidden, QuotaExceeded, NotFound, Conflict, Validation, Server, Network) |
| `core/api/jwt_storage.dart` | JWT persistence (FlutterSecureStorage on native, SharedPreferences on web) |
| `core/models/user_role.dart` | `UserRole` enum (owner, worker, platformAdmin, b2bAdmin, apiConsumer) |
| `core/models/subscription_tier.dart` | `SubscriptionTier` enum (basic, standard, premium, enterprise) + `FeatureFlags` + `checkTierAccess` |
| `core/models/view_state.dart` | `ViewState` enum for page state switching |
| `core/permissions/role_permission.dart` | Static permission checks per `UserRole` |
| `features/farm_switcher/farm_switcher_controller.dart` | `FarmSwitcherController` — loads farms via API, manages active farm selection |

## Code Style Guidelines

### Imports

Order: Flutter SDK → third-party (`flutter_riverpod`, `go_router`, `http`) → project (`hkt_livestock_agentic/`).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/models/user_role.dart';
import 'package:hkt_livestock_agentic/features/dashboard/domain/dashboard_repository.dart';
```

### Naming Conventions

- **Files**: `snake_case.dart` — e.g., `dashboard_controller.dart`, `api_client.dart`
- **Classes**: `UpperCamelCase` — e.g., `DashboardController`, `HighfiCard`
- **Private classes** (widget helpers): leading underscore — e.g., `_NavItem`, `_FarmEmptyGuidance`
- **Variables/functions**: `lowerCamelCase` — e.g., `dashboardRepositoryProvider`, `setViewState`
- **Provider names**: `{module}XxxProvider` — e.g., `dashboardRepositoryProvider`, `sessionControllerProvider`

### Widget Patterns

- Always use `const` constructors; accept `super.key` (not `Key? key`).
- Use `ConsumerWidget` (not `StatelessWidget`) when reading providers.
- Private helper widgets as `_ClassName` inside the same file.
- Use `Key('descriptive-id')` on all major UI elements for testability.

```dart
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) { … }
}
```

### Models

- Immutable value objects with `const` constructors and `final` fields.
- Enums are simple; enhanced enums only when needed (like `AppRoute`).

```dart
class DashboardMetric {
  const DashboardMetric({required this.widgetKey, required this.title, required this.value});
  final String widgetKey;
  final String title;
  final String value;
}
```

### Repository Pattern

Every feature module follows:

1. **Abstract interface** in `domain/` — defines method signatures only.
2. **API implementation** in `data/` — calls `ApiClient` singleton.
3. **Controller** in `presentation/` — Riverpod `Notifier` that delegates to repository.

```dart
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return const DashboardApiRepository();
});
```

### State Management

- `flutter_riverpod` exclusively — no `setState`, no `ChangeNotifier`.
- `Provider` for read-only dependencies; `NotifierProvider` for mutable state.
- `ref.watch()` in `build()`; `ref.read()` in callbacks.

### UI Strings

- All user-facing text is **Chinese** (e.g., `'看板'`, `'告警'`, `'围栏'`, `'暂无看板数据'`).
- Keep strings inline (no i18n framework yet).

### Theme

- Material 3 via `AppTheme.light()`.
- Colors in `AppColors`, spacing in `AppSpacing`, typography in `AppTypography`.
- Reference theme tokens, never hardcode colors or sizes.

```dart
// Good
color: AppColors.danger
const SizedBox(height: AppSpacing.lg)

// Bad
color: Colors.red
const SizedBox(height: 16)
```

### Error Handling

- Use `ViewState` enum (normal/loading/empty/error/forbidden/offline) to switch UI.
- `ApiException` sealed hierarchy: `AuthException`, `ForbiddenException`, `QuotaExceededException`, `NotFoundException`, `ConflictException`, `ValidationException`, `ServerException`, `NetworkException`.
- Error messages are descriptive Chinese strings, no stack traces shown.

### Testing Conventions

- Tests live in `mobile_app/test/`.
- Use `flutter_test` only; no additional test frameworks.
- Find widgets by `Key` (not by text) for stability.
- Every page and nav item has a well-known `Key` value.
- `DemoApp()` can be instantiated with `overrides` for provider injection.
- Test file naming mirrors source: `{feature}/{aspect}_test.dart`.

```dart
testWidgets('owner sees admin nav', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('nav-admin')), findsOneWidget);
});
```

## API Client

- `ApiClient` singleton at `core/api/api_client.dart`.
- Default base URL: `http://127.0.0.1:18080/api/v1` (web) or `http://localhost:18080/api/v1` (native).
- Override via `--dart-define=API_BASE_URL=...`.
- JWT token stored in `JwtStorage` (flutter_secure_storage on native, SharedPreferences on web).
- Farm-scoped methods (`farmGet`, `farmPost`, `farmPut`, `farmDelete`) auto-prepend `/farms/{activeFarmId}`.

## Roles & Permissions

| Role | `UserRole` enum | Access |
|------|-----------------|--------|
| 牧场主 (Owner) | `owner` | All pages + admin + worker mgmt + subscription |
| 牧工 (Worker) | `worker` | Dashboard, Map, Alerts, Mine, Fence; alerts: acknowledge only |
| 平台管理员 (Platform Admin) | `platformAdmin` | Full tenant mgmt, contract CRUD, revenue, subscription services, API auth |
| B端客户管理员 (B2B Admin) | `b2bAdmin` | Overview, farm mgmt, contract, revenue, subfarm workers |
| API开发者 (API Consumer) | `apiConsumer` | API access only, no App UI |

Permission checks go through `RolePermission` static methods.

## Multi-Farm Context

- `FarmSwitcherController` loads farm list via `ApiClient.get('/farms')` and manages active farm.
- `ApiClient.setActiveFarmId()` scopes all farm-scoped API calls.
- `SessionController.updateActiveFarm()` persists active farm in session state.

## Subscription & Feature Flags

- `SubscriptionTier` enum: basic, standard, premium, enterprise.
- `FeatureFlags` class defines feature-to-tier mapping with shapes: `none`, `lock`, `limit`, `filter`.
- `checkTierAccess(tier, featureKey)` validates access.
- Locked features show `LockedOverlay` with upgrade prompt.
- Backend `feature-flag` middleware gates features by tier.

## Developer Portal

Vue 3 + Pinia + Vue Router SPA in `developer-portal/`:
- API key management, endpoint docs, usage dashboards, authorization review
- Authenticates against same Spring Boot backend
- Tested with Vitest + @vue/test-utils

## Key Constraints

- **Real backend** — Flutter app calls Spring Boot REST API (port 18080 via nginx). No mock server.
- **No secrets or API keys** in code.
- **No comments** in code unless user explicitly requests them.
- **Chinese UI text**, English variable/class names.
- Every new interactive element must have a `Key` for test access.
