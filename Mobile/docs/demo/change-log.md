# Demo Change Log

## 2026-03-26 Task 1

- Initialized `mobile_app` Flutter demo project skeleton.
- Added TDD smoke test at `mobile_app/test/widget_smoke_test.dart` for texts `智慧畜牧` and `登录`.
- Implemented minimal runnable app flow: `main()` -> `DemoApp` -> `DemoShell`.
- Added placeholder home UI with brand title and login button.
- Test command attempted as requested, but blocked by missing local `flutter` CLI.

## 2026-03-26 Task 2

- Added role model `DemoRole` with `owner` / `worker` / `ops`.
- Added permission gate `RolePermission.canEditFence()` for `fence-edit-action` visibility.
- Added login page `LoginPage` with required keys: `role-worker`, `role-owner`, `role-ops`, `login-submit`.
- Updated `DemoShell` login split flow: `owner`/`worker` enter business shell (`围栏页`), `ops` enters tenant-admin placeholder.
- Added TDD widget tests in `mobile_app/test/role_visibility_test.dart`:
  - worker login enters fence page and `fence-edit-action` is hidden.
  - owner login enters fence page and `fence-edit-action` is visible.
  - includes enum sanity check for `ops`.
- Verified with `flutter test test/role_visibility_test.dart` and full `flutter test`; both passed.

## 2026-03-26 Task 2 Fixes (Spec Review)

- Updated business-side post-login shell to include bottom navigation structure.
- Added fence navigation key `Key('nav-fence')` in business bottom nav.
- Updated role visibility tests to follow `login -> nav-fence -> 围栏页` path before permission assertions.
- Kept ops login routing unchanged (`租户后台占位`).
- Re-verified with target test and full test suite, all passed.

## 2026-03-26 Task 2 Quality Fixes

- Added ops diversion widget test: `role-ops -> login-submit` shows `租户后台占位`.
- Added negative assertions in ops test: `围栏` / `围栏页` / `fence-edit-action` are not visible.
- Stabilized fence navigation test interaction to tap by visible text `围栏` instead of icon-internal key targeting.
- Re-ran required command `flutter test test/role_visibility_test.dart && flutter test`, all passed.

## 2026-03-26 Task 3A

- Followed strict TDD for route skeleton:
  - RED: updated `mobile_app/test/widget_smoke_test.dart` to validate nav click flow and required keys.
  - Verified failing run: expected `page-dashboard` not found before implementation.
  - GREEN: minimally updated `mobile_app/lib/app/demo_shell.dart` to wire six placeholder pages.
- Added and connected six page placeholders:
  - business pages: `dashboard` / `map` / `alerts` / `mine` / `fence`
  - admin placeholder for `ops`
- Added required page keys and navigation reachability:
  - `Key('page-dashboard')` / `Key('page-map')` / `Key('page-alerts')`
  - plus `page-mine` / `page-fence` / `page-admin`
- Updated business bottom nav labels to support click navigation path:
  - `看板` / `地图` / `告警` / `我的` / `围栏`
- Verification:
  - `flutter test test/widget_smoke_test.dart` passed.
  - `flutter test` passed (including role visibility tests).

## 2026-03-26 Task 3A Fixes (Spec Review)

- Kept strict TDD loop:
  - RED: updated `mobile_app/test/widget_smoke_test.dart` to click nav keys (`nav-map`, `nav-alerts`, `nav-mine`, `nav-fence`, `nav-admin`) and assert all route pages are reachable.
  - Verified failing run before implementation (`nav-map` key not found).
  - GREEN: implemented minimal routing/file extraction changes until tests passed.
- Extracted six page skeletons into independent widget files:
  - `mobile_app/lib/features/pages/dashboard_page.dart`
  - `mobile_app/lib/features/pages/map_page.dart`
  - `mobile_app/lib/features/pages/alerts_page.dart`
  - `mobile_app/lib/features/pages/mine_page.dart`
  - `mobile_app/lib/features/pages/admin_page.dart`
  - `mobile_app/lib/features/pages/fence_page.dart`
- Updated `DemoShell` to wire six-page `IndexedStack` and business nav entries including admin tab.
- Added/standardized navigation keys for click tests:
  - `nav-dashboard` / `nav-map` / `nav-alerts` / `nav-mine` / `nav-admin` / `nav-fence`
- Verification:
  - `flutter test test/widget_smoke_test.dart` passed.
  - `flutter test` passed.

## 2026-03-26 Task 3A Quality Fixes

- Applied minimal role-based nav behavior in `DemoShell`:
  - `owner`: `dashboard/map/alerts/mine/fence/admin`
  - `worker`: `dashboard/map/alerts/mine/fence` (no `admin`)
  - `ops`: still direct to `AdminPage`
- Updated smoke tests to avoid hardcoding wrong behavior:
  - owner test keeps six-page reachability via nav keys and includes `nav-admin`
  - worker test explicitly asserts `nav-admin` is hidden (`findsNothing`)
- Kept strict TDD loop:
  - RED: new worker assertion failed first because `nav-admin` was visible.
  - GREEN: dynamic nav/page list implemented to satisfy role constraints.
- Verification:
  - `flutter test test/widget_smoke_test.dart && flutter test` passed.

## 2026-03-26 Task 3B

- Followed strict TDD for state-switch integration:
  - RED: updated `mobile_app/test/widget_smoke_test.dart` to assert six state switch keys:
    `state-switch-dashboard` / `state-switch-map` / `state-switch-alerts` / `state-switch-mine` / `state-switch-admin` / `state-switch-fence`.
  - Verified failing run before implementation (`state-switch-dashboard` not found).
  - GREEN: implemented minimal shared model/widget and connected six pages.
- Added unified state enum in `mobile_app/lib/core/models/view_state.dart`:
  - `normal` / `loading` / `empty` / `error` / `forbidden` / `offline`.
- Added reusable state switch component `mobile_app/lib/widgets/state_switch_bar.dart`.
- Integrated `StateSwitchBar` into six pages with required page-level keys:
  - dashboard / map / alerts / mine / admin / fence.
- Kept existing page keys and role permission behavior intact (including `fence-edit-action` visibility by role).

## 2026-03-27 Task 3C

- Added low-fi data layer: `demo_models.dart`, `demo_seed.dart`.
- Added widgets: `MetricCard`, `StatusTag`, `LowfiEmptyState`.
- Dashboard: four metric cards with stable keys (`dashboard-metric-*`), state-driven body.
- Map: `map-animal-filter`, `map-range-toggle` (24h/7d/30d), error-state list fallback `map-fallback-list`.
- Fence: `fence-add` / `fence-delete` for owner; retained `fence-edit-action`; title `围栏页` for tests.
- Alerts: role-aware actions (`alert-confirm` / `alert-handle` / `alert-archive` / `alert-batch`); `AlertsPage` now receives `role`.
- Admin: `tenant-open`, `tenant-toggle`, `tenant-license-adjust`; kept copy `租户后台占位` for ops flow.
- Extended `RolePermission` for alert action visibility.
- Smoke test: `核心操作入口按 Key 可见（owner）` for dashboard metric, map range, tenant license adjust.
- Verification: `flutter test` (all), `flutter analyze` (expected clean).

## 2026-03-27 Task 4

- **告警流程**：`AlertsPage` 增加 `_DemoAlertStage`（待处理→已确认→已处理→已归档）；按钮按阶段显隐；展示 Key `alert-status-confirmed` / `alert-status-handled` / `alert-status-archived`。
- **地图流程**：正常态地图摘要 `Text` 增加 Key `map-flow-summary`，便于断言筛选与区间切换结果。
- **围栏流程**：点击 `fence-edit-action` 设置本地状态并展示 `fence-flow-edit-saved`。
- **租户后台流程**：点击 `tenant-license-adjust` 展示 `tenant-license-demo-applied`。
- **测试**：新增 `mobile_app/test/flow_smoke_test.dart`（告警三键流、地图筛选+7d、围栏编辑、license 调整、worker 无后台、ops 直达后台）。
- Verification: `flutter analyze`, `flutter test test/flow_smoke_test.dart`, `flutter test` 全部通过。

---

**后续 ToDo（Shell / 路由 / 权限）**：见 [post-lowfi-follow-ups.md](./post-lowfi-follow-ups.md)（低保真 Demo 与上线 MVP 之间的显式欠账清单）。

## 2026-03-27 规格回填

- 在设计规格 `docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md` 增加 **12.10.5 Demo 与 MVP 边界及后续 ToDo**，并指向本目录 `post-lowfi-follow-ups.md`；附录 B 增加同上链接。

## 2026-03-27 Task 5（客户评审与交付说明）

- 新增 **`docs/demo/lowfi-client-review-script.md`**：10 分钟脚本、六类状态、四条流程、**保留项 / 修改项 / 新增项 / 冻结项** 模板及会后动作。
- 新增 **`docs/demo/acceptance-checklist.md`**：演示验收手工勾选表（与实施计划验收门槛对齐）。
- 规格 **`2026-03-26-smart-livestock-app-design.md`** 增加 **12.10.6 Demo 交付物与使用方式**（交付物表、`flutter run` / `analyze`+`test`）；附录 B 增加评审脚本与验收单链接。

## 2026-03-27 High-Fidelity Freeze

- 补充高保真验收门禁：
  - `mobile_app/test/widget_smoke_test.dart` 增加三大标杆页关键块检查。
  - `mobile_app/test/flow_smoke_test.dart` 增加围栏分组 / 模板 / 图层演示检查。
- 围栏页新增分组展示 Key：`fence-group-chip`。
- 新增 **`docs/qa/highfi-ux-acceptance.md`**：记录自动化门禁、手工演示项与**保留项 / 修改项 / 新增项 / 冻结项**。
- 高保真基线可作为 Phase 0 冻结版本，后续优先转入联调准备。
