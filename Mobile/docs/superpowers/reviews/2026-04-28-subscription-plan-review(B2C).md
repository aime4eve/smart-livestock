# SaaS 订阅服务实施计划 — 评审

**评审日期**: 2026-04-28
**评审文件**: `docs/superpowers/plans/2026-04-27-subscription-service-implementation(B2C).md`
**对照规格**: `docs/superpowers/specs/2026-04-24-subscription-service-design(B2C).md`

## 总体评价

计划整体**覆盖了规格需求的约 95%**。18 个 Task 划分合理，TDD 流程完整，文件结构与规格一致。以下按严重程度列出问题。

---

## 缺陷（必须修复）

### 1. Trial 取消未立即降级

**位置**: Task 2 `backend/data/subscriptions.js` — `cancel()` 函数

**问题**: 规格明确要求："试用取消立即生效（无当前周期），直接降级为基础版（status='expired'）"。但计划的 `cancel()` 统一设置 `status: 'cancelled'`，未区分 trial 状态：

```javascript
function cancel(tenantId) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return null;
  sub.status = 'cancelled';  // ❌ trial 用户应为 'expired' + tier='basic'
  return { ...sub };
}
```

**修复**: 增加 trial 判断分支：

```javascript
function cancel(tenantId) {
  const sub = subscriptions.get(tenantId);
  if (!sub) return null;
  if (sub.status === 'trial') {
    sub.status = 'expired';
    sub.tier = 'basic';
    sub.calculatedPrice = 0;
    sub.trialEndsAt = null;
  } else {
    sub.status = 'cancelled';
  }
  return { ...sub };
}
```

---

### 2. MockSubscriptionRepository 传 null 给非空字段

**位置**: Task 9 `lib/features/subscription/data/mock_subscription_repository.dart`

**问题**: `SubscriptionStatus` 模型中 `currentPeriodStart`/`currentPeriodEnd` 是 `required DateTime`（非空），但 Mock 实现传了 `null`：

```dart
SubscriptionStatus(
  tenantId: 'tenant_001',
  tier: SubscriptionTier.basic,
  currentPeriodStart: null,  // ❌ 编译错误
  currentPeriodEnd: null,    // ❌ 编译错误
  ...
);
```

**修复**: 传入实际日期值：

```dart
SubscriptionStatus(
  tenantId: 'tenant_001',
  tier: SubscriptionTier.basic,
  currentPeriodStart: DateTime.now(),
  currentPeriodEnd: DateTime.now().add(const Duration(days: 30)),
  status: SubscriptionState.active,
  livestockCount: 50,
  calculatedPrice: 0,
);
```

---

### 3. 到期自动降级使用 checkout() 创建了错误的 30 天周期

**位置**: Task 3 `backend/middleware/feature-flag.js` — `shapingMiddleware` 降级逻辑

**问题**: 计划中 shaping 中间件的到期降级调用了 `checkout()`：

```javascript
if (needDowngrade) {
  const { checkout } = require('../data/subscriptions');
  sub = checkout(tenantId, 'basic', sub.livestockCount);  // ❌ periodEnd = now + 30天
  sub.status = 'expired';
  const { subscriptions } = require('../data/subscriptions');
  subscriptions.set(tenantId, sub);
}
```

`checkout()` 会将 `currentPeriodEnd` 设为 30 天后，但过期降级用户不应获得新的 30 天周期。

**修复**: 直接修改原对象，不调用 `checkout()`：

```javascript
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
```

---

## 差距（建议补充）

### 4. Usage 端点缺少围栏数和数据量统计

**位置**: Task 2 `backend/data/subscriptions.js` — `getUsage()` 函数

**问题**: 规格要求 usage 返回"牲畜数/围栏数/数据量 vs 套餐限制"，但计划仅返回牲畜数：

```javascript
function getUsage(tenantId) {
  return {
    livestock: { used, limit, isUnlimited },
    // ❌ 缺少 fence count 和 data volume
  };
}
```

**建议**: 补充 `fences` 和 `dataUsage` 字段，或在范围界定中明确标注 MVP 仅含牲畜数。若选择后者，在 "本计划不覆盖" 中添加一行说明。

---

### 5. applyMockShaping() 缺实现细节

**位置**: Task 16 `lib/features/subscription/data/mock_subscription_repository.dart`

**问题**: 计划仅给出了函数签名，未提供与后端 `applyShapingRules` 等价的 Dart 实现。各 `MockXxxRepository` 如何调用也未说明。

**建议**: 补充核心管道逻辑的 Dart 实现，至少包含：
- filter 天数截断（按 `occurredAt`/`recordedAt` 字段过滤）
- limit 注入（`{ maxCount, locked, message }`）
- lock 注入（`{ locked: true, upgradeTier, message, items: [], total: 0 }`）

---

### 6. health_score Feature Flag 未关联任何路由

**位置**: Task 1 `backend/data/feature-flags.js` + Task 5 路由注册

**问题**: `health_score` 定义了 `minTier: 'premium'`，但 twin 路由中没有端点使用它作为 feature key。规格的"对现有端点的影响"表中也未列出对应端点。

**建议**: 在计划范围界定中注明 `health_score`、`gait_analysis`、`behavior_stats`、`api_access`、`dedicated_support` 为"已定义但未关联端点，预留未来使用"。

---

### 7. 企业版 mailto 链接实现细节缺失

**位置**: Task 10 `lib/features/subscription/presentation/widgets/tier_card.dart`

**问题**: 规格要求"邮件发送订阅需求至 sales@hktlora.com"，计划范围界定提到 mailto 但未在 TierCard 实现步骤中体现。

**建议**: 在 `TierCard` 的 enterprise 分支中补充点击处理：

```dart
onTap: () => launchUrl(Uri.parse('mailto:sales@hktlora.com?subject=企业版订阅咨询')),
```

并在文件头部添加 `import 'package:url_launcher/url_launcher.dart';`（需确认项目是否已有该依赖）。

---

## 覆盖率确认

| 规格模块 | 计划覆盖 |
|---------|---------|
| 四层订阅 + 混合计费 | ✅ |
| 20 个 Feature Flags | ✅ 全部定义 |
| 响应塑造（res.ok 包装） | ✅ |
| 4 种 Shaping 策略 + 管道顺序（filter→limit→lock） | ✅ |
| 7 个订阅 API 端点 | ✅ |
| 到期自动降级（trial/active/cancelled） | ✅（有缺陷 #3）|
| 试用 14 天 + 到期检测 | ✅ |
| 幂等性 key 防护（内存 Map + 5min TTL） | ✅ |
| ops 绕过 | ✅ |
| LockedOverlay 组件（owner/worker 区分） | ✅ |
| 两层权限体系（Role + Subscription） | ✅ |
| 前端路由新增 + owner 守卫 | ✅ |
| ApiCache 预加载 + checkout 后重载 | ✅ |
| Mock 模式兼容（applyMockShaping） | ✅（有差距 #5）|
| 到期提醒横幅（warning/critical/expired） | ✅ |
| 登录弹窗（当日不重复） | ✅ |
| 降级数据保留策略 | ✅ |
| 后端测试（unit + integration） | ✅ |
| 前端测试（unit + widget + flow） | ✅ |
| Trial 取消流程 | ⚠️（有缺陷 #1）|
| Usage 端点完整性 | ⚠️（有差距 #4）|

**结论**: 修复 3 个缺陷后可开始执行，4 个差距可在实施中补充。建议在计划文件中直接标注修复点。
