# 智慧畜牧低保真 Demo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 24 小时内交付可点击 Flutter 低保真 Demo，用于客户确认页面范围、关键流程、角色权限与异常状态，不接真实后端接口。

**Architecture:** 采用“演示壳层 + 页面模块 + 本地假数据 + 场景切换”结构。`main.dart` 只负责路由和全局状态入口；每个页面独立管理展示与交互；角色权限通过本地 `RolePermission` 映射控制可见项与操作按钮；全局状态通过统一枚举驱动（正常/加载/空/错误/无权限/离线）。

**Tech Stack:** Flutter、Dart、Material 3、flutter_test

---

## 0. 文件结构（先定边界）

**Create:**
- `mobile_app/pubspec.yaml`
- `mobile_app/lib/main.dart`
- `mobile_app/lib/app/demo_app.dart`
- `mobile_app/lib/app/demo_shell.dart`
- `mobile_app/lib/core/models/demo_role.dart`
- `mobile_app/lib/core/models/view_state.dart`
- `mobile_app/lib/core/models/demo_models.dart`
- `mobile_app/lib/core/data/demo_seed.dart`
- `mobile_app/lib/core/permissions/role_permission.dart`
- `mobile_app/lib/features/auth/login_page.dart`
- `mobile_app/lib/features/dashboard/dashboard_page.dart`
- `mobile_app/lib/features/map/map_page.dart`
- `mobile_app/lib/features/fence/fence_page.dart`
- `mobile_app/lib/features/alerts/alerts_page.dart`
- `mobile_app/lib/features/admin/tenant_admin_page.dart`
- `mobile_app/lib/features/mine/mine_page.dart`
- `mobile_app/lib/widgets/state_switch_bar.dart`
- `mobile_app/lib/widgets/status_tag.dart`
- `mobile_app/lib/widgets/metric_card.dart`
- `mobile_app/lib/widgets/empty_state.dart`
- `mobile_app/test/widget_smoke_test.dart`
- `mobile_app/test/role_visibility_test.dart`
- `mobile_app/test/flow_smoke_test.dart`
- `docs/demo/lowfi-client-review-script.md`

**Modify:**
- `docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md`（仅在实现后回填截图链接与交付说明）

**职责约束：**
- `core/*` 仅放跨页面模型、权限与假数据，不放页面渲染代码。
- `features/*` 各页面只处理本页视图与交互，不跨页读写状态。
- `widgets/*` 放复用组件，不耦合具体业务页路由。

## 0.1 执行前置（环境与门禁）

- Flutter 版本：`3.22.x`
- 首次执行：
  - `cd mobile_app && flutter --version`
  - `cd mobile_app && flutter pub get`
- 非 Git 环境处理（当前仓库可能未初始化）：
  - 若 `git rev-parse --is-inside-work-tree` 失败，则各 Task 的 Step 5 不执行 `git commit`
  - 改为维护 `docs/demo/change-log.md`，记录“文件清单 + 目的 + 测试结果”

---

### Task 1: 初始化 Flutter 演示工程与可运行骨架

**Files:**
- Create: `mobile_app/pubspec.yaml`
- Create: `mobile_app/lib/main.dart`
- Create: `mobile_app/lib/app/demo_app.dart`
- Create: `mobile_app/lib/app/demo_shell.dart`
- Test: `mobile_app/test/widget_smoke_test.dart`

- [ ] **Step 1: 写失败测试（应用可启动并显示登录入口）**

```dart
testWidgets('app boots and shows login action', (tester) async {
  await tester.pumpWidget(const DemoApp());
  expect(find.text('智慧畜牧'), findsOneWidget);
  expect(find.text('登录'), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: FAIL（`DemoApp` 或入口不存在）

- [ ] **Step 3: 最小实现（应用入口 + 演示壳层）**

```dart
void main() {
  runApp(const DemoApp());
}
```

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/pubspec.yaml mobile_app/lib/main.dart mobile_app/lib/app mobile_app/test/widget_smoke_test.dart
git commit -m "feat: bootstrap flutter lowfi demo shell"
```

---

### Task 2: 登录分流与角色权限可见性

**Files:**
- Create: `mobile_app/lib/core/models/demo_role.dart`
- Create: `mobile_app/lib/core/permissions/role_permission.dart`
- Create: `mobile_app/lib/features/auth/login_page.dart`
- Modify: `mobile_app/lib/app/demo_shell.dart`
- Test: `mobile_app/test/role_visibility_test.dart`

- [ ] **Step 1: 写失败测试（角色切换后菜单可见项变化）**

```dart
testWidgets('worker role hides fence edit entry', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-worker')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const Key('nav-fence')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('fence-edit-action')), findsNothing);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/role_visibility_test.dart`  
Expected: FAIL（角色权限映射未实现）

- [ ] **Step 3: 最小实现（角色映射 + 登录分流）**
- 角色：`owner` / `worker` / `ops`
- 登录页提供角色切换开关
- 登录后：
  - `owner` 进入业务端底部导航
  - `worker` 进入业务端但隐藏编辑类操作
  - `ops` 直接进入租户管理后台

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/role_visibility_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/core/models/demo_role.dart mobile_app/lib/core/permissions/role_permission.dart mobile_app/lib/features/auth/login_page.dart mobile_app/lib/app/demo_shell.dart mobile_app/test/role_visibility_test.dart
git commit -m "feat: add login role switch and permission visibility rules"
```

---

### Task 3A: 六大页面路由骨架

**Files:**
- Create: `mobile_app/lib/features/dashboard/dashboard_page.dart`
- Create: `mobile_app/lib/features/map/map_page.dart`
- Create: `mobile_app/lib/features/fence/fence_page.dart`
- Create: `mobile_app/lib/features/alerts/alerts_page.dart`
- Create: `mobile_app/lib/features/admin/tenant_admin_page.dart`
- Create: `mobile_app/lib/features/mine/mine_page.dart`
- Test: `mobile_app/test/widget_smoke_test.dart`

- [ ] **Step 1: 写失败测试（六个页面均可进入，使用 Key 锚点）**

```dart
testWidgets('all pages are reachable by route keys', (tester) async {
  await tester.pumpWidget(const DemoApp());
  expect(find.byKey(const Key('page-dashboard')), findsOneWidget);

  await tester.tap(find.byKey(const Key('nav-map')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('page-map')), findsOneWidget);

  await tester.tap(find.byKey(const Key('nav-alerts')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('page-alerts')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: FAIL（页面 key 或路由不存在）

- [ ] **Step 3: 最小实现（仅页面占位 + 可达导航）**
- 新建并接入 6 个页面占位
- 导航可进入：`dashboard/map/alerts/mine/admin/fence`
- 先不接入状态切换与复杂交互

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features mobile_app/lib/app/demo_shell.dart mobile_app/test/widget_smoke_test.dart
git commit -m "feat: scaffold lowfi page routes and navigation"
```

---

### Task 3B: 统一状态切换组件接入

**Files:**
- Modify: `mobile_app/lib/features/dashboard/dashboard_page.dart`
- Modify: `mobile_app/lib/features/map/map_page.dart`
- Modify: `mobile_app/lib/features/fence/fence_page.dart`
- Modify: `mobile_app/lib/features/alerts/alerts_page.dart`
- Modify: `mobile_app/lib/features/admin/tenant_admin_page.dart`
- Modify: `mobile_app/lib/features/mine/mine_page.dart`
- Create: `mobile_app/lib/core/models/view_state.dart`
- Create: `mobile_app/lib/widgets/state_switch_bar.dart`
- Test: `mobile_app/test/widget_smoke_test.dart`

- [ ] **Step 1: 写失败测试（每页存在状态切换 Key）**

```dart
testWidgets('each page contains state switch bar', (tester) async {
  await tester.pumpWidget(const DemoApp());
  expect(find.byKey(const Key('state-switch-dashboard')), findsOneWidget);
  expect(find.byKey(const Key('state-switch-map')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: FAIL（状态切换组件未接入）

- [ ] **Step 3: 最小实现（ViewState + state_switch_bar）**
- 统一枚举：`normal/loading/empty/error/forbidden/offline`
- 六页面都接入状态切换组件

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/core/models/view_state.dart mobile_app/lib/widgets/state_switch_bar.dart mobile_app/lib/features mobile_app/test/widget_smoke_test.dart
git commit -m "feat: add unified view state switch for all lowfi pages"
```

---

### Task 3C: 页面关键占位与操作入口

**Files:**
- Create: `mobile_app/lib/core/models/demo_models.dart`
- Create: `mobile_app/lib/core/data/demo_seed.dart`
- Create: `mobile_app/lib/widgets/status_tag.dart`
- Create: `mobile_app/lib/widgets/metric_card.dart`
- Create: `mobile_app/lib/widgets/empty_state.dart`
- Modify: `mobile_app/lib/features/dashboard/dashboard_page.dart`
- Modify: `mobile_app/lib/features/map/map_page.dart`
- Modify: `mobile_app/lib/features/fence/fence_page.dart`
- Modify: `mobile_app/lib/features/alerts/alerts_page.dart`
- Modify: `mobile_app/lib/features/admin/tenant_admin_page.dart`
- Test: `mobile_app/test/widget_smoke_test.dart`

- [ ] **Step 1: 写失败测试（关键入口按 Key 存在）**

```dart
testWidgets('core action entries are visible', (tester) async {
  await tester.pumpWidget(const DemoApp());
  expect(find.byKey(const Key('dashboard-metric-alert-pending')), findsOneWidget);
  expect(find.byKey(const Key('map-range-toggle')), findsOneWidget);
  expect(find.byKey(const Key('tenant-license-adjust')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: FAIL（关键入口尚未渲染）

- [ ] **Step 3: 最小实现（占位与操作入口）**
- 首页：4 指标卡 + 下钻入口
- 地图：筛选 + 回放区间 + 失败回退列表
- 围栏：新增/编辑/删除入口（受权限控制）
- 告警：确认/处理/归档/批量入口
- 租户后台：开通、禁用/启用、license 调整入口

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/widget_smoke_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/core mobile_app/lib/widgets mobile_app/lib/features mobile_app/test/widget_smoke_test.dart
git commit -m "feat: add lowfi page placeholders and key action entries"
```

---

### Task 4: 四条关键流程可点击串联

**Files:**
- Modify: `mobile_app/lib/app/demo_shell.dart`
- Modify: `mobile_app/lib/features/map/map_page.dart`
- Modify: `mobile_app/lib/features/alerts/alerts_page.dart`
- Modify: `mobile_app/lib/features/fence/fence_page.dart`
- Modify: `mobile_app/lib/features/admin/tenant_admin_page.dart`
- Test: `mobile_app/test/flow_smoke_test.dart`

- [ ] **Step 1: 写失败测试（点击后状态迁移，使用 Key 锚点）**

```dart
testWidgets('alert flow transitions by tapping actions', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('nav-alerts')));
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('alert-confirm')));
  await tester.pump();
  expect(find.byKey(const Key('alert-status-confirmed')), findsOneWidget);

  await tester.tap(find.byKey(const Key('alert-handle')));
  await tester.pump();
  expect(find.byKey(const Key('alert-status-handled')), findsOneWidget);

  await tester.tap(find.byKey(const Key('alert-archive')));
  await tester.pump();
  expect(find.byKey(const Key('alert-status-archived')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/flow_smoke_test.dart`  
Expected: FAIL（流程按钮或跳转未就绪）

- [ ] **Step 3: 最小实现（四条流程）**
- 流程 1：登录 -> 角色分流
- 流程 2：地图筛选 -> 轨迹回放区间切换
- 流程 3：告警确认 -> 处理 -> 归档
- 流程 4：围栏编辑与租户 license 调整（按角色可见）
- 所有动作仅更新本地演示状态，不接后端

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/flow_smoke_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/app/demo_shell.dart mobile_app/lib/features/map/map_page.dart mobile_app/lib/features/alerts/alerts_page.dart mobile_app/lib/features/fence/fence_page.dart mobile_app/lib/features/admin/tenant_admin_page.dart mobile_app/test/flow_smoke_test.dart
git commit -m "feat: wire clickable lowfi demo flows for client review"
```

---

### Task 5: 客户评审脚本与交付打包

**Files:**
- Create: `docs/demo/lowfi-client-review-script.md`
- Modify: `docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md`

- [ ] **Step 1: 写失败检查（脚本包含 10 分钟评审结构）**

检查项（手工）：
- 是否覆盖 4 条流程与 6 类状态
- 是否包含“保留/修改/新增/冻结”会后模板

- [ ] **Step 2: 执行检查并确认失败**

Run: `rg "保留项|修改项|新增项|冻结项" docs/demo/lowfi-client-review-script.md`  
Expected: FAIL（文件尚未创建）

- [ ] **Step 3: 最小实现（交付脚本与规格回填）**
- 输出客户现场讲解脚本（含计时建议）
- 在规格文档回填“Demo 交付物与使用方式”

- [ ] **Step 4: 复测**

Run: `rg "保留项|修改项|新增项|冻结项" docs/demo/lowfi-client-review-script.md`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add docs/demo/lowfi-client-review-script.md docs/superpowers/specs/2026-03-26-smart-livestock-app-design.md
git commit -m "docs: add lowfi client review script and delivery notes"
```

---

## 验证与验收门槛

- 自动化验证：
  - `cd mobile_app && flutter test`
  - `cd mobile_app && flutter analyze`
- 预期：测试与静态检查全部通过。
- 范围门禁（必须通过）：
  - `rg "package:(dio|http|chopper|graphql)" mobile_app/lib mobile_app/pubspec.yaml`
  - `rg "(http://|https://|Dio\\(|HttpClient\\()" mobile_app/lib`
  - 两条命令预期均“无匹配”，确保不接真实网络。
- 手工验证：
  - 可在 10 分钟内完整演示 4 条流程
  - 角色切换能清晰体现菜单与操作差异
  - 每个核心页面均可切换 6 种状态
  - 租户管理入口仅运维可见
  - 记录结果到 `docs/demo/acceptance-checklist.md`（时间、执行人、结论）

## 风险与控范围原则（24 小时约束）

- 不接真实 API，不做持久化，不做性能优化。
- 地图能力用占位/列表回退表达，不集成真实地图 SDK。
- 仅实现“需求确认最小闭环”，不追加高保真视觉细节。
