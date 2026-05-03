# AGENTS.md — Guidance for Agentic Coding Agents

## Project Overview

Smart Livestock (智慧畜牧) is a Flutter mobile app for ranchers to manage cattle/sheep
via IoT devices (GPS trackers, rumen capsules, accelerometers). Current stage: **Phase 2a
complete (B2B admin, multi-farm, subscription infra)** — Phase 2b in design. Uses local mock data
(`APP_MODE=mock`) or a Node.js mock server (`APP_MODE=live`). No real backend yet.

## Build / Lint / Test Commands

All Flutter commands run from `mobile_app/`:

```bash
# Install dependencies
flutter pub get

# Run ALL tests
flutter test

# Run a SINGLE test file
flutter test test/widget_smoke_test.dart
flutter test test/app_architecture_test.dart
flutter test test/role_visibility_test.dart

# Run a subset of tests by name pattern
flutter test --name="owner"

# Static analysis (lint)
flutter analyze

# Run the app (mock data by default)
flutter run
flutter run --dart-define=APP_MODE=mock
flutter run --dart-define=APP_MODE=live

# Build web
flutter build web
```

Mock server lives in `backend/` (Node.js + Express 5, port 3001).

## Architecture Overview

```
mobile_app/lib/
├── app/           # App shell, router, session, mode switching, URL strategy
├── core/
│   ├── models/    # Domain models (demo_role, demo_models, view_state, subscription_tier, twin_models)
│   ├── data/      # Static mock seed (demo_seed.dart)
│   ├── api/       # api_cache, api_role, api_auth, api_http_client
│   ├── mock/      # Mock config & scenario definitions
│   ├── map/       # Map config (Leaflet)
│   ├── debug/     # Debug utilities
│   ├── theme/     # AppColors, AppSpacing, AppTypography, AppTheme
│   └── permissions/  # RolePermission static helpers
├── features/
│   ├── pages/     # Page widgets (twin_overview_page, map_page, alerts_page, …)
│   ├── auth/      # Login page
│   ├── admin/     # B2B admin dashboard (platform_admin)
│   ├── b2b_admin/ # B2B client console (b2b_admin): dashboard, farm list, contract
│   ├── tenant/    # Tenant CRUD, detail cards, devices/logs/stats controllers, trend chart
│   ├── subscription/ # Subscription plans, checkout, locked overlay
│   ├── farm_switcher/ # Farm switcher widget + controller
│   ├── worker_management/ # Subfarm worker management
│   ├── highfi/    # High-fidelity UI widgets
│   └── {module}/  # Each module: domain/ → data/ → presentation/
│       ├── domain/{module}_repository.dart      # Abstract repository
│       ├── data/mock_{module}_repository.dart   # Mock impl
│       ├── data/live_{module}_repository.dart   # Live (API) impl
│       └── presentation/{module}_controller.dart # Riverpod Notifier
└── widgets/       # Shared widgets (metric_card, empty_state, status_tag, pagination_bar)
```

### Key Files

| File | Purpose |
|------|---------|
| `app/app_route.dart` | `AppRoute` enum — single source of truth for paths, names, labels (34 routes) |
| `app/app_router.dart` | GoRouter config with auth redirect guard |
| `app/app_mode.dart` | `AppMode` enum (mock/live), toggled via `--dart-define` |
| `app/demo_app.dart` | Root widget, injects `ProviderScope` + `MaterialApp.router` |
| `app/demo_shell.dart` | Shell with role-based bottom navigation |
| `app/session/` | `AppSession` value object + `SessionController` Riverpod notifier |
| `app/expiry_popup_handler.dart` | Subscription expiry popup handling |
| `core/models/view_state.dart` | `ViewState` enum for page state switching |
| `core/models/demo_role.dart` | `DemoRole` enum (owner, worker, platformAdmin, b2bAdmin, apiConsumer) |
| `core/models/subscription_tier.dart` | `SubscriptionTier` enum (trial/basic/pro/enterprise) |
| `core/permissions/role_permission.dart` | Static permission checks per `DemoRole` |
| `core/api/api_cache.dart` | HTTP cache, preloaded at startup in live mode, scoped by role |
| `core/api/api_auth.dart` | API auth helpers (token management) |
| `core/api/api_http_client.dart` | HTTP client wrapper |

## Code Style Guidelines

### Imports

Order: Flutter SDK → third-party (`flutter_riverpod`, `go_router`) → project (`smart_livestock_demo/`).

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';
import 'package:smart_livestock_demo/features/dashboard/domain/dashboard_repository.dart';
```

### Naming Conventions

- **Files**: `snake_case.dart` — e.g., `dashboard_controller.dart`, `mock_map_repository.dart`
- **Classes**: `UpperCamelCase` — e.g., `DashboardController`, `HighfiCard`
- **Private classes** (widget helpers): leading underscore — e.g., `_NavItem`, `_DashboardFarmHeader`
- **Variables/functions**: `lowerCamelCase` — e.g., `dashboardRepositoryProvider`, `setViewState`
- **Provider names**: `{module}RepositoryProvider`, `{module}ControllerProvider`
- **Keys**: descriptive dash-separated strings — e.g., `'page-twin'`, `'nav-twin'`, `'login-submit'`, `'twin-metric-alert-pending'`

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
- Utility classes use private constructor: `const DemoSeed._();`
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
2. **Mock implementation** in `data/mock_*.dart` — returns static data from `DemoSeed`.
3. **Live implementation** in `data/live_*.dart` — reads from `ApiCache` at runtime.
4. **Controller** in `presentation/` — Riverpod `Notifier` that delegates to repository.

The repository provider switches on `appModeProvider`:

```dart
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock: return const MockDashboardRepository();
    case AppMode.live: return const LiveDashboardRepository();
  }
});
```

### State Management

- `flutter_riverpod` exclusively — no `setState`, no `ChangeNotifier`.
- `Provider` for read-only dependencies; `NotifierProvider` for mutable state.
- `ref.watch()` in `build()`; `ref.read()` in callbacks.
- Use `NotifierProvider.family` for parameterized state (e.g., tenant detail by id).

### UI Strings

- All user-facing text is **Chinese** (e.g., `'看板'`, `'告警'`, `'围栏'`, `'暂无看板数据'`).
- Keep strings inline (no i18n framework yet).

### Theme

- Material 3 via `AppTheme.light()`.
- Colors in `AppColors`, spacing in `AppSpacing`, typography in `AppTypography`.
- Reference theme tokens, never hardcode colors or sizes:

```dart
// Good
color: AppColors.danger
const SizedBox(height: AppSpacing.lg)

// Bad
color: Colors.red
const SizedBox(height: 16)
```

### Error Handling (Demo Stage)

- Use `ViewState` enum (normal/loading/empty/error/forbidden/offline) to switch UI; state is driven by repository/controller data, not manual demo controls.
- Error messages are descriptive Chinese strings, no stack traces shown.

### Testing Conventions

- Tests live in `mobile_app/test/`.
- Use `flutter_test` only; no additional test frameworks.
- Find widgets by `Key` (not by text) for stability.
- Every page and nav item has a well-known `Key` value.
- `DemoApp()` can be instantiated with `overrides` for provider injection.
- Test file naming: `{feature}_{aspect}_test.dart`.

```dart
testWidgets('owner sees admin nav', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-owner')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('nav-admin')), findsOneWidget);
});
```

## Roles & Permissions

| Role | `DemoRole` enum | Access |
|------|-----------------|--------|
| 牧场主 (Owner) | `owner` | All pages + admin + worker mgmt + subscription |
| 牧工 (Worker) | `worker` | Dashboard, Map, Alerts, Mine, Fence; alerts: acknowledge only |
| 平台管理员 (Platform Admin) | `platformAdmin` | Full tenant mgmt, contract CRUD, revenue, subscription services, API auth |
| B端客户管理员 (B2B Admin) | `b2bAdmin` | Overview, farm mgmt, contract, revenue, subfarm workers |
| API开发者 (API Consumer) | `apiConsumer` | API access only, no App UI |

Permission checks go through `RolePermission` static methods.

## Multi-Farm Context

- `FarmSwitcherController` manages active farm selection.
- Mock Server `farmContextMiddleware` reads `activeFarmTenantId` from request headers.
- Data stores filter results by farm tenant ID.
- `ApiCache` scopes preloading to the current farm.

## Feature Flags / Subscription Tiers

- `SubscriptionTier` enum: trial, basic, pro, enterprise.
- Mock Server `feature-flag.js` middleware gates features by tier.
- Frontend `ApiCache` filters data based on tier during preload.
- Locked features show overlay with upgrade prompt.

## Key Constraints

- **Mock Server as backend** — `APP_MODE=live` 时通过 HTTP 调用 Node.js Mock Server（端口 3001），数据层使用内存 Store 模块（`backend/data/*Store.js`），无持久化。
- **No secrets or API keys** in code.
- **No comments** in code unless user explicitly requests them.
- **Chinese UI text**, English variable/class names.
- Every new interactive element must have a `Key` for test access.
