# SaaS 订阅服务实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为智慧畜牧系统新增四层 SaaS 订阅（基础/标准/高级/企业）+ Mock 支付 + 试用/续费/取消完整流程，通过后端响应塑造（Response Shaping）实现零侵入的功能权限控制。

**Architecture:** 后端新增 shaping 中间件包装 `res.ok()`，在响应序列化前按订阅层级注入 `locked`/`limit`/`filter`；前端新增 LockedOverlay 统一组件 + SubscriptionController 管理订阅状态；Mock 模式下通过共享 `applyMockShaping()` 函数模拟后端 shaping 规则。

**Tech Stack:** Flutter 3.x, flutter_riverpod, go_router, Node.js + Express 5

**被实施规格:** `docs/superpowers/specs/2026-04-24-subscription-service-design.md`

---

## Issue 索引

| 优先级 | Issue | 标题 |
|--------|-------|------|
| P1 | 待创建 | SaaS 订阅服务：后端 shaping 中间件 + 订阅 API |
| P1 | 待创建 | SaaS 订阅服务：前端模型 + LockedOverlay + 订阅管理页 |
| P1 | 待创建 | SaaS 订阅服务：集成 shapings → 现有路由 + 前端页面适配 |

### 完成记录

| 完成日期 | Issue | PR | 备注 |
|----------|-------|-----|------|
| | | | |

---

## 范围界定（Scope）

**本计划覆盖:**
- 后端：feature-flag 配置文件 + 订阅种子数据 + subscriptionStore
- 后端：shaping 中间件（包装 res.ok，支持 filter/limit/lock/none 四种策略 + 多 key 管道）
- 后端：订阅管理 API 7 个端点（current/features/plans/checkout/cancel/renew/usage）
- 后端：到期自动降级检测（每次请求时在 shaping 中间件中判断）
- 后端：将 shaping 注册到所有受影响现有路由（map/fences/alerts/dashboard/twin）
- 后端：新租户自动创建 14 天试用订阅
- 后端：幂等性 key 防护（内存 Map + 5 分钟 TTL）
- 前端：`SubscriptionTier` 枚举 + Feature 定义模型 + `SubscriptionStatus` 模型
- 前端：`LockedOverlay` 统一组件（锁遮罩 + 升级按钮）
- 前端：`SubscriptionController`（Riverpod Notifier）
- 前端：`SubscriptionStatusCard`（"我的"页面内嵌卡片）
- 前端：`SubscriptionPlanPage`（套餐选择/升级页）
- 前端：`SubscriptionCheckoutPage`（Mock 支付确认页）
- 前端：`TierCard`、`FeatureComparisonTable`、`UsageProgressBar` 组件
- 前端：`SubscriptionRenewalBanner`（孪生总览页到期提醒横幅）
- 前端：到期提醒登录弹窗（daysUntilExpiry ≤ 7 时弹出）
- 前端：`AppRoute` 新增 `subscription` / `checkout` + `GoRouter` 注册
- 前端：`ApiCache` 新增预加载 `subscription/current` + `subscription/features`
- 前端：`MinePage` 嵌入 `SubscriptionStatusCard`
- 前端：孪生/地图/告警/围栏页面适配 LockedOverlay
- 前端：Mock 模式 `applyMockShaping()` 兼容（共享函数模拟后端规则）
- 测试：后端 unit + integration 测试全覆盖
- 测试：前端 unit + widget + flow 测试全覆盖

**本计划不覆盖:**
- 真实支付集成（Mock 模拟 500ms 延迟）
- 后端真实数据库持久化（内存存储）
- 企业版真实销售流程（仅展示"联系销售"入口 + `url_launcher` mailto 链接）
- MQTT/实时通信（不在当前阶段）
- worker 角色的订阅切换入口（worker 无底部"后台"导航，订阅状态卡片仍展示但无管理入口）
- 以下 Feature Flags 已定义但未关联路由，预留未来功能使用：`health_score`、`gait_analysis`、`behavior_stats`、`api_access`、`dedicated_support`

---

## 文件结构

### 后端 — 新建

| 文件 | 职责 |
|------|------|
| `backend/data/feature-flags.js` | Feature Flag 定义 Map + `applyShapingRules()` 管道函数 |
| `backend/data/subscriptions.js` | 订阅种子数据 + `subscriptionStore`（createTrial/getByTenantId/checkout/cancel/renew/updateLivestockCount）+ 幂等性 key 存储 |
| `backend/middleware/feature-flag.js` | 响应塑造中间件（包装 res.ok + 到期检测 + 调用 applyShapingRules） |
| `backend/routes/subscription.js` | 订阅管理 API 7 个端点 |
| `backend/test/feature-flags.test.js` | Feature Flag 定义测试 |
| `backend/test/response-shaping.test.js` | 响应塑造中间件单元测试（含到期检测） |
| `backend/test/subscription-api.test.js` | 订阅管理 API 集成测试 |
| `backend/test/tier-access-integration.test.js` | 端到端层级访问测试 |

### 后端 — 修改

| 文件 | 变更 |
|------|------|
| `backend/data/seed.js` | 无修改（订阅数据独立于 `data/subscriptions.js`） |
| `backend/routes/tenants.js` | POST handler 串行调用 `subscriptionStore.createTrial()` |
| `backend/routes/map.js` | 新增 feature keys 中间件 + shaping 中间件注册 |
| `backend/routes/fences.js` | 新增 feature keys 中间件 + shaping 中间件注册（含 POST 数量检查） |
| `backend/routes/alerts.js` | 新增 feature keys 中间件 + shaping 中间件注册（多 key: data_retention_days + alert_history） |
| `backend/routes/dashboard.js` | 新增 feature keys 中间件 + shaping 中间件注册 |
| `backend/routes/twin.js` | 新增 feature keys 中间件 + shaping 中间件注册（仅 estrus/epidemic 端点 lock） |
| `backend/routes/registerApiRoutes.js` | 注册 subscription 路由 |
| `backend/middleware/auth.js` | 确认 `req.user.tenantId` 可用（当前已有，无需修改） |

### 前端 — 新建

| 文件 | 职责 |
|------|------|
| `lib/core/models/subscription_tier.dart` | `SubscriptionTier` 枚举 + Feature Flag 定义 + `SubscriptionStatus` 模型 |
| `lib/widgets/locked_overlay.dart` | 通用锁定遮罩组件（跨模块共享） |
| `lib/features/subscription/domain/subscription_repository.dart` | Repository 接口（同步，遵循现有模式） |
| `lib/features/subscription/data/mock_subscription_repository.dart` | Mock 实现 + `applyMockShaping()` 共享函数 |
| `lib/features/subscription/data/live_subscription_repository.dart` | Live 实现（从 ApiCache 读取） |
| `lib/features/subscription/presentation/subscription_controller.dart` | Riverpod Notifier（管理当前订阅状态 + checkout 操作） |
| `lib/features/subscription/presentation/subscription_status_card.dart` | "我的"页面内嵌订阅状态卡片 |
| `lib/features/subscription/presentation/subscription_plan_page.dart` | 套餐选择/升级/管理页（全屏，无底部导航） |
| `lib/features/subscription/presentation/subscription_checkout_page.dart` | Mock 支付确认页 |
| `lib/features/subscription/presentation/widgets/tier_card.dart` | 单个套餐卡片组件 |
| `lib/features/subscription/presentation/widgets/feature_comparison_table.dart` | 功能对比表组件 |
| `lib/features/subscription/presentation/widgets/usage_progress_bar.dart` | 用量进度条组件 |
| `lib/features/subscription/presentation/widgets/subscription_renewal_banner.dart` | 到期提醒横幅（孪生总览页顶部） |
| `lib/features/subscription/presentation/widgets/subscription_expiry_dialog.dart` | 到期提醒登录弹窗 |
| `test/core/subscription_tier_test.dart` | Tier 枚举 + 价格计算 + 功能配置测试 |
| `test/widgets/locked_overlay_test.dart` | LockedOverlay 组件测试 |
| `test/features/subscription/subscription_controller_test.dart` | SubscriptionController 测试 |
| `test/features/subscription/subscription_checkout_flow_test.dart` | 支付流程端到端测试 |
| `test/features/subscription/subscription_cancel_flow_test.dart` | 取消订阅流程测试 |
| `test/features/subscription/subscription_renewal_reminder_test.dart` | 到期提醒测试 |
| `test/features/subscription/tier_visibility_test.dart` | 层级可见性集成测试 |

### 前端 — 修改

| 文件 | 变更 |
|------|------|
| `lib/app/app_route.dart` | 新增 `subscription`、`checkout` 两个枚举值 |
| `lib/app/app_router.dart` | ShellRoute 外部注册订阅路由 + redirect 守卫 |
| `lib/core/api/api_cache.dart` | 新增 `_subscriptionStatus`、`_features` 缓存字段 + `init()` 预加载 + checkout/cancel/renew 后重载 |
| `lib/features/mine/presentation/mine_controller.dart` | `MineViewData` 新增 `subscriptionStatus` 字段 |
| `lib/features/pages/mine_page.dart` | 在"我的"页面嵌入 `SubscriptionStatusCard` |
| `lib/features/pages/twin_overview_page.dart` | 添加 `SubscriptionRenewalBanner` + 登录弹窗检查 |
| `lib/features/pages/fence_page.dart` | 围栏列表限 3 个时新建按钮 disabled + 提示 |
| `lib/features/pages/alerts_page.dart` | 告警 Tab 中历史 tab 显示锁图标 |
| `lib/core/data/demo_seed.dart` | 新增订阅假数据（align 后端 seed） |

---

## 前置条件与约定

1. **Shaping 执行顺序**: `filter` → `limit` → `lock`（先裁剪数据，再注入限制元数据，最后判断锁定）。`none` 策略跳过。
2. **中间件注册顺序**: `envelopeMiddleware`（全局）→ `authMiddleware`（路由级）→ `featureKeys 中间件`（路由级）→ `shapingMiddleware`（路由级）。shaping 按需在每个路由模块的 auth 之后注册。
3. **订阅路由不注册 shaping**: `/api/subscription/*` 仅注册 `authMiddleware`，否则 `/api/subscription/current` 自身会被 shaping 拦截。
4. **ops 绕过**: ops 用户 `tenantId` 为 `null`，shaping 中间件检测后直接透传，不执行任何 shaping 规则。
5. **到期自动降级**: 每次请求时在 shaping 中间件中检测 `trialEndsAt` 和 `currentPeriodEnd`，到期后自动将 status 改为 'expired'、tier 改为 'basic'。
6. **Mock 模式兼容**: `applyMockShaping()` 共享函数在 `MockSubscriptionRepository` 中导出，各 `MockXxxRepository` 在返回数据前调用。
7. **价格单位**: 后端存储和计算全部用"分"（int），前端展示时除以 100 转为元。
8. **降级后数据**: lock 类功能已缓存数据保持可见（前端不清除），新 API 请求响应注入 `locked: true`；filter 类数据按基础版规则截断；limit 类资源已有数据保留，禁新建。
9. **提交频次**: 每个 Task 结束后 `git commit`。
10. **测试模式**: ProviderContainer 隔离，不依赖真实后端。Mock Server 测试用 `node:test` + `node:assert/strict`。

---

## Task 1：Feature Flag 配置文件

**Files:**
- Create: `backend/data/feature-flags.js`
- Create: `backend/test/feature-flags.test.js`

### 目标

新增 Feature Flag 定义 Map + `applyShapingRules()` 管道函数，作为 shaping 中间件的数据源。

### 实施步骤

- [ ] **Step 1: 写测试 `backend/test/feature-flags.test.js`**

```javascript
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');
const { featureFlags, applyShapingRules } = require('../data/feature-flags');

describe('featureFlags config', () => {
  it('所有 Feature Flag 都定义了 key 和 category', () => {
    for (const [key, flag] of featureFlags) {
      assert.equal(flag.featureKey, key);
      assert.ok(['location', 'health', 'analytics', 'service', 'management'].includes(flag.category));
    }
  });

  it('lock 策略的 flag 有 minTier 和 lockMeta', () => {
    const lockFlags = [...featureFlags.values()].filter(f => f.shaping === 'lock');
    for (const flag of lockFlags) {
      assert.ok(flag.minTier);
      assert.ok(flag.lockMeta);
      assert.ok(flag.lockMeta.upgradeTier);
      assert.ok(flag.lockMeta.message);
    }
  });

  it('limit 策略的 flag 有 rulesByTier', () => {
    const limitFlags = [...featureFlags.values()].filter(f => f.shaping === 'limit');
    for (const flag of limitFlags) {
      assert.ok(flag.rulesByTier);
    }
  });

  it('filter 策略的 flag 有 rulesByTier', () => {
    const filterFlags = [...featureFlags.values()].filter(f => f.shaping === 'filter');
    for (const flag of filterFlags) {
      assert.ok(flag.rulesByTier);
    }
  });
});

describe('applyShapingRules', () => {
  it('basic 用户访问 estrus_detect → locked: true', () => {
    const data = { items: [{ id: '1', name: 'test' }], total: 1 };
    const result = applyShapingRules(data, 'basic', ['estrus_detect']);
    assert.equal(result.locked, true);
    assert.equal(result.upgradeTier, 'premium');
  });

  it('premium 用户访问 estrus_detect → 无 locked', () => {
    const data = { items: [{ id: '1', name: 'test' }], total: 1 };
    const result = applyShapingRules(data, 'premium', ['estrus_detect']);
    assert.equal(result.locked, undefined);
  });

  it('basic 用户访问 fence → limit 注入', () => {
    const data = { items: [{ id: 'f1' }, { id: 'f2' }, { id: 'f3' }], total: 3 };
    const result = applyShapingRules(data, 'basic', ['fence']);
    assert.ok(result.limit);
    assert.equal(result.limit.maxCount, 3);
  });

  it('basic 用户 alerts 数据按 7 天截断 (data_retention_days)', () => {
    const now = new Date();
    const oldDate = new Date(now.getTime() - 10 * 86400000).toISOString();
    const recentDate = new Date(now.getTime() - 2 * 86400000).toISOString();
    const data = {
      items: [
        { id: 'a1', occurredAt: oldDate },
        { id: 'a2', occurredAt: recentDate },
      ],
      total: 2,
    };
    const result = applyShapingRules(data, 'basic', ['data_retention_days'], { filterField: 'occurredAt' });
    assert.equal(result.items.length, 1);
    assert.equal(result.items[0].id, 'a2');
  });

  it('多 key 叠加：alerts data_retention_days filter + alert_history lock 同时生效', () => {
    const now = new Date();
    const oldDate = new Date(now.getTime() - 10 * 86400000).toISOString();
    const data = {
      items: [{ id: 'a1', occurredAt: oldDate }],
      total: 1,
    };
    const result = applyShapingRules(data, 'basic', ['data_retention_days', 'alert_history'], { filterField: 'occurredAt' });
    // filter 先执行：items 被清空
    assert.equal(result.items.length, 0);
    // lock 后执行：注入 locked
    assert.equal(result.locked, true);
  });

  it('管道执行顺序：filter → limit → lock', () => {
    const data = { items: [{ id: 'x' }], total: 1, limit: null };
    // 构造多 key 场景确保顺序
    const result = applyShapingRules(data, 'basic', ['data_retention_days', 'alert_history'], { filterField: 'occurredAt' });
    // filter 先裁剪，lock 后注入
    assert.equal(result.locked, true);
  });

  it('none 策略跳过所有处理', () => {
    const data = { items: [{ id: 'g1' }], total: 1 };
    const result = applyShapingRules(data, 'basic', ['gps_location']);
    assert.deepEqual(result, data);
  });

  it('enterprise 用户所有功能可用', () => {
    const data = { items: [{ id: '1' }], total: 1 };
    for (const key of featureFlags.keys()) {
      const result = applyShapingRules(data, 'enterprise', [key], { filterField: 'occurredAt' });
      // enterprise 不应有 locked
      assert.equal(result.locked, undefined);
    }
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/backend && node --test test/feature-flags.test.js
```

Expected: FAIL（模块不存在）。

- [ ] **Step 3: 实现 `backend/data/feature-flags.js`**

```javascript
/**
 * Feature Flag 定义 Map
 * key: featureKey (string) → ShapingRule
 */
const featureFlags = new Map();

const TIER_ORDER = ['basic', 'standard', 'premium', 'enterprise'];

function tierIndex(tier) {
  return TIER_ORDER.indexOf(tier);
}

function tierGte(tier, minTier) {
  if (!minTier) return true;
  return tierIndex(tier) >= tierIndex(minTier);
}

// ===== Location =====
featureFlags.set('gps_location', {
  featureKey: 'gps_location',
  category: 'location',
  shaping: 'none',
});

featureFlags.set('fence', {
  featureKey: 'fence',
  category: 'location',
  shaping: 'limit',
  rulesByTier: {
    basic: { maxCount: 3, onExceed: 'lock_new', message: '基础版最多 3 个围栏，升级标准版解锁更多' },
  },
});

featureFlags.set('trajectory', {
  featureKey: 'trajectory',
  category: 'location',
  shaping: 'lock',
  minTier: 'standard',
  lockMeta: { upgradeTier: 'standard', message: '历史轨迹需要标准版及以上' },
});

// ===== Health =====
featureFlags.set('temperature_monitor', {
  featureKey: 'temperature_monitor',
  category: 'health',
  shaping: 'none',
});

featureFlags.set('peristaltic_monitor', {
  featureKey: 'peristaltic_monitor',
  category: 'health',
  shaping: 'none',
});

featureFlags.set('health_score', {
  featureKey: 'health_score',
  category: 'health',
  shaping: 'lock',
  minTier: 'premium',
  lockMeta: { upgradeTier: 'premium', message: '健康评分需要高级版及以上' },
});

featureFlags.set('estrus_detect', {
  featureKey: 'estrus_detect',
  category: 'health',
  shaping: 'lock',
  minTier: 'premium',
  lockMeta: { upgradeTier: 'premium', message: '发情检测需要高级版及以上' },
});

featureFlags.set('epidemic_alert', {
  featureKey: 'epidemic_alert',
  category: 'health',
  shaping: 'lock',
  minTier: 'premium',
  lockMeta: { upgradeTier: 'premium', message: '疫病预警需要高级版及以上' },
});

// ===== Analytics =====
featureFlags.set('gait_analysis', {
  featureKey: 'gait_analysis',
  category: 'analytics',
  shaping: 'lock',
  minTier: 'enterprise',
  lockMeta: { upgradeTier: 'enterprise', message: '步态分析需要企业版' },
});

featureFlags.set('behavior_stats', {
  featureKey: 'behavior_stats',
  category: 'analytics',
  shaping: 'lock',
  minTier: 'enterprise',
  lockMeta: { upgradeTier: 'enterprise', message: '行为统计需要企业版' },
});

featureFlags.set('api_access', {
  featureKey: 'api_access',
  category: 'analytics',
  shaping: 'lock',
  minTier: 'enterprise',
  lockMeta: { upgradeTier: 'enterprise', message: 'API 访问需要企业版' },
});

// ===== Service =====
featureFlags.set('data_retention_days', {
  featureKey: 'data_retention_days',
  category: 'service',
  shaping: 'filter',
  rulesByTier: { basic: 7, standard: 30, premium: 365, enterprise: null },
});

featureFlags.set('alert_history', {
  featureKey: 'alert_history',
  category: 'service',
  shaping: 'lock',
  minTier: 'standard',
  lockMeta: { upgradeTier: 'standard', message: '告警历史查询需要标准版及以上' },
});

featureFlags.set('dedicated_support', {
  featureKey: 'dedicated_support',
  category: 'service',
  shaping: 'lock',
  minTier: 'premium',
  lockMeta: { upgradeTier: 'premium', message: '专属客服支持需要高级版及以上' },
});

// ===== Management =====
featureFlags.set('device_management', {
  featureKey: 'device_management',
  category: 'management',
  shaping: 'none',
});

featureFlags.set('livestock_detail', {
  featureKey: 'livestock_detail',
  category: 'management',
  shaping: 'none',
});

featureFlags.set('stats', {
  featureKey: 'stats',
  category: 'analytics',
  shaping: 'none',
});

featureFlags.set('dashboard_summary', {
  featureKey: 'dashboard_summary',
  category: 'analytics',
  shaping: 'limit',
  rulesByTier: {
    basic: {
      visibleMetrics: ['livestockCount', 'deviceOnlineRate', 'todayAlerts'],
      onExceed: 'hide_metrics',
      message: '升级标准版解锁健康评分、行为统计等高级指标',
    },
  },
});

featureFlags.set('profile', {
  featureKey: 'profile',
  category: 'management',
  shaping: 'none',
});

featureFlags.set('tenant_admin', {
  featureKey: 'tenant_admin',
  category: 'management',
  shaping: 'none',
});

// ===== Shaping Pipeline =====

function applyFilterRule(data, days) {
  if (!days) return data; // null = unlimited
  const cutoff = new Date();
  cutoff.setDate(cutoff.getDate() - days);
  if (data.items && Array.isArray(data.items)) {
    const filtered = data.items.filter(item => {
      // Try multiple common timestamp fields
      const ts = item.occurredAt || item.recordedAt || item.timestamp || item.createdAt;
      if (!ts) return true;
      return new Date(ts) >= cutoff;
    });
    return { ...data, items: filtered, total: filtered.length };
  }
  return data;
}

function applyLimitRule(data, rule) {
  if (!rule) return data;
  const result = { ...data, limit: { maxCount: rule.maxCount, locked: false, message: rule.message } };
  if (data.total >= rule.maxCount && rule.onExceed === 'lock_new') {
    result.limit.locked = true;
  }
  return result;
}

function applyDashboardLimit(data, rule) {
  if (!rule || !rule.visibleMetrics) return data;
  if (data.metrics && Array.isArray(data.metrics)) {
    const filtered = data.metrics.filter(m => rule.visibleMetrics.includes(m.key));
    return { ...data, metrics: filtered, limit: { locked: false, message: rule.message } };
  }
  return data;
}

function applyLockRule(data, flag) {
  if (flag.lockMeta) {
    return {
      ...data,
      locked: true,
      upgradeTier: flag.lockMeta.upgradeTier,
      message: flag.lockMeta.message,
      items: [],
      total: 0,
    };
  }
  return data;
}

/**
 * Apply shaping rules for multiple feature keys in order: filter → limit → lock
 * @param {object} data - Response data
 * @param {string} tier - Current subscription tier
 * @param {string[]} featureKeys - Route feature keys
 * @param {object} [options] - { filterField: string }
 * @returns {object} Shaped data
 */
function applyShapingRules(data, tier, featureKeys, options = {}) {
  if (!featureKeys || featureKeys.length === 0) return data;
  if (tier === 'enterprise') return data; // enterprise 无限制

  let result = { ...data };

  // Phase 1: filter
  for (const key of featureKeys) {
    const flag = featureFlags.get(key);
    if (!flag || flag.shaping !== 'filter') continue;
    const days = flag.rulesByTier?.[tier];
    if (days || days === 0) {
      result = applyFilterRule(result, days);
    }
  }

  // Phase 2: limit
  for (const key of featureKeys) {
    const flag = featureFlags.get(key);
    if (!flag || flag.shaping !== 'limit') continue;
    const rule = flag.rulesByTier?.[tier];
    if (rule) {
      if (key === 'dashboard_summary') {
        result = applyDashboardLimit(result, rule);
      } else {
        result = applyLimitRule(result, rule);
      }
    }
  }

  // Phase 3: lock
  for (const key of featureKeys) {
    const flag = featureFlags.get(key);
    if (!flag || flag.shaping !== 'lock') continue;
    if (!tierGte(tier, flag.minTier)) {
      result = applyLockRule(result, flag);
    }
  }

  return result;
}

module.exports = { featureFlags, applyShapingRules, tierIndex, tierGte };
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/backend && node --test test/feature-flags.test.js
```

Expected: PASS（全部测试通过）。

- [ ] **Step 5: 提交**

```bash
git add backend/data/feature-flags.js backend/test/feature-flags.test.js
git commit -m "feat(subscription): add feature flag definitions and shaping rules pipeline"
```

---

## Task 2：订阅种子数据 + SubscriptionStore

**Files:**
- Create: `backend/data/subscriptions.js`

### 目标

新增订阅状态种子数据（6 个现有租户均为基础版）和 `subscriptionStore`（CRUD + 幂等性防护）。

### 实施步骤

- [ ] **Step 1: 实现 `backend/data/subscriptions.js`**

```javascript
/**
 * Subscription Store — 内存 Map，对齐 seed.js 的 6 个租户
 */
const subscriptions = new Map();

// Seed: 现有 6 个租户均为基础版
const defaultSubscriptions = [
  { tenantId: 'tenant_001', tier: 'basic', status: 'active', livestockCount: 50 },
  { tenantId: 'tenant_002', tier: 'basic', status: 'active', livestockCount: 120 },
  { tenantId: 'tenant_003', tier: 'basic', status: 'active', livestockCount: 180 },
  { tenantId: 'tenant_004', tier: 'basic', status: 'active', livestockCount: 30 },
  { tenantId: 'tenant_005', tier: 'basic', status: 'active', livestockCount: 95 },
  { tenantId: 'tenant_006', tier: 'basic', status: 'active', livestockCount: 75 },
];

function initSubscriptions() {
  subscriptions.clear();
  const now = new Date();
  const periodEnd = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  const periodStart = new Date(now.getFullYear(), now.getMonth(), 1);

  for (const sub of defaultSubscriptions) {
    subscriptions.set(sub.tenantId, {
      tenantId: sub.tenantId,
      tier: sub.tier,
      currentPeriodStart: periodStart.toISOString().split('T')[0],
      currentPeriodEnd: periodEnd.toISOString().split('T')[0],
      status: sub.status,
      livestockCount: sub.livestockCount,
      calculatedPrice: 0,
      trialEndsAt: null,
    });
  }
}

// Tier definitions (prices in 分)
const TIERS = {
  basic: {
    id: 'basic',
    name: '基础版',
    monthlyPrice: 0,
    includedLivestock: 50,
    perUnitPrice: null,
    perUnitSize: null,
  },
  standard: {
    id: 'standard',
    name: '标准版',
    monthlyPrice: 29900,
    includedLivestock: 200,
    perUnitPrice: 50,
    perUnitSize: 50,
  },
  premium: {
    id: 'premium',
    name: '高级版',
    monthlyPrice: 69900,
    includedLivestock: 1000,
    perUnitPrice: 80,
    perUnitSize: 100,
  },
  enterprise: {
    id: 'enterprise',
    name: '企业版',
    monthlyPrice: null,
    includedLivestock: -1,
    perUnitPrice: null,
    perUnitSize: null,
  },
};

function calculatePrice(tierId, livestockCount) {
  const tier = TIERS[tierId];
  if (!tier || tier.monthlyPrice === null) return null; // enterprise
  if (tier.includedLivestock === -1) return null; // unlimited
  let price = tier.monthlyPrice;
  if (livestockCount > tier.includedLivestock && tier.perUnitPrice && tier.perUnitSize) {
    const extra = livestockCount - tier.includedLivestock;
    const units = Math.ceil(extra / tier.perUnitSize);
    price += units * tier.perUnitPrice;
  }
  return price;
}

function createTrial(tenantId) {
  const now = new Date();
  const trialEnd = new Date(now.getTime() + 14 * 24 * 60 * 60 * 1000);
  const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const sub = {
    tenantId,
    tier: 'premium',
    currentPeriodStart: now.toISOString().split('T')[0],
    currentPeriodEnd: periodEnd.toISOString().split('T')[0],
    status: 'trial',
    livestockCount: 0,
    calculatedPrice: 0,
    trialEndsAt: trialEnd.toISOString().split('T')[0],
  };
  subscriptions.set(tenantId, sub);
  return { ...sub };
}

function getByTenantId(tenantId) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return null;
  const result = { ...sub };

  // Calculate daysUntilExpiry
  if (sub.status === 'expired') {
    result.daysUntilExpiry = 0;
  } else {
    const endDate = sub.status === 'trial' ? sub.trialEndsAt : sub.currentPeriodEnd;
    if (endDate) {
      const now = new Date();
      const end = new Date(endDate);
      const diff = Math.ceil((end.getTime() - now.getTime()) / (1000 * 60 * 60 * 24));
      result.daysUntilExpiry = Math.max(0, diff);
    }
  }

  // Calculate current price
  result.calculatedPrice = calculatePrice(sub.tier, sub.livestockCount) ?? 0;

  return result;
}

function checkout(tenantId, tierId, livestockCount) {
  const now = new Date();
  const periodEnd = new Date(now.getTime() + 30 * 24 * 60 * 60 * 1000);
  const price = calculatePrice(tierId, livestockCount);
  const sub = {
    tenantId,
    tier: tierId,
    currentPeriodStart: now.toISOString().split('T')[0],
    currentPeriodEnd: periodEnd.toISOString().split('T')[0],
    status: 'active',
    livestockCount,
    calculatedPrice: price ?? 0,
    trialEndsAt: null,
  };
  subscriptions.set(tenantId, sub);
  return { ...sub };
}

function cancel(tenantId) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return null;
  if (sub.status === 'trial') {
    // 试用取消立即生效，直接降级为基础版
    sub.status = 'expired';
    sub.tier = 'basic';
    sub.calculatedPrice = 0;
    sub.trialEndsAt = null;
  } else {
    sub.status = 'cancelled';
  }
  return { ...sub };
}

function renew(tenantId) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return null;
  const currentEnd = new Date(sub.currentPeriodEnd);
  currentEnd.setDate(currentEnd.getDate() + 30);
  sub.currentPeriodEnd = currentEnd.toISOString().split('T')[0];
  sub.status = 'active';
  if (sub.trialEndsAt) sub.trialEndsAt = null;
  return { ...sub };
}

function updateLivestockCount(tenantId, count) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return;
  sub.livestockCount = count;
  sub.calculatedPrice = calculatePrice(sub.tier, count) ?? 0;
}

function getUsage(tenantId, options = {}) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return null;
  const tier = TIERS[sub.tier];
  return {
    tenantId,
    tier: sub.tier,
    livestock: {
      used: sub.livestockCount,
      limit: tier.includedLivestock === -1 ? null : tier.includedLivestock,
      isUnlimited: tier.includedLivestock === -1,
    },
    fences: {
      used: options.fenceCount ?? 0,
      limit: sub.tier === 'basic' ? 3 : null,
      isUnlimited: sub.tier !== 'basic',
    },
    dataUsage: {
      retentionDays: sub.tier === 'basic' ? 7 : sub.tier === 'standard' ? 30 : sub.tier === 'premium' ? 365 : null,
      isUnlimited: sub.tier === 'enterprise',
    },
  };
}

// Idempotency key storage (5 min TTL)
const idempotencyStore = new Map();

function getIdempotencyResult(key) {
  const entry = idempotencyStore.get(key);
  if (!entry) return null;
  if (Date.now() - entry.timestamp > 5 * 60 * 1000) {
    idempotencyStore.delete(key);
    return null;
  }
  return entry.result;
}

function setIdempotencyResult(key, result) {
  idempotencyStore.set(key, { result, timestamp: Date.now() });
}

// Periodic cleanup
setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of idempotencyStore) {
    if (now - entry.timestamp > 5 * 60 * 1000) {
      idempotencyStore.delete(key);
    }
  }
}, 60 * 1000);

// Reset for tests
function reset() {
  idempotencyStore.clear();
  initSubscriptions();
}

initSubscriptions();

module.exports = {
  subscriptions,
  TIERS,
  calculatePrice,
  createTrial,
  getByTenantId,
  checkout,
  cancel,
  renew,
  updateLivestockCount,
  getUsage,
  getIdempotencyResult,
  setIdempotencyResult,
  reset,
};
```

- [ ] **Step 2: 运行 quick verification**

```bash
cd Mobile/backend && node -e "const s = require('./data/subscriptions'); console.log(s.getByTenantId('tenant_001'));"
```

Expected: 输出 tenant_001 的订阅状态（basic, active）。

- [ ] **Step 3: 提交**

```bash
git add backend/data/subscriptions.js
git commit -m "feat(subscription): add subscription store with seed data and idempotency support"
```

---

## Task 3：Shaping 中间件

**Files:**
- Create: `backend/middleware/feature-flag.js`
- Create: `backend/test/response-shaping.test.js`

### 目标

实现 shaping 中间件（包装 `res.ok` → 到期检测 → 调用 `applyShapingRules`），覆盖到期自动降级 + 多 key 管道 + ops 绕过。

### 实施步骤

- [ ] **Step 1: 写测试 `backend/test/response-shaping.test.js`**

```javascript
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const http = require('http');
const { envelopeMiddleware } = require('../middleware/envelope');
const { authMiddleware } = require('../middleware/auth');
const { shapingMiddleware } = require('../middleware/feature-flag');
const { reset } = require('../data/subscriptions');

function makeRequest(app, path, token) {
  return new Promise((resolve, reject) => {
    const server = http.createServer(app);
    server.listen(0, () => {
      const port = server.address().port;
      const req = http.request({
        hostname: 'localhost',
        port,
        path,
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      }, (res) => {
        let body = '';
        res.on('data', d => body += d);
        res.on('end', () => {
          server.close();
          resolve({ status: res.statusCode, body: JSON.parse(body) });
        });
      });
      req.on('error', reject);
      req.end();
    });
  });
}

describe('shapingMiddleware', () => {
  before(() => reset());

  it('basic 用户访问 estrus → locked: true', async () => {
    const app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    app.use('/api/twin', authMiddleware);
    app.use('/api/twin', (req, res, next) => {
      req.routeFeatureKeys = ['estrus_detect'];
      next();
    });
    app.use('/api/twin', shapingMiddleware);
    app.get('/api/twin/estrus/list', (req, res) => {
      res.ok({ items: [{ id: 'e1', livestockId: 'cow_001' }], total: 1 });
    });

    const { body } = await makeRequest(app, '/api/twin/estrus/list', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.locked, true);
    assert.equal(body.data.upgradeTier, 'premium');
  });

  it('ops 用户跳过 shaping', async () => {
    const app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    app.use('/api/tenants', authMiddleware);
    app.use('/api/tenants', (req, res, next) => {
      req.routeFeatureKeys = ['estrus_detect'];
      next();
    });
    app.use('/api/tenants', shapingMiddleware);
    app.get('/api/tenants', (req, res) => {
      res.ok({ items: [{ id: 't1' }], total: 1 });
    });

    const { body } = await makeRequest(app, '/api/tenants', 'mock-token-ops');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.locked, undefined);
  });

  it('basic 用户访问 fever（temperature_monitor=all tiers）→ 正常返回', async () => {
    const app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    app.use('/api/twin', authMiddleware);
    app.use('/api/twin', (req, res, next) => {
      req.routeFeatureKeys = ['temperature_monitor'];
      next();
    });
    app.use('/api/twin', shapingMiddleware);
    app.get('/api/twin/fever/list', (req, res) => {
      res.ok({ items: [{ id: 'f1' }], total: 1 });
    });

    const { body } = await makeRequest(app, '/api/twin/fever/list', 'mock-token-owner');
    assert.equal(body.data.locked, undefined);
    assert.equal(body.data.items.length, 1);
  });

  it('缺少 routeFeatureKeys 时跳过 shaping', async () => {
    const app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    app.use('/api/test', authMiddleware);
    app.use('/api/test', shapingMiddleware);
    app.get('/api/test', (req, res) => {
      res.ok({ data: 'hello' });
    });

    const { body } = await makeRequest(app, '/api/test', 'mock-token-owner');
    assert.equal(body.data.data, 'hello');
  });

  it('trial 到期自动降级 → locked 注入', async () => {
    const { subscriptions } = require('../data/subscriptions');
    const past = new Date();
    past.setDate(past.getDate() - 20);
    subscriptions.set('tenant_test_expired', {
      tenantId: 'tenant_test_expired',
      tier: 'premium',
      status: 'trial',
      trialEndsAt: past.toISOString().split('T')[0],
      currentPeriodStart: '2026-01-01',
      currentPeriodEnd: '2026-02-01',
      livestockCount: 0,
      calculatedPrice: 0,
    });

    const app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    app.use('/api/twin', authMiddleware);
    app.use('/api/twin', (req, res, next) => {
      req.routeFeatureKeys = ['estrus_detect'];
      next();
    });
    app.use('/api/twin', shapingMiddleware);
    app.get('/api/twin/estrus/list', (req, res) => {
      res.ok({ items: [{ id: 'e1' }], total: 1 });
    });

    // Need a token that maps to tenant_test_expired — use owner token (tenant_001) for this test
    const sub = subscriptions.get('tenant_001');
    const originalStatus = sub.status;
    const originalTier = sub.tier;
    sub.status = 'trial';
    sub.trialEndsAt = past.toISOString().split('T')[0];
    sub.tier = 'premium';

    const { body } = await makeRequest(app, '/api/twin/estrus/list', 'mock-token-owner');
    // After expiry, tier should be basic and estrus should be locked
    assert.equal(body.data.locked, true);

    // Restore
    sub.status = originalStatus;
    sub.tier = originalTier;
    sub.trialEndsAt = null;
  });

  it('多 key 叠加（alerts: filter + lock）', async () => {
    const app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    app.use('/api/alerts', authMiddleware);
    app.use('/api/alerts', (req, res, next) => {
      req.routeFeatureKeys = ['data_retention_days', 'alert_history'];
      next();
    });
    app.use('/api/alerts', shapingMiddleware);

    const now = new Date();
    const oldDate = new Date(now.getTime() - 10 * 86400000).toISOString();
    const recentDate = new Date(now.getTime() - 2 * 86400000).toISOString();

    app.get('/api/alerts', (req, res) => {
      res.ok({
        items: [
          { id: 'a1', occurredAt: oldDate },
          { id: 'a2', occurredAt: recentDate },
        ],
        total: 2,
      });
    });

    const { body } = await makeRequest(app, '/api/alerts', 'mock-token-owner');
    // filter: only recent (≤7 days for basic)
    assert.equal(body.data.items.length, 1);
    assert.equal(body.data.items[0].id, 'a2');
    // lock: alert_history locked for basic
    assert.equal(body.data.locked, true);
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/backend && node --test test/response-shaping.test.js
```

Expected: FAIL（shapingMiddleware 未定义）。

- [ ] **Step 3: 实现 `backend/middleware/feature-flag.js`**

```javascript
const { getByTenantId } = require('../data/subscriptions');
const { applyShapingRules } = require('../data/feature-flags');

/**
 * Response Shaping Middleware
 * 
 * 前置条件：
 *   1. envelopeMiddleware 必须在全局注册（挂载 res.ok / res.fail）
 *   2. authMiddleware 必须在本中间件之前注册（设置 req.user）
 *   3. req.routeFeatureKeys 必须在本中间件之前设置（路由级中间件）
 * 
 * 注册顺序约束：
 *   envelopeMiddleware（全局）→ authMiddleware（路由级）→ featureKeys（路由级）→ shapingMiddleware（路由级）
 */
function shapingMiddleware(req, res, next) {
  // ops 跳过（tenantId 为 null）
  if (req.user == null || req.user.tenantId == null) {
    return next();
  }

  const originalOk = res.ok.bind(res);

  res.ok = (data, message) => {
    const tenantId = req.user.tenantId;

    // Check for expiry and auto-downgrade
    let sub = getByTenantId(tenantId);
    if (sub) {
      const now = new Date();
      const needDowngrade =
        (sub.status === 'trial' && sub.trialEndsAt && now > new Date(sub.trialEndsAt)) ||
        ((sub.status === 'active' || sub.status === 'cancelled') && now > new Date(sub.currentPeriodEnd));

      if (needDowngrade) {
        const { subscriptions } = require('../data/subscriptions');
        const raw = subscriptions.get(tenantId);
        if (raw) {
          raw.tier = 'basic';
          raw.status = 'expired';
          raw.calculatedPrice = 0;
          raw.trialEndsAt = null;
        }
      }
    }

    // 降级后需重新读取更新后的 tier
    sub = getByTenantId(tenantId);
    const tier = sub ? sub.tier : 'basic';
    const featureKeys = req.routeFeatureKeys || [];

    if (featureKeys.length === 0) {
      return originalOk(data, message);
    }

    const shaped = applyShapingRules(data, tier, featureKeys, {
      filterField: req.query?.filterField,
    });

    return originalOk(shaped, message);
  };

  next();
}

module.exports = { shapingMiddleware };
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/backend && node --test test/response-shaping.test.js
```

Expected: PASS（全部测试通过）。

- [ ] **Step 5: 提交**

```bash
git add backend/middleware/feature-flag.js backend/test/response-shaping.test.js
git commit -m "feat(subscription): add response shaping middleware with expiry detection"
```

---

## Task 4：订阅管理 API

**Files:**
- Create: `backend/routes/subscription.js`
- Create: `backend/test/subscription-api.test.js`

### 目标

新增 7 个订阅管理端点，支持获取当前订阅/功能清单/套餐列表/Mock 支付/取消/续费/用量统计。

### 实施步骤

- [ ] **Step 1: 写测试 `backend/test/subscription-api.test.js`**

```javascript
const { describe, it, before, after } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const http = require('http');
const { envelopeMiddleware } = require('../middleware/envelope');
const { authMiddleware } = require('../middleware/auth');
const { reset } = require('../data/subscriptions');

function makeRequest(app, method, path, token, body) {
  return new Promise((resolve, reject) => {
    const server = http.createServer(app);
    server.listen(0, () => {
      const port = server.address().port;
      const options = {
        hostname: 'localhost', port, path, method,
        headers: { 'Content-Type': 'application/json' },
      };
      if (token) options.headers.Authorization = `Bearer ${token}`;
      const req = http.request(options, (res) => {
        let data = '';
        res.on('data', d => data += d);
        res.on('end', () => {
          server.close();
          resolve({ status: res.statusCode, body: JSON.parse(data) });
        });
      });
      if (body) req.write(JSON.stringify(body));
      req.on('error', reject);
      req.end();
    });
  });
}

describe('Subscription API', () => {
  let app;
  before(() => {
    reset();
    app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    const subscriptionRoutes = require('../routes/subscription');
    app.use('/api/subscription', subscriptionRoutes);
  });

  it('GET /api/subscription/current — 返回当前订阅状态', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/subscription/current', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.tier, 'basic');
    assert.equal(body.data.status, 'active');
    assert.ok(body.data.currentPeriodEnd);
  });

  it('GET /api/subscription/features — 返回功能清单', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/subscription/features', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.ok(Array.isArray(body.data.features));
    assert.ok(body.data.features.length > 0);
    // 验证有 category 分组
    const categories = [...new Set(body.data.features.map(f => f.category))];
    assert.ok(categories.includes('health'));
  });

  it('GET /api/subscription/plans — 返回全部套餐', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/subscription/plans', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.ok(Array.isArray(body.data.plans));
    assert.equal(body.data.plans.length, 4);
    // enterprise 有 contactSales
    const enterprise = body.data.plans.find(p => p.id === 'enterprise');
    assert.equal(enterprise.contactSales, true);
  });

  it('POST /api/subscription/checkout — 升级到标准版', async () => {
    const { body } = await makeRequest(app, 'POST', '/api/subscription/checkout', 'mock-token-owner', {
      tier: 'standard',
      idempotencyKey: 'test-key-001',
    });
    assert.equal(body.code, 'OK');
    assert.equal(body.data.tier, 'standard');
    assert.equal(body.data.status, 'active');
  });

  it('POST /api/subscription/checkout — 幂等性防重复', async () => {
    const payload = { tier: 'premium', idempotencyKey: 'test-key-idem-001' };
    const { body: b1 } = await makeRequest(app, 'POST', '/api/subscription/checkout', 'mock-token-owner', payload);
    const { body: b2 } = await makeRequest(app, 'POST', '/api/subscription/checkout', 'mock-token-owner', payload);
    // 第二次请求返回相同结果
    assert.equal(b1.data.tier, b2.data.tier);
  });

  it('POST /api/subscription/checkout — 无效层级返回 400', async () => {
    const { status, body } = await makeRequest(app, 'POST', '/api/subscription/checkout', 'mock-token-owner', {
      tier: 'invalid',
      idempotencyKey: 'test-key-002',
    });
    assert.equal(status, 400);
  });

  it('POST /api/subscription/cancel — 取消订阅', async () => {
    const { body } = await makeRequest(app, 'POST', '/api/subscription/cancel', 'mock-token-owner', {});
    assert.equal(body.code, 'OK');
    assert.equal(body.data.status, 'cancelled');
  });

  it('POST /api/subscription/renew — 续费', async () => {
    const { body } = await makeRequest(app, 'POST', '/api/subscription/renew', 'mock-token-owner', {});
    assert.equal(body.code, 'OK');
    assert.equal(body.data.status, 'active');
  });

  it('GET /api/subscription/usage — 返回用量统计', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/subscription/usage', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.ok(body.data.livestock);
  });

  it('worker 角色访问订阅 → 返回但无管理权限标记', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/subscription/current', 'mock-token-worker');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.isOwner, false);
  });

  it('ops 角色无 tenantId → 返回 403', async () => {
    const { status } = await makeRequest(app, 'GET', '/api/subscription/current', 'mock-token-ops');
    assert.ok(status === 403 || status === 404);
  });
});
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/backend && node --test test/subscription-api.test.js
```

Expected: FAIL（路由文件不存在）。

- [ ] **Step 3: 实现 `backend/routes/subscription.js`**

```javascript
const express = require('express');
const router = express.Router();
const { authMiddleware } = require('../middleware/auth');
const {
  getByTenantId,
  checkout,
  cancel,
  renew,
  getUsage,
  TIERS,
  getIdempotencyResult,
  setIdempotencyResult,
} = require('../data/subscriptions');
const { featureFlags } = require('../data/feature-flags');

// 订阅路由不注册 shapingMiddleware，避免自身被拦截

router.use(authMiddleware);

// GET /api/subscription/current
router.get('/current', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.fail(403, 'SUBSCRIPTION_FORBIDDEN', '当前角色无订阅功能');
  }
  const sub = getByTenantId(tenantId);
  if (!sub) {
    return res.fail(404, 'SUBSCRIPTION_NOT_FOUND', '未找到订阅信息');
  }
  res.ok({
    ...sub,
    isOwner: req.userRole === 'owner',
    tierName: TIERS[sub.tier]?.name || '',
  });
});

// GET /api/subscription/features
router.get('/features', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.fail(403, 'SUBSCRIPTION_FORBIDDEN', '当前角色无订阅功能');
  }
  const sub = getByTenantId(tenantId);
  const tier = sub ? sub.tier : 'basic';

  const features = [];
  for (const [key, flag] of featureFlags) {
    features.push({
      key,
      category: flag.category,
      name: key,
      shaping: flag.shaping,
      available: flag.shaping === 'none' ||
        (flag.minTier ? ['basic', 'standard', 'premium', 'enterprise'].indexOf(tier) >= ['basic', 'standard', 'premium', 'enterprise'].indexOf(flag.minTier) : true),
      ...(flag.rulesByTier?.[tier] ? { limit: flag.rulesByTier[tier] } : {}),
    });
  }

  res.ok({ features, currentTier: tier });
});

// GET /api/subscription/plans
router.get('/plans', (req, res) => {
  const tenantId = req.user?.tenantId;
  const sub = tenantId ? getByTenantId(tenantId) : null;
  const currentTier = sub ? sub.tier : 'basic';

  const plans = Object.values(TIERS).map(tier => ({
    ...tier,
    isCurrent: tier.id === currentTier,
    contactSales: tier.id === 'enterprise',
    salesEmail: tier.id === 'enterprise' ? 'sales@hktlora.com' : undefined,
  }));

  res.ok({ plans, currentTier });
});

// POST /api/subscription/checkout
router.post('/checkout', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.fail(403, 'SUBSCRIPTION_FORBIDDEN', '当前角色无订阅功能');
  }

  const { tier, idempotencyKey } = req.body || {};

  // Idempotency check
  if (idempotencyKey) {
    const cached = getIdempotencyResult(idempotencyKey);
    if (cached) return res.ok(cached);
  }

  if (!tier || !TIERS[tier]) {
    return res.fail(400, 'INVALID_TIER', '无效的套餐层级');
  }

  if (tier === 'enterprise') {
    return res.fail(400, 'ENTERPRISE_CONTACT', '企业版请联系销售');
  }

  const sub = getByTenantId(tenantId);
  const livestockCount = sub ? sub.livestockCount : 0;

  // Simulate payment delay
  setTimeout(() => {
    const result = checkout(tenantId, tier, livestockCount);

    if (idempotencyKey) {
      setIdempotencyResult(idempotencyKey, result);
    }

    res.ok({
      ...result,
      tierName: TIERS[tier].name,
    });
  }, 500);
});

// POST /api/subscription/cancel
router.post('/cancel', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.fail(403, 'SUBSCRIPTION_FORBIDDEN', '当前角色无订阅功能');
  }

  const sub = getByTenantId(tenantId);
  if (!sub) {
    return res.fail(404, 'SUBSCRIPTION_NOT_FOUND', '未找到订阅信息');
  }

  const result = cancel(tenantId);
  res.ok(result);
});

// POST /api/subscription/renew
router.post('/renew', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.fail(403, 'SUBSCRIPTION_FORBIDDEN', '当前角色无订阅功能');
  }

  const { idempotencyKey } = req.body || {};

  if (idempotencyKey) {
    const cached = getIdempotencyResult(idempotencyKey);
    if (cached) return res.ok(cached);
  }

  const sub = getByTenantId(tenantId);
  if (!sub) {
    return res.fail(404, 'SUBSCRIPTION_NOT_FOUND', '未找到订阅信息');
  }

  setTimeout(() => {
    const result = renew(tenantId);

    if (idempotencyKey) {
      setIdempotencyResult(idempotencyKey, result);
    }

    res.ok(result);
  }, 500);
});

// GET /api/subscription/usage
router.get('/usage', (req, res) => {
  const tenantId = req.user?.tenantId;
  if (!tenantId) {
    return res.fail(403, 'SUBSCRIPTION_FORBIDDEN', '当前角色无订阅功能');
  }

  const usage = getUsage(tenantId);
  if (!usage) {
    return res.fail(404, 'SUBSCRIPTION_NOT_FOUND', '未找到订阅信息');
  }

  res.ok(usage);
});

module.exports = router;
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/backend && node --test test/subscription-api.test.js
```

Expected: PASS（全部测试通过）。

- [ ] **Step 5: 提交**

```bash
git add backend/routes/subscription.js backend/test/subscription-api.test.js
git commit -m "feat(subscription): add subscription management API with idempotent checkout"
```

---

## Task 5：将 Shaping 注册到现有路由

**Files:**
- Modify: `backend/routes/map.js`
- Modify: `backend/routes/fences.js`
- Modify: `backend/routes/alerts.js`
- Modify: `backend/routes/dashboard.js`
- Modify: `backend/routes/twin.js`
- Create: `backend/test/tier-access-integration.test.js`

### 目标

在每个受影响路由的 auth 中间件之后、路由处理函数之前注册 feature keys + shaping 中间件。

### 实施步骤

- [ ] **Step 1: 写集成测试 `backend/test/tier-access-integration.test.js`**

```javascript
const { describe, it, before } = require('node:test');
const assert = require('node:assert/strict');
const express = require('express');
const http = require('http');
const { reset } = require('../data/subscriptions');

function makeRequest(app, method, path, token) {
  return new Promise((resolve, reject) => {
    const server = http.createServer(app);
    server.listen(0, () => {
      const port = server.address().port;
      const req = http.request({
        hostname: 'localhost', port, path, method,
        headers: token ? { Authorization: `Bearer ${token}` } : {},
      }, (res) => {
        let body = '';
        res.on('data', d => body += d);
        res.on('end', () => {
          server.close();
          resolve({ status: res.statusCode, body: JSON.parse(body) });
        });
      });
      req.on('error', reject);
      req.end();
    });
  });
}

describe('Tier Access Integration', () => {
  let app;
  before(() => {
    reset();
    const { envelopeMiddleware } = require('../middleware/envelope');
    const { registerApiRoutes } = require('../routes/registerApiRoutes');

    app = express();
    app.use(express.json());
    app.use(envelopeMiddleware);
    registerApiRoutes(app, '/api');
  });

  it('basic 用户 GET /api/twin/estrus/list → locked', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/twin/estrus/list', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.locked, true);
  });

  it('basic 用户 GET /api/twin/fever/list → 正常', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/twin/fever/list', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.locked, undefined);
  });

  it('basic 用户 GET /api/fences → items ≤ 3（但 locked 不注入，仅 limit）', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/fences?pageSize=100', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    // limit 应该注入（如果数据超过 3 个围栏）
    if (body.data.limit) {
      assert.equal(body.data.limit.maxCount, 3);
    }
    assert.ok(body.data.items.length <= 3 || body.data.limit);
  });

  it('basic 用户 GET /api/alerts → filter + locked', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/alerts?pageSize=100', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    // alert_history locked for basic (data_retention_days filter + alert_history lock)
    assert.equal(body.data.locked, true);
  });

  it('basic 用户 GET /api/dashboard/summary → limited metrics', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/dashboard/summary', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    if (body.data.limit) {
      assert.ok(body.data.limit.message);
    }
  });

  it('basic 用户 GET /api/map/trajectories → locked（trajectory）', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/map/trajectories?animalId=animal_001&range=24h', 'mock-token-owner');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.locked, true);
  });

  it('ops 用户 GET /api/tenants → 正常（无 shaping）', async () => {
    const { body } = await makeRequest(app, 'GET', '/api/tenants?pageSize=100', 'mock-token-ops');
    assert.equal(body.code, 'OK');
    assert.equal(body.data.locked, undefined);
    assert.ok(Array.isArray(body.data.items));
  });
});
```

- [ ] **Step 2: 运行测试确认失败（当前路由未注册 shaping）**

```bash
cd Mobile/backend && node --test test/tier-access-integration.test.js
```

Expected: FAIL（locked 未注入）。

- [ ] **Step 3: 修改 `backend/routes/map.js`**

在 `router.use(authMiddleware)` 之后、路由处理函数之前添加：

```javascript
const { shapingMiddleware } = require('../middleware/feature-flag');

// ... existing code ...

router.use(authMiddleware);
router.use(requirePermission('map:view'));

// 订阅 shaping: trajectory + data_retention_days
router.use((req, res, next) => {
  req.routeFeatureKeys = ['trajectory', 'data_retention_days'];
  next();
});
router.use(shapingMiddleware);
```

- [ ] **Step 4: 修改 `backend/routes/fences.js`**

在 `router.use(authMiddleware)` 之后添加：

```javascript
const { shapingMiddleware } = require('../middleware/feature-flag');
const { getByTenantId } = require('../data/subscriptions');
const { featureFlags, tierIndex } = require('../data/feature-flags');

// ... existing imports ...

router.use(authMiddleware);

// 订阅 shaping: fence（limit 策略）
router.use((req, res, next) => {
  req.routeFeatureKeys = ['fence'];
  next();
});
router.use(shapingMiddleware);
```

在 POST handler 中 `store.createFence()` 调用之前添加围栏数量检查：

```javascript
// routes/fences.js POST handler 中
router.post('/', requirePermission('fence:manage'), (req, res) => {
  const tenantId = req.user?.tenantId;
  if (tenantId) {
    const sub = getByTenantId(tenantId);
    const tier = sub ? sub.tier : 'basic';
    const fenceFlag = featureFlags.get('fence');
    const rule = fenceFlag?.rulesByTier?.[tier];
    if (rule) {
      const existingCount = store.listByTenant(tenantId).length;
      if (existingCount >= rule.maxCount) {
        return res.ok({
          limit: { maxCount: rule.maxCount, locked: true, message: rule.message },
          items: [],
          total: 0,
        });
      }
    }
  }
  // ... 继续现有 createFence 逻辑 ...
});
```

- [ ] **Step 5: 修改 `backend/routes/alerts.js`**

```javascript
const { shapingMiddleware } = require('../middleware/feature-flag');

router.use(authMiddleware);

// 订阅 shaping: data_retention_days filter + alert_history lock（多 key）
router.use((req, res, next) => {
  req.routeFeatureKeys = ['data_retention_days', 'alert_history'];
  next();
});
router.use(shapingMiddleware);
```

- [ ] **Step 6: 修改 `backend/routes/dashboard.js`**

```javascript
const { shapingMiddleware } = require('../middleware/feature-flag');

router.use(authMiddleware);

router.use((req, res, next) => {
  req.routeFeatureKeys = ['dashboard_summary'];
  next();
});
router.use(shapingMiddleware);
```

- [ ] **Step 7: 修改 `backend/routes/twin.js`**

```javascript
const { shapingMiddleware } = require('../middleware/feature-flag');

router.use(authMiddleware);
router.use(requirePermission('twin:view'));

// 订阅 shaping: 按端点区分 feature keys
// estrus 端点: estrus_detect (lock)
// epidemic 端点: epidemic_alert (lock)
// fever/digestive: temperature_monitor / peristaltic_monitor (none，但仍注册以透传)
router.use((req, res, next) => {
  const path = req.path;
  if (path.includes('/estrus')) {
    req.routeFeatureKeys = ['estrus_detect'];
  } else if (path.includes('/epidemic')) {
    req.routeFeatureKeys = ['epidemic_alert'];
  } else if (path.includes('/fever')) {
    req.routeFeatureKeys = ['temperature_monitor'];
  } else if (path.includes('/digestive')) {
    req.routeFeatureKeys = ['peristaltic_monitor'];
  } else {
    req.routeFeatureKeys = [];
  }
  next();
});
router.use(shapingMiddleware);
```

- [ ] **Step 8: 运行集成测试确认通过**

```bash
cd Mobile/backend && node --test test/tier-access-integration.test.js
```

Expected: PASS（全部测试通过）。

- [ ] **Step 9: 提交**

```bash
git add backend/routes/map.js backend/routes/fences.js backend/routes/alerts.js backend/routes/dashboard.js backend/routes/twin.js backend/test/tier-access-integration.test.js
git commit -m "feat(subscription): wire shaping middleware into existing API routes"
```

---

## Task 6：租户创建试订阅 + 路由注册

**Files:**
- Modify: `backend/routes/tenants.js`
- Modify: `backend/routes/registerApiRoutes.js`

### 目标

新租户创建时自动获得高级版 14 天试用订阅；注册 subscription 路由。

### 实施步骤

- [ ] **Step 1: 修改 `backend/routes/tenants.js` — POST handler 集成**

在文件顶部添加引用：

```javascript
const { createTrial } = require('../data/subscriptions');
```

在 POST handler 中 `store.createTenant()` 成功后：

```javascript
// 在 store.createTenant(newTenant) 之后
const trial = createTrial(newTenant.id);
```

- [ ] **Step 2: 修改 `backend/routes/registerApiRoutes.js`**

```javascript
const subscriptionRoutes = require('./subscription');

function registerApiRoutes(app, prefix) {
  app.use(`${prefix}/auth`, authRoutes);
  app.use(`${prefix}/me`, meRoutes);
  // ... existing routes ...
  app.use(`${prefix}/subscription`, subscriptionRoutes);  // 新增
}
```

- [ ] **Step 3: 验证现有后端测试全部通过**

```bash
cd Mobile/backend && node --test test/
```

- [ ] **Step 4: 提交**

```bash
git add backend/routes/tenants.js backend/routes/registerApiRoutes.js
git commit -m "feat(subscription): auto-create trial on tenant creation and register subscription routes"
```

---

## Task 7：前端 SubscriptionTier 模型 + TDD

**Files:**
- Create: `lib/core/models/subscription_tier.dart`
- Create: `test/core/subscription_tier_test.dart`

### 目标

定义 `SubscriptionTier` 枚举、`SubscriptionStatus` 模型、价格计算函数。

### 实施步骤

- [ ] **Step 1: 写测试 `test/core/subscription_tier_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

void main() {
  group('SubscriptionTier', () {
    test('有四个层级', () {
      expect(SubscriptionTier.values.length, 4);
    });

    test('monthlyPriceInFen 正确', () {
      expect(SubscriptionTier.basic.monthlyPriceInFen, 0);
      expect(SubscriptionTier.standard.monthlyPriceInFen, 29900);
      expect(SubscriptionTier.premium.monthlyPriceInFen, 69900);
      expect(SubscriptionTier.enterprise.monthlyPriceInFen, null);
    });

    test('displayPrice 展示为元', () {
      expect(SubscriptionTier.basic.displayPrice, '¥0');
      expect(SubscriptionTier.standard.displayPrice, '¥299');
      expect(SubscriptionTier.premium.displayPrice, '¥699');
      expect(SubscriptionTier.enterprise.displayPrice, '定制报价');
    });

    test('enterprise contactSales 为 true', () {
      expect(SubscriptionTier.enterprise.contactSales, true);
      expect(SubscriptionTier.premium.contactSales, false);
    });
  });

  group('calculatePrice', () {
    test('基础版 50 头 = ¥0', () {
      expect(calculatePrice(SubscriptionTier.basic, 50), 0);
    });

    test('标准版 200 头 = ¥299', () {
      expect(calculatePrice(SubscriptionTier.standard, 200), 29900);
    });

    test('标准版 350 头 = ¥449（超出 150 头=3x50）', () {
      expect(calculatePrice(SubscriptionTier.standard, 350), 44900);
    });

    test('高级版 1500 头 = ¥1,099（超出 500 头=5x80）', () {
      expect(calculatePrice(SubscriptionTier.premium, 1500), 109900);
    });

    test('企业版无限 = null', () {
      expect(calculatePrice(SubscriptionTier.enterprise, 9999), null);
    });
  });

  group('SubscriptionStatus', () {
    test('daysUntilExpiry 计算正确', () {
      final status = SubscriptionStatus(
        tenantId: 't1',
        tier: SubscriptionTier.standard,
        currentPeriodStart: DateTime(2026, 4, 1),
        currentPeriodEnd: DateTime(2026, 5, 1).add(const Duration(days: 10)),
        status: SubscriptionState.active,
        livestockCount: 100,
        calculatedPrice: 29900,
      );
      expect(status.daysUntilExpiry, greaterThan(0));
    });

    test('expired 状态 daysUntilExpiry = 0', () {
      final status = SubscriptionStatus(
        tenantId: 't1',
        tier: SubscriptionTier.basic,
        currentPeriodStart: DateTime(2026, 4, 1),
        currentPeriodEnd: DateTime(2026, 5, 1),
        status: SubscriptionState.expired,
        livestockCount: 50,
        calculatedPrice: 0,
      );
      expect(status.daysUntilExpiry, 0);
    });

    test('expiryLevel 返回正确级别', () {
      final warning = SubscriptionStatus(
        tenantId: 't1', tier: SubscriptionTier.standard,
        currentPeriodStart: DateTime(2026, 4, 1),
        currentPeriodEnd: DateTime.now().add(const Duration(days: 5)),
        status: SubscriptionState.active, livestockCount: 100, calculatedPrice: 29900,
      );
      expect(warning.expiryLevel, ExpiryLevel.warning);

      final critical = SubscriptionStatus(
        tenantId: 't1', tier: SubscriptionTier.standard,
        currentPeriodStart: DateTime(2026, 4, 1),
        currentPeriodEnd: DateTime.now().add(const Duration(days: 2)),
        status: SubscriptionState.active, livestockCount: 100, calculatedPrice: 29900,
      );
      expect(critical.expiryLevel, ExpiryLevel.critical);

      final expired = SubscriptionStatus(
        tenantId: 't1', tier: SubscriptionTier.basic,
        currentPeriodStart: DateTime(2026, 4, 1),
        currentPeriodEnd: DateTime.now().subtract(const Duration(days: 1)),
        status: SubscriptionState.expired, livestockCount: 50, calculatedPrice: 0,
      );
      expect(expired.expiryLevel, ExpiryLevel.expired);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/mobile_app && flutter test test/core/subscription_tier_test.dart
```

Expected: FAIL（文件不存在）。

- [ ] **Step 3: 实现 `lib/core/models/subscription_tier.dart`**

```dart
enum SubscriptionTier {
  basic(monthlyPriceInFen: 0, includedLivestock: 50, perUnitPrice: null, perUnitSize: null),
  standard(monthlyPriceInFen: 29900, includedLivestock: 200, perUnitPrice: 50, perUnitSize: 50),
  premium(monthlyPriceInFen: 69900, includedLivestock: 1000, perUnitPrice: 80, perUnitSize: 100),
  enterprise(monthlyPriceInFen: null, includedLivestock: -1, perUnitPrice: null, perUnitSize: null);

  const SubscriptionTier({
    required this.monthlyPriceInFen,
    required this.includedLivestock,
    required this.perUnitPrice,
    required this.perUnitSize,
  });

  final int? monthlyPriceInFen;
  final int includedLivestock;
  final int? perUnitPrice;
  final int? perUnitSize;

  String get displayPrice {
    if (monthlyPriceInFen == null) return '定制报价';
    final yuan = monthlyPriceInFen! ~/ 100;
    return '¥$yuan';
  }

  String get name => switch (this) {
    SubscriptionTier.basic => '基础版',
    SubscriptionTier.standard => '标准版',
    SubscriptionTier.premium => '高级版',
    SubscriptionTier.enterprise => '企业版',
  };

  bool get contactSales => this == SubscriptionTier.enterprise;

  bool get isFree => monthlyPriceInFen == 0;
}

enum SubscriptionState {
  active('生效中'),
  trial('试用中'),
  expired('已过期'),
  cancelled('已取消');

  const SubscriptionState(this.label);
  final String label;
}

enum ExpiryLevel { none, warning, critical, expired }

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.tenantId,
    required this.tier,
    required this.currentPeriodStart,
    required this.currentPeriodEnd,
    required this.status,
    required this.livestockCount,
    required this.calculatedPrice,
    this.trialEndsAt,
    this.isOwner = true,
  });

  final String tenantId;
  final SubscriptionTier tier;
  final DateTime currentPeriodStart;
  final DateTime currentPeriodEnd;
  final SubscriptionState status;
  final int livestockCount;
  final int calculatedPrice;
  final DateTime? trialEndsAt;
  final bool isOwner;

  int get daysUntilExpiry {
    if (status == SubscriptionState.expired) return 0;
    final endDate = status == SubscriptionState.trial ? trialEndsAt : currentPeriodEnd;
    if (endDate == null) return 999;
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }

  ExpiryLevel get expiryLevel {
    if (daysUntilExpiry <= 0) return ExpiryLevel.expired;
    if (daysUntilExpiry <= 3) return ExpiryLevel.critical;
    if (daysUntilExpiry <= 7) return ExpiryLevel.warning;
    return ExpiryLevel.none;
  }
}

int? calculatePrice(SubscriptionTier tier, int livestockCount) {
  if (tier.monthlyPriceInFen == null) return null; // enterprise
  if (tier.includedLivestock == -1) return null; // unlimited
  int price = tier.monthlyPriceInFen!;
  if (livestockCount > tier.includedLivestock &&
      tier.perUnitPrice != null &&
      tier.perUnitSize != null) {
    final extra = livestockCount - tier.includedLivestock;
    final units = (extra / tier.perUnitSize!).ceil();
    price += units * tier.perUnitPrice!;
  }
  return price;
}

List<SubscriptionTier> get upgradableTiers {
  final tiers = SubscriptionTier.values.toList();
  tiers.remove(SubscriptionTier.enterprise); // enterprise is separate
  return tiers;
}
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/mobile_app && flutter test test/core/subscription_tier_test.dart
```

Expected: PASS。

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/core/models/subscription_tier.dart mobile_app/test/core/subscription_tier_test.dart
git commit -m "feat(subscription): add SubscriptionTier model with price calculation"
```

---

## Task 8：LockedOverlay 统一组件 + TDD

**Files:**
- Create: `lib/widgets/locked_overlay.dart`
- Create: `test/widgets/locked_overlay_test.dart`

### 目标

实现通用 LockedOverlay 组件，覆盖 locked 遮罩 + 升级按钮（owner 显示，worker 不显示）。

### 实施步骤

- [ ] **Step 1: 写测试 `test/widgets/locked_overlay_test.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/widgets/locked_overlay.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

void main() {
  group('LockedOverlay', () {
    testWidgets('locked=true 显示锁图标和消息', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedOverlay(
              isLocked: true,
              upgradeTier: SubscriptionTier.premium,
              message: '需要高级版',
              showUpgradeButton: true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('需要高级版'), findsOneWidget);
    });

    testWidgets('locked=false 正常渲染 child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedOverlay(
              isLocked: false,
              upgradeTier: SubscriptionTier.premium,
              message: '需要高级版',
              showUpgradeButton: true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('Content'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });

    testWidgets('showUpgradeButton=false (worker) 隐藏升级按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedOverlay(
              isLocked: true,
              upgradeTier: SubscriptionTier.premium,
              message: '需要高级版',
              showUpgradeButton: false,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('升级到高级版解锁'), findsNothing);
      expect(find.text('功能不可用'), findsOneWidget);
    });

    testWidgets('showUpgradeButton=true (owner) 显示升级按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedOverlay(
              isLocked: true,
              upgradeTier: SubscriptionTier.standard,
              message: '需要标准版',
              showUpgradeButton: true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('升级到标准版解锁'), findsOneWidget);
    });

    testWidgets('limit 类型 locked=true 禁用新建按钮', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LockedOverlay(
              isLocked: true,
              limitMaxCount: 3,
              limitMessage: '基础版最多 3 个围栏',
              showUpgradeButton: true,
              child: const Text('Content'),
            ),
          ),
        ),
      );

      expect(find.text('基础版最多 3 个围栏'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

```bash
cd Mobile/mobile_app && flutter test test/widgets/locked_overlay_test.dart
```

- [ ] **Step 3: 实现 `lib/widgets/locked_overlay.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class LockedOverlay extends StatelessWidget {
  const LockedOverlay({
    super.key,
    required this.isLocked,
    required this.showUpgradeButton,
    required this.child,
    this.upgradeTier,
    this.message,
    this.limitMaxCount,
    this.limitMessage,
    this.onUpgradeTap,
  });

  final bool isLocked;
  final bool showUpgradeButton;
  final Widget child;
  final SubscriptionTier? upgradeTier;
  final String? message;
  final int? limitMaxCount;
  final String? limitMessage;
  final VoidCallback? onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    if (!isLocked) return child;

    return Stack(
      children: [
        child,
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 40,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      message ?? limitMessage ?? '功能不可用',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (showUpgradeButton && upgradeTier != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ElevatedButton(
                        onPressed: onUpgradeTap ??
                            () => Navigator.of(context).pushNamed('/subscription'),
                        child: Text('升级到${upgradeTier!.name}解锁'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

```bash
cd Mobile/mobile_app && flutter test test/widgets/locked_overlay_test.dart
```

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/widgets/locked_overlay.dart mobile_app/test/widgets/locked_overlay_test.dart
git commit -m "feat(subscription): add LockedOverlay unified component"
```

---

## Task 9：Subscription Repository + Controller + TDD

**Files:**
- Create: `lib/features/subscription/domain/subscription_repository.dart`
- Create: `lib/features/subscription/data/mock_subscription_repository.dart`
- Create: `lib/features/subscription/data/live_subscription_repository.dart`
- Create: `lib/features/subscription/presentation/subscription_controller.dart`
- Create: `test/features/subscription/subscription_controller_test.dart`

### 目标

实现订阅 Repository（mock + live）+ SubscriptionController（Riverpod Notifier）。

### 实施步骤

- [ ] **Step 1: 写 Controller 测试 `test/features/subscription/subscription_controller_test.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

void main() {
  group('SubscriptionController', () {
    test('初始状态为 basic', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(subscriptionControllerProvider);
      expect(state.tier, SubscriptionTier.basic);
      expect(state.status, SubscriptionState.active);
    });

    test('checkout 成功后状态更新', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).checkout(
        SubscriptionTier.standard,
        idempotencyKey: 'test-key',
      );

      final state = container.read(subscriptionControllerProvider);
      expect(state.tier, SubscriptionTier.standard);
      expect(state.status, SubscriptionState.active);
    });

    test('cancel 后状态变为 cancelled', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).cancel();

      final state = container.read(subscriptionControllerProvider);
      expect(state.status, SubscriptionState.cancelled);
    });

    test('renew 后状态变为 active', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container.read(subscriptionControllerProvider.notifier).cancel();
      await container.read(subscriptionControllerProvider.notifier).renew();

      final state = container.read(subscriptionControllerProvider);
      expect(state.status, SubscriptionState.active);
    });
  });
}
```

- [ ] **Step 2: 运行测试确认失败**

- [ ] **Step 3: 实现 `subscription_repository.dart`（接口）**

```dart
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class SubscriptionViewData {
  const SubscriptionViewData({
    this.viewState = ViewState.normal,
    this.status,
    this.features = const [],
    this.plans = const [],
    this.message,
  });

  final ViewState viewState;
  final SubscriptionStatus? status;
  final List<Map<String, dynamic>> features;
  final List<SubscriptionTier> plans;
  final String? message;
}

abstract class SubscriptionRepository {
  SubscriptionViewData load();
  Future<SubscriptionStatus?> checkout(SubscriptionTier tier, String idempotencyKey);
  Future<SubscriptionStatus?> cancel();
  Future<SubscriptionStatus?> renew(String idempotencyKey);
}
```

- [ ] **Step 4: 实现 `mock_subscription_repository.dart`**

```dart
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  SubscriptionStatus _status = SubscriptionStatus(
    tenantId: 'tenant_001',
    tier: SubscriptionTier.basic,
    currentPeriodStart: DateTime.now(),
    currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
    status: SubscriptionState.active,
    livestockCount: 50,
    calculatedPrice: 0,
  );

  @override
  SubscriptionViewData load() {
    return SubscriptionViewData(
      status: _status,
      features: _buildFeatures(),
      plans: SubscriptionTier.values.toList(),
    );
  }

  List<Map<String, dynamic>> _buildFeatures() {
    // 与后端 feature-flags.js 对齐
    return [
      {'key': 'gps_location', 'category': 'location', 'available': true},
      {'key': 'fence', 'category': 'location', 'available': true, 'limit': {'maxCount': 3}},
      {'key': 'trajectory', 'category': 'location', 'available': false},
      {'key': 'temperature_monitor', 'category': 'health', 'available': true},
      {'key': 'estrus_detect', 'category': 'health', 'available': false},
      {'key': 'epidemic_alert', 'category': 'health', 'available': false},
      {'key': 'data_retention_days', 'category': 'service', 'available': true, 'retentionDays': 7},
      {'key': 'alert_history', 'category': 'service', 'available': false},
      {'key': 'dashboard_summary', 'category': 'analytics', 'available': true},
    ];
  }

  @override
  Future<SubscriptionStatus?> checkout(SubscriptionTier tier, String idempotencyKey) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final now = DateTime.now();
    _status = SubscriptionStatus(
      tenantId: _status.tenantId,
      tier: tier,
      currentPeriodStart: now,
      currentPeriodEnd: now.add(const Duration(days: 30)),
      status: SubscriptionState.active,
      livestockCount: _status.livestockCount,
      calculatedPrice: calculatePrice(tier, _status.livestockCount) ?? 0,
    );
    return _status;
  }

  @override
  Future<SubscriptionStatus?> cancel() async {
    _status = SubscriptionStatus(
      tenantId: _status.tenantId,
      tier: _status.tier,
      currentPeriodStart: _status.currentPeriodStart,
      currentPeriodEnd: _status.currentPeriodEnd,
      status: SubscriptionState.cancelled,
      livestockCount: _status.livestockCount,
      calculatedPrice: _status.calculatedPrice,
    );
    return _status;
  }

  @override
  Future<SubscriptionStatus?> renew(String idempotencyKey) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final newEnd = (_status.currentPeriodEnd ?? DateTime.now()).add(const Duration(days: 30));
    _status = SubscriptionStatus(
      tenantId: _status.tenantId,
      tier: _status.tier,
      currentPeriodStart: _status.currentPeriodStart,
      currentPeriodEnd: newEnd,
      status: SubscriptionState.active,
      livestockCount: _status.livestockCount,
      calculatedPrice: _status.calculatedPrice,
    );
    return _status;
  }
}
```

- [ ] **Step 5: 实现 `live_subscription_repository.dart`**

```dart
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

class LiveSubscriptionRepository implements SubscriptionRepository {
  @override
  SubscriptionViewData load() {
    final cache = ApiCache.instance;
    if (!cache.initialized) {
      return const SubscriptionViewData(viewState: ViewState.loading);
    }
    final raw = cache.subscriptionStatus;
    if (raw == null) {
      return const SubscriptionViewData(viewState: ViewState.empty, message: '暂无订阅数据');
    }
    final tierId = raw['tier'] as String? ?? 'basic';
    final tier = SubscriptionTier.values.firstWhere(
      (t) => t.name == raw['tierName'] || t.name == tierId,
      orElse: () => SubscriptionTier.basic,
    );
    final statusStr = raw['status'] as String? ?? 'active';
    final state = switch (statusStr) {
      'trial' => SubscriptionState.trial,
      'expired' => SubscriptionState.expired,
      'cancelled' => SubscriptionState.cancelled,
      _ => SubscriptionState.active,
    };

    return SubscriptionViewData(
      status: SubscriptionStatus(
        tenantId: raw['tenantId'] as String? ?? '',
        tier: tier,
        currentPeriodStart: DateTime.tryParse(raw['currentPeriodStart'] as String? ?? '') ?? DateTime.now(),
        currentPeriodEnd: DateTime.tryParse(raw['currentPeriodEnd'] as String? ?? '') ?? DateTime.now(),
        status: state,
        livestockCount: raw['livestockCount'] as int? ?? 0,
        calculatedPrice: raw['calculatedPrice'] as int? ?? 0,
        trialEndsAt: raw['trialEndsAt'] != null ? DateTime.tryParse(raw['trialEndsAt'] as String) : null,
        isOwner: raw['isOwner'] as bool? ?? true,
      ),
      features: List<Map<String, dynamic>>.from(cache.features),
      plans: SubscriptionTier.values.toList(),
    );
  }

  @override
  Future<SubscriptionStatus?> checkout(SubscriptionTier tier, String idempotencyKey) async {
    final ok = await ApiCache.instance.checkoutSubscriptionRemote('owner', tier.name, idempotencyKey);
    if (!ok) return null;
    await ApiCache.instance.refreshSubscription('owner');
    return load().status;
  }

  @override
  Future<SubscriptionStatus?> cancel() async {
    final ok = await ApiCache.instance.cancelSubscriptionRemote('owner');
    if (!ok) return null;
    await ApiCache.instance.refreshSubscription('owner');
    return load().status;
  }

  @override
  Future<SubscriptionStatus?> renew(String idempotencyKey) async {
    final ok = await ApiCache.instance.renewSubscriptionRemote('owner', idempotencyKey);
    if (!ok) return null;
    await ApiCache.instance.refreshSubscription('owner');
    return load().status;
  }
}
```

- [ ] **Step 6: 实现 `subscription_controller.dart`**

```dart
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/subscription/data/live_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/data/mock_subscription_repository.dart';
import 'package:smart_livestock_demo/features/subscription/domain/subscription_repository.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final appMode = ref.watch(appModeProvider);
  return appMode.isLive ? LiveSubscriptionRepository() : MockSubscriptionRepository();
});

final subscriptionControllerProvider = NotifierProvider<SubscriptionController, SubscriptionViewData>(
  SubscriptionController.new,
);

class SubscriptionController extends Notifier<SubscriptionViewData> {
  @override
  SubscriptionViewData build() {
    return ref.read(subscriptionRepositoryProvider).load();
  }

  Future<SubscriptionStatus?> checkout(SubscriptionTier tier, {String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'sub-checkout-${Random().nextInt(999999)}';
    state = SubscriptionViewData(viewState: ViewState.loading, status: state.status);
    final status = await ref.read(subscriptionRepositoryProvider).checkout(tier, key);
    if (status != null) {
      state = SubscriptionViewData(status: status, plans: SubscriptionTier.values.toList());
    } else {
      state = SubscriptionViewData(viewState: ViewState.error, message: '支付失败，请重试');
    }
    return status;
  }

  Future<SubscriptionStatus?> cancel() async {
    state = SubscriptionViewData(viewState: ViewState.loading, status: state.status);
    final status = await ref.read(subscriptionRepositoryProvider).cancel();
    if (status != null) {
      state = SubscriptionViewData(status: status, plans: SubscriptionTier.values.toList());
    }
    return status;
  }

  Future<SubscriptionStatus?> renew({String? idempotencyKey}) async {
    final key = idempotencyKey ?? 'sub-renew-${Random().nextInt(999999)}';
    state = SubscriptionViewData(viewState: ViewState.loading, status: state.status);
    final status = await ref.read(subscriptionRepositoryProvider).renew(key);
    if (status != null) {
      state = SubscriptionViewData(status: status, plans: SubscriptionTier.values.toList());
    }
    return status;
  }
}
```

- [ ] **Step 4: 运行测试确认通过**

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/subscription/ mobile_app/test/features/subscription/subscription_controller_test.dart
git commit -m "feat(subscription): add subscription repository and controller"
```

---

## Task 10：订阅 UI 页面

**Files:**
- Create: `lib/features/subscription/presentation/subscription_plan_page.dart`
- Create: `lib/features/subscription/presentation/subscription_checkout_page.dart`
- Create: `lib/features/subscription/presentation/widgets/tier_card.dart`
- Create: `lib/features/subscription/presentation/widgets/feature_comparison_table.dart`
- Create: `lib/features/subscription/presentation/widgets/usage_progress_bar.dart`

### 目标

实现套餐选择/升级页 + Mock 支付确认页 + 三个子组件。

### 实施步骤

- [ ] **Step 0a: 写 `tier_card` 测试**

```dart
void main() {
  testWidgets('TierCard 显示套餐名和价格', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TierCard(tier: SubscriptionTier.standard))));
    expect(find.text('标准版'), findsOneWidget);
    expect(find.text('¥299'), findsOneWidget);
    expect(find.text('含 200 头'), findsOneWidget);
  });

  testWidgets('TierCard 当前套餐显示"当前套餐"标签', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TierCard(tier: SubscriptionTier.standard, isCurrent: true))));
    expect(find.text('当前套餐'), findsOneWidget);
  });

  testWidgets('TierCard enterprise 显示"联系销售"', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: TierCard(tier: SubscriptionTier.enterprise))));
    expect(find.text('联系销售'), findsOneWidget);
  });
}
```

- [ ] **Step 0b: 写 `feature_comparison_table` 测试**

```dart
testWidgets('FeatureComparisonTable 显示 4 列（4 层级）', (tester) async { ... });
testWidgets('FeatureComparisonTable basic 行正确标记 ✓/✗', (tester) async { ... });
```

- [ ] **Step 0c: 写 `usage_progress_bar` 测试**

```dart
testWidgets('UsageProgressBar 正常用量显示绿色', (tester) async { ... });
testWidgets('UsageProgressBar 超量显示红色', (tester) async { ... });
```

- [ ] **Step 0d: 运行上述测试确认失败**

```bash
cd Mobile/mobile_app && flutter test test/features/subscription/
```

- [ ] **Step 1: 实现 `tier_card.dart`**

套餐卡片组件：显示名称、价格、包含牲畜数、当前标签/推荐标签。企业版特殊处理：

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';  // 需 pubspec.yaml 已有
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class TierCard extends StatelessWidget {
  const TierCard({
    super.key,
    required this.tier,
    this.isCurrent = false,
    this.isSelected = false,
    this.onTap,
  });

  final SubscriptionTier tier;
  final bool isCurrent;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnterprise = tier == SubscriptionTier.enterprise;
    return GestureDetector(
      onTap: isEnterprise
          ? () => launchUrl(Uri.parse('mailto:sales@hktlora.com?subject=企业版订阅咨询&body=您好，我对企业版智慧畜牧系统感兴趣，请提供报价和方案详情。'))
          : onTap,
      child: Container(
        // ... 卡片 UI：名称、价格（enterprise 显示"定制报价"而非价格）、
        //     包含牲畜数（enterprise 显示"无限"）、
        //     isCurrent → "当前套餐"标签、isSelected → 边框高亮
        //     isEnterprise → "联系销售"按钮替代"选择"按钮
      ),
    );
  }
}
```

> **依赖确认**: 项目 `pubspec.yaml` 中已有 `url_launcher` 依赖（若没有则需 `flutter pub add url_launcher`）。

- [ ] **Step 2: 实现 `feature_comparison_table.dart`**

功能对比表：行=feature category，列=tier，支持滚动。

- [ ] **Step 3: 实现 `usage_progress_bar.dart`**

用量进度条：当前使用量 / 套餐限制，超量红色警告。

- [ ] **Step 4: 运行测试确认通过**

- [ ] **Step 5: 实现 `subscription_plan_page.dart`**

全屏页面，无底部导航。包含：
- 当前套餐信息区
- 套餐卡片列表（点击选中）
- 企业版"联系销售"入口
- "取消订阅"底部文字链接（仅 active/trial 状态显示）

- [ ] **Step 6: 实现 `subscription_checkout_page.dart`**

Mock 支付确认页：
- 显示所选套餐和价格
- "确认支付"按钮（500ms Loading → 成功 → 跳转）
- 取消返回按钮

- [ ] **Step 7: 运行 flutter analyze + 测试**

```bash
cd Mobile/mobile_app && flutter analyze && flutter test test/features/subscription/
```

- [ ] **Step 8: 提交**

```bash
git add mobile_app/lib/features/subscription/presentation/
git commit -m "feat(subscription): add plan selection and checkout pages"
```

---

## Task 11：AppRoute + GoRouter 集成

**Files:**
- Modify: `lib/app/app_route.dart`
- Modify: `lib/app/app_router.dart`

### 目标

新增 `subscription` / `checkout` 两个路由，ShellRoute 外部注册，owner 守卫。

### 实施步骤

- [ ] **Step 1: 修改 `lib/app/app_route.dart`**

在现有枚举中添加：

```dart
subscription('/subscription', 'subscription', '订阅管理'),
checkout('/subscription/checkout', 'checkout', '确认支付'),
```

- [ ] **Step 2: 修改 `lib/app/app_router.dart`**

在 `ShellRoute` 之前插入订阅路由树：

```dart
// 订阅路由（ShellRoute 外部，独立全屏页面）
GoRoute(
  path: AppRoute.subscription.path,
  name: AppRoute.subscription.routeName,
  builder: (context, state) => const SubscriptionPlanPage(),
  redirect: (context, state) {
    final role = ref.read(sessionControllerProvider).role;
    if (role != DemoRole.owner) return AppRoute.mine.path;
    return null;
  },
  routes: [
    GoRoute(
      path: 'checkout',
      name: AppRoute.checkout.routeName,
      builder: (context, state) => const SubscriptionCheckoutPage(),
      redirect: (context, state) {
        final role = ref.read(sessionControllerProvider).role;
        if (role != DemoRole.owner) return AppRoute.mine.path;
        return null;
      },
    ),
  ],
),
```

- [ ] **Step 3: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```

- [ ] **Step 4: 提交**

```bash
git add mobile_app/lib/app/app_route.dart mobile_app/lib/app/app_router.dart
git commit -m "feat(subscription): add subscription routes to GoRouter"
```

---

## Task 12：ApiCache 集成

**Files:**
- Modify: `lib/core/api/api_cache.dart`

### 目标

`ApiCache.init()` 新增预加载 `subscription/current` + `subscription/features`；checkout/cancel/renew 后自动重载。

### 实施步骤

- [ ] **Step 1: 新增缓存字段和 getter**

```dart
Map<String, dynamic>? _subscriptionStatus;
List<Map<String, dynamic>> _features = [];

Map<String, dynamic>? get subscriptionStatus => _subscriptionStatus;
List<Map<String, dynamic>> get features => _features;
```

- [ ] **Step 2: `init()` 中新增两个并行请求**

在 `Future.wait` 数组中添加：

```dart
_get('/subscription/current', headers),
_get('/subscription/features', headers),
```

并在结果处理中解析。

- [ ] **Step 3: 新增 `refreshSubscription()` 方法**

```dart
Future<void> refreshSubscription(
  String role, {
  ApiAuthTokens? tokens,
  bool allowMockTokenFallback = false,
}) async {
  final headers = _headers(role, tokens: tokens, allowMockTokenFallback: allowMockTokenFallback, roleTokens: _roleTokens);
  final current = await _get('/subscription/current', headers);
  if (current != null) _subscriptionStatus = current;
  final features = await _get('/subscription/features', headers);
  if (features != null && features['features'] is List) {
    _features = List<Map<String, dynamic>>.from(features['features']);
  }
}
```

- [ ] **Step 4: checkout/cancel/renew 远程方法并触发重载**

```dart
Future<bool> checkoutSubscriptionRemote(String role, String tier, String idempotencyKey) async { ... }
Future<bool> cancelSubscriptionRemote(String role) async { ... }
Future<bool> renewSubscriptionRemote(String role, String idempotencyKey) async { ... }
```

成功后调用 `await init(role, ...)` 完全重载缓存。

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/core/api/api_cache.dart
git commit -m "feat(subscription): add subscription endpoints to ApiCache with reload on state change"
```

---

## Task 13：MinePage 嵌入 SubscriptionStatusCard

**Files:**
- Create: `lib/features/subscription/presentation/subscription_status_card.dart`
- Modify: `lib/features/mine/presentation/mine_controller.dart`
- Modify: `lib/features/mine/presentation/pages/mine_page.dart`（注：实际路径为 `lib/features/pages/mine_page.dart`）

### 目标

"我的"页面嵌入订阅状态卡片，显示当前套餐、到期时间、续费/升级入口。

### 实施步骤

- [ ] **Step 1: 实现 `subscription_status_card.dart`**

```dart
class SubscriptionStatusCard extends ConsumerWidget {
  // 显示：套餐名称 + 价格 + 到期时间 + 状态标签
  // active: 绿色"生效中" + 到期时间
  // trial: 蓝色"试用中" + 试用剩余天数
  // cancelled: 黄色"已取消" + 到期时间
  // expired: 红色"已过期" + 升级按钮
  // 点击 → context.push(AppRoute.subscription.path)
}
```

- [ ] **Step 2: 修改 `mine_controller.dart`**

`MineViewData` 新增 `subscriptionStatus` 字段，Controller 从 Repository 读取。

- [ ] **Step 3: 修改 `mine_page.dart`**

在 `HighfiCard`（账户正常卡片）之后插入 `SubscriptionStatusCard`：

```dart
const SizedBox(height: AppSpacing.md),
const SubscriptionStatusCard(),
```

- [ ] **Step 4: 提交**

```bash
git add mobile_app/lib/features/subscription/presentation/subscription_status_card.dart mobile_app/lib/features/mine/ mobile_app/lib/features/pages/mine_page.dart
git commit -m "feat(subscription): embed SubscriptionStatusCard in MinePage"
```

---

## Task 14：孪生总览页到期提醒横幅 + 登录弹窗

**Files:**
- Create: `lib/features/subscription/presentation/widgets/subscription_renewal_banner.dart`
- Create: `lib/features/subscription/presentation/widgets/subscription_expiry_dialog.dart`
- Modify: `lib/features/pages/twin_overview_page.dart`
- Modify: `lib/main.dart`（登录后弹窗检查）

### 目标

根据 `daysUntilExpiry` 显示不同级别的到期提醒横幅 + 登录后弹窗。

### 实施步骤

- [ ] **Step 1: 写 renewal_banner 测试**

```dart
testWidgets('warning 级别显示黄色横幅', (tester) async {
  final status = SubscriptionStatus(
    tenantId: 't1', tier: SubscriptionTier.standard,
    currentPeriodStart: DateTime.now(), currentPeriodEnd: DateTime.now().add(const Duration(days: 5)),
    status: SubscriptionState.active, livestockCount: 100, calculatedPrice: 29900,
  );
  await tester.pumpWidget(ProviderScope(overrides: [
    subscriptionControllerProvider.overrideWith((ref) => SubscriptionViewData(status: status)),
  ], child: MaterialApp(home: Scaffold(body: SubscriptionRenewalBanner()))));
  expect(find.textContaining('天后到期'), findsOneWidget);
});

testWidgets('normal 级别不显示横幅', (tester) async { ... });
```

- [ ] **Step 2: 运行测试确认失败** → 实现 `subscription_renewal_banner.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/subscription/presentation/subscription_controller.dart';

class SubscriptionRenewalBanner extends ConsumerWidget {
  const SubscriptionRenewalBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(subscriptionControllerProvider);
    final status = data.status;
    if (status == null) return const SizedBox.shrink();

    final level = status.expiryLevel;
    if (level == ExpiryLevel.none) return const SizedBox.shrink();

    final isWarning = level == ExpiryLevel.warning;
    final color = isWarning ? AppColors.warning : AppColors.danger;
    String message;
    switch (level) {
      case ExpiryLevel.warning:
        message = '订阅将于 ${status.daysUntilExpiry} 天后到期';
        break;
      case ExpiryLevel.critical:
        message = '订阅即将到期！仅剩 ${status.daysUntilExpiry} 天';
        break;
      case ExpiryLevel.expired:
        message = '订阅已过期，已降级为基础版';
        break;
      default:
        return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed('/subscription'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: color.withValues(alpha: 0.12),
        child: Row(
          children: [
            Icon(isWarning ? Icons.info_outline : Icons.warning_amber_rounded, color: color, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: TextStyle(color: color, fontSize: 13))),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: 实现 `subscription_expiry_dialog.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

class SubscriptionExpiryDialog extends StatelessWidget {
  const SubscriptionExpiryDialog({super.key, required this.status});
  final SubscriptionStatus status;

  @override
  Widget build(BuildContext context) {
    final isExpired = status.expiryLevel == ExpiryLevel.expired;
    return AlertDialog(
      title: Text(isExpired ? '订阅已过期' : '订阅即将到期'),
      content: Text(isExpired
          ? '您的订阅已过期，已自动降级为基础版（免费）。部分功能已锁定，续费后可立即恢复。'
          : '您的${status.tier.name}订阅还剩 ${status.daysUntilExpiry} 天到期。到期后将自动降级为基础版（免费），部分功能将被锁定。'),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('知道了')),
        if (!isExpired)
          TextButton(
            onPressed: () { Navigator.of(context).pop(); Navigator.of(context).pushNamed('/subscription'); },
            child: const Text('立即续费'),
          ),
      ],
    );
  }
}
```

- [ ] **Step 4: 修改 `twin_overview_page.dart`**

在页面顶部 Column children 最前面添加 `const SubscriptionRenewalBanner()`。

- [ ] **Step 5: 修改 `app_router.dart` 或 `demo_shell.dart` — 登录后弹窗检查**

在 `DemoShell`（`ConsumerWidget`）的 `build` 中添加 listener：

```dart
// 顶层变量（同一 session 内当日不重复，无需 shared_preferences）
String? _lastDismissedDate;

// 在 DemoShell build() 中：
ref.listen(sessionControllerProvider, (prev, next) {
  if (next.isLoggedIn && next.role == DemoRole.owner) {
    Future.delayed(const Duration(milliseconds: 800), () {
      final subData = ref.read(subscriptionControllerProvider);
      final status = subData.status;
      if (status != null && status.daysUntilExpiry <= 7) {
        final now = DateTime.now();
        final todayKey = '${now.year}-${now.month}-${now.day}';
        if (_lastDismissedDate != todayKey) {
          showDialog(
            context: context,
            builder: (_) => SubscriptionExpiryDialog(status: status),
          ).then((_) { _lastDismissedDate = todayKey; });
        }
      }
    });
  }
});
```

此方案使用内存变量 `_lastDismissedDate` 实现当日不重复弹窗，无需引入 `shared_preferences` 等持久化依赖。

- [ ] **Step 5: 提交**

```bash
git add mobile_app/lib/features/subscription/presentation/widgets/subscription_renewal_banner.dart mobile_app/lib/features/subscription/presentation/widgets/subscription_expiry_dialog.dart mobile_app/lib/features/pages/twin_overview_page.dart mobile_app/lib/app/demo_shell.dart mobile_app/test/features/subscription/
git commit -m "feat(subscription): add expiry renewal banner and login popup dialog"
```

---

## Task 15：现有页面 LockedOverlay 适配

**Files:**
- Modify: `lib/features/pages/twin_overview_page.dart`
- Modify: `lib/features/pages/estrus_page.dart`
- Modify: `lib/features/pages/epidemic_page.dart`
- Modify: `lib/features/pages/alerts_page.dart`
- Modify: `lib/features/pages/fence_page.dart`

### 目标

在各页面中根据 API 响应中的 `locked`/`limit` 字段渲染 LockedOverlay。

### 实施步骤

- [ ] **Step 1: 孪生总览页 — 发情/疫病卡片 LockedOverlay**

从 API 响应中读取 `locked` 字段，对 estrus/epidemic 卡片包裹 LockedOverlay。

- [ ] **Step 2: 发情/疫病列表页 — LockedOverlay**

API 响应 `locked: true` → 全页 LockedOverlay。

- [ ] **Step 3: 告警页 — 历史 tab 锁图标**

`alert_history` locked → 历史 Tab 显示锁图标 + Tooltip。

- [ ] **Step 4: 围栏页 — 新建按钮禁用 + limit 提示**

`limit.locked == true` → 新建按钮禁用 + SnackBar 提示。

- [ ] **Step 5: 地图轨迹 — 轨迹按钮 disabled**

`trajectory` locked → 轨迹按钮 disabled + Tooltip。

- [ ] **Step 6: 提交**

```bash
git add mobile_app/lib/features/pages/
git commit -m "feat(subscription): wire LockedOverlay into existing pages"
```

---

## Task 16：Mock 模式兼容

**Files:**
- Modify: `lib/features/subscription/data/mock_subscription_repository.dart`
- Modify: `lib/core/data/demo_seed.dart`

### 目标

Mock 模式下通过 `applyMockShaping()` 函数模拟后端 shaping 规则，确保离线开发也能看到 LockedOverlay。

### 实施步骤

- [ ] **Step 1: 在 `mock_subscription_repository.dart` 中实现 `applyMockShaping()`**

完整 Dart 实现，与后端 `applyShapingRules` 逻辑等价：

```dart
import 'package:smart_livestock_demo/core/models/subscription_tier.dart';

/// Shared mock shaping function — mirrors backend/data/feature-flags.js applyShapingRules
Map<String, dynamic> applyMockShaping(
  Map<String, dynamic> data,
  SubscriptionTier tier,
  List<String> featureKeys, {
  String? filterField,
}) {
  if (featureKeys.isEmpty) return data;
  if (tier == SubscriptionTier.enterprise) return data;

  Map<String, dynamic> result = Map<String, dynamic>.from(data);

  // Phase 1: filter — 按天数截断 items
  int? retentionDays;
  if (featureKeys.contains('data_retention_days')) {
    switch (tier) {
      case SubscriptionTier.basic: retentionDays = 7;
      case SubscriptionTier.standard: retentionDays = 30;
      case SubscriptionTier.premium: retentionDays = 365;
      case SubscriptionTier.enterprise: retentionDays = null;
    }
    if (retentionDays != null && result['items'] is List) {
      final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
      final items = (result['items'] as List).where((item) {
        if (item is! Map<String, dynamic>) return true;
        final ts = item[filterField ?? 'occurredAt'] ?? item['recordedAt'] ?? item['timestamp'] ?? item['createdAt'];
        if (ts == null) return true;
        return DateTime.tryParse(ts.toString())?.isAfter(cutoff) ?? true;
      }).toList();
      result['items'] = items;
      result['total'] = items.length;
    }
  }

  // Phase 2: limit
  if (featureKeys.contains('fence') && tier == SubscriptionTier.basic) {
    final total = result['total'] as int? ?? 0;
    result['limit'] = {
      'maxCount': 3,
      'locked': total >= 3,
      'message': '基础版最多 3 个围栏，升级标准版解锁更多',
    };
  }
  if (featureKeys.contains('dashboard_summary') && tier == SubscriptionTier.basic) {
    final metrics = result['metrics'] as List?;
    if (metrics != null) {
      result['metrics'] = metrics.where((m) {
        final key = (m as Map<String, dynamic>)['key'] as String?;
        return ['livestockCount', 'deviceOnlineRate', 'todayAlerts'].contains(key);
      }).toList();
    }
  }

  // Phase 3: lock
  const lockFlags = {
    'trajectory': SubscriptionTier.standard,
    'estrus_detect': SubscriptionTier.premium,
    'epidemic_alert': SubscriptionTier.premium,
    'health_score': SubscriptionTier.premium,
    'gait_analysis': SubscriptionTier.enterprise,
    'behavior_stats': SubscriptionTier.enterprise,
    'api_access': SubscriptionTier.enterprise,
    'alert_history': SubscriptionTier.standard,
    'dedicated_support': SubscriptionTier.premium,
  };

  for (final key in featureKeys) {
    final minTier = lockFlags[key];
    if (minTier != null && tier.index < minTier.index) {
      final names = {
        'trajectory': '历史轨迹',
        'estrus_detect': '发情检测',
        'epidemic_alert': '疫病预警',
        'health_score': '健康评分',
        'gait_analysis': '步态分析',
        'behavior_stats': '行为统计',
        'api_access': 'API 访问',
        'alert_history': '告警历史查询',
        'dedicated_support': '专属客服支持',
      };
      result = {
        ...result,
        'locked': true,
        'upgradeTier': minTier.name,
        'message': '${names[key] ?? key}需要${minTier.name}版及以上',
        'items': <Map<String, dynamic>>[],
        'total': 0,
      };
    }
  }

  return result;
}
```

- [ ] **Step 2: 在各 Mock Repository 返回数据前调用**

`MockTwinRepository.loadEstrusList()` 示例：

```dart
@override
TwinEstrusViewData loadEstrusList() {
  final raw = DemoSeed.estrusList;
  final shaped = applyMockShaping(
    {'items': raw, 'total': raw.length},
    _currentTier,
    ['estrus_detect'],
  );
  return TwinEstrusViewData.fromShaped(shaped);
}
```

`MockFenceRepository` — 在 `loadList()` 中：

```dart
final shaped = applyMockShaping(
  {'items': fences, 'total': fences.length},
  _currentTier,
  ['fence'],
);
```

`MockAlertsRepository` — 在 `loadList()` 中：

```dart
final shaped = applyMockShaping(
  {'items': alerts, 'total': alerts.length},
  _currentTier,
  ['data_retention_days', 'alert_history'],
  filterField: 'occurredAt',
);
```

`MockDashboardRepository` — 在 `loadSummary()` 中：

```dart
final shaped = applyMockShaping(
  {'metrics': metrics},
  _currentTier,
  ['dashboard_summary'],
);
```

其中 `_currentTier` 从 `MockSubscriptionRepository` 读取，默认 `SubscriptionTier.basic`。

- [ ] **Step 3: `demo_seed.dart` 新增订阅假数据**

默认 tier=basic，对齐后端 seed。

- [ ] **Step 4: 提交**

```bash
git add mobile_app/lib/features/subscription/data/mock_subscription_repository.dart mobile_app/lib/core/data/demo_seed.dart mobile_app/lib/features/twin/data/ mobile_app/lib/features/alerts/data/ mobile_app/lib/features/fence/data/
git commit -m "feat(subscription): add Mock mode shaping compatibility"
```

---

## Task 17：前端全量测试 + Flutter Analyze

**Files:**
- Create: `test/features/subscription/tier_visibility_test.dart`
- Create: `test/features/subscription/subscription_checkout_flow_test.dart`
- Create: `test/features/subscription/subscription_cancel_flow_test.dart`
- Create: `test/features/subscription/subscription_renewal_reminder_test.dart`

### 目标

补齐前端全部测试，确保 `flutter analyze` + `flutter test` 通过。

### 实施步骤

- [ ] **Step 1: 实现 `tier_visibility_test.dart`**

验证 basic 用户孪生页面：发热/消化正常、发情/疫病有锁。

- [ ] **Step 2: 实现 `subscription_checkout_flow_test.dart`**

验证支付流程：选择套餐 → 确认 → loading → 成功 → 状态更新。

- [ ] **Step 3: 实现 `subscription_cancel_flow_test.dart`**

验证取消流程：确认弹窗 → 取消 → status='cancelled'。

- [ ] **Step 4: 实现 `subscription_renewal_reminder_test.dart`**

验证到期提醒：7 天 warning、3 天 critical、0 天 expired。

- [ ] **Step 5: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```

Expected: No issues found.

- [ ] **Step 6: 运行全部测试**

```bash
cd Mobile/mobile_app && flutter test
```

Expected: All tests pass.

- [ ] **Step 7: 提交**

```bash
git add mobile_app/test/features/subscription/
git commit -m "test(subscription): add tier visibility, checkout/cancel flow, and renewal reminder tests"
```

---

## Task 18：最终验证

### 目标

端到端验证：前后端联动正常，Mock Server + Flutter App 可运行。

### 实施步骤

- [ ] **Step 1: 运行后端全部测试**

```bash
cd Mobile/backend && node --test test/
```

- [ ] **Step 2: 运行前端全部测试 + analyze**

```bash
cd Mobile/mobile_app && flutter analyze && flutter test
```

- [ ] **Step 3: 启动 Mock Server 验证端点**

```bash
cd Mobile/backend && node server.js &
curl http://localhost:3001/api/subscription/current -H "Authorization: Bearer mock-token-owner"
curl http://localhost:3001/api/subscription/plans -H "Authorization: Bearer mock-token-owner"
curl http://localhost:3001/api/subscription/features -H "Authorization: Bearer mock-token-owner"
curl http://localhost:3001/api/twin/estrus/list -H "Authorization: Bearer mock-token-owner"
```

Expected: subscription/current 返回 basic tier；estrus/list 返回 locked:true。

- [ ] **Step 4: 提交（如有遗漏的修改）**

```bash
git status
git add ... && git commit -m "chore(subscription): final verification fixes"
```

---

## 验收标准汇总

| # | 验收项 | 验证方式 |
|---|--------|---------|
| 1 | basic 用户访问发情检测 → locked: true | `curl /api/twin/estrus/list` |
| 2 | basic 用户访问发热监测 → 正常 | `curl /api/twin/fever/list` |
| 3 | basic 用户最多 3 个围栏，第 4 个 locked | `curl /api/fences` |
| 4 | basic 用户告警历史 tab locked | `curl /api/alerts` |
| 5 | basic 用户 dashboard 指标受限 | `curl /api/dashboard/summary` |
| 6 | basic 用户轨迹 locked | `curl /api/map/trajectories` |
| 7 | trial 用户 14 天内正常使用高级功能 | 设置 trial → curl |
| 8 | trial 到期自动降级 basic | 设置过期 trialEndsAt → curl |
| 9 | active 周期到期自动降级 basic | 设置过期 currentPeriodEnd → curl |
| 10 | checkout 升级成功 | `POST /api/subscription/checkout` |
| 11 | cancel 标记 cancelled | `POST /api/subscription/cancel` |
| 12 | renew 恢复 active | `POST /api/subscription/renew` |
| 13 | 新租户自动获得 trial | `POST /api/tenants` |
| 14 | ops 角色所有请求跳过 shaping | ops token → curl |
| 15 | LockedOverlay owner 显示升级按钮 | Widget test |
| 16 | LockedOverlay worker 隐藏升级按钮 | Widget test |
| 17 | 到期 7 天 yellow banner | Widget test |
| 18 | 到期 3 天 red banner | Widget test |
| 19 | 企业版"联系销售"渲染正确 | Widget test |
| 20 | 前端全部测试 + analyze 通过 | `flutter test && flutter analyze` |
| 21 | 后端全部测试通过 | `node --test test/` |
| 22 | Mock 模式 locked/limit 正确注入 | Mock Repository test |

---

**计划完成。请选择执行方式：**

1. **Subagent-Driven（推荐）** — 每个 Task 派发独立 subagent，Task 间 review
2. **Inline Execution** — 当前 session 中按 Task 逐步执行

