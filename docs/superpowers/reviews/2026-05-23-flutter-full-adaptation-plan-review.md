# Flutter 全量适配计划 — 评审报告

> **评审对象**: [2026-05-23-flutter-full-adaptation-plan.md](../plans/2026-05-23-flutter-full-adaptation-plan.md)
> **关联规格**: [2026-05-23-flutter-full-adaptation-design.md](../specs/2026-05-23-flutter-full-adaptation-design.md)
> **评审日期**: 2026-05-24

---

## 总结

计划结构清晰，18 个 Task 拆分合理，依赖关系图准确。Task 1（ApiClient）和 Task 4（Dashboard 示范模块）的代码质量较高，可作为后续模块的参考模板。但存在 **5 个 P0 问题**（测试策略缺失、模型迁移顺序冲突、FarmSwitcher 反模式等）和 **若干 P1 问题**，需要在执行前修正。

---

## P0 — 必须修正

### 1. 测试策略完全缺失

**现状**: 代码库有 60 个测试文件，其中 18 个直接引用 `DemoRole`、`AppMode`、`ApiCache` 或 `appModeProvider`：

```
test/api_auth_test.dart
test/api_base_url_test.dart
test/api_cache_role_scope_test.dart
test/api_live_contract_test.dart
test/app_mode_switch_test.dart
test/app_session_test.dart
test/farm_switcher_controller_test.dart
test/features/b2b_admin/b2b_pages_test.dart
test/features/farm_switcher/farm_switcher_test.dart
test/features/fence/fence_live_conflict_feedback_test.dart
test/features/fence/fence_page_mode_switch_test.dart
test/features/subscription/subscription_controller_test.dart
test/features/tenant/live_tenant_repository_test.dart
test/features/worker_management/worker_repository_test.dart
test/main_live_bootstrap_test.dart
test/mock_repository_state_test.dart
test/role_visibility_test.dart
test/seed_data_test.dart
```

**问题**: 计划中每个 Task 的 "验证编译通过" 只运行 `flutter analyze`，没有 `flutter test`。Task 2 删除 `DemoRole`/`AppMode` 后这 18 个测试会全部编译失败，后续 Task 的 `flutter analyze` 也可能因为 cascade error 无法精确定位问题。

**建议**:
- Task 2 后增加一个 **Task 2a: 修复/删除失效测试**，或者在每个 Task 的 Step 中增加测试修复步骤
- 每个 Task 的验证步骤改为 `flutter analyze && flutter test`
- 明确列出哪些测试需要重写 vs 删除（如 `app_mode_switch_test.dart` 直接删除，`app_session_test.dart` 需要重写为 `UserRole` + phone/password 登录测试）

### 2. demo_models.dart 删除时机与引用冲突

**现状**: `demo_models.dart` 被 **23+ 个文件** 引用（dashboard、alerts、devices、livestock、stats、highfi、pages、tenant 等模块），其中包含共享类型如 `DashboardMetric`、`GeoPoint`、`FencePolygon`。

**问题**: 计划在 Task 17 才删除 `demo_models.dart`，但 Task 4 的 `DashboardApiRepository` 仍然 `import demo_models.dart`。整个 Task 5-16 的所有 `*_api_repository.dart` 都可能引用 `demo_models.dart` 中的类型。

**建议**:
- 在 Task 2 之后、Task 4 之前增加一步：**将 `demo_models.dart` 中需要的类型迁移到各模块的 domain 层**（如 `DashboardMetric` → `features/dashboard/domain/`，`GeoPoint` → `core/models/geo_point.dart`）
- 或者保留 `demo_models.dart` 但重命名为 `core_models.dart`（移除 "demo" 前缀），统一管理跨模块共享类型
- 明确哪些类型是模块私有的（迁移到模块内）、哪些是跨模块共享的（保留在 core/models/）

### 3. FarmSwitcherController Future.microtask 反模式

**问题代码**（Task 3）:

```dart
@override
FarmSwitcherState build() {
  final session = ref.watch(sessionControllerProvider);
  if (!session.isLoggedIn) return const FarmSwitcherState.empty();
  Future.microtask(() => _loadFarms());  // ← 反模式
  return const FarmSwitcherState(isLoading: true);
}
```

**风险**: Riverpod Notifier 的 `build()` 不应该有副作用。`Future.microtask` 触发 `_loadFarms()` → `state = ...` → 如果 `session` 变化触发 rebuild → 再次 `Future.microtask` → 可能导致竞态条件和无限循环。

**建议**: 改用 `AsyncNotifier` 模式（与 Task 4 Dashboard 保持一致），或使用 `ref.listenSelf` / 在 SessionController 的 login 方法中主动触发 farm 加载：

```dart
// 方案 A: AsyncNotifier
class FarmSwitcherController extends AsyncNotifier<FarmSwitcherState> {
  @override
  Future<FarmSwitcherState> build() async {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isLoggedIn) return const FarmSwitcherState.empty();
    final farms = await _loadFarms();
    return FarmSwitcherState(farms: farms, activeFarmId: session.activeFarmId ?? farms.first.id);
  }
}

// 方案 B: 在 SessionController.login() 中主动触发
Future<bool> login({...}) async {
  ...
  ref.read(farmSwitcherControllerProvider.notifier).loadFarms();
  ...
}
```

### 4. UserRole.visibleTabs 与设计规格不一致

**设计规格 §8.2** 明确列出 owner 可见页面包含 **Stats** 和 **Twin（开发中）**：

> owner: Dashboard、Map、Alerts、Fences、Livestock、Devices、**Stats**、**Twin（开发中）**、Subscription、Mine、Admin

**计划代码**（Task 2）:

```dart
Set<String> get visibleTabs => switch (this) {
  UserRole.owner => {'dashboard', 'map', 'alerts', 'fences', 'livestock', 'devices', 'subscription', 'mine', 'admin'},
  // ↑ 缺少 'stats' 和 'twin_overview'
```

**影响**: Stats 页面和 Twin 概览页面对 owner 角色不可见，与设计规格不符。

**建议**: 添加 `'stats'` 和 `'twin_overview'` 到 owner 的 visibleTabs 集合中。

### 5. ApiClient._handleResponse 401 双重处理

**问题代码**（Task 1 Step 3）:

```dart
Map<String, dynamic> _handleResponse(http.Response response) {
  if (response.statusCode == 401) {
    _handle401(response);  // ← 第一次
  }
  // ...
  switch (response.statusCode) {
    case 401:
      _handle401(response);  // ← 第二次（不可能到达）
      throw AuthException(...);
  }
}
```

**问题**:
1. 401 状态码会被 `_handle401` 处理两次（第一次在方法顶部，第二次在 switch 中）。虽然幂等无害，但代码令人困惑。
2. 方法顶部的 `if (401) _handle401` 之后没有 `throw`，代码会继续执行到后面的 JSON 解析逻辑，可能对 401 响应体解析失败。
3. `delete()` 方法返回 `void` 但内部 `_handleResponse()` 返回 `Map`，虽然 Dart 允许忽略返回值，但语义不一致。

**建议**:

```dart
Map<String, dynamic> _handleResponse(http.Response response) {
  if (response.statusCode == 401) {
    _handle401(response);
    throw AuthException(...);
  }
  // 移除 switch 中的 401 case
  // ...
}
```

---

## P1 — 建议修正

### 6. ApiClient / JwtStorage 单例与测试不友好

`ApiClient._()` 和 `JwtStorage._()` 均使用单例模式，使得单元测试中无法注入 mock。在 Riverpod 架构中，推荐通过 Provider 注册：

```dart
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient.instance);
```

计划中 Task 4 的 `dashboardRepositoryProvider` 直接 `const DashboardApiRepository()` 硬编码了 `ApiClient.instance`，测试中无法替换。建议所有 repository 通过 Provider 注入 ApiClient。

### 7. Login 响应解析有不必要的 fallback

```dart
final token = (data['accessToken'] ?? data['token']) as String;
```

设计规格明确说后端返回 `accessToken` 字段，不需要 fallback 到 `token`。fallback 掩盖了潜在的 API 契约变化，应该严格按契约解析。

### 8. Task 2 Step 4/5/6/7 描述太模糊

`login_page.dart`、`app_router.dart`、`demo_app.dart`、`demo_shell.dart` 的改造只有文字描述，没有完整代码。这些文件的改动量大且影响全局路由逻辑，建议给出完整代码或至少关键函数的完整签名。

### 9. Task 5 Map / Task 14 Admin / Task 15 Mine 缺少完整实现

Task 5（Map）、Task 14（Admin API Key 弹窗）、Task 15（Farm Creation）只有接口定义或文字描述，缺少 `_api_repository.dart` 实现代码。考虑到 Task 4 建立了示范模式，后续模块可以遵循，但建议至少给出关键解析逻辑的代码片段（如 Map overview 的牲畜位置解析）。

### 10. SubscriptionTier 枚举值需要确认对齐

当前 `SubscriptionTier { basic, standard, premium, enterprise }`，但后端 Commerce 的 `SubscriptionService` 可能使用不同的 tier 名称。Task 10 需要确认后端返回的 tier 字符串与前端枚举完全匹配，否则 `fromJson` 会抛异常。

### 11. Task 16 种子数据 ID 冲突风险

V4 已使用了 `id=1`（tenant、user）。V9-V12 如果也使用硬编码 `id=1`（livestock、fence、alert、device），需要确认序列化不冲突。建议：
- 使用 `INSERT ...` 不指定 `id`，让 PostgreSQL sequence 自动生成
- 或使用明确不冲突的范围（如 `id >= 100`）

---

## P2 — 改进建议

### 12. 缺少网络错误/重试 UI 指导

从同步 ApiCache 切换到异步 ApiClient 后，所有页面都可能遇到网络错误。计划中只提到 `AsyncValue.when(error:)` 显示错误信息，但没有统一的错误处理策略（如重试按钮、toast 通知、错误页面样式）。

### 13. 缺少 loading 骨架屏策略

当前 UI 从同步读取（无 loading）切换到异步 `AsyncValue`，loading 状态将频繁出现。建议在 Task 4 示范模块中建立骨架屏/Spinner 标准样式，后续模块统一复用。

### 14. onAuthFailure 回调未在 main.dart 中设置

Task 1 创建了 `ApiClient.instance.onAuthFailure` 回调，Task 2 的 main.dart 没有设置它。计划注释说"通过 GoRouter redirect 处理"，但 `onAuthFailure` 实际是 void callback，需要主动调用才能触发登出跳转。建议在 `main.dart` 或 `DemoApp` 中显式设置：

```dart
ApiClient.instance.onAuthFailure = () {
  // 通过某种方式通知 SessionController logout
};
```

### 15. Commit 粒度和并行路径合理

18 个 Task 的拆分粒度恰当，每个 Task 一个 commit 便于 code review 和回滚。依赖关系图中的并行路径（Task 4-9 可并行、Task 16 可与前端并行）标注清晰。这是一大优点。

---

## Checklist 摘要

| # | 级别 | 问题 | 影响 Task | 建议 |
|---|------|------|----------|------|
| 1 | P0 | 测试策略缺失 | Task 2 之后所有 | 增加 Task 2a 或每步含测试 |
| 2 | P0 | demo_models.dart 删除时机 | Task 4/17 | Task 2 后迁移共享类型 |
| 3 | P0 | FarmSwitcher microtask 反模式 | Task 3 | 改用 AsyncNotifier 或主动触发 |
| 4 | P0 | UserRole.visibleTabs 缺少 stats/twin | Task 2 | 补全 visibleTabs |
| 5 | P0 | _handleResponse 401 双重处理 | Task 1 | 合并 401 处理逻辑 |
| 6 | P1 | ApiClient 单例不利于测试 | Task 1/4 | Provider 注入 |
| 7 | P1 | Login token fallback 不必要 | Task 1 | 移除 fallback |
| 8 | P1 | Task 2 多文件描述模糊 | Task 2 | 补充完整代码 |
| 9 | P1 | Task 5/14/15 缺实现代码 | Task 5/14/15 | 补充关键代码 |
| 10 | P1 | SubscriptionTier 对齐未确认 | Task 10 | 确认后端枚举值 |
| 11 | P1 | 种子数据 ID 冲突 | Task 16 | 不硬编码 ID 或用非冲突范围 |
| 12 | P2 | 网络错误 UI 无统一策略 | 全局 | 建立错误处理标准 |
| 13 | P2 | Loading 骨架屏未考虑 | 全局 | Task 4 中建立标准 |
| 14 | P2 | onAuthFailure 未设置 | Task 1/2 | 显式设置回调 |

**结论**: 修正 5 个 P0 问题后，计划可进入执行阶段。建议在开始实施前先修复 P0 #1（测试策略）和 P0 #2（模型迁移顺序），其余 P0 可在对应 Task 中修复。
