# Commerce 配额引擎与 API 端点（Section 4）设计评审

**评审对象**: Section 4 — 配额引擎与 API 端点
**日期**: 2026-05-18

---

## 一、总体评价

配额引擎架构（拦截器+注解+服务层）设计合理，API 端点覆盖 App 和 Admin 双场景，生命周期端到端流程完整，定时任务覆盖全面。以下为需调整和建议优化的项目。

---

## 二、需修改

### 2.1 FREE 状态下 changeTier() 不可用

**现状**: Section 3 中 changeTier() 的 requireStatus 只允许 ACTIVE 和 TRIAL，FREE 不在允许列表
**问题**: 场景 1 流程中 Trial → FREE → 付费升级，changeTier() 会抛异常
**建议**: requireStatus 加上 FREE

```java
public void changeTier(SubscriptionTier newTier) {
    requireStatus(SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL, SubscriptionStatus.FREE);
    // ...
}
```

或新增 upgradeFromFree() 方法，语义更明确。

### 2.2 Trial effectiveTier 硬编码 Premium

**现状**: QuotaApplicationService 中硬编码 `Trial = Premium`
**问题**: Trial 策略变化时需改代码
**建议**: 改为配置驱动，在 Subscription 上统一处理

```java
// Subscription 中
public SubscriptionTier effectiveTier() {
    if (isTrialActive()) return SubscriptionTier.PREMIUM; // 或从配置读取
    return this.tier;
}
```

长期可从 feature_gates 或 application.yml 读取 Trial 对应的 effective tier。

---

## 三、建议修改

### 3.1 配额超限应返回 403 而非 429

**现状**: QuotaInterceptor 超限返回 HTTP 429
**问题**: 429 语义是"Too Many Requests"（限流），配额超限不是频率问题
**建议**: 返回 403 Forbidden + 业务码 QUOTA_EXCEEDED，语义更准确

```java
response.setStatus(403);
response.getWriter().write("{\"code\":\"QUOTA_EXCEEDED\",\"message\":\"" + result.getDenyReason() + "\"}");
```

### 3.2 resolveUsage 需定义 UsageResolver 接口

**现状**: 注释写"委托给 UsageResolver"，但未定义接口
**问题**: 不同 feature 的用量来源不同（围栏数查 ranch，牲畜数查 ranch，设备数查 iot），缺少统一的查询抽象
**建议**: 至少定义接口，并明确统计粒度（tenant 级 vs farm 级）

```java
public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, HttpServletRequest request);
}
```

当前 FarmScopeInterceptor 已设置 farm 上下文，围栏/牲畜配额应明确是 farm 级还是 tenant 级。

### 3.3 subscription/checkout 缺幂等机制

**现状**: POST /subscription/checkout 无幂等参数
**问题**: 订阅支付是金融操作，POST 不幂等，可能重复扣费
**建议**: 请求体中至少要求传 `idempotency_key`，接口设计预留

```json
{
    "tier": "standard",
    "billingCycle": "monthly",
    "idempotencyKey": "uuid-xxx"
}
```

MVP 阶段 Mock 支付可简单处理，但接口应预留。

### 3.4 PUT /admin/subscriptions/{id}/status 过于宽泛

**现状**: 一个 PUT 接口覆盖所有状态变更
**问题**: 缺少状态机校验的显式表达，容易产生非法跳转
**建议**: 拆分为独立操作，或在请求体中明确 target status + reason

```json
PUT /admin/subscriptions/{id}/status
{
    "targetStatus": "suspended",
    "reason": "欠费暂停"
}
```

后端校验状态机合法性，非法跳转返回 409。

### 3.5 RevenueCalculationJob 需过滤合同状态

**现状**: 定时任务遍历合同计算分润，未提及合同状态过滤
**问题**: 可能对 EXPIRED/TERMINATED/SUSPENDED 的合同也生成 RevenuePeriod
**建议**: 计算前过滤 status=ACTIVE 的合同，Partner 旗下子 Tenant 的订阅状态也应纳入校验

---

## 四、确认无问题的部分

| 模块 | 评价 |
|------|------|
| QuotaInterceptor 拦截链位置 | 在 Auth + FarmScope 之后，职责链正确 |
| @QuotaCheck 注解设计 | 声明式注解，对业务代码零侵入 |
| QuotaResult 三态设计 | allowed/denied/allowedWithRetention 覆盖完整 |
| API 端点分类 | App API + Admin API 分离清晰 |
| 场景 2 B2B 分润流程 | 七步端到端流程完整 |
| 场景 3 Licensed 心跳流程 | provision→heartbeat→grace→degrade 链路完整 |
| 定时任务设计 | 五个 Job 覆盖所有过期/心跳/结算场景 |

---

## 五、评审结论

| 严重度 | 项目 | 位置 |
|--------|------|------|
| 需修改 | FREE 状态下 changeTier() 不可用 | 2.1 |
| 需修改 | Trial effectiveTier 硬编码 | 2.2 |
| 建议改 | 429 改为 403 + 业务码 | 3.1 |
| 建议改 | 定义 UsageResolver 接口 | 3.2 |
| 建议改 | checkout 加幂等参数 | 3.3 |
| 建议改 | PUT status 拆分或加 target+reason | 3.4 |
| 建议改 | RevenueCalculationJob 过滤合同状态 | 3.5 |
