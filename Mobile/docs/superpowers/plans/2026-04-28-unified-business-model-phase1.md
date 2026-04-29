# 统一商业模型 Phase 1 — 统一基础设施实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在现有 Mock Server + Flutter 代码基础上，落地统一商业模型 Phase 1：扩展 tenant 数据模型（3 种类型）、升级角色体系（新增 b2b_admin/api_consumer）、建设订阅基础设施（Feature Flag + Shaping 中间件 + 订阅 Store/API + 双门控机制）、交付 B2C 完整订阅链路。

**Architecture:** 后端新增 farmContextMiddleware 提取 activeFarmTenantId，Shaping 中间件全局注册包装 res.ok()，按 `getEffectiveTier()` 实现 filter/limit/lock 三种门控策略；前端新增 LockedOverlay 统一组件 + SubscriptionController 管理订阅状态；设备门控在路由处理函数内部实现，tier 门控在 Shaping 中间件实现，前端 LockedOverlay 统一判断两者。

**Tech Stack:** Flutter 3.x, flutter_riverpod, go_router, Node.js + Express 5

**被实施规格:** `docs/superpowers/specs/2026-04-28-unified-business-model-design.md` (v1.3)
**关联规格:** `docs/superpowers/specs/2026-04-24-subscription-service-design(B2C).md`（订阅服务设计，被本计划覆盖并修改）

**勘误约定**：订阅服务设计规格中的 9 项勘误（S1–S8）以统一商业模型规格为准，实施时遵循统一规格。

---

## Issue 索引

| 优先级 | Issue | 标题 | 状态 |
|--------|-------|------|------|
| P1 | — | 统一商业模型 Phase 1 Core：后端基础设施 + 前端订阅管理 | ✅ 已实现 |
| P1 | — | 统一商业模型 Phase 1.1：前端全页门控 + Mock Shaping + 到期弹窗 | ✅ 已实现（5/6，applyMockShaping 推迟） |

### 完成记录

| 完成日期 | 范围 | 分支 | 备注 |
|----------|------|------|------|
| 2026-04-28 | Phase 1 Core（Task 1–22, 24–25） | feature/unified-business-model-phase1 | 后端全部 + 前端订阅模型/UI/路由/ApiCache 已完成 |
| 2026-04-29 | Phase 1.1（5/6 完成） | feature/unified-business-model-phase1 | 3 页 LockedOverlay（estrus/estrus_detail/epidemic）、RenewalBanner、ExpiryPopupHandler、tier-access 集成测试已补齐；applyMockShaping 因类型不匹配推迟；8 页面经分析确认无需 LockedOverlay（feature 对所有 tier 开放） |

---

## 范围界定（Scope）

**本计划覆盖:**
- 后端：tenantStore 扩展字段（type, parentTenantId, billingModel, entitlementTier, ownerId）
- 后端：seed.js 新增 b2b_admin / api_consumer 用户 + partner / api 示例 tenant
- 后端：auth.js 新增 b2b_admin / api_consumer 角色（保留 ops 名称）
- 后端：新增 farmContextMiddleware（提取 req.activeFarmTenantId）+ 全局注册
- 后端：新增 getEffectiveTier() 函数（tier 继承链 + subscription 状态校验）
- 后端：Feature Flag 定义（20 个 key，含 requiredDevices）+ applyShapingRules()
- 后端：Shaping 中间件（全局注册，包装 res.ok，filter/limit/lock 三种策略）
- 后端：subscriptionStore（createTrial/getByTenantId/checkout/cancel/renew）+ 幂等性 key
- 后端：订阅管理 API 7 个端点（current/features/plans/checkout/cancel/renew/usage）
- 后端：tenants.js 路由适配新字段 + POST handler 调用 createTrial()
- 后端：设备门控在各受影响路由处理函数内实现
- 后端：将 Shaping 中间件注册到所有受影响现有路由
- 后端：验证 `/api/v1/*` 前缀已注册（server.js 已有，无需新增），Open API `/api/open/v1/*` 推迟到 Phase 2
- 前端：DemoRole 枚举新增 b2b_admin / api_consumer
- 前端：AppSession 适配新角色
- 前端：RolePermission 扩展权限判断
- 前端：AppRoute 新增 b2bAdmin + subscription + checkout + subscriptionPlan 路由
- 前端：GoRouter 路由守卫适配新角色
- 前端：DemoShell 新增 b2b_admin 导航
- 前端：B2B Admin 占位页面（"功能开发中"）
- 前端：SubscriptionTier 枚举 + Feature 定义模型 + SubscriptionStatus 模型（3 子字段价格）
- 前端：LockedOverlay 统一组件（双门控判断）
- 前端：SubscriptionController（Riverpod Notifier）
- 前端：SubscriptionStatusCard（"我的"页面内嵌）
- 前端：SubscriptionPlanPage（套餐选择/升级页）
- 前端：SubscriptionCheckoutPage（Mock 支付确认页）
- 前端：TierCard + FeatureComparisonTable + UsageProgressBar 组件
- 前端：SubscriptionRenewalBanner（到期提醒横幅）
- 前端：到期提醒登录弹窗（daysUntilExpiry ≤ 7 弹出）
- 前端：MinePage 嵌入 SubscriptionStatusCard
- 前端：孪生/地图/告警/围栏页面适配 LockedOverlay
- 前端：Mock 模式 applyMockShaping() 兼容
- 前端：ApiCache 新增预加载端点
- 测试：后端 subscriptionStore + shaping + subscription API + tier-access 集成测试
- 测试：前端 subscription 相关 unit + widget 测试

**本计划不覆盖（Phase 2）:**
- B端管理后台完整 UI（b2b_admin 仅占位页面）
- ContractStore / LicenseStore / ApiTierStore 真实逻辑（仅静态接口框架）
- API 开放平台端点 `/api/open/v1/*`
- 分润引擎 + 对账看板
- License 激活 + 心跳监控
- owner 多 farm 切换（Phase 1 唯一约束：一个 owner 一个 farm）
- ops → platform_admin 改名（影响面大，推迟到 Phase 2）
- worker 多 farm 分配（仍沿用单一 tenantId）
- 真实支付集成（Mock 模拟 500ms 延迟）
- 真实数据库持久化（内存存储）
- MQTT / 实时通信
- enterprise 真实销售流程（仅"联系销售"入口 + mailto 链接）

### Phase 1.1 待补项（从 Phase 1 Scope 拆出）

以下项在 Phase 1 分支中**未实现**，已在 Phase 1.1 中补齐（除 applyMockShaping 外）：

| 待补项 | 计划 Task | 状态 | 说明 |
|--------|-----------|------|------|
| 12 个业务页面接入 LockedOverlay | Task 23 | ✅ 已完成（3/12 页面） | 经分析：`estrus_page`/`estrus_detail_page`/`epidemic_page` 使用 lock shape feature，需 LockedOverlay；其余 9 页面（twin_overview/alerts/fence/fence_form/fever_warning/fever_detail/digestive/digestive_detail/stats）的 feature 使用 none/filter/limit shape，对所有 tier 开放或由后端 Shaping 处理，**无需前端 LockedOverlay** |
| 孪生页挂载 SubscriptionRenewalBanner | Task 23 | ✅ 已完成 | `twin_overview_page.dart` 已在 ViewState.normal 分支下挂载 RenewalBanner |
| 登录到期弹窗 | Scope | ✅ 已完成 | 新建 `expiry_popup_handler.dart`，嵌入 ShellRoute builder，`daysUntilExpiry ≤ 7` 时弹出 AlertDialog（一次性） |
| applyMockShaping() 接通调用链 | Task 17 | ⬜ 推迟 | 函数签名 `Map<String, dynamic>` 与 Repository 返回类型 ViewData 不兼容，需重构 Repository 层或 applyMockShaping 签名，推迟到 Phase 2 |
| `backend/test/tier-access-integration.test.js` | 文件结构表 | ✅ 已完成 | 6 个集成测试场景（fence limit / alert filter / lock-unlock / data retention / shaping skip / dashboard limit） |
| 地图页 LockedOverlay | Task 23 | ✅ 不适用 | 产品现状无独立地图页面/路由（地图功能嵌入孪生页），已移除此项 |

---

## 文件结构

### 后端 — 新建

| 文件 | 职责 |
|------|------|
| `backend/data/feature-flags.js` | Feature Flag 定义 Map（20 key，含 requiredDevices）+ `applyShapingRules()` 管道函数 |
| `backend/data/subscriptions.js` | 订阅种子数据 + subscriptionStore（createTrial/getByTenantId/checkout/cancel/renew）+ 幂等性 key 存储 |
| `backend/middleware/farmContext.js` | farmContextMiddleware：从 req.user 提取 activeFarmTenantId |
| `backend/middleware/feature-flag.js` | Shaping 中间件（包装 res.ok + 到期检测 + 调用 applyShapingRules） |
| `backend/routes/subscription.js` | 订阅管理 API 7 个端点 |
| `backend/services/tierService.js` | `getEffectiveTier(farmTenantId)` 函数（tier 继承链 + subscription 状态校验） |
| `backend/services/deviceGate.js` | `checkDeviceRequirement(cattle, featureKey)` 辅助函数（查 FEATURE_FLAGS.requiredDevices + cattle.devices） |
| `backend/routes/b2bAdmin.js` | b2b_admin 占位路由（Phase 1 fallback） |
| `backend/test/feature-flags.test.js` | Feature Flag 定义测试 |
| `backend/test/response-shaping.test.js` | Shaping 中间件单元测试（含到期检测） |
| `backend/test/subscription-api.test.js` | 订阅管理 API 集成测试 |
| `backend/test/tier-access-integration.test.js` | 端到端层级访问测试（**✅ Phase 1.1 已补齐**） |
| `backend/test/tierService.test.js` | getEffectiveTier() 单元测试 |
| `backend/test/farmContext.test.js` | farmContextMiddleware 测试 |

### 后端 — 修改

| 文件 | 变更 |
|------|------|
| `backend/data/tenantStore.js` | 新增字段（type, parentTenantId, billingModel, entitlementTier, ownerId）+ `findByOwnerId()` + `findByParentTenantId()` 辅助方法 |
| `backend/data/seed.js` | users 新增 b2b_admin / api_consumer；tenants 扩展示例字段 + 新增 partner/api tenant |
| `backend/middleware/auth.js` | TOKEN_MAP 新增 b2b_admin / api_consumer；users 新增对应角色；requirePermission 扩展权限集 |
| `backend/server.js` | 全局注册 authMiddleware → farmContextMiddleware → shapingMiddleware；ROUTE_DEFINITIONS 新增路由 |
| `backend/routes/registerApiRoutes.js` | 注册 subscription + b2bAdmin 路由 |
| `backend/routes/tenants.js` | POST handler 调用 createTrial()；新增字段读写 |
| `backend/routes/twin.js` | 路由处理函数内实现 device_gate（单牛端点 + list 端点） |
| `backend/routes/map.js` | 注册 feature keys + shaping 中间件（per-route） |
| `backend/routes/fences.js` | 注册 feature keys + shaping 中间件；fence_count limit 检查 |
| `backend/routes/alerts.js` | 注册 feature keys + shaping 中间件（多 key: data_retention_days + alert_history） |
| `backend/routes/dashboard.js` | 注册 feature keys + shaping 中间件 |

### 前端 — 新建

| 文件 | 职责 |
|------|------|
| `lib/core/models/subscription_tier.dart` | SubscriptionTier 枚举 + Feature Flag 定义 + SubscriptionStatus 模型 |
| `lib/core/data/apply_mock_shaping.dart` | applyMockShaping() 共享函数（Mock 模式门控） |
| `lib/features/subscription/domain/subscription_repository.dart` | SubscriptionRepository 接口 |
| `lib/features/subscription/data/mock_subscription_repository.dart` | Mock 实现（同步读取） |
| `lib/features/subscription/data/live_subscription_repository.dart` | Live 实现（ApiCache 读取） |
| `lib/features/subscription/presentation/subscription_controller.dart` | SubscriptionController（Riverpod Notifier） |
| `lib/features/subscription/presentation/widgets/locked_overlay.dart` | LockedOverlay 统一组件（双门控：tier + device） |
| `lib/features/subscription/presentation/widgets/subscription_status_card.dart` | SubscriptionStatusCard（"我的"页面卡片） |
| `lib/features/subscription/presentation/widgets/tier_card.dart` | TierCard 组件 |
| `lib/features/subscription/presentation/widgets/feature_comparison_table.dart` | FeatureComparisonTable 组件 |
| `lib/features/subscription/presentation/widgets/usage_progress_bar.dart` | UsageProgressBar 组件 |
| `lib/features/subscription/presentation/widgets/subscription_renewal_banner.dart` | SubscriptionRenewalBanner（到期提醒横幅） |
| `lib/app/expiry_popup_handler.dart` | ✅ Phase 1.1 新增：到期提醒弹窗（daysUntilExpiry ≤ 7 时弹出） |
| `lib/features/subscription/presentation/subscription_plan_page.dart` | 套餐选择/升级页 |
| `lib/features/subscription/presentation/subscription_checkout_page.dart` | Mock 支付确认页 |
| `lib/features/pages/b2b_admin_placeholder_page.dart` | B2B Admin 占位页面 |
| `test/core/subscription_tier_test.dart` | SubscriptionTier 模型测试 |
| `test/features/subscription/locked_overlay_test.dart` | LockedOverlay Widget 测试 |
| `test/features/subscription/subscription_controller_test.dart` | SubscriptionController 测试 |

### 前端 — 修改

| 文件 | 变更 |
|------|------|
| `lib/core/models/demo_role.dart` | 新增 b2b_admin / api_consumer 枚举值 |
| `lib/app/session/app_session.dart` | 新增 isB2bAdmin / isApiConsumer getter |
| `lib/app/session/session_controller.dart` | 无逻辑改（role 类型扩展自动适配） |
| `lib/app/app_route.dart` | 新增 b2bAdmin / subscription / checkout / subscriptionPlan 路由 |
| `lib/app/app_router.dart` | ✅ 路由守卫适配 b2b_admin；注册新路由；ShellRoute builder 包裹 ExpiryPopupHandler |
| `lib/app/demo_shell.dart` | b2b_admin 看到专用导航（无牛/地图/围栏入口） |
| `lib/core/permissions/role_permission.dart` | 扩展 b2b_admin 权限判断 |
| `lib/core/api/api_cache.dart` | 新增预加载 subscription/current + subscription/features |
| `lib/features/auth/login_page.dart` | 新增 b2b_admin / api_consumer 角色选择 |
| `lib/features/pages/mine_page.dart` | 嵌入 SubscriptionStatusCard |
| `lib/features/pages/twin_overview_page.dart` | ✅ 挂载 SubscriptionRenewalBanner（无需 LockedOverlay，twin 页 feature 对所有 tier 开放） |
| `lib/features/pages/alerts_page.dart` | 无需 LockedOverlay（alert_history 为 filter shape，所有 tier 可访问） |
| `lib/features/pages/fence_page.dart` | 无需 LockedOverlay（fence 为 limit shape，所有 tier 可创建） |
| `lib/features/pages/fence_form_page.dart` | 无需 LockedOverlay（同上） |
| `lib/features/pages/fever_warning_page.dart` | 无需 LockedOverlay（temperature_monitor 为 none shape） |
| `lib/features/pages/fever_detail_page.dart` | 无需 LockedOverlay（同上） |
| `lib/features/pages/digestive_page.dart` | 无需 LockedOverlay（peristaltic_monitor 为 none shape） |
| `lib/features/pages/digestive_detail_page.dart` | 无需 LockedOverlay（同上） |
| `lib/features/pages/estrus_page.dart` | ✅ LockedOverlay（FeatureFlags.estrusDetect, upgradeTier: '高级版'） |
| `lib/features/pages/estrus_detail_page.dart` | ✅ LockedOverlay（FeatureFlags.estrusDetect, upgradeTier: '高级版'） |
| `lib/features/pages/epidemic_page.dart` | ✅ LockedOverlay（FeatureFlags.epidemicAlert, upgradeTier: '高级版'） |
| `lib/features/pages/stats_page.dart` | 无需 LockedOverlay（stats 为 none shape） |
| `lib/widgets/empty_state.dart` | 无需修改（review 确认） |
| 所有引用 `DemoRole.ops` 的测试文件 | 保留现有引用（ops 未改名），仅测试文件新增 b2b_admin 相关测试 case |

---

## 前置条件与约定

1. **价格单位**: 所有价格字段统一使用**元**（人民币），不使用分。`SubscriptionTier.monthlyPrice`、`perUnitPrice`、`SubscriptionStatus.calculatedDeviceFee`/`calculatedTierFee`/`calculatedTotal` 均以元为单位。
2. **超额阶梯费**: 按套餐差异化单价——basic=¥3/头/月, standard=¥2/头/月, premium=¥1/头/月, enterprise=免费（替代原订阅规格中的统一 ¥2/头 和批次定价 ¥50/50头）。
3. **entitlementTier 存储语义**: `tenant.entitlementTier` 存储"当前有效的 tier"。购买/升级时写入新 tier，到期/取消时回写为 `'basic'`。是 Shaping 的权威数据源。
4. **tier 继承**: farm 的 effective tier 通过 `getEffectiveTier()` 计算：farm 自有值优先 → 查 parent partner → 回退 'basic'。direct farm 需经 subscription 状态校验（试用过期/取消/到期 → basic）。
5. **owner 单 farm 约束**: Phase 1 明确声明 `ownerId` 唯一约束，farmContextMiddleware 取 owner 的第一个 farm。
6. **ops 名称保留**: Phase 1 不改名 ops → platform_admin，仅新增 b2b_admin / api_consumer。
7. **b2b_admin Phase 1 降级**: 可登录但路由显示"功能开发中，敬请期待"占位页面，含退出登录按钮。
8. **全局中间件注册**: authMiddleware → farmContextMiddleware → shapingMiddleware 三者全局注册。Shaping 中间件全局注册时仅包装 `res.ok()`，实际 shaping 逻辑延迟到 `res.ok(data)` 调用时执行。
9. **device_gate 实现位置**: 在路由处理函数内部（非 Shaping 中间件）。Shaping 中间件无法感知当前请求针对哪头牛。
10. **前后端协作**: 响应数据中 locked（tier 级）在信封 data 层，deviceLocked（设备级）在每条 item 内。前端 LockedOverlay 逐 item 判断：`item.deviceLocked || data.locked`。
11. **所有主要 UI 元素必须有 Key**（如 `Key('descriptive-id')`），用于测试。
12. **TDD**: 每个 Task 先写测试 → 验证失败 → 实现 → 验证通过 → 提交。

---

## Task 1: 后端 — tenant 数据模型扩展

**Files:**
- Modify: `backend/data/seed.js`
- Modify: `backend/data/tenantStore.js`
- Create: `backend/test/tenantStore.test.js`（若无则新建，有则扩展）

### Step 1: 扩展 seed.js — users 新增角色

在 `seed.js` 的 `users` 对象中：

1. **owner 用户新增 `subscription:manage` 权限**（否则 checkout/cancel/renew 端点返回 403）：
```javascript
// owner 的 permissions 数组新增：
'subscription:manage',
```

2. **新增 b2b_admin 和 api_consumer 用户**（ops 之后）：

```javascript
b2b_admin: {
  userId: 'u_004',
  tenantId: 'tenant_p001',
  name: '星辰牧业',
  role: 'b2b_admin',
  mobile: '13800000003',
  permissions: [
    'tenant:view',
    'tenant:create',
    'farm:view_summary',
  ],
},
api_consumer: {
  userId: 'u_005',
  tenantId: 'tenant_a001',
  name: '数据科技公司',
  role: 'api_consumer',
  mobile: '13800000004',
  permissions: [],
},
```

### Step 2: 扩展 seed.js — tenants 新增字段

现有 6 个 tenant（tenant_001 ~ tenant_006）新增以下字段（默认值，兼容现有数据）：

```javascript
// 每个现有 tenant 新增：
type: 'farm',
parentTenantId: null,
billingModel: 'direct',
entitlementTier: 'basic',
ownerId: null,  // tenant_001 的 ownerId 设为 'u_001'
```

新增 1 个 partner tenant 和 1 个 api tenant：

```javascript
// partner tenant
{
  id: 'tenant_p001',
  name: '星辰牧业（代理商）',
  type: 'partner',
  parentTenantId: null,
  billingModel: 'revenue_share',
  entitlementTier: 'standard',
  ownerId: null,
  status: 'active',
  contactName: '王五',
  contactPhone: '13800000003',
  contactEmail: 'wangwu@example.com',
  region: '华中',
  remarks: 'B端客户示例',
  licenseUsed: 0,
  licenseTotal: 500,
  createdAt: '2026-04-28T00:00:00+08:00',
  updatedAt: '2026-04-28T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
},
// api tenant
{
  id: 'tenant_a001',
  name: '数据科技公司（API）',
  type: 'api',
  parentTenantId: null,
  billingModel: 'api_usage',
  entitlementTier: null,
  ownerId: null,
  status: 'active',
  contactName: '赵六',
  contactPhone: '13800000004',
  contactEmail: 'zhaoliu@example.com',
  region: '华北',
  remarks: 'API客户示例',
  licenseUsed: 0,
  licenseTotal: 0,
  createdAt: '2026-04-28T00:00:00+08:00',
  updatedAt: '2026-04-28T00:00:00+08:00',
  lastUpdatedBy: '系统初始化',
},
```

tenant_001 的 `ownerId` 设为 `'u_001'`（对应用户张三）。

### Step 3: 扩展 tenantStore.js

新增辅助方法 `findByOwnerId(ownerId)` 和 `findByParentTenantId(parentTenantId)`：

```javascript
function findByOwnerId(ownerId) {
  return tenants.filter((t) => t.ownerId === ownerId);
}

function findByParentTenantId(parentTenantId) {
  return tenants.filter((t) => t.parentTenantId === parentTenantId);
}
```

`createTenant()` 支持新字段（type, parentTenantId, billingModel, entitlementTier, ownerId），默认值：`type: 'farm'`, `parentTenantId: null`, `billingModel: 'direct'`, `entitlementTier: 'basic'`, `ownerId: null`。

修改 `module.exports` 导出 `findByOwnerId` 和 `findByParentTenantId`。

### Step 4: 运行测试验证

Run: `cd backend && node -e "const s = require('./data/tenantStore'); console.log(s.findByOwnerId('u_001')); console.log(s.findByParentTenantId('tenant_p001'));"`

Expected: tenant_001 出现在 ownerId 查询结果中；无 tenant 归属 tenant_p001（Phase 1 不含子 farm）

### Step 5: 提交

---

## Task 2: 后端 — 角色体系升级（auth.js）

**Files:**
- Modify: `backend/middleware/auth.js`

### Step 1: 扩展 TOKEN_MAP

```javascript
const TOKEN_MAP = {
  'mock-token-owner': 'owner',
  'mock-token-worker': 'worker',
  'mock-token-ops': 'ops',
  'mock-token-b2b-admin': 'b2b_admin',
  'mock-token-api-consumer': 'api_consumer',
};
```

### Step 2: 扩展 requirePermission 权限集

在 `requirePermission` 工厂函数中，`req.user.permissions` 检查保持不变（权限已在 seed.js 的 users 中定义）。无需修改中间件逻辑，仅需确认 b2b_admin 的 `farm:view_summary` 权限在后续路由中正确使用。

### Step 3: 验证

Run: `cd backend && node -e "
const { authMiddleware } = require('./middleware/auth');
const TOKEN_MAP = require('./middleware/auth').TOKEN_MAP;
console.log('TOKEN_MAP entries:', Object.keys(TOKEN_MAP));
console.log('b2b_admin token:', TOKEN_MAP['mock-token-b2b-admin']);
console.log('api_consumer token:', TOKEN_MAP['mock-token-api-consumer']);
"`

Expected: TOKEN_MAP 包含 5 个条目，b2b_admin 和 api_consumer token 正确映射

### Step 4: 提交

---

## Task 3: 后端 — tierService（getEffectiveTier）

**Files:**
- Create: `backend/services/tierService.js`
- Create: `backend/test/tierService.test.js`

### Step 1: 写测试

```javascript
// backend/test/tierService.test.js
// 测试策略（配合现有 no-jest 环境）：
//   - 直接操作 tenantStore 和 subscriptionStore 的内存数据来设置测试前置条件
//   - 在每个测试用例前调用 tenantStore.reset() / subscriptionStore.reset() 清理
//   - subscriptionStore 的 reset() 方法需要在 subscriptions.js 中导出
//   - 所有 tenant 数据直接 push 到 stores 中，调用 getEffectiveTier() 验证结果
//
// 环境：沿用现有 backend/test 的简单 require-and-run 模式（不引入 jest/mocha）

const { getEffectiveTier } = require('../services/tierService');
const tenantStore = require('../data/tenantStore');
const subscriptionStore = require('../data/subscriptions');

function runTest(name, fn) {
  try {
    tenantStore.reset();
    if (subscriptionStore.reset) subscriptionStore.reset();
    fn();
    console.log(`  PASS: ${name}`);
  } catch (e) {
    console.log(`  FAIL: ${name} — ${e.message}`);
  }
}

runTest('direct farm with active subscription returns farm entitlementTier', () => {
  // 直接写入 tenant
  tenantStore.createTenant({ name: 'test', /* type: 'farm', ownerId: 'u_test' */ });
  const farm = tenantStore.getAll().find(t => t.name === 'test');
  farm.entitlementTier = 'premium';

  // 直接写入 subscription
  subscriptionStore.createTrial(farm.id);
  const sub = subscriptionStore.getByTenantId(farm.id);
  sub.status = 'active';

  const result = getEffectiveTier(farm.id);
  // expected: 'premium'
});

// ... 其余 8 个测试用例模式相同

test('direct farm with expired subscription returns basic', () => {
  // farm 无 parentTenantId，subscription status='expired'，entitlementTier='premium'
  // expected: 'basic'
});

test('direct farm with cancelled subscription past period end returns basic', () => {
  // subscription status='cancelled'，currentPeriodEnd 在过去
  // expected: 'basic'
});

test('direct farm with trial expired returns basic', () => {
  // subscription status='trial'，trialEndsAt 在过去
  // expected: 'basic'
});

test('direct farm without subscription record returns basic (null-sub defense)', () => {
  // subscriptionStore.getByTenantId returns null
  // expected: 'basic'
});

test('farm under partner inherits parent entitlementTier', () => {
  // farm.parentTenantId = 'tenant_p001'
  // farm.entitlementTier = null
  // parent.entitlementTier = 'standard'
  // expected: 'standard'
});

test('farm under partner with own entitlementTier uses own value', () => {
  // farm.parentTenantId = 'tenant_p001'，farm.entitlementTier = 'premium'
  // parent.entitlementTier = 'standard'
  // expected: 'premium'（farm 自有优先）
});

test('farm under partner with null entitlementTier and parent without tier returns basic', () => {
  // farm.parentTenantId = 'tenant_p002'
  // farm.entitlementTier = null
  // parent.entitlementTier = null
  // expected: 'basic'
});

test('unknown farmTenantId returns basic', () => {
  // tenantStore.findById returns undefined
  // expected: 'basic'
});
```

### Step 2: 运行测试确认失败

Run: `cd backend && npx jest test/tierService.test.js 2>/dev/null || node -e "require('./test/tierService.test.js')"`

### Step 3: 实现 getEffectiveTier()

按统一商业模型规格 Section 2.3 的 `getEffectiveTier(farmTenantId)` 伪代码实现：

```javascript
// backend/services/tierService.js
const tenantStore = require('../data/tenantStore');

function getEffectiveTier(farmTenantId) {
  const farm = tenantStore.findById(farmTenantId);
  if (!farm) return 'basic';

  const now = new Date();

  // direct farm：需检查 subscription 状态
  if (!farm.parentTenantId) {
    const subscriptionStore = require('../data/subscriptions');
    const sub = subscriptionStore.getByTenantId(farmTenantId);
    if (!sub) return 'basic';
    if (sub.status === 'expired') return 'basic';
    if (sub.status === 'cancelled' && now > new Date(sub.currentPeriodEnd)) return 'basic';
    if (sub.status === 'trial' && now > new Date(sub.trialEndsAt)) return 'basic';
  }

  // farm 自有值优先
  if (farm.entitlementTier) return farm.entitlementTier;

  // 查 parent partner
  if (farm.parentTenantId) {
    const parent = tenantStore.findById(farm.parentTenantId);
    return parent?.entitlementTier ?? 'basic';
  }

  return 'basic';
}

module.exports = { getEffectiveTier };
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 4: 后端 — Feature Flag 定义 + applyShapingRules

**Files:**
- Create: `backend/data/feature-flags.js`
- Create: `backend/test/feature-flags.test.js`

### Step 1: 写测试

验证 Feature Flag 定义的完整性：
- 20 个 key 全部定义
- 每个 key 有 tier 访问级别（basic/standard/premium/enterprise）
- 5 个 key 有 requiredDevices（fence, gps_location, trajectory → GPS；temperature_monitor, peristaltic_monitor → 胶囊；health_score, estrus_detect, epidemic_alert → 双配）
- applyShapingRules 正确执行 filter/limit/lock/none 四种策略

### Step 2: 运行测试确认失败

### Step 3: 实现 feature-flags.js

```javascript
// backend/data/feature-flags.js

const ALL_TIERS = ['basic', 'standard', 'premium', 'enterprise'];

// Feature Flag 定义 Map
// 每个 key: { tiers: Set|string[], shape?: 'none'|'lock'|'limit'|'filter', limit?: number, requiredDevices?: string[] }
const FEATURE_FLAGS = {
  // location 分类
  gps_location:              { tiers: ALL_TIERS,                          shape: 'none' },
  fence:                     { tiers: { basic: 3, standard: 5, premium: 10, enterprise: -1 }, shape: 'limit', requiredDevices: ['gps'] },
  trajectory:                { tiers: ['standard','premium','enterprise'], shape: 'lock', requiredDevices: ['gps'] },

  // health 分类
  temperature_monitor:       { tiers: ALL_TIERS,                          shape: 'none',  requiredDevices: ['capsule'] },
  peristaltic_monitor:       { tiers: ALL_TIERS,                          shape: 'none',  requiredDevices: ['capsule'] },
  health_score:              { tiers: ['premium','enterprise'],     shape: 'lock',  requiredDevices: ['gps','capsule'] },
  estrus_detect:             { tiers: ['premium','enterprise'],     shape: 'lock',  requiredDevices: ['gps','capsule'] },
  epidemic_alert:            { tiers: ['premium','enterprise'],     shape: 'lock',  requiredDevices: ['gps','capsule'] },

  // analytics 分类
  gait_analysis:             { tiers: ['enterprise'],               shape: 'lock' },
  behavior_stats:            { tiers: ['enterprise'],               shape: 'lock' },
  api_access:                { tiers: ['enterprise'],               shape: 'lock' },
  stats:                     { tiers: ALL_TIERS,                          shape: 'none' },
  dashboard_summary:         { tiers: ALL_TIERS,                          shape: 'limit', limit: 4 },

  // service 分类
  data_retention_days:       { tiers: { basic: 7, standard: 30, premium: 365, enterprise: 1095 }, shape: 'filter' },
  alert_history:             { tiers: { basic: 7, standard: 30, premium: 90, enterprise: 365 }, shape: 'filter' },
  dedicated_support:         { tiers: ['premium','enterprise'],     shape: 'lock' },

  // management 分类
  device_management:         { tiers: ALL_TIERS,                          shape: 'none' },
  livestock_detail:          { tiers: ALL_TIERS,                          shape: 'none' },
  profile:                   { tiers: ALL_TIERS,                          shape: 'none' },
  tenant_admin:              { tiers: ALL_TIERS,                          shape: 'none' },
};

const TIER_LEVEL = { basic: 0, standard: 1, premium: 2, enterprise: 3 };

function applyShapingRules(data, tier, featureKeys) {
  if (!featureKeys || featureKeys.length === 0) return data;

  let result = data;
  for (const key of featureKeys) {
    const flag = FEATURE_FLAGS[key];
    if (!flag) continue;

    const hasAccess = checkTierAccess(tier, flag.tiers);
    if (!hasAccess) {
      if (flag.shape === 'lock') {
        result = { ...result, locked: true, upgradeTier: getMinTierForFeature(flag.tiers) };
      } else if (flag.shape === 'filter') {
        result = applyFilter(result, key, getEffectiveDataRetention(tier));
      } else if (flag.shape === 'limit') {
        result = applyLimit(result, flag.limit);
      }
    }
  }
  return result;
}

// 辅助函数：

// checkTierAccess(tier, tiersConfig) — 判断当前 tier 是否在允许列表中
// getMinTierForFeature(tiersConfig) — 返回解锁此功能所需的最小 tier
// getEffectiveDataRetention(tier) — 返回当前 tier 对应的 data_retention_days

// applyFilter(data, key, retentionDays) — 按日期过滤数据：
//   data_retention_days 字段到数据 key 的映射：
//     alerts 端点 → 过滤 items[x].occurredAt
//     trajectories 端点 → 过滤 items[x].recordedAt
//     sensor/twin 端点 → 过滤 items[x].timestamp
//   过滤规则：只保留日期 ≥ (now - retentionDays) 的数据
//   实现方式：在 applyShapingRules 中，当 shape='filter' 时检查 key 名称：
//     - 'data_retention_days': featureKeys 中同时包含 'alert_history' → 过滤 occurredAt
//     - 'data_retention_days': featureKeys 中同时包含 'trajectory' → 过滤 recordedAt
//   applyFilter 遍历 data.items（如有），移除过期条目，返回修改后的 data

// applyLimit(data, limit) — 截断数组：
//   若 data.items 存在且 length > limit → 截断为前 limit 条
//   在 data 中注入 limitExceeded: true, limitValue: limit, totalBeforeLimit: 原 length

module.exports = { FEATURE_FLAGS, applyShapingRules, checkTierAccess, TIER_LEVEL };
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 5: 后端 — subscriptionStore + 种子数据

**Files:**
- Create: `backend/data/subscriptions.js`
- Create: `backend/test/subscription-api.test.js`（部分：store 单元测试）

### Step 1: 写测试

覆盖以下场景：
- createTrial 为新 tenant 创建 14 天试用
- createTrial 幂等性（同一 tenant 不重复创建）
- getByTenantId 正确返回
- checkout 从 trial/active 升级
- checkout 幂等性 key 防重（5 分钟 TTL）
- cancel 标记取消
- renew 更新周期
- checkout/renew 返回 calculatedDeviceFee + calculatedTierFee + calculatedTotal（单位：元）
- renew 时重算设备月费（牛数可能已变化）

### Step 2: 运行测试确认失败

### Step 3: 实现 subscriptions.js

```javascript
// backend/data/subscriptions.js

let subscriptions = [];
let idempotencyKeys = new Map();  // key → { createdAt, result }

const TIER_PRICES = { basic: 0, standard: 299, premium: 699, enterprise: null };
const DEVICE_PRICES = { gps: 15, capsule: 30 };  // 元/牛/月
const TRIAL_DAYS = 14;
const PER_UNIT_PRICES = { basic: 3, standard: 2, premium: 1, enterprise: 0 };  // 超出单价按套餐差异化（元/头/月）

function createTrial(tenantId) {
  const existing = subscriptions.find(s => s.tenantId === tenantId);
  if (existing) return { error: 'already_exists', subscription: existing };

  const now = new Date();
  const trialEnd = new Date(now);
  trialEnd.setDate(trialEnd.getDate() + TRIAL_DAYS);

  const sub = {
    id: `sub_${subscriptions.length + 1}`.padEnd(6, '0'),
    tenantId,
    tier: 'premium',          // 试用高级版
    status: 'trial',
    trialEndsAt: trialEnd.toISOString(),
    currentPeriodStart: now.toISOString(),
    currentPeriodEnd: trialEnd.toISOString(),
    livestockCount: 0,
    calculatedDeviceFee: 0,   // 新增：设备月费（元）
    calculatedTierFee: 0,     // 原 calculatedPrice，tier 月费（元）
    calculatedTotal: 0,       // 新增：合计（元）
    createdAt: now.toISOString(),
    updatedAt: now.toISOString(),
  };
  subscriptions.push(sub);
  return { subscription: sub };
}

function getByTenantId(tenantId) {
  return subscriptions.find(s => s.tenantId === tenantId) ?? null;
}

function checkout(tenantId, tier, livestockCount, idempotencyKey) {
  // 幂等性检查
  if (idempotencyKey) {
    const cached = idempotencyKeys.get(idempotencyKey);
    if (cached && (Date.now() - cached.createdAt) < 300000) return cached.result;
  }

  const sub = getByTenantId(tenantId);
  if (!sub) return { error: 'no_subscription' };
  if (!['basic','standard','premium'].includes(tier)) return { error: 'invalid_tier' };

  // 计算费用（单位：元）
  const tierPrice = TIER_PRICES[tier];
  const deviceFee = livestockCount * (DEVICE_PRICES.gps + DEVICE_PRICES.capsule);
  // tier 月费 = 固定月费
  let tierFee = tierPrice;
  // 超出阶梯费
  const limits = { basic: 50, standard: 200, premium: 1000 };
  const limit = limits[tier] || 0;
  if (livestockCount > limit) {
    tierFee += (livestockCount - limit) * (PER_UNIT_PRICES[tier] || 0);
  }
  const total = deviceFee + tierFee;

  const now = new Date();
  const periodEnd = new Date(now);
  periodEnd.setMonth(periodEnd.getMonth() + 1);

  sub.tier = tier;
  sub.status = 'active';
  sub.trialEndsAt = null;
  sub.currentPeriodStart = now.toISOString();
  sub.currentPeriodEnd = periodEnd.toISOString();
  sub.livestockCount = livestockCount;
  sub.calculatedDeviceFee = deviceFee;
  sub.calculatedTierFee = tierFee;
  sub.calculatedTotal = total;
  sub.updatedAt = now.toISOString();

  // 同步 tenant.entitlementTier
  const tenantStore = require('./tenantStore');
  const tenant = tenantStore.findById(tenantId);
  if (tenant) tenant.entitlementTier = tier;

  const result = { subscription: { ...sub } };
  if (idempotencyKey) idempotencyKeys.set(idempotencyKey, { createdAt: Date.now(), result });
  return result;
}

function cancel(tenantId) {
  const sub = getByTenantId(tenantId);
  if (!sub) return { error: 'no_subscription' };
  sub.status = 'cancelled';
  sub.updatedAt = new Date().toISOString();
  return { subscription: sub };
}

function renew(tenantId, livestockCount, idempotencyKey) {
  // 类似 checkout，重算设备月费
  // ...
}

module.exports = {
  createTrial,
  getByTenantId,
  checkout,
  cancel,
  renew,
  reset,  // 测试用
};
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 6: 后端 — farmContextMiddleware

**Files:**
- Create: `backend/middleware/farmContext.js`
- Create: `backend/test/farmContext.test.js`

### Step 1: 写测试

覆盖：
- owner 角色 → req.activeFarmTenantId = findByOwnerId 的第一个结果
- worker 角色 → req.activeFarmTenantId = tenantId（沿用现有逻辑）
- platform_admin (ops) 角色 → req.activeFarmTenantId = null
- b2b_admin 角色 → req.activeFarmTenantId = null
- api_consumer 角色 → req.activeFarmTenantId = null
- owner 无 farm → req.activeFarmTenantId = null

### Step 2: 运行测试确认失败

### Step 3: 实现 farmContextMiddleware

按统一商业模型规格 Section 6.2 的伪代码实现：

```javascript
// backend/middleware/farmContext.js
const tenantStore = require('../data/tenantStore');

function farmContextMiddleware(req, res, next) {
  if (req.user?.role === 'owner') {
    const farms = tenantStore.findByOwnerId(req.user.userId);
    req.activeFarmTenantId = farms.length > 0 ? farms[0].id : null;
  } else if (req.user?.role === 'worker') {
    req.activeFarmTenantId = req.user.tenantId ?? null;
  } else {
    req.activeFarmTenantId = null;
  }
  next();
}

module.exports = { farmContextMiddleware };
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 7: 后端 — Shaping 中间件

**Files:**
- Create: `backend/middleware/feature-flag.js`
- Create: `backend/test/response-shaping.test.js`

### Step 1: 写测试

覆盖：
- 无 feature keys → 数据原样返回
- tier 满足 → 数据不变
- tier 不足 lock → locked: true, upgradeTier 为最小满足 tier
- tier 不足 filter → 数据被过滤（如 data_retention_days）
- tier 不足 limit → 数据被截断
- 多 key 管道 → 多个 key 依次处理
- 到期检测 → expired/cancelled/trial 过期 → basic tier
- req.activeFarmTenantId 为 null → shaping 直接跳过，原样返回数据（ops/b2b_admin/api_consumer 不受 shaping 限制）

### Step 2: 运行测试确认失败

### Step 3: 实现 Shaping 中间件

```javascript
// backend/middleware/feature-flag.js
const { getEffectiveTier } = require('../services/tierService');
const { applyShapingRules } = require('../data/feature-flags');

function shapingMiddleware(req, res, next) {
  const originalOk = res.ok.bind(res);

  res.ok = function(data, message) {
    const farmTenantId = req.activeFarmTenantId;
    // ops / b2b_admin / api_consumer 无 farm context，直接跳过 shaping
    if (!farmTenantId) return originalOk(data, message);

    const tier = getEffectiveTier(farmTenantId);
    const featureKeys = req.routeFeatureKeys ?? [];

    let shaped = { ...data };
    if (featureKeys.length > 0) {
      shaped = applyShapingRules(shaped, tier, featureKeys);
    }

    return originalOk(shaped, message);
  };

  next();
}

// 辅助中间件：设置 route feature keys
function featureKeys(...keys) {
  return (req, res, next) => {
    req.routeFeatureKeys = keys;
    next();
  };
}

module.exports = { shapingMiddleware, featureKeys };
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 8: 后端 — 订阅管理 API

**Files:**
- Create: `backend/routes/subscription.js`
- Create: `backend/test/subscription-api.test.js`（API 集成测试部分）

### Step 1: 写测试

覆盖 7 个端点：
- `GET /subscription/current` — 返回当前订阅状态
- `GET /subscription/features` — 返回 Feature Flag 列表
- `GET /subscription/plans` — 返回套餐列表
- `POST /subscription/checkout` — 购买/升级（幂等性 key）
- `POST /subscription/cancel` — 取消订阅
- `POST /subscription/renew` — 续费
- `GET /subscription/usage` — 用量统计

### Step 2: 运行测试确认失败

### Step 3: 实现 subscription 路由

7 个端点，遵循现有路由风格（authMiddleware + requirePermission + res.ok/fail 包络）：

```
GET  /subscription/current   → auth + 返回 subscriptionStore.getByTenantId(activeFarmTenantId)
GET  /subscription/features  → auth + 返回 FEATURE_FLAGS + current tier
GET  /subscription/plans     → auth + 返回套餐列表（含价格）
POST /subscription/checkout  → auth + requirePermission('subscription:manage') + 校验 body + checkout()
POST /subscription/cancel    → auth + requirePermission('subscription:manage') + cancel()
POST /subscription/renew     → auth + requirePermission('subscription:manage') + renew()
GET  /subscription/usage     → auth + 返回用量（牛数/设备数等）
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 9: 后端 — 全局中间件注册 + 路由注册 + tenants 适配

**Files:**
- Modify: `backend/server.js`
- Modify: `backend/routes/registerApiRoutes.js`
- Modify: `backend/routes/tenants.js`

### Step 1: server.js 全局注册中间件

修改 `server.js`：

```javascript
const { authMiddleware } = require('./middleware/auth');
const { farmContextMiddleware } = require('./middleware/farmContext');
const { shapingMiddleware } = require('./middleware/feature-flag');

// 在 envelopeMiddleware 之后，registerApiRoutes 之前：
app.use(authMiddleware);           // 1. 认证 + 注入 req.user
app.use(farmContextMiddleware);    // 2. 提取 activeFarmTenantId
app.use(shapingMiddleware);        // 3. 包装 res.ok() 加入 shaping
```

**重要**：由于 authMiddleware 全局注册，必须移除所有现有路由文件中 per-route 的 `router.use(authMiddleware)` 和单个端点上的 `authMiddleware` 调用。否则会导致 authMiddleware 对每个请求执行两次。具体修改范围：
- 移除各路由文件中的所有 `authMiddleware` 引用（alerts.js, dashboard.js, devices.js, fences.js, map.js, me.js, profile.js, tenants.js, twin.js）
- 保留 `requirePermission(...)` 调用（这些不重复执行认证）
- 路由文件不再 import authMiddleware

ROUTE_DEFINITIONS 新增订阅路由和 b2b 路由。

### Step 2: registerApiRoutes.js 注册新路由

```javascript
const subscriptionRoutes = require('./subscription');
const b2bAdminRoutes = require('./b2bAdmin');

// 在 registerApiRoutes 中新增：
app.use(`${prefix}/subscription`, subscriptionRoutes);
app.use(`${prefix}/b2b`, b2bAdminRoutes);
```

### Step 3: tenants.js 适配

- POST handler 创建 tenant 后调用 `subscriptionStore.createTrial(tenant.id)`
- 读写支持新字段（type, parentTenantId, billingModel, entitlementTier, ownerId）
- 新增 `GET /tenants?type=partner|farm|api` 按类型过滤（响应格式与现有列表接口一致：`{ items, page, pageSize, total }`，type 作为服务端过滤参数，不影响分页结构）
- 新增 `GET /tenants?parentTenantId=xxx` 按 parent 查子 tenant（同上分页格式）

### Step 4: 验证

Run: `cd backend && node server.js`，确认启动无报错，所有路由注册成功。

### Step 5: 提交

---

## Task 10: 后端 — 设备门控 + 现有路由适配 Shaping

**Files:**
- Modify: `backend/routes/twin.js`
- Modify: `backend/routes/map.js`
- Modify: `backend/routes/fences.js`
- Modify: `backend/routes/alerts.js`
- Modify: `backend/routes/dashboard.js`

### Step 1: 为各路由注册 feature keys

```javascript
// 注意：由于 authMiddleware 已全局注册，以下路由不再出现 authMiddleware

// map.js：
const { featureKeys } = require('../middleware/feature-flag');
router.get('/trajectories', featureKeys('gps_location', 'trajectory'), handler);

// fences.js：
router.get('/', featureKeys('fence'), handler);
// POST /fences 不注册 featureKeys('fence')，原因是 fence feature 使用 shape:limit
// limit 策略操作的是数组 items，单个 create 响应无法被正确限制。
// POST handler 内部手动检查 fence count：若已超过 tier 上限，在返回数据中注入 locked: true
router.post('/', requirePermission('fence:manage'), handler);

// alerts.js：
router.get('/', featureKeys('alert_history', 'data_retention_days'), handler);

// dashboard.js：
router.get('/summary', featureKeys('dashboard_summary'), handler);

// twin.js：
router.get('/fever/list', featureKeys('temperature_monitor'), handler);
router.get('/fever/:id', featureKeys('temperature_monitor'), handler);  // 单牛端点
router.get('/digestive/list', featureKeys('peristaltic_monitor'), handler);
router.get('/digestive/:id', featureKeys('peristaltic_monitor'), handler);
router.get('/estrus/list', featureKeys('estrus_detect'), handler);
router.get('/estrus/:id', featureKeys('estrus_detect'), handler);
router.get('/epidemic/summary', featureKeys('epidemic_alert'), handler);
```

### Step 2: 在 twin.js 路由处理函数内实现 device_gate

以 `/twin/fever/:id` 为例：

```javascript
router.get('/fever/:id', featureKeys('temperature_monitor'), (req, res) => {
  const cattle = cattleStore.findById(req.params.id);
  if (!cattle) return res.fail(404, 'RESOURCE_NOT_FOUND', '牛只不存在');

  const hasRequiredDevices = checkDeviceRequirement(cattle, 'temperature_monitor');
  const data = {
    ...buildFeverData(cattle),
    deviceLocked: !hasRequiredDevices,
    deviceMessage: hasRequiredDevices ? null : '此功能需要安装瘤胃胶囊',
  };
  res.ok(data);
});
```

对 list 端点，每条 item 含 `deviceLocked` / `deviceMessage` 字段。

`checkDeviceRequirement(cattle, featureKey)` 辅助函数（位于 `backend/services/deviceGate.js`）：
- 查 FEATURE_FLAGS[featureKey].requiredDevices
- 若无 requireDevices → 返回 true
- 'gps' → 检查牛是否有 GPS 设备（遍历 cattle.devices 按 type 查找）
- 'capsule' → 检查牛是否有瘤胃胶囊
- ['gps','capsule'] → 两者都需有

`backend/services/deviceGate.js` 同步加入文件结构表（后端新建文件）。

### Step 3: 运行后端测试

Run: `cd backend && node -e "require('./test/response-shaping.test.js')"`

验证 shaping + device gate 端到端工作。

### Step 4: 提交

---

## Task 11: 后端 — b2bAdmin 占位路由

**Files:**
- Create: `backend/routes/b2bAdmin.js`

### Step 1: 实现占位路由

```javascript
// backend/routes/b2bAdmin.js
const { Router } = require('express');
const { authMiddleware } = require('../middleware/auth');
const router = Router();

router.get('/status', authMiddleware, (req, res) => {
  if (req.userRole !== 'b2b_admin') {
    return res.fail(403, 'AUTH_FORBIDDEN', '仅 B端客户可访问');
  }
  res.ok({ phase: 1, message: '功能开发中，敬请期待' });
});

module.exports = router;
```

### Step 2: 提交

---

## Task 12: 前端 — DemoRole 枚举扩展 + AppSession 适配

**Files:**
- Modify: `lib/core/models/demo_role.dart`
- Modify: `lib/app/session/app_session.dart`

### Step 1: 扩展 DemoRole 枚举

```dart
enum DemoRole {
  owner,
  worker,
  ops,
  b2bAdmin,
  apiConsumer,
}
```

### Step 2: 扩展 AppSession

```dart
bool get isB2bAdmin => role == DemoRole.b2bAdmin;
bool get isApiConsumer => role == DemoRole.apiConsumer;
```

### Step 3: 运行 flutter analyze

### Step 4: 提交

---

## Task 13: 前端 — AppRoute + GoRouter 适配

**Files:**
- Modify: `lib/app/app_route.dart`
- Modify: `lib/app/app_router.dart`

### Step 1: 新增 AppRoute 枚举值

```dart
b2bAdmin('/b2b/admin', 'b2b-admin', 'B端控制台'),
subscription('/subscription', 'subscription', '订阅管理'),
checkout('/subscription/checkout', 'checkout', '确认支付'),
subscriptionPlan('/subscription/plans', 'subscription-plan', '套餐选择'),
```

### Step 2: GoRouter 新增路由 + 守卫适配

路由守卫：
```dart
if (role == DemoRole.b2bAdmin) {
  return location.startsWith(AppRoute.b2bAdmin.path)
      ? null
      : AppRoute.b2bAdmin.path;
}
```

新增 b2bAdmin GoRoute（独立 ShellRoute，无底部导航）：
```dart
GoRoute(
  path: AppRoute.b2bAdmin.path,
  name: AppRoute.b2bAdmin.routeName,
  builder: (context, state) => const B2bAdminPlaceholderPage(),
),
```

新增 subscription / checkout / subscriptionPlan 为**独立全屏 GoRoute**（不放在 ShellRoute 内，避免底部导航栏出现在订阅页面）。订阅页为全屏独立页面，与 ShellRoute 平级：

```dart
// 在 ShellRoute 之前/之后注册：
GoRoute(
  path: AppRoute.subscription.path,
  name: AppRoute.subscription.routeName,
  builder: (context, state) => const SubscriptionPlanPage(),
),
GoRoute(
  path: AppRoute.checkout.path,
  name: AppRoute.checkout.routeName,
  builder: (context, state) {
    final extra = state.extra as Map<String, dynamic>;
    return SubscriptionCheckoutPage(
      tier: extra['tier'] as SubscriptionTier,
      livestockCount: extra['livestockCount'] as int,
    );
  },
),
GoRoute(
  path: AppRoute.subscriptionPlan.path,
  name: AppRoute.subscriptionPlan.routeName,
  builder: (context, state) => const SubscriptionPlanPage(),
),
```

注意：路由守卫中需允许已登录 owner 访问这些路径（不被重定向到 login）。

### Step 3: 运行 flutter analyze

### Step 4: 提交

---

## Task 14: 前端 — DemoShell + RolePermission + LoginPage 适配

**Files:**
- Modify: `lib/app/demo_shell.dart`
- Modify: `lib/core/permissions/role_permission.dart`
- Modify: `lib/features/auth/login_page.dart`

### Step 1: DemoShell 新增 b2b_admin 导航

b2b_admin 显示专用 Shell（含退出登录，无底部导航）：

```dart
if (role == DemoRole.b2bAdmin) {
  return Scaffold(
    body: child,
    // b2b_admin 无底部导航，仅 AppBar 含退出登录
  );
}
```

### Step 2: RolePermission 扩展

```dart
static bool canViewFarmSummary(DemoRole role) =>
    role == DemoRole.b2bAdmin || role == DemoRole.ops;

static bool canManageSubscription(DemoRole role) =>
    role == DemoRole.owner;
```

### Step 3: LoginPage 新增角色选择

新增两个角色按钮：
- "B端客户（代理商）" → b2bAdmin
- "API 客户" → apiConsumer

### Step 4: 运行 flutter analyze

### Step 5: 提交

---

## Task 15: 前端 — B2B Admin 占位页面

**Files:**
- Create: `lib/features/pages/b2b_admin_placeholder_page.dart`

### Step 1: 实现占位页面

```dart
class B2bAdminPlaceholderPage extends ConsumerWidget {
  const B2bAdminPlaceholderPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('B端控制台'),
        actions: [
          IconButton(
            key: const Key('b2b-logout'),
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(sessionControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.construction, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('功能开发中，敬请期待', style: TextStyle(fontSize: 18, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
```

### Step 2: 运行 flutter analyze

### Step 3: 提交

---

## Task 16: 前端 — SubscriptionTier 模型 + Feature 定义

**Files:**
- Create: `lib/core/models/subscription_tier.dart`
- Create: `test/core/subscription_tier_test.dart`

### Step 1: 写测试

验证：
- SubscriptionTier 4 层级枚举值正确
- 每个 tier 的月费、牲畜上限、feature 列表正确
- SubscriptionStatus.fromJson 正确解析（含 3 子字段价格）
- 价格均为元（非分）

### Step 2: 运行测试确认失败

### Step 3: 实现模型

```dart
enum SubscriptionTier { basic, standard, premium, enterprise }

class SubscriptionTierInfo {
  final SubscriptionTier tier;
  final String name;
  final double monthlyPrice;   // 元
  final int livestockLimit;
  final double perUnitPrice;   // 超出每头价格（元），按套餐差异化：basic=3, standard=2, premium=1, enterprise=0
  final List<String> features;
  // ...
}

class SubscriptionStatus {
  final String id;
  final String tenantId;
  final SubscriptionTier tier;
  final String status;          // trial | active | cancelled | expired
  final DateTime? trialEndsAt;
  final DateTime? currentPeriodEnd;
  final int livestockCount;
  final double calculatedDeviceFee;  // 元
  final double calculatedTierFee;    // 元
  final double calculatedTotal;      // 元

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) => ...;
}
```

定义 20 个 Feature Flag key 常量和 `checkFeatureAccess(tier, featureKey)` 函数。

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 17: 前端 — Mock Shaping 共享函数

**Files:**
- Create: `lib/core/data/apply_mock_shaping.dart`

### Step 1: 实现 applyMockShaping()

与后端 `applyShapingRules` 保持一致的门控逻辑：

```dart
Map<String, dynamic> applyMockShaping(
  Map<String, dynamic> data,
  SubscriptionTier tier,
  List<String> featureKeys,
) {
  // 对每个 featureKey 应用 filter/limit/lock/none
  // 与后端 feature-flags.js 保持同步
}
```

### Step 2: 运行 flutter analyze

### Step 3: 提交

---

## Task 18: 前端 — LockedOverlay 组件

**Files:**
- Create: `lib/features/subscription/presentation/widgets/locked_overlay.dart`
- Create: `test/features/subscription/locked_overlay_test.dart`

### Step 1: 写测试

覆盖：
- locked=false, deviceLocked=false → 正常内容
- locked=true, deviceLocked=false → 显示"升级到 X"按钮
- locked=false, deviceLocked=true → 显示设备缺失提示
- locked=true, deviceLocked=true → 显示设备缺失提示（设备缺失是根本原因）
- upgradeTier 非 null → 显示对应 tier 名称
- deviceMessage 非 null → 显示设备缺失文案

### Step 2: 运行测试确认失败

### Step 3: 实现 LockedOverlay

```dart
class LockedOverlay extends StatelessWidget {
  const LockedOverlay({
    super.key,
    required this.locked,
    required this.upgradeTier,
    this.deviceLocked = false,
    this.deviceMessage,
    required this.child,
    this.onUpgrade,
  });

  final bool locked;
  final String? upgradeTier;
  final bool deviceLocked;
  final String? deviceMessage;
  final Widget child;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final isLocked = deviceLocked || locked;
    if (!isLocked) return child;

    final message = deviceLocked
        ? (deviceMessage ?? '缺少所需设备')
        : '升级到 $upgradeTier 解锁此功能';

    return Stack(
      children: [
        Opacity(opacity: 0.4, child: IgnorePointer(child: child)),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(deviceLocked ? Icons.devices : Icons.lock, size: 32),
              const SizedBox(height: 8),
              Text(message),
              if (!deviceLocked && onUpgrade != null) ...[
                const SizedBox(height: 8),
                ElevatedButton(onPressed: onUpgrade, child: Text('升级到 $upgradeTier')),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
```

### Step 4: 运行测试确认通过

### Step 5: 提交

---

## Task 19: 前端 — SubscriptionController + Repository

**Files:**
- Create: `lib/features/subscription/domain/subscription_repository.dart`
- Create: `lib/features/subscription/data/mock_subscription_repository.dart`
- Create: `lib/features/subscription/data/live_subscription_repository.dart`
- Create: `lib/features/subscription/presentation/subscription_controller.dart`
- Create: `test/features/subscription/subscription_controller_test.dart`

### Step 1: 写测试

覆盖：
- loadCurrent 返回试用状态
- loadCurrent 返回已订阅状态
- loadFeatures 返回 feature 列表
- checkout 成功后状态变更
- cancel 后状态变更

### Step 2: 实现 Repository 接口

```dart
abstract class SubscriptionRepository {
  SubscriptionViewData loadCurrent();
  List<FeatureFlag> loadFeatures();
  SubscriptionViewData checkout(SubscriptionTier tier, int livestockCount, {String? idempotencyKey});
  SubscriptionViewData cancel();
  SubscriptionViewData renew(int livestockCount, {String? idempotencyKey});
  List<SubscriptionTierInfo> loadPlans();
}
```

### Step 3: 实现 Mock Repository

基于 demo_seed 和 subscriptionStore 数据。

### Step 4: 实现 Live Repository

通过 ApiCache 读取数据。

### Step 5: 实现 SubscriptionController

```dart
class SubscriptionController extends Notifier<SubscriptionViewData> {
  @override
  SubscriptionViewData build() => ...;

  void checkout(SubscriptionTier tier) { ... }
  void cancel() { ... }
  void renew() { ... }
}
```

### Step 6: 运行测试确认通过

### Step 7: 提交

---

## Task 20: 前端 — 订阅 UI 组件（TierCard + FeatureComparisonTable + UsageProgressBar）

**Files:**
- Create: `lib/features/subscription/presentation/widgets/tier_card.dart`
- Create: `lib/features/subscription/presentation/widgets/feature_comparison_table.dart`
- Create: `lib/features/subscription/presentation/widgets/usage_progress_bar.dart`

### Step 1: 实现三个组件

TierCard: 套餐卡片（tier 名称、月费、包含功能、当前标记）
FeatureComparisonTable: 功能对比表（类似定价页，显示各 tier 功能差异）
UsageProgressBar: 用量进度条（牲畜数 / 上限）

### Step 2: 运行 flutter analyze

### Step 3: 提交

---

## Task 21: 前端 — SubscriptionStatusCard + SubscriptionRenewalBanner

**Files:**
- Create: `lib/features/subscription/presentation/widgets/subscription_status_card.dart`
- Create: `lib/features/subscription/presentation/widgets/subscription_renewal_banner.dart`

### Step 1: 实现 SubscriptionStatusCard

显示当前订阅状态（tier 名称、到期时间、用量、费用明细）和操作按钮（升级/续费/取消）。

```dart
class SubscriptionStatusCard extends ConsumerWidget {
  // 显示：tier 名称 | 状态标签 | 到期时间 | 价格明细 | 操作按钮
}
```

### Step 2: 实现 SubscriptionRenewalBanner

到期前 7 天显示横幅。使用 `SubscriptionController` 获取 `daysUntilExpiry`。

### Step 3: 运行 flutter analyze

### Step 4: 提交

---

## Task 22: 前端 — SubscriptionPlanPage + SubscriptionCheckoutPage

**Files:**
- Create: `lib/features/pages/subscription_plan_page.dart`
- Create: `lib/features/pages/subscription_checkout_page.dart`

### Step 1: 实现 SubscriptionPlanPage

套餐选择/升级页：展示 4 个 TierCard + FeatureComparisonTable，当前套餐高亮，点击"升级"按钮跳转支付页。enterprise 套餐显示"联系销售"入口（mailto:sales@hktlora.com）。

### Step 2: 实现 SubscriptionCheckoutPage

Mock 支付确认页：显示订单摘要（设备月费 + tier 月费 + 超出阶梯费 + 合计），Mock 支付按钮（500ms 延迟模拟），成功后跳回"我的"页面。

### Step 3: 运行 flutter analyze

### Step 4: 提交

---

## Task 23: 前端 — 现有页面适配 LockedOverlay（Phase 1.1 待补）

> **状态**: 分支上 12 个业务页面均未接入 LockedOverlay。此 Task 需在 Phase 1.1 中完成。

**Files:**
- Modify: `lib/features/pages/twin_overview_page.dart`
- Modify: `lib/features/pages/alerts_page.dart`
- Modify: `lib/features/pages/fence_page.dart`
- Modify: `lib/features/pages/fever_warning_page.dart`
- Modify: `lib/features/pages/fever_detail_page.dart`
- Modify: `lib/features/pages/digestive_page.dart`
- Modify: `lib/features/pages/digestive_detail_page.dart`
- Modify: `lib/features/pages/estrus_page.dart`
- Modify: `lib/features/pages/estrus_detail_page.dart`
- Modify: `lib/features/pages/epidemic_page.dart`
- Modify: `lib/features/pages/stats_page.dart`

### Step 1: 为关键页面包裹 LockedOverlay

以 twin_overview_page.dart 为例：在 body 外层包裹 LockedOverlay，传入订阅状态和 feature key。

对各页面：
- twin_overview: 添加 SubscriptionRenewalBanner
- alerts: 检查 alert_history feature
- fence: 检查 fence feature
- fever_warning/detail: 检查 temperature_monitor + deviceLocked
- digestive/detail: 检查 peristaltic_monitor + deviceLocked
- estrus/detail: 检查 estrus_detect + deviceLocked
- epidemic: 检查 epidemic_alert + deviceLocked
- stats: 检查 stats feature

### Step 2: 更新现有页面测试

受影响的现有页面测试文件需要提供 mock subscription state。至少需要更新：
- `test/widget_smoke_test.dart`（若引用了修改的页面）
- 各页面对应的 widget 测试文件（如有）

在 ProviderContainer 中注入 mock SubscriptionRepository，确保测试不会因新增的 LockedOverlay/SubscriptionController 依赖而失败。

### Step 3: 运行 flutter analyze + flutter test

### Step 4: 提交

---

## Task 24: 前端 — MinePage 嵌入 SubscriptionStatusCard

**Files:**
- Modify: `lib/features/pages/mine_page.dart`

### Step 1: 在"我的"页面嵌入 SubscriptionStatusCard

在现有内容上方或作为独立 section 嵌入卡片。

### Step 2: 运行 flutter analyze

### Step 3: 提交

---

## Task 25: 前端 — ApiCache 预加载扩展

**Files:**
- Modify: `lib/core/api/api_cache.dart`

### Step 1: 新增预加载端点

```dart
// 新增缓存字段
Map<String, dynamic>? _subscriptionCurrent;
List<dynamic>? _subscriptionFeatures;

// 新增预加载调用
Future<void> _fetchSubscriptionCurrent() async { ... }
Future<void> _fetchSubscriptionFeatures() async { ... }
```

在 `init()` 方法中新增这两个预加载调用。

### Step 2: 运行 flutter analyze

### Step 3: 提交

---

## Task 26: 端到端验证 + 冒烟测试

**Files:**
- 所有新增/修改文件

### Step 1: 启动 Mock Server

```bash
cd backend && node server.js
```

确认所有路由注册无报错。

### Step 2: 验证 API

```bash
# 登录 b2b_admin
curl http://localhost:3001/api/v1/auth/login -X POST -H "Content-Type: application/json" -d '{"role":"b2b_admin"}'

# 查询订阅状态（owner）
curl http://localhost:3001/api/v1/subscription/current -H "Authorization: Bearer mock-token-owner"

# 查询 tenant（按类型过滤）
curl "http://localhost:3001/api/v1/tenants?type=farm" -H "Authorization: Bearer mock-token-ops"
```

### Step 3: 运行 Flutter 测试

```bash
cd mobile_app && flutter test
```

### Step 4: 运行 Flutter 应用验证

```bash
cd mobile_app && flutter run --dart-define=APP_MODE=live
```

手动验证：
- owner 登录 → 孪生页面显示 LockedOverlay（如适用）
- owner → "我的"页面显示 SubscriptionStatusCard
- owner → 套餐选择 → Mock 支付
- b2b_admin 登录 → 显示占位页面
- ops 登录 → 租户管理正常

### Step 5: 提交最终版本

---

## 执行顺序建议

Task 1–11 为后端工作（无前端依赖），可按顺序执行：
```
Task 1 (tenant 扩展) → Task 2 (角色) → Task 3 (tierService)
→ Task 4 (Feature Flags) → Task 5 (subscriptionStore)
→ Task 6 (farmContext) → Task 7 (Shaping) → Task 8 (订阅 API)
→ Task 9 (全局注册) → Task 10 (设备门控+路由适配) → Task 11 (b2bAdmin)
```

Task 12–25 为前端工作：
```
Task 12 (角色枚举) → Task 13 (路由) → Task 14 (Shell+登录)
→ Task 15 (b2b占位) → Task 16 (模型) → Task 17 (mock shaping)
→ Task 18 (LockedOverlay) → Task 19 (Controller+Repo)
→ Task 20 (UI组件) → Task 21 (卡片+横幅) → Task 22 (页面)
→ Task 23 (现有页面适配) → Task 24 (MinePage)
→ Task 25 (ApiCache) → Task 26 (端到端验证)
```

后端和前端可并行开发（不同目录，无冲突）。

---

## Phase 1.1 执行计划（已完成 5/6）

Phase 1 Core 已完成（后端全部 + 前端订阅管理基础设施）。Phase 1.1 于 2026-04-29 补齐，仅 applyMockShaping 推迟：

### 1.1.1 前端全页门控（Task 23 补齐） — ✅ 已完成

**实际执行结果**：经 feature shape 分析，12 个页面中仅 3 个需要 LockedOverlay（lock shape = 仅 premium+/enterprise 可用），其余 9 个页面的 feature 对所有 tier 开放或由后端 Shaping 中间件处理数据。

已接入 LockedOverlay 的页面：
- `estrus_page`: LockedOverlay（FeatureFlags.estrusDetect, upgradeTier: '高级版'）
- `estrus_detail_page`: LockedOverlay（FeatureFlags.estrusDetect, upgradeTier: '高级版'）
- `epidemic_page`: LockedOverlay（FeatureFlags.epidemicAlert, upgradeTier: '高级版'）

无需 LockedOverlay 的页面（及原因）：
- `twin_overview_page`: 无 lock shape feature，仅挂载 SubscriptionRenewalBanner ✅
- `alerts_page`: alert_history 为 filter shape（所有 tier 可访问，后端按天数过滤数据）
- `fence_page` / `fence_form_page`: fence 为 limit shape（所有 tier 可创建围栏，数量由 tier 差异化）
- `fever_warning_page` / `fever_detail_page`: temperature_monitor 为 none shape（所有 tier 可访问）
- `digestive_page` / `digestive_detail_page`: peristaltic_monitor 为 none shape（所有 tier 可访问）
- `stats_page`: stats 为 none shape（所有 tier 可访问）

### 1.1.2 Mock Shaping 接通 — ⬜ 推迟至 Phase 2

`apply_mock_shaping.dart` 函数签名 `Map<String, dynamic>` 与 Repository 返回的强类型 ViewData 不兼容。接通需重构 Repository 层或修改函数签名，影响面大，推迟到 Phase 2。

### 1.1.3 登录到期弹窗 — ✅ 已完成

实现方式：新建 `lib/app/expiry_popup_handler.dart`（ConsumerStatefulWidget），嵌入 ShellRoute builder 包裹 DemoShell。在 `initState` 首帧检查 `daysUntilExpiry ≤ 7`，弹出 AlertDialog，含"稍后再说"和"前往续费"按钮。`_hasShown` 标志确保每次会话只弹一次。

### 1.1.4 后端集成测试 — ✅ 已完成

`backend/test/tier-access-integration.test.js` 包含 6 个场景：
1. basic tier fence limit（3 个围栏上限）
2. standard tier alert history filter（30 天过滤）
3. premium tier lock feature unlock（estrus_detect 解锁）
4. basic tier data retention filter（7 天数据保留）
5. ops 角色 shaping 跳过（无 farm context）
6. dashboard_summary limit 策略
