# SaaS 订阅服务设计规格

## 概述

为智慧畜牧系统新增 SaaS 分层付费订阅功能。牧场主（owner）按月付费使用平台，四层订阅（基础/标准/高级/企业），混合计费模式（基础月费 + 牲畜阶梯加价）。仅 owner 角色可订阅，worker 继承 owner 的订阅权限。

当前阶段为 MVP：实现完整权限体系和 UI，支付流程用 Mock 模拟。

## 订阅层级

| 属性 | 基础版（免费） | 标准版 | 高级版 | 企业版 |
|------|--------------|--------|--------|--------|
| 月费 | ¥0 | ¥299 | ¥699 | 定制 |
| 包含牲畜数 | 50 | 200 | 1000 | 无限 |
| 超出加价 | — | 每 50 头 +¥50 | 每 100 头 +¥80 | — |

### 计费示例

- 标准版：牧场主养 350 头牛 → ¥299（含 200 头）+ ¥150（超出 150 头，3×¥50）= ¥449/月
- 高级版：牧场主养 1500 头牛 → ¥699（含 1000 头）+ ¥400（超出 500 头，5×¥80）= ¥1,099/月

## Feature Flag 清单

| key | 分类 | basic | standard | premium | enterprise |
|-----|------|-------|----------|---------|------------|
| `gps_location` | location | ✓ | ✓ | ✓ | ✓ |
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
  includedLivestock: int,   // 包含牲畜数，enterprise 为 -1（表示无限）
  perUnitPrice: int,        // 超出后每单位价格，单位：分
  perUnitSize: int,         // 每单位包含牲畜数
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
  livestockCount: int,
  calculatedPrice: int,     // 实际月费，单位：分（含超量加价）
  trialEndsAt: DateTime?,   // 试用结束时间（仅 status='trial' 时有值）
}
```

## 后端架构：响应塑造

### 核心机制

采用响应塑造（Response Shaping），通过替换 Express 的 `res.ok()` 辅助函数实现。现有路由处理函数调用 `res.ok(data)` 时，shaping 逻辑在数据序列化之前介入，根据订阅层级改造数据后返回。

### 技术实现：替换 res.ok()

现有 `envelopeMiddleware` 为 `res` 挂载了 `res.ok(data)` 和 `res.fail()` 辅助函数。shaping 中间件通过包装 `res.ok()` 实现后置拦截：

```javascript
// middleware/feature-flag.js
function shapingMiddleware(req, res, next) {
  const originalOk = res.ok.bind(res);
  res.ok = (data) => {
    const tier = getSubscriptionTier(req.tenantId);
    const shaped = applyShapingRules(data, tier, req.routeFeatureKey);
    originalOk(shaped);
  };
  next();
}
```

路由处理函数不感知订阅，调用 `res.ok(data)` 时 shaping 自动生效。

### 请求生命周期

```
请求进入
  → auth 中间件：解析 Bearer token → 角色 + tenantId
  → shaping 中间件：包装 res.ok()，注入 shaping 逻辑
  → 路由处理函数：正常执行，调用 res.ok(data)
  → res.ok() 被拦截：
      1. 查询 tenantId 对应的订阅层级
      2. 根据 tier 查 Feature Flag 配置
      3. 对 data 执行 shaping 规则
      4. 调用原始 res.ok(shapedData)
  → envelope 中间件：包裹统一响应格式，发送给前端
```

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
    filterField: 'timestamp'
  },
  'alert_history': {
    shaping: 'lock',
    minTier: 'standard',
    lockMeta: { upgradeTier: 'standard', message: '告警历史查询需要标准版' }
  }
}
```

### 新增后端文件

```
backend/
├── middleware/
│   └── feature-flag.js          # 新增：后置响应塑造中间件
├── data/
│   ├── feature-flags.js         # 新增：Feature Flag 定义 + shaping 规则
│   └── subscriptions.js         # 新增：订阅状态种子数据
├── routes/
│   └── subscription.js          # 新增：订阅管理 API
└── server.js                    # 修改：注册新路由和中间件
```

### 对现有端点的影响

| 现有端点 | Shaping 行为 |
|---------|-------------|
| `GET /api/map/positions` | 所有层级可用，GPS 定位不受限 |
| `GET /api/map/trajectories` | basic 注入 locked，standard+ 按 `data_retention_days` 过滤 |
| `GET /api/fences` | basic 用户限制最多 3 个围栏 |
| `POST /api/fences` | basic 已有 3 个围栏时返回 locked |
| `GET /api/twin/fever/*` | 所有层级可用（temperature_monitor 在 basic 开放） |
| `GET /api/twin/digestive/*` | 所有层级可用（peristaltic_monitor 在 basic 开放） |
| `GET /api/twin/estrus/*` | basic/standard 注入 locked，premium+ 正常 |
| `GET /api/twin/epidemic/*` | basic/standard 注入 locked，premium+ 正常 |
| `GET /api/alerts` | basic 按 7 天截断，standard 30 天 |
| `GET /api/dashboard/summary` | basic 隐藏高级指标，standard+ 完整 |
| `GET /api/devices` | 所有层级可用 |
| `GET /api/profile` | 所有层级可用 |
| `GET /api/tenants/*` | 所有层级可用（ops 角色权限控制） |

### 订阅管理 API

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/subscription/current` | GET | 获取当前订阅状态（层级、到期时间、实际月费） |
| `/api/subscription/features` | GET | 获取当前层级的功能清单 + 限制配置 |
| `/api/subscription/plans` | GET | 获取全部可选套餐列表（供升级页展示） |
| `/api/subscription/checkout` | POST | Mock 支付：选择套餐 → 立即生效 |
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
  child: <原有功能 Widget>,
)
```

行为：功能 Widget 正常渲染，覆盖半透明遮罩 + 锁图标 + "升级到 X 版解锁"按钮。点击按钮导航到 `/subscription`。

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

### 路由新增与守卫

```dart
subscription,    // /subscription — 套餐选择/升级页
checkout,        // /subscription/checkout — Mock 支付页
```

路由守卫规则：
- 仅 `owner` 角色可访问 `/subscription` 和 `/subscription/checkout`
- `worker` 访问时重定向到 `/mine`（"我的"页面不显示订阅入口）
- `ops` 角色无订阅相关入口
- 两个路由放在 `ShellRoute` 外部（不显示底部导航），独立全屏页面

入口：`features/mine/presentation/` 的"我的"页面中嵌入 `SubscriptionStatusCard`，点击跳转。

### ApiCache 集成

新增预加载端点（加入 `ApiCache.init()` 列表）：
- `GET /api/subscription/current` — 当前订阅状态
- `GET /api/subscription/features` — 功能清单 + locked 状态

缓存失效策略：Mock 支付成功（checkout）后，调用 `ApiCache.instance.init()` 完全重新初始化缓存。这确保所有端点数据根据新订阅层级重新加载（locked 状态解除、数据过滤范围变化等）。

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

`idempotencyKey`：前端生成的 UUID，防止双击重复提交。服务端记忆最近一个 key，相同 key 返回上一次结果。

### 升级/降级处理

| 操作 | Mock Server 行为 |
|------|-----------------|
| 升级 | 立即生效 |
| 降级 | 立即生效（MVP 简化） |
| 取消 | 标记 cancelled，当前周期内仍可用 |

## 测试策略

### 后端测试

新增文件：`feature-flag.test.js`、`response-shaping.test.js`、`subscription-api.test.js`、`tier-access-integration.test.js`

核心场景：
- basic 用户访问 `/api/twin/estrus` → locked: true
- basic 用户访问 `/api/twin/fever` → 正常返回
- basic 用户创建第 4 个围栏 → locked
- basic 用户告警数据按 7 天截断
- 升级后功能解锁

### 前端测试

新增文件：`subscription_tier_test.dart`、`locked_overlay_test.dart`、`subscription_controller_test.dart`、`tier_visibility_test.dart`、`subscription_checkout_flow_test.dart`

核心场景：
- LockedOverlay locked=true 显示遮罩 + 升级按钮
- LockedOverlay locked=false 正常渲染
- basic 用户孪生页面：发热/消化正常，发情/疫病有锁
- Mock 支付成功后 Controller 状态更新
- 升级后 ApiCache 刷新，locked 状态解除
