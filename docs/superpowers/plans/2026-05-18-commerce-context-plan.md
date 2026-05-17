# Commerce 限界上下文实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 Commerce 限界上下文——订阅管理、合同管理、分润结算、Licensed 服务、配额引擎，支撑四种计费模式（direct/revenue_share/licensed/api_usage）。

**Architecture:** 独立 Commerce 限界上下文与 Identity/Ranch/IoT 平级，按 DDD 四层洋葱架构（domain → application → infrastructure → interfaces）。聚合根通过状态机管控生命周期，配额通过 @QuotaCheck 注解 + QuotaInterceptor 拦截，定时任务处理过期/心跳/结算。

**Tech Stack:** Spring Boot 3.3.0 / Java 17 / JPA + Hibernate / PostgreSQL 16 / Redis 7 / Flyway / JUnit 5 + Mockito

**Spec:** `docs/superpowers/specs/2026-05-18-commerce-context-design.md`

**前置:** MVP Phase 1 已完成，V1-V5 迁移已存在

---

## File Structure

### commerce/ — Create

| File | Responsibility |
|------|---------------|
| `domain/model/Subscription.java` | 订阅聚合根（状态机、工厂方法、effectiveTier） |
| `domain/model/SubscriptionTier.java` | Tier 枚举（定价、超量计算） |
| `domain/model/SubscriptionStatus.java` | 订阅状态枚举 |
| `domain/model/Contract.java` | 合同聚合根（签署、暂停、分润计算） |
| `domain/model/ContractStatus.java` | 合同状态枚举 |
| `domain/model/RevenuePeriod.java` | 分润结算聚合根（三方确认状态机） |
| `domain/model/RevenueSettlementStatus.java` | 结算状态枚举 |
| `domain/model/SubscriptionService.java` | Licensed 服务聚合根（心跳、serviceKey） |
| `domain/model/SubscriptionServiceStatus.java` | 服务状态枚举 |
| `domain/model/FeatureGate.java` | 功能门控值对象 |
| `domain/repository/SubscriptionRepository.java` | 订阅 Repository port |
| `domain/repository/ContractRepository.java` | 合同 Repository port |
| `domain/repository/RevenuePeriodRepository.java` | 分润 Repository port |
| `domain/repository/SubscriptionServiceRepository.java` | 服务 Repository port |
| `application/dto/QuotaResult.java` | 配额校验结果 DTO |
| `application/dto/CheckoutRequest.java` | 结算请求 DTO |
| `application/dto/SubscriptionResponse.java` | 订阅响应 DTO |
| `application/dto/ContractResponse.java` | 合同响应 DTO |
| `application/dto/RevenuePeriodResponse.java` | 分润响应 DTO |
| `application/service/SubscriptionApplicationService.java` | 订阅应用服务 |
| `application/service/ContractApplicationService.java` | 合同应用服务 |
| `application/service/RevenueApplicationService.java` | 分润应用服务 |
| `application/service/QuotaApplicationService.java` | 配额引擎服务 |
| `application/service/UsageResolver.java` | 用量解析接口 |
| `application/service/FarmLivestockUsageResolver.java` | farm 级牲畜用量 |
| `application/service/FarmFenceUsageResolver.java` | farm 级围栏用量 |
| `application/scheduler/CommerceScheduler.java` | 定时任务（6 Job） |
| `infrastructure/persistence/entity/SubscriptionJpaEntity.java` | 订阅 JPA 实体 |
| `infrastructure/persistence/entity/ContractJpaEntity.java` | 合同 JPA 实体 |
| `infrastructure/persistence/entity/RevenuePeriodJpaEntity.java` | 分润 JPA 实体 |
| `infrastructure/persistence/entity/SubscriptionServiceJpaEntity.java` | 服务 JPA 实体 |
| `infrastructure/persistence/entity/FeatureGateJpaEntity.java` | 功能门控 JPA 实体 |
| `infrastructure/persistence/mapper/SubscriptionMapper.java` | 订阅 mapper |
| `infrastructure/persistence/mapper/ContractMapper.java` | 合同 mapper |
| `infrastructure/persistence/mapper/RevenuePeriodMapper.java` | 分润 mapper |
| `infrastructure/persistence/mapper/SubscriptionServiceMapper.java` | 服务 mapper |
| `infrastructure/persistence/mapper/FeatureGateMapper.java` | 功能门控 mapper |
| `infrastructure/persistence/JpaSubscriptionRepositoryImpl.java` | 订阅 Repository 实现 |
| `infrastructure/persistence/JpaContractRepositoryImpl.java` | 合同 Repository 实现 |
| `infrastructure/persistence/JpaRevenuePeriodRepositoryImpl.java` | 分润 Repository 实现 |
| `infrastructure/persistence/JpaSubscriptionServiceRepositoryImpl.java` | 服务 Repository 实现 |
| `infrastructure/persistence/SpringSubscriptionJpaRepository.java` | Spring Data JPA |
| `infrastructure/persistence/SpringContractJpaRepository.java` | Spring Data JPA |
| `infrastructure/persistence/SpringRevenuePeriodJpaRepository.java` | Spring Data JPA |
| `infrastructure/persistence/SpringSubscriptionServiceJpaRepository.java` | Spring Data JPA |
| `infrastructure/persistence/SpringFeatureGateJpaRepository.java` | Spring Data JPA |
| `interfaces/SubscriptionController.java` | App 订阅 API |
| `interfaces/CheckoutController.java` | App 结算 API |
| `interfaces/AdminSubscriptionController.java` | Admin 订阅管理 |
| `interfaces/AdminContractController.java` | Admin 合同管理 |
| `interfaces/AdminRevenueController.java` | Admin 分润管理 |
| `interfaces/AdminServiceController.java` | Admin 服务管理 |
| `interfaces/QuotaInterceptor.java` | 配额拦截器 |

### shared/ — Modify

| File | Change |
|------|--------|
| `shared/common/ErrorCode.java` | 新增 Commerce 相关错误码 |
| `shared/security/SecurityConfig.java` | 注册 QuotaInterceptor |
| `shared/security/RequestContext.java` | 新增 tenantType/billingModel 上下文字段 |

### identity/ — Modify

| File | Change |
|------|--------|
| `identity/domain/model/Tenant.java` | 新增 type + billingModel 字段 |

### ranch/ — Modify (adding @QuotaCheck)

| File | Change |
|------|--------|
| `ranch/interfaces/FenceController.java` | createFence 加 @QuotaCheck(feature="fence_management") |
| `ranch/interfaces/LivestockController.java` | registerLivestock 加 @QuotaCheck(feature="livestock_management") |

### test/ — Create

| File | Test Target |
|------|------------|
| `domain/model/SubscriptionTest.java` | 订阅聚合根 13 个测试 |
| `domain/model/SubscriptionTierTest.java` | Tier 定价与超量测试 |
| `domain/model/ContractTest.java` | 合同聚合根测试 |
| `domain/model/RevenuePeriodTest.java` | 分润聚合根测试 |
| `domain/model/SubscriptionServiceTest.java` | Licensed 服务测试 |
| `application/service/QuotaApplicationServiceTest.java` | 配额引擎 6 个测试 |
| `application/service/SubscriptionApplicationServiceTest.java` | 订阅应用服务测试 |
| `application/service/ContractApplicationServiceTest.java` | 合同应用服务测试 |
| `interfaces/SubscriptionControllerTest.java` | API 集成测试 |
| `interfaces/AdminContractControllerTest.java` | Admin API 集成测试 |

### resources/ — Create

| File | Responsibility |
|------|---------------|
| `db/migration/V6__create_commerce_tables.sql` | 全部 DDL + 种子数据 |

---

## Task Dependency Graph

```
Task 1 (DDL)
    ↓
Task 2 (Enums + ErrorCode) ──→ Task 3 (Subscription) ──┐
                            ──→ Task 4 (Contract etc.) ──┤
                            ──→ Task 5 (Quota)         ──┤
                                                       ↓
                                                  Task 6 (Persistence)
                                                       ↓
                                                  Task 7 (Interceptor)
                                                       ↓
                                                  Task 8 (App Services)
                                                       ↓
                                                  Task 9 (Controllers)
                                                       ↓
                                                  Task 10 (Scheduler)
                                                       ↓
                                                  Task 11 (Integration)
```

Tasks 3, 4, 5 可并行。Tasks 6-10 严格串行。

---

## Task 1: V6 Flyway Migration — Commerce DDL + 种子数据

**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V6__create_commerce_tables.sql`
- Reference: `docs/superpowers/specs/2026-05-18-commerce-context-design.md` Section 2

- [ ] **Step 1: 创建迁移文件**

按 Spec Section 2 完整 DDL，包含以下 6 张表：

```sql
-- V6__create_commerce_tables.sql

-- subscriptions
CREATE TABLE subscriptions (
    id              BIGSERIAL PRIMARY KEY,
    tenant_id       BIGINT NOT NULL REFERENCES tenants(id),
    tier            VARCHAR(20) NOT NULL DEFAULT 'basic',
    status          VARCHAR(30) NOT NULL DEFAULT 'trial',
    billing_cycle   VARCHAR(20) NOT NULL DEFAULT 'monthly',
    started_at      TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ,
    trial_ends_at   TIMESTAMPTZ,
    last_heartbeat_at TIMESTAMPTZ,
    version         BIGINT NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_subscriptions_tenant_id ON subscriptions(tenant_id);
CREATE INDEX idx_subscriptions_status ON subscriptions(status);
CREATE INDEX idx_subscriptions_expires_at ON subscriptions(expires_at) WHERE expires_at IS NOT NULL;
CREATE INDEX idx_subscriptions_status_expires ON subscriptions(status, expires_at) WHERE status IN ('active', 'trial', 'renewal_failed') AND expires_at IS NOT NULL;

-- contracts
CREATE TABLE contracts (
    id                  BIGSERIAL PRIMARY KEY,
    contract_number     VARCHAR(20) NOT NULL UNIQUE,
    partner_tenant_id   BIGINT NOT NULL REFERENCES tenants(id),
    billing_model       VARCHAR(30) NOT NULL,
    revenue_share_ratio DECIMAL(5,4),
    signed_at           TIMESTAMPTZ NOT NULL,
    expires_at          TIMESTAMPTZ,
    status              VARCHAR(20) NOT NULL DEFAULT 'active',
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_contracts_partner_tenant ON contracts(partner_tenant_id);
CREATE INDEX idx_contracts_status ON contracts(status);
CREATE INDEX idx_contracts_expires_at ON contracts(expires_at) WHERE expires_at IS NOT NULL;

-- revenue_periods
CREATE TABLE revenue_periods (
    id                  BIGSERIAL PRIMARY KEY,
    contract_id         BIGINT NOT NULL REFERENCES contracts(id),
    period_start        DATE NOT NULL,
    period_end          DATE NOT NULL,
    gross_amount        INTEGER NOT NULL,
    platform_share      INTEGER NOT NULL,
    partner_share       INTEGER NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'pending',
    settled_at          TIMESTAMPTZ,
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_revenue_periods_contract ON revenue_periods(contract_id);
CREATE INDEX idx_revenue_periods_status ON revenue_periods(status);

-- subscription_services
CREATE TABLE subscription_services (
    id                  BIGSERIAL PRIMARY KEY,
    tenant_id           BIGINT NOT NULL REFERENCES tenants(id),
    service_name        VARCHAR(100) NOT NULL,
    service_key_prefix  VARCHAR(20) NOT NULL,
    service_key_hash    VARCHAR(64) NOT NULL,
    status              VARCHAR(20) NOT NULL DEFAULT 'provisioned',
    last_heartbeat_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    grace_ends_at       TIMESTAMPTZ,
    expires_at          TIMESTAMPTZ,
    version             BIGINT NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sub_services_tenant ON subscription_services(tenant_id);
CREATE INDEX idx_sub_services_status ON subscription_services(status);
CREATE INDEX idx_sub_services_heartbeat ON subscription_services(status, last_heartbeat_at) WHERE status = 'active';

-- feature_gates
CREATE TABLE feature_gates (
    id          BIGSERIAL PRIMARY KEY,
    tier        VARCHAR(20) NOT NULL,
    feature_key VARCHAR(50) NOT NULL,
    gate_type   VARCHAR(10) NOT NULL,
    limit_value INTEGER,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE UNIQUE INDEX idx_feature_gates_tier_feature ON feature_gates(tier, feature_key);

-- tenants 扩展字段
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS billing_model VARCHAR(30) DEFAULT 'direct';

-- 种子数据：功能门控
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value) VALUES
    ('basic',    'fence_management',    'limit', 3),
    ('basic',    'livestock_management','limit', 50),
    ('basic',    'device_management',   'limit', 10),
    ('basic',    'alerts',              'none',  NULL),
    ('standard', 'fence_management',    'limit', 5),
    ('standard', 'livestock_management','limit', 200),
    ('standard', 'device_management',   'limit', 50),
    ('standard', 'alerts',              'none',  NULL),
    ('premium',  'fence_management',    'limit', 10),
    ('premium',  'livestock_management','limit', 1000),
    ('premium',  'device_management',   'limit', 200),
    ('premium',  'alerts',              'none',  NULL),
    ('premium',  'health_monitoring',   'none',  NULL),
    ('premium',  'breeding_analytics',  'none',  NULL),
    ('premium',  'api_calls',           'limit', 10000),
    ('enterprise','fence_management',   'none',  NULL),
    ('enterprise','livestock_management','none', NULL),
    ('enterprise','device_management',  'none',  NULL),
    ('enterprise','alerts',             'none',  NULL),
    ('enterprise','health_monitoring',  'none',  NULL),
    ('enterprise','breeding_analytics', 'none',  NULL),
    ('enterprise','api_calls',          'none',  NULL);

-- 种子数据：示例订阅（owner 租户）
INSERT INTO subscriptions (tenant_id, tier, status, billing_cycle, started_at, expires_at, trial_ends_at)
VALUES (1, 'premium', 'trial', 'monthly', now(), now() + interval '14 days', now() + interval '14 days');

-- 种子数据：合同编号计数器（通过序列模拟）
CREATE SEQUENCE IF NOT EXISTS contract_number_seq START 1;
```

- [ ] **Step 2: 验证迁移可执行**

Run: `cd smart-livestock-server && ./gradlew flywayMigrate -x test 2>&1 | tail -5`
Expected: 迁移成功或 "Successfully applied 1 migration"

- [ ] **Step 3: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V6__create_commerce_tables.sql
git commit -m "feat(commerce): add V6 migration for commerce tables and seed data"
```

---

## Task 2: ErrorCode 扩展 + 枚举类

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/shared/common/ErrorCode.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/SubscriptionTier.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/SubscriptionStatus.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/ContractStatus.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/RevenueSettlementStatus.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceStatus.java`
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTierTest.java`

- [ ] **Step 1: 扩展 ErrorCode**

在 ErrorCode 枚举中追加以下 Commerce 相关错误码：

```java
// --- Commerce ---
ENTERPRISE_CUSTOM_PRICING("COMMERCE_001", "Enterprise 需定制计费，请使用合同模式"),
QUOTA_EXCEEDED("COMMERCE_002", "配额已超限"),
INVALID_BILLING_MODEL("COMMERCE_003", "无效的计费模型"),
INVALID_REVENUE_SHARE_RATIO("COMMERCE_004", "分润比例须在 0~1 之间"),
SUBSCRIPTION_EXPIRED("COMMERCE_005", "订阅已过期"),
TRIAL_ALREADY_STARTED("COMMERCE_006", "试用已开始，不可重复"),
HEARTBEAT_REQUIRED("COMMERCE_007", "Licensed 服务心跳超时"),
SERVICE_KEY_MISMATCH("COMMERCE_008", "服务密钥不匹配"),
CONTRACT_NOT_ACTIVE("COMMERCE_009", "合同非生效状态"),
SETTLEMENT_ALREADY_CONFIRMED("COMMERCE_010", "结算已确认，不可重复操作"),
```

- [ ] **Step 2: 创建 SubscriptionTier 枚举**

```java
package com.smartlivestock.commerce.domain.model;

public enum SubscriptionTier {
    BASIC(0, 50),
    STANDARD(99, 200),
    PREMIUM(199, 1000),
    ENTERPRISE(-1, -1);

    private final int monthlyFeePerHundredHead;
    private final int includedLivestock;

    SubscriptionTier(int monthlyFeePerHundredHead, int includedLivestock) {
        this.monthlyFeePerHundredHead = monthlyFeePerHundredHead;
        this.includedLivestock = includedLivestock;
    }

    public int calculateMonthlyFee(int livestockCount) {
        if (this == ENTERPRISE) {
            throw new com.smartlivestock.shared.common.ApiException(
                com.smartlivestock.shared.common.ErrorCode.ENTERPRISE_CUSTOM_PRICING,
                "Enterprise 需定制计费"
            );
        }
        if (livestockCount <= includedLivestock) return monthlyFeePerHundredHead;
        int excess = livestockCount - includedLivestock;
        int excessHundreds = (int) Math.ceil(excess / 100.0);
        return monthlyFeePerHundredHead + excessHundreds * 20;
    }

    public int getIncludedLivestock() {
        return includedLivestock;
    }
}
```

- [ ] **Step 3: 创建 SubscriptionStatus 枚举**

```java
package com.smartlivestock.commerce.domain.model;

public enum SubscriptionStatus {
    TRIAL,
    ACTIVE,
    FREE,
    SUSPENDED,
    RENEWAL_FAILED,
    CANCELLED,
    EXPIRED
}
```

- [ ] **Step 4: 创建 ContractStatus 枚举**

```java
package com.smartlivestock.commerce.domain.model;

public enum ContractStatus {
    ACTIVE,
    SUSPENDED,
    EXPIRED,
    TERMINATED
}
```

- [ ] **Step 5: 创建 RevenueSettlementStatus 枚举**

```java
package com.smartlivestock.commerce.domain.model;

public enum RevenueSettlementStatus {
    PENDING,
    PLATFORM_CONFIRMED,
    PARTNER_CONFIRMED,
    SETTLED
}
```

- [ ] **Step 6: 创建 SubscriptionServiceStatus 枚举**

```java
package com.smartlivestock.commerce.domain.model;

public enum SubscriptionServiceStatus {
    PROVISIONED,
    ACTIVE,
    GRACE_PERIOD,
    DEGRADED,
    EXPIRED
}
```

- [ ] **Step 7: 写 SubscriptionTierTest**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import static org.assertj.core.api.Assertions.*;

class SubscriptionTierTest {

    @Test
    void basic_withinIncluded_returnsBaseFee() {
        assertThat(SubscriptionTier.BASIC.calculateMonthlyFee(50)).isEqualTo(0);
    }

    @Test
    void basic_exceedsIncluded_chargesExcess() {
        // 50 included, 100 excess → 1 hundred → 20
        assertThat(SubscriptionTier.BASIC.calculateMonthlyFee(150)).isEqualTo(20);
    }

    @Test
    void standard_withinIncluded_returnsBaseFee() {
        assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(200)).isEqualTo(99);
    }

    @Test
    void standard_exceedsIncluded_chargesExcess() {
        // 200 included, 50 excess → 1 hundred → 20
        assertThat(SubscriptionTier.STANDARD.calculateMonthlyFee(250)).isEqualTo(119);
    }

    @Test
    void premium_withinIncluded_returnsBaseFee() {
        assertThat(SubscriptionTier.PREMIUM.calculateMonthlyFee(1000)).isEqualTo(199);
    }

    @Test
    void enterprise_throwsException() {
        assertThatThrownBy(() -> SubscriptionTier.ENTERPRISE.calculateMonthlyFee(100))
            .isInstanceOf(ApiException.class)
            .extracting("errorCode").isEqualTo(ErrorCode.ENTERPRISE_CUSTOM_PRICING);
    }
}
```

- [ ] **Step 8: 运行测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.domain.model.SubscriptionTierTest" -v`
Expected: 6 tests PASS

- [ ] **Step 9: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/shared/common/ErrorCode.java
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/
git add smart-livestock-server/src/test/java/com/smartlivestock/commerce/
git commit -m "feat(commerce): add ErrorCode extensions and enum classes"
```

---

## Task 3: Subscription 聚合根

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/Subscription.java`
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionTest.java`

- [ ] **Step 1: 写 SubscriptionTest — 13 个测试用例**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import static org.assertj.core.api.Assertions.*;

class SubscriptionTest {

    private Subscription createTrialSubscription() {
        return Subscription.startTrial(
            1L,
            Instant.now(),
            Instant.now().plus(14, ChronoUnit.DAYS)
        );
    }

    // --- startTrial ---

    @Test
    void startTrial_createsTrialSubscription() {
        var sub = createTrialSubscription();
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
        assertThat(sub.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
        assertThat(sub.getTenantId()).isEqualTo(1L);
    }

    @Test
    void startTrial_alreadyActive_throws() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        assertThatThrownBy(() -> Subscription.startTrial(1L, Instant.now(), Instant.now().plus(14, ChronoUnit.DAYS)))
            .isInstanceOf(ApiException.class);
    }

    // --- activate ---

    @Test
    void activate_fromTrial_setsActiveStandard() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.getTier()).isEqualTo(SubscriptionTier.STANDARD);
    }

    @Test
    void activate_fromFree_setsActive() {
        var sub = createTrialSubscription();
        sub.expireTrial();
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.FREE);
        sub.activate(SubscriptionTier.PREMIUM, "yearly", Instant.now().plus(365, ChronoUnit.DAYS));
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
    }

    // --- expireTrial ---

    @Test
    void expireTrial_downgradesToFree() {
        var sub = createTrialSubscription();
        sub.expireTrial();
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.FREE);
        assertThat(sub.getTier()).isEqualTo(SubscriptionTier.BASIC);
    }

    // --- effectiveTier ---

    @Test
    void effectiveTier_trial_returnsPremium() {
        var sub = createTrialSubscription();
        assertThat(sub.effectiveTier()).isEqualTo(SubscriptionTier.PREMIUM);
    }

    @Test
    void effectiveTier_active_returnsActualTier() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        assertThat(sub.effectiveTier()).isEqualTo(SubscriptionTier.STANDARD);
    }

    @Test
    void effectiveTier_free_returnsBasic() {
        var sub = createTrialSubscription();
        sub.expireTrial();
        assertThat(sub.effectiveTier()).isEqualTo(SubscriptionTier.BASIC);
    }

    // --- changeTier ---

    @Test
    void changeTier_allowedFromActive() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        sub.changeTier(SubscriptionTier.PREMIUM);
        assertThat(sub.getTier()).isEqualTo(SubscriptionTier.PREMIUM);
    }

    @Test
    void changeTier_allowedFromFree() {
        var sub = createTrialSubscription();
        sub.expireTrial();
        sub.changeTier(SubscriptionTier.STANDARD);
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.getTier()).isEqualTo(SubscriptionTier.STANDARD);
    }

    @Test
    void changeTier_fromSuspended_throws() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        sub.suspend();
        assertThatThrownBy(() -> sub.changeTier(SubscriptionTier.PREMIUM))
            .isInstanceOf(ApiException.class)
            .extracting("errorCode").isEqualTo(ErrorCode.STATE_CONFLICT);
    }

    // --- suspend / reactivate ---

    @Test
    void suspend_active_setsSuspended() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        sub.suspend();
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.SUSPENDED);
    }

    @Test
    void reactivate_suspended_setsActiveAndExtendsExpiry() {
        var sub = createTrialSubscription();
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        sub.suspend();
        var beforeReactivate = Instant.now();
        sub.reactivate();
        assertThat(sub.getStatus()).isEqualTo(SubscriptionStatus.ACTIVE);
        assertThat(sub.getExpiresAt()).isAfter(beforeReactivate);
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.domain.model.SubscriptionTest" -v`
Expected: FAIL — Subscription class not found

- [ ] **Step 3: 实现 Subscription 聚合根**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

public class Subscription extends AggregateRoot {

    private Long id;
    private Long tenantId;
    private SubscriptionTier tier;
    private SubscriptionStatus status;
    private String billingCycle;
    private Instant startedAt;
    private Instant expiresAt;
    private Instant trialEndsAt;

    private Subscription() {}

    public static Subscription startTrial(Long tenantId, Instant startedAt, Instant trialEndsAt) {
        var sub = new Subscription();
        sub.tenantId = tenantId;
        sub.tier = SubscriptionTier.PREMIUM;
        sub.status = SubscriptionStatus.TRIAL;
        sub.billingCycle = "monthly";
        sub.startedAt = startedAt;
        sub.trialEndsAt = trialEndsAt;
        sub.expiresAt = trialEndsAt;
        sub.registerEvent(new SubscriptionTrialStartedEvent(tenantId));
        return sub;
    }

    public void activate(SubscriptionTier tier, String billingCycle, Instant expiresAt) {
        requireStatus(SubscriptionStatus.TRIAL, SubscriptionStatus.FREE);
        this.tier = tier;
        this.status = SubscriptionStatus.ACTIVE;
        this.billingCycle = billingCycle;
        this.expiresAt = expiresAt;
        registerEvent(new SubscriptionActivatedEvent(tenantId, tier));
    }

    public void expireTrial() {
        requireStatus(SubscriptionStatus.TRIAL);
        this.tier = SubscriptionTier.BASIC;
        this.status = SubscriptionStatus.FREE;
        registerEvent(new SubscriptionTrialExpiredEvent(tenantId));
    }

    public SubscriptionTier effectiveTier() {
        if (status == SubscriptionStatus.TRIAL) return SubscriptionTier.PREMIUM;
        return this.tier;
    }

    public void changeTier(SubscriptionTier newTier) {
        requireStatus(SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL, SubscriptionStatus.FREE);
        if (this.status == SubscriptionStatus.FREE) {
            this.status = SubscriptionStatus.ACTIVE;
        }
        this.tier = newTier;
    }

    public void suspend() {
        requireStatus(SubscriptionStatus.ACTIVE);
        this.status = SubscriptionStatus.SUSPENDED;
        registerEvent(new SubscriptionSuspendedEvent(tenantId));
    }

    public void reactivate() {
        requireStatus(SubscriptionStatus.SUSPENDED);
        this.status = SubscriptionStatus.ACTIVE;
        int days = "yearly".equals(billingCycle) ? 365 : 30;
        this.expiresAt = Instant.now().plus(days, ChronoUnit.DAYS);
    }

    public void markRenewalFailed() {
        requireStatus(SubscriptionStatus.ACTIVE);
        this.status = SubscriptionStatus.RENEWAL_FAILED;
    }

    public void downgradeAfterRenewalFailure() {
        requireStatus(SubscriptionStatus.RENEWAL_FAILED);
        this.tier = SubscriptionTier.BASIC;
        this.status = SubscriptionStatus.FREE;
    }

    public void cancel() {
        requireStatus(SubscriptionStatus.ACTIVE, SubscriptionStatus.FREE);
        this.status = SubscriptionStatus.CANCELLED;
    }

    public void markExpired() {
        requireStatus(SubscriptionStatus.ACTIVE, SubscriptionStatus.TRIAL, SubscriptionStatus.RENEWAL_FAILED);
        this.status = SubscriptionStatus.EXPIRED;
    }

    private void requireStatus(SubscriptionStatus... allowed) {
        for (var s : allowed) {
            if (this.status == s) return;
        }
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "当前状态 " + this.status + " 不允许此操作");
    }

    // Getters
    public Long getId() { return id; }
    public Long getTenantId() { return tenantId; }
    public SubscriptionTier getTier() { return tier; }
    public SubscriptionStatus getStatus() { return status; }
    public String getBillingCycle() { return billingCycle; }
    public Instant getStartedAt() { return startedAt; }
    public Instant getExpiresAt() { return expiresAt; }
    public Instant getTrialEndsAt() { return trialEndsAt; }
}
```

- [ ] **Step 4: 创建领域事件类**

在 `commerce/domain/model/` 下创建事件类：

```java
// SubscriptionTrialStartedEvent.java
package com.smartlivestock.commerce.domain.model;
public record SubscriptionTrialStartedEvent(Long tenantId) {}

// SubscriptionActivatedEvent.java
package com.smartlivestock.commerce.domain.model;
public record SubscriptionActivatedEvent(Long tenantId, SubscriptionTier tier) {}

// SubscriptionTrialExpiredEvent.java
package com.smartlivestock.commerce.domain.model;
public record SubscriptionTrialExpiredEvent(Long tenantId) {}

// SubscriptionSuspendedEvent.java
package com.smartlivestock.commerce.domain.model;
public record SubscriptionSuspendedEvent(Long tenantId) {}
```

- [ ] **Step 5: 运行测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.domain.model.SubscriptionTest" -v`
Expected: 13 tests PASS

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/
git add smart-livestock-server/src/test/java/com/smartlivestock/commerce/
git commit -m "feat(commerce): add Subscription aggregate root with 13 tests"
```

---

## Task 4: Contract + RevenuePeriod + SubscriptionService 聚合根

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/Contract.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/RevenuePeriod.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/SubscriptionService.java`
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/ContractTest.java`
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/RevenuePeriodTest.java`
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/domain/model/SubscriptionServiceTest.java`

- [ ] **Step 1: 写 ContractTest**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;
import java.time.Instant;
import static org.assertj.core.api.Assertions.*;

class ContractTest {

    private Contract createActiveContract() {
        return Contract.sign(
            1L, "CT-2026-000001", "revenue_share",
            new BigDecimal("0.3000"),
            Instant.now(), Instant.now().plus(365, java.time.temporal.ChronoUnit.DAYS)
        );
    }

    @Test
    void sign_createsActiveContract() {
        var c = createActiveContract();
        assertThat(c.getStatus()).isEqualTo(ContractStatus.ACTIVE);
        assertThat(c.getContractNumber()).isEqualTo("CT-2026-000001");
    }

    @Test
    void sign_invalidRatio_throws() {
        assertThatThrownBy(() -> Contract.sign(
            1L, "CT-2026-000002", "revenue_share",
            new BigDecimal("1.5000"),
            Instant.now(), Instant.now().plus(365, java.time.temporal.ChronoUnit.DAYS)
        )).isInstanceOf(ApiException.class)
          .extracting("errorCode").isEqualTo(ErrorCode.INVALID_REVENUE_SHARE_RATIO);
    }

    @Test
    void suspend_active_setsSuspended() {
        var c = createActiveContract();
        c.suspend();
        assertThat(c.getStatus()).isEqualTo(ContractStatus.SUSPENDED);
    }

    @Test
    void reactivate_suspended_setsActive() {
        var c = createActiveContract();
        c.suspend();
        c.reactivate();
        assertThat(c.getStatus()).isEqualTo(ContractStatus.ACTIVE);
    }

    @Test
    void terminate_active_setsTerminated() {
        var c = createActiveContract();
        c.terminate();
        assertThat(c.getStatus()).isEqualTo(ContractStatus.TERMINATED);
    }

    @Test
    void terminate_alreadyTerminated_throws() {
        var c = createActiveContract();
        c.terminate();
        assertThatThrownBy(c::terminate).isInstanceOf(ApiException.class);
    }

    @Test
    void calculateRevenueShare_splitsCorrectly() {
        var c = createActiveContract(); // ratio 0.3
        var share = c.calculateRevenueShare(10000);
        assertThat(share.platformShare()).isEqualTo(7000);
        assertThat(share.partnerShare()).isEqualTo(3000);
    }
}
```

- [ ] **Step 2: 写 RevenuePeriodTest**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import org.junit.jupiter.api.Test;
import java.time.LocalDate;
import static org.assertj.core.api.Assertions.*;

class RevenuePeriodTest {

    @Test
    void create_setsPending() {
        var rp = RevenuePeriod.create(1L,
            LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
            10000, 7000, 3000);
        assertThat(rp.getStatus()).isEqualTo(RevenueSettlementStatus.PENDING);
    }

    @Test
    void confirmByPlatform_pending_setsPlatformConfirmed() {
        var rp = RevenuePeriod.create(1L,
            LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
            10000, 7000, 3000);
        rp.confirmByPlatform();
        assertThat(rp.getStatus()).isEqualTo(RevenueSettlementStatus.PLATFORM_CONFIRMED);
    }

    @Test
    void confirmByPartner_platformConfirmed_setsPartnerConfirmed() {
        var rp = RevenuePeriod.create(1L,
            LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
            10000, 7000, 3000);
        rp.confirmByPlatform();
        rp.confirmByPartner();
        assertThat(rp.getStatus()).isEqualTo(RevenueSettlementStatus.PARTNER_CONFIRMED);
    }

    @Test
    void settle_partnerConfirmed_setsSettled() {
        var rp = RevenuePeriod.create(1L,
            LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
            10000, 7000, 3000);
        rp.confirmByPlatform();
        rp.confirmByPartner();
        rp.settle();
        assertThat(rp.getStatus()).isEqualTo(RevenueSettlementStatus.SETTLED);
    }

    @Test
    void settle_withoutConfirmation_throws() {
        var rp = RevenuePeriod.create(1L,
            LocalDate.of(2026, 5, 1), LocalDate.of(2026, 5, 31),
            10000, 7000, 3000);
        assertThatThrownBy(rp::settle).isInstanceOf(ApiException.class);
    }
}
```

- [ ] **Step 3: 写 SubscriptionServiceTest**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import static org.assertj.core.api.Assertions.*;

class SubscriptionServiceTest {

    private SubscriptionService createProvisionedService() {
        return SubscriptionService.provision(
            1L, "SmartLivestock", "SL",
            "hashed-key-abc"
        );
    }

    @Test
    void provision_createsWithProvisionedStatus() {
        var ss = createProvisionedService();
        assertThat(ss.getStatus()).isEqualTo(SubscriptionServiceStatus.PROVISIONED);
        assertThat(ss.getLastHeartbeatAt()).isNotNull();
    }

    @Test
    void activate_provisioned_setsActive() {
        var ss = createProvisionedService();
        ss.activate(Instant.now().plus(365, ChronoUnit.DAYS));
        assertThat(ss.getStatus()).isEqualTo(SubscriptionServiceStatus.ACTIVE);
    }

    @Test
    void recordHeartbeat_active_updatesTimestamp() {
        var ss = createProvisionedService();
        ss.activate(Instant.now().plus(365, ChronoUnit.DAYS));
        var before = ss.getLastHeartbeatAt();
        ss.recordHeartbeat();
        assertThat(ss.getLastHeartbeatAt()).isAfter(before);
    }

    @Test
    void checkHeartbeat_expiredHeartbeat_entersGracePeriod() {
        var ss = createProvisionedService();
        ss.activate(Instant.now().plus(365, ChronoUnit.DAYS));
        // Simulate expired heartbeat by reflection or test helper
        ss.checkHeartbeatWithLastAt(Instant.now().minus(25, ChronoUnit.HOURS));
        assertThat(ss.getStatus()).isEqualTo(SubscriptionServiceStatus.GRACE_PERIOD);
    }

    @Test
    void degrade_gracePeriod_setsDegraded() {
        var ss = createProvisionedService();
        ss.activate(Instant.now().plus(365, ChronoUnit.DAYS));
        ss.checkHeartbeatWithLastAt(Instant.now().minus(25, ChronoUnit.HOURS));
        ss.degrade();
        assertThat(ss.getStatus()).isEqualTo(SubscriptionServiceStatus.DEGRADED);
    }

    @Test
    void revoke_anyStatus_setsExpired() {
        var ss = createProvisionedService();
        ss.revoke();
        assertThat(ss.getStatus()).isEqualTo(SubscriptionServiceStatus.EXPIRED);
    }
}
```

- [ ] **Step 4: 实现 Contract 聚合根**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import java.math.BigDecimal;
import java.time.Instant;

public class Contract extends AggregateRoot {

    private Long id;
    private String contractNumber;
    private Long partnerTenantId;
    private String billingModel;
    private BigDecimal revenueShareRatio;
    private Instant signedAt;
    private Instant expiresAt;
    private ContractStatus status;

    private Contract() {}

    public static Contract sign(Long partnerTenantId, String contractNumber,
                                String billingModel, BigDecimal revenueShareRatio,
                                Instant signedAt, Instant expiresAt) {
        if (revenueShareRatio != null &&
            (revenueShareRatio.compareTo(BigDecimal.ZERO) < 0 ||
             revenueShareRatio.compareTo(BigDecimal.ONE) > 0)) {
            throw new ApiException(ErrorCode.INVALID_REVENUE_SHARE_RATIO, "分润比例须在 0~1 之间");
        }
        var c = new Contract();
        c.partnerTenantId = partnerTenantId;
        c.contractNumber = contractNumber;
        c.billingModel = billingModel;
        c.revenueShareRatio = revenueShareRatio;
        c.signedAt = signedAt;
        c.expiresAt = expiresAt;
        c.status = ContractStatus.ACTIVE;
        return c;
    }

    public RevenueShareResult calculateRevenueShare(int grossAmount) {
        if (revenueShareRatio == null) {
            return new RevenueShareResult(grossAmount, 0);
        }
        int partnerShare = revenueShareRatio.multiply(BigDecimal.valueOf(grossAmount)).intValue();
        return new RevenueShareResult(grossAmount - partnerShare, partnerShare);
    }

    public void suspend() {
        requireStatus(ContractStatus.ACTIVE);
        this.status = ContractStatus.SUSPENDED;
    }

    public void reactivate() {
        requireStatus(ContractStatus.SUSPENDED);
        this.status = ContractStatus.ACTIVE;
    }

    public void terminate() {
        requireStatus(ContractStatus.ACTIVE, ContractStatus.SUSPENDED);
        this.status = ContractStatus.TERMINATED;
    }

    public void markExpired() {
        requireStatus(ContractStatus.ACTIVE);
        this.status = ContractStatus.EXPIRED;
    }

    private void requireStatus(ContractStatus... allowed) {
        for (var s : allowed) {
            if (this.status == s) return;
        }
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "当前状态 " + this.status + " 不允许此操作");
    }

    public record RevenueShareResult(int platformShare, int partnerShare) {}

    // Getters
    public Long getId() { return id; }
    public String getContractNumber() { return contractNumber; }
    public Long getPartnerTenantId() { return partnerTenantId; }
    public String getBillingModel() { return billingModel; }
    public BigDecimal getRevenueShareRatio() { return revenueShareRatio; }
    public Instant getSignedAt() { return signedAt; }
    public Instant getExpiresAt() { return expiresAt; }
    public ContractStatus getStatus() { return status; }
}
```

- [ ] **Step 5: 实现 RevenuePeriod 聚合根**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import java.time.Instant;
import java.time.LocalDate;

public class RevenuePeriod extends AggregateRoot {

    private static final int HEARTBEAT_THRESHOLD_HOURS = 24;

    private Long id;
    private Long contractId;
    private LocalDate periodStart;
    private LocalDate periodEnd;
    private int grossAmount;
    private int platformShare;
    private int partnerShare;
    private RevenueSettlementStatus status;
    private Instant settledAt;

    private RevenuePeriod() {}

    /** @pre contract.isActive() — 调用方须先校验合同状态 */
    public static RevenuePeriod create(Long contractId, LocalDate periodStart,
                                       LocalDate periodEnd, int grossAmount,
                                       int platformShare, int partnerShare) {
        var rp = new RevenuePeriod();
        rp.contractId = contractId;
        rp.periodStart = periodStart;
        rp.periodEnd = periodEnd;
        rp.grossAmount = grossAmount;
        rp.platformShare = platformShare;
        rp.partnerShare = partnerShare;
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
    }

    public void settle() {
        requireStatus(RevenueSettlementStatus.PARTNER_CONFIRMED);
        this.status = RevenueSettlementStatus.SETTLED;
        this.settledAt = Instant.now();
    }

    private void requireStatus(RevenueSettlementStatus... allowed) {
        for (var s : allowed) {
            if (this.status == s) return;
        }
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "当前状态 " + this.status + " 不允许此操作");
    }

    // Getters
    public Long getId() { return id; }
    public Long getContractId() { return contractId; }
    public LocalDate getPeriodStart() { return periodStart; }
    public LocalDate getPeriodEnd() { return periodEnd; }
    public int getGrossAmount() { return grossAmount; }
    public int getPlatformShare() { return platformShare; }
    public int getPartnerShare() { return partnerShare; }
    public RevenueSettlementStatus getStatus() { return status; }
    public Instant getSettledAt() { return settledAt; }
}
```

- [ ] **Step 6: 实现 SubscriptionService 聚合根**

```java
package com.smartlivestock.commerce.domain.model;

import com.smartlivestock.shared.common.ApiException;
import com.smartlivestock.shared.common.ErrorCode;
import com.smartlivestock.shared.domain.AggregateRoot;
import java.security.MessageDigest;
import java.time.Instant;
import java.time.temporal.ChronoUnit;

public class SubscriptionService extends AggregateRoot {

    private static final int HEARTBEAT_THRESHOLD_HOURS = 24;
    private static final int GRACE_PERIOD_DAYS = 7;

    private Long id;
    private Long tenantId;
    private String serviceName;
    private String serviceKeyPrefix;
    private String serviceKeyHash;
    private SubscriptionServiceStatus status;
    private Instant lastHeartbeatAt;
    private Instant graceEndsAt;
    private Instant expiresAt;

    private SubscriptionService() {}

    public static SubscriptionService provision(Long tenantId, String serviceName,
                                                 String serviceKeyPrefix, String serviceKeyHash) {
        var ss = new SubscriptionService();
        ss.tenantId = tenantId;
        ss.serviceName = serviceName;
        ss.serviceKeyPrefix = serviceKeyPrefix;
        ss.serviceKeyHash = serviceKeyHash;
        ss.status = SubscriptionServiceStatus.PROVISIONED;
        ss.lastHeartbeatAt = Instant.now();
        return ss;
    }

    public void activate(Instant expiresAt) {
        requireStatus(SubscriptionServiceStatus.PROVISIONED);
        this.status = SubscriptionServiceStatus.ACTIVE;
        this.expiresAt = expiresAt;
    }

    public void recordHeartbeat() {
        requireStatus(SubscriptionServiceStatus.ACTIVE);
        this.lastHeartbeatAt = Instant.now();
    }

    public void checkHeartbeat() {
        if (status != SubscriptionServiceStatus.ACTIVE) return;
        checkHeartbeatWithLastAt(lastHeartbeatAt);
    }

    public void checkHeartbeatWithLastAt(Instant lastAt) {
        if (status != SubscriptionServiceStatus.ACTIVE) return;
        var threshold = Instant.now().minus(HEARTBEAT_THRESHOLD_HOURS, ChronoUnit.HOURS);
        if (lastAt.isBefore(threshold)) {
            this.status = SubscriptionServiceStatus.GRACE_PERIOD;
            this.graceEndsAt = Instant.now().plus(GRACE_PERIOD_DAYS, ChronoUnit.DAYS);
        }
    }

    public void degrade() {
        requireStatus(SubscriptionServiceStatus.GRACE_PERIOD);
        this.status = SubscriptionServiceStatus.DEGRADED;
    }

    public void revoke() {
        this.status = SubscriptionServiceStatus.EXPIRED;
    }

    public boolean verifyKey(String rawKey) {
        try {
            var digest = MessageDigest.getInstance("SHA-256");
            var hashBytes = digest.digest(rawKey.getBytes());
            var expectedBytes = hexToBytes(serviceKeyHash);
            return MessageDigest.isEqual(hashBytes, expectedBytes);
        } catch (Exception e) {
            return false;
        }
    }

    private static byte[] hexToBytes(String hex) {
        var bytes = new byte[hex.length() / 2];
        for (int i = 0; i < bytes.length; i++) {
            bytes[i] = (byte) Integer.parseInt(hex.substring(i * 2, i * 2 + 2), 16);
        }
        return bytes;
    }

    private void requireStatus(SubscriptionServiceStatus... allowed) {
        for (var s : allowed) {
            if (this.status == s) return;
        }
        throw new ApiException(ErrorCode.STATE_CONFLICT,
            "当前状态 " + this.status + " 不允许此操作");
    }

    // Getters
    public Long getId() { return id; }
    public Long getTenantId() { return tenantId; }
    public String getServiceName() { return serviceName; }
    public String getServiceKeyPrefix() { return serviceKeyPrefix; }
    public SubscriptionServiceStatus getStatus() { return status; }
    public Instant getLastHeartbeatAt() { return lastHeartbeatAt; }
    public Instant getGraceEndsAt() { return graceEndsAt; }
    public Instant getExpiresAt() { return expiresAt; }
}
```

- [ ] **Step 7: 运行全部测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.domain.model.*Test" -v`
Expected: ContractTest(7) + RevenuePeriodTest(5) + SubscriptionServiceTest(6) = 18 PASS

- [ ] **Step 8: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/
git add smart-livestock-server/src/test/java/com/smartlivestock/commerce/
git commit -m "feat(commerce): add Contract, RevenuePeriod, SubscriptionService aggregate roots"
```

---

## Task 5: FeatureGate + QuotaApplicationService

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/model/FeatureGate.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/dto/QuotaResult.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/QuotaApplicationService.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/UsageResolver.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/domain/repository/FeatureGateRepository.java`
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/QuotaApplicationServiceTest.java`

- [ ] **Step 1: 写 QuotaApplicationServiceTest — 6 个测试**

```java
package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import org.junit.jupiter.api.Test;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class QuotaApplicationServiceTest {

    private FeatureGateRepository gateRepo = mock(FeatureGateRepository.class);
    private UsageResolver resolver = mock(UsageResolver.class);
    private QuotaApplicationService service = new QuotaApplicationService(gateRepo);

    @Test
    void checkQuota_gateTypeNone_returnsAllowed() {
        when(gateRepo.findByTierAndFeatureKey(SubscriptionTier.PREMIUM, "alerts"))
            .thenReturn(Optional.of(new FeatureGate(SubscriptionTier.PREMIUM, "alerts", "none", null)));

        var result = service.check(SubscriptionTier.PREMIUM, "alerts", 0);
        assertThat(result.isAllowed()).isTrue();
    }

    @Test
    void checkQuota_gateTypeLimit_withinLimit_returnsAllowed() {
        when(gateRepo.findByTierAndFeatureKey(SubscriptionTier.BASIC, "fence_management"))
            .thenReturn(Optional.of(new FeatureGate(SubscriptionTier.BASIC, "fence_management", "limit", 3)));
        when(resolver.resolve(1L, null)).thenReturn(2);

        service.registerResolver(resolver);
        var result = service.check(SubscriptionTier.BASIC, "fence_management", 2);
        assertThat(result.isAllowed()).isTrue();
    }

    @Test
    void checkQuota_gateTypeLimit_atLimit_returnsDenied() {
        when(gateRepo.findByTierAndFeatureKey(SubscriptionTier.BASIC, "fence_management"))
            .thenReturn(Optional.of(new FeatureGate(SubscriptionTier.BASIC, "fence_management", "limit", 3)));
        when(resolver.resolve(1L, null)).thenReturn(3);

        service.registerResolver(resolver);
        var result = service.check(SubscriptionTier.BASIC, "fence_management", 3);
        assertThat(result.isAllowed()).isFalse();
        assertThat(result.getDenyReason()).contains("已达上限");
    }

    @Test
    void checkQuota_noGate_returnsAllowed() {
        when(gateRepo.findByTierAndFeatureKey(SubscriptionTier.PREMIUM, "unknown_feature"))
            .thenReturn(Optional.empty());

        var result = service.check(SubscriptionTier.PREMIUM, "unknown_feature", 0);
        assertThat(result.isAllowed()).isTrue();
    }

    @Test
    void checkQuota_limitZero_returnsAllowed() {
        when(gateRepo.findByTierAndFeatureKey(SubscriptionTier.ENTERPRISE, "api_calls"))
            .thenReturn(Optional.of(new FeatureGate(SubscriptionTier.ENTERPRISE, "api_calls", "none", null)));

        var result = service.check(SubscriptionTier.ENTERPRISE, "api_calls", 999);
        assertThat(result.isAllowed()).isTrue();
    }

    @Test
    void checkQuota_allowedWithRetention() {
        when(gateRepo.findByTierAndFeatureKey(SubscriptionTier.STANDARD, "livestock_management"))
            .thenReturn(Optional.of(new FeatureGate(SubscriptionTier.STANDARD, "livestock_management", "limit", 200)));
        when(resolver.resolve(1L, null)).thenReturn(250);

        service.registerResolver(resolver);
        var result = service.check(SubscriptionTier.STANDARD, "livestock_management", 250);
        assertThat(result.isAllowed()).isFalse();
        assertThat(result.getDenyReason()).contains("已达上限");
    }
}
```

- [ ] **Step 2: 运行测试验证失败**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.application.service.QuotaApplicationServiceTest" -v`
Expected: FAIL

- [ ] **Step 3: 实现 FeatureGate 值对象**

```java
package com.smartlivestock.commerce.domain.model;

public class FeatureGate {
    private SubscriptionTier tier;
    private String featureKey;
    private String gateType; // none, limit, lock, filter
    private Integer limitValue;

    public FeatureGate(SubscriptionTier tier, String featureKey, String gateType, Integer limitValue) {
        this.tier = tier;
        this.featureKey = featureKey;
        this.gateType = gateType;
        this.limitValue = limitValue;
    }

    public boolean isBlocked(int currentUsage) {
        return switch (gateType) {
            case "none" -> false;
            case "limit" -> currentUsage >= limitValue;
            case "lock" -> true;
            default -> false;
        };
    }

    public String getDenyReason(int currentUsage) {
        return switch (gateType) {
            case "limit" -> featureKey + " 已达上限 " + limitValue + "（当前 " + currentUsage + "）";
            case "lock" -> featureKey + " 需要升级解锁";
            default -> null;
        };
    }

    // Getters
    public SubscriptionTier getTier() { return tier; }
    public String getFeatureKey() { return featureKey; }
    public String getGateType() { return gateType; }
    public Integer getLimitValue() { return limitValue; }
}
```

- [ ] **Step 4: 实现 QuotaResult DTO**

```java
package com.smartlivestock.commerce.application.dto;

public class QuotaResult {
    private final boolean allowed;
    private final String denyReason;

    private QuotaResult(boolean allowed, String denyReason) {
        this.allowed = allowed;
        this.denyReason = denyReason;
    }

    public static QuotaResult allowed() {
        return new QuotaResult(true, null);
    }

    public static QuotaResult denied(String reason) {
        return new QuotaResult(false, reason);
    }

    public boolean isAllowed() { return allowed; }
    public String getDenyReason() { return denyReason; }
}
```

- [ ] **Step 5: 实现 UsageResolver 接口**

```java
package com.smartlivestock.commerce.application.service;

import jakarta.servlet.http.HttpServletRequest;

public interface UsageResolver {
    String featureKey();
    int resolve(Long tenantId, HttpServletRequest request);
}
```

- [ ] **Step 6: 实现 FeatureGateRepository port**

```java
package com.smartlivestock.commerce.domain.repository;

import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import java.util.Optional;

public interface FeatureGateRepository {
    Optional<FeatureGate> findByTierAndFeatureKey(SubscriptionTier tier, String featureKey);
}
```

- [ ] **Step 7: 实现 QuotaApplicationService**

```java
package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.domain.model.FeatureGate;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import com.smartlivestock.commerce.domain.repository.FeatureGateRepository;
import jakarta.servlet.http.HttpServletRequest;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;

public class QuotaApplicationService {

    private final FeatureGateRepository featureGateRepository;
    private final Map<String, UsageResolver> resolvers = new ConcurrentHashMap<>();

    public QuotaApplicationService(FeatureGateRepository featureGateRepository) {
        this.featureGateRepository = featureGateRepository;
    }

    public void registerResolver(UsageResolver resolver) {
        resolvers.put(resolver.featureKey(), resolver);
    }

    public QuotaResult check(SubscriptionTier tier, String featureKey, int currentUsage) {
        Optional<FeatureGate> gate = featureGateRepository.findByTierAndFeatureKey(tier, featureKey);
        if (gate.isEmpty()) return QuotaResult.allowed();

        FeatureGate g = gate.get();
        if (g.isBlocked(currentUsage)) {
            return QuotaResult.denied(g.getDenyReason(currentUsage));
        }
        return QuotaResult.allowed();
    }
}
```

- [ ] **Step 8: 运行测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.application.service.QuotaApplicationServiceTest" -v`
Expected: 6 tests PASS

- [ ] **Step 9: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/
git add smart-livestock-server/src/test/java/com/smartlivestock/commerce/
git commit -m "feat(commerce): add FeatureGate, QuotaApplicationService, and UsageResolver"
```

---

## Task 6: 持久化层 — JPA Entities + Mappers + Repositories

**Files:**
- Create: 5 JPA entities in `infrastructure/persistence/entity/`
- Create: 5 mappers in `infrastructure/persistence/mapper/`
- Create: 5 Spring Data JPA repositories in `infrastructure/persistence/`
- Create: 4 Repository implementations in `infrastructure/persistence/`
- Reference: `ranch/infrastructure/persistence/` for pattern

- [ ] **Step 1: 创建 5 个 JPA Entity**

每个 Entity 参照 `FenceJpaEntity` 模式：@Entity + @Table + @Version + 字段与 DDL 对齐。

```java
// SubscriptionJpaEntity.java
@Entity
@Table(name = "subscriptions")
public class SubscriptionJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long tenantId;
    private String tier;
    private String status;
    private String billingCycle;
    private Instant startedAt;
    private Instant expiresAt;
    private Instant trialEndsAt;
    @Version private Long version;
    private Instant createdAt;
    private Instant updatedAt;
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
```

```java
// ContractJpaEntity.java
@Entity
@Table(name = "contracts")
public class ContractJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String contractNumber;
    private Long partnerTenantId;
    private String billingModel;
    private BigDecimal revenueShareRatio;
    private Instant signedAt;
    private Instant expiresAt;
    private String status;
    @Version private Long version;
    private Instant createdAt;
    private Instant updatedAt;
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
```

```java
// RevenuePeriodJpaEntity.java
@Entity
@Table(name = "revenue_periods")
public class RevenuePeriodJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long contractId;
    private LocalDate periodStart;
    private LocalDate periodEnd;
    private int grossAmount;
    private int platformShare;
    private int partnerShare;
    private String status;
    private Instant settledAt;
    @Version private Long version;
    private Instant createdAt;
    private Instant updatedAt;
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
```

```java
// SubscriptionServiceJpaEntity.java
@Entity
@Table(name = "subscription_services")
public class SubscriptionServiceJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private Long tenantId;
    private String serviceName;
    private String serviceKeyPrefix;
    private String serviceKeyHash;
    private String status;
    private Instant lastHeartbeatAt;
    private Instant graceEndsAt;
    private Instant expiresAt;
    @Version private Long version;
    private Instant createdAt;
    private Instant updatedAt;
    @PreUpdate void onUpdate() { updatedAt = Instant.now(); }
}
```

```java
// FeatureGateJpaEntity.java
@Entity
@Table(name = "feature_gates")
public class FeatureGateJpaEntity {
    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String tier;
    private String featureKey;
    private String gateType;
    private Integer limitValue;
    private Instant createdAt;
}
```

- [ ] **Step 2: 创建 5 个 Mapper**

每个 Mapper 参照 `FenceMapper` 的 static 方法模式，处理 Domain ↔ JPA 转换：

```java
// SubscriptionMapper.java
public class SubscriptionMapper {
    public static SubscriptionJpaEntity toJpa(Subscription domain) { ... }
    public static Subscription toDomain(SubscriptionJpaEntity jpa) { ... }
}
// ContractMapper.java, RevenuePeriodMapper.java, SubscriptionServiceMapper.java, FeatureGateMapper.java
// 同样模式
```

- [ ] **Step 3: 创建 5 个 Spring Data JPA Repository**

```java
// SpringSubscriptionJpaRepository.java
public interface SpringSubscriptionJpaRepository extends JpaRepository<SubscriptionJpaEntity, Long> {
    Optional<SubscriptionJpaEntity> findByTenantId(Long tenantId);
    List<SubscriptionJpaEntity> findByStatusInAndExpiresAtBefore(List<String> statuses, Instant time);
}
// SpringContractJpaRepository.java
public interface SpringContractJpaRepository extends JpaRepository<ContractJpaEntity, Long> {
    List<ContractJpaEntity> findByStatus(String status);
    List<ContractJpaEntity> findByPartnerTenantId(Long partnerTenantId);
}
// SpringRevenuePeriodJpaRepository.java
public interface SpringRevenuePeriodJpaRepository extends JpaRepository<RevenuePeriodJpaEntity, Long> {
    List<RevenuePeriodJpaEntity> findByContractIdAndStatus(Long contractId, String status);
}
// SpringSubscriptionServiceJpaRepository.java
public interface SpringSubscriptionServiceJpaRepository extends JpaRepository<SubscriptionServiceJpaEntity, Long> {
    List<SubscriptionServiceJpaEntity> findByStatus(String status);
}
// SpringFeatureGateJpaRepository.java
public interface SpringFeatureGateJpaRepository extends JpaRepository<FeatureGateJpaEntity, Long> {
    Optional<FeatureGateJpaEntity> findByTierAndFeatureKey(String tier, String featureKey);
}
```

- [ ] **Step 4: 创建 4 个 Repository 实现**

```java
// JpaSubscriptionRepositoryImpl.java — 实现 domain/repository/SubscriptionRepository
// JpaContractRepositoryImpl.java — 实现 domain/repository/ContractRepository
// JpaRevenuePeriodRepositoryImpl.java — 实现 domain/repository/RevenuePeriodRepository
// JpaSubscriptionServiceRepositoryImpl.java — 实现 domain/repository/SubscriptionServiceRepository
```

每个实现注入对应的 Spring Data JPA Repository，使用 Mapper 转换。

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/infrastructure/
git commit -m "feat(commerce): add persistence layer — JPA entities, mappers, repositories"
```

---

## Task 7: @QuotaCheck 注解 + QuotaInterceptor + UsageResolver 实现

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/QuotaCheck.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/QuotaInterceptor.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/FarmLivestockUsageResolver.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/FarmFenceUsageResolver.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/SecurityConfig.java` — 注册拦截器

- [ ] **Step 1: 创建 @QuotaCheck 注解**

```java
package com.smartlivestock.commerce.interfaces;

import java.lang.annotation.*;

@Target(ElementType.METHOD)
@Retention(RetentionPolicy.RUNTIME)
@Documented
public @interface QuotaCheck {
    String feature();
}
```

- [ ] **Step 2: 创建 QuotaInterceptor**

拦截链位置：Auth + FarmScope 之后。

```java
package com.smartlivestock.commerce.interfaces;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.smartlivestock.commerce.application.dto.QuotaResult;
import com.smartlivestock.commerce.application.service.QuotaApplicationService;
import com.smartlivestock.commerce.domain.model.SubscriptionTier;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.method.HandlerMethod;
import org.springframework.web.servlet.HandlerInterceptor;

@Component
public class QuotaInterceptor implements HandlerInterceptor {

    private final QuotaApplicationService quotaService;
    private final ObjectMapper objectMapper;

    public QuotaInterceptor(QuotaApplicationService quotaService, ObjectMapper objectMapper) {
        this.quotaService = quotaService;
        this.objectMapper = objectMapper;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        if (!(handler instanceof HandlerMethod method)) return true;

        var annotation = method.getMethodAnnotation(QuotaCheck.class);
        if (annotation == null) return true;

        var tier = resolveTier(request);
        int usage = resolveCurrentUsage(request, annotation.feature());

        QuotaResult result = quotaService.check(tier, annotation.feature(), usage);
        if (!result.isAllowed()) {
            response.setStatus(403);
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write(objectMapper.writeValueAsString(
                new QuotaExceededResponse("QUOTA_EXCEEDED", result.getDenyReason())));
            return false;
        }
        return true;
    }

    private SubscriptionTier resolveTier(HttpServletRequest request) {
        String tierStr = request.getAttribute("subscriptionTier") instanceof String s ? s : "basic";
        return SubscriptionTier.valueOf(tierStr.toUpperCase());
    }

    private int resolveCurrentUsage(HttpServletRequest request, String feature) {
        Object usage = request.getAttribute("currentUsage_" + feature);
        return usage instanceof Integer i ? i : 0;
    }

    record QuotaExceededResponse(String code, String message) {}
}
```

- [ ] **Step 3: 实现 2 个 UsageResolver**

```java
// FarmFenceUsageResolver.java
@Component
public class FarmFenceUsageResolver implements UsageResolver {
    private final RanchFenceRepository fenceRepository; // ranch context
    @Override public String featureKey() { return "fence_management"; }
    @Override public int resolve(Long tenantId, HttpServletRequest request) {
        Long farmId = (Long) request.getAttribute("activeFarmId");
        return fenceRepository.countByFarmId(farmId);
    }
}

// FarmLivestockUsageResolver.java
@Component
public class FarmLivestockUsageResolver implements UsageResolver {
    private final RanchLivestockRepository livestockRepository;
    @Override public String featureKey() { return "livestock_management"; }
    @Override public int resolve(Long tenantId, HttpServletRequest request) {
        Long farmId = (Long) request.getAttribute("activeFarmId");
        return livestockRepository.countByFarmId(farmId);
    }
}
```

- [ ] **Step 4: 注册 QuotaInterceptor 到 SecurityConfig**

在现有 interceptor 注册之后追加 QuotaInterceptor，确保位于 Auth + FarmScope 之后。

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/
git add smart-livestock-server/src/main/java/com/smartlivestock/shared/security/SecurityConfig.java
git commit -m "feat(commerce): add @QuotaCheck annotation, QuotaInterceptor, and UsageResolver implementations"
```

---

## Task 8: Application Services

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationService.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/ContractApplicationService.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/RevenueApplicationService.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/service/BillingApplicationService.java` (预留)
- Create DTOs: CheckoutRequest, SubscriptionResponse, ContractResponse, RevenuePeriodResponse
- Test: `smart-livestock-server/src/test/java/com/smartlivestock/commerce/application/service/SubscriptionApplicationServiceTest.java`

- [ ] **Step 1: 创建 DTO 类**

```java
// CheckoutRequest.java
public record CheckoutRequest(
    String tier,
    String billingCycle,
    String idempotencyKey
) {}

// SubscriptionResponse.java
public record SubscriptionResponse(
    Long id, String tier, String status, String billingCycle,
    Instant startedAt, Instant expiresAt, Instant trialEndsAt
) {}

// ContractResponse.java
public record ContractResponse(
    Long id, String contractNumber, String billingModel,
    BigDecimal revenueShareRatio, String status,
    Instant signedAt, Instant expiresAt
) {}

// RevenuePeriodResponse.java
public record RevenuePeriodResponse(
    Long id, Long contractId, LocalDate periodStart, LocalDate periodEnd,
    int grossAmount, int platformShare, int partnerShare,
    String status, Instant settledAt
) {}
```

- [ ] **Step 2: 写 SubscriptionApplicationServiceTest**

```java
package com.smartlivestock.commerce.application.service;

import com.smartlivestock.commerce.domain.model.*;
import com.smartlivestock.commerce.domain.repository.SubscriptionRepository;
import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Optional;
import static org.assertj.core.api.Assertions.*;
import static org.mockito.Mockito.*;

class SubscriptionApplicationServiceTest {

    private SubscriptionRepository subRepo = mock(SubscriptionRepository.class);
    private SubscriptionApplicationService service = new SubscriptionApplicationService(subRepo);

    @Test
    void getOrCreateSubscription_existing_returnsExisting() {
        var existing = Subscription.startTrial(1L, Instant.now(), Instant.now().plus(14, ChronoUnit.DAYS));
        when(subRepo.findByTenantId(1L)).thenReturn(Optional.of(existing));

        var result = service.getOrCreateSubscription(1L);
        assertThat(result.getStatus()).isEqualTo(SubscriptionStatus.TRIAL);
    }

    @Test
    void upgrade_changesTierFromStandardToPremium() {
        var sub = Subscription.startTrial(1L, Instant.now(), Instant.now().plus(14, ChronoUnit.DAYS));
        sub.activate(SubscriptionTier.STANDARD, "monthly", Instant.now().plus(30, ChronoUnit.DAYS));
        when(subRepo.findByTenantId(1L)).thenReturn(Optional.of(sub));

        service.upgrade(1L, SubscriptionTier.PREMIUM);
        verify(subRepo).save(argThat(s -> s.getTier() == SubscriptionTier.PREMIUM));
    }
}
```

- [ ] **Step 3: 实现 SubscriptionApplicationService**

```java
@Service
public class SubscriptionApplicationService {
    private final SubscriptionRepository subscriptionRepository;

    public Subscription getOrCreateSubscription(Long tenantId) {
        return subscriptionRepository.findByTenantId(tenantId)
            .orElseGet(() -> {
                var sub = Subscription.startTrial(tenantId, Instant.now(),
                    Instant.now().plus(14, ChronoUnit.DAYS));
                return subscriptionRepository.save(sub);
            });
    }

    public void upgrade(Long tenantId, SubscriptionTier newTier) {
        var sub = subscriptionRepository.findByTenantId(tenantId)
            .orElseThrow(() -> new ApiException(ErrorCode.RESOURCE_NOT_FOUND, "订阅不存在"));
        sub.changeTier(newTier);
        subscriptionRepository.save(sub);
    }

    // expireTrial, suspend, reactivate, cancel — 委托聚合根方法
}
```

- [ ] **Step 4: 实现 ContractApplicationService**

```java
@Service
public class ContractApplicationService {
    private final ContractRepository contractRepository;
    // sign, suspend, reactivate, terminate, listByPartner — 委托聚合根
}
```

- [ ] **Step 5: 实现 RevenueApplicationService**

```java
@Service
public class RevenueApplicationService {
    private final RevenuePeriodRepository revenueRepo;
    private final ContractRepository contractRepo;
    // calculatePeriod, confirmByPlatform, confirmByPartner, settle — 委托聚合根
    // calculatePeriod 前置校验: contract.isActive()
}
```

- [ ] **Step 6: 创建 BillingApplicationService 预留骨架**

```java
@Service
public class BillingApplicationService {
    // 预留位置，Q1/Q2 不实现账单明细
}
```

- [ ] **Step 7: 运行测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.commerce.application.*Test" -v`
Expected: 2 tests PASS

- [ ] **Step 8: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/
git add smart-livestock-server/src/test/java/com/smartlivestock/commerce/
git commit -m "feat(commerce): add application services layer"
```

---

## Task 9: Controllers — App + Admin API

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/SubscriptionController.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/CheckoutController.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/AdminSubscriptionController.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/AdminContractController.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/AdminRevenueController.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/AdminServiceController.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/FenceController.java` — 加 @QuotaCheck
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/LivestockController.java` — 加 @QuotaCheck

- [ ] **Step 1: 实现 SubscriptionController（App API）**

```java
@RestController
@RequestMapping("/api/v1/subscription")
public class SubscriptionController {
    private final SubscriptionApplicationService subService;

    @GetMapping
    public ApiResponse<SubscriptionResponse> getMySubscription() { ... }

    @PostMapping("/checkout")
    public ApiResponse<SubscriptionResponse> checkout(@RequestBody CheckoutRequest req) { ... }

    @PostMapping("/change-tier")
    public ApiResponse<SubscriptionResponse> changeTier(@RequestBody Map<String, String> body) { ... }

    @PostMapping("/cancel")
    public ApiResponse<Void> cancel() { ... }
}
```

- [ ] **Step 2: 实现 CheckoutController**

checkout 接口含 `idempotencyKey` 参数。MVP 阶段 Mock 支付，直接激活。

- [ ] **Step 3: 实现 4 个 Admin Controller**

```java
// AdminSubscriptionController — /api/v1/admin/subscriptions
@GetMapping, @PutMapping("/{id}/status") // targetStatus + reason + 状态机校验

// AdminContractController — /api/v1/admin/contracts
@GetMapping, @PostMapping, @PutMapping("/{id}/suspend", @PutMapping("/{id}/terminate")

// AdminRevenueController — /api/v1/admin/revenue
@GetMapping("/periods"), @PostMapping("/periods/{id}/confirm-platform"), @PostMapping("/periods/{id}/confirm-partner")

// AdminServiceController — /api/v1/admin/services
@GetMapping, @PostMapping("/{id}/activate"), @PostMapping("/{id}/revoke")
```

- [ ] **Step 4: 在现有 Ranch Controller 加 @QuotaCheck**

```java
// FenceController.java — createFence 方法加注解
@QuotaCheck(feature = "fence_management")
@PostMapping
public ApiResponse<FenceResponse> createFence(...) { ... }

// LivestockController.java — registerLivestock 方法加注解
@QuotaCheck(feature = "livestock_management")
@PostMapping
public ApiResponse<LivestockResponse> registerLivestock(...) { ... }
```

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 6: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/interfaces/
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/FenceController.java
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/LivestockController.java
git commit -m "feat(commerce): add App + Admin controllers with @QuotaCheck on ranch endpoints"
```

---

## Task 10: CommerceScheduler — 6 个定时任务

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/scheduler/CommerceScheduler.java`

- [ ] **Step 1: 实现 CommerceScheduler**

```java
@Component
public class CommerceScheduler {

    private final SubscriptionRepository subRepo;
    private final ContractRepository contractRepo;
    private final RevenuePeriodRepository revenueRepo;
    private final SubscriptionServiceRepository serviceRepo;
    private final RevenueApplicationService revenueService;

    // Job 1: TrialExpiryJob — 每小时
    // 找 status=TRIAL AND trialEndsAt < now() → expireTrial()
    @Scheduled(cron = "0 0 * * * *")
    public void expireTrials() { ... }

    // Job 2: SubscriptionExpiryJob — 每小时
    // 找 status=ACTIVE AND expiresAt < now() → markExpired()
    @Scheduled(cron = "0 30 * * * *")
    public void expireSubscriptions() { ... }

    // Job 3: RenewalFailedExpiryJob — 每天凌晨2点
    // 找 status=RENEWAL_FAILED AND updatedAt < now()-7d → downgradeAfterRenewalFailure()
    @Scheduled(cron = "0 0 2 * * *")
    public void downgradeRenewalFailures() { ... }

    // Job 4: HeartbeatCheckJob — 每小时
    // 找 status=ACTIVE 的 SubscriptionService → checkHeartbeat()
    // 找 status=GRACE_PERIOD AND graceEndsAt < now() → degrade()
    @Scheduled(cron = "0 0 * * * *")
    public void checkHeartbeats() { ... }

    // Job 5: RevenueCalculationJob — 每月1日凌晨3点
    // 找 status=ACTIVE 的合同 → revenueService.calculatePeriod()
    // 前置过滤: contract.isActive()
    @Scheduled(cron = "0 0 3 1 * *")
    public void calculateRevenue() { ... }

    // Job 6: ContractExpiryJob — 每天凌晨4点
    // 找 status=ACTIVE AND expiresAt < now() → markExpired()
    @Scheduled(cron = "0 0 4 * * *")
    public void expireContracts() { ... }
}
```

- [ ] **Step 2: 确保 @EnableScheduling 在主类或配置类上**

检查 `SmartLivestockApplication.java` 是否有 `@EnableScheduling`，无则添加。

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 4: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/commerce/application/scheduler/
git commit -m "feat(commerce): add CommerceScheduler with 6 scheduled jobs"
```

---

## Task 11: 集成验证

**Files:**
- All Commerce files
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/model/Tenant.java` — 加 type + billingModel

- [ ] **Step 1: Tenant 扩展字段**

```java
// Tenant.java 追加
@Column(name = "type")
private String type; // rancher, reseller, enterprise, developer

@Column(name = "billing_model")
private String billingModel = "direct"; // direct, revenue_share, licensed, api_usage
```

- [ ] **Step 2: 全量编译**

Run: `cd smart-livestock-server && ./gradlew compileJava`
Expected: BUILD SUCCESSFUL

- [ ] **Step 3: 全量测试**

Run: `cd smart-livestock-server && ./gradlew test`
Expected: ALL PASS

- [ ] **Step 4: Flyway 迁移验证**

启动应用验证 V6 迁移成功，检查 PostgreSQL 中 6 张新表和种子数据。

Run: `cd smart-livestock-server && docker compose up -d postgres && ./gradlew bootRun`
验证: 连接数据库，检查 feature_gates 种子数据、subscriptions 种子数据。

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/
git commit -m "feat(commerce): complete Commerce bounded context — integration verified"
```

---

*Plan generated: 2026-05-18*
*Design spec: `docs/superpowers/specs/2026-05-18-commerce-context-design.md`*