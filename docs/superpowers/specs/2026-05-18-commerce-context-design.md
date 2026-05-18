# Commerce 限界上下文设计规格

**日期**: 2026-05-18
**状态**: 已评审通过（第三轮修正，基于架构评审与 Plan 修正）
**范围**: MVP Phase 2 — Commerce 子系统（订阅、合同、分润、Licensed 服务、配额引擎）
**前置**: MVP Phase 1 已完成（Identity + Ranch + IoT 限界上下文）

---

## 1. Commerce 限界上下文定位与核心模型

### 1.1 在 DDD 架构中的位置

```
smart-livestock-server/src/main/java/com/smartlivestock/
├── identity/     ← 已有：Tenant, User, Farm, Role, Auth
├── ranch/        ← 已有：Livestock, Fence, Alert
├── iot/          ← 已有：Device, DeviceLicense, Installation, GpsLog
├── commerce/     ← 新增
│   ├── domain/
│   │   ├── model/
│   │   │   ├── Subscription.java        (聚合根)
│   │   │   ├── SubscriptionTier.java    (值对象枚举)
│   │   │   ├── SubscriptionStatus.java  (值对象枚举)
│   │   │   ├── Contract.java            (聚合根)
│   │   │   ├── ContractStatus.java      (值对象枚举)
│   │   │   ├── RevenuePeriod.java       (聚合根)
│   │   │   ├── RevenueSettlementStatus.java
│   │   │   ├── SubscriptionService.java (聚合根, licensed 专用)
│   │   │   ├── SubscriptionServiceStatus.java
│   │   │   ├── FeatureGate.java         (值对象)
│   │   │   └── event/                   (24 个领域事件)
│   │   └── repository/
│   │       ├── SubscriptionRepository.java
│   │       ├── ContractRepository.java
│   │       ├── RevenuePeriodRepository.java
│   │       ├── SubscriptionServiceRepository.java
│   │       └── FeatureGateRepository.java
│   ├── application/
│   │   ├── service/
│   │   │   ├── SubscriptionApplicationService.java
│   │   │   ├── ContractApplicationService.java
│   │   │   ├── RevenueApplicationService.java
│   │   │   ├── QuotaApplicationService.java
│   │   │   └── UsageResolver.java (接口 + 实现)
│   │   ├── dto/
│   │   │   ├── QuotaResult.java
│   │   │   ├── CheckoutRequest.java
│   │   │   ├── SubscriptionResponse.java
│   │   │   ├── ContractResponse.java
│   │   │   └── RevenuePeriodResponse.java
│   │   ├── scheduler/
│   │   │   └── CommerceScheduler.java (7 个定时任务)
│   │   └── listener/
│   │       └── NotificationEventListener.java
│   ├── infrastructure/
│   │   └── persistence/
│   │       ├── entity/    (5 JPA Entity)
│   │       ├── mapper/    (5 Mapper)
│   │       └── repository/ (5 Spring Data JPA + 4 Impl + 1 FeatureGate Impl)
│   └── interfaces/
│       ├── SubscriptionController.java
│       ├── CommerceController.java
│       ├── AdminSubscriptionController.java
│       ├── AdminContractController.java
│       ├── AdminRevenueController.java
│       ├── AdminServiceController.java
│       ├── AdminFeatureGateController.java
│       ├── QuotaCheck.java (注解)
│       └── QuotaInterceptor.java
├── shared/
│   ├── common/ErrorCode.java (新增 9 个 Commerce 错误码)
│   ├── notification/ (notification 表 Repository + Service)
│   └── domain/ (AggregateRoot + DomainEvent 已有)
```

### 1.2 与现有 Identity 上下文的关系

```
Identity (已有)                       Commerce (新增)
┌──────────────┐                      ┌──────────────────┐
│ Tenant       │ 1 ─────────────── 1 │ Subscription      │
│  .type       │                      │  .tier            │
│  .billingModel│                     │  .billingModel    │  ← 从 Tenant 快照
│              │                      │  .status          │
│              │                      └──────────────────┘
│              │ 1 ──────────── 0..1 │ Contract          │
│              │                      │  .effectiveTier   │
│              │                      │  .revenueShareRatio│
│              │                      └──────────────────┘
│              │ 1 ──────────── 0..* │ RevenuePeriod     │
│              │                      └──────────────────┘
│              │ 1 ──────────── 0..1 │ SubscriptionService│
│              │                      │  .effectiveTier    │
│              │                      │  .deviceQuota      │
└──────────────┘                      └──────────────────┘

feature_gates (全局配置，独立于 tenant)
  └── feature_key + tier → 加载为 FeatureGate 值对象
```

### 1.3 Tenant 模型变更

```java
// Tenant.java 新增字段
private String type;           // rancher | reseller | enterprise | developer
private String billingModel;   // direct | revenue_share | licensed | api_usage
```

| 字段 | 含义 | 值域 |
|------|------|------|
| `type` | 租户在生态中的商业角色 | rancher、reseller、enterprise、developer |
| `billingModel` | 默认计费模式 | direct、revenue_share、licensed、api_usage |

两个维度正交：type 回答"你是谁"，billingModel 回答"怎么收钱"。

---

## 2. 数据库 Schema（Commerce 新增表）

### 2.1 subscriptions

```sql
CREATE TABLE subscriptions (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES tenants(id),
    tier            VARCHAR(20) NOT NULL DEFAULT 'basic',
    billing_model   VARCHAR(20) NOT NULL DEFAULT 'direct',
    status          VARCHAR(30) NOT NULL DEFAULT 'trial',
    billing_cycle   VARCHAR(20) NOT NULL DEFAULT 'monthly',
    started_at      TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ,
    trial_ends_at   TIMESTAMPTZ,
    cancelled_at    TIMESTAMPTZ,
    version         BIGINT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_subscriptions_tenant UNIQUE (tenant_id)
);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_status_expires ON subscriptions(status, expires_at)
    WHERE status IN ('active', 'trial', 'renewal_failed') AND expires_at IS NOT NULL;
```

### 2.2 contracts

```sql
CREATE TABLE contracts (
    id                  BIGSERIAL PRIMARY KEY,
    contract_number     VARCHAR(30) NOT NULL,
    tenant_id           BIGINT NOT NULL REFERENCES tenants(id),
    billing_model       VARCHAR(20) NOT NULL,
    effective_tier      VARCHAR(20) NOT NULL,
    revenue_share_ratio DECIMAL(5,4),
    status              VARCHAR(20) NOT NULL DEFAULT 'draft',
    signed_by           BIGINT REFERENCES users(id),
    signed_at           TIMESTAMPTZ,
    started_at          TIMESTAMPTZ NOT NULL,
    expires_at          TIMESTAMPTZ,
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_contracts_number UNIQUE (contract_number)
);
CREATE INDEX idx_contracts_tenant ON contracts(tenant_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_expires ON contracts(expires_at) WHERE expires_at IS NOT NULL;
```

### 2.3 revenue_periods

```sql
CREATE TABLE revenue_periods (
    id                  BIGSERIAL PRIMARY KEY,
    contract_id         BIGINT NOT NULL REFERENCES contracts(id),
    tenant_id           BIGINT NOT NULL REFERENCES tenants(id),
    period_start        DATE NOT NULL,
    period_end          DATE NOT NULL,
    gross_amount        INTEGER NOT NULL,
    platform_share      INTEGER NOT NULL,
    partner_share       INTEGER NOT NULL,
    revenue_share_ratio DECIMAL(5,4) NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending',
    settled_at          TIMESTAMPTZ,
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_revenue_period UNIQUE (contract_id, period_start)
);
CREATE INDEX idx_revenue_periods_tenant ON revenue_periods(tenant_id);
CREATE INDEX idx_revenue_periods_status ON revenue_periods(status);
```

### 2.4 subscription_services

```sql
CREATE TABLE subscription_services (
    id                      BIGSERIAL PRIMARY KEY,
    tenant_id               BIGINT NOT NULL REFERENCES tenants(id),
    service_name            VARCHAR(100) NOT NULL,
    service_key_prefix      VARCHAR(8),
    service_key_hash        VARCHAR(64) NOT NULL,
    effective_tier          VARCHAR(20) NOT NULL,
    device_quota            INTEGER,
    status                  VARCHAR(20) NOT NULL DEFAULT 'provisioned',
    last_heartbeat_at       TIMESTAMPTZ,
    grace_ends_at           TIMESTAMPTZ,
    started_at              TIMESTAMPTZ NOT NULL,
    expires_at              TIMESTAMPTZ,
    heartbeat_interval_hrs  INTEGER DEFAULT 24,
    grace_period_days       INTEGER DEFAULT 7,
    version                 BIGINT NOT NULL DEFAULT 0,
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_subscription_service_tenant UNIQUE (tenant_id)
);
CREATE INDEX idx_sub_services_status ON subscription_services(status);
```

### 2.5 feature_gates

```sql
CREATE TABLE feature_gates (
    id              BIGSERIAL PRIMARY KEY,
    tier            VARCHAR(20) NOT NULL,
    feature_key     VARCHAR(50) NOT NULL,
    gate_type       VARCHAR(10) NOT NULL,
    limit_value     INTEGER,
    retention_days  INTEGER,
    is_enabled      BOOLEAN DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_feature_gates_tier_feature UNIQUE (tier, feature_key)
);
```

### 2.6 notifications

```sql
CREATE TABLE notifications (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL REFERENCES tenants(id),
    user_id     BIGINT REFERENCES users(id),
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    content     TEXT,
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_tenant_unread ON notifications(tenant_id, is_read) WHERE is_read = FALSE;
```

### 2.7 Tenant 表变更

```sql
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS billing_model VARCHAR(20) DEFAULT 'direct';
UPDATE tenants SET type = 'rancher', billing_model = 'direct' WHERE type IS NULL;
```

### 2.8 表关系图

```
tenants (ALTER: type, billing_model)
  │
  ├── 1:1 ── subscriptions
  │            ├── tier, status, billing_model, billing_cycle
  │            └── trial_ends_at, cancelled_at
  │
  ├── 1:0..1 ── contracts
  │               ├── contract_number (CT-YYYY-NNNN)
  │               ├── billing_model, effective_tier, revenue_share_ratio
  │               ├── status (draft → active → suspended/expired/terminated)
  │               │
  │               └── 1:0..* ── revenue_periods
  │                              ├── period_start, period_end
  │                              ├── gross_amount, platform_share, partner_share
  │                              └── revenue_share_ratio (快照)
  │
  └── 1:0..1 ── subscription_services
                  ├── effective_tier, device_quota
                  ├── service_key_hash (License 验证)
                  └── heartbeat_interval_hrs, grace_period_days

feature_gates (全局配置，独立于 tenant)
  └── feature_key + tier → 4 种 gateType (none/lock/limit/filter)

notifications (事件驱动通知)
  └── tenant_id + user_id → 前端拉取
```

---

## 3. 领域模型与状态机

### 3.1 SubscriptionTier（值对象枚举）

定价统一使用 USD 美分。全部硬编码，后续替换为 API 获取。

```java
public enum SubscriptionTier {
    BASIC(0, 50, 40),           // $0, 50头, 超出 $0.40/头/月
    STANDARD(1400, 200, 30),    // $14, 200头, 超出 $0.30/头/月
    PREMIUM(2800, 1000, 15),    // $28, 1000头, 超出 $0.15/头/月
    ENTERPRISE(-1, -1, -1);     // 定制

    private final int monthlyPriceCents;
    private final int includedLivestock;
    private final int overagePriceCents;

    public int calculateMonthlyFee(int livestockCount) {
        if (this == ENTERPRISE)
            throw new ApiException(ErrorCode.ENTERPRISE_CUSTOM_PRICING,
                "Enterprise 需定制计费，不可自动计算");
        int base = monthlyPriceCents;
        int overflow = Math.max(0, livestockCount - includedLivestock);
        return base + overflow * overagePriceCents;
    }
}
```

### 3.2 Subscription（聚合根）

**字段：**
```
id, tenantId, tier, billingModel, status, billingCycle,
startedAt, expiresAt, trialEndsAt, cancelledAt
```

**状态机：**
```
startTrial(tenantId, startedAt, trialEndsAt) → TRIAL
  │ billingModel 从调用方传入
  │
  ├─ expireTrial() → FREE (tier=BASIC)
  ├─ cancel() → CANCELLED (记录 cancelledAt)
  │
  └─ activate(tier, billingCycle, expiresAt) → ACTIVE
       ├─ changeTier(newTier) (ACTIVE/TRIAL/FREE 均可)
       ├─ suspend() → SUSPENDED → reactivate() → ACTIVE
       ├─ markRenewalFailed() → RENEWAL_FAILED
       │    ├─ recoverFromRenewalFailure() → ACTIVE (MVP 未触发)
       │    └─ downgradeAfterRenewalFailure() → FREE
       ├─ cancel() → CANCELLED (记录 cancelledAt)
       └─ markExpired() → EXPIRED
```

**业务查询：**
```java
public SubscriptionTier effectiveTier() {
    if (isTrialActive()) return SubscriptionTier.PREMIUM;
    return this.tier;
}

public boolean isTrialActive() {
    return status == SubscriptionStatus.TRIAL
        && trialEndsAt != null && trialEndsAt.isAfter(Instant.now());
}

public boolean isActiveOrTrial() {
    return status == SubscriptionStatus.ACTIVE
        || status == SubscriptionStatus.TRIAL
        || status == SubscriptionStatus.FREE;
}
```

**领域事件：**

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| SubscriptionCreatedEvent | `startTrial()` / `activate()` | Identity: TenantPhase SAMPLE→BATCH |
| SubscriptionTierChangedEvent | `changeTier()` / `expireTrial()` / `downgradeAfterRenewalFailure()` | Ranch/IoT: 更新配额缓存 |
| SubscriptionSuspendedEvent | `suspend()` | Ranch/IoT: 限制功能访问 |
| SubscriptionReactivatedEvent | `reactivate()` / `recoverFromRenewalFailure()` | Ranch/IoT: 恢复功能访问 |
| SubscriptionCancelledEvent | `cancel()` | 通知: 告知 owner |
| SubscriptionExpiredEvent | `markExpired()` | Ranch/IoT: 限制功能访问 |

### 3.3 Contract（聚合根）

**字段：**
```
id, tenantId, contractNumber, billingModel, effectiveTier,
revenueShareRatio(BigDecimal), signedBy, signedAt, startedAt, expiresAt, status
```

**状态机：**
```
create(tenantId, contractNumber, billingModel, effectiveTier, ...) → DRAFT
  └─ sign(userId) → ACTIVE
       ├─ suspend() → SUSPENDED → reactivate() → ACTIVE
       ├─ terminate() → TERMINATED
       └─ markExpired() → EXPIRED
```

**业务方法：**
```java
public RevenueShareResult calculateRevenueShare(int grossAmountCents) {
    int partnerShare = revenueShareRatio
        .multiply(BigDecimal.valueOf(grossAmountCents)).intValue();
    return new RevenueShareResult(grossAmountCents - partnerShare, partnerShare);
}

public record RevenueShareResult(int platformShare, int partnerShare) {}
```

**领域事件：**

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| ContractCreatedEvent | `create()` | 无（内部审计） |
| ContractSignedEvent | `sign()` | Identity: 创建 Partner 子 Tenant |
| ContractSuspendedEvent | `suspend()` | 通知: 告知合作方 |
| ContractTerminatedEvent | `terminate()` | 通知: 告知合作方 |
| ContractExpiredEvent | `markExpired()` | 通知: 告知合作方 |

### 3.4 RevenuePeriod（聚合根）

**字段：**
```
id, contractId, tenantId, periodStart, periodEnd,
grossAmount(美分), platformShare(美分), partnerShare(美分),
revenueShareRatio(快照), status, settledAt
```

**状态机：**
```
PENDING → confirmByPlatform() → PLATFORM_CONFIRMED
  → confirmByPartner() → PARTNER_CONFIRMED
  → settle() → SETTLED
```

**领域事件：**

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| RevenuePeriodCreatedEvent | `calculate()` | 通知: 告知合作方有待确认结算 |
| RevenuePlatformConfirmedEvent | `confirmByPlatform()` | 通知: 告知合作方可确认 |
| RevenuePartnerConfirmedEvent | `confirmByPartner()` | 通知: 触发结算 |
| RevenueSettledEvent | `settle()` | 通知: 结算完成通知 |

### 3.5 SubscriptionService（聚合根，Licensed 模式专用）

**字段：**
```
id, tenantId, serviceName, serviceKeyPrefix, serviceKeyHash,
effectiveTier, deviceQuota,
status, lastHeartbeatAt, graceEndsAt, startedAt, expiresAt,
heartbeatIntervalHrs(实例字段, 默认24), gracePeriodDays(实例字段, 默认7)
```

**MVP 激活机制：离线 License 文件。**

provision() 时生成 License 文件（JWT，含 tenantId + effectiveTier + deviceQuota + 有效期 + RSA 签名）。activate() 时验证 License 文件签名。在线心跳机制延后实现。

**状态机（完整定义，MVP 部分触发）：**
```
provision(tenantId, serviceName, rawServiceKey, tier, deviceQuota) → PROVISIONED
  → activate(expiresAt) → ACTIVE (验证 License 文件签名)
     ├─ recordHeartbeat() (MVP 未触发)
     ├─ checkHeartbeat() → GRACE_PERIOD (MVP 未触发)
     │    ├─ recordHeartbeat() → ACTIVE (恢复, MVP 未触发)
     │    └─ degrade() → DEGRADED (MVP 未触发)
     ├─ revoke() → EXPIRED
     ├─ expire() → EXPIRED (MVP: 定时任务检查 License 文件到期)
     └─ adjustQuota(newQuota)
```

**领域事件：**

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| ServiceActivatedEvent | `activate()` | 通知: 服务上线 |
| ServiceHeartbeatLostEvent | `checkHeartbeat()` | 通知: 运维告警 |
| ServiceHeartbeatRecoveredEvent | GRACE_PERIOD 中 `recordHeartbeat()` | 通知: 关闭告警工单 |
| ServiceDegradedEvent | `degrade()` | Ranch/IoT: 配额降为 BASIC |
| ServiceQuotaAdjustedEvent | `adjustQuota()` | Ranch/IoT: 更新配额缓存 |
| ServiceRevokedEvent | `revoke()` / `expire()` | Ranch/IoT: 停止服务 |

---

## 4. 配额引擎与 API 端点

### 4.1 配额引擎架构

```
HTTP Request
    │
    ▼
JwtAuthenticationFilter → 设置 TenantContext
    │
    ▼
FarmScopeInterceptor → 验证 farm 归属，设置 farmId
    │
    ▼
QuotaInterceptor
    │ 1. 从 request 提取 tenantId, farmId (纯值，不出 interfaces 层)
    │ 2. QuotaApplicationService.checkQuota(tenantId, featureKey, usage)
    │    ├─ 第一道：订阅是否活跃？(TRIAL/ACTIVE/FREE → 放行)
    │    └─ 第二道：门控规则是否允许？(feature_gates 校验)
    │ 3. 超出 → 403 QUOTA_EXCEEDED
    ▼
Controller / Service
```

### 4.2 QuotaApplicationService

```java
public class QuotaApplicationService {
    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;

    public QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage) {
        // 第一道：订阅状态检查
        Subscription sub = subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new ApiException(ErrorCode.SUBSCRIPTION_NOT_FOUND));
        if (!sub.isActiveOrTrial()) {
            return QuotaResult.denied("订阅状态非活跃: " + sub.getStatus());
        }

        // 第二道：门控规则
        FeatureGate gate = loadGate(featureKey, sub.effectiveTier());
        return switch (gate.getGateType()) {
            case "none" -> QuotaResult.allowed();
            case "lock" -> gate.isEnabled()
                ? QuotaResult.allowed()
                : QuotaResult.denied("功能 " + featureKey + " 当前 Tier 不可用");
            case "limit" -> currentUsage < gate.getLimitValue()
                ? QuotaResult.allowed()
                : QuotaResult.denied("已达到上限 " + gate.getLimitValue() + "，当前: " + currentUsage);
            case "filter" -> QuotaResult.allowedWithRetention(gate.getRetentionDays());
        };
    }

    public int getRetentionDays(SubscriptionTier tier, String featureKey) {
        // filter 类型专用，供查询层裁剪数据范围
    }
}
```

### 4.3 三种 gateType 各归其位

| gateType | 拦截时机 | 执行方式 |
|----------|---------|---------|
| lock | 请求时 | QuotaInterceptor 拦截 |
| limit | 请求时 | QuotaInterceptor 拦截 |
| filter | 查询时 | Application Service 调用 `getRetentionDays()` 裁剪 |

### 4.4 UsageResolver

```java
public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, Long farmId);
}
```

| Resolver | featureKey | 粒度 | 数据源 |
|----------|-----------|------|--------|
| FenceUsageResolver | fence_management | farm | ranch.fences |
| LivestockUsageResolver | livestock_management | farm | ranch.livestock |

### 4.5 API 端点

#### App API — `/api/v1/`（9 个端点）

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/subscription` | 查看订阅状态 + Tier + 用量 | 认证用户 |
| GET | `/subscription/plans` | 查看 Tier 定价信息 | 认证用户 |
| POST | `/subscription/checkout` | 发起订阅（MVP: Mock 支付） | owner |
| PUT | `/subscription/tier` | 升降级 Tier | owner |
| POST | `/subscription/cancel` | 取消订阅 | owner |
| GET | `/subscription/usage` | 用量 vs 配额对比 | 认证用户 |
| GET | `/contracts/me` | 查看自己的合同 | reseller/enterprise |
| GET | `/revenue/periods` | 查看分润记录 | reseller |
| POST | `/revenue/periods/{id}/confirm` | Partner 确认结算 | reseller |

#### Admin API — `/api/v1/admin/`（21 个端点）

**订阅管理（AdminSubscriptionController，3 个）：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/subscriptions` | 列表（支持 status/tier 过滤+分页） |
| GET | `/admin/subscriptions/{id}` | 详情 |
| PUT | `/admin/subscriptions/{id}/status` | 变更状态（targetStatus + reason） |

**合同管理（AdminContractController，6 个）：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/contracts` | 列表 |
| POST | `/admin/contracts` | 创建合同草稿 |
| GET | `/admin/contracts/{id}` | 详情 |
| PUT | `/admin/contracts/{id}` | 修改草稿 |
| POST | `/admin/contracts/{id}/sign` | 签署合同 |
| PUT | `/admin/contracts/{id}/status` | 状态变更 |

**分润结算（AdminRevenueController，5 个）：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/revenue/periods` | 列表 |
| GET | `/admin/revenue/periods/{id}` | 详情 |
| POST | `/admin/revenue/calculate` | 触发月度分润计算（幂等） |
| POST | `/admin/revenue/periods/{id}/confirm` | 平台确认结算 |
| POST | `/admin/revenue/periods/{id}/recalculate` | 重新计算 |

**Licensed 服务管理（AdminServiceController，5 个）：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/subscription-services` | 列表 |
| POST | `/admin/subscription-services` | 新建（生成 License 文件） |
| GET | `/admin/subscription-services/{id}` | 详情 |
| PUT | `/admin/subscription-services/{id}/status` | 状态变更 |
| PUT | `/admin/subscription-services/{id}/quota` | 调整设备配额 |

**功能门控配置（AdminFeatureGateController，2 个）：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/feature-gates` | 列表 |
| PUT | `/admin/feature-gates/{id}` | 修改配置 |

#### Ranch 现有 Controller 修改

| Controller | 修改 |
|-----------|------|
| FenceController | `createFence()` 加 `@QuotaCheck(feature = "fence_management")` |
| LivestockController | `registerLivestock()` 加 `@QuotaCheck(feature = "livestock_management")` |

### 4.6 端到端流程

**场景 1: B2C 直订阅**

1. 用户注册 → Identity 创建 Tenant (type=rancher, billingModel=direct)
2. Commerce 自动创建 Subscription (status=TRIAL, tier=PREMIUM, trialEndsAt=now+14d)
3. 14 天后 TrialExpiryJob → expireTrial() → FREE, tier=BASIC
4. 用户选择 Standard → POST /subscription/checkout (Mock 支付)
5. 支付成功 → activate(STANDARD, "monthly", expiresAt) → ACTIVE
6. 用户升级 → PUT /subscription/tier → changeTier(PREMIUM)
7. 订阅到期 → markRenewalFailed() → 7 天宽限期
   ├─ 宽限期内补缴 → recoverFromRenewalFailure() → ACTIVE
   └─ 宽限期结束 → downgradeAfterRenewalFailure() → FREE

**场景 2: B2B 分润**

1. Admin 创建 Partner Tenant (type=reseller, billingModel=revenue_share)
2. Admin 创建合同草稿 → POST /admin/contracts → DRAFT
3. Admin 签署合同 → POST /admin/contracts/{id}/sign → ACTIVE
4. 每月 1 日 RevenueCalculationJob → 过滤 ACTIVE 合同
   → 计算分润 → 生成 RevenuePeriod (PENDING)
5. Platform 确认 → confirmByPlatform() → PLATFORM_CONFIRMED
6. Partner 确认 → confirmByPartner() → PARTNER_CONFIRMED
7. 系统结算 → settle() → SETTLED

**场景 3: Licensed 独立部署**

1. Admin 创建 Enterprise Tenant (type=enterprise, billingModel=licensed)
2. Admin 创建 SubscriptionService → provision() → 生成 License 文件
3. 客户拿到 License 文件集成到自己的系统
4. Admin 激活 → activate() → ACTIVE
5. LicenseExpiryJob 检查文件到期 → expire() → EXPIRED

### 4.7 定时任务

| Job | 频率 | 逻辑 |
|------|------|------|
| TrialExpiryJob | 每小时 | status=TRIAL AND expires_at < now → expireTrial() |
| SubscriptionExpiryJob | 每小时 | status=ACTIVE AND expires_at < now → markRenewalFailed()（7 天宽限期） |
| RenewalFailedExpiryJob | 每天 2:00 | status=RENEWAL_FAILED 超过 7d → downgradeAfterRenewalFailure() |
| HeartbeatCheckJob | 每 6 小时 | ACTIVE 的 SubscriptionService → checkHeartbeat()（MVP 未触发，预留） |
| LicenseExpiryJob | 每天 4:00 | 检查 License 文件是否到期 → expire() |
| ContractExpiryJob | 每天 5:00 | ACTIVE AND expires_at < now → markExpired() |
| RevenueCalculationJob | 每月 1 日 3:00 | ACTIVE 合同 → 计算分润 → 生成 RevenuePeriod |

---

## 5. 领域事件发布机制

### 5.1 发布流程

```
聚合根.registerEvent(DomainEvent)
    ↓
ApplicationService.save(aggregate)
    ↓
Spring ApplicationEventPublisher.publishEvent(domainEvent)
    ↓
NotificationEventListener (同步，同事务内)
    ├─ 写入 notification 表
    └─ 跨上下文 ApplicationListener (Identity/Ranch/IoT)
```

### 5.2 全部 24 个事件

见 Section 3 各聚合根的事件表。

### 5.3 RocketMQ

MVP 不引入。单体应用内 Spring ApplicationEvent 足够。微服务拆分时替换传输层，24 个事件定义不变。

---

## 6. Tier 定价参考

| Tier | 月费 | 含牲畜数 | 超出费用 | 数据保留 | SLA |
|------|------|---------|---------|---------|-----|
| basic | $0 | 50 头 | $0.40/头/月 | 7 天 | 99.5% |
| standard | $14 | 200 头 | $0.30/头/月 | 30 天 | 99.5% |
| premium | $28 | 1000 头 | $0.15/头/月 | 90 天 | 99.9% |
| enterprise | 定制 | 无限 | — | 3 年 | 99.99% |

---

## 7. ErrorCode

Commerce 新增 9 个：

```java
ENTERPRISE_CUSTOM_PRICING,     // Enterprise 不走自动计费
INVALID_BILLING_MODEL,         // 无效的 billingModel
INVALID_REVENUE_SHARE_RATIO,   // 分润比例不在 0~1
SUBSCRIPTION_NOT_FOUND,        // 租户无订阅记录
SUBSCRIPTION_NOT_ACTIVE,       // 订阅非活跃状态
CONTRACT_NOT_ACTIVE,           // 合同非生效状态
SERVICE_KEY_MISMATCH,          // License 签名校验失败
SERVICE_LICENSE_EXPIRED,       // License 文件已过期
SETTLEMENT_DUPLICATE_CONFIRM,  // 重复确认结算
```

复用已有：`QUOTA_EXCEEDED`、`LICENSE_EXPIRED`、`STATE_CONFLICT`。

---

*设计规格版本: 2026-05-18 v3（架构评审修正版）*
*评审记录: `docs/superpowers/reviews/2026-05-18-Commerce-架构评审与Plan修正.md`*
*实施计划: `docs/superpowers/plans/2026-05-18-commerce-context-plan.md`*

---

## 附录：延后事项

| 事项 | 说明 | 触发条件 |
|------|------|---------|
| TenantPhase 重命名 | SAMPLE/BATCH → TRIAL/ACTIVE | 团队统一后 |
| 合同续签关联 | 加 parent_contract_id | B2B 客户有续签需求时 |
| 账单明细模型 | BillingDetail 表 | 需向牧场主展示月度账单明细时 |
| 真实支付集成 | Mock → 支付宝/微信支付 | 商业化上线时 |
| 在线心跳机制 | License 文件 → 在线验证 | 有外网的私有云/混合云部署 |
| 定价 API | 硬编码 → 外部定价服务 | 多币种/动态定价需求 |
| Redis 配额缓存 | DB 直查 → Redis 缓存 | 高并发场景 |
| 分布式锁 | 单实例 → @SchedulerLock | 多实例部署 |
| RocketMQ 事件总线 | Spring Event → RocketMQ | 微服务拆分 |
