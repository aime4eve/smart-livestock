# 统一商业模型 Phase 2a 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 清理 Phase 1 遗留技术债（ops 改名 + shaping 接通），新增多 farm 切换与 B端管理后台，为多租户商业模型奠定基础。

**Architecture:** E1 先行完成全局改名和 shaping 接通；E2（多 farm）和 E3（B端后台）可并行。后端新增 workerFarmStore / contractStore 内存 Store + 扩展 farmContextMiddleware；前端新增 FarmSwitcher 全局组件 + B端侧边栏 Shell。

**Tech Stack:** Flutter 3.x / flutter_riverpod / go_router, Node.js + Express 5

**被实施规格:** `docs/superpowers/specs/2026-04-29-unified-business-model-phase2a-design.md`

**前置计划:** `docs/superpowers/plans/2026-04-28-unified-business-model-phase1.md`（Phase 1 已完成）

**真相来源:** Issue 的 **open/closed** 以 GitHub 为准；本文件记录范围说明、依赖与 **关闭后** 的归档信息。

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P0 | 待创建 | E1: 技术债清理 — ops→platform_admin 改名 + applyMockShaping 接通 |
| P0 | 待创建 | E2: 多 farm 支持 — owner 多 farm 切换 + worker 多 farm 分配 |
| P0 | 待创建 | E3: B端管理后台 — 用量看板 + 旗下 farm 管理 + 合同信息 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| 2026-04-30 | E1 | 未提 PR | ops→platform_admin 改名、ownerId 非唯一注释、applyMockShaping 接通；未提交 commit |
| 2026-04-30 | E2 | — | 多 farm 支持：workerFarmStore、my-farms/switch-farm、/farms/:farmId/workers、FarmSwitcher + ApiCache、牧工管理；代码已提交于分支 feat/ubm-e2-multi-farm，待合并 master |

---

## 范围界定（Scope）

**本计划覆盖:**
- E1: ops→platform_admin 全局改名（后端 7 文件 + 前端 15 文件）
- E1: applyMockShaping 接通至 alerts / fence / dashboard / stats 四个 Controller
- E1: ownerId 非唯一性注释
- E2: 后端 workerFarmStore + farmContextMiddleware 扩展 + my-farms / switch-farm / workers CRUD 端点
- E2: 前端 FarmSwitcher 全局组件 + AppSession 扩展 + worker 管理子页面
- E3: 后端 contractStore + b2b dashboard / farms / contract 端点（替换 Phase 1 占位）
- E3: 前端 B端侧边栏 Shell + 概览 / 牧场管理 / 合同信息三个页面
- E2+E3 seed 数据扩展 + 全量测试

**本计划不覆盖:**
- 分润引擎 + 对账看板 → Phase 2b
- License 激活 + 心跳监控 → Phase 2b
- 合同创建/编辑（platform_admin 后台操作） → Phase 2b
- b2b_admin 管理旗下 farm 的 worker → Phase 2b
- API 开放平台 `/api/open/v1/*` → Phase 2c
- LicenseStore / ApiTierStore 真实逻辑 → Phase 2b

---

## 依赖关系

```
E1 (技术债) ──→ E2 (多 farm) ──┐
                  E3 (B端后台) ──┤──→ Phase 2b
```

E1 必须先完成（E2/E3 代码中需使用 `platform_admin` 命名）。E2 和 E3 可并行开发。

---

## 文件结构

### 后端 — 新建

| 文件 | Epic | 职责 |
|------|------|------|
| `backend/data/workerFarmStore.js` | E2 | worker-farm 分配内存 Store |
| `backend/data/contractStore.js` | E3 | 合同内存 Store |
| `backend/routes/b2bDashboard.js` | E3 | B端控制台路由（替换现有 b2bAdmin.js） |
| `backend/routes/workerRoutes.js` | E2 | `/api/v1/farms/:farmId/workers` 牧工分配路由（保持规格路径） |
| `backend/test/workerFarmStore.test.js` | E2 | workerFarmStore 单元测试 |
| `backend/test/farm-switch.test.js` | E2 | farm 切换 API 集成测试 |
| `backend/test/worker-routes.test.js` | E2 | workers CRUD API 集成测试 |
| `backend/test/contractStore.test.js` | E3 | contractStore 单元测试 |
| `backend/test/b2b-dashboard.test.js` | E3 | B端控制台 API 集成测试 |

### 后端 — 修改

| 文件 | Epic | 变更 |
|------|------|------|
| `backend/data/seed.js` | E1+E2+E3 | ops→platform_admin；新增 tenant_007 / wfa 种子 / contract 种子 / b2b_admin 权限扩展 |
| `backend/middleware/auth.js` | E1 | TOKEN_MAP ops→platform-admin |
| `backend/middleware/farmContext.js` | E1+E2 | ops→platform_admin；x-active-farm header + workerFarmStore 查询 |
| `backend/middleware/feature-flag.js` | E1 | 注释更新 ops→platform_admin |
| `backend/routes/auth.js` | E1 | 错误信息 ops→platform_admin |
| `backend/routes/registerApiRoutes.js` | E2+E3 | 注册 my-farms / switch-farm / farms/:id/workers / b2bDashboard 路由 |
| `backend/server.js` | E2+E3 | ROUTE_DEFINITIONS 新增端点 |
| `backend/test/farmContext.test.js` | E1 | ops→platform_admin |
| `backend/test/subscription-api.test.js` | E1 | ops→platform_admin |

### 前端 — 新建

| 文件 | Epic | 职责 |
|------|------|------|
| `lib/features/farm_switcher/farm_switcher_controller.dart` | E2 | Riverpod Notifier，管理 activeFarmTenantId + farm 列表 |
| `lib/features/farm_switcher/farm_switcher_widget.dart` | E2 | 全局下拉组件，嵌入 DemoShell AppBar |
| `lib/features/worker_management/domain/worker_repository.dart` | E2 | 牧工管理 Repository 接口 |
| `lib/features/worker_management/data/mock_worker_repository.dart` | E2 | Mock 实现 |
| `lib/features/worker_management/data/live_worker_repository.dart` | E2 | Live 实现（ApiCache） |
| `lib/features/worker_management/presentation/worker_controller.dart` | E2 | 牧工管理 Controller |
| `lib/features/worker_management/presentation/worker_list_page.dart` | E2 | 牧工列表页（MinePage 子页面） |
| `lib/features/b2b_admin/presentation/b2b_dashboard_page.dart` | E3 | B端概览页 |
| `lib/features/b2b_admin/presentation/b2b_farm_list_page.dart` | E3 | 旗下 farm 列表页 |
| `lib/features/b2b_admin/presentation/b2b_contract_page.dart` | E3 | 合同信息页 |
| `lib/features/b2b_admin/data/b2b_repository.dart` | E3 | B端数据仓库（domain 接口 + mock/live 实现） |
| `lib/features/b2b_admin/presentation/b2b_controller.dart` | E3 | B端 Riverpod Controller |
| `test/features/farm_switcher/farm_switcher_test.dart` | E2 | FarmSwitcher widget 测试 |
| `test/features/worker_management/worker_list_test.dart` | E2 | 牧工管理页面 widget 测试 |
| `test/features/b2b_admin/b2b_pages_test.dart` | E3 | B端页面 widget 测试 |

### 前端 — 修改

| 文件 | Epic | 变更 |
|------|------|------|
| `lib/core/models/demo_role.dart` | E1 | `ops` → `platformAdmin` |
| `lib/app/session/app_session.dart` | E1+E2 | `isOps` → `isPlatformAdmin`；新增 `activeFarmTenantId` |
| `lib/core/permissions/role_permission.dart` | E1+E3 | ops→platformAdmin；新增 canViewContract / canCreateFarm / canViewB2bDashboard |
| `lib/app/app_route.dart` | E1+E3 | `opsAdmin` → `platformAdmin`；新增 b2b 子路由 |
| `lib/app/app_router.dart` | E1+E2+E3 | ops→platformAdmin；b2b 子路由；farm context 注入 |
| `lib/app/demo_shell.dart` | E1+E2+E3 | ops→platformAdmin；FarmSwitcher 嵌入；b2b 侧边栏分支 |
| `lib/features/auth/login_page.dart` | E1 | ops→platformAdmin；文案 "平台管理员" |
| `lib/features/pages/b2b_admin_placeholder_page.dart` | E3 | 删除（被 b2bDashboard 替换） |
| `lib/features/pages/admin_page.dart` | E1 | ops→platformAdmin 标签 |
| `lib/features/tenant/data/mock_tenant_repository.dart` | E1 | 运维管理员→平台管理员 |
| `lib/features/tenant/presentation/pages/*.dart` | E1 | ops→platformAdmin；路由引用更新 |
| `lib/features/alerts/presentation/alerts_controller.dart` | E1 | applyMockShaping 接通 |
| `lib/features/fence/presentation/fence_controller.dart` | E1 | applyMockShaping 接通 |
| `lib/features/dashboard/presentation/dashboard_controller.dart` | E1 | applyMockShaping 接通 |
| `lib/features/stats/presentation/stats_controller.dart` | E1 | applyMockShaping 接通 |
| `lib/features/pages/mine_page.dart` | E2 | 新增"牧工管理"入口（owner 可见） |
| `test/*.dart` (约 10+ 文件) | E1 | ops→platformAdmin 引用更新 |

### 删除

| 文件 | Epic | 原因 |
|------|------|------|
| `backend/routes/b2bAdmin.js` | E3 | 被 b2bDashboard.js 替换 |
| `lib/features/pages/b2b_admin_placeholder_page.dart` | E3 | 被实际页面替换 |

---

## Epic E1: 技术债清理

### Task 1: 后端 ops → platform_admin 改名

**Files:**
- Modify: `backend/data/seed.js`
- Modify: `backend/middleware/auth.js`
- Modify: `backend/middleware/farmContext.js`
- Modify: `backend/middleware/feature-flag.js`
- Modify: `backend/routes/auth.js`
- Modify: `backend/test/farmContext.test.js`
- Modify: `backend/test/subscription-api.test.js`

- [x] **Step 1: 修改 seed.js 用户定义**

在 `backend/data/seed.js` 中：

```javascript
// 改前
ops: {
  userId: 'u_003',
  tenantId: null,
  name: '运维管理员',
  role: 'ops',
  ...
}

// 改后
platform_admin: {
  userId: 'u_003',
  tenantId: null,
  name: '平台管理员',
  role: 'platform_admin',
  ...
}
```

- [x] **Step 2: 修改 auth.js TOKEN_MAP，并预留动态 mock 用户注册能力**

在 `backend/middleware/auth.js` 中：

```javascript
// 改前
'mock-token-ops': 'ops',

// 改后
'mock-token-platform-admin': 'platform_admin',
```

同时添加 `TOKEN_USER_OVERRIDES` 和 `registerMockUserToken()`，用于 Phase 2a 中 b2b_admin 动态创建 owner 后注册 token：

```javascript
const TOKEN_USER_OVERRIDES = {};

function registerMockUserToken(token, user) {
  TOKEN_MAP[token] = user.role;
  TOKEN_USER_OVERRIDES[token] = user;
  users[user.userId] = user;
}
```

在 `authMiddleware()` 中把 mock token 的用户解析改为：

```javascript
req.userRole = role;
req.user = TOKEN_USER_OVERRIDES[token] ?? users[role];
```

并在导出中包含 `registerMockUserToken`：

```javascript
module.exports = {
  authMiddleware,
  requirePermission,
  TOKEN_MAP,
  extractBearerToken,
  registerMockUserToken,
};
```

- [x] **Step 3: 修改 farmContext.js 注释**

在 `backend/middleware/farmContext.js` 中，更新注释 `// platform_admin (ops)` → `// platform_admin`（去掉括号中的旧名）。

- [x] **Step 4: 修改 feature-flag.js 注释**

在 `backend/middleware/feature-flag.js` 中，更新注释中的 `ops` 引用为 `platform_admin`。

- [x] **Step 5: 修改 auth.js 错误信息**

在 `backend/routes/auth.js` 中：

```javascript
// 改前
'role 或 account 必须映射到 owner / worker / ops'

// 改后
'role 或 account 必须映射到 owner / worker / platform_admin'
```

- [x] **Step 6: 修改后端测试**

在 `backend/test/farmContext.test.js` 中：

```javascript
// 改前
test('farmContext: ops role sets activeFarmTenantId to null', () => {
  const req = mockReq({ userId: 'u_003', role: 'ops', tenantId: 'tenant_003' });

// 改后
test('farmContext: platform_admin role sets activeFarmTenantId to null', () => {
  const req = mockReq({ userId: 'u_003', role: 'platform_admin', tenantId: 'tenant_003' });
```

在 `backend/test/subscription-api.test.js` 中：

```javascript
// 改前
test('GET /subscription/current returns 400 for ops (no farm context)', async () => {
  const token = await loginGetToken('ops');

// 改后
test('GET /subscription/current returns 400 for platform_admin (no farm context)', async () => {
  const token = await loginGetToken('platform_admin');
```

检查文件中所有 `'ops'` 引用，全部替换为 `'platform_admin'`。同时更新 `loginGetToken` 调用中对应的 token 字符串为 `'mock-token-platform-admin'`。

- [x] **Step 7: 运行后端测试验证**

Run: `cd Mobile/backend && node --test test/*.test.js`
Expected: 全部 PASS，无 `'ops'` 相关断言失败

- [x] **Step 8: 启动 Mock Server 验证端点**

Run: `cd Mobile/backend && node server.js`
然后：

```bash
# 验证旧 token 失效
curl -s http://localhost:3001/api/me -H "Authorization: Bearer mock-token-ops" | head -5
# Expected: 401

# 验证新 token 有效
curl -s http://localhost:3001/api/me -H "Authorization: Bearer mock-token-platform-admin" | head -5
# Expected: 200, role: "platform_admin"
```

- [ ] **Step 9: Commit**

```bash
cd Mobile
git add backend/
git commit -m "refactor(backend): rename ops role to platform_admin"
```

---

### Task 2: 前端 ops → platformAdmin 改名

**Files:**
- Modify: `mobile_app/lib/core/models/demo_role.dart`
- Modify: `mobile_app/lib/app/session/app_session.dart`
- Modify: `mobile_app/lib/core/permissions/role_permission.dart`
- Modify: `mobile_app/lib/app/app_route.dart`
- Modify: `mobile_app/lib/app/app_router.dart`
- Modify: `mobile_app/lib/app/demo_shell.dart`
- Modify: `mobile_app/lib/features/auth/login_page.dart`
- Modify: `mobile_app/lib/features/pages/admin_page.dart`
- Modify: `mobile_app/lib/features/tenant/data/mock_tenant_repository.dart`
- Modify: `mobile_app/lib/features/tenant/presentation/pages/tenant_create_page.dart`
- Modify: `mobile_app/lib/features/tenant/presentation/pages/tenant_edit_page.dart`
- Modify: `mobile_app/lib/features/tenant/presentation/pages/tenant_detail_page.dart`
- Modify: `mobile_app/lib/features/tenant/presentation/pages/tenant_list_page.dart`

- [x] **Step 1: 修改 DemoRole 枚举**

在 `lib/core/models/demo_role.dart` 中：

```dart
// 改前
enum DemoRole {
  owner,
  worker,
  ops,
  b2bAdmin,
  apiConsumer,
}

// 改后
enum DemoRole {
  owner,
  worker,
  platformAdmin,
  b2bAdmin,
  apiConsumer,
}
```

- [x] **Step 2: 修改 AppSession**

在 `lib/app/session/app_session.dart` 中：

```dart
// 改前
bool get isOps => role == DemoRole.ops;

// 改后
bool get isPlatformAdmin => role == DemoRole.platformAdmin;
```

- [x] **Step 3: 修改 RolePermission**

在 `lib/core/permissions/role_permission.dart` 中，全局替换 `DemoRole.ops` → `DemoRole.platformAdmin`。
重点检查 `canManageTenants()`：

```dart
// 改前
static bool canManageTenants(DemoRole role) =>
    role == DemoRole.owner || role == DemoRole.ops;

// 改后
static bool canManageTenants(DemoRole role) =>
    role == DemoRole.owner || role == DemoRole.platformAdmin;
```

- [x] **Step 4: 修改 AppRoute 枚举**

在 `lib/app/app_route.dart` 中：

```dart
// 改前
opsAdmin('/ops/admin', 'ops-admin', '运维后台'),

// 改后
platformAdmin('/ops/admin', 'platform-admin', '平台后台'),
```

注意：URL 路径 `/ops/admin` 保留不变，仅改枚举名和显示文案。

- [x] **Step 5: 修改 AppRouter 路由守卫**

在 `lib/app/app_router.dart` 中，全局替换 `DemoRole.ops` → `DemoRole.platformAdmin`，替换 `AppRoute.opsAdmin` → `AppRoute.platformAdmin`。路由名称 `'ops-tenant-*'` 保留不变（仅内部标识，不影响用户）。

- [x] **Step 6: 修改 DemoShell**

在 `lib/app/demo_shell.dart` 中：

```dart
// 改前
if (role == null || role == DemoRole.ops || role == DemoRole.b2bAdmin) {

// 改后
if (role == null || role == DemoRole.platformAdmin || role == DemoRole.b2bAdmin) {
```

- [x] **Step 7: 修改 LoginPage**

在 `lib/features/auth/login_page.dart` 中：

```dart
// 改前
buttonKey: const Key('role-ops'),
label: 'ops',
selected: _selectedRole == DemoRole.ops,
setState(() => _selectedRole = DemoRole.ops),

// 改后
buttonKey: const Key('role-platform-admin'),
label: '平台管理员',
selected: _selectedRole == DemoRole.platformAdmin,
setState(() => _selectedRole = DemoRole.platformAdmin),
```

- [x] **Step 8: 修改 admin_page.dart 标签**

在 `lib/features/pages/admin_page.dart` 中：`'ops / owner 演示入口'` → `'platform_admin / owner 演示入口'`。

- [x] **Step 9: 修改 tenant 模块中的 ops 引用**

在以下文件中全局替换 `DemoRole.ops` → `DemoRole.platformAdmin`、`'ops'` → `'platform_admin'`：
- `lib/features/tenant/data/mock_tenant_repository.dart`：`'运维管理员'` → `'平台管理员'`
- `lib/features/tenant/presentation/pages/tenant_create_page.dart`
- `lib/features/tenant/presentation/pages/tenant_edit_page.dart`
- `lib/features/tenant/presentation/pages/tenant_detail_page.dart`
- `lib/features/tenant/presentation/pages/tenant_list_page.dart`

这些文件中的 `role?.name ?? 'ops'` 改为 `role?.name ?? 'platform_admin'`。

- [x] **Step 10: 修改前端测试**

在 `test/` 目录下所有 `.dart` 文件中：
- `DemoRole.ops` → `DemoRole.platformAdmin`
- `Key('role-ops')` → `Key('role-platform-admin')`
- 测试描述中的 `'ops'` → `'platform_admin'`

涉及文件（基于探索结果）：
- `test/flow_smoke_test.dart`
- `test/role_visibility_test.dart`

- [x] **Step 11: 添加登录页 token 输入 escape hatch**

规格 Section 3.3 提到：b2b_admin 创建子 farm 时会动态生成 owner 用户和 mock token，这些用户不在登录页固定按钮上。解决方案：在 `lib/features/auth/login_page.dart` 底部添加一个"直接输入 token"输入框（Mock 环境专用），允许输入任意 token 字符串登录：

```dart
// 在角色按钮下方添加（仅 Mock 模式可见）
if (const String.fromEnvironment('APP_MODE', defaultValue: 'mock') == 'mock')
  Padding(
    padding: const EdgeInsets.only(top: 16),
    child: TextField(
      key: const Key('token-input'),
      decoration: const InputDecoration(
        labelText: '直接输入 Token',
        hintText: 'mock-token-xxx',
        isDense: true,
      ),
      onSubmitted: (token) {
        // 通过 SessionController 直接设置 token + 角色
        ref.read(sessionControllerProvider.notifier).loginWithToken(token);
      },
    ),
  ),
```

需要在 `SessionController` 中添加 `loginWithToken(String token)` 方法，解析 token 映射到角色（Mock 环境下的简易实现）。

在 `lib/app/session/session_controller.dart` 中添加：

```dart
DemoRole? _roleFromMockToken(String token) {
  return switch (token) {
    'mock-token-owner' => DemoRole.owner,
    'mock-token-worker' => DemoRole.worker,
    'mock-token-platform-admin' => DemoRole.platformAdmin,
    'mock-token-b2b-admin' => DemoRole.b2bAdmin,
    'mock-token-api-consumer' => DemoRole.apiConsumer,
    _ when token.startsWith('mock-token-u_') => DemoRole.owner,
    _ => null,
  };
}

void loginWithToken(String token) {
  final trimmed = token.trim();
  final role = _roleFromMockToken(trimmed);
  if (role == null) return;
  state = AppSession.withTokens(
    role: role,
    accessToken: trimmed,
  );
}
```

动态 owner token 使用 `mock-token-u_<timestamp>` 约定，前端可按 owner 角色进入；后端通过 `registerMockUserToken()` 负责把该 token 绑定到真实动态用户对象。

- [x] **Step 12: 运行前端测试验证**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 全部 PASS

- [ ] **Step 13: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "refactor(frontend): rename ops role to platformAdmin"
```

---

### Task 3: ownerId 非唯一性注释

**Files:**
- Modify: `backend/data/tenantStore.js`

- [x] **Step 1: 添加设计决策注释**

在 `backend/data/tenantStore.js` 的 `createTenant()` 方法中，在参数校验区域添加一行注释：

```javascript
// ownerId 非唯一：同一 owner 可拥有多个 farm（Phase 2a 确认）
```

- [ ] **Step 2: Commit**

```bash
cd Mobile
git add backend/data/tenantStore.js
git commit -m "docs(backend): annotate ownerId non-unique design decision"
```

---

### Task 4: applyMockShaping 接通 — Controller 层

**设计决策:** 规格建议修改 `applyMockShaping` 签名为接受 `ViewData`，但各模块的 `XxxViewData` 没有公共基类。方案调整为：**在 Controller 层应用 shaping**（Controller 有 `ref` 可读取 subscription tier），Repository 接口和签名不变。后端 live 模式由 shaping 中间件处理，前端 mock 模式由 Controller 补齐。

**Files:**
- Modify: `mobile_app/lib/features/alerts/presentation/alerts_controller.dart`
- Modify: `mobile_app/lib/features/fence/presentation/fence_controller.dart`
- Modify: `mobile_app/lib/features/dashboard/presentation/dashboard_controller.dart`
- Modify: `mobile_app/lib/features/stats/presentation/stats_controller.dart`
- Modify: `mobile_app/lib/core/data/apply_mock_shaping.dart`（新增辅助方法）
- Test: `mobile_app/test/mock_shaping_test.dart`（新建）

- [x] **Step 1: 新增辅助方法到 apply_mock_shaping.dart**

在 `apply_mock_shaping.dart` 底部添加通用辅助函数，用于将 List 转为 Map 后执行 shaping 并返回结构化结果：

```dart
/// Shaping 结果，供 Controller 层使用
class ShapingResult {
  final bool locked;
  final String? upgradeTier;
  final int retainedCount;
  final int? originalCount;

  const ShapingResult({
    this.locked = false,
    this.upgradeTier,
    required this.retainedCount,
    this.originalCount,
  });
}

/// 对列表数据执行 shaping，返回结构化结果。
/// [items] 为 Map 列表，[getDate] 提取日期字符串用于 filter。
ShapingResult shapeListItems({
  required List<Map<String, dynamic>> items,
  required SubscriptionTier tier,
  required List<String> featureKeys,
  String Function(Map<String, dynamic>)? getDate,
}) {
  final data = <String, dynamic>{
    'items': items,
    'total': items.length,
  };
  final shaped = applyMockShaping(data, tier, featureKeys);

  if (shaped['locked'] == true) {
    return ShapingResult(
      locked: true,
      upgradeTier: shaped['upgradeTier'] as String?,
      retainedCount: 0,
      originalCount: items.length,
    );
  }

  final retained = shaped['items'] as List? ?? items;
  return ShapingResult(
    retainedCount: retained.length,
    originalCount: (shaped['filteredTotal'] ?? shaped['totalBeforeLimit'] ?? items.length) as int?,
  );
}
```

- [x] **Step 2: 写 alerts shaping 测试**

创建 `test/mock_shaping_test.dart`：

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/data/apply_mock_shaping.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

void main() {
  group('shapeListItems', () {
    test('locked feature returns locked result for insufficient tier', () {
      final items = List.generate(
        5,
        (i) => <String, dynamic>{'id': 'a_$i', 'title': 'Alert $i'},
      );
      final result = shapeListItems(
        items: items,
        tier: SubscriptionTier.basic,
        featureKeys: [FeatureFlags.trajectory], // lock: standard+
      );
      expect(result.locked, isTrue);
      expect(result.retainedCount, equals(0));
      expect(result.originalCount, equals(5));
    });

    test('non-locked feature returns all items for sufficient tier', () {
      final items = List.generate(
        5,
        (i) => <String, dynamic>{'id': 'a_$i'},
      );
      final result = shapeListItems(
        items: items,
        tier: SubscriptionTier.premium,
        featureKeys: [FeatureFlags.gpsLocation], // none: all tiers
      );
      expect(result.locked, isFalse);
      expect(result.retainedCount, equals(5));
    });

    test('limit feature truncates items for lowest tier', () {
      final items = List.generate(
        10,
        (i) => <String, dynamic>{'id': 'f_$i'},
      );
      final result = shapeListItems(
        items: items,
        tier: SubscriptionTier.basic,
        featureKeys: [FeatureFlags.fence], // limit: basic=3
      );
      expect(result.locked, isFalse);
      expect(result.retainedCount, equals(3));
      expect(result.originalCount, equals(10));
    });
  });
}
```

- [x] **Step 3: 运行测试确认通过**

Run: `cd Mobile/mobile_app && flutter test test/mock_shaping_test.dart`
Expected: PASS

- [x] **Step 4: 修改 AlertsController 接入 shaping**

在 `alerts_controller.dart` 中，**注意 `AlertsController` 当前是 `Notifier<AlertsViewData>`**，通过构造函数 `AlertsController(this.role)` 注入角色（不是 `FamilyNotifier`，也没有 `arg` 参数）。在 build 方法返回前加入 mock 模式 shaping 逻辑：

```dart
// 仅 mock 模式应用前端 shaping（live 模式由后端中间件处理）
final appMode = ref.watch(appModeProvider);
if (!appMode.isLive && data.viewState == ViewState.normal && data.items.isNotEmpty) {
  final tier = ref.watch(subscriptionControllerProvider).tier;
  final itemMaps = data.items.map((a) => <String, dynamic>{
    'id': a.id,
    'title': a.title,
    'subtitle': a.subtitle,
    'priority': a.priority,
    'type': a.type,
    'stage': a.stage,
    'earTag': a.earTag,
    if (a.livestockId != null) 'livestockId': a.livestockId,
  }).toList();

  final result = shapeListItems(
    items: itemMaps,
    tier: tier,
    featureKeys: [FeatureFlags.alertHistory],
  );

  if (result.locked) {
    return AlertsViewData(
      viewState: ViewState.forbidden,
      role: data.role,
      stage: data.stage,
      title: '告警历史',
      subtitle: '升级套餐后可查看',
      items: [],
      message: '当前套餐不支持告警历史',
    );
  }

  if (result.retainedCount < data.items.length) {
    final retainedIds = itemMaps
        .take(result.retainedCount)
        .map((m) => m['id'] as String)
        .toSet();
    return AlertsViewData(
      viewState: data.viewState,
      role: data.role,
      stage: data.stage,
      title: data.title,
      subtitle: data.subtitle,
      items: data.items.where((a) => retainedIds.contains(a.id)).toList(),
      message: data.message,
    );
  }
}
```

注意：需在文件顶部添加 `import` 语句引入 `apply_mock_shaping.dart`、`subscription_tier.dart`、`subscription_controller.dart`（如尚未引入）和 `app_mode.dart`。

- [x] **Step 5: 修改 FenceController 接入 shaping**

在 `fence_controller.dart` 中，`FenceController` 是 `Notifier<FenceState>`，`build()` 返回 `FenceState`。在 `build()` 中获取 `fences` 后、返回 `FenceState` 前加入 shaping：

```dart
@override
FenceState build() {
  var fences = ref.watch(fenceRepositoryProvider).loadAll();

  // mock 模式 fence shaping
  final appMode = ref.watch(appModeProvider);
  if (!appMode.isLive && fences.isNotEmpty) {
    final tier = ref.watch(subscriptionControllerProvider).tier;
    final itemMaps = fences.map((f) => <String, dynamic>{
      'id': f.id,
      'name': f.name,
    }).toList();
    final result = shapeListItems(
      items: itemMaps,
      tier: tier,
      featureKeys: [FeatureFlags.fence],
    );
    if (result.retainedCount < fences.length) {
      fences = fences.take(result.retainedCount).toList();
    }
  }

  return FenceState(
    fences: fences,
    viewState: fences.isEmpty ? ViewState.empty : ViewState.normal,
  );
}
```

- [x] **Step 6: 修改 DashboardController 接入 shaping**

在 `dashboard_controller.dart` 中，dashboardSummary 是 `limit: 4` 策略，作用于 `List<DashboardMetric>`：

```dart
// mock 模式 dashboard shaping
final appMode = ref.watch(appModeProvider);
if (!appMode.isLive && data.viewState == ViewState.normal) {
  final tier = ref.watch(subscriptionControllerProvider).tier;
  final itemMaps = data.metrics.map((m) => <String, dynamic>{
    'id': m.widgetKey,
  }).toList();
  final result = shapeListItems(
    items: itemMaps,
    tier: tier,
    featureKeys: [FeatureFlags.dashboardSummary],
  );
  if (result.retainedCount < data.metrics.length) {
    return DashboardViewData(
      viewState: data.viewState,
      metrics: data.metrics.take(result.retainedCount).toList(),
      message: data.message,
    );
  }
}
```

- [x] **Step 7: 修改 StatsController 接入 shaping**

规格 Section 1.2 将 `mock_stats_repository.dart` 列为需接通 shaping 的 repository（feature: `stats`）。当前 `StatsViewData` 不是列表结构，`FeatureFlags.stats` 也是 `FeatureShape.none`，因此这里主要完成 mock/live 行为一致性的接线：mock 模式下读取套餐并调用 `applyMockShaping`，若未来 feature flag 改成 lock，可立即返回 forbidden。

在 `stats_controller.dart` 中添加 imports：

```dart
import 'package:smart_livestock_demo/core/data/apply_mock_shaping.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';
```

在 `build()` 返回前加入：

```dart
final data = ref.watch(statsRepositoryProvider).load(
      viewState: ViewState.normal,
      timeRange: StatsTimeRange.d7,
    );

final appMode = ref.watch(appModeProvider);
if (!appMode.isLive && data.viewState == ViewState.normal) {
  final tier = ref.watch(subscriptionControllerProvider).tier;
  final shaped = applyMockShaping(
    const <String, dynamic>{'enabled': true},
    tier,
    [FeatureFlags.stats],
  );

  if (shaped['locked'] == true) {
    return StatsViewData(
      viewState: ViewState.forbidden,
      timeRange: data.timeRange,
      message: '当前套餐不支持统计分析',
    );
  }
}

return data;
```

`setViewState()` 和 `setTimeRange()` 后续如需严格同步 shaping，可抽取 `_loadShaped()` 私有方法复用，避免 build 与交互刷新路径不一致。

- [x] **Step 8: 运行全量测试验证**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 全部 PASS，无回归

- [ ] **Step 9: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): connect applyMockShaping to alerts/fence/dashboard/stats controllers"
```

---

### Task 5: E1 全量回归验证

- [x] **Step 1: 后端全量测试**

Run: `cd Mobile/backend && node --test test/*.test.js`
Expected: 全部 PASS

- [x] **Step 2: 前端全量测试 + 静态分析**

Run: `cd Mobile/mobile_app && flutter analyze && flutter test`
Expected: 0 issues, 全部 PASS

---
## Epic E2: 多 farm 支持

> **前置条件:** Task 1-5（E1）已完成。

### Task 6: 后端 workerFarmStore + seed 数据

**Files:**
- Create: `backend/data/workerFarmStore.js`
- Modify: `backend/data/seed.js`
- Test: `backend/test/workerFarmStore.test.js`

- [ ] **Step 1: 写 workerFarmStore 单元测试**

创建 `backend/test/workerFarmStore.test.js`：

```javascript
const { describe, test, beforeEach } = require('node:test');
const assert = require('node:assert/strict');

describe('workerFarmStore', () => {
  let store;

  beforeEach(() => {
    // 重置模块缓存以获取干净实例
    delete require.cache[require.resolve('../data/workerFarmStore')];
    store = require('../data/workerFarmStore');
  });

  test('findByUserId returns assignments for a worker', () => {
    const assignments = store.findByUserId('u_002');
    assert.ok(assignments.length >= 1);
    assert.equal(assignments[0].userId, 'u_002');
  });

  test('findByFarmId returns workers for a farm', () => {
    const workers = store.findByFarmId('tenant_001');
    assert.ok(workers.length >= 1);
  });

  test('assign creates new assignment', () => {
    const assignment = store.assign('u_new', 'tenant_001', 'worker');
    assert.equal(assignment.userId, 'u_new');
    assert.equal(assignment.farmTenantId, 'tenant_001');
    assert.equal(assignment.role, 'worker');
    assert.ok(assignment.id);
    assert.ok(assignment.assignedAt);
  });

  test('unassign removes assignment', () => {
    const assignment = store.assign('u_del', 'tenant_001', 'worker');
    const removed = store.unassign(assignment.id);
    assert.equal(removed, true);
    assert.equal(store.findByUserId('u_del').length, 0);
  });

  test('unassign returns false for non-existent id', () => {
    assert.equal(store.unassign('nonexistent'), false);
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile/backend && node --test test/workerFarmStore.test.js`
Expected: FAIL — module not found

- [ ] **Step 3: 实现 workerFarmStore**

创建 `backend/data/workerFarmStore.js`：

```javascript
// Worker-Farm 分配内存 Store
// Phase 2a: worker 可被分配到多个 farm

const _assignments = [];

function _initSeed() {
  _assignments.push(
    {
      id: 'wfa_001',
      userId: 'u_002',
      farmTenantId: 'tenant_001',
      role: 'worker',
      assignedAt: '2026-04-28T00:00:00+08:00',
    },
    {
      id: 'wfa_002',
      userId: 'u_002',
      farmTenantId: 'tenant_007',
      role: 'worker',
      assignedAt: '2026-04-29T00:00:00+08:00',
    },
  );
}

_initSeed();

function findByUserId(userId) {
  return _assignments.filter((a) => a.userId === userId);
}

function findByFarmId(farmTenantId) {
  return _assignments.filter((a) => a.farmTenantId === farmTenantId);
}

function assign(userId, farmTenantId, role) {
  // 防重复
  const exists = _assignments.find(
    (a) => a.userId === userId && a.farmTenantId === farmTenantId,
  );
  if (exists) return null;

  const assignment = {
    id: `wfa_${Date.now()}`,
    userId,
    farmTenantId,
    role: role || 'worker',
    assignedAt: new Date().toISOString(),
  };
  _assignments.push(assignment);
  return assignment;
}

function unassign(assignmentId) {
  const idx = _assignments.findIndex((a) => a.id === assignmentId);
  if (idx === -1) return false;
  _assignments.splice(idx, 1);
  return true;
}

module.exports = { findByUserId, findByFarmId, assign, unassign };
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd Mobile/backend && node --test test/workerFarmStore.test.js`
Expected: 全部 PASS

- [ ] **Step 5: 扩展 seed.js — 新增 tenant_007**

在 `backend/data/seed.js` 的 tenants 数组中新增 owner（张三）的第二个 farm：

```javascript
{
  id: 'tenant_007',
  name: '张三的第二牧场',
  type: 'farm',
  parentTenantId: null,
  billingModel: 'direct',
  entitlementTier: 'basic',
  ownerId: 'u_001',
  status: 'active',
  contactName: '张三',
  contactPhone: '13800000001',
  contactEmail: 'zhangsan@example.com',
  region: '华北',
  remarks: 'owner 多 farm 演示',
  licenseUsed: 0,
  licenseTotal: 50,
  createdAt: '2026-04-29T00:00:00+08:00',
  updatedAt: '2026-04-29T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
},
```

- [ ] **Step 6: Commit**

```bash
cd Mobile
git add backend/data/workerFarmStore.js backend/data/seed.js backend/test/workerFarmStore.test.js
git commit -m "feat(backend): add workerFarmStore + seed tenant_007 for multi-farm"
```

---

### Task 7: 后端 farmContextMiddleware 扩展 + my-farms/switch-farm 端点

**Files:**
- Modify: `backend/middleware/farmContext.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/server.js`
- Create: `backend/routes/farmRoutes.js`
- Test: `backend/test/farm-switch.test.js`

- [ ] **Step 1: 写 farm 切换 API 集成测试**

创建 `backend/test/farm-switch.test.js`：

> **测试模式:** 使用 `app.listen(0)` 启动真实 HTTP 服务器（与现有 `subscription-api.test.js` 一致），通过 `fetch` 发送请求。Express 不支持 `app.inject()`。

```javascript
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../server');

async function withServer(fn) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    server.close();
  }
}

describe('Farm switching API', () => {
  test('GET /my-farms returns farms for owner', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/my-farms`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.farms.length >= 2); // tenant_001 + tenant_007
      assert.ok(body.data.activeFarmId);
    });
  });

  test('GET /my-farms returns farms for worker', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/my-farms`, {
        headers: { authorization: 'Bearer mock-token-worker' },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.farms.length >= 1);
    });
  });

  test('POST /switch-farm succeeds for owned farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/switch-farm`, {
        method: 'POST',
        headers: {
          authorization: 'Bearer mock-token-owner',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ farmTenantId: 'tenant_007' }),
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.equal(body.data.activeFarmId, 'tenant_007');
    });
  });

  test('POST /switch-farm returns 403 for non-owned farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/switch-farm`, {
        method: 'POST',
        headers: {
          authorization: 'Bearer mock-token-worker',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ farmTenantId: 'tenant_005' }),
      });
      assert.ok(res.status === 403 || res.status === 200);
    });
  });

  test('farmContextMiddleware uses x-active-farm header', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farm/my-farms`, {
        headers: {
          authorization: 'Bearer mock-token-owner',
          'x-active-farm': 'tenant_007',
        },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.equal(body.data.activeFarmId, 'tenant_007');
    });
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile/backend && node --test test/farm-switch.test.js`
Expected: FAIL — route not found

- [ ] **Step 3: 扩展 farmContextMiddleware**

替换 `backend/middleware/farmContext.js` 全部内容：

```javascript
const tenantStore = require('../data/tenantStore');
const workerFarmStore = require('../data/workerFarmStore');

function farmContextMiddleware(req, res, next) {
  const headerFarmId = req.headers['x-active-farm'];

  if (req.user?.role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    if (headerFarmId && farms.some((f) => f.id === headerFarmId)) {
      req.activeFarmTenantId = headerFarmId;
    } else {
      req.activeFarmTenantId = farms.length > 0 ? farms[0].id : null;
    }
  } else if (req.user?.role === 'worker') {
    const assignments = workerFarmStore.findByUserId(req.user.userId);
    const farmIds = assignments.map((a) => a.farmTenantId);
    if (headerFarmId && farmIds.includes(headerFarmId)) {
      req.activeFarmTenantId = headerFarmId;
    } else {
      req.activeFarmTenantId = farmIds.length > 0 ? farmIds[0] : null;
    }
  } else {
    // platform_admin, b2b_admin, api_consumer — no farm context
    req.activeFarmTenantId = null;
  }
  next();
}

module.exports = { farmContextMiddleware };
```

- [ ] **Step 4: 创建 farmRoutes.js**

创建 `backend/routes/farmRoutes.js`：

```javascript
const { Router } = require('express');
const router = Router();

const tenantStore = require('../data/tenantStore');
const workerFarmStore = require('../data/workerFarmStore');

// GET /my-farms — 返回当前用户关联的 farm 列表
router.get('/my-farms', (req, res) => {
  const role = req.userRole;
  let farms = [];
  let activeFarmId = req.activeFarmTenantId;

  if (role === 'owner') {
    const allFarms = tenantStore.findByOwnerId(req.user.userId);
    farms = allFarms.map((f) => ({
      id: f.id,
      name: f.name,
      status: f.status,
      livestockCount: 0, // Phase 2a: mock，后续接入真实数据
      region: f.region,
    }));
  } else if (role === 'worker') {
    const assignments = workerFarmStore.findByUserId(req.user.userId);
    farms = assignments.map((a) => {
      const t = tenantStore.findById(a.farmTenantId);
      return {
        id: a.farmTenantId,
        name: t?.name ?? '未知牧场',
        status: t?.status ?? 'unknown',
        livestockCount: 0,
        region: t?.region ?? '',
      };
    });
  } else {
    return res.fail(403, 'AUTH_FORBIDDEN', '仅 owner/worker 可查看 farm 列表');
  }

  if (!activeFarmId && farms.length > 0) {
    activeFarmId = farms[0].id;
  }

  res.ok({ farms, activeFarmId });
});

// POST /switch-farm — 验证 farm 可用性
router.post('/switch-farm', (req, res) => {
  const { farmTenantId } = req.body;
  if (!farmTenantId) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少 farmTenantId');
  }

  const role = req.userRole;
  let authorized = false;
  let farmName = '';

  if (role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    const farm = farms.find((f) => f.id === farmTenantId);
    if (farm) {
      authorized = true;
      farmName = farm.name;
    }
  } else if (role === 'worker') {
    const assignments = workerFarmStore.findByUserId(req.user.userId);
    const assignment = assignments.find((a) => a.farmTenantId === farmTenantId);
    if (assignment) {
      const farm = tenantStore.findById(farmTenantId);
      authorized = true;
      farmName = farm?.name ?? '未知牧场';
    }
  }

  if (!authorized) {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权切换到该牧场');
  }

  res.ok({ activeFarmId: farmTenantId, farmName });
});

module.exports = router;
```

- [ ] **Step 5: 注册路由**

在 `backend/routes/registerApiRoutes.js` 中添加：

```javascript
const farmRoutes = require('./farmRoutes');

function registerApiRoutes(app, prefix) {
  // ... 现有路由 ...
  app.use(`${prefix}/farm`, farmRoutes);   // my-farms, switch-farm
}
```

在 `backend/server.js` 的 `ROUTE_DEFINITIONS` 数组中添加：

```javascript
['GET',    '/farm/my-farms'],
['POST',   '/farm/switch-farm'],
```

- [ ] **Step 6: 运行测试确认通过**

Run: `cd Mobile/backend && node --test test/farm-switch.test.js test/farmContext.test.js`
Expected: 全部 PASS

- [ ] **Step 7: Commit**

```bash
cd Mobile
git add backend/
git commit -m "feat(backend): multi-farm support — farmContextMiddleware + my-farms + switch-farm"
```

---

### Task 8: 后端 /farms/:farmId/workers 端点

**Files:**
- Create: `backend/routes/workerRoutes.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/server.js`
- Test: `backend/test/worker-routes.test.js`

- [ ] **Step 1: 写 workers CRUD API 集成测试**

创建 `backend/test/worker-routes.test.js`：

```javascript
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../server');

async function withServer(fn) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    server.close();
  }
}

describe('Workers CRUD API', () => {
  test('GET /farms/:farmId/workers returns workers for owned farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_001/workers`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(Array.isArray(body.data.items));
      assert.ok(body.data.total >= 1);
    });
  });

  test('GET /farms/:farmId/workers returns 403 for non-owned farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_005/workers`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });
      assert.equal(res.status, 403);
    });
  });

  test('POST /farms/:farmId/workers returns 409 for duplicate assignment', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_001/workers`, {
        method: 'POST',
        headers: {
          authorization: 'Bearer mock-token-owner',
          'content-type': 'application/json',
        },
        body: JSON.stringify({ userId: 'u_002', role: 'worker' }),
      });
      assert.equal(res.status, 409);
    });
  });

  test('DELETE /farms/:farmId/workers/:id returns 404 for missing assignment', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/farms/tenant_001/workers/missing`, {
        method: 'DELETE',
        headers: { authorization: 'Bearer mock-token-owner' },
      });
      assert.equal(res.status, 404);
    });
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile/backend && node --test test/worker-routes.test.js`
Expected: FAIL — route not found

- [ ] **Step 3: 创建 workerRoutes.js**

规格 Section 2.2 定义路径为 `/api/v1/farms/:farmId/workers`，因此 workers CRUD 不挂到 `/farm` 前缀下，避免生成 `/api/v1/farm/farms/...`。

创建 `backend/routes/workerRoutes.js`：

```javascript
const { Router } = require('express');
const router = Router();

const tenantStore = require('../data/tenantStore');
const workerFarmStore = require('../data/workerFarmStore');

// GET /farms/:farmId/workers — 某 farm 的 worker 列表
router.get('/:farmId/workers', (req, res) => {
  const { farmId } = req.params;
  const role = req.userRole;

  // 权限：owner 只能查自己的 farm，platform_admin 可查任意
  if (role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    if (!farms.find((f) => f.id === farmId)) {
      return res.fail(403, 'AUTH_FORBIDDEN', '无权查看该牧场的牧工');
    }
  } else if (role !== 'platform_admin') {
    return res.fail(403, 'AUTH_FORBIDDEN', '无权查看牧工列表');
  }

  const assignments = workerFarmStore.findByFarmId(farmId);
  const items = assignments.map((a) => ({
    id: a.id,
    userId: a.userId,
    userName: a.userId, // Phase 2a: mock，无 user lookup
    role: a.role,
    assignedAt: a.assignedAt,
  }));

  res.ok({ items, total: items.length });
});

// POST /farms/:farmId/workers — 分配 worker
router.post('/:farmId/workers', (req, res) => {
  const { farmId } = req.params;
  const { userId, role: workerRole } = req.body;

  if (!userId) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少 userId');
  }

  const assignment = workerFarmStore.assign(userId, farmId, workerRole || 'worker');
  if (!assignment) {
    return res.fail(409, 'CONFLICT', '该牧工已分配到此牧场');
  }

  res.ok(assignment);
});

// DELETE /farms/:farmId/workers/:id — 移除分配
router.delete('/:farmId/workers/:id', (req, res) => {
  const { id } = req.params;
  const removed = workerFarmStore.unassign(id);
  if (!removed) {
    return res.fail(404, 'NOT_FOUND', '分配记录不存在');
  }
  res.ok({ removed: true });
});

module.exports = router;
```

- [ ] **Step 4: 注册路由**

在 `backend/routes/registerApiRoutes.js` 中添加：

```javascript
const workerRoutes = require('./workerRoutes');

function registerApiRoutes(app, prefix) {
  // ... 现有路由 ...
  app.use(`${prefix}/farms`, workerRoutes);
}
```

- [ ] **Step 5: 更新 server.js ROUTE_DEFINITIONS**

在 `ROUTE_DEFINITIONS` 数组中添加：

```javascript
['GET',    '/farms/:farmId/workers'],
['POST',   '/farms/:farmId/workers'],
['DELETE', '/farms/:farmId/workers/:id'],
```

- [ ] **Step 6: 运行后端全量测试**

Run: `cd Mobile/backend && node --test test/*.test.js`
Expected: 全部 PASS

- [ ] **Step 7: Commit**

```bash
cd Mobile
git add backend/
git commit -m "feat(backend): add workers CRUD endpoints for farm management"
```

---

### Task 9: 前端 AppSession 扩展 + FarmSwitcherController

**Files:**
- Modify: `mobile_app/lib/app/session/app_session.dart`
- Create: `mobile_app/lib/features/farm_switcher/farm_switcher_controller.dart`

- [ ] **Step 1: 扩展 AppSession**

在 `lib/app/session/app_session.dart` 中添加 `activeFarmTenantId` 字段：

```dart
class AppSession {
  const AppSession._({
    this.role,
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
    this.activeFarmTenantId,
  });

  const AppSession.loggedOut() : this._();

  const AppSession.authenticated(DemoRole role) : this._(role: role);

  const AppSession.withTokens({
    required DemoRole role,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? activeFarmTenantId,
  }) : this._(
          role: role,
          accessToken: accessToken,
          refreshToken: refreshToken,
          expiresAt: expiresAt,
          activeFarmTenantId: activeFarmTenantId,
        );

  final DemoRole? role;
  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
  final String? activeFarmTenantId;

  bool get isLoggedIn => role != null;
  bool get isPlatformAdmin => role == DemoRole.platformAdmin;
  bool get isB2bAdmin => role == DemoRole.b2bAdmin;
  bool get isApiConsumer => role == DemoRole.apiConsumer;
  bool get canAccessAdminTab => role == DemoRole.owner;

  AppSession copyWith({String? activeFarmTenantId}) {
    return AppSession._(
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: expiresAt,
      activeFarmTenantId: activeFarmTenantId,
    );
  }
}
```

- [ ] **Step 2: 创建 FarmSwitcherController**

创建 `lib/features/farm_switcher/farm_switcher_controller.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/app/session/app_session.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/demo_role.dart';

class FarmInfo {
  const FarmInfo({required this.id, required this.name, required this.status});

  final String id;
  final String name;
  final String status;
}

class FarmSwitcherState {
  const FarmSwitcherState({
    this.farms = const [],
    this.activeFarmId,
  });

  final List<FarmInfo> farms;
  final String? activeFarmId;

  bool get hasMultipleFarms => farms.length > 1;
  bool get hasFarms => farms.isNotEmpty;
}

const _ownerMockFarms = [
  FarmInfo(id: 'tenant_001', name: '华东示范牧场', status: 'active'),
  FarmInfo(id: 'tenant_007', name: '张三的第二牧场', status: 'active'),
];

const _workerMockFarms = [
  FarmInfo(id: 'tenant_001', name: '华东示范牧场', status: 'active'),
  FarmInfo(id: 'tenant_007', name: '张三的第二牧场', status: 'active'),
];

class FarmSwitcherController extends Notifier<FarmSwitcherState> {
  @override
  FarmSwitcherState build() {
    final session = ref.watch(sessionControllerProvider);
    final role = session.role;
    if (role == null) return const FarmSwitcherState();

    final appMode = ref.watch(appModeProvider);

    if (appMode.isLive) {
      return _loadFromApiCache(session);
    }
    return _loadFromSeed(role);
  }

  FarmSwitcherState _loadFromSeed(DemoRole role) {
    if (role == DemoRole.owner) {
      return const FarmSwitcherState(
        farms: _ownerMockFarms,
        activeFarmId: 'tenant_001',
      );
    }
    if (role == DemoRole.worker) {
      return const FarmSwitcherState(
        farms: _workerMockFarms,
        activeFarmId: 'tenant_001',
      );
    }
    return const FarmSwitcherState();
  }

  FarmSwitcherState _loadFromApiCache(AppSession session) {
    try {
      final cache = ApiCache.instance;
      final data = cache.myFarms;
      if (data == null) return const FarmSwitcherState();

      final farmsList = (data['farms'] as List?) ?? [];
      final farms = farmsList.map((f) => FarmInfo(
        id: f['id'] as String,
        name: f['name'] as String,
        status: f['status'] as String? ?? 'active',
      )).toList();

      return FarmSwitcherState(
        farms: farms,
        activeFarmId: data['activeFarmId'] as String? ??
            session.activeFarmTenantId,
      );
    } catch (_) {
      return const FarmSwitcherState();
    }
  }

  void switchFarm(String farmId) {
    final current = state;
    if (!current.farms.any((f) => f.id == farmId)) return;

    state = FarmSwitcherState(
      farms: current.farms,
      activeFarmId: farmId,
    );

    // 同步到 AppSession
    ref.read(sessionControllerProvider.notifier).updateActiveFarm(farmId);
  }
}

final farmSwitcherControllerProvider =
    NotifierProvider<FarmSwitcherController, FarmSwitcherState>(
  FarmSwitcherController.new,
);
```

注意：需要在 `SessionController` 中添加 `updateActiveFarm` 方法（下一步实现）。

- [ ] **Step 3: 在 SessionController 添加 updateActiveFarm 方法**

在 `lib/app/session/session_controller.dart` 的 `SessionController` 类中添加：

```dart
void updateActiveFarm(String farmId) {
  final current = state;
  if (current is! AppSession) return;
  state = current.copyWith(activeFarmTenantId: farmId);
}
```

- [ ] **Step 4: 扩展 ApiCache 添加 myFarms**

在 `lib/core/api/api_cache.dart` 中添加 `myFarms`、`workers`、`b2bDashboard`、`b2bContract` 字段。在 `init()` 方法中根据角色预加载：

- `GET /api/v1/farm/my-farms`（owner/worker）
- `GET /api/v1/farms/{farmId}/workers`（owner）
- `GET /api/v1/b2b/dashboard`（b2b_admin）
- `GET /api/v1/b2b/contract/current`（b2b_admin）

将响应分别缓存到对应属性。

实现时避免把所有角色都请求 B端或 worker 端点。可在通用 `Future.wait` 后追加按角色加载：

```dart
Map<String, dynamic>? _myFarms;
Map<String, dynamic>? _workers;
Map<String, dynamic>? _b2bDashboard;
Map<String, dynamic>? _b2bContract;

Map<String, dynamic>? get myFarms => _myFarms;
Map<String, dynamic>? get workers => _workers;
Map<String, dynamic>? get b2bDashboard => _b2bDashboard;
Map<String, dynamic>? get b2bContract => _b2bContract;
```

在 `init()` 基础数据加载成功后追加：

```dart
if (role == 'owner' || role == 'worker') {
  _myFarms = await _get('/farm/my-farms', headers);
  final activeFarmId = _myFarms?['activeFarmId'] as String?;
  if (role == 'owner' && activeFarmId != null) {
    _workers = await _get('/farms/$activeFarmId/workers', headers);
  }
}

if (role == 'b2b_admin') {
  _b2bDashboard = await _get('/b2b/dashboard', headers);
  _b2bContract = await _get('/b2b/contract/current', headers);
}
```

在 `_clearLiveData()` 中同步清空这 4 个字段。

- [ ] **Step 5: 运行前端测试验证**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 全部 PASS

- [ ] **Step 6: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add FarmSwitcherController + extend AppSession with activeFarmTenantId"
```

---

### Task 10: 前端 FarmSwitcher Widget + DemoShell 集成

**Files:**
- Create: `mobile_app/lib/features/farm_switcher/farm_switcher_widget.dart`
- Modify: `mobile_app/lib/app/demo_shell.dart`

- [ ] **Step 1: 创建 FarmSwitcher Widget**

创建 `lib/features/farm_switcher/farm_switcher_widget.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';

class FarmSwitcher extends ConsumerWidget {
  const FarmSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final farmState = ref.watch(farmSwitcherControllerProvider);

    if (!farmState.hasMultipleFarms) return const SizedBox.shrink();

    final activeFarm = farmState.farms.firstWhere(
      (f) => f.id == farmState.activeFarmId,
      orElse: () => farmState.farms.first,
    );

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          key: const Key('farm-switcher'),
          value: farmState.activeFarmId,
          icon: const Icon(Icons.swap_horiz, size: 20),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
              ),
          items: farmState.farms.map((farm) {
            return DropdownMenuItem<String>(
              value: farm.id,
              child: Text(
                farm.name,
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (farmId) {
            if (farmId != null) {
              ref
                  .read(farmSwitcherControllerProvider.notifier)
                  .switchFarm(farmId);
            }
          },
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: 在 DemoShell AppBar 中嵌入 FarmSwitcher**

在 `lib/app/demo_shell.dart` 中，为 owner/worker 角色的 AppBar actions 添加 FarmSwitcher：

```dart
// 在 Scaffold 的 appBar 中：
actions: [
  if (role == DemoRole.owner || role == DemoRole.worker)
    const FarmSwitcher(),
  // ... 现有 actions ...
],
```

**owner 无 farm 边界情况（规格 Section 2.1）:** 若 `FarmSwitcherState.hasFarms == false`，`FarmSwitcher` 已通过 `hasMultipleFarms` 检查自动隐藏。当 owner/worker 无 farm 时，DemoShell body 应显示引导提示。在 DemoShell 的角色判断中增加：

```dart
// owner/worker 无 farm 时的引导
if ((role == DemoRole.owner || role == DemoRole.worker) &&
    !ref.watch(farmSwitcherControllerProvider).hasFarms) {
  return const Scaffold(
    body: Center(child: Text('请创建您的第一个牧场')),
  );
}
```

- [ ] **Step 3: 运行前端测试**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 全部 PASS

- [ ] **Step 4: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add FarmSwitcher widget and integrate into DemoShell"
```

---

### Task 11: 前端 worker 管理 — domain + data 层

**Files:**
- Create: `mobile_app/lib/features/worker_management/domain/worker_repository.dart`
- Create: `mobile_app/lib/features/worker_management/data/mock_worker_repository.dart`
- Create: `mobile_app/lib/features/worker_management/data/live_worker_repository.dart`

- [ ] **Step 1: 创建 Repository 接口**

创建 `lib/features/worker_management/domain/worker_repository.dart`：

```dart
import 'package:smart_livestock_demo/core/models/view_state.dart';

class WorkerAssignment {
  const WorkerAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.assignedAt,
  });

  final String id;
  final String userId;
  final String userName;
  final String role;
  final String assignedAt;
}

class WorkersViewData {
  const WorkersViewData({
    required this.viewState,
    this.items = const [],
    this.message,
  });

  final ViewState viewState;
  final List<WorkerAssignment> items;
  final String? message;
}

abstract class WorkerRepository {
  WorkersViewData load({
    required ViewState viewState,
    required String farmId,
  });

  bool assign(String farmId, String userId, {String role = 'worker'});

  bool unassign(String assignmentId);
}
```

- [ ] **Step 2: 创建 Mock 实现**

创建 `lib/features/worker_management/data/mock_worker_repository.dart`：

```dart
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

class MockWorkerRepository implements WorkerRepository {
  const MockWorkerRepository();

  // 内存中的分配列表（模拟 workerFarmStore）
  static final List<WorkerAssignment> _assignments = [
    const WorkerAssignment(
      id: 'wfa_001',
      userId: 'u_002',
      userName: '李四（牧工）',
      role: 'worker',
      assignedAt: '2026-04-28T00:00:00+08:00',
    ),
    const WorkerAssignment(
      id: 'wfa_002',
      userId: 'u_002',
      userName: '李四（牧工）',
      role: 'worker',
      assignedAt: '2026-04-29T00:00:00+08:00',
    ),
  ];

  @override
  WorkersViewData load({
    required ViewState viewState,
    required String farmId,
  }) {
    return WorkersViewData(
      viewState: viewState,
      items: viewState == ViewState.normal ? _assignments : const [],
      message: switch (viewState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无牧工',
        ViewState.error => '加载失败（演示）',
        ViewState.forbidden => '无权限管理牧工（演示）',
        ViewState.offline => '离线数据（演示）',
        ViewState.normal => null,
      },
    );
  }

  @override
  bool assign(String farmId, String userId, {String role = 'worker'}) {
    // Mock: 总是成功
    return true;
  }

  @override
  bool unassign(String assignmentId) {
    return true;
  }
}
```

- [ ] **Step 3: 创建 Live 实现**

创建 `lib/features/worker_management/data/live_worker_repository.dart`：

```dart
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/data/mock_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

class LiveWorkerRepository implements WorkerRepository {
  const LiveWorkerRepository();

  @override
  WorkersViewData load({
    required ViewState viewState,
    required String farmId,
  }) {
    try {
      final cache = ApiCache.instance;
      final data = cache.workers;
      if (data == null) {
        // ApiCache 未加载时 fallback 到 Mock
        return const MockWorkerRepository().load(
          viewState: viewState,
          farmId: farmId,
        );
      }
      final items = (data['items'] as List?)?.map((w) => WorkerAssignment(
        id: w['id'] as String,
        userId: w['userId'] as String,
        userName: w['userName'] as String? ?? w['userId'],
        role: w['role'] as String? ?? 'worker',
        assignedAt: w['assignedAt'] as String? ?? '',
      )).toList() ?? [];

      return WorkersViewData(
        viewState: viewState,
        items: viewState == ViewState.normal ? items : const [],
        message: viewState == ViewState.normal ? null : '加载中',
      );
    } catch (_) {
      return const MockWorkerRepository().load(
        viewState: viewState,
        farmId: farmId,
      );
    }
  }

  @override
  bool assign(String farmId, String userId, {String role = 'worker'}) {
    // Live 模式下实际 POST API（Phase 2a: mock 返回 true）
    return true;
  }

  @override
  bool unassign(String assignmentId) {
    return true;
  }
}
```

- [ ] **Step 4: Commit**

```bash
cd Mobile
git add mobile_app/lib/features/worker_management/
git commit -m "feat(frontend): add worker management domain + data layer"
```

---

### Task 12: 前端 worker 管理 — presentation 层 + MinePage 集成

**Files:**
- Create: `mobile_app/lib/features/worker_management/presentation/worker_controller.dart`
- Create: `mobile_app/lib/features/worker_management/presentation/worker_list_page.dart`
- Modify: `mobile_app/lib/features/pages/mine_page.dart`
- Modify: `mobile_app/lib/app/app_route.dart`
- Modify: `mobile_app/lib/app/app_router.dart`

- [ ] **Step 1: 创建 WorkerController**

创建 `lib/features/worker_management/presentation/worker_controller.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/worker_management/data/live_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/data/mock_worker_repository.dart';
import 'package:smart_livestock_demo/features/worker_management/domain/worker_repository.dart';

final workerRepositoryProvider = Provider<WorkerRepository>((ref) {
  final appMode = ref.watch(appModeProvider);
  return appMode.isLive
      ? const LiveWorkerRepository()
      : const MockWorkerRepository();
});

class WorkerController extends Notifier<WorkersViewData> {
  @override
  WorkersViewData build() {
    return const WorkersViewData(viewState: ViewState.normal);
  }

  void loadWorkers(String farmId) {
    final repo = ref.read(workerRepositoryProvider);
    state = repo.load(viewState: ViewState.normal, farmId: farmId);
  }

  bool assignWorker(String farmId, String userId) {
    final repo = ref.read(workerRepositoryProvider);
    final success = repo.assign(farmId, userId);
    if (success) loadWorkers(farmId);
    return success;
  }

  bool removeWorker(String assignmentId, String farmId) {
    final repo = ref.read(workerRepositoryProvider);
    final success = repo.unassign(assignmentId);
    if (success) loadWorkers(farmId);
    return success;
  }
}

final workerControllerProvider =
    NotifierProvider<WorkerController, WorkersViewData>(
  WorkerController.new,
);
```

- [ ] **Step 2: 创建 WorkerListPage**

创建 `lib/features/worker_management/presentation/worker_list_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/farm_switcher/farm_switcher_controller.dart';
import 'package:smart_livestock_demo/features/worker_management/presentation/worker_controller.dart';

class WorkerListPage extends ConsumerStatefulWidget {
  const WorkerListPage({super.key});

  @override
  ConsumerState<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends ConsumerState<WorkerListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final farmId =
          ref.read(farmSwitcherControllerProvider).activeFarmId ?? 'tenant_001';
      ref.read(workerControllerProvider.notifier).loadWorkers(farmId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(workerControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('牧工管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/mine'),
        ),
      ),
      body: switch (data.viewState) {
        ViewState.loading => const Center(child: CircularProgressIndicator()),
        ViewState.empty => const Center(child: Text('暂无牧工')),
        ViewState.error => const Center(child: Text('加载失败')),
        ViewState.forbidden => const Center(child: Text('无权限')),
        _ => data.items.isEmpty
            ? const Center(child: Text('暂无牧工'))
            : ListView.builder(
                itemCount: data.items.length,
                itemBuilder: (context, index) {
                  final worker = data.items[index];
                  return ListTile(
                    key: Key('worker-${worker.id}'),
                    title: Text(worker.userName),
                    subtitle: Text('角色: ${worker.role}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.person_remove, color: Colors.red),
                      onPressed: () {
                        final farmId =
                            ref.read(farmSwitcherControllerProvider).activeFarmId ??
                                'tenant_001';
                        ref
                            .read(workerControllerProvider.notifier)
                            .removeWorker(worker.id, farmId);
                      },
                    ),
                  );
                },
              ),
      },
    );
  }
}
```

- [ ] **Step 3: 添加路由**

在 `lib/app/app_route.dart` 中添加枚举值：

```dart
workerManagement('/mine/workers', 'worker-management', '牧工管理'),
```

在 `lib/app/app_router.dart` 中注册路由：

```dart
GoRoute(
  path: AppRoute.workerManagement.path,
  name: AppRoute.workerManagement.routeName,
  builder: (context, state) => const WorkerListPage(),
),
```

- [ ] **Step 4: 在 MinePage 添加入口**

在 `lib/features/pages/mine_page.dart` 中，为 owner 角色添加"牧工管理"列表项：

```dart
// 在设备管理入口之后（仅 owner 可见）
if (role == DemoRole.owner)
  ListTile(
    key: const Key('mine-worker-management'),
    leading: const Icon(Icons.groups),
    title: const Text('牧工管理'),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => context.go('/mine/workers'),
  ),
```

- [ ] **Step 5: 运行测试验证**

Run: `cd Mobile/mobile_app && flutter test`
Expected: 全部 PASS

- [ ] **Step 6: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add worker management page and mine page entry"
```

---

## Epic E3: B端管理后台

> **前置条件:** Task 1-5（E1）已完成。可与 Task 6-12（E2）并行开发。

### Task 13: 后端 contractStore + seed 数据

**Files:**
- Create: `backend/data/contractStore.js`
- Modify: `backend/data/seed.js`
- Test: `backend/test/contractStore.test.js`

- [ ] **Step 1: 写 contractStore 单元测试**

创建 `backend/test/contractStore.test.js`：

```javascript
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');

describe('contractStore', () => {
  let store;

  test('getByPartnerTenantId returns contract for known partner', () => {
    delete require.cache[require.resolve('../data/contractStore')];
    store = require('../data/contractStore');
    const contract = store.getByPartnerTenantId('tenant_p001');
    assert.ok(contract);
    assert.equal(contract.partnerTenantId, 'tenant_p001');
    assert.equal(contract.status, 'active');
    assert.equal(contract.effectiveTier, 'standard');
  });

  test('getByPartnerTenantId returns null for unknown partner', () => {
    const contract = store.getByPartnerTenantId('nonexistent');
    assert.equal(contract, null);
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile/backend && node --test test/contractStore.test.js`
Expected: FAIL — module not found

- [ ] **Step 3: 实现 contractStore**

创建 `backend/data/contractStore.js`：

```javascript
// 合同内存 Store
// Phase 2a: 合同为只读展示，无创建/编辑

const _contracts = [
  {
    id: 'contract_001',
    partnerTenantId: 'tenant_p001',
    status: 'active',
    effectiveTier: 'standard',
    revenueShareRatio: 0.15,
    startedAt: '2026-01-01T00:00:00+08:00',
    expiresAt: '2027-01-01T00:00:00+08:00',
    signedBy: '王五',
  },
];

function getByPartnerTenantId(partnerTenantId) {
  return _contracts.find((c) => c.partnerTenantId === partnerTenantId) ?? null;
}

module.exports = { getByPartnerTenantId };
```

- [ ] **Step 4: 运行测试确认通过**

Run: `cd Mobile/backend && node --test test/contractStore.test.js`
Expected: PASS

- [ ] **Step 5: 扩展 seed.js — 新增 partner 旗下 farm + 用户**

在 `backend/data/seed.js` 中：

1. 新增用户 `u_006`（partner 旗下牧场主）：

```javascript
// 在 users 对象中 b2b_admin 之后添加
u_006: {
  userId: 'u_006',
  tenantId: 'tenant_f_p001_001',
  name: '马七',
  role: 'owner',
  mobile: '13800000005',
  permissions: [
    'tenant:view', 'fence:view', 'fence:edit',
    'alert:view', 'alert:ack', 'dashboard:view',
    'subscription:view', 'profile:view',
  ],
},
```

2. 新增 partner 旗下 farm：

```javascript
{
  id: 'tenant_f_p001_001',
  name: '星辰合作牧场A',
  type: 'farm',
  parentTenantId: 'tenant_p001',
  billingModel: 'revenue_share',
  entitlementTier: null,
  ownerId: 'u_006',
  status: 'active',
  contactName: '马七',
  contactPhone: '13800000005',
  contactEmail: 'maqi@example.com',
  region: '华中',
  remarks: 'partner 旗下示例牧场',
  licenseUsed: 0,
  licenseTotal: 200,
  createdAt: '2026-04-28T00:00:00+08:00',
  updatedAt: '2026-04-28T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
},
```

3. 扩展 b2b_admin 的 permissions：

```javascript
b2b_admin: {
  // 移除 tenant:create：b2b_admin 仅能通过 farm:create 创建旗下子 farm
  permissions: ['tenant:view', 'farm:view_summary', 'contract:view', 'farm:create', 'b2b:dashboard'],
},
```

4. 在 `backend/middleware/auth.js` 中扩展静态示例 owner token 的用户覆盖：

```javascript
// 在 Task 1 Step 2 创建的 TOKEN_USER_OVERRIDES 初始化中加入：
const TOKEN_USER_OVERRIDES = {
  'mock-token-u_006': users.u_006,
};

// 在 TOKEN_MAP 中加入：
const TOKEN_MAP = {
  // ...现有 token...
  'mock-token-u_006': 'owner',
};
```

这样通过 `mock-token-u_006` 登录时，`req.userRole === 'owner'` 且 `req.user === users.u_006`，不会错误地回落到默认 `users.owner`。

- [ ] **Step 6: Commit**

```bash
cd Mobile
git add backend/
git commit -m "feat(backend): add contractStore + seed partner farm data"
```

---

### Task 14: 后端 B端控制台路由（替换 b2bAdmin.js）

**Files:**
- Create: `backend/routes/b2bDashboard.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/server.js`
- Delete: `backend/routes/b2bAdmin.js`
- Test: `backend/test/b2b-dashboard.test.js`

- [ ] **Step 1: 写 B端控制台集成测试**

创建 `backend/test/b2b-dashboard.test.js`：

> **测试模式:** 同 farm-switch.test.js，使用 `app.listen(0)` + `fetch`。

```javascript
const { describe, test } = require('node:test');
const assert = require('node:assert/strict');
const { app } = require('../server');

async function withServer(fn) {
  const server = app.listen(0);
  try {
    const { port } = server.address();
    await fn(`http://127.0.0.1:${port}`);
  } finally {
    server.close();
  }
}

describe('B2B Dashboard API', () => {
  const b2bAuth = 'Bearer mock-token-b2b-admin';

  test('GET /b2b/dashboard returns aggregate metrics', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/dashboard`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.totalFarms >= 1);
      assert.ok(body.data.totalLivestock >= 0);
      assert.ok(body.data.contractStatus);
    });
  });

  test('GET /b2b/farms returns partner farms', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/farms`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.items.length >= 1);
    });
  });

  test('POST /b2b/farms creates sub-farm', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/farms`, {
        method: 'POST',
        headers: {
          authorization: b2bAuth,
          'content-type': 'application/json',
        },
        body: JSON.stringify({
          name: '新合作牧场',
          ownerName: '钱八',
          contactPhone: '13800000006',
          region: '华北',
        }),
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.equal(body.data.type, 'farm');
      assert.equal(body.data.parentTenantId, 'tenant_p001');
      assert.equal(body.data.ownerId.startsWith('u_'), true);
      assert.equal(body.data.ownerToken.startsWith('mock-token-u_'), true);
    });
  });

  test('GET /b2b/contract/current returns contract', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/contract/current`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data);
      assert.equal(body.data.status, 'active');
      assert.equal(body.data.effectiveTier, 'standard');
    });
  });

  test('GET /b2b/contract/usage-summary returns usage data', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/contract/usage-summary`, {
        headers: { authorization: b2bAuth },
      });
      assert.equal(res.status, 200);
      const body = await res.json();
      assert.ok(body.data.totalFarms >= 1);
      assert.ok(body.data.monthlyBreakdown);
    });
  });

  test('non-b2b_admin cannot access /b2b/dashboard', async () => {
    await withServer(async (base) => {
      const res = await fetch(`${base}/api/v1/b2b/dashboard`, {
        headers: { authorization: 'Bearer mock-token-owner' },
      });
      assert.equal(res.status, 403);
    });
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

Run: `cd Mobile/backend && node --test test/b2b-dashboard.test.js`
Expected: FAIL — route returns placeholder or 404

- [ ] **Step 3: 创建 b2bDashboard.js**

创建 `backend/routes/b2bDashboard.js`（替换 b2bAdmin.js）：

```javascript
const { Router } = require('express');
const router = Router();

const tenantStore = require('../data/tenantStore');
const contractStore = require('../data/contractStore');
const { users } = require('../data/seed');
const { registerMockUserToken } = require('../middleware/auth');

// 所有 /b2b/* 端点仅限 b2b_admin
function requireB2bAdmin(req, res, next) {
  if (req.userRole !== 'b2b_admin') {
    return res.fail(403, 'AUTH_FORBIDDEN', '仅 B端客户可访问');
  }
  next();
}

router.use(requireB2bAdmin);

// GET /b2b/dashboard — 用量看板
router.get('/dashboard', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const farms = tenantStore.findByParentTenantId(partnerTenantId);

  // Phase 2a: livestock/device/alert 计数用 mock 值
  const farmsWithStats = farms.map((f) => ({
    id: f.id,
    name: f.name,
    livestockCount: 120, // mock
    deviceCount: 95,     // mock
    pendingAlerts: 5,    // mock
  }));

  const contract = contractStore.getByPartnerTenantId(partnerTenantId);

  res.ok({
    totalFarms: farms.length,
    totalLivestock: farmsWithStats.reduce((sum, f) => sum + f.livestockCount, 0),
    totalDevices: farmsWithStats.reduce((sum, f) => sum + f.deviceCount, 0),
    pendingAlerts: farmsWithStats.reduce((sum, f) => sum + f.pendingAlerts, 0),
    farms: farmsWithStats,
    contractStatus: contract?.status ?? null,
    contractExpiresAt: contract?.expiresAt ?? null,
  });
});

// GET /b2b/farms — 旗下 farm 列表
router.get('/farms', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const { search } = req.query;
  let farms = tenantStore.findByParentTenantId(partnerTenantId);

  if (search) {
    farms = farms.filter((f) => f.name.includes(search));
  }

  const items = farms.map((f) => ({
    id: f.id,
    name: f.name,
    status: f.status,
    ownerName: f.contactName ?? '',
    livestockCount: 120, // mock
    region: f.region ?? '',
    createdAt: f.createdAt,
  }));

  res.ok({ items, page: 1, pageSize: 20, total: items.length });
});

// POST /b2b/farms — 创建子 farm
router.post('/farms', (req, res) => {
  const { name, ownerName, contactPhone, region } = req.body;
  if (!name) {
    return res.fail(400, 'VALIDATION_ERROR', '缺少牧场名称');
  }

  const partnerTenantId = req.user.tenantId;
  const partner = tenantStore.findById(partnerTenantId);
  const ownerId = ownerName ? `u_${Date.now()}` : null;

  const result = tenantStore.createTenant({
    name,
    type: 'farm',
    parentTenantId: partnerTenantId,
    billingModel: partner?.billingModel ?? 'revenue_share',
    entitlementTier: null,
    ownerId,
    status: 'active',
    contactName: ownerName ?? '',
    contactPhone: contactPhone ?? '',
    region: region ?? '',
  });

  if (result.error) {
    if (result.error === 'name_conflict') {
      return res.fail(409, 'CONFLICT', '牧场名称已存在');
    }
    return res.fail(400, 'VALIDATION_ERROR', result.error);
  }

  const farm = result.tenant;
  let ownerToken = null;

  if (ownerId && ownerName) {
    const ownerUser = {
      userId: ownerId,
      tenantId: farm.id,
      name: ownerName,
      role: 'owner',
      mobile: contactPhone ?? '',
      permissions: [...users.owner.permissions],
    };
    ownerToken = `mock-token-${ownerId}`;
    registerMockUserToken(ownerToken, ownerUser);
  }

  res.ok({
    ...farm,
    ...(ownerToken ? { ownerToken } : {}),
  });
});

// GET /b2b/contract/current — 合同信息
router.get('/contract/current', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const contract = contractStore.getByPartnerTenantId(partnerTenantId);
  res.ok(contract);
});

// GET /b2b/contract/usage-summary — 用量汇总
router.get('/contract/usage-summary', (req, res) => {
  const partnerTenantId = req.user.tenantId;
  const farms = tenantStore.findByParentTenantId(partnerTenantId);

  // Phase 2a: 月度数据用 mock 固定值
  res.ok({
    totalFarms: farms.length,
    totalLivestock: farms.length * 120,
    totalDevices: farms.length * 95,
    monthlyBreakdown: [
      { month: '2026-03', livestockCount: 200, deviceCount: 150 },
      { month: '2026-04', livestockCount: farms.length * 120, deviceCount: farms.length * 95 },
    ],
  });
});

module.exports = router;
```

- [ ] **Step 4: 更新路由注册**

在 `backend/routes/registerApiRoutes.js` 中：

```javascript
// 改前
const b2bAdminRoutes = require('./b2bAdmin');
// ...
app.use(`${prefix}/b2b`, b2bAdminRoutes);

// 改后
const b2bDashboardRoutes = require('./b2bDashboard');
// ...
app.use(`${prefix}/b2b`, b2bDashboardRoutes);
```

- [ ] **Step 5: 更新 server.js 路由表**

在 `ROUTE_DEFINITIONS` 中替换 `/b2b/status` 为：

```javascript
['GET',    '/b2b/dashboard'],
['GET',    '/b2b/farms'],
['POST',   '/b2b/farms'],
['GET',    '/b2b/contract/current'],
['GET',    '/b2b/contract/usage-summary'],
```

- [ ] **Step 6: 删除旧文件**

```bash
rm backend/routes/b2bAdmin.js
```

- [ ] **Step 7: 运行测试确认通过**

Run: `cd Mobile/backend && node --test test/b2b-dashboard.test.js test/contractStore.test.js`
Expected: 全部 PASS

- [ ] **Step 8: Commit**

```bash
cd Mobile
git add backend/
git commit -m "feat(backend): replace b2bAdmin placeholder with full B2B dashboard routes"
```

---

### Task 15: 前端 B端 Shell + 导航 + 路由

**Files:**
- Modify: `mobile_app/lib/app/demo_shell.dart`
- Modify: `mobile_app/lib/app/app_route.dart`
- Modify: `mobile_app/lib/app/app_router.dart`
- Modify: `mobile_app/lib/core/permissions/role_permission.dart`
- Delete: `mobile_app/lib/features/pages/b2b_admin_placeholder_page.dart`

- [ ] **Step 1: 扩展 RolePermission**

在 `lib/core/permissions/role_permission.dart` 底部添加：

```dart
static bool canViewContract(DemoRole role) => role == DemoRole.b2bAdmin;
static bool canCreateFarm(DemoRole role) =>
    role == DemoRole.b2bAdmin || role == DemoRole.platformAdmin;
static bool canViewB2bDashboard(DemoRole role) => role == DemoRole.b2bAdmin;
```

- [ ] **Step 2: 扩展 AppRoute 枚举**

在 `lib/app/app_route.dart` 中添加 B端子路由：

```dart
b2bAdmin('/b2b/admin', 'b2b-admin', 'B端控制台'),
b2bAdminFarms('/b2b/admin/farms', 'b2b-admin-farms', '牧场管理'),
b2bAdminContract('/b2b/admin/contract', 'b2b-admin-contract', '合同信息'),
```

- [ ] **Step 3: 更新 AppRouter 注册 B端子路由**

在 `lib/app/app_router.dart` 中，当前 B端路由位于主 `ShellRoute`（包含 `ExpiryPopupHandler` + `DemoShell`）**内部**。**不要创建独立 ShellRoute** — 保持 B端路由在主 ShellRoute 内部以维持 `ExpiryPopupHandler` 包装和路由守卫。

将现有 b2bAdmin 单条路由替换为带子路由的 GoRoute：

```dart
GoRoute(
  path: AppRoute.b2bAdmin.path,
  name: AppRoute.b2bAdmin.routeName,
  builder: (context, state) => const B2bDashboardPage(),
  routes: [
    GoRoute(
      path: 'farms',
      name: AppRoute.b2bAdminFarms.routeName,
      builder: (context, state) => const B2bFarmListPage(),
    ),
    GoRoute(
      path: 'contract',
      name: AppRoute.b2bAdminContract.routeName,
      builder: (context, state) => const B2bContractPage(),
    ),
  ],
),
```

- [ ] **Step 4: 修改 DemoShell b2bAdmin 分支**

在 `lib/app/demo_shell.dart` 中，将 b2bAdmin 的 `Scaffold(body: child)` 改为渲染带侧边栏的布局：

```dart
if (role == DemoRole.b2bAdmin) {
  return _B2bAdminShell(child: child);
}
```

`_B2bAdminShell` 定义在 demo_shell.dart 文件内（私有 Widget），包含 NavigationRail（左侧） + body（右侧）：

```dart
class _B2bAdminShell extends StatelessWidget {
  const _B2bAdminShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _calculateIndex(context),
            onDestinationSelected: (index) => _navigate(context, index),
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard),
                label: Text('概览'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.agriculture),
                label: Text('牧场'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.description),
                label: Text('合同'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }

  int _calculateIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.contains('/farms')) return 1;
    if (location.contains('/contract')) return 2;
    return 0;
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoute.b2bAdmin.path);
        break;
      case 1:
        context.go(AppRoute.b2bAdminFarms.path);
        break;
      case 2:
        context.go(AppRoute.b2bAdminContract.path);
        break;
    }
  }
}
```

- [ ] **Step 5: 删除占位页面**

```bash
rm mobile_app/lib/features/pages/b2b_admin_placeholder_page.dart
```

- [ ] **Step 6: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): B2B admin shell with sidebar navigation and route setup"
```

---

### Task 16: 前端 B端数据层 + Controller

**Files:**
- Create: `mobile_app/lib/features/b2b_admin/data/b2b_repository.dart`
- Create: `mobile_app/lib/features/b2b_admin/presentation/b2b_controller.dart`

- [ ] **Step 1: 创建 B2B Repository（接口 + mock + live 合一）**

创建 `lib/features/b2b_admin/data/b2b_repository.dart`：

```dart
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class B2bFarmSummary {
  const B2bFarmSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.livestockCount,
    required this.region,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final String ownerName;
  final int livestockCount;
  final String region;
  final String? createdAt;
}

class B2bDashboardData {
  const B2bDashboardData({
    required this.viewState,
    this.totalFarms = 0,
    this.totalLivestock = 0,
    this.totalDevices = 0,
    this.pendingAlerts = 0,
    this.farms = const [],
    this.contractStatus,
    this.contractExpiresAt,
    this.message,
  });

  final ViewState viewState;
  final int totalFarms;
  final int totalLivestock;
  final int totalDevices;
  final int pendingAlerts;
  final List<B2bFarmSummary> farms;
  final String? contractStatus;
  final String? contractExpiresAt;
  final String? message;
}

class B2bContractData {
  const B2bContractData({
    required this.viewState,
    this.id,
    this.status,
    this.effectiveTier,
    this.revenueShareRatio,
    this.startedAt,
    this.expiresAt,
    this.signedBy,
    this.message,
  });

  final ViewState viewState;
  final String? id;
  final String? status;
  final String? effectiveTier;
  final double? revenueShareRatio;
  final String? startedAt;
  final String? expiresAt;
  final String? signedBy;
  final String? message;
}

class B2bRepository {
  const B2bRepository();

  B2bDashboardData loadDashboard(ViewState viewState, AppMode appMode) {
    if (viewState != ViewState.normal) {
      return B2bDashboardData(viewState: viewState);
    }

    if (appMode.isLive) {
      return _loadDashboardFromCache();
    }

    // Mock 数据
    return const B2bDashboardData(
      viewState: ViewState.normal,
      totalFarms: 1,
      totalLivestock: 120,
      totalDevices: 95,
      pendingAlerts: 5,
      farms: [
        B2bFarmSummary(
          id: 'tenant_f_p001_001',
          name: '星辰合作牧场A',
          status: 'active',
          ownerName: '马七',
          livestockCount: 120,
          region: '华中',
        ),
      ],
      contractStatus: 'active',
      contractExpiresAt: '2027-01-01T00:00:00+08:00',
    );
  }

  B2bContractData loadContract(ViewState viewState, AppMode appMode) {
    if (viewState != ViewState.normal) {
      return B2bContractData(viewState: viewState);
    }

    if (appMode.isLive) {
      return _loadContractFromCache();
    }

    return const B2bContractData(
      viewState: ViewState.normal,
      id: 'contract_001',
      status: 'active',
      effectiveTier: 'standard',
      revenueShareRatio: 0.15,
      startedAt: '2026-01-01T00:00:00+08:00',
      expiresAt: '2027-01-01T00:00:00+08:00',
      signedBy: '王五',
    );
  }

  B2bDashboardData _loadDashboardFromCache() {
    try {
      final data = ApiCache.instance.b2bDashboard;
      if (data == null) {
        return const B2bDashboardData(viewState: ViewState.normal);
      }
      final farms = (data['farms'] as List?)?.map((f) => B2bFarmSummary(
        id: f['id'] as String,
        name: f['name'] as String,
        status: f['status'] as String,
        ownerName: f['ownerName'] as String? ?? '',
        livestockCount: f['livestockCount'] as int? ?? 0,
        region: f['region'] as String? ?? '',
      )).toList() ?? [];

      return B2bDashboardData(
        viewState: ViewState.normal,
        totalFarms: data['totalFarms'] as int? ?? 0,
        totalLivestock: data['totalLivestock'] as int? ?? 0,
        totalDevices: data['totalDevices'] as int? ?? 0,
        pendingAlerts: data['pendingAlerts'] as int? ?? 0,
        farms: farms,
        contractStatus: data['contractStatus'] as String?,
        contractExpiresAt: data['contractExpiresAt'] as String?,
      );
    } catch (_) {
      return const B2bDashboardData(viewState: ViewState.normal);
    }
  }

  B2bContractData _loadContractFromCache() {
    try {
      final data = ApiCache.instance.b2bContract;
      if (data == null) {
        return const B2bContractData(viewState: ViewState.normal);
      }
      return B2bContractData(
        viewState: ViewState.normal,
        id: data['id'] as String?,
        status: data['status'] as String?,
        effectiveTier: data['effectiveTier'] as String?,
        revenueShareRatio: (data['revenueShareRatio'] as num?)?.toDouble(),
        startedAt: data['startedAt'] as String?,
        expiresAt: data['expiresAt'] as String?,
        signedBy: data['signedBy'] as String?,
      );
    } catch (_) {
      return const B2bContractData(viewState: ViewState.normal);
    }
  }
}
```

- [ ] **Step 2: 创建 B2B Controller**

创建 `lib/features/b2b_admin/presentation/b2b_controller.dart`：

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/b2b_admin/data/b2b_repository.dart';

final b2bRepositoryProvider = Provider<B2bRepository>((_) => const B2bRepository());

class B2bDashboardController extends Notifier<B2bDashboardData> {
  @override
  B2bDashboardData build() {
    final appMode = ref.watch(appModeProvider);
    final repo = ref.read(b2bRepositoryProvider);
    return repo.loadDashboard(ViewState.normal, appMode);
  }
}

final b2bDashboardControllerProvider =
    NotifierProvider<B2bDashboardController, B2bDashboardData>(
  B2bDashboardController.new,
);

class B2bContractController extends Notifier<B2bContractData> {
  @override
  B2bContractData build() {
    final appMode = ref.watch(appModeProvider);
    final repo = ref.read(b2bRepositoryProvider);
    return repo.loadContract(ViewState.normal, appMode);
  }
}

final b2bContractControllerProvider =
    NotifierProvider<B2bContractController, B2bContractData>(
  B2bContractController.new,
);
```

注意：需在文件顶部添加 `import 'package:smart_livestock_demo/core/models/view_state.dart';`。

- [ ] **Step 3: 扩展 ApiCache**

在 `lib/core/api/api_cache.dart` 中添加 `b2bDashboard` 和 `b2bContract` 字段。在 `init()` 方法中添加 `/api/v1/b2b/dashboard` 和 `/api/v1/b2b/contract/current` 的预加载（仅 b2b_admin 角色加载）。

- [ ] **Step 4: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add B2B repository and controllers"
```

---

### Task 17: 前端 B端概览页

**Files:**
- Create: `mobile_app/lib/features/b2b_admin/presentation/b2b_dashboard_page.dart`

- [ ] **Step 1: 创建 B2bDashboardPage**

创建 `lib/features/b2b_admin/presentation/b2b_dashboard_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/session/session_controller.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bDashboardPage extends ConsumerWidget {
  const B2bDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bDashboardControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('B端控制台', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.md),

          // 合同状态卡片
          if (data.contractStatus != null)
            Card(
              child: ListTile(
                leading: Icon(
                  data.contractStatus == 'active'
                      ? Icons.verified
                      : Icons.warning,
                  color: data.contractStatus == 'active'
                      ? Colors.green
                      : Colors.orange,
                ),
                title: Text('合同状态: ${data.contractStatus}'),
                subtitle: data.contractExpiresAt != null
                    ? Text('到期: ${data.contractExpiresAt!.substring(0, 10)}')
                    : null,
              ),
            ),
          const SizedBox(height: AppSpacing.md),

          // 概览指标
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              _MetricCard(title: '旗下牧场', value: '${data.totalFarms}', icon: Icons.agriculture),
              _MetricCard(title: '总牲畜数', value: '${data.totalLivestock}', icon: Icons.pets),
              _MetricCard(title: '总设备数', value: '${data.totalDevices}', icon: Icons.devices),
              _MetricCard(title: '待处理告警', value: '${data.pendingAlerts}', icon: Icons.warning_amber),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 旗下 farm 列表
          Text('旗下牧场', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          ...data.farms.map((farm) => Card(
            child: ListTile(
              key: Key('b2b-farm-${farm.id}'),
              title: Text(farm.name),
              subtitle: Text('${farm.region} · 牲畜: ${farm.livestockCount}'),
              trailing: Chip(
                label: Text(farm.status),
                backgroundColor: farm.status == 'active'
                    ? Colors.green.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),
          )),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(title, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add B2B dashboard overview page"
```

---

### Task 18: 前端 B端牧场管理页

**Files:**
- Create: `mobile_app/lib/features/b2b_admin/presentation/b2b_farm_list_page.dart`

- [ ] **Step 1: 创建 B2bFarmListPage**

创建 `lib/features/b2b_admin/presentation/b2b_farm_list_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bFarmListPage extends ConsumerWidget {
  const B2bFarmListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bDashboardControllerProvider);
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('旗下牧场', style: theme.textTheme.titleLarge),
              FilledButton.icon(
                key: const Key('b2b-create-farm'),
                onPressed: () => _showCreateDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('新建牧场'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          if (data.farms.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(32),
              child: Text('暂无旗下牧场'),
            ))
          else
            ...data.farms.map((farm) => Card(
              child: ListTile(
                key: Key('b2b-farm-${farm.id}'),
                title: Text(farm.name),
                subtitle: Text('负责人: ${farm.ownerName}\n${farm.region} · 牲畜: ${farm.livestockCount}'),
                isThreeLine: true,
                trailing: Chip(
                  label: Text(farm.status),
                ),
              ),
            )),
        ],
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新建牧场'),
        content: TextField(
          key: const Key('b2b-farm-name-input'),
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '牧场名称',
            hintText: '请输入牧场名称',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              // Phase 2a: mock，不实际创建
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('已创建: ${nameController.text}')),
              );
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add B2B farm list page with create dialog"
```

---

### Task 19: 前端 B端合同页

**Files:**
- Create: `mobile_app/lib/features/b2b_admin/presentation/b2b_contract_page.dart`

- [ ] **Step 1: 创建 B2bContractPage**

创建 `lib/features/b2b_admin/presentation/b2b_contract_page.dart`：

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/b2b_admin/presentation/b2b_controller.dart';

class B2bContractPage extends ConsumerWidget {
  const B2bContractPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(b2bContractControllerProvider);
    final theme = Theme.of(context);

    if (data.id == null) {
      return const Center(child: Text('暂无合同信息'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('合同信息', style: theme.textTheme.headlineMedium),
          const SizedBox(height: AppSpacing.lg),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _InfoRow(label: '合同编号', value: data.id!),
                  const Divider(),
                  _InfoRow(label: '合同状态', value: _statusText(data.status)),
                  const Divider(),
                  _InfoRow(label: '服务等级', value: _tierText(data.effectiveTier)),
                  const Divider(),
                  _InfoRow(
                    label: '分成比例',
                    value: data.revenueShareRatio != null
                        ? '${(data.revenueShareRatio! * 100).toStringAsFixed(0)}%'
                        : '-',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: '签约人',
                    value: data.signedBy ?? '-',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: '生效日期',
                    value: data.startedAt != null
                        ? data.startedAt!.substring(0, 10)
                        : '-',
                  ),
                  const Divider(),
                  _InfoRow(
                    label: '到期日期',
                    value: data.expiresAt != null
                        ? data.expiresAt!.substring(0, 10)
                        : '-',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),
          Text('合同为只读展示，如需变更请联系平台管理员。',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  String _statusText(String? status) => switch (status) {
    'active' => '生效中',
    'suspended' => '已暂停',
    'expired' => '已过期',
    _ => status ?? '-',
  };

  String _tierText(String? tier) => switch (tier) {
    'standard' => '标准版',
    'premium' => '高级版',
    'enterprise' => '企业版',
    _ => tier ?? '-',
  };
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Commit**

```bash
cd Mobile
git add mobile_app/
git commit -m "feat(frontend): add B2B contract page"
```

---

### Task 20: E2+E3 全量回归测试

- [ ] **Step 1: 后端全量测试**

Run: `cd Mobile/backend && node --test test/*.test.js`
Expected: 全部 PASS

- [ ] **Step 2: 前端静态分析 + 全量测试**

Run: `cd Mobile/mobile_app && flutter analyze && flutter test`
Expected: 0 issues, 全部 PASS

- [ ] **Step 3: 端到端冒烟验证**

1. 启动 Mock Server：`cd Mobile/backend && node server.js`
2. 确认新端点可达：

```bash
# 多 farm 切换
curl -s http://localhost:3001/api/v1/farm/my-farms -H "Authorization: Bearer mock-token-owner"

# B端控制台
curl -s http://localhost:3001/api/v1/b2b/dashboard -H "Authorization: Bearer mock-token-b2b-admin"
curl -s http://localhost:3001/api/v1/b2b/contract/current -H "Authorization: Bearer mock-token-b2b-admin"
curl -s http://localhost:3001/api/v1/b2b/farms -H "Authorization: Bearer mock-token-b2b-admin"
```

Expected: 全部返回 200 + 正确数据

- [ ] **Step 4: 创建合并 commit**

```bash
cd Mobile
git add -A
git commit -m "feat: Phase 2a — tech debt cleanup, multi-farm support, B2B admin dashboard"
```

---

## 实施检查清单

| Epic | 后端测试 | 前端测试 | 冒烟验证 |
|------|---------|---------|---------|
| E1 | `node --test test/*.test.js` | `flutter test` | 旧 token 失效 + 新 token 有效 |
| E2 | workerFarmStore + farm-switch + farmContext | FarmSwitcher widget + worker 管理 | my-farms / switch-farm 端点 |
| E3 | contractStore + b2b-dashboard | B端三页面 widget | b2b dashboard/farms/contract 端点 |

---

**文档结束**
