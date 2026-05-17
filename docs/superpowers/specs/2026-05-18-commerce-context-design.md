# Commerce 限界上下文设计规格

**日期**: 2026-05-18
**状态**: 已评审通过（第二轮修正）
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
│   │   │   │   └── FeatureGate          (值对象，归属 Subscription)
│   │   │   ├── SubscriptionTier.java    (值对象枚举)
│   │   │   ├── SubscriptionStatus.java  (值对象枚举)
│   │   │   ├── Contract.java            (聚合根)
│   │   │   ├── ContractStatus.java      (值对象枚举)
│   │   │   ├── RevenuePeriod.java       (聚合根)
│   │   │   ├── RevenueSettlementStatus.java
│   │   │   └── SubscriptionService.java (聚合根, licensed 专用)
│   │   └── repository/
│   │       ├── SubscriptionRepository.java
│   │       ├── ContractRepository.java
│   │       ├── RevenuePeriodRepository.java
│   │       └── SubscriptionServiceRepository.java
│   ├── application/
│   │   ├── SubscriptionApplicationService.java
│   │   ├── ContractApplicationService.java
│   │   ├── RevenueApplicationService.java
│   │   ├── QuotaApplicationService.java
│   │   ├── BillingApplicationService.java  ← 预留，Q1/Q2 不实现
│   │   ├── dto/
│   │   │   └── QuotaResult.java        ← 配额校验计算结果（非持久化）
│   │   └── interceptor/
│   │       └── QuotaInterceptor.java   ← 配额门控拦截器
│   ├── infrastructure/
│   │   └── persistence/ ...
│   └── interfaces/
│       ├── SubscriptionController.java
│       ├── ContractController.java
│       ├── RevenueController.java
│       └── SubscriptionAdminController.java
```

### 1.2 与现有 Identity 上下文的关系

```
Identity (已有)                       Commerce (新增)
┌──────────────┐                      ┌──────────────────┐
│ Tenant       │ 1 ─────────────── 1 │ Subscription      │
│  .type       │                      │  .tier            │
│  .phase      │                      │  .billingModel    │  ← 实际生效值
│  .billingModel│                     │  .status          │
│              │                      │  .featureGates[]  │  ← 归属于此
│              │ 1 ──────────── 0..1 │ Contract          │
│              │                      │  .billingModel    │  ← 实际生效值
│              │                      │  .revenueShareRatio│
│              │                      └──────────────────┘
│              │ 1 ──────────── 0..* │ RevenuePeriod     │
│              │                      └──────────────────┘
│              │ 1 ──────────── 0..1 │ SubscriptionService│
│              │                      │  .serviceKey       │
└──────────────┘                      └──────────────────┘

说明：
- Tenant.billingModel = 注册时的默认路由策略
- Subscription/Contract.billingModel = 创建时从 Tenant 快照（不随 Tenant 变更同步），作为实际生效的计费模型
  （支持混合模式：如 reseller + licensed，不改 Tenant 结构）
- FeatureGate 挂在 Subscription 聚合根下，随 Tier 变更
- 所有聚合根表使用乐观锁（version INT DEFAULT 0，JPA @Version），并发冲突返回 409
```

### 1.3 Tenant 模型变更

现有 `Tenant` 需扩展两个字段，其余商业数据由 Commerce 上下文管理：

```java
// Tenant.java 新增字段
private String type;           // rancher | reseller | enterprise | developer
private String billingModel;   // direct | revenue_share | licensed | api_usage
// parentTenantId 已有
```

| 字段 | 含义 | 值域 |
|------|------|------|
| `type` | 租户在生态中的商业角色 | rancher（牧场主）、reseller（代理商）、enterprise（集团）、developer（开发者） |
| `billingModel` | 默认计费模式 | direct、revenue_share、licensed、api_usage |

两个维度正交：type 回答"你是谁"，billingModel 回答"怎么收钱"。

TenantPhase 保留 SAMPLE / BATCH（延后重命名为 TRIAL / ACTIVE，不影响架构）。

---

## 2. 数据库 Schema（Commerce 新增表）

紧跟现有 V1-V4 迁移之后。

### 2.1 subscriptions

```sql
CREATE TABLE subscriptions (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES tenants(id),
    tier            VARCHAR(20) NOT NULL,   -- basic | standard | premium | enterprise
    billing_model   VARCHAR(20) NOT NULL,   -- direct | revenue_share | licensed | api_usage
    status          VARCHAR(20) NOT NULL,   -- trial | active | free | suspended | renewal_failed | cancelled | expired
    billing_cycle   VARCHAR(20) NOT NULL DEFAULT 'monthly',
    started_at      TIMESTAMP NOT NULL,
    expires_at      TIMESTAMP,
    trial_ends_at   TIMESTAMP,
    cancelled_at    TIMESTAMP,
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMP NOT NULL DEFAULT NOW(),  -- JPA @PreUpdate 自动更新
    version         INT NOT NULL DEFAULT 0,             -- 乐观锁，JPA @Version
    CONSTRAINT uq_subscriptions_tenant UNIQUE (tenant_id)
);

CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expires ON subscriptions(expires_at) WHERE status = 'active';
```

### 2.2 feature_gates（全局功能门控配置表）

```sql
CREATE TABLE feature_gates (
    id              BIGSERIAL PRIMARY KEY,
    feature_key     VARCHAR(50) NOT NULL,
    gate_type       VARCHAR(10) NOT NULL,   -- none | lock | limit | filter
    tier            VARCHAR(20) NOT NULL,
    limit_value     INTEGER,                -- limit 类型：数量上限
    retention_days  INTEGER,                -- filter 类型：保留天数
    is_enabled      BOOLEAN DEFAULT TRUE,   -- lock 类型：是否开放
    created_at      TIMESTAMP NOT NULL DEFAULT NOW(),
    CONSTRAINT uq_feature_gates_key_tier UNIQUE (feature_key, tier)
);
```

存储层 vs Domain 层映射：feature_gates 是全局配置表，按 tier 定义能力模板。Domain 层的 FeatureGate 作为 Subscription 聚合根的值对象，通过 `tier` 查询 feature_gates 表构建。创建/变更 Subscription 时加载对应 tier 的配置，映射为 Subscription 下的 FeatureGate 值对象。**feature_gates 配置变更实时生效**——不快照到 Subscription，所有请求按最新配置校验。这样修改配额（如 basic 围栏从 3 改为 5）立即对所有 basic 用户生效。

### 2.3 contracts

```sql
CREATE TABLE contracts (
    id                  BIGSERIAL PRIMARY KEY,
    contract_number     VARCHAR(30) NOT NULL,    -- CT-YYYY-NNNNNN（6位序号，年度上限 999999）
    tenant_id           BIGINT NOT NULL REFERENCES tenants(id),
    billing_model       VARCHAR(20) NOT NULL,
    effective_tier      VARCHAR(20) NOT NULL,
    revenue_share_ratio DECIMAL(5,4),
    status              VARCHAR(20) NOT NULL,   -- draft | active | suspended | expired | terminated
    signed_by           BIGINT REFERENCES users(id),
    signed_at           TIMESTAMP,
    started_at          TIMESTAMP NOT NULL,
    expires_at          TIMESTAMP,
    created_at          TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at          TIMESTAMP NOT NULL DEFAULT NOW(),  -- JPA @PreUpdate
    version             INT NOT NULL DEFAULT 0,             -- 乐观锁
    CONSTRAINT uq_contracts_number UNIQUE (contract_number)
);
CREATE INDEX idx_contracts_tenant ON contracts(tenant_id);
```

### 2.4 revenue_periods

```sql
CREATE TABLE revenue_periods (
    id                      BIGSERIAL PRIMARY KEY,
    contract_id             BIGINT NOT NULL REFERENCES contracts(id),
    tenant_id               BIGINT NOT NULL REFERENCES tenants(id),
    settlement_period       CHAR(7) NOT NULL,          -- 'YYYY-MM'
    total_device_fee        DECIMAL(12,2) NOT NULL,
    total_livestock         INTEGER NOT NULL,
    revenue_share_ratio     DECIMAL(5,4) NOT NULL,
    revenue_share_amount    DECIMAL(12,2) NOT NULL,
    status                  VARCHAR(20) NOT NULL,      -- pending → platform_confirmed → partner_confirmed → settled
    confirmed_at            TIMESTAMP,
    settled_at              TIMESTAMP,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    version                 INT NOT NULL DEFAULT 0,             -- 乐观锁
    CONSTRAINT uq_revenue_period UNIQUE (contract_id, settlement_period)
);
CREATE INDEX idx_revenue_periods_tenant ON revenue_periods(tenant_id);
```

状态机统一管控，不使用布尔字段：

```
pending ──(platform 确认)──→ platform_confirmed ──(partner 确认)──→ partner_confirmed ──(系统结算)──→ settled
```

非法跳转返回 409 CONFLICT。

### 2.5 subscription_services

```sql
CREATE TABLE subscription_services (
    id                      BIGSERIAL PRIMARY KEY,
    tenant_id               BIGINT NOT NULL REFERENCES tenants(id),
    service_key_prefix      VARCHAR(8),                -- 展示用，如 "sk-abcd"
    service_key_hash        VARCHAR(64) NOT NULL,      -- SHA-256，校验用
    status                  VARCHAR(20) NOT NULL,      -- active | grace_period | degraded | revoked | expired
    -- expires_at 到期时由 GracePeriodExpiryJob 触发 → status=EXPIRED
    effective_tier          VARCHAR(20) NOT NULL,
    device_quota            INTEGER,
    last_heartbeat_at       TIMESTAMP,
    heartbeat_interval_hrs  INTEGER DEFAULT 24,
    grace_period_days       INTEGER DEFAULT 15,
    started_at              TIMESTAMP NOT NULL,
    expires_at              TIMESTAMP,
    created_at              TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at              TIMESTAMP NOT NULL DEFAULT NOW(),  -- JPA @PreUpdate
    version                 INT NOT NULL DEFAULT 0,             -- 乐观锁
    CONSTRAINT uq_subscription_service_tenant UNIQUE (tenant_id)
);
```

### 2.6 Tenant 表变更

```sql
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS billing_model VARCHAR(20);
UPDATE tenants SET type = 'rancher', billing_model = 'direct' WHERE type IS NULL;
```

### 2.7 表关系图

```
tenants (ALTER: type, billing_model)
  │
  ├── 1:1 ── subscriptions
  │            ├── tier, status, billing_model, billing_cycle
  │            └── trial_ends_at
  │
  ├── 1:0..1 ── contracts
  │               ├── contract_number (CT-YYYY-NNNN)
  │               ├── billing_model, effective_tier, revenue_share_ratio
  │               │
  │               └── 1:0..* ── revenue_periods
  │                              ├── settlement_period (YYYY-MM)
  │                              ├── status 状态机 (pending→platform_confirmed→partner_confirmed→settled)
  │                              └── total_device_fee, revenue_share_amount
  │
  └── 1:0..1 ── subscription_services
                  ├── service_key_prefix (展示用)
                  ├── service_key_hash (校验用)
                  └── last_heartbeat_at

feature_gates (全局配置，独立于 tenant)
  └── feature_key + tier → 加载为 Subscription 的 FeatureGate 值对象
```

### 2.8 种子数据

```sql
-- feature_gates：与 Flutter FeatureFlags 对齐的功能门控
-- 完整 23 条在迁移脚本中，此处示例
INSERT INTO feature_gates (feature_key, gate_type, tier, is_enabled) VALUES
('gps_tracking', 'none', 'basic', TRUE),
('health_score', 'lock', 'basic', FALSE),
('health_score', 'lock', 'standard', TRUE);

-- limit 类型
INSERT INTO feature_gates (feature_key, gate_type, tier, limit_value) VALUES
('fence_management', 'limit', 'basic', 3),
('fence_management', 'limit', 'standard', 5),
('fence_management', 'limit', 'premium', 10),
('fence_management', 'limit', 'enterprise', 999);

-- filter 类型
INSERT INTO feature_gates (feature_key, gate_type, tier, retention_days) VALUES
('alert_history', 'filter', 'basic', 7),
('alert_history', 'filter', 'standard', 30),
('alert_history', 'filter', 'premium', 90),
('alert_history', 'filter', 'enterprise', 365);

-- limit 类型：开放平台 API 调用量门控（仅管控 /api/v1/open/** 端点，不影响 App 内部 API）
-- basic/standard 不开放 API，limit=0 由 QuotaInterceptor 拦截开放平台请求
INSERT INTO feature_gates (feature_key, gate_type, tier, limit_value) VALUES
('api_calls', 'limit', 'basic', 0),
('api_calls', 'limit', 'standard', 0),
('api_calls', 'limit', 'premium', 1000),
('api_calls', 'limit', 'enterprise', 99999);
```

---

## 3. 领域模型与状态机

### 3.1 Subscription（聚合根）

```java
public class Subscription extends AggregateRoot {

    private Long tenantId;
    private SubscriptionTier tier;
    private String billingModel;
    private SubscriptionStatus status;
    private String billingCycle;
    private Instant startedAt;
    private Instant expiresAt;
    private Instant trialEndsAt;
    private Instant cancelledAt;

    // ── 工厂方法 ──

    /** SAMPLE 阶段：创建试用订阅，自动获得 Premium，14 天
     *  @param billingModel 从 Tenant.billingModel 快照传入
     */
    public static Subscription createTrial(Long tenantId, String billingModel) {
        Subscription s = new Subscription();
        s.tenantId = tenantId;
        s.tier = SubscriptionTier.PREMIUM;
        s.billingModel = billingModel;
        s.status = SubscriptionStatus.TRIAL;
        s.billingCycle = "monthly";
        s.startedAt = Instant.now();
        s.trialEndsAt = Instant.now().plus(14, ChronoUnit.DAYS);
        s.registerEvent(new SubscriptionCreatedEvent(tenantId, SubscriptionTier.PREMIUM, SubscriptionStatus.TRIAL));
        return s;
    }

    /** BATCH 阶段：创建付费订阅
     *  @param billingModel 从 Tenant.billingModel 快照传入，不随 Tenant 变更同步
     */
    public static Subscription createPaid(Long tenantId, SubscriptionTier tier,
                                           String billingModel, String billingCycle) {
        Subscription s = new Subscription();
        s.tenantId = tenantId;
        s.tier = tier;
        s.billingModel = billingModel;
        s.status = SubscriptionStatus.ACTIVE;
        s.billingCycle = billingCycle;
        s.startedAt = Instant.now();
        s.registerEvent(new SubscriptionCreatedEvent(tenantId, tier, SubscriptionStatus.ACTIVE));
        return s;
    }

    // ── 业务查询 ──

    /** 当前生效的 Tier（Trial 期间视为 Premium） */
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

    // ── 状态转换 ──

    /** 试用到期 → 降级为 basic 免费层 */
    public void expireTrial() {
        requireStatus(SubscriptionStatus.TRIAL);
        this.tier = SubscriptionTier.BASIC;
        this.status = SubscriptionStatus.FREE;
        this.trialEndsAt = Instant.now();
        this.registerEvent(new SubscriptionTierChangedEvent(tenantId, SubscriptionTier.PREMIUM, SubscriptionTier.BASIC));
    }

    /** 升级/降级 Tier（FREE 状态也可用，用于免费→付费升级） */
    public void changeTier(SubscriptionTier newTier) {
        requireStatus(SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL, SubscriptionStatus.FREE);
        SubscriptionTier oldTier = this.tier;
        this.tier = newTier;
        if (this.status == SubscriptionStatus.FREE) {
            this.status = SubscriptionStatus.ACTIVE;
        }
        this.registerEvent(new SubscriptionTierChangedEvent(tenantId, oldTier, newTier));
    }

    /** 暂停订阅（管理员手动） */
    public void suspend() {
        requireStatus(SubscriptionStatus.ACTIVE);
        this.status = SubscriptionStatus.SUSPENDED;
    }

    /** 续费失败（系统自动） */
    public void markRenewalFailed() {
        requireStatus(SubscriptionStatus.ACTIVE);
        this.status = SubscriptionStatus.RENEWAL_FAILED;
    }

    /** 补缴成功恢复 */
    public void recoverFromRenewalFailure() {
        requireStatus(SubscriptionStatus.RENEWAL_FAILED);
        this.status = SubscriptionStatus.ACTIVE;
        int days = "yearly".equals(billingCycle) ? 365 : 30;
        this.expiresAt = Instant.now().plus(days, ChronoUnit.DAYS);
    }

    /** 续费失败宽限期到期（7天） → 降级为免费 */
    public void downgradeAfterRenewalFailure() {
        requireStatus(SubscriptionStatus.RENEWAL_FAILED);
        this.tier = SubscriptionTier.BASIC;
        this.status = SubscriptionStatus.FREE;
        this.registerEvent(new SubscriptionTierChangedEvent(tenantId, tier, SubscriptionTier.BASIC));
    }

    /** 恢复订阅，同时顺延计费周期 */
    public void reactivate() {
        requireStatus(SubscriptionStatus.SUSPENDED);
        this.status = SubscriptionStatus.ACTIVE;
        int days = "yearly".equals(billingCycle) ? 365 : 30;
        this.expiresAt = Instant.now().plus(days, ChronoUnit.DAYS);
    }

    /** 取消订阅 */
    public void cancel() {
        requireStatus(SubscriptionStatus.ACTIVE, SubscriptionStatus.SUSPENDED);
        this.status = SubscriptionStatus.CANCELLED;
        this.cancelledAt = Instant.now();
    }

    /** 到期 */
    public void expire() {
        requireStatus(SubscriptionStatus.ACTIVE);
        this.status = SubscriptionStatus.EXPIRED;
    }

    private void requireStatus(SubscriptionStatus... allowed) {
        for (SubscriptionStatus s : allowed) {
            if (this.status == s) return;
        }
        throw new ApiException(ErrorCode.INVALID_STATE_TRANSITION,
            "订阅状态 " + status + " 不允许此操作，当前要求: " + Arrays.toString(allowed));
    }
}
```

状态机：

```
                  createTrial()
                       │
                       ▼
                  ┌─────────┐
        expireTrial()│ TRIAL  │
             ┌───────┤        │
             │       └─────────┘
             │            │ cancel()
             ▼            ▼
        ┌─────────┐  ┌───────────┐
        │  FREE   │  │ CANCELLED  │
        └─────────┘  └───────────┘
         │changeTier()  ▲
         ▼              │
        ┌─────────┐     │ suspend()
        │ ACTIVE ◄─┼─────┘
        └─────────┘     │ reactivate()
         │  ▲  ▲        │
  suspend()│  │  │        │
         │  │  │markRenewalFailed()
         │  │  ▼        │
         │  │ ┌─────────────────┐
         │  │ │RENEWAL_FAILED  │──recoverFromRenewalFailure()──► ACTIVE
         │  │ └─────────────────┘
         │  │       │宽限期结束(7天)
         │  │       ▼
         │  │  downgradeAfterRenewalFailure() → FREE
         ▼  │       ▼
     ┌───────────┐  │
     │ SUSPENDED │──┘
     └───────────┘
          │expire()
          ▼
     ┌──────────┐
     │ EXPIRED  │
     └──────────┘

  ACTIVE / TRIAL / FREE 状态内：changeTier() 可切换 tier
  TrialExpiryJob 仅做批量降级，请求时 effectiveTier() 中的 isTrialActive() 检查是主要防线
```

### 3.2 SubscriptionTier（值对象枚举）

```java
public enum SubscriptionTier {
    BASIC("basic", 0, 50),
    STANDARD("standard", 29900, 200),      // ¥299 = 29900 分
    PREMIUM("premium", 69900, 1000),       // ¥699 = 69900 分
    ENTERPRISE("enterprise", 0, Integer.MAX_VALUE);

    private final String value;
    private final int monthlyPriceCents;
    private final int includedLivestock;

    public int calculateMonthlyFee(int livestockCount) {
        if (this == ENTERPRISE)
            throw new ApiException(ErrorCode.ENTERPRISE_CUSTOM_PRICING,
                "Enterprise 需定制计费，不可自动计算");
        int base = monthlyPriceCents;
        int overflow = Math.max(0, livestockCount - includedLivestock);
        return base + overflow * getOveragePriceCents();
    }

    private int getOveragePriceCents() {
        return switch (this) {
            case BASIC -> 300;       // ¥3/头/月
            case STANDARD -> 200;    // ¥2/头/月
            case PREMIUM -> 100;     // ¥1/头/月
            default -> 0;
        };
    }
}
```

围栏等配额由 feature_gates 表统一管控，枚举中不重复定义。

### 3.3 Contract（聚合根）

```java
public class Contract extends AggregateRoot {

    private Long tenantId;
    private String contractNumber;     // CT-YYYY-NNNN
    private String billingModel;
    private SubscriptionTier effectiveTier;
    private BigDecimal revenueShareRatio;
    private ContractStatus status;
    private Long signedBy;
    private Instant signedAt;
    private Instant startedAt;
    private Instant expiresAt;

    // ── 工厂方法 ──

    public static Contract create(Long tenantId, String contractNumber,
                                   String billingModel, SubscriptionTier effectiveTier,
                                   BigDecimal revenueShareRatio, Instant startedAt) {
        if (revenueShareRatio != null
            && (revenueShareRatio.compareTo(BigDecimal.ZERO) < 0
                || revenueShareRatio.compareTo(BigDecimal.ONE) > 0)) {
            throw new ApiException(ErrorCode.INVALID_PARAM, "分润比例须在 0~1 之间");
        }
        Contract c = new Contract();
        c.tenantId = tenantId;
        c.contractNumber = contractNumber;
        c.billingModel = billingModel;
        c.effectiveTier = effectiveTier;
        c.revenueShareRatio = revenueShareRatio;
        c.status = ContractStatus.DRAFT;
        c.startedAt = startedAt;
        return c;
    }

    // ── 状态转换 ──

    public void sign(Long signerUserId) {
        requireStatus(ContractStatus.DRAFT);
        this.status = ContractStatus.ACTIVE;
        this.signedBy = signerUserId;
        this.signedAt = Instant.now();
        this.registerEvent(new ContractSignedEvent(tenantId, contractNumber));
    }

    public void suspend() {
        requireStatus(ContractStatus.ACTIVE);
        this.status = ContractStatus.SUSPENDED;
    }

    public void reactivate() {
        requireStatus(ContractStatus.SUSPENDED);
        this.status = ContractStatus.ACTIVE;
    }

    public void expire() {
        requireStatus(ContractStatus.ACTIVE, ContractStatus.SUSPENDED);
        this.status = ContractStatus.EXPIRED;
    }

    public void terminate() {
        requireStatus(ContractStatus.ACTIVE, ContractStatus.SUSPENDED);
        this.status = ContractStatus.TERMINATED;
    }

    // ── 业务方法 ──

    public BigDecimal calculateRevenueShare(BigDecimal totalDeviceFee) {
        return totalDeviceFee.multiply(revenueShareRatio);
    }

    public boolean isActive() { return status == ContractStatus.ACTIVE; }
}
```

状态机：

```
  create()       sign()
     │             │
     ▼             ▼
┌─────────┐   ┌─────────┐
│  DRAFT  │──►│ ACTIVE ◄────┐
└─────────┘   └─────────┘    │
                  │  ▲        │ reactivate()
     suspend()   │  │        │
                  ▼  │        │
              ┌───────────┐   │
              │ SUSPENDED │───┘
              └───────────┘
                  │
    expire() / terminate()
                  │
       ┌──────────┴──────────┐
       ▼                     ▼
 ┌──────────┐          ┌────────────┐
 │ EXPIRED  │          │ TERMINATED │
 └──────────┘          └────────────┘
```

### 3.4 RevenuePeriod（聚合根）

```java
public class RevenuePeriod extends AggregateRoot {

    private Long contractId;
    private Long tenantId;
    private String settlementPeriod;            // YYYY-MM
    private BigDecimal totalDeviceFee;
    private int totalLivestock;
    private BigDecimal revenueShareRatio;
    private BigDecimal revenueShareAmount;
    private RevenueSettlementStatus status;
    private Instant confirmedAt;
    private Instant settledAt;

    /**
     * 计算分润周期
     * @pre contract.isActive() — 调用方须先校验合同状态（ApplicationService 层过滤 ACTIVE 合同）
     * @pre 子 Tenant 的 Subscription 状态为 ACTIVE/FREE
     */
    public static RevenuePeriod calculate(Long contractId, Long tenantId,
                                           String period, BigDecimal totalDeviceFee,
                                           int totalLivestock, BigDecimal ratio) {
        RevenuePeriod rp = new RevenuePeriod();
        rp.contractId = contractId;
        rp.tenantId = tenantId;
        rp.settlementPeriod = period;
        rp.totalDeviceFee = totalDeviceFee;
        rp.totalLivestock = totalLivestock;
        rp.revenueShareRatio = ratio;
        rp.revenueShareAmount = totalDeviceFee.multiply(ratio);
        rp.status = RevenueSettlementStatus.PENDING;
        return rp;
    }

    public void confirmByPlatform() {
        requireStatus(RevenueSettlementStatus.PENDING);
        this.status = RevenueSettlementStatus.PLATFORM_CONFIRMED;
    }

    public void confirmByPartner() {
        requireStatus(RevenueSettlementStatus.PLATFORM_CONFIRMED);
        this.status = RevenueSettlementStatus.PARTNER_CONFIRMED;
        this.confirmedAt = Instant.now();
    }

    public void settle() {
        requireStatus(RevenueSettlementStatus.PARTNER_CONFIRMED);
        this.status = RevenueSettlementStatus.SETTLED;
        this.settledAt = Instant.now();
        this.registerEvent(new RevenueSettledEvent(tenantId, settlementPeriod, revenueShareAmount));
    }
}
```

### 3.5 SubscriptionService（聚合根，Licensed 模式专用）

```java
public class SubscriptionService extends AggregateRoot {

    private Long tenantId;
    private String serviceKeyPrefix;
    private String serviceKeyHash;
    private SubscriptionServiceStatus status;
    private SubscriptionTier effectiveTier;
    private Integer deviceQuota;
    private Instant lastHeartbeatAt;
    private int heartbeatIntervalHrs;
    private int gracePeriodDays;
    private Instant startedAt;
    private Instant expiresAt;

    public static SubscriptionService provision(Long tenantId, String rawServiceKey,
                                                  SubscriptionTier tier, Integer deviceQuota) {
        SubscriptionService ss = new SubscriptionService();
        ss.tenantId = tenantId;
        ss.serviceKeyPrefix = rawServiceKey.substring(0, Math.min(8, rawServiceKey.length()));
        ss.serviceKeyHash = sha256(rawServiceKey);
        ss.effectiveTier = tier;
        ss.deviceQuota = deviceQuota;
        ss.status = SubscriptionServiceStatus.ACTIVE;
        ss.lastHeartbeatAt = Instant.now();
        ss.heartbeatIntervalHrs = 24;
        ss.gracePeriodDays = 15;
        ss.startedAt = Instant.now();
        return ss;
    }

    public void recordHeartbeat() {
        requireStatus(SubscriptionServiceStatus.ACTIVE, SubscriptionServiceStatus.GRACE_PERIOD);
        this.lastHeartbeatAt = Instant.now();
        if (this.status == SubscriptionServiceStatus.GRACE_PERIOD) {
            this.status = SubscriptionServiceStatus.ACTIVE;
        }
    }

    public void checkHeartbeat() {
        if (status != SubscriptionServiceStatus.ACTIVE) return;
        Instant deadline = lastHeartbeatAt.plus(heartbeatIntervalHrs, ChronoUnit.HOURS);
        if (Instant.now().isAfter(deadline)) {
            this.status = SubscriptionServiceStatus.GRACE_PERIOD;
            this.registerEvent(new ServiceHeartbeatLostEvent(tenantId));
        }
    }

    public void degrade() {
        requireStatus(SubscriptionServiceStatus.GRACE_PERIOD);
        this.status = SubscriptionServiceStatus.DEGRADED;
        this.effectiveTier = SubscriptionTier.BASIC;
        this.registerEvent(new ServiceDegradedEvent(tenantId));
    }

    public void revoke() {
        this.status = SubscriptionServiceStatus.REVOKED;
    }

    /** 到期处理 */
    public void expire() {
        requireStatus(SubscriptionServiceStatus.ACTIVE, SubscriptionServiceStatus.GRACE_PERIOD);
        this.status = SubscriptionServiceStatus.EXPIRED;
    }

    /** 调整设备配额（Enterprise 扩容） */
    public void adjustQuota(Integer newQuota) {
        requireStatus(SubscriptionServiceStatus.ACTIVE);
        this.deviceQuota = newQuota;
        registerEvent(new ServiceQuotaAdjustedEvent(tenantId, newQuota));
    }

    /** 校验 serviceKey（常量时间比较，防止时序攻击） */
SubscriptionService 状态机：

```
provision()
     │
     ▼
┌─────────┐  心跳超时   ┌──────────────┐  宽限期到期  ┌───────────┐
│  ACTIVE │────────────►│ GRACE_PERIOD │───────────►│ DEGRADED  │
└─────────┘             └──────────────┘            └───────────┘
     ▲                        │
     │  recordHeartbeat()     │ revoke()
     └────────────────────────┘
                                     │ revoke() (ACTIVE/GRACE_PERIOD/DEGRADED 均可)
                                     ▼
                               ┌───────────┐
                               │  REVOKED  │
                               └───────────┘

expires_at 到期（由 GracePeriodExpiryJob 扫描）：
  ACTIVE / GRACE_PERIOD / DEGRADED ──► EXPIRED
```

### 3.6 领域事件
        return MessageDigest.isEqual(
            sha256(rawKey).getBytes(StandardCharsets.UTF_8),
            serviceKeyHash.getBytes(StandardCharsets.UTF_8));
    }
}
```

### 3.6 领域事件

| 事件 | 触发场景 | 跨上下文消费方 |
|------|---------|---------------|
| SubscriptionCreatedEvent | 创建订阅 | Identity: 触发 TenantPhase SAMPLE→BATCH |
| SubscriptionTierChangedEvent | Tier 变更 | Ranch/IoT: 更新配额缓存 |
| ContractSignedEvent | 合同签署 | Identity: 创建 Partner 下的子 Tenant |
| RevenueSettledEvent | 结算完成 | 通知 |
| ServiceHeartbeatLostEvent | 心跳丢失 | 通知运维团队 |
| ServiceDegradedEvent | 服务降级 | Ranch/IoT: 降级配额 |
| ServiceQuotaAdjustedEvent | 配额调整 | Ranch/IoT: 更新配额缓存 |

---

## 4. 配额引擎与 API 端点

### 4.1 配额引擎架构

```
HTTP Request
    │
    ▼
JwtAuthenticationFilter (已有) → 设置 TenantContext
    │
    ▼
FarmScopeInterceptor (已有) → 验证 farm 归属
    │
    ▼
QuotaInterceptor (新增)
    │ 1. 读取 Subscription.effectiveTier()
    │ 2. 查询 feature_gates 中该 tier 的规则
    │ 3. 通过 UsageResolver 获取当前用量
    │ 4. 超出 → 403 QUOTA_EXCEEDED
    ▼
Controller / Service
```

#### 4.1.1 QuotaApplicationService

```java
@Service
@RequiredArgsConstructor
public class QuotaApplicationService {

    private final SubscriptionRepository subscriptionRepository;

    public QuotaResult checkQuota(Long tenantId, String featureKey, int currentUsage) {
        Subscription sub = subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "订阅不存在"));

        if (!sub.isActiveOrTrial()) {
            return QuotaResult.denied("订阅状态非活跃: " + sub.getStatus());
        }

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

    private FeatureGate loadGate(String featureKey, SubscriptionTier tier) {
        // 查 feature_gates 表，缓存到 Redis (key: quota:{featureKey}:{tier})
    }
}
```

#### 4.1.2 QuotaResult

```java
public class QuotaResult {
    private final boolean allowed;
    private final String denyReason;
    private final int retentionDays;

    public static QuotaResult allowed() { ... }
    public static QuotaResult denied(String reason) { ... }
    public static QuotaResult allowedWithRetention(int days) { ... }
}
```

#### 4.1.3 UsageResolver 接口

```java
/**
 * 配额用量查询接口。
 * resolve() 返回的是当前已有数量（不含当前请求中的资源），用于 limit 类型的 < 比较。
 * 统计粒度：围栏/牲畜/设备按 farm 级统计，API 调用量按 tenant 级统计。
 */
public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, Long farmId);  // farmId 可为 null（tenant 级）
}
```

实现：

| Resolver | featureKey | 粒度 | 数据源 |
|----------|-----------|------|--------|
| FenceUsageResolver | fence_management | farm | ranch.fences |
| LivestockUsageResolver | livestock_registration | farm | ranch.livestock |
| ApiCallUsageResolver | api_calls | tenant | Redis / api_usage_logs |

#### 4.1.4 @QuotaCheck 注解

```java
@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
public @interface QuotaCheck {
    String feature();
}
```

#### 4.1.5 QuotaInterceptor

```java
@Component
@RequiredArgsConstructor
public class QuotaInterceptor implements HandlerInterceptor {

    private final QuotaApplicationService quotaService;
    private final Map<String, UsageResolver> resolvers;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                              Object handler) {
        if (!(handler instanceof HandlerMethod hm)) return true;
        QuotaCheck annotation = hm.getMethodAnnotation(QuotaCheck.class);
        if (annotation == null) return true;

        Long tenantId = TenantContext.getCurrentTenant();
        if (tenantId == null) return true;

        Long farmId = FarmContext.getCurrentFarm();
        int currentUsage = resolveUsage(annotation.feature(), tenantId, farmId);
        QuotaResult result = quotaService.checkQuota(tenantId, annotation.feature(), currentUsage);

        if (!result.isAllowed()) {
            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"code\":\"QUOTA_EXCEEDED\",\"message\":\""
                + result.getDenyReason() + "\"}");
            return false;
        }
        return true;
    }

    private int resolveUsage(String featureKey, Long tenantId, Long farmId) {
        UsageResolver resolver = resolvers.get(featureKey);
        if (resolver == null) return 0;
        return resolver.resolve(tenantId, farmId);
    }
}
```

使用示例：

```java
@PostMapping("/farms/{farmId}/fences")
@QuotaCheck(feature = "fence_management")
public ResponseEntity<ApiResponse<FenceDto>> createFence(...) { ... }
```

> **api_calls 门控范围**：QuotaCheck(feature = "api_calls") 仅应用于 `/api/v1/open/**` 的 Open API 端点，不影响 App 内部 API 请求。UsageResolver 返回的是**当前已有数量**（不含当前请求中的资源）。

### 4.2 API 端点

#### 4.2.1 App API — `/api/v1/`

| 方法 | 路径 | 说明 | 权限 |
|------|------|------|------|
| GET | `/subscription` | 查看当前订阅状态+Tier+用量 | 认证用户 |
| GET | `/subscription/plans` | 查看可用的订阅计划（定价信息） | 认证用户 |
| POST | `/subscription/checkout` | 发起订阅（MVP: Mock 支付） | owner |
| PUT | `/subscription/tier` | 升级/降级 Tier | owner |
| POST | `/subscription/cancel` | 取消订阅 | owner |
| GET | `/subscription/usage` | 当前用量 vs 配额 | 认证用户 |
| GET | `/contracts/me` | 查看自己的合同（B2B） | reseller/enterprise |
| GET | `/revenue/periods` | 查看自己的分润记录 | reseller |
| POST | `/revenue/periods/{id}/confirm` | Partner 确认结算 | reseller |

checkout 请求体：

```json
{
    "tier": "standard",
    "billingCycle": "monthly",
    "idempotencyKey": "550e8400-e29b-41d4-a716-446655440000"
}
```

#### 4.2.2 Admin API — `/api/v1/admin/`

**订阅管理：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/subscriptions` | 列出所有订阅（支持 status/tier 过滤） |
| GET | `/admin/subscriptions/{id}` | 订阅详情 |
| PUT | `/admin/subscriptions/{id}/status` | 变更订阅状态 |

PUT status 请求体：

```json
{
    "targetStatus": "suspended",
    "reason": "欠费暂停"
}
```

后端校验状态机合法性，非法跳转返回 409。

> **Admin API 通用约定**：所有列表接口支持 `page`/`size` 分页和字段过滤（如 `?status=active&tier=premium`）。合同签署、状态变更等关键操作记录审计日志。

**合同管理：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/contracts` | 列出所有合同 |
| POST | `/admin/contracts` | 创建合同草稿 |
| GET | `/admin/contracts/{id}` | 合同详情 |
| PUT | `/admin/contracts/{id}` | 修改合同草稿 |
| POST | `/admin/contracts/{id}/sign` | 签署合同 |
| PUT | `/admin/contracts/{id}/status` | 合同状态变更 |

**分润结算：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/revenue/periods` | 列出结算周期 |
| GET | `/admin/revenue/periods/{id}` | 结算详情 |
| POST | `/admin/revenue/calculate` | 触发月度分润计算（按月去重，幂等） |
| POST | `/admin/revenue/periods/{id}/confirm` | 平台确认结算 |
| POST | `/admin/revenue/periods/{id}/recalculate` | 重新计算（冲正 settled 记录） |

**Licensed 服务管理：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/subscription-services` | 列出所有 Licensed 服务 |
| POST | `/admin/subscription-services` | 新建服务（生成 serviceKey） |
| GET | `/admin/subscription-services/{id}` | 服务详情 |
| PUT | `/admin/subscription-services/{id}/status` | 状态变更 |

**功能门控配置：**

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/feature-gates` | 列出所有功能门控规则 |
| PUT | `/admin/feature-gates/{id}` | 修改功能门控配置 |

**租户扩展（补充 TenantAdminController）：**

| 方法 | 路径 | 说明 |
|------|------|------|
| PUT | `/admin/tenants/{id}/type` | 设置租户类型 |
| PUT | `/admin/tenants/{id}/billing-model` | 设置计费模式 |
| POST | `/admin/tenants/{id}/activate-subscription` | 管理员为租户激活订阅 |

### 4.3 端到端流程

**场景 1: B2C 直订阅**

1. 用户注册 → Identity 创建 Tenant (type=rancher, billingModel=direct, phase=SAMPLE)
2. Commerce 自动创建 Subscription (status=TRIAL, tier=PREMIUM, trialEndsAt=now+14d)
3. 14 天后 TrialExpiryJob → subscription.expireTrial() → status=FREE, tier=BASIC
4. 用户选择 Standard → POST /subscription/checkout (Mock 支付)
5. 支付成功 → subscription.changeTier(STANDARD) → status=ACTIVE
6. 用户升级 → PUT /subscription/tier { tier: "premium" } → changeTier(PREMIUM)

**场景 2: B2B 分润**

1. Admin 创建 Partner Tenant (type=reseller, billingModel=revenue_share)
2. Admin 创建合同 → POST /admin/contracts
3. Admin 签署合同 → POST /admin/contracts/{id}/sign → 合同生效
4. 每月 1 日 RevenueCalculationJob → 过滤 status=ACTIVE 的合同
   - 遍历 Partner 旗下所有 Farm
   - 校验子 Tenant 的 Subscription 状态为 ACTIVE/FREE
   - 汇总牲畜数 × 设备单价 = 设备月费
   - 分润金额 = 设备月费 × revenueShareRatio
   - 生成 RevenuePeriod (status=pending)
5. Platform 确认 → POST /admin/revenue/periods/{id}/confirm → platform_confirmed
6. Partner 确认 → POST /revenue/periods/{id}/confirm → partner_confirmed
7. 系统结算 → settle() → settled

**场景 3: Licensed 独立部署**

1. Admin 创建 Enterprise Tenant (type=enterprise, billingModel=licensed)
2. Admin 创建 SubscriptionService → 生成 serviceKey
3. 客户系统每 24h 发送心跳 → recordHeartbeat()
4. HeartbeatCheckJob → checkHeartbeat() → 超时进入 GRACE_PERIOD
5. 15 天内未恢复 → degrade() → 降级为 BASIC

### 4.4 定时任务

| 任务 | 频率 | 职责 |
|------|------|------|
| TrialExpiryJob | 每小时 | 扫描 `status=TRIAL AND trial_ends_at < now()`，调用 expireTrial() |
| SubscriptionExpiryJob | 每小时 | 扫描 `status=ACTIVE AND expires_at < now()`，调用 markRenewalFailed()（续费失败，进入 7 天宽限期） |
| RenewalFailedExpiryJob | 每天 | 扫描 `status=RENEWAL_FAILED` 且超过 7 天，调用 downgradeAfterRenewalFailure() |
| HeartbeatCheckJob | 每 6 小时 | 扫描 ACTIVE 的 SubscriptionService，调用 checkHeartbeat() |
| GracePeriodExpiryJob | 每天 | 扫描 `status=GRACE_PERIOD AND last_heartbeat_at + gracePeriodDays < now()`，调用 degrade()；同时扫描 `status=ACTIVE AND expires_at < now()` 的 subscription_services，调用 expire() |
| RevenueCalculationJob | 每月 1 日 | 过滤 status=ACTIVE 的合同，按 Contract 维度计算上月分润，生成 RevenuePeriod |

---

## 5. Tier 定价与配额参考

### 5.1 B2C 订阅定价

| Tier | 月费 | 含牲畜数 | 超出费用 | 数据保留 | SLA |
|------|------|---------|---------|---------|-----|
| basic | ¥0 | 50 头 | ¥3/头/月 | 7 天 | 99.5% |
| standard | ¥299 | 200 头 | ¥2/头/月 | 30 天 | 99.5% |
| premium | ¥699 | 1000 头 | ¥1/头/月 | 90 天 | 99.9% |
| enterprise | 定制 | 无限 | — | 3 年 | 99.99% |

### 5.2 设备月费（独立于 Tier）

- GPS 追踪器：¥15/头/月
- 瘤胃胶囊：¥30/头/月

### 5.3 API 开放平台定价

| API Tier | 月费 | 含调用量 | 超出费用 |
|----------|------|---------|---------|
| free | ¥0 | 1000 次/月 | — |
| growth | ¥500 | 10000 次 | ¥0.01/次 |
| scale | ¥2000 | 100000 次 | ¥0.005/次 |

---

*设计规格生成日期: 2026-05-18*
*评审记录: docs/superpowers/reviews/2026-05-17-Commerce限界上下文设计评审.md, 2026-05-17-Commerce-领域模型设计评审.md, 2026-05-18-Commerce-配额引擎与API设计评审.md*

---

## 附录：延后事项

| 事项 | 说明 | 触发条件 |
|------|------|---------|
| TenantPhase 重命名 | SAMPLE/BATCH → TRIAL/ACTIVE | 团队统一后 |
| 合同续签关联 | 加 parent_contract_id 关联原始合同 | B2B 客户有续签需求时 |
| 账单明细模型 | BillingApplicationService + Invoice/InvoiceItem | 需向牧场主展示月度账单明细时 |
| 真实支付集成 | Mock → 支付宝/微信支付 | 商业化上线时 |
