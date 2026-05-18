# Commerce 限界上下文实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 Commerce 限界上下文——订阅管理、合同管理、分润结算、Licensed 服务、配额引擎、领域事件、通知系统，支撑四种计费模型（direct/revenue_share/licensed/api_usage）。

**Architecture:** 独立 Commerce 限界上下文与 Identity/Ranch/IoT 平级，按 DDD 四层洋葱架构（domain → application → infrastructure → interfaces）。聚合根通过状态机管控生命周期，配额通过 @QuotaCheck 注解 + QuotaInterceptor 拦截（两道防线），定时任务处理过期/续费失败/结算，Spring ApplicationEvent 驱动通知。

**Tech Stack:** Spring Boot 3.3.0 / Java 17 / JPA + Hibernate / PostgreSQL 16 / Flyway / JUnit 5 + Mockito / Spring ApplicationEvent

**Spec:** `docs/superpowers/specs/2026-05-18-commerce-context-design.md` (v3)

**Review:** `docs/superpowers/reviews/2026-05-18-Commerce-架构评审与Plan修正.md`

**前置:** MVP Phase 1 已完成，V1-V5 迁移已存在

---

## File Structure

### commerce/ — Create

| File | Responsibility |
|------|---------------|
| `domain/model/Subscription.java` | 订阅聚合根（状态机、effectiveTier、billingModel） |
| `domain/model/SubscriptionTier.java` | Tier 枚举（USD 美分定价、超量计算） |
| `domain/model/SubscriptionStatus.java` | 订阅状态枚举（7 种） |
| `domain/model/Contract.java` | 合同聚合根（DRAFT→ACTIVE、分润计算） |
| `domain/model/ContractStatus.java` | 合同状态枚举（5 种，含 DRAFT） |
| `domain/model/RevenuePeriod.java` | 分润结算聚合根（三方确认状态机） |
| `domain/model/RevenueSettlementStatus.java` | 结算状态枚举 |
| `domain/model/SubscriptionService.java` | Licensed 服务聚合根（License 文件、心跳、deviceQuota） |
| `domain/model/SubscriptionServiceStatus.java` | 服务状态枚举（6 种，含 PROVISIONED） |
| `domain/model/FeatureGate.java` | 功能门控值对象（4 种 gateType） |
| `domain/model/event/*.java` | 24 个领域事件 (record) |
| `domain/repository/SubscriptionRepository.java` | 订阅 Repository port |
| `domain/repository/ContractRepository.java` | 合同 Repository port |
| `domain/repository/RevenuePeriodRepository.java` | 分润 Repository port |
| `domain/repository/SubscriptionServiceRepository.java` | 服务 Repository port |
| `domain/repository/FeatureGateRepository.java` | 功能门控 Repository port |
| `application/dto/QuotaResult.java` | 配额校验结果（allowed/denied/allowedWithRetention） |
| `application/dto/CheckoutRequest.java` | 结算请求 DTO |
| `application/dto/SubscriptionResponse.java` | 订阅响应 DTO |
| `application/dto/ContractResponse.java` | 合同响应 DTO |
| `application/dto/RevenuePeriodResponse.java` | 分润响应 DTO |
| `application/service/SubscriptionApplicationService.java` | 订阅应用服务 |
| `application/service/ContractApplicationService.java` | 合同应用服务 |
| `application/service/RevenueApplicationService.java` | 分润应用服务 |
| `application/service/QuotaApplicationService.java` | 配额引擎服务（两道防线） |
| `application/service/UsageResolver.java` | 用量解析接口（纯值签名） |
| `application/service/FarmLivestockUsageResolver.java` | farm 级牲畜用量 |
| `application/service/FarmFenceUsageResolver.java` | farm 级围栏用量 |
| `application/scheduler/CommerceScheduler.java` | 定时任务（7 Job） |
| `application/listener/NotificationEventListener.java` | 事件监听→写 notification 表 |
| `infrastructure/persistence/entity/*.java` | 5 JPA Entity |
| `infrastructure/persistence/mapper/*.java` | 5 Mapper |
| `infrastructure/persistence/Jpa*RepositoryImpl.java` | 5 Repository 实现 |
| `infrastructure/persistence/Spring*JpaRepository.java` | 5 Spring Data JPA |
| `interfaces/SubscriptionController.java` | App 订阅 API (6 端点) |
| `interfaces/CommerceController.java` | App 合同/分润 API (3 端点) |
| `interfaces/AdminSubscriptionController.java` | Admin 订阅管理 (3 端点) |
| `interfaces/AdminContractController.java` | Admin 合同管理 (6 端点) |
| `interfaces/AdminRevenueController.java` | Admin 分润管理 (5 端点) |
| `interfaces/AdminServiceController.java` | Admin 服务管理 (5 端点) |
| `interfaces/AdminFeatureGateController.java` | Admin 功能门控 (2 端点) |
| `interfaces/QuotaCheck.java` | 配额注解 |
| `interfaces/QuotaInterceptor.java` | 配额拦截器 |

### shared/ — Modify

| File | Change |
|------|--------|
| `shared/common/ErrorCode.java` | 新增 9 个 Commerce 错误码 |

### identity/ — Modify

| File | Change |
|------|--------|
| `identity/domain/model/Tenant.java` | 新增 type + billingModel 字段 |

### ranch/ — Modify

| File | Change |
|------|--------|
| `ranch/interfaces/FenceController.java` | createFence 加 @QuotaCheck(feature="fence_management") |
| `ranch/interfaces/LivestockController.java` | registerLivestock 加 @QuotaCheck(feature="livestock_management") |

### shared/notification/ — Create

| File | Responsibility |
|------|---------------|
| `Notification.java` | 通知实体 |
| `NotificationRepository.java` | 通知 Repository |
| `NotificationService.java` | 通知写入服务 |

### test/ — Create

| File | Test Target |
|------|------------|
| `domain/model/SubscriptionTest.java` | 订阅聚合根（含 recoverFromRenewalFailure） |
| `domain/model/SubscriptionTierTest.java` | Tier 定价与超量（USD 美分） |
| `domain/model/ContractTest.java` | 合同聚合根（含 DRAFT→sign） |
| `domain/model/RevenuePeriodTest.java` | 分润聚合根 |
| `domain/model/SubscriptionServiceTest.java` | Licensed 服务（含 License 验证） |
| `domain/model/FeatureGateTest.java` | 功能门控值对象 |
| `application/service/QuotaApplicationServiceTest.java` | 配额引擎（两道防线） |
| `application/service/SubscriptionApplicationServiceTest.java` | 订阅应用服务 |
| `application/service/ContractApplicationServiceTest.java` | 合同应用服务 |

### resources/ — Create

| File | Responsibility |
|------|---------------|
| `db/migration/V6__create_commerce_tables.sql` | 全部 DDL + 种子数据 (7 张表/变更) |

---

## Task Dependency Graph

```
Task 1 (DDL)
    ↓
Task 2 (Enums + ErrorCode + Events)
    ↓
Task 3 (Subscription) ──┐
Task 4 (Contract + RevenuePeriod) ──┤  ← 可并行
Task 5 (SubscriptionService) ──┘
    ↓
Task 6 (FeatureGate + QuotaEngine)
    ↓
Task 7 (Persistence Layer)
    ↓
Task 8 (@QuotaCheck + Interceptor + UsageResolver)
    ↓
Task 9 (Notification + EventListener)
    ↓
Task 10 (Application Services)
    ↓
Task 11 (Controllers — App + Admin)
    ↓
Task 12 (Scheduler — 7 Jobs)
    ↓
Task 13 (Integration + Tenant Extension)
```

Tasks 3, 4, 5 可并行。Tasks 6-13 严格串行。

---

## Task 1: V6 Flyway Migration — Commerce DDL + 种子数据

**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V6__create_commerce_tables.sql`
- Reference: Spec Section 2

- [ ] **Step 1: 创建迁移文件**

按 Spec Section 2 完整 DDL，包含 7 张表/变更：

```sql
-- subscriptions (含 billing_model, cancelled_at)
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

-- contracts (含 effective_tier, signed_by, started_at, DRAFT 默认状态)
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

-- revenue_periods (含 tenant_id, revenue_share_ratio 快照)
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

-- subscription_services (含 effective_tier, device_quota, started_at, 可配置参数)
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

-- feature_gates (含 retention_days, is_enabled, 4 种 gateType)
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

-- notifications
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

-- tenants 扩展字段
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS billing_model VARCHAR(20) DEFAULT 'direct';
UPDATE tenants SET type = 'rancher', billing_model = 'direct' WHERE type IS NULL;

-- 种子数据：feature_gates (44 条)

-- none 类型 (16 条)
INSERT INTO feature_gates (tier, feature_key, gate_type) VALUES
    ('basic', 'gps_tracking', 'none'), ('standard', 'gps_tracking', 'none'),
    ('premium', 'gps_tracking', 'none'), ('enterprise', 'gps_tracking', 'none'),
    ('basic', 'alerts', 'none'), ('standard', 'alerts', 'none'),
    ('premium', 'alerts', 'none'), ('enterprise', 'alerts', 'none'),
    ('basic', 'fence_management', 'none'), ('standard', 'fence_management', 'none'),
    ('premium', 'fence_management', 'none'), ('enterprise', 'fence_management', 'none'),
    ('basic', 'livestock_management', 'none'), ('standard', 'livestock_management', 'none'),
    ('premium', 'livestock_management', 'none'), ('enterprise', 'livestock_management', 'none');
-- 注：none 类型需要用完整 INSERT 含 limit_value=NULL

-- limit 类型 (16 条)
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value) VALUES
    ('basic', 'fence_management', 'limit', 3),
    ('basic', 'livestock_management', 'limit', 50),
    ('basic', 'device_management', 'limit', 10),
    ('basic', 'api_calls', 'limit', 0),
    ('standard', 'fence_management', 'limit', 5),
    ('standard', 'livestock_management', 'limit', 200),
    ('standard', 'device_management', 'limit', 50),
    ('standard', 'api_calls', 'limit', 0),
    ('premium', 'fence_management', 'limit', 10),
    ('premium', 'livestock_management', 'limit', 1000),
    ('premium', 'device_management', 'limit', 200),
    ('premium', 'api_calls', 'limit', 10000),
    ('enterprise', 'fence_management', 'limit', 999),
    ('enterprise', 'livestock_management', 'limit', 99999),
    ('enterprise', 'device_management', 'limit', 9999),
    ('enterprise', 'api_calls', 'limit', 99999);

-- lock 类型 (8 条)
INSERT INTO feature_gates (tier, feature_key, gate_type, is_enabled) VALUES
    ('basic', 'health_monitoring', 'lock', FALSE),
    ('basic', 'breeding_analytics', 'lock', FALSE),
    ('standard', 'health_monitoring', 'lock', TRUE),
    ('standard', 'breeding_analytics', 'lock', FALSE),
    ('premium', 'health_monitoring', 'lock', TRUE),
    ('premium', 'breeding_analytics', 'lock', TRUE),
    ('enterprise', 'health_monitoring', 'lock', TRUE),
    ('enterprise', 'breeding_analytics', 'lock', TRUE);

-- filter 类型 (4 条)
INSERT INTO feature_gates (tier, feature_key, gate_type, retention_days) VALUES
    ('basic', 'alert_history', 'filter', 7),
    ('standard', 'alert_history', 'filter', 30),
    ('premium', 'alert_history', 'filter', 90),
    ('enterprise', 'alert_history', 'filter', 365);

-- none 类型覆盖上面的 limit（同 feature_key 不同 tier 可以同时有 none 和 limit）
-- 注意：上面的 none 和 limit 对 fence_management/livestock_management 有冲突
-- 正确做法：每对 (tier, feature_key) 只有一条，gateType 取最严格的
-- 修正：去掉 none 类型中对 fence_management/livestock_management 的重复

-- 示例订阅
INSERT INTO subscriptions (tenant_id, tier, billing_model, status, billing_cycle, started_at, expires_at, trial_ends_at)
VALUES (1, 'premium', 'direct', 'trial', 'monthly', now(), now() + interval '14 days', now() + interval '14 days');

-- 合同编号序列
CREATE SEQUENCE IF NOT EXISTS contract_number_seq START 1;
```

> **注意**: 种子数据中 none 和 limit 对同一 (tier, feature_key) 不可重复。fence_management/livestock_management 在 basic/standard 有 limit，在 premium/enterprise 也是 limit（上限更高）。none 类型仅用于 gps_tracking 和 alerts。实际 SQL 需去重，此处伪代码示意。

- [ ] **Step 2: 验证迁移可执行**

Run: `cd smart-livestock-server && ./gradlew flywayMigrate -x test 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V6__create_commerce_tables.sql
git commit -m "feat(commerce): add V6 migration — 6 tables + notifications + seed data"
```

---

## Task 2: Enums + ErrorCode + Events

**Files:**
- Modify: `ErrorCode.java` (新增 9 个)
- Create: 5 个枚举类 + 24 个领域事件
- Test: `SubscriptionTierTest.java`

- [ ] **Step 1: 扩展 ErrorCode**

新增：ENTERPRISE_CUSTOM_PRICING, INVALID_BILLING_MODEL, INVALID_REVENUE_SHARE_RATIO, SUBSCRIPTION_NOT_FOUND, SUBSCRIPTION_NOT_ACTIVE, CONTRACT_NOT_ACTIVE, SERVICE_KEY_MISMATCH, SERVICE_LICENSE_EXPIRED, SETTLEMENT_DUPLICATE_CONFIRM

- [ ] **Step 2: 创建枚举类**

SubscriptionTier: BASIC(0, 50, 40), STANDARD(1400, 200, 30), PREMIUM(2800, 1000, 15), ENTERPRISE(-1, -1, -1)
SubscriptionStatus: TRIAL, ACTIVE, FREE, SUSPENDED, RENEWAL_FAILED, CANCELLED, EXPIRED
ContractStatus: DRAFT, ACTIVE, SUSPENDED, EXPIRED, TERMINATED
RevenueSettlementStatus: PENDING, PLATFORM_CONFIRMED, PARTNER_CONFIRMED, SETTLED
SubscriptionServiceStatus: PROVISIONED, ACTIVE, GRACE_PERIOD, DEGRADED, EXPIRED

- [ ] **Step 3: 创建 24 个领域事件**

全部 record，放在 `domain/model/event/` 下

- [ ] **Step 4: 写 SubscriptionTierTest**

测试 calculateMonthlyFee：含内、超量、Enterprise 抛异常

- [ ] **Step 5: 运行测试**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add enums, ErrorCode extensions, 24 domain events"
```

---

## Task 3: Subscription 聚合根

**Files:**
- Create: `Subscription.java`
- Test: `SubscriptionTest.java`

- [ ] **Step 1: 写 SubscriptionTest**

覆盖：startTrial, activate, expireTrial, effectiveTier, changeTier(FREE→ACTIVE), suspend, reactivate, markRenewalFailed, recoverFromRenewalFailure, downgradeAfterRenewalFailure, cancel(cancelledAt), markExpired, requireStatus 非法跳转

- [ ] **Step 2: 实现 Subscription**

字段：id, tenantId, tier, billingModel, status, billingCycle, startedAt, expiresAt, trialEndsAt, cancelledAt。状态机按 Spec Section 3.2。所有状态转换产生对应领域事件。

- [ ] **Step 3: 运行测试**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(commerce): add Subscription aggregate root with state machine and events"
```

---

## Task 4: Contract + RevenuePeriod 聚合根

**Files:**
- Create: `Contract.java`, `RevenuePeriod.java`
- Test: `ContractTest.java`, `RevenuePeriodTest.java`

- [ ] **Step 1: 写 ContractTest**

覆盖：create→DRAFT, sign→ACTIVE, 分润比例校验, suspend/reactivate, terminate, markExpired, calculateRevenueShare

- [ ] **Step 2: 写 RevenuePeriodTest**

覆盖：create→PENDING, confirmByPlatform, confirmByPartner, settle, 非法跳转

- [ ] **Step 3: 实现 Contract**

字段：id, tenantId, contractNumber, billingModel, effectiveTier, revenueShareRatio, signedBy, signedAt, startedAt, expiresAt, status。DRAFT→sign()→ACTIVE。分润返回 RevenueShareResult。

- [ ] **Step 4: 实现 RevenuePeriod**

字段：id, contractId, tenantId, periodStart, periodEnd, grossAmount, platformShare, partnerShare, revenueShareRatio(快照), status, settledAt

- [ ] **Step 5: 运行测试**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add Contract and RevenuePeriod aggregate roots"
```

---

## Task 5: SubscriptionService 聚合根

**Files:**
- Create: `SubscriptionService.java`
- Test: `SubscriptionServiceTest.java`

- [ ] **Step 1: 写 SubscriptionServiceTest**

覆盖：provision→PROVISIONED, activate→ACTIVE, recordHeartbeat, checkHeartbeat→GRACE_PERIOD, degrade, revoke, expire, adjustQuota, verifyKey（常量时间比较）

- [ ] **Step 2: 实现 SubscriptionService**

字段：id, tenantId, serviceName, serviceKeyPrefix, serviceKeyHash, effectiveTier, deviceQuota, status, lastHeartbeatAt, graceEndsAt, startedAt, expiresAt, heartbeatIntervalHrs(实例字段,默认24), gracePeriodDays(实例字段,默认7)。provision() 生成 License 文件（JWT + RSA 签名）。activate() 验证签名。

- [ ] **Step 3: 运行测试**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(commerce): add SubscriptionService aggregate root with License file support"
```

---

## Task 6: FeatureGate + QuotaApplicationService

**Files:**
- Create: `FeatureGate.java`, `QuotaResult.java`, `UsageResolver.java`, `FeatureGateRepository.java`, `QuotaApplicationService.java`
- Test: `QuotaApplicationServiceTest.java`, `FeatureGateTest.java`

- [ ] **Step 1: 写测试**

两道防线（订阅状态 + 门控规则），4 种 gateType (none/lock/limit/filter)，订阅 SUSPENDED 直接拒绝，filter 返回 retentionDays

- [ ] **Step 2: 实现 FeatureGate**

gateType: none/lock/limit/filter。字段：tier, featureKey, gateType, limitValue, retentionDays, isEnabled

- [ ] **Step 3: 实现 QuotaResult**

allowed(), denied(reason), allowedWithRetention(days)

- [ ] **Step 4: 实现 UsageResolver**

纯值签名：`resolve(Long tenantId, Long farmId)`

- [ ] **Step 5: 实现 QuotaApplicationService**

依赖：SubscriptionRepository + FeatureGateRepository。checkQuota() 先检查订阅活跃，再检查门控。getRetentionDays() 供查询层调用。

- [ ] **Step 6: 运行测试**

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(commerce): add FeatureGate, QuotaEngine with two-layer defense"
```

---

## Task 7: 持久化层 — JPA Entities + Mappers + Repositories

**Files:**
- Create: 5 JPA entities, 5 mappers, 5 Spring Data JPA repositories, 5 Repository implementations

- [ ] **Step 1: 创建 5 个 JPA Entity**

与 DDL 完全对齐。@Version 乐观锁，@PreUpdate 更新 updatedAt

- [ ] **Step 2: 创建 5 个 Mapper**

Domain ↔ JPA 双向转换，枚举 ↔ String，BigDecimal 映射

- [ ] **Step 3: 创建 5 个 Spring Data JPA Repository**

含定制查询方法

- [ ] **Step 4: 创建 5 个 Repository 实现**

注入 Spring Data JPA，使用 Mapper 转换

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add persistence layer — JPA entities, mappers, repositories"
```

---

## Task 8: @QuotaCheck + QuotaInterceptor + UsageResolver 实现

**Files:**
- Create: `QuotaCheck.java`, `QuotaInterceptor.java`, `FarmLivestockUsageResolver.java`, `FarmFenceUsageResolver.java`
- Modify: `SecurityConfig.java`

- [ ] **Step 1: 创建 @QuotaCheck 注解**

- [ ] **Step 2: 创建 QuotaInterceptor**

从 request 提取 tenantId/farmId（纯值），调用 QuotaApplicationService

- [ ] **Step 3: 实现 2 个 UsageResolver**

纯值签名 resolve(tenantId, farmId)，通过 shared 层接口查询

- [ ] **Step 4: 注册 QuotaInterceptor**

位于 Auth + FarmScope 之后

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add QuotaCheck annotation, interceptor, and UsageResolver"
```

---

## Task 9: Notification + EventListener

**Files:**
- Create: `shared/notification/Notification.java`, `NotificationRepository.java`, `NotificationService.java`
- Create: `application/listener/NotificationEventListener.java`

- [ ] **Step 1: 创建 Notification 实体 + Repository**

- [ ] **Step 2: 创建 NotificationService**

按事件类型生成 title/content，写入 notifications 表

- [ ] **Step 3: 创建 NotificationEventListener**

Spring ApplicationListener 接收 24 个事件

- [ ] **Step 4: ApplicationService 中发布事件**

save() 后调用 Spring ApplicationEventPublisher

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add notification system with Spring ApplicationEvent"
```

---

## Task 10: Application Services

**Files:**
- Create: 3 个 ApplicationService + DTO classes
- Test: `SubscriptionApplicationServiceTest.java`, `ContractApplicationServiceTest.java`

- [ ] **Step 1: 创建 DTO 类**

- [ ] **Step 2: 写测试并实现 SubscriptionApplicationService**

getOrCreateSubscription, upgrade, expireTrial, suspend, reactivate, cancel。save() 后发布事件

- [ ] **Step 3: 实现 ContractApplicationService**

create(DRAFT), sign, suspend, reactivate, terminate

- [ ] **Step 4: 实现 RevenueApplicationService**

calculatePeriod, confirmByPlatform, confirmByPartner, settle, recalculate。前置校验 contract.isActive()

- [ ] **Step 5: 运行测试**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add application services layer with event publishing"
```

---

## Task 11: Controllers — App + Admin API

**Files:**
- Create: 7 个 Controller
- Modify: FenceController, LivestockController

- [ ] **Step 1: SubscriptionController (App, 6 端点)**

GET /subscription, GET /subscription/plans, POST /subscription/checkout, PUT /subscription/tier, POST /subscription/cancel, GET /subscription/usage

- [ ] **Step 2: CommerceController (App, 3 端点)**

GET /contracts/me, GET /revenue/periods, POST /revenue/periods/{id}/confirm

- [ ] **Step 3: 5 个 Admin Controller**

AdminSubscriptionController(3), AdminContractController(6), AdminRevenueController(5), AdminServiceController(5), AdminFeatureGateController(2)

- [ ] **Step 4: Ranch Controller 加 @QuotaCheck**

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add 30 API endpoints (9 App + 21 Admin) with @QuotaCheck"
```

---

## Task 12: CommerceScheduler — 7 个定时任务

**Files:**
- Create: `CommerceScheduler.java`

- [ ] **Step 1: 实现 7 个定时任务**

| Job | 频率 | 逻辑 |
|-----|------|------|
| TrialExpiryJob | 每小时 | TRIAL AND expires_at < now → expireTrial() |
| SubscriptionExpiryJob | 每小时 | ACTIVE AND expires_at < now → markRenewalFailed() |
| RenewalFailedExpiryJob | 每天 2:00 | RENEWAL_FAILED 超过 7d → downgrade |
| HeartbeatCheckJob | 每 6 小时 | 预留，MVP 不触发 |
| LicenseExpiryJob | 每天 4:00 | License 文件到期 → expire() |
| ContractExpiryJob | 每天 5:00 | ACTIVE AND expires_at < now → markExpired() |
| RevenueCalculationJob | 每月 1 日 3:00 | ACTIVE 合同 → calculatePeriod() |

- [ ] **Step 2: 确保 @EnableScheduling**

- [ ] **Step 3: 编译验证**

- [ ] **Step 4: Commit**

```bash
git commit -m "feat(commerce): add CommerceScheduler with 7 scheduled jobs"
```

---

## Task 13: 集成验证 + Tenant 扩展

**Files:**
- Modify: `Tenant.java` (加 type + billingModel)

- [ ] **Step 1: Tenant 扩展字段**

- [ ] **Step 2: 全量编译**

- [ ] **Step 3: 全量测试**

- [ ] **Step 4: Flyway 迁移验证**

- [ ] **Step 5: Commit**

```bash
git commit -m "feat(commerce): complete Commerce bounded context — all modules verified"
```

---

*Plan version: 2026-05-18 v3 (based on architecture review corrections)*
*Design spec: `docs/superpowers/specs/2026-05-18-commerce-context-design.md`*
*Review: `docs/superpowers/reviews/2026-05-18-Commerce-架构评审与Plan修正.md`*
