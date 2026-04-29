# 统一商业模型 Phase 2a 设计规格

> **文档编号**: SL-BIZ-2026-002
> **版本**: v1.1
> **编制日期**: 2026-04-29
> **修订日期**: 2026-04-29
> **状态**: 已修订（按 R1 评审报告修复 6 个 P0 + 10 个 P1 问题）
> **受众**: 产品经理 + 技术团队
> **前置文档**: `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.3)
> **前置计划**: `docs/superpowers/plans/2026-04-28-unified-business-model-phase1.md`（Phase 1 已完成）

---

## 概述

Phase 2a 是统一商业模型 Phase 2 的第一个子阶段，聚焦三项交付：

1. **E1: 技术债清理** — ops→platform_admin 全局改名 + applyMockShaping 接通 + ownerId 唯一约束移除
2. **E2: 多 farm 支持** — owner 多 farm 切换 + worker 多 farm 分配 + farmContextMiddleware 扩展
3. **E3: B端管理后台** — b2b_admin 完整 UI（用量看板 + 旗下 farm 管理 + 合同信息）+ ContractStore 真实逻辑

**依赖关系**：E1 先行，E2 和 E3 可并行开发。

**不在 Phase 2a 范围**（留给 Phase 2b/2c）：
- 分润引擎 + 对账看板
- License 激活 + 心跳监控
- API 开放平台 `/api/open/v1/*`
- LicenseStore / ApiTierStore 真实逻辑
- Phase 2 专用字段（licenseKey, heartbeatAt, apiKey, apiCallQuota 等）

---

## E1: 技术债清理

### 1.1 ops → platform_admin 改名

全局替换 `ops` 角色为 `platform_admin`，消除语义歧义。

**后端改动**：

| 文件 | 改动 |
|------|------|
| `backend/data/seed.js` | `users.ops` → `users.platform_admin`；`role: 'ops'` → `role: 'platform_admin'` |
| `backend/middleware/auth.js` | `TOKEN_MAP` value `'ops'` → `'platform_admin'`；token key `'mock-token-ops'` → `'mock-token-platform-admin'` |
| `backend/routes/b2bAdmin.js` | 无需改动（仅检查 `'b2b_admin'` 角色，不涉及 ops） |
| `backend/test/*.js`（约 12 个文件） | 所有 `'ops'` 角色字符串替换为 `'platform_admin'` |

**前端改动**：

| 文件 | 改动 |
|------|------|
| `lib/core/models/demo_role.dart` | `DemoRole.ops` → `DemoRole.platformAdmin` |
| `lib/app/session/app_session.dart` | `isOps` → `isPlatformAdmin` |
| `lib/core/permissions/role_permission.dart` | 所有 `DemoRole.ops` 引用更新 |
| `lib/app/app_route.dart` | 守卫逻辑中 ops → platformAdmin |
| `lib/app/app_router.dart` | 路由守卫条件更新 |
| `lib/app/demo_shell.dart` | 导航判断中 ops → platformAdmin |
| `lib/features/auth/login_page.dart` | 角色按钮文案："运维管理员" → "平台管理员" |
| `test/*.dart`（约 10+ 个文件） | 所有 `DemoRole.ops` 引用更新 |

**Token 变更**：

```
旧: mock-token-ops       → role 'ops'
新: mock-token-platform-admin → role 'platform_admin'
```

**命名一致性规则**：
- Dart 枚举：`DemoRole.platformAdmin`（lowerCamelCase）
- 后端字符串：`'platform_admin'`（snake_case）
- 显示文案："平台管理员"
- Token 字符串：`mock-token-platform-admin`（角色名中的 `_` 替换为 `-`，与 `mock-token-b2b-admin` 命名约定一致）

**路由路径**：前端路由路径 `/ops/admin` 保留不变（`AppRoute.opsAdmin` → 未来改名为 `AppRoute.platformAdmin`，但 URL path `/ops/admin` 保持兼容）。E1 仅改枚举名和显示文案，不改 URL。

### 1.2 applyMockShaping 接通

**问题**：`applyMockShaping` 函数签名接受 `Map<String, dynamic>`，但 Repository 返回强类型 ViewData。

**方案**：修改 `apply_mock_shaping.dart` 的签名，接受 ViewData 并在内部提取 data map：

```dart
// 改前
Map<String, dynamic> applyMockShaping(
  Map<String, dynamic> data,
  SubscriptionTier tier,
  List<String> featureKeys,
)

// 改后
ViewData applyMockShaping(
  ViewData viewData,
  SubscriptionTier tier,
  List<String> featureKeys,
)
```

**受影响的 Mock Repository**（需在返回前调用 `applyMockShaping`）：
- `mock_alert_repository.dart`（feature: `alert_history`）
- `mock_fence_repository.dart`（feature: `fence`）
- `mock_dashboard_repository.dart`（feature: `dashboard_summary`）
- `mock_stats_repository.dart`（feature: `stats`）
- 其他返回需 shaping 的数据的 repository（根据 feature key 逐个判断）

### 1.3 ownerId 唯一约束

Phase 1 计划中声明 `ownerId` 唯一约束，但实际代码 `tenantStore.createTenant()` 未实现该校验。E1 无需改动后端代码，仅在 `tenantStore.createTenant()` 注释中标注 `ownerId` 允许多个 farm 共享同一 owner。seed 数据不变。

---

## E2: 多 farm 支持

### 2.1 owner 多 farm 切换

**后端**：

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/my-farms` | GET | 返回当前 owner/worker 关联的所有 farm 列表 | owner, worker |
| `/api/v1/switch-farm` | POST | 验证 farm 可用性（仅返回确认，不设服务端 session） | owner, worker |

**`GET /api/v1/my-farms` 响应**：

```json
{
  "code": 200,
  "data": {
    "items": [
      {
        "id": "tenant_001",
        "name": "张三的牧场",
        "status": "active",
        "livestockCount": 45,
        "region": "华中"
      }
    ],
    "activeFarmId": "tenant_001"
  }
}
```

- owner：`items` 来自 `tenantStore.findByOwnerId(userId)`
- worker：`items` 来自 `workerFarmStore.findByUserId(userId)` 映射 farm 详情
- `activeFarmId`：来自 `req.headers['x-active-farm']`，若无 header 则取 items[0].id

**`POST /api/v1/switch-farm` 请求/响应**：

```json
// 请求
{ "farmTenantId": "tenant_007" }

// 成功响应
{ "code": 200, "data": { "activeFarmId": "tenant_007", "farmName": "张三的第二牧场" } }

// 错误：farm 不属于当前用户
{ "code": 403, "message": "无权切换到该牧场" }

// 错误：farm 不存在
{ "code": 404, "message": "牧场不存在" }
```

**farm 切换机制**：客户端在每次请求中通过 `x-active-farm` header 携带当前活跃 farm ID。`switch-farm` 端点仅做权限校验（确认该 farm 属于当前用户），不做服务端 session 存储。前端 `FarmSwitcherController` 维护 `activeFarmTenantId` 状态，切换时更新状态并在后续请求中自动注入 header。

**`farmContextMiddleware` 扩展**（替换 Phase 1 版本）：

```javascript
function farmContextMiddleware(req, res, next) {
  // 优先使用客户端指定的活跃 farm
  const headerFarmId = req.headers['x-active-farm'];

  if (req.user?.role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    if (headerFarmId && farms.some(f => f.id === headerFarmId)) {
      req.activeFarmTenantId = headerFarmId;
    } else {
      req.activeFarmTenantId = farms.length > 0 ? farms[0].id : null;
    }
  } else if (req.user?.role === 'worker') {
    const assignments = workerFarmStore.findByUserId(req.user.userId);
    const farmIds = assignments.map(a => a.farmTenantId);
    if (headerFarmId && farmIds.includes(headerFarmId)) {
      req.activeFarmTenantId = headerFarmId;
    } else {
      req.activeFarmTenantId = farmIds.length > 0 ? farmIds[0] : null;
    }
  } else {
    req.activeFarmTenantId = null;
  }
  next();
}
```

**前端**：

| 组件 | 说明 |
|------|------|
| `FarmSwitcher` | 全局下拉组件，嵌入 DemoShell AppBar（仅 owner/worker 可见）。显示当前 farm 名称，下拉展示所有关联 farm，点击切换 |
| `FarmSwitcherController` | Riverpod Notifier，管理 activeFarmTenantId 状态。切换 farm 后通知所有依赖 farm context 的 Controller 刷新数据 |

`AppSession` 扩展：新增 `activeFarmTenantId` 字段。登录时默认取第一个 farm。该字段仅保存在内存（Riverpod state），不跨会话持久化。

**owner 无 farm 边界情况**：若 `my-farms` 返回空列表，前端显示引导页面（"请创建您的第一个牧场"），FarmSwitcher 隐藏。各业务页面显示 EmptyState。

**seed 数据扩展**：为 owner（张三）新增第二个 farm 用于演示切换：

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
  // 其余字段同现有 farm
}
```

### 2.2 worker 多 farm 分配

**新增 `workerFarmStore`**（`backend/data/workerFarmStore.js`）：

```
字段: { id, userId, farmTenantId, role: 'worker'|'supervisor', assignedAt }
```

辅助方法：`findByUserId(userId)`、`findByFarmId(farmTenantId)`、`assign(userId, farmTenantId, role)`、`unassign(assignmentId)`。

**后端端点**：

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/farms/:farmId/workers` | GET | 某 farm 的 worker 列表 | owner, platform_admin |
| `/api/v1/farms/:farmId/workers` | POST | 分配 worker 到 farm，body: `{ userId, role }` | owner, platform_admin |
| `/api/v1/farms/:farmId/workers/:id` | DELETE | 移除分配 | owner, platform_admin |

**farmContextMiddleware 适配 worker**：worker 登录后，从 `workerFarmStore.findByUserId()` 获取分配的 farm 列表。若分配到多个 farm，同样通过 `x-active-farm` header 切换。

**前端**：
- owner 的"我的"页面新增"牧工管理"入口，可查看/分配/移除 worker
- worker 的 FarmSwitcher 显示其被分配的 farm 列表
- **无需新增前端路由**：牧工管理作为 MinePage 的子页面（`/mine/workers`），不是独立导航 Tab

**后端端点响应定义**：

`GET /api/v1/farms/:farmId/workers`：
```json
{
  "code": 200,
  "data": {
    "items": [
      { "id": "wfa_001", "userId": "u_002", "userName": "李四", "role": "worker", "assignedAt": "2026-04-28T..." }
    ],
    "total": 1
  }
}
```
权限校验：owner 只能查自己 farm（`findByOwnerId` 包含 farmId），platform_admin 可查任意。

`POST /api/v1/farms/:farmId/workers`：
```json
// 请求
{ "userId": "u_002", "role": "worker" }
// 成功响应
{ "code": 200, "data": { "id": "wfa_003", "userId": "u_002", "farmTenantId": "tenant_001", "role": "worker", "assignedAt": "..." } }
// 错误：已分配
{ "code": 409, "message": "该牧工已分配到此牧场" }
// 错误：用户不存在
{ "code": 404, "message": "用户不存在" }
```

`DELETE /api/v1/farms/:farmId/workers/:id`：
```json
{ "code": 200, "data": { "removed": true } }
```

**seed 数据**（完整定义）：

```javascript
// workerFarmStore 初始数据
{ id: 'wfa_001', userId: 'u_002', farmTenantId: 'tenant_001', role: 'worker', assignedAt: '2026-04-28T00:00:00+08:00' },
{ id: 'wfa_002', userId: 'u_002', farmTenantId: 'tenant_007', role: 'worker', assignedAt: '2026-04-29T00:00:00+08:00' },
```

---

## E3: B端管理后台

### 3.1 b2b_admin 导航结构

替换 Phase 1 占位页面，交付三个核心模块。

**B端 Shell 实现**：修改现有 `DemoShell`，当 `role == DemoRole.b2bAdmin` 时渲染带侧边栏的 `Scaffold`（`Drawer` 或 `NavigationRail`），替代 Phase 1 的空 Scaffold。不新建 Shell 组件，在 DemoShell 内部通过 role 分支渲染。`B2bAdminPlaceholderPage` 被替换为 `B2bDashboardPage`。

**导航结构**：

```
B端控制台（侧边栏导航，无底部 Tab）
├── 概览（用量看板）
├── 牧场管理（旗下 farm 列表 + 创建子 farm）
└── 合同信息（只读）
```

**前端路由**：复用现有 `AppRoute.b2bAdmin`（`/b2b/admin`），新增子路由：
- `/b2b/admin` → B2bDashboardPage（概览，默认页）
- `/b2b/admin/farms` → B2bFarmListPage
- `/b2b/admin/contract` → B2bContractPage

### 3.2 用量看板

聚合展示旗下所有 farm 的关键指标：

| 指标 | 数据来源 |
|------|---------|
| 总牲畜数 | 各 farm 的 cattleStore 按 parentTenantId 聚合 |
| 总设备数 | 各 farm 的 devicesStore 聚合 |
| 待处理告警数 | alertsStore 按 farmTenantId 聚合 |
| farm 数量 | tenantStore.findByParentTenantId() |

端点：`GET /api/v1/b2b/dashboard`

**响应结构**：

```json
{
  "code": 200,
  "data": {
    "totalFarms": 3,
    "totalLivestock": 245,
    "totalDevices": 180,
    "pendingAlerts": 12,
    "farms": [
      {
        "id": "tenant_f_p001_001",
        "name": "星辰合作牧场A",
        "livestockCount": 120,
        "deviceCount": 95,
        "pendingAlerts": 5
      }
    ],
    "contractStatus": "active",
    "contractExpiresAt": "2027-01-01T00:00:00+08:00"
  }
}
```

### 3.3 旗下 farm 管理

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/b2b/farms` | GET | 旗下 farm 列表（分页、搜索） | b2b_admin |
| `/api/v1/b2b/farms` | POST | 创建子 farm | b2b_admin |

**`GET /api/v1/b2b/farms` 响应**：

```json
{
  "code": 200,
  "data": {
    "items": [
      {
        "id": "tenant_f_p001_001",
        "name": "星辰合作牧场A",
        "status": "active",
        "ownerName": "马七",
        "livestockCount": 120,
        "region": "华中",
        "createdAt": "2026-04-28T..."
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 3
  }
}
```
支持 `?search=xxx` 按名称模糊搜索。

**`POST /api/v1/b2b/farms` 请求/响应**：

```json
// 请求（必填：name；可选：ownerName, contactPhone, region）
{
  "name": "新合作牧场",
  "ownerName": "钱八",
  "contactPhone": "13800000006",
  "region": "华北"
}

// 成功响应
{
  "code": 200,
  "data": {
    "id": "tenant_f_p001_002",
    "name": "新合作牧场",
    "type": "farm",
    "parentTenantId": "tenant_p001",
    "billingModel": "revenue_share",
    "entitlementTier": null,
    "status": "active"
  }
}
```

创建子 farm 逻辑：
1. `type='farm'`，`parentTenantId` = 当前 b2b_admin 的 partner tenant ID
2. `billingModel` 和 `entitlementTier` 继承 parent partner
3. **仅 direct farm** 调用 `subscriptionStore.createTrial()`（partner 下 farm 的 `getEffectiveTier()` 通过 parent lookup 绕过 subscription 检查，无需 trial）
4. 若指定 `ownerName`，自动创建 owner 用户并关联

### 3.4 合同信息

**ContractStore 实现**（`backend/data/contractStore.js`）：

```
字段: {
  id,
  partnerTenantId,
  status: 'active' | 'suspended' | 'expired',
  effectiveTier: 'standard' | 'premium' | 'enterprise',
  revenueShareRatio: float,  // 如 0.15 = 15%
  startedAt,
  expiresAt,
  signedBy
}
```

辅助方法：`getByPartnerTenantId(partnerTenantId)`。

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/contract/current` | GET | 查看自己合同 | b2b_admin |
| `/api/v1/contract/usage-summary` | GET | 旗下 farm 用量聚合（与 dashboard 数据源相同，但按月分组） | b2b_admin |

**`GET /api/v1/contract/current` 响应**：

```json
{
  "code": 200,
  "data": {
    "id": "contract_001",
    "partnerTenantId": "tenant_p001",
    "status": "active",
    "effectiveTier": "standard",
    "revenueShareRatio": 0.15,
    "startedAt": "2026-01-01T00:00:00+08:00",
    "expiresAt": "2027-01-01T00:00:00+08:00",
    "signedBy": "王五"
  }
}
```
无合同时返回 `{ "code": 200, "data": null }`（不返回 404）。

**`GET /api/v1/contract/usage-summary` 响应**：

```json
{
  "code": 200,
  "data": {
    "totalFarms": 3,
    "totalLivestock": 245,
    "totalDevices": 180,
    "monthlyBreakdown": [
      { "month": "2026-03", "livestockCount": 200, "deviceCount": 150 },
      { "month": "2026-04", "livestockCount": 245, "deviceCount": 180 }
    ]
  }
}
```
与 `/api/v1/b2b/dashboard` 的区别：dashboard 是实时快照，usage-summary 包含历史月度趋势。

Phase 2a 中合同为只读展示（合同创建/编辑由 platform_admin 在后台操作，Phase 2b）。

### 3.5 seed 数据扩展

新增 partner 旗下的示例 farm + 新用户：

```javascript
// 新增用户（partner 旗下的牧场主）
{
  userId: 'u_006',
  tenantId: 'tenant_f_p001_001',
  name: '马七',
  role: 'owner',
  mobile: '13800000005',
  permissions: [/* 同现有 owner */],
}

// partner 旗下的示例 farm
{
  id: 'tenant_f_p001_001',
  name: '星辰合作牧场A',
  type: 'farm',
  parentTenantId: 'tenant_p001',
  billingModel: 'revenue_share',
  entitlementTier: null,  // 继承 parent 的 'standard'
  ownerId: 'u_006',
  status: 'active',
  // 其余字段同现有 farm
}

// partner 合同
{
  id: 'contract_001',
  partnerTenantId: 'tenant_p001',
  status: 'active',
  effectiveTier: 'standard',
  revenueShareRatio: 0.15,
  startedAt: '2026-01-01T00:00:00+08:00',
  expiresAt: '2027-01-01T00:00:00+08:00',
  signedBy: '王五',
}
```

### 3.6 b2b_admin 角色权限扩展

`seed.js` 中 b2b_admin 的 permissions 扩展：

```javascript
b2b_admin: {
  // 现有
  'tenant:view', 'tenant:create', 'farm:view_summary',
  // 新增
  'contract:view', 'farm:create', 'b2b:dashboard',
}
```

**前端 `RolePermission` 对应扩展**：

```dart
static bool canViewContract(DemoRole role) => role == DemoRole.b2bAdmin;
static bool canCreateFarm(DemoRole role) =>
    role == DemoRole.b2bAdmin || role == DemoRole.platformAdmin;
static bool canViewB2bDashboard(DemoRole role) => role == DemoRole.b2bAdmin;
```

### 3.7 不在 Phase 2a 范围

- 分润计算引擎 + 对账看板 → Phase 2b
- 合同创建/编辑/续签（platform_admin 后台操作） → Phase 2b
- License 激活 + 心跳监控 → Phase 2b
- b2b_admin 管理旗下 farm 的 worker → Phase 2b
- API 开放平台 → Phase 2c

---

## 横切关注点

### 文件结构预估

**后端新建**：

| 文件 | Epic | 职责 |
|------|------|------|
| `backend/data/workerFarmStore.js` | E2 | worker-farm 分配内存 Store |
| `backend/data/contractStore.js` | E3 | 合同内存 Store |
| `backend/routes/b2bDashboard.js` | E3 | 替换现有 `b2bAdmin.js`，B端控制台路由（用量看板 + farm 管理 + 合同） |
| `backend/test/workerFarmStore.test.js` | E2 | workerFarmStore 单元测试 |
| `backend/test/contractStore.test.js` | E3 | contractStore 单元测试 |
| `backend/test/b2b-dashboard.test.js` | E3 | B端控制台 API 集成测试 |

**前端新建**：

| 文件 | Epic | 职责 |
|------|------|------|
| `lib/features/farm_switcher/` | E2 | FarmSwitcher 组件 + Controller |
| `lib/features/worker_management/` | E2 | 牧工管理页面（domain/data/presentation 三层） |
| `lib/features/b2b_admin/` | E3 | B端管理后台（dashboard/farm_list/contract 三页面 + 导航组件） |
| `test/features/farm_switcher/` | E2 | FarmSwitcher widget 测试 |
| `test/features/b2b_admin/` | E3 | B端页面 widget 测试 |

### 测试策略

| Epic | 后端测试 | 前端测试 |
|------|---------|---------|
| E1 | 全量 `backend/test/*.js` 回归验证 | 全量 `flutter test` 回归验证 |
| E2 | workerFarmStore 单元 + farm 切换集成 | FarmSwitcher widget + 牧工管理页面测试 |
| E3 | contractStore 单元 + b2b API 集成 | B端三页面 widget 测试 |

### 与 Phase 1 规格的关系

- 本 spec 是 Phase 1 spec (`2026-04-28-unified-business-model-design.md` v1.3) 的延续
- Phase 1 spec 中标注"Phase 2 实现"的内容以本 spec 为准
- Phase 1 推迟的 `applyMockShaping` 接通在本 spec E1 中覆盖
- Phase 1 已定义的概念（`getEffectiveTier`、Shaping 中间件、Feature Flag、tenant 数据模型等）不重复定义

---

**文档结束**
