# Commerce 限界上下文设计规格

**日期**: 2026-05-18
**状态**: 已实施完成（2026-05-22 通过端到端验证，18/18 PASS）
**范围**: MVP Phase 2 — Commerce 子系统（订阅、合同、分润、Licensed 服务、配额引擎）
**前置**: MVP Phase 1 已完成（Identity + Ranch + IoT 限界上下文）
**架构评审**: `docs/superpowers/reviews/2026-05-18-项目总体技术架构评审.md` (v2)
**实现复核**: 2026-06-26 按实际代码实现修正结构/类名/集成（v7），见附录 B

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
│   │   │   ├── SubscriptionTier.java    (枚举，含定价策略)
│   │   │   ├── SubscriptionStatus.java  (枚举)
│   │   │   ├── Contract.java            (聚合根)
│   │   │   ├── ContractStatus.java      (枚举)
│   │   │   ├── RevenuePeriod.java       (聚合根)
│   │   │   ├── RevenueSettlementStatus.java (枚举)
│   │   │   ├── SubscriptionService.java (聚合根, licensed 专用)
│   │   │   ├── SubscriptionServiceStatus.java (枚举)
│   │   │   ├── FeatureGate.java         (实体，extends Entity，非聚合根)
│   │   │   ├── GateType.java            (枚举: NONE/LOCK/LIMIT/FILTER)
│   │   │   └── event/                   (15 个内部领域事件，均 extends shared.domain.DomainEvent)
│   │   ├── port/
│   │   │   └── RanchQueryPort.java      (出站端口：查 Ranch 牲畜/围栏数量，由 acl/RanchQueryPortImpl 实现)
│   │   └── repository/
│   │       ├── SubscriptionRepository.java
│   │       ├── ContractRepository.java
│   │       ├── RevenuePeriodRepository.java
│   │       ├── SubscriptionServiceRepository.java
│   │       ├── FeatureGateRepository.java
│   │       └── port/
│   │           └── SubscriptionQueryPort.java  (跨上下文只读端口，由 JpaSubscriptionQueryPortImpl 实现)
│   ├── application/
│   │   ├── service/
│   │   │   ├── SubscriptionApplicationService.java
│   │   │   ├── ContractApplicationService.java
│   │   │   ├── RevenueApplicationService.java
│   │   │   ├── QuotaApplicationService.java   (实现 QuotaCheckService 接口)
│   │   │   ├── UsageResolver.java             (接口)
│   │   │   ├── FarmLivestockUsageResolver.java (实现，featureKey=livestock_management)
│   │   │   └── FarmFenceUsageResolver.java     (实现，featureKey=fence_management)
│   │   ├── port/
│   │   │   └── QuotaCheckService.java (配额检查端口，QuotaApplicationService 实现，供 platform/web 依赖)
│   │   ├── query/                        (读模型)
│   │   │   ├── SubscriptionQueryService.java
│   │   │   └── RevenueQueryService.java
│   │   ├── job/
│   │   │   └── CommerceScheduler.java (7 个定时任务)
│   │   ├── dto/
│   │   │   ├── QuotaResult.java
│   │   │   ├── CheckoutRequest.java    (已定义；Controller 实际用 Map 接收 body，此 DTO 暂未被引用)
│   │   │   ├── SubscriptionResponse.java
│   │   │   ├── ContractResponse.java
│   │   │   └── RevenuePeriodResponse.java
│   │   └── assembler/                   (DTO 映射，3 个)
│   │       ├── SubscriptionAssembler.java
│   │       ├── ContractAssembler.java
│   │       └── RevenuePeriodAssembler.java
│   ├── infrastructure/
│   │   ├── acl/
│   │   │   └── RanchQueryPortImpl.java  (实现 domain.port.RanchQueryPort，注入 ranch LivestockRepository/FenceRepository)
│   │   └── persistence/
│   │       ├── entity/    (5 JPA Entity)
│   │       ├── mapper/    (5 Mapper + EnumConverters，共 6 个；枚举在 DB 中以小写存储)
│   │       ├── JpaSubscriptionQueryPortImpl.java  (实现 SubscriptionQueryPort)
│   │       ├── Jpa{Subscription|Contract|RevenuePeriod|SubscriptionService|FeatureGate}RepositoryImpl.java (5 个，实现 domain repository)
│   │       └── SpringData{Subscription|Contract|RevenuePeriod|SubscriptionService|FeatureGate}Repository.java (5 个 Spring Data JPA 接口)
│   └── interfaces/
│       ├── app/                          (基于 TenantContext 鉴权)
│       │   ├── SubscriptionController.java
│       │   └── CommerceController.java
│       └── admin/                        (校验 ROLE_PLATFORM_ADMIN)
│           ├── AdminSubscriptionController.java
│           ├── AdminContractController.java
│           ├── AdminRevenueController.java
│           ├── AdminServiceController.java
│           └── AdminFeatureGateController.java
├── shared/                              (共享内核，实际包名为 shared，非 shared-kernel)
│   ├── common/
│   │   ├── ErrorCode.java               (Commerce 新增 9 个错误码)
│   │   ├── DomainException.java         (领域层异常)
│   │   ├── ApiException.java            (Web 适配层异常)
│   │   └── ApiResponse.java             (统一响应包络)
│   └── domain/
│       ├── AggregateRoot.java           (聚合根基类)
│       ├── Entity.java                  (实体基类)
│       ├── DomainEvent.java             (领域事件基类)
│       ├── DomainEventPublisher.java    (进程内事件发布器)
│       └── event/                       (9 个跨上下文共享事件)
│           ├── SubscriptionTierChangedEvent.java
│           ├── SubscriptionSuspendedEvent.java
│           ├── SubscriptionReactivatedEvent.java
│           ├── SubscriptionExpiredEvent.java
│           ├── SubscriptionCreatedEvent.java
│           ├── ContractSignedEvent.java
│           ├── ServiceDegradedEvent.java
│           ├── ServiceQuotaAdjustedEvent.java
│           └── ServiceRevokedEvent.java
└── platform/
    ├── web/
    │   ├── QuotaCheck.java    (配额注解，横切关注点)
    │   └── QuotaInterceptor.java (配额拦截器，依赖 commerce QuotaCheckService port)
    ├── messaging/
    │   ├── NotificationJpaEntity.java          (通知 JPA 实体，平台级统一通知)
    │   ├── SpringDataNotificationRepository.java (通知 Spring Data Repository)
    │   └── NotificationService.java            (平台级通知服务，非 Commerce 私有)
    └── infrastructure/mq/
        └── PlatformEventConsumer.java          (平台事件消费者)
```

### 1.2 与其他限界上下文的关系

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
  └── feature_key + tier → 加载为 FeatureGate 实体（extends Entity）

#### 跨上下文端口集成（ACL，双向）

| 方向 | 端口（定义方） | 实现（消费方 infra） | 用途 |
|------|--------------|-------------------|------|
| commerce → ranch | `commerce/domain/port/RanchQueryPort` | `commerce/infrastructure/acl/RanchQueryPortImpl` | 配额引擎统计牲畜/围栏数量（注入 ranch LivestockRepository/FenceRepository） |
| identity → commerce | `identity/domain/port/CommerceQueryPort` | `identity/infrastructure/acl/CommerceQueryPortImpl` | B2B 仪表板聚合活跃合同（调用 commerce SubscriptionQueryService） |
| health → commerce | `health/domain/port/HealthSubscriptionPort` | `health/infrastructure/acl/HealthSubscriptionPortImpl` | 健康模块按 tier 解析数据保留天数/功能权限（直接注入 commerce SubscriptionRepository/FeatureGateRepository） |
| platform → commerce | `commerce/application/port/QuotaCheckService` | `platform/web/QuotaInterceptor` | 请求级配额拦截（注入 commerce 的 List<UsageResolver>） |

> 依赖方向收敛：identity/health 均通过各自定义的入站端口 + ACL 实现反向依赖 commerce，避免 commerce 反向耦合上游上下文。Commerce 唯一的出站依赖是 ranch（RanchQueryPort）。
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
CREATE INDEX idx_subscriptions_trial_expires ON subscriptions(status, trial_ends_at)
    WHERE status = 'trial' AND trial_ends_at IS NOT NULL;
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

### 2.6 notifications（平台基础设施，非 Commerce 私有）

> notifications 是平台级统一通知中心，服务于所有限界上下文（Commerce/Ranch/IoT/Identity）。DDL 包含在 V6 迁移中以便一次性部署，但表归属 platform，不与 Commerce 业务表耦合。后续其他上下文（如 Ranch 围栏告警）可直接写入此表。

```sql
CREATE TABLE notifications (
    id          BIGSERIAL PRIMARY KEY,
    tenant_id   BIGINT NOT NULL REFERENCES tenants(id),
    user_id     BIGINT REFERENCES users(id),
    type        VARCHAR(50) NOT NULL,
    title       VARCHAR(200) NOT NULL,
    content     TEXT,
    is_read     BOOLEAN DEFAULT FALSE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
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

notifications (平台基础设施，独立于 Commerce，所有上下文可写入)
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
            throw new DomainException(ErrorCode.ENTERPRISE_CUSTOM_PRICING,
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

| 事件 | 触发点 | 消费方 | 归属 |
|------|--------|--------|------|
| SubscriptionCreatedEvent | `startTrial()` / `activate()` | Identity: TenantPhase SAMPLE→BATCH | shared |
| SubscriptionTierChangedEvent | `changeTier()` / `expireTrial()` / `downgradeAfterRenewalFailure()` | Ranch/IoT: 更新配额缓存 | shared |
| SubscriptionSuspendedEvent | `suspend()` | Ranch/IoT: 限制功能访问 | shared |
| SubscriptionReactivatedEvent | `reactivate()` / `recoverFromRenewalFailure()` | Ranch/IoT: 恢复功能访问 | shared |
| SubscriptionCancelledEvent | `cancel()` | 通知: 告知 owner | internal |
| SubscriptionRenewalFailedEvent | `markRenewalFailed()` | 通知: 续费失败提醒 | internal |
| SubscriptionExpiredEvent | `markExpired()` | Ranch/IoT: 限制功能访问 | shared |

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

| 事件 | 触发点 | 消费方 | 归属 |
|------|--------|--------|------|
| ContractCreatedEvent | `create()` | 无（内部审计） | internal |
| ContractSignedEvent | `sign()` | Identity: 创建 Partner 子 Tenant | shared |
| ContractSuspendedEvent | `suspend()` | 通知: 告知合作方 | internal |
| ContractReactivatedEvent | `reactivate()` | 通知: 告知合作方恢复 | internal |
| ContractTerminatedEvent | `terminate()` | 通知: 告知合作方 | internal |
| ContractExpiredEvent | `markExpired()` | 通知: 告知合作方 | internal |

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

| 事件 | 触发点 | 消费方 | 归属 |
|------|--------|--------|------|
| RevenuePeriodCreatedEvent | `calculate()` | 通知: 告知合作方有待确认结算 | internal |
| RevenuePlatformConfirmedEvent | `confirmByPlatform()` | 通知: 告知合作方可确认 | internal |
| RevenuePartnerConfirmedEvent | `confirmByPartner()` | 通知: 触发结算 | internal |
| RevenueSettledEvent | `settle()` | 通知: 结算完成通知 | internal |

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

| 事件 | 触发点 | 消费方 | 归属 |
|------|--------|--------|------|
| ServiceProvisionedEvent | `provision()` | 通知: 服务已配置 | internal |
| ServiceActivatedEvent | `activate()` | 通知: 服务上线 | internal |
| ServiceHeartbeatLostEvent | `checkHeartbeat()` | 通知: 运维告警 | internal |
| ServiceHeartbeatRecoveredEvent | GRACE_PERIOD 中 `recordHeartbeat()` | 通知: 关闭告警工单 | internal |
| ServiceDegradedEvent | `degrade()` | Ranch/IoT: 配额降为 BASIC | shared |
| ServiceQuotaAdjustedEvent | `adjustQuota()` | Ranch/IoT: 更新配额缓存 | shared |
| ServiceRevokedEvent | `revoke()` / `expire()` | Ranch/IoT: 停止服务 | shared |

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
QuotaInterceptor (platform/web/)
    │ 1. 从 request 提取 tenantId, farmId (纯值，不出 interfaces 层)
    │ 2. 调用 commerce QuotaCheckService port → QuotaApplicationService.checkQuota()
    │    ├─ 第一道：订阅是否活跃？(TRIAL/ACTIVE/FREE → 放行)
    │    └─ 第二道：门控规则是否允许？(feature_gates 校验)
    │ 3. 超出 → 403 QUOTA_EXCEEDED
    ▼
Controller / Service
```

**依赖方向：** `platform/web/QuotaInterceptor` → `commerce/application/port/QuotaCheckService` ← `commerce/application/service/QuotaApplicationService`。平台层依赖业务 port，不定义业务语义。

### 4.2 QuotaApplicationService

```java
public class QuotaApplicationService implements QuotaCheckService {
    private final SubscriptionRepository subscriptionRepository;
    private final FeatureGateRepository featureGateRepository;

    @Override
    public QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage) {
        // 第一道：订阅状态检查
        Subscription sub = subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new DomainException(ErrorCode.SUBSCRIPTION_NOT_FOUND,
                "订阅不存在: tenantId=" + tenantId));
        if (!sub.isActiveOrTrial()) {
            return QuotaResult.denied("订阅未激活");
        }

        // 第二道：门控规则（gateType 为 GateType 枚举：NONE/LOCK/LIMIT/FILTER）
        FeatureGate gate = loadGate(featureKey, sub.effectiveTier());
        return switch (gate.getGateType()) {
            case NONE -> QuotaResult.allowed();
            case LOCK -> gate.isEnabled()
                ? QuotaResult.allowed()
                : QuotaResult.denied("功能 " + featureKey + " 当前 Tier 不可用");
            case LIMIT -> currentUsage < gate.getLimitValue()
                ? QuotaResult.allowed()
                : QuotaResult.denied("已达到上限 " + gate.getLimitValue() + "，当前: " + currentUsage);
            case FILTER -> QuotaResult.allowedWithRetention(gate.getRetentionDays());
        };
    }

    private FeatureGate loadGate(String featureKey, SubscriptionTier tier) {
        // tier 以小写存储（EnumConverters）；未命中配置时回退为不受限（NONE）
        return featureGateRepository.findByTierAndFeatureKey(tier.name().toLowerCase(), featureKey)
            .orElseGet(FeatureGate::unrestricted);
    }
}
```

### 4.3 三种 gateType 各归其位

| gateType | 拦截时机 | 执行方式 |
|----------|---------|---------|
| lock | 请求时 | QuotaInterceptor 拦截 |
| limit | 请求时 | QuotaInterceptor 拦截 |
| filter | 查询时 | QueryService 调用 `getRetentionDays()` 裁剪数据范围 |

### 4.4 UsageResolver

```java
public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, Long farmId);
}
```

| Resolver | featureKey | 粒度 | 数据源 |
|----------|-----------|------|--------|
| FarmFenceUsageResolver | fence_management | farm | RanchQueryPort.countFencesByFarmIdAndTenantId |
| FarmLivestockUsageResolver | livestock_management | farm | RanchQueryPort.countLivestockByFarmIdAndTenantId |

### 4.5 API 端点

#### App API — `/api/v1/`（9 个端点）

| 方法 | 路径 | 说明 | 权限 | 归属服务 |
|------|------|------|------|---------|
| GET | `/subscription` | 查看订阅状态 + Tier + 用量 | 认证用户 | SubscriptionQueryService |
| GET | `/subscription/plans` | 查看 Tier 定价信息 | 认证用户 | SubscriptionQueryService |
| POST | `/subscription/checkout` | 发起订阅（MVP: Mock 支付） | owner | SubscriptionApplicationService |
| PUT | `/subscription/tier` | 升降级 Tier | owner | SubscriptionApplicationService |
| POST | `/subscription/cancel` | 取消订阅 | owner | SubscriptionApplicationService |
| GET | `/subscription/usage` | 用量 vs 配额对比（含 filter 型门控裁剪） | 认证用户 | SubscriptionQueryService |
| GET | `/contracts/me` | 查看自己的合同 | reseller/enterprise | SubscriptionQueryService |
| GET | `/revenue/periods` | 查看分润记录（含 filter 型门控裁剪） | reseller | RevenueQueryService |
| POST | `/revenue/periods/{id}/confirm` | Partner 确认结算 | reseller | RevenueApplicationService |

#### Admin API — `/api/v1/admin/`（21 个端点）

**订阅管理（AdminSubscriptionController，3 个）：**

| 方法 | 路径 | 说明 | 归属服务 |
|------|------|------|---------|
| GET | `/admin/subscriptions` | 列表（支持 status/tier 过滤+分页） | SubscriptionQueryService |
| GET | `/admin/subscriptions/{id}` | 详情 | SubscriptionQueryService |
| PUT | `/admin/subscriptions/{id}/status` | 变更状态（targetStatus + reason） | SubscriptionApplicationService |

**合同管理（AdminContractController，6 个）：**

| 方法 | 路径 | 说明 | 归属服务 |
|------|------|------|---------|
| GET | `/admin/contracts` | 列表 | RevenueQueryService |
| POST | `/admin/contracts` | 创建合同草稿 | ContractApplicationService |
| GET | `/admin/contracts/{id}` | 详情 | RevenueQueryService |
| PUT | `/admin/contracts/{id}` | 修改草稿 | ContractApplicationService |
| POST | `/admin/contracts/{id}/sign` | 签署合同 | ContractApplicationService |
| PUT | `/admin/contracts/{id}/status` | 状态变更 | ContractApplicationService |

**分润结算（AdminRevenueController，5 个）：**

| 方法 | 路径 | 说明 | 归属服务 |
|------|------|------|---------|
| GET | `/admin/revenue/periods` | 列表 | RevenueQueryService |
| GET | `/admin/revenue/periods/{id}` | 详情 | RevenueQueryService |
| POST | `/admin/revenue/calculate` | 触发月度分润计算（幂等） | RevenueApplicationService |
| POST | `/admin/revenue/periods/{id}/confirm` | 平台确认结算 | RevenueApplicationService |
| POST | `/admin/revenue/periods/{id}/recalculate` | 重新计算 | RevenueApplicationService |

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
| TrialExpiryJob | 每小时 | status=TRIAL AND trial_ends_at < now → expireTrial() |
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
ApplicationService.save(aggregate) → DomainEventPublisher.publishDomainEvents(aggregate)
    ↓ (DomainEventPublisher 内部委托 Spring ApplicationEventPublisher；MVP 同步、同事务内，无 RocketMQ)
    ├── PlatformEventConsumer (platform/infrastructure/mq/) → NotificationService → 写入 notifications 表
    └── 各上下文 @EventListener（如 iot/SpringEventPublisher）
```

### 5.2 全部 24 个事件

9 个跨上下文共享事件（`shared-kernel/domain/event/`）+ 15 个内部领域事件（`commerce/domain/model/event/`）= 24 个。见 Section 3 各聚合根的事件表，标注"归属"列。

**9 个跨上下文共享事件：** SubscriptionCreatedEvent、SubscriptionTierChangedEvent、SubscriptionSuspendedEvent、SubscriptionReactivatedEvent、SubscriptionExpiredEvent、ContractSignedEvent、ServiceDegradedEvent、ServiceQuotaAdjustedEvent、ServiceRevokedEvent

**15 个内部事件：** SubscriptionCancelledEvent、SubscriptionRenewalFailedEvent、ContractCreatedEvent、ContractSuspendedEvent、ContractReactivatedEvent、ContractTerminatedEvent、ContractExpiredEvent、RevenuePeriodCreatedEvent、RevenuePlatformConfirmedEvent、RevenuePartnerConfirmedEvent、RevenueSettledEvent、ServiceProvisionedEvent、ServiceActivatedEvent、ServiceHeartbeatLostEvent、ServiceHeartbeatRecoveredEvent

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

Commerce 新增 9 个（保留在 `shared/common/ErrorCode.java`）：

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

*设计规格版本: 2026-05-18 v6（Task 1-2 实施后评审修正）*
*评审记录: `docs/superpowers/reviews/2026-05-18-项目总体技术架构评审.md` (v2)*
*实施计划: `docs/superpowers/plans/2026-05-18-commerce-context-plan.md`*
*验证报告: `docs/superpowers/testing/2026-05-22-commerce-manual-verification-guide.md`*
*Postman: `docs/superpowers/testing/commerce-e2e-postman-collection.json`*

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
| RocketMQ 事件总线 | Spring ApplicationEvent → RocketMQ（引入 SpringEventBridge 按 topic 转发） | 微服务拆分 |

---

## 附录 B：修正记录

### v3 → v4 修正

| 修正项 | v3 内容 | v4 修正 | 对应评审 |
|---|---|---|---|
| interfaces 目录 | Controller 平铺 | 拆为 `interfaces/app/` + `interfaces/admin/` | 评审 T3 |
| application 目录 | `scheduler/` + `listener/` | `job/`（原 scheduler）+ `query/` + `assembler/`，listener 并入 service | 评审 T4 |
| ErrorCode 归属 | `shared/common/ErrorCode.java` | `shared-kernel/domain/ErrorCode.java` | 评审 v2 A1 修正 |
| ApiException 使用 | 领域模型直接用 ApiException | 领域模型改用 DomainException | 评审 v2 A1 修正 |
| Notification 归属 | `shared/notification/` | `platform/messaging/NotificationService.java` | 评审 v2 A1 |
| EventPublisher | 未提及归位 | `platform/messaging/SpringEventBridge.java` | 评审 v2 T1.5 |
| 跨上下文 port | 无 | `domain/repository/port/SubscriptionQueryPort.java` | 评审 v2 T1.5 |
| query 层 | 无 | `application/query/SubscriptionQueryService.java` + `RevenueQueryService.java` | 评审 T5 |
| assembler 层 | 无 | `application/assembler/*.java`（3 个 DTO 映射器） | 评审 T4 |

### v4 → v5 修正

| 修正项 | v4 内容 | v5 修正 | 原因 |
|---|---|---|---|
| notifications 边界 | DDL 在 Commerce Schema，服务在 platform | 表标注为平台基础设施，所有上下文可写入 | 避免 Ranch/IoT 通知依赖 Commerce 迁移 |
| TrialExpiryJob 字段 | `status=TRIAL AND expires_at < now` | `status=TRIAL AND trial_ends_at < now` | 试用订阅应检查 trial_ends_at，非 expires_at |
| QuotaCheckService 位置 | `platform/web/QuotaCheckService.java` | `commerce/application/port/QuotaCheckService.java` | 业务契约不应由平台层定义，平台依赖业务 port |
| 事件发布机制 | 5.1 写 RocketMQ bridge，5.3 写 MVP 不引入 | MVP 仅 Spring ApplicationEvent，RocketMQ 移入延后事项 | 消除矛盾，明确 MVP 路径 |
| Query 层职责 | GET 端点无归属，getRetentionDays 在 ApplicationService | API 端点表加归属服务列，filter 型门控由 QueryService 执行 | 防止读逻辑回流到写服务 |
| QuotaApplicationService | 未标注实现接口 | `implements QuotaCheckService` | 依赖方向：QuotaInterceptor → port ← 实现 |

### v5 → v6 修正

| 修正项 | v5 内容 | v6 修正 | 原因 |
|---|---|---|---|
| notifications.updated_at | 无此列 | 新增 `updated_at TIMESTAMPTZ NOT NULL DEFAULT now()` | is_read 标记已读时需追踪更新时间，与 V1-V3 所有可变表保持一致 |
| 领域事件实现形式 | 未指定（plan 写 "record"） | 明确为 `class extends DomainEvent`（非 record） | Java record 不能继承抽象类，DomainEvent 已有 eventId/occurredAt 状态 |
| 共享事件字段类型 | 未说明 | shared 事件中枚举值用 String（非 Java enum），内部事件可用 enum | 避免 shared → commerce 循环依赖；共享事件面向跨上下文序列化，String 解耦更安全 |

### v6 → v7 修正（2026-06-26 按实际实现复核）

| 修正项 | v6 内容 | v7 修正 | 原因 |
|---|---|---|---|
| 共享内核包名 | `shared-kernel/domain/` | `shared/common/`（ErrorCode/DomainException/ApiException/ApiResponse）+ `shared/domain/`（AggregateRoot/Entity/DomainEvent/DomainEventPublisher/event） | 实际包名为 shared，common/domain 分层存放 |
| Notification 类 | `Notification`(JPA) + `NotificationRepository` + `NotificationEventListener` | `NotificationJpaEntity` + `SpringDataNotificationRepository` + `PlatformEventConsumer`（platform/infrastructure/mq/，取代 NotificationEventListener） | 类名/职责与实际实现对齐 |
| 事件发布入口 | Spring ApplicationEventPublisher 直发 | ApplicationService 调 `DomainEventPublisher.publishDomainEvents(aggregate)`，内部委托 Spring ApplicationEventPublisher | 应用层经 shared 发布器，非直接用 Spring |
| Commerce 出站端口 | 目录树未列出 | 补 `domain/port/RanchQueryPort` + `infrastructure/acl/RanchQueryPortImpl` | 实际存在，配额引擎统计依赖 |
| UsageResolver 类名 | FenceUsageResolver / LivestockUsageResolver | FarmFenceUsageResolver / FarmLivestockUsageResolver | 实际类名 |
| SubscriptionQueryPort 实现 | "由 SubscriptionQueryService 实现" | 由 `JpaSubscriptionQueryPortImpl` 实现 | 读端口由基础设施实现，非应用服务 |
| QuotaApplicationService | gateType 用字符串字面量 "none"/"lock"/... | 用 `GateType` 枚举（NONE/LOCK/LIMIT/FILTER）switch；loadGate 未命中回退 `FeatureGate.unrestricted()` | 实际为枚举，且配置缺失时放行 |
| persistence mapper 数量 | 5 Mapper | 5 Mapper + `EnumConverters`（共 6，枚举以小写入库） | 补枚举转换器 |
| persistence repository 描述 | "5 Spring Data + 4 Impl + 1 FeatureGate Impl" | 5 Spring Data + 5 Jpa Impl + 1 `JpaSubscriptionQueryPortImpl` | 与实际文件数对齐 |
| 跨上下文集成 | 仅画 Identity↔Commerce 数据关系 | 补 identity/health/platform→commerce 入站端口 + commerce→ranch 出站端口 ACL 表 | 反映实际双向依赖 |
| FeatureGate 定位 | 值对象 | 实体（extends Entity），非聚合根 | 实际继承 Entity |
| CheckoutRequest | dto 列出未说明用途 | 标注 Controller 实际用 Map 接收 body，此 DTO 暂未被引用 | 反映实现现状 |
