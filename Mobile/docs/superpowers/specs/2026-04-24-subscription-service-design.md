# SaaS 订阅服务设计规格

## 概述

为智慧畜牧系统新增 SaaS 分层付费订阅功能。牧场主（owner）按月付费使用平台，四层订阅（基础/标准/高级/企业），混合计费模式（基础月费 + 牲畜阶梯加价）。仅 owner 角色可订阅，worker 继承 owner 的订阅权限。

当前阶段为 MVP：实现完整权限体系和 UI，支付流程用 Mock 模拟。包含以下完整流程：

- **试用**：新租户自动获得高级版 14 天免费试用，到期自动降级为基础版
- **订阅/升级**：选择套餐 → Mock 支付 → 立即生效
- **续费**：周期到期前 7 天提醒，到期后标记需手动续费
- **取消**：从套餐管理页发起，当前周期内仍可用，到期降级
- **降级**：降级后超量数据隐藏但保留，重新订阅后恢复可见
- **企业版**：展示"联系销售"入口，邮件发送订阅需求至 sales@hktlora.com

## 订阅层级

| 属性 | 基础版（免费） | 标准版 | 高级版 | 企业版 |
|------|--------------|--------|--------|--------|
| 月费 | ¥0 | ¥299 | ¥699 | 定制报价 |
| 包含牲畜数 | 50 | 200 | 1000 | 无限 |
| 超出加价 | — | 每 50 头 +¥50 | 每 100 头 +¥80 | — |
| 前端操作 | — | 升级按钮 | 升级/续费/取消 | "联系销售"代替购买 |

> **试用**：新租户自动获得高级版 14 天免费试用（`status: 'trial'`），试用到期后自动降级为基础版。

### 计费示例

- 标准版：牧场主养 350 头牛 → ¥299（含 200 头）+ ¥150（超出 150 头，3×¥50）= ¥449/月
- 高级版：牧场主养 1500 头牛 → ¥699（含 1000 头）+ ¥400（超出 500 头，5×¥80）= ¥1,099/月

## Feature Flag 清单

| key | 分类 | basic | standard | premium | enterprise |
|-----|------|-------|----------|---------|------------|
| `gps_location` | location | ✓ | ✓ | ✓ | ✓ | 注：无独立端点，地图页面渲染 GPS 坐标时使用，所有层级 shape 策略为 none
| `fence` | location | ✓ limit=3 | ✓ | ✓ | ✓ |
| `trajectory` | location | ✗ | ✓ | ✓ | ✓ |
| `temperature_monitor` | health | ✓ | ✓ | ✓ | ✓ |
| `peristaltic_monitor` | health | ✓ | ✓ | ✓ | ✓ |
| `health_score` | health | ✗ | ✗ | ✓ | ✓ |
| `estrus_detect` | health | ✗ | ✗ | ✓ | ✓ |
| `epidemic_alert` | health | ✗ | ✗ | ✓ | ✓ |
| `gait_analysis` | analytics | ✗ | ✗ | ✗ | ✓ |
| `behavior_stats` | analytics | ✗ | ✗ | ✗ | ✓ |
| `api_access` | analytics | ✗ | ✗ | ✗ | ✓ |
| `data_retention_days` | service | 7 | 30 | 365 | ∞ |
| `alert_history` | service | ✗ | ✓ | ✓ | ✓ |
| `dedicated_support` | service | ✗ | ✗ | ✓ | ✓ |
| `device_management` | management | ✓ | ✓ | ✓ | ✓ |
| `livestock_detail` | management | ✓ | ✓ | ✓ | ✓ |
| `stats` | analytics | ✓ | ✓ | ✓ | ✓ |
| `dashboard_summary` | analytics | ✓ limit | ✓ | ✓ | ✓ |
| `profile` | management | ✓ | ✓ | ✓ | ✓ |
| `tenant_admin` | management | ✓ | ✓ | ✓ | ✓ |

## 数据模型

### SubscriptionTier

```
SubscriptionTier {
  id: 'basic' | 'standard' | 'premium' | 'enterprise',
  name: String,
  monthlyPrice: int,        // 月费，单位：分。basic=0, standard=29900, premium=69900, enterprise=null（定制报价）
                            //   前端展示时需除以 100 转换为元：¥(monthlyPrice / 100)
  includedLivestock: int,   // 包含牲畜数，enterprise 为 -1（表示无限）
  perUnitPrice: int | null, // 超出后每单位价格，单位：分。仅 standard/premium 有效，basic/enterprise 为 null
  perUnitSize: int | null,  // 每单位包含牲畜数。仅 standard/premium 有效，basic/enterprise 为 null
}
```

### SubscriptionStatus

```
SubscriptionStatus {
  tenantId: String,
  tier: SubscriptionTier,
  currentPeriodStart: DateTime,
  currentPeriodEnd: DateTime,
  status: 'active' | 'trial' | 'expired' | 'cancelled',
  livestockCount: int,       // 从现有牲畜数据实时统计（按 tenantId 统计该租户下的牲畜数量）
  calculatedPrice: int,      // 实际月费，单位：分（含超量加价）
  trialEndsAt: DateTime?,    // 试用结束时间（仅 status='trial' 时有值）
  daysUntilExpiry: int?,     // 距到期天数（到期前 30 天内计算），null 表示不适用
}
```

**到期提醒级别**（基于 `daysUntilExpiry`）：

| 天数 | 级别 | 行为 |
|------|------|------|
| ≤ 7 | `warning` | 首页黄色横幅 + 每登录弹窗提醒 |
| ≤ 3 | `critical` | 首页红色横幅 + 每登录弹窗提醒 |
| = 0 | `expired` | 自动降级基础版，status 改为 'expired' |

## 后端架构：响应塑造

### 核心机制

采用响应塑造（Response Shaping），通过替换 Express 的 `res.ok()` 辅助函数实现。现有路由处理函数调用 `res.ok(data)` 时，shaping 逻辑在数据序列化之前介入，根据订阅层级改造数据后返回。

### 技术实现：替换 res.ok()

现有 `envelopeMiddleware` 为 `res` 挂载了 `res.ok(data)` 和 `res.fail()` 辅助函数。shaping 中间件通过包装 `res.ok()` 实现后置拦截：

```javascript
// middleware/feature-flag.js
function shapingMiddleware(req, res, next) {
  const originalOk = res.ok.bind(res);
  res.ok = (data, message) => {
    const tenantId = req.user?.tenantId;  // 由 authMiddleware 设置
    if (tenantId == null) return originalOk(data, message);  // ops 跳过
    const tier = getSubscriptionTier(tenantId);
    // 对每个 feature key 按 filter → limit → lock 顺序依次执行
    const shaped = applyShapingRules(data, tier, req.routeFeatureKeys);
    originalOk(shaped, message);  // 保留 message 参数透传
  };
  next();
}
```

**管道执行顺序**：`filter` → `limit` → `lock`（先裁剪数据，再注入限制元数据，最后判断锁定）。`none` 策略跳过。

前置依赖：`authMiddleware` 需在解析 token 后设置 `req.user.tenantId`（当前 `middleware/auth.js` 已设置 `req.user`，其中包含 `tenantId` 字段，但需确认该字段始终存在）。

**ops 角色绕过**：ops 用户 `tenantId` 为 `null`（seed.js），shaping 中间件检测到 `req.user.tenantId == null` 时直接调用 `originalOk(data, message)` 跳过所有 shaping 规则。ops 仅访问租户管理后台（`/api/tenants/*`），不受订阅限制。

**`req.routeFeatureKeys` 设置**：每个路由模块在注册 `shapingMiddleware` 前通过自定义中间件设置 feature key 数组，支持多个 key 叠加：

```javascript
// routes/twin.js — 单 key 示例
router.use(authMiddleware);
router.use(requirePermission('twin:view'));
router.use((req, res, next) => {
  req.routeFeatureKeys = ['estrus_detect'];  // 本路由匹配的 feature flags
  next();
});
router.use(shapingMiddleware);

// routes/alerts.js — 多 key 示例（filter + lock 同时生效）
router.use(authMiddleware);
router.use(requirePermission('alert:view'));
router.use((req, res, next) => {
  req.routeFeatureKeys = ['data_retention_days', 'alert_history'];
  next();
});
router.use(shapingMiddleware);
```

大部分路由仅需一个 feature key，少数端点（alerts、trajectories）需要多 key 叠加。路由处理函数不感知订阅，调用 `res.ok(data)` 时 shaping 自动生效。

### 中间件注册顺序

当前代码库中 `authMiddleware` 按路由模块注册（如 `routes/twin.js` 中 `router.use(authMiddleware)`），而非全局注册。shaping 中间件同样采用**按路由注册**方式，在 auth 之后挂载：

```javascript
// server.js — 全局中间件（不变）
app.use(cors());
app.use(express.json());
app.use(requestContext(runtimeConfig));
app.use(envelopeMiddleware);   // 1) 全局挂载 res.ok() / res.fail()

// 方式 A：在各路由文件中，auth 之后添加 shaping
//   routes/twin.js:
//     router.use(authMiddleware);
//     router.use(requirePermission('twin:view'));
//     router.use(shapingMiddleware);   // ← 新增，在 auth 之后
//
// 方式 B：在 registerApiRoutes 中统一包装
//   registerApiRoutes 内部为每个路由模块自动插入 shapingMiddleware

registerApiRoutes(app, '/api');
registerApiRoutes(app, '/api/v1');
```

推荐**方式 A**（按路由文件显式注册），与现有 auth 模式一致，且允许每个路由模块指定自己的 `routeFeatureKey`。

若后续将 auth 改为全局注册，shaping 亦应同步改为全局注册（`app.use(authMiddleware)` → `app.use(shapingMiddleware)`）。

### 请求生命周期（按路由注册模式）

```
请求进入
  → 全局中间件：cors → json → requestContext → envelopeMiddleware（挂载 res.ok/res.fail）
  → 路由模块匹配
  → auth 中间件（路由级）：解析 Bearer token → req.user.role + req.user.tenantId
  → feature keys 中间件（路由级）：req.routeFeatureKeys = ['key1', 'key2']
  → shaping 中间件（路由级）：包装 res.ok()，替换为 shaping 版本
  → 路由处理函数：正常执行，调用 res.ok(data, message?)
  → res.ok() 被 shaping 拦截：
      1. 若 req.user.tenantId 为 null（ops），跳过 shaping，直接透传
      2. 检查订阅到期：若 status='trial' 且 now > trialEndsAt → 自动降级 basic
         若 status='active'/'cancelled' 且 now > currentPeriodEnd → 自动降级 basic
      3. 从 req.user.tenantId 获取当前订阅层级 tier
      4. 遍历 req.routeFeatureKeys，按 filter → limit → lock 顺序依次执行各规则
      5. 调用原始 res.ok(shapedData, message) → res.json(envelope(shapedData))
  → 响应发送给前端（res.json 直接序列化，无后续中间件介入）
```

注册顺序约束：`envelopeMiddleware`（全局）→ `authMiddleware`（路由级）→ `featureKeys`（路由级）→ `shapingMiddleware`（路由级）。若顺序颠倒，shaping 包装时 `res.ok` 尚不存在或 `req.user` 未设置，会导致运行时错误。

**到期自动降级逻辑**（每次请求时在 shaping 中间件中检测）：

| 当前 status | 触发条件 | 操作 |
|------------|---------|------|
| `trial` | `now > trialEndsAt` | status → 'expired'，tier → 'basic' |
| `active` | `now > currentPeriodEnd` | status → 'expired'，tier → 'basic' |
| `cancelled` | `now > currentPeriodEnd` | status → 'expired'，tier → 'basic' |

### Locked 注入结构

lock 策略在**信封级别**注入 locked 状态，不修改 items 数组内容：

```json
{
  "code": 200,
  "message": "success",
  "requestId": "xxx",
  "data": {
    "locked": true,
    "upgradeTier": "premium",
    "message": "发情检测需要高级版",
    "items": [],
    "total": 0
  }
}
```

前端根据 `data.locked` 判断：如果为 true，渲染 LockedOverlay 遮罩，items 为空或仅含预览数据。

limit 策略在 data 级别注入限制信息：

```json
{
  "code": 200,
  "data": {
    "items": [...],
    "total": 3,
    "limit": { "maxCount": 3, "locked": true, "upgradeTier": "standard", "message": "基础版最多 3 个围栏" }
  }
}
```

### 四种 Shaping 策略

| 策略 | 行为 | 示例 |
|------|------|------|
| **lock** | 注入 `{ locked: true, upgradeTier, message }` | basic 用户访问发情检测 |
| **limit** | 限制数量，超出时隐藏新建/新增 | basic 最多 3 个围栏 |
| **filter** | 按时间/数量过滤实际数据 | basic 告警只保留 7 天 |
| **none** | 完全放行 | 所有层级可访问 GPS 定位 |

### Shaping 配置示例

```javascript
{
  'estrus_detect': {
    shaping: 'lock',
    minTier: 'premium',
    lockMeta: { upgradeTier: 'premium', message: '发情检测需要高级版' }
  },
  'fence': {
    shaping: 'limit',
    rulesByTier: {
      basic: { maxCount: 3, onExceed: 'lock_new', message: '基础版最多 3 个围栏' }
    }
  },
  'data_retention_days': {
    shaping: 'filter',
    rulesByTier: { basic: 7, standard: 30, premium: 365, enterprise: null },
    // filterField 按端点区分（见"对现有端点的影响"表）：
    //   alerts → occurredAt
    //   trajectories → recordedAt
    //   twin/sensor 数据 → timestamp
    // 在 applyShapingRules 中根据 req.routeFeatureKey 选择正确的 field
  },
  'alert_history': {
    shaping: 'lock',
    minTier: 'standard',
    lockMeta: { upgradeTier: 'standard', message: '告警历史查询需要标准版' }
  },
  'dashboard_summary': {
    shaping: 'limit',
    rulesByTier: {
      basic: {
        visibleMetrics: ['livestockCount', 'deviceOnlineRate', 'todayAlerts'],
        onExceed: 'hide_metrics',
        message: '升级标准版解锁健康评分、行为统计等高级指标'
      }
    }
  }
}
```

### 新增后端文件

```
backend/
├── middleware/
│   └── feature-flag.js          # 新增：后置响应塑造中间件（含到期检测 + 多 key 管道）
├── data/
│   ├── feature-flags.js         # 新增：Feature Flag 定义 + shaping 规则
│   ├── subscriptions.js         # 新增：订阅状态种子数据 + subscriptionStore（createTrial/getByTenantId/update/checkout/cancel/renew）
│   └── tenantStore.js           # 修改：导出 tenantEvents 用于订阅感知（或直接由 routes/tenants.js 串行调用）
├── routes/
│   ├── tenants.js               # 修改：POST handler 串行调用 subscriptionStore.createTrial()
│   └── subscription.js          # 新增：订阅管理 API（current/features/plans/checkout/cancel/renew/usage）
└── server.js                    # 修改：注册 subscription 路由
```

**`data/feature-flags.js` schema**：

```javascript
// 返回 Feature Flag 配置 Map
// key: featureKey (string) → value: ShapingRule
{
  'estrus_detect': {
    featureKey: 'estrus_detect',
    category: 'health',
    shaping: 'lock',                    // 'lock' | 'limit' | 'filter' | 'none'
    minTier: 'premium',                 // 解锁最低层级，null 表示所有层级可用
    lockMeta: {                         // 仅 shaping='lock' 时需要
      upgradeTier: 'premium',
      message: '发情检测需要高级版'
    },
    rulesByTier: {                      // 仅 shaping='limit'/'filter' 时需要
      basic: { maxCount: 3, onExceed: 'lock_new', message: '...' }
      // standard: 未定义即无限制
    }
  },
  // ... 其他 feature
}
```

**`data/subscriptions.js` schema**：

```javascript
// 内存 Map: tenantId → SubscriptionStatus
// 种子数据中所有现有租户（tenant_001 ~ tenant_006）均设为基础版
// 新创建的租户自动获得高级版 14 天试用
{
  'tenant_001': {
    tenantId: 'tenant_001',
    tier: 'basic',                      // 'basic' | 'standard' | 'premium' | 'enterprise'
    currentPeriodStart: '2026-04-01',
    currentPeriodEnd: '2026-05-01',
    status: 'active',                   // 'active' | 'trial' | 'expired' | 'cancelled'
    livestockCount: 120,                // 从现有牲畜数据实时统计
    calculatedPrice: 0,                 // 单位：分
    // trialEndsAt: null,               // 非试用状态为 null
  },
  // 新创建租户示例（自动生成）：
  'tenant_007': {
    tenantId: 'tenant_007',
    tier: 'premium',                    // 试用高级版
    currentPeriodStart: '2026-04-27',
    currentPeriodEnd: '2026-05-27',     // 30 天周期（含 14 天试用）
    status: 'trial',
    livestockCount: 0,
    calculatedPrice: 0,
    trialEndsAt: '2026-05-11',          // 14 天后
  }
}
```

**`subscriptionStore` 新增函数**：

```javascript
function createTrial(tenantId) {
  const now = new Date();
  const trialEnd = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);
  const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const subscription = {
    tenantId,
    tier: 'premium',
    currentPeriodStart: now.toISOString().split('T')[0],
    currentPeriodEnd: periodEnd.toISOString().split('T')[0],
    status: 'trial',
    livestockCount: 0,
    calculatedPrice: 0,
    trialEndsAt: trialEnd.toISOString().split('T')[0],
  };
  subscriptions.set(tenantId, subscription);
  return subscription;
}
```

**与租户创建的耦合**：`routes/tenants.js` 的 POST handler 在 `store.createTenant()` 成功后，串行调用 `subscriptionStore.createTrial(tenant.id)` 为新租户创建试用订阅。

### 对现有端点的影响

| 现有端点 | Shaping 行为 |
|---------|-------------|
| `GET /api/map/trajectories` | featureKeys: `['trajectory', 'data_retention_days']` — basic: lock 注入 + filter 按 7 天截断 `recordedAt`；standard+: filter 按层级天数，无 lock |
| `GET /api/fences` | featureKeys: `['fence']` — basic 用户限制最多 3 个围栏 |
| `POST /api/fences` | featureKeys: `['fence']` — basic 已有 3 个围栏时返回 locked。**注意**：POST 不返回列表，shaping 中间件仅拦截 `res.ok()` 调用。POST handler 需在调用 `res.ok()` 前自行检查围栏数量并注入 locked。 |
| `GET /api/twin/fever/list` `GET /api/twin/fever/:id` | 所有层级可用（temperature_monitor 在 basic 开放），无 locked/filter |
| `GET /api/twin/digestive/list` `GET /api/twin/digestive/:id` | 所有层级可用（peristaltic_monitor 在 basic 开放），无 locked/filter |
| `GET /api/twin/estrus/list` `GET /api/twin/estrus/:id` | basic/standard 注入 locked（trial/premium+ 正常）；降级后仅 lock 新请求，历史数据可读 |
| `GET /api/twin/epidemic/summary` `GET /api/twin/epidemic/contacts` | basic/standard 注入 locked（trial/premium+ 正常）；降级后仅 lock 新请求，历史数据可读 |
| `GET /api/alerts` | featureKeys: `['data_retention_days', 'alert_history']` — basic: filter 按 7 天截断 `occurredAt` + lock 历史 tab；standard: filter 30 天，无 lock |
| `GET /api/dashboard/summary` | basic 仅展示 `livestockCount`、`deviceOnlineRate`、`todayAlerts` 三项基础指标，standard+ 展示全部指标 |
| `GET /api/devices` | 所有层级可用 |
| `GET /api/profile` | 所有层级可用 |
| `GET /api/tenants/*` | 所有层级可用（ops 角色权限控制） |

### 订阅管理 API

> **重要**：`/api/subscription/*` 路由**不注册 shaping 中间件**（仅注册 authMiddleware），避免订阅端点自身被 shaping 拦截（如 `/api/subscription/current` 返回 locked）。

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/subscription/current` | GET | 获取当前订阅状态（层级、到期时间、实际月费、`daysUntilExpiry`） |
| `/api/subscription/features` | GET | 获取当前层级的功能清单 + 限制配置 |
| `/api/subscription/plans` | GET | 获取全部可选套餐列表（供升级页展示），企业版含 `contactSales: true` |
| `/api/subscription/checkout` | POST | Mock 支付：选择套餐 → 立即生效 |
| `/api/subscription/cancel` | POST | 取消订阅：标记 cancelled，当前周期内仍可用 |
| `/api/subscription/renew` | POST | 续费同一层级：`currentPeriodEnd += 30天`，status 恢复为 active |
| `/api/subscription/usage` | GET | 当前用量统计（牲畜数/围栏数/数据量 vs 套餐限制） |

## 前端架构

### 模块结构

```
core/models/
└── subscription_tier.dart              # Tier 枚举 + Feature 定义（跨模块共享）
widgets/
└── locked_overlay.dart                 # 通用锁定遮罩组件（跨模块共享）
features/subscription/
├── domain/
│   └── subscription_repository.dart
├── data/
│   ├── mock_subscription_repository.dart
│   └── live_subscription_repository.dart
├── presentation/
│   ├── subscription_controller.dart
│   ├── subscription_status_card.dart      # "我的"页面内嵌卡片
│   ├── subscription_plan_page.dart        # 套餐选择/升级页
│   ├── subscription_checkout_page.dart    # Mock 支付页
│   └── widgets/
│       ├── tier_card.dart                 # 单个套餐卡片
│       ├── feature_comparison_table.dart  # 功能对比表
│       └── usage_progress_bar.dart        # 用量进度条
```

### LockedOverlay 统一组件

```dart
LockedOverlay(
  isLocked: item.locked,
  requiredTier: SubscriptionTier.premium,
  showUpgradeButton: currentRole == DemoRole.owner,  // 仅 owner 显示升级按钮
  child: <原有功能 Widget>,
)
```

行为：功能 Widget 正常渲染，覆盖半透明遮罩 + 锁图标。若 `showUpgradeButton` 为 true（owner），显示"升级到 X 版解锁"按钮，点击导航到 `/subscription`。若为 false（worker），仅显示锁图标和功能不可用提示，不显示升级入口。

### 各页面 Locked 处理

| 页面 | Locked 场景 | 处理方式 |
|------|------------|---------|
| 孪生总览 `/twin` | 发热/消化正常，发情/疫病卡片 locked | 卡片覆盖 LockedOverlay |
| 发热/消化详情 | 所有层级正常 | 无需处理 |
| 围栏列表 | basic 已有 3 个围栏，新建按钮 locked | 新建按钮禁用 + 提示 |
| 告警历史 tab | basic 用户历史 tab locked | Tab 可见但带锁 |
| 地图轨迹 | basic 用户轨迹按钮 locked | 按钮带锁 + 提示 |

### 两层权限体系

```
第一层：RolePermission（owner/worker/ops）
  → 不变，角色级访问控制

第二层：SubscriptionPermission（订阅层级）
  → 在角色权限通过后，按订阅层级控制功能可用性

互不干扰：
  - worker 继承 owner 的订阅层级权限
  - ops 无需订阅（租户管理后台）
```

**SubscriptionPermission 实现方式**：前端不自行重新判断订阅权限，而是纯粹依赖后端 API 响应中的 `locked`/`limit` 字段：

- **API 响应驱动**：每个 API 调用返回的数据中，后端的 shaping 中间件已注入 `locked` 或 `limit` 字段。前端只需读取这些字段决定 UI 行为。
- **SubscriptionController**（Riverpod Notifier）负责缓存当前订阅状态（`GET /api/subscription/current`），仅供 `SubscriptionStatusCard` 展示套餐信息和升级入口使用，不参与逐请求的权限判断。
- **LockedOverlay** 组件根据数据中的 `locked`/`limit` 字段渲染遮罩或限制提示，不自行查询订阅层级。

```dart
// 前端判断逻辑示例
if (data.locked == true) {
  return LockedOverlay(requiredTier: data.upgradeTier, message: data.message);
}
if (data.limit != null && data.limit.locked == true) {
  // 显示限制提示，禁用新建按钮
}
```

### 路由新增与守卫

**AppRoute enum 新增**（`app/app_route.dart`）：

```dart
enum AppRoute {
  // ... 现有值 ...
  subscription('/subscription', 'subscription', '订阅管理'),
  checkout('/subscription/checkout', 'checkout', '确认支付'),
}
```

注：现有 enum 构造函数为 `AppRoute(this.path, this.routeName, this.label)`，新增值遵循相同模式。两个路由均为全屏独立页面，不在 `ShellRoute` 的底部导航范围内。

**GoRouter 注册**（`app/app_router.dart`）：在 `ShellRoute` 之前插入两条独立路由（无底部导航栏）：

```dart
// app_router.dart
GoRouter(
  // ... redirect guard ...
  routes: [
    // 订阅路由（ShellRoute 外部，独立全屏页面）
    GoRoute(
      path: '/subscription',
      name: AppRoute.subscription.routeName,
      builder: (context, state) => const SubscriptionPlanPage(),
      redirect: (context, state) {
        final role = ref.read(sessionControllerProvider).role;
        if (role != DemoRole.owner) return '/mine';
        return null;
      },
      routes: [
        GoRoute(
          path: 'checkout',
          name: AppRoute.checkout.routeName,
          builder: (context, state) => const SubscriptionCheckoutPage(),
          redirect: (context, state) {
            final role = ref.read(sessionControllerProvider).role;
            if (role != DemoRole.owner) return '/mine';
            return null;
          },
        ),
      ],
    ),
    // ShellRoute（底部导航页面）
    ShellRoute(
      // ... 现有路由树 ...
    ),
  ],
)
```

路由守卫规则：
- 仅 `owner` 角色可访问 `/subscription` 和 `/subscription/checkout`
- `worker` 访问时重定向到 `/mine`（"我的"页面不显示订阅入口）
- `ops` 角色无订阅相关入口
- 两个路由放在 `ShellRoute` 外部（不显示底部导航），独立全屏页面

入口：`features/mine/presentation/` 的"我的"页面中嵌入 `SubscriptionStatusCard`，点击跳转。

### ApiCache 集成

新增预加载端点（加入 `ApiCache.init()` 列表，与现有 13 个请求并行加载）：
- `GET /api/subscription/current` — 当前订阅状态
- `GET /api/subscription/features` — 功能清单 + locked 状态

缓存失效策略：订阅状态变更（checkout / cancel / renew）成功后，调用 `ApiCache.instance.init()` 完全重新初始化缓存。这确保所有端点数据根据新订阅层级重新加载（locked 状态解除、数据过滤范围变化等）。

### Mock 模式兼容

在 `APP_MODE=mock` 下，请求不经过后端 shaping 中间件，Mock Repository 需要自行模拟 `locked`/`limit` 注入：

- `MockSubscriptionRepository` 返回当前 mock 订阅层级（默认 basic）
- 各 `MockXxxRepository` 在返回数据前，调用一个共享的 `applyMockShaping(data, featureKey, tier)` 函数，模拟后端 shaping 规则
- 这确保 Mock 模式下也能看到 LockedOverlay 遮罩和 limit 限制，前端开发调试无需依赖 live 模式

### 种子数据对齐

- `backend/data/subscriptions.js`：默认 owner 租户为 basic 层级
- `mobile_app/lib/core/data/demo_seed.dart`：同步新增订阅假数据

## Mock 支付流程

```
用户点击"订阅标准版"
  → POST /api/subscription/checkout { tier: 'standard', period: 'monthly', idempotencyKey: 'uuid-xxx' }
  → 服务端：模拟支付延迟（500ms）→ 更新内存中租户订阅状态
  → 返回 { success: true, newTier: 'standard', validUntil: '2026-05-24' }
  → 前端：调用 ApiCache.instance.init() 完全重载 → SubscriptionController 更新 → 跳转回"我的"
```

支付成功后的 UI 过渡：
1. Checkout 页面显示 loading spinner（ApiCache 重载期间）
2. ApiCache 全部请求完成后，SubscriptionController 状态更新
3. locked 状态自动解除（新订阅层级的数据已加载）
4. 自动跳转回"我的"页面，SubscriptionStatusCard 显示新套餐信息

`idempotencyKey`：前端生成的 UUID，防止双击重复提交。Mock Server 存储策略：内存 `Map<string, { result, timestamp }>`，5 分钟 TTL（setInterval 定时扫描过期），相同 key 在 TTL 内返回缓存结果，否则按新请求处理。

### Mock 续费流程

```
用户点击"立即续费"
  → POST /api/subscription/renew { idempotencyKey: 'uuid-xxx' }
  → 服务端：模拟延迟（500ms）→ currentPeriodEnd += 30天，status 恢复为 active
  → 返回 { success: true, newPeriodEnd: '2026-06-24' }
  → 前端：调用 ApiCache.instance.init() 重载 → SubscriptionController 更新 → 跳转回"我的"
```

### 升级/降级/续费处理

| 操作 | Mock Server 行为 |
|------|-----------------|
| 升级 | 立即生效，tier 更新，`currentPeriodEnd` 重置为 30 天后 |
| 降级 | 立即生效（MVP 简化），超量数据隐藏但保留，重新订阅后恢复 |
| 续费 | 同一层级续费，`currentPeriodEnd += 30天`，status 恢复为 active |
| 取消 | 标记 cancelled，当前周期内仍可用，到期自动降级 basic |
| 试用到期 | 每次请求时检测，`now > trialEndsAt` → status='expired'，tier='basic' |
| 周期到期 | active/cancelled 在 `now > currentPeriodEnd` 时自动降级 basic |

### 试用流程

```
新租户注册
  → subscriptionStore.createTrial(tenantId)
  → tier='premium'，status='trial'，trialEndsAt=14天后
  → 试用期间可正常使用所有高级版功能
  → 每次请求时 shaping 中间件检查 now > trialEndsAt
      → 若到期：自动降级 basic，status='expired'
  → 试用期内可随时升级到付费版（checkout 操作覆盖试用状态）
```

**试用期升级**：试用期间调用 `POST /api/subscription/checkout` 选择付费套餐，`status` 从 trial 变为 active，`trialEndsAt` 置 null，正常计费。

**试用取消**：试用期取消立即生效（无当前周期），直接降级为基础版（status='expired'）。

### 取消订阅流程

入口：套餐管理页（`/subscription`）底部文字链接 "计划有变？你可以取消订阅"。

```
用户点击"取消订阅"
  → 确认弹窗：说明降级后果（列出将失去的功能），显示"保留订阅"/"确认取消"
  → 用户点击"确认取消"
      → POST /api/subscription/cancel
      → status='cancelled'，当前周期内仍可正常使用
      → 前端更新状态卡片：显示"已取消"标签 + 到期日期 + "重新订阅"按钮
  → 到期后 shaping 中间件自动降级 basic
```

前端确认弹窗内容包括：
- 当前套餐到期日期
- "到期后自动降级为基础版（免费）"
- 降级将失去的功能列表（根据当前 tier 动态生成）

### 到期续费提醒

**触发时机**：`GET /api/subscription/current` 响应中 `daysUntilExpiry` 字段驱动。

**提醒级别**：

| 剩余天数 | 级别 | 前端行为 |
|---------|------|---------|
| 8-30 天 | 无 | 无特殊提示 |
| 4-7 天 | `warning` | 孪生总览页顶部黄色横幅"订阅将于 X 天后到期" + 登录弹窗提醒（每次登录直到用户关闭） |
| 1-3 天 | `critical` | 孪生总览页顶部红色横幅"订阅即将到期！" + 登录弹窗提醒（每次登录） |
| 0 天 | `expired` | 红色横幅"订阅已过期，已降级为基础版" + 登录弹窗 |

**登录弹窗**：`main.dart` 登录成功后检查 `daysUntilExpiry ≤ 7`，若满足则弹出对话框。用户关闭后记录本地标志 `lastDismissedExpiryReminder`，当日不再重复显示（次日重置）。

**首页横幅**：`TwinOverviewPage` 顶部渲染 `SubscriptionRenewalBanner` widget，根据 `daysUntilExpiry` 切换样式。横幅可点击，跳转到 `/subscription`。

### 降级后数据处理

降级（包括取消到期、试用到期、手动降级）后，超出基础版限制的数据**隐藏但保留**：

- **lock 类功能**（发情检测、疫病预警等）：降级前已在客户端缓存中的数据保持可见（前端不主动清除）；降级后新的 API 请求响应注入 `locked: true`，阻止刷新获取新数据。即降级后该功能变为"只读"——已缓存数据可看，新请求锁定。
- **filter 类数据**（告警历史等）：shaping 按基础版规则（7天）过滤，超过 7 天的数据不返回。重新订阅高级版后恢复 365 天范围。
- **limit 类资源**（围栏等）：shaping 返回 limit 对象限制新建，已有资源保留可查看/编辑。

**重新订阅恢复**：用户重新订阅后，所有隐藏数据和新操作权限立即恢复。

## 测试策略

### 后端测试

新增文件：`feature-flag.test.js`、`response-shaping.test.js`、`subscription-api.test.js`、`tier-access-integration.test.js`

核心场景：
- basic 用户访问 `/api/twin/estrus` → locked: true
- basic 用户访问 `/api/twin/fever` → 正常返回
- basic 用户创建第 4 个围栏 → locked
- basic 用户告警数据按 7 天截断（filter），同时 alert_history locked
- basic 用户 trajectories 同时 locked + filter 截断
- 多 key 叠加测试（alerts: data_retention_days + alert_history 同时生效）
- 管道执行顺序测试（确保 filter → limit → lock，filter 先裁剪数据再 lock 判断）
- trial 用户正常访问高级版功能
- trial 到期（now > trialEndsAt）→ 自动降级 basic，locked 注入
- active 周期到期 → 自动降级 basic
- cancelled 周期到期 → 自动降级 basic
- 升级后功能解锁
- 取消订阅 → status='cancelled'，当前周期内仍可用
- 续费 → currentPeriodEnd 延长，status 恢复 active
- 新租户自动创建 trial 订阅
- ops 角色所有请求跳过 shaping
- Mock 模式下 Mock Repository 正确注入 locked/limit 字段（不依赖后端 shaping）

### 前端测试

新增文件：`subscription_tier_test.dart`、`locked_overlay_test.dart`、`subscription_controller_test.dart`、`tier_visibility_test.dart`、`subscription_checkout_flow_test.dart`、`subscription_cancel_flow_test.dart`、`subscription_renewal_reminder_test.dart`

核心场景：
- LockedOverlay locked=true 显示遮罩 + 升级按钮
- LockedOverlay locked=false 正常渲染
- LockedOverlay showUpgradeButton=false（worker）隐藏升级按钮
- basic 用户孪生页面：发热/消化正常，发情/疫病有锁
- worker 用户看到锁定遮罩但无升级按钮
- Mock 支付成功后 Controller 状态更新
- 取消订阅确认弹窗内容正确
- 取消后状态卡片显示"已取消"标签 + 到期日期
- 到期提醒横幅在 7 天/3 天/到期时显示正确的级别和样式
- 登录弹窗在 daysUntilExpiry ≤ 7 时弹出
- 企业版"联系销售"按钮渲染正确
- 试用到期后自动降级 UI 展示正确
- 升级后 ApiCache 刷新，locked 状态解除
