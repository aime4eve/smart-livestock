# 统一商业模型 Phase 2a 设计规格

> **文档编号**: SL-BIZ-2026-002
> **版本**: v1.0
> **编制日期**: 2026-04-29
> **状态**: 初始版本
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
| `backend/routes/b2bAdmin.js` | 角色检查字符串更新 |
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

各 Mock Repository 在返回数据前调用 `applyMockShaping()`，替代当前直接返回 ViewData 的方式。

### 1.3 ownerId 唯一约束移除

移除 Phase 1 中 `tenantStore.createTenant()` 对 `ownerId` 的唯一性校验。seed 数据不变（owner 仍只关联 tenant_001），为 E2 多 farm 铺路。

---

## E2: 多 farm 支持

### 2.1 owner 多 farm 切换

**后端**：

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/my-farms` | GET | 返回当前 owner 关联的所有 farm 列表 | owner |
| `/api/v1/switch-farm` | POST | 切换活跃 farm，body: `{ farmTenantId }` | owner |

`farmContextMiddleware` 扩展：
- 不再取 owner 的第一个 farm
- 优先从 `req.headers['x-active-farm']` 读取活跃 farm ID
- 若 header 缺失，回退到第一个 farm（Phase 1 兼容行为）

**前端**：

| 组件 | 说明 |
|------|------|
| `FarmSwitcher` | 全局下拉组件，嵌入 DemoShell AppBar（仅 owner/worker 可见）。显示当前 farm 名称，下拉展示所有关联 farm，点击切换 |
| `FarmSwitcherController` | Riverpod Notifier，管理 activeFarmTenantId 状态。切换 farm 后通知所有依赖 farm context 的 Controller 刷新数据 |

`AppSession` 扩展：新增 `activeFarmTenantId` 字段。登录时默认取第一个 farm。

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

**seed 数据**：worker（李四）分配到 tenant_001 + tenant_007。

---

## E3: B端管理后台

### 3.1 b2b_admin 导航结构

替换 Phase 1 占位页面，交付三个核心模块。b2b_admin 使用专用 Shell（无底部 Tab，侧边栏导航）：

```
B端控制台
├── 概览（用量看板）
├── 牧场管理（旗下 farm 列表 + 创建子 farm）
└── 合同信息（只读）
```

### 3.2 用量看板

聚合展示旗下所有 farm 的关键指标：

| 指标 | 数据来源 |
|------|---------|
| 总牲畜数 | 各 farm 的 cattleStore 按 parentTenantId 聚合 |
| 总设备数 | 各 farm 的 devicesStore 聚合 |
| 待处理告警数 | alertsStore 按 farmTenantId 聚合 |
| farm 数量 | tenantStore.findByParentTenantId() |

端点：`GET /api/v1/b2b/dashboard`

### 3.3 旗下 farm 管理

| 端点 | 方法 | 说明 | 权限 |
|------|------|------|------|
| `/api/v1/b2b/farms` | GET | 旗下 farm 列表（分页、搜索） | b2b_admin |
| `/api/v1/b2b/farms` | POST | 创建子 farm | b2b_admin |

创建子 farm 逻辑：
1. `type='farm'`，`parentTenantId` = 当前 b2b_admin 的 partner tenant ID
2. `billingModel` 和 `entitlementTier` 继承 parent partner
3. 自动为该 farm 调用 `subscriptionStore.createTrial()`（试用高级版 14 天）
4. 若指定 `ownerId`，创建 owner-farm 关联

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
| `/api/v1/contract/usage-summary` | GET | 旗下 farm 用量聚合 | b2b_admin |

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
| `backend/routes/b2bDashboard.js` | E3 | B端控制台路由（用量看板 + farm 管理 + 合同） |
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
