# 智慧畜牧 App（高保真 UI/UX + Mock 优先）实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 先交付可评审、可演示、可冻结范围的高保真前端体验（重点覆盖虚拟围栏场景），后端继续使用 mock/仿真数据与配置驱动，待 UI 冻结后再切换真实服务。  

**Architecture:** 采用 Flutter 单代码库内“设计系统层 + 页面层 + mock 场景层 + data source 切换层”的四层结构。页面仅依赖 controller/repository，不直接读取假数据；通过 `APP_MODE` 与 repository/data source 保持 mock/live 同构，确保后续联调仅替换数据层。  

**Tech Stack:** Flutter、Dart、Material 3、flutter_test、mock data/config、现有 `APP_MODE` 切换机制

---

## 0. 文件结构（高保真优先边界）

**Create:**
- `mobile_app/lib/core/theme/app_colors.dart`
- `mobile_app/lib/core/theme/app_typography.dart`
- `mobile_app/lib/core/theme/app_spacing.dart`
- `mobile_app/lib/core/theme/app_theme.dart`
- `mobile_app/lib/core/mock/mock_scenarios.dart`
- `mobile_app/lib/core/mock/mock_config.dart`
- `mobile_app/lib/features/highfi/widgets/highfi_card.dart`
- `mobile_app/lib/features/highfi/widgets/highfi_stat_tile.dart`
- `mobile_app/lib/features/highfi/widgets/highfi_status_chip.dart`
- `mobile_app/lib/features/highfi/widgets/highfi_empty_error_state.dart`
- `mobile_app/test/theme/highfi_theme_test.dart`
- `mobile_app/test/highfi/dashboard_highfi_test.dart`
- `mobile_app/test/highfi/map_fence_highfi_test.dart`
- `mobile_app/test/highfi/alerts_highfi_test.dart`
- `docs/demo/highfi-review-script.md`
- `docs/demo/highfi-change-log.md`

**Modify:**
- `mobile_app/lib/app/demo_app.dart`
- `mobile_app/lib/app/demo_shell.dart`
- `mobile_app/lib/app/app_mode.dart`
- `mobile_app/lib/features/pages/dashboard_page.dart`
- `mobile_app/lib/features/pages/map_page.dart`
- `mobile_app/lib/features/pages/alerts_page.dart`
- `mobile_app/lib/features/pages/fence_page.dart`
- `mobile_app/lib/features/pages/admin_page.dart`
- `mobile_app/lib/features/pages/mine_page.dart`
- `mobile_app/lib/features/auth/login_page.dart`
- `docs/demo/mock-to-live-switch-guide.md`
- `docs/demo/post-lowfi-follow-ups.md`

**职责约束：**
- `core/theme/*` 只定义设计 token 与主题映射，不写业务逻辑。
- `core/mock/*` 只管理仿真数据与场景切换，不写 UI 渲染。
- `features/pages/*` 只负责页面结构与交互，不直接 new 假数据。
- `features/highfi/widgets/*` 放可复用高保真组件，不耦合单页面业务。

---

### Task 1: 建立高保真设计系统（自然牧场风 C2）

**Files:**
- Create: `mobile_app/lib/core/theme/app_colors.dart`
- Create: `mobile_app/lib/core/theme/app_typography.dart`
- Create: `mobile_app/lib/core/theme/app_spacing.dart`
- Create: `mobile_app/lib/core/theme/app_theme.dart`
- Modify: `mobile_app/lib/app/demo_app.dart`
- Test: `mobile_app/test/theme/highfi_theme_test.dart`

- [ ] **Step 1: 写失败测试（主题 token 可被应用读取）**

```dart
testWidgets('uses highfi theme tokens', (tester) async {
  await tester.pumpWidget(const DemoApp());
  final BuildContext ctx = tester.element(find.byType(MaterialApp));
  final theme = Theme.of(ctx);
  expect(theme.colorScheme.primary.value, isNonZero);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/theme/highfi_theme_test.dart`  
Expected: FAIL（主题文件或 token 未接入）

- [ ] **Step 3: 最小实现（颜色/字体/间距/圆角/阴影）**
- 颜色：草地绿主色 + 暖灰中性色 + 状态色
- 字体：标题/正文/辅助层级
- 间距：8pt 体系（4/8/12/16/24/32）
- 组件形态：中圆角、轻阴影、可读性优先

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/theme/highfi_theme_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/core/theme mobile_app/lib/app/demo_app.dart mobile_app/test/theme/highfi_theme_test.dart
git commit -m "feat: add high-fidelity C2 design system tokens and app theme"
```

---

### Task 2: 建立高保真基础组件库（卡片/状态/空错态）

**Files:**
- Create: `mobile_app/lib/features/highfi/widgets/highfi_card.dart`
- Create: `mobile_app/lib/features/highfi/widgets/highfi_stat_tile.dart`
- Create: `mobile_app/lib/features/highfi/widgets/highfi_status_chip.dart`
- Create: `mobile_app/lib/features/highfi/widgets/highfi_empty_error_state.dart`
- Test: `mobile_app/test/highfi/dashboard_highfi_test.dart`

- [ ] **Step 1: 写失败测试（核心组件 key 可见且可复用）**

```dart
testWidgets('renders reusable highfi components', (tester) async {
  await tester.pumpWidget(const DemoApp());
  expect(find.byKey(const Key('highfi-stat-tile')), findsWidgets);
  expect(find.byKey(const Key('highfi-status-chip')), findsWidgets);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/highfi/dashboard_highfi_test.dart`  
Expected: FAIL（组件尚未创建或页面未接入）

- [ ] **Step 3: 最小实现（高保真组件）**
- 统计卡支持标题/值/趋势/点击态
- 状态芯片支持 `normal/loading/empty/error/forbidden/offline`
- 空/错态支持图标+说明+重试入口

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/highfi/dashboard_highfi_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/highfi/widgets mobile_app/test/highfi/dashboard_highfi_test.dart
git commit -m "feat: add reusable high-fidelity UI component library"
```

---

### Task 3: Dashboard 高保真首屏（牧场概览优先）

**Files:**
- Modify: `mobile_app/lib/features/pages/dashboard_page.dart`
- Modify: `mobile_app/lib/app/demo_shell.dart`
- Test: `mobile_app/test/highfi/dashboard_highfi_test.dart`

- [ ] **Step 1: 写失败测试（首页高保真关键块存在）**

```dart
testWidgets('dashboard highfi blocks are visible', (tester) async {
  await tester.pumpWidget(const DemoApp());
  expect(find.byKey(const Key('dashboard-farm-header')), findsOneWidget);
  expect(find.byKey(const Key('dashboard-metric-livestock')), findsOneWidget);
  expect(find.byKey(const Key('dashboard-quick-fence')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/highfi/dashboard_highfi_test.dart`  
Expected: FAIL

- [ ] **Step 3: 最小实现（高保真首页）**
- 顶部牧场信息条（牧场名/天气/同步时间）
- 四指标卡（牲畜总数、在围率、活跃告警、设备状态）
- 快捷入口（创建围栏、查看地图、告警中心、租户后台）

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/highfi/dashboard_highfi_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/pages/dashboard_page.dart mobile_app/lib/app/demo_shell.dart mobile_app/test/highfi/dashboard_highfi_test.dart
git commit -m "feat: implement high-fidelity dashboard overview experience"
```

---

### Task 4: Map + 虚拟围栏高保真（本轮核心）

**Files:**
- Modify: `mobile_app/lib/features/pages/map_page.dart`
- Modify: `mobile_app/lib/features/pages/fence_page.dart`
- Create: `mobile_app/lib/core/mock/mock_scenarios.dart`
- Create: `mobile_app/lib/core/mock/mock_config.dart`
- Test: `mobile_app/test/highfi/map_fence_highfi_test.dart`

- [ ] **Step 1: 写失败测试（围栏绘制/图层/筛选入口存在）**

```dart
testWidgets('map and fence highfi actions are available', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('nav-map')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('map-toolbar-draw-fence')), findsOneWidget);
  expect(find.byKey(const Key('map-layer-fence-toggle')), findsOneWidget);
  expect(find.byKey(const Key('map-livestock-filter')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/highfi/map_fence_highfi_test.dart`  
Expected: FAIL

- [ ] **Step 3: 最小实现（围栏主场景）**
- 地图工具栏：选择/绘制/编辑/删除/测量
- 图层控制：围栏/牲畜/告警/轨迹
- 围栏模板：矩形/圆形/不规则（mock 场景驱动）
- 围栏分组与离线缓存标识（UI 标识 + mock 配置）

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/highfi/map_fence_highfi_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/pages/map_page.dart mobile_app/lib/features/pages/fence_page.dart mobile_app/lib/core/mock mobile_app/test/highfi/map_fence_highfi_test.dart
git commit -m "feat: implement high-fidelity virtual fence map workflows with mock scenarios"
```

---

### Task 5: Alerts 高保真（越界/低电/失联三类 P0）

**Files:**
- Modify: `mobile_app/lib/features/pages/alerts_page.dart`
- Modify: `mobile_app/lib/core/permissions/role_permission.dart`
- Test: `mobile_app/test/highfi/alerts_highfi_test.dart`

- [ ] **Step 1: 写失败测试（三类告警与状态流转可见）**

```dart
testWidgets('alerts page shows p0 categories and flow', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('nav-alerts')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('alert-type-fence-breach')), findsOneWidget);
  expect(find.byKey(const Key('alert-type-battery-low')), findsOneWidget);
  expect(find.byKey(const Key('alert-type-signal-lost')), findsOneWidget);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/highfi/alerts_highfi_test.dart`  
Expected: FAIL

- [ ] **Step 3: 最小实现（告警高保真）**
- 告警筛选：全部/未处理/已处理
- P0 类型：越界、低电、信号丢失
- 状态动作：确认 -> 处理 -> 归档（按角色限制）

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/highfi/alerts_highfi_test.dart`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/pages/alerts_page.dart mobile_app/lib/core/permissions/role_permission.dart mobile_app/test/highfi/alerts_highfi_test.dart
git commit -m "feat: upgrade alerts page to high-fidelity p0 categories and flows"
```

---

### Task 6: 登录/后台/我的页面风格统一与权限边界表达

**Files:**
- Modify: `mobile_app/lib/features/auth/login_page.dart`
- Modify: `mobile_app/lib/features/pages/admin_page.dart`
- Modify: `mobile_app/lib/features/pages/mine_page.dart`
- Modify: `mobile_app/lib/app/demo_shell.dart`
- Test: `mobile_app/test/role_visibility_test.dart`

- [ ] **Step 1: 写失败测试（高保真样式下角色边界仍正确）**

```dart
testWidgets('role visibility remains correct after highfi upgrade', (tester) async {
  await tester.pumpWidget(const DemoApp());
  await tester.tap(find.byKey(const Key('role-worker')));
  await tester.tap(find.byKey(const Key('login-submit')));
  await tester.pumpAndSettle();
  expect(find.byKey(const Key('nav-admin')), findsNothing);
});
```

- [ ] **Step 2: 运行测试并确认失败**

Run: `cd mobile_app && flutter test test/role_visibility_test.dart`  
Expected: FAIL（样式重构时可能破坏 key/权限逻辑）

- [ ] **Step 3: 最小实现（统一视觉 + 保留权限约束）**
- 登录页高保真（品牌/表单/角色切换）
- 后台页高保真（租户卡片/license 操作）
- 我的页高保真（账号/设备/帮助）

- [ ] **Step 4: 复测**

Run: `cd mobile_app && flutter test test/role_visibility_test.dart && flutter test`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/auth/login_page.dart mobile_app/lib/features/pages/admin_page.dart mobile_app/lib/features/pages/mine_page.dart mobile_app/lib/app/demo_shell.dart mobile_app/test/role_visibility_test.dart
git commit -m "feat: align login admin mine pages with high-fidelity style and role boundaries"
```

---

### Task 7: Mock 场景中心化与配置驱动（联调前门禁）

**Files:**
- Modify: `mobile_app/lib/app/app_mode.dart`
- Modify: `mobile_app/lib/app/app_router.dart`
- Modify: `mobile_app/lib/app/app_route.dart`
- Modify: `docs/demo/mock-to-live-switch-guide.md`
- Modify: `docs/demo/post-lowfi-follow-ups.md`
- Create: `docs/demo/highfi-review-script.md`
- Create: `docs/demo/highfi-change-log.md`

- [ ] **Step 1: 写失败检查（文档与运行方式一致）**

Run: `rg "APP_MODE|mock|live|场景" docs/demo/mock-to-live-switch-guide.md docs/demo/highfi-review-script.md`  
Expected: FAIL（新脚本尚未创建或描述不完整）

- [ ] **Step 2: 执行检查并确认失败**

Run: `rg "高保真|虚拟围栏|越界|低电|失联" docs/demo/highfi-review-script.md`  
Expected: FAIL（文件尚未创建）

- [ ] **Step 3: 最小实现（mock 场景契约）**
- 定义场景：正常、围栏越界、设备低电、信号丢失、离线缓存
- 明确 mock/live 切换：页面层不分支，仓储层切换
- 记录高保真变更追溯与评审脚本

- [ ] **Step 4: 复测**

Run: `rg "高保真|虚拟围栏|越界|低电|失联|APP_MODE" docs/demo/highfi-review-script.md docs/demo/mock-to-live-switch-guide.md`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/app/app_mode.dart mobile_app/lib/app/app_router.dart mobile_app/lib/app/app_route.dart docs/demo/mock-to-live-switch-guide.md docs/demo/post-lowfi-follow-ups.md docs/demo/highfi-review-script.md docs/demo/highfi-change-log.md
git commit -m "docs: define high-fidelity mock-first workflow and demo scripts"
```

---

### Task 8: 高保真阶段验收与冻结

**Files:**
- Modify: `mobile_app/test/widget_smoke_test.dart`
- Modify: `mobile_app/test/flow_smoke_test.dart`
- Create: `docs/qa/highfi-ux-acceptance.md`
- Modify: `docs/demo/change-log.md`

- [ ] **Step 1: 写验收用例（高保真门禁）**
- 三个标杆页（Dashboard/Map/Alerts）关键块完整
- 围栏场景（绘制/编辑/分组/模板/图层）可演示
- 六类状态与角色权限不回归

- [ ] **Step 2: 执行自动化验证**

Run: `cd mobile_app && flutter analyze && flutter test`  
Expected: 全部 PASS

- [ ] **Step 3: 执行手工演示验收**

Run: `cd mobile_app && flutter run`  
Expected: 可在 10 分钟完成高保真演示脚本

- [ ] **Step 4: 记录冻结结论**

Run: `rg "保留项|修改项|新增项|冻结项" docs/qa/highfi-ux-acceptance.md`  
Expected: PASS

- [ ] **Step 5: 提交**

```bash
git add mobile_app/test docs/qa/highfi-ux-acceptance.md docs/demo/change-log.md
git commit -m "test: add high-fidelity UX acceptance baseline and freeze results"
```

---

## 验证与里程碑（修正版）

- **High-Fidelity 里程碑（当前最高优先级）**：Task 1-8 完成，形成“可评审、可冻结、可切换数据源”的高保真前端基线。
- **Mock 契约里程碑**：mock 场景与配置稳定，`APP_MODE` 切换路径清晰，页面层不出现数据源分叉判断。
- **后端启动里程碑（后置）**：在高保真冻结后，恢复执行全栈计划中的后端 Task 1-8（FastAPI/MQTT/DB）。

## 执行建议

- 每个 Task 保持 TDD：先失败测试，再最小实现，再复测，再记录。
- UI 改动必须保留关键 `Key`，保证自动化测试与演示脚本稳定。
- 围栏相关需求按 `docs/2026-03-27-虚拟围栏应用需求分析.md` 的 P0/P1 优先级推进：先 P0（创建/编辑/删除、定位、越界/低电/失联），再 P1（模板、分组、离线围栏）。

