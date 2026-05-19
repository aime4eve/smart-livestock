# Commerce 限界上下文实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 Commerce 限界上下文——订阅管理、合同管理、分润结算、Licensed 服务、配额引擎、领域事件、通知系统，支撑四种计费模型（direct/revenue_share/licensed/api_usage）。

**Architecture:** 独立 Commerce 限界上下文与 Identity/Ranch/IoT 平级，按 DDD 四层洋葱架构（domain → application → infrastructure → interfaces）。聚合根通过状态机管控生命周期，配额通过 @QuotaCheck 注解 + QuotaInterceptor 拦截（两道防线），定时任务处理过期/续费失败/结算，Spring ApplicationEvent 驱动通知。

**Tech Stack:** Spring Boot 3.3.0 / Java 17 / JPA + Hibernate / PostgreSQL 16 / Flyway / JUnit 5 + Mockito / Spring ApplicationEvent

**Spec:** `docs/superpowers/specs/2026-05-18-commerce-context-design.md` (v4)

**Review:** `docs/superpowers/reviews/2026-05-18-项目总体技术架构评审.md` (v2)

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
| `domain/model/event/*.java` | 15 个内部领域事件 (record) |
| `domain/repository/SubscriptionRepository.java` | 订阅 Repository port |
| `domain/repository/ContractRepository.java` | 合同 Repository port |
| `domain/repository/RevenuePeriodRepository.java` | 分润 Repository port |
| `domain/repository/SubscriptionServiceRepository.java` | 服务 Repository port |
| `domain/repository/FeatureGateRepository.java` | 功能门控 Repository port |
| `domain/repository/port/SubscriptionQueryPort.java` | v4 新增：跨上下文查询订阅状态 port |
| `application/dto/QuotaResult.java` | 配额校验结果（allowed/denied/allowedWithRetention） |
| `application/dto/CheckoutRequest.java` | 结算请求 DTO |
| `application/dto/SubscriptionResponse.java` | 订阅响应 DTO |
| `application/dto/ContractResponse.java` | 合同响应 DTO |
| `application/dto/RevenuePeriodResponse.java` | 分润响应 DTO |
| `application/service/SubscriptionApplicationService.java` | 订阅应用服务 |
| `application/service/ContractApplicationService.java` | 合同应用服务 |
| `application/service/RevenueApplicationService.java` | 分润应用服务 |
| `application/service/QuotaApplicationService.java` | 配额引擎服务（两道防线，实现 QuotaCheckService 接口） |
| `application/service/UsageResolver.java` | 用量解析接口（纯值签名） |
| `application/service/FarmLivestockUsageResolver.java` | farm 级牲畜用量 |
| `application/service/FarmFenceUsageResolver.java` | farm 级围栏用量 |
| `application/query/SubscriptionQueryService.java` | v4 新增：订阅读模型 |
| `application/query/RevenueQueryService.java` | v4 新增：分润读模型 |
| `application/assembler/SubscriptionAssembler.java` | v4 新增：订阅 DTO 映射 |
| `application/assembler/ContractAssembler.java` | v4 新增：合同 DTO 映射 |
| `application/assembler/RevenuePeriodAssembler.java` | v4 新增：分润 DTO 映射 |
| `application/job/CommerceScheduler.java` | v4 修正：定时任务（7 Job，从 scheduler/ 改为 job/） |
| `infrastructure/persistence/entity/*.java` | 5 JPA Entity |
| `infrastructure/persistence/mapper/*.java` | 5 Mapper |
| `infrastructure/persistence/Jpa*RepositoryImpl.java` | 5 Repository 实现 |
| `infrastructure/persistence/Spring*JpaRepository.java` | 5 Spring Data JPA |
| `interfaces/app/SubscriptionController.java` | v4 修正：App 订阅 API (6 端点)，归入 app/ 子目录 |
| `interfaces/app/CommerceController.java` | v4 修正：App 合同/分润 API (3 端点)，归入 app/ 子目录 |
| `interfaces/admin/AdminSubscriptionController.java` | v4 修正：Admin 订阅管理 (3 端点)，归入 admin/ 子目录 |
| `interfaces/admin/AdminContractController.java` | v4 修正：Admin 合同管理 (6 端点) |
| `interfaces/admin/AdminRevenueController.java` | v4 修正：Admin 分润管理 (5 端点) |
| `interfaces/admin/AdminServiceController.java` | v4 修正：Admin 服务管理 (5 端点) |
| `interfaces/admin/AdminFeatureGateController.java` | v4 修正：Admin 功能门控 (2 端点) |

### shared/ — Modify

| File | Change |
|------|--------|
| `shared/common/ErrorCode.java` | v4 修正：新增 9 个 Commerce 错误码 |
| `shared/common/DomainException.java` | v4 新增：领域层异常（替代领域模型对 ApiException 的直接依赖） |
| `shared/domain/event/*.java` | v4 新增：9 个跨上下文共享事件（供 Ranch/IoT/Identity 消费），详见下方列表 |

**9 个跨上下文共享事件（`shared/domain/event/`）：**
- SubscriptionCreatedEvent
- SubscriptionTierChangedEvent
- SubscriptionSuspendedEvent
- SubscriptionReactivatedEvent
- SubscriptionExpiredEvent
- ContractSignedEvent
- ServiceDegradedEvent
- ServiceQuotaAdjustedEvent
- ServiceRevokedEvent

### platform/ — Create

| File | Responsibility |
|------|---------------|
| `platform/messaging/NotificationService.java` | v4 修正：通知写入服务（从 shared/notification 归入 platform/messaging） |
| `platform/messaging/NotificationEventListener.java` | v4 修正：事件监听→写 notification 表（从 commerce/application/listener 归入 platform） |
| `platform/messaging/Notification.java` | v4 新增：通知 JPA 实体（对应 notifications 表） |
| `platform/messaging/NotificationRepository.java` | v4 新增：通知 Spring Data JPA Repository |
| `platform/web/QuotaCheck.java` | v4 修正：配额注解（横切关注点，从 commerce/interfaces 归入 platform/web） |
| `platform/web/QuotaInterceptor.java` | v4 修正：配额拦截器（从 commerce/interfaces 归入 platform/web） |
| `platform/web/QuotaCheckService.java` | v4 新增：配额检查接口（QuotaApplicationService 实现此接口） |

### platform/ — Modify

| File | Change |
|------|--------|
| `platform/web/ApiException.java` | v4 修正：仅保留 HTTP 状态码映射功能，领域模型不再直接使用 |

### identity/ — Modify

| File | Change |
|------|--------|
| `identity/domain/model/Tenant.java` | 新增 type + billingModel 字段 |

### ranch/ — Modify

| File | Change |
|------|--------|
| `ranch/interfaces/FenceController.java` | v4 修正：createFence 加 @QuotaCheck(feature="fence_management") |
| `ranch/interfaces/LivestockController.java` | v4 修正：registerLivestock 加 @QuotaCheck(feature="livestock_management") |

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
Task 2 (Enums + ErrorCode + DomainException + Events)
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
Task 9 (Notification + EventListener — platform/messaging)
    ↓
Task 10 (Application Services + Query Services + Assemblers)
    ↓
Task 11 (Controllers — app/ + admin/ 目录)
    ↓
Task 12 (Scheduler — 7 Jobs, job/ 目录)
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

按 Spec Section 2 完整 DDL，包含 7 张表/变更（同 Spec Section 2 完整 SQL，此处不重复）。

- [ ] **Step 2: 验证迁移可执行**

Run: `cd smart-livestock-server && ./gradlew flywayMigrate -x test 2>&1 | tail -5`

- [ ] **Step 3: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V6__create_commerce_tables.sql
git commit -m "feat(commerce): add V6 migration — 6 tables + notifications + seed data"
```

---

## Task 2: Enums + ErrorCode + DomainException + Events

**Files:**
- Modify: `ErrorCode.java` (新增 9 个，位于 `shared/common/`)
- Create: `DomainException.java` (位于 `shared/common/`)
- Create: 5 个枚举类 + 9 个跨上下文事件 (shared/domain/event/) + 15 个内部事件 (commerce/domain/model/event/)
- Test: `SubscriptionTierTest.java`

- [ ] **Step 1: 创建 DomainException**

位于 `shared/common/DomainException.java`：

```java
package com.smartlivestock.shared.common;

public class DomainException extends RuntimeException {
    private final ErrorCode code;

    public DomainException(ErrorCode code, String message) {
        super(message);
        this.code = code;
    }

    public ErrorCode getCode() { return code; }
}
```

- [ ] **Step 2: 扩展 ErrorCode**（位于 `shared/common/ErrorCode.java`）

新增：ENTERPRISE_CUSTOM_PRICING, INVALID_BILLING_MODEL, INVALID_REVENUE_SHARE_RATIO, SUBSCRIPTION_NOT_FOUND, SUBSCRIPTION_NOT_ACTIVE, CONTRACT_NOT_ACTIVE, SERVICE_KEY_MISMATCH, SERVICE_LICENSE_EXPIRED, SETTLEMENT_DUPLICATE_CONFIRM

- [ ] **Step 3: 创建枚举类**

SubscriptionTier: BASIC(0, 50, 40), STANDARD(1400, 200, 30), PREMIUM(2800, 1000, 15), ENTERPRISE(-1, -1, -1)
SubscriptionStatus: TRIAL, ACTIVE, FREE, SUSPENDED, RENEWAL_FAILED, CANCELLED, EXPIRED
ContractStatus: DRAFT, ACTIVE, SUSPENDED, EXPIRED, TERMINATED
RevenueSettlementStatus: PENDING, PLATFORM_CONFIRMED, PARTNER_CONFIRMED, SETTLED
SubscriptionServiceStatus: PROVISIONED, ACTIVE, GRACE_PERIOD, DEGRADED, EXPIRED

- [ ] **Step 4: 创建 24 个领域事件**

全部 record。9 个跨上下文事件放在 `shared/domain/event/`，15 个内部事件放在 `commerce/domain/model/event/`

- [ ] **Step 5: 写 SubscriptionTierTest**

测试 calculateMonthlyFee：含内、超量、Enterprise 抛 DomainException

- [ ] **Step 6: 运行测试**

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(commerce): add DomainException, enums, ErrorCode extensions, 24 domain events (9 shared + 15 internal)"
```

---

## Task 3: Subscription 聚合根

**Files:**
- Create: `Subscription.java`
- Test: `SubscriptionTest.java`

- [ ] **Step 1: 写 SubscriptionTest**

覆盖：startTrial, activate, expireTrial, effectiveTier, changeTier(FREE→ACTIVE), suspend, reactivate, markRenewalFailed, recoverFromRenewalFailure, downgradeAfterRenewalFailure, cancel(cancelledAt), markExpired, requireStatus 非法跳转。**领域模型使用 DomainException 而非 ApiException。**

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

依赖：SubscriptionRepository + FeatureGateRepository。checkQuota() 先检查订阅活跃，再检查门控。getRetentionDays() 供查询层调用。**实现 QuotaCheckService 接口，使用 DomainException 而非 ApiException。**

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

注入 Spring Data JPA，使用 Mapper 转换。**同时创建 SubscriptionQueryPort 实现。**

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add persistence layer — JPA entities, mappers, repositories"
```

---

## Task 8: @QuotaCheck + QuotaInterceptor + UsageResolver 实现

**Files:**
- Create: `platform/web/QuotaCheck.java`, `platform/web/QuotaInterceptor.java`, `platform/web/QuotaCheckService.java`, `FarmLivestockUsageResolver.java`, `FarmFenceUsageResolver.java`
- Modify: `SecurityConfig.java` (位于 `platform/security/`)

- [ ] **Step 1: 创建 QuotaCheckService 接口**

位于 `platform/web/QuotaCheckService.java`，定义 checkQuota(tenantId, featureKey, usage) 签名

- [ ] **Step 2: 创建 @QuotaCheck 注解**

位于 `platform/web/QuotaCheck.java`

- [ ] **Step 3: 创建 QuotaInterceptor**

位于 `platform/web/QuotaInterceptor.java`

从 request 提取 tenantId/farmId（纯值），调用 QuotaApplicationService

- [ ] **Step 4: 实现 2 个 UsageResolver**

纯值签名 resolve(tenantId, farmId)，通过 shared 层接口查询

- [ ] **Step 5: 注册 QuotaInterceptor**

位于 Auth + FarmScope 之后

- [ ] **Step 6: 编译验证**

- [ ] **Step 7: Commit**

```bash
git commit -m "feat(commerce): add QuotaCheckService, QuotaCheck annotation, interceptor, and UsageResolver in platform/web/"
```

---

## Task 9: Notification + EventListener（platform/messaging/）

**Files:**
- Create: `platform/messaging/NotificationService.java`
- Create: `platform/messaging/NotificationEventListener.java`

- [ ] **Step 1: 创建 Notification 实体 + Repository**

通知数据模型（notification 表的 JPA Entity + Repository）

- [ ] **Step 2: 创建 NotificationService**

位于 `platform/messaging/`，按事件类型生成 title/content，写入 notifications 表

- [ ] **Step 3: 创建 NotificationEventListener**

位于 `platform/messaging/`，Spring ApplicationListener 接收全部 24 个事件（9 跨上下文 + 15 内部）

- [ ] **Step 4: ApplicationService 中发布事件**

save() 后调用 Spring ApplicationEventPublisher

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add notification system in platform/messaging with Spring ApplicationEvent"
```

---

## Task 10: Application Services + Query Services + Assemblers

**Files:**
- Create: 3 个 ApplicationService + 3 个 Assembler + 2 个 QueryService + DTO classes
- Test: `SubscriptionApplicationServiceTest.java`, `ContractApplicationServiceTest.java`

- [ ] **Step 1: 创建 DTO 类**

- [ ] **Step 2: 创建 3 个 Assembler**（位于 `application/assembler/`）

SubscriptionAssembler, ContractAssembler, RevenuePeriodAssembler — DTO 映射集中化

- [ ] **Step 3: 写测试并实现 SubscriptionApplicationService**

getOrCreateSubscription, upgrade, expireTrial, suspend, reactivate, cancel。save() 后发布事件

- [ ] **Step 4: 实现 ContractApplicationService**

create(DRAFT), sign, suspend, reactivate, terminate

- [ ] **Step 5: 实现 RevenueApplicationService**

calculatePeriod, confirmByPlatform, confirmByPartner, settle, recalculate。前置校验 contract.isActive()

- [ ] **Step 6: 创建 2 个 QueryService**（位于 `application/query/`）

SubscriptionQueryService — 订阅读模型（状态 + 用量汇总）
RevenueQueryService — 分润读模型（列表 + 过滤）

- [ ] **Step 7: 运行测试**

- [ ] **Step 8: Commit**

```bash
git commit -m "feat(commerce): add application services, query services, and assemblers with event publishing"
```

---

## Task 11: Controllers — app/ + admin/ 目录

**Files:**
- Create: 7 个 Controller（按 app/ + admin/ 子目录组织）
- Modify: FenceController, LivestockController

- [ ] **Step 1: SubscriptionController (App, 6 端点)**

位于 `interfaces/app/SubscriptionController.java`：
GET /subscription, GET /subscription/plans, POST /subscription/checkout, PUT /subscription/tier, POST /subscription/cancel, GET /subscription/usage

- [ ] **Step 2: CommerceController (App, 3 端点)**

位于 `interfaces/app/CommerceController.java`：
GET /contracts/me, GET /revenue/periods, POST /revenue/periods/{id}/confirm

- [ ] **Step 3: 5 个 Admin Controller**

全部位于 `interfaces/admin/`：
AdminSubscriptionController(3), AdminContractController(6), AdminRevenueController(5), AdminServiceController(5), AdminFeatureGateController(2)

- [ ] **Step 4: Ranch Controller 加 @QuotaCheck**

`ranch/interfaces/FenceController.java` 和 `ranch/interfaces/LivestockController.java`

- [ ] **Step 5: 编译验证**

- [ ] **Step 6: Commit**

```bash
git commit -m "feat(commerce): add 30 API endpoints — interfaces/app/ + interfaces/admin/ with @QuotaCheck"
```

---

## Task 12: CommerceScheduler — 7 个定时任务（application/job/）

**Files:**
- Create: `application/job/CommerceScheduler.java`

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
git commit -m "feat(commerce): add CommerceScheduler with 7 scheduled jobs in application/job/"
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

## v3 → v4 修正记录

| 修正项 | v3 Plan | v4 Plan | 对应评审 |
|---|---|---|---|
| interfaces 目录 | Controller 平铺 | `interfaces/app/` + `interfaces/admin/` | 评审 T3 |
| application 目录 | `scheduler/` + `listener/` | `job/` + `query/` + `assembler/` | 评审 T4 |
| ErrorCode | `shared/common/ErrorCode.java` | `shared/common/ErrorCode.java`（保留原位） | 评审 v2 A1 修正 |
| 领域异常 | 直接用 ApiException | 新增 DomainException，领域模型不再依赖 ApiException | 评审 v2 A1 修正 |
| Notification | `shared/notification/` | `platform/messaging/NotificationService.java` | 评审 v2 A1 |
| EventListener | `commerce/application/listener/` | `platform/messaging/NotificationEventListener.java` | 评审 v2 T1.5 |
| Query Service | 无 | `application/query/SubscriptionQueryService.java` + `RevenueQueryService.java` | 评审 T5 |
| Assembler | 无 | `application/assembler/*.java`（3 个 DTO 映射器） | 评审 T4 |
| 跨上下文 port | 无 | `domain/repository/port/SubscriptionQueryPort.java` | 评审 v2 T1.5 |
| Scheduler 目录 | `application/scheduler/` | `application/job/` | 评审 T4 |
| 新增 Task 2 步骤 | 无 | Step 1 新增创建 DomainException | 评审 v2 A1 修正 |
| Task 10 扩展 | 仅 ApplicationService | 增加 QueryService + Assembler | 评审 T4/T5 |
| QuotaCheck 位置 | `commerce/interfaces/` | `platform/web/` + QuotaCheckService 接口 | 评审 v2 跨上下文 |
| 事件拆分 | 24 全在 commerce/ | 9 shared/domain/event/ + 15 commerce/domain/model/event/ | 评审 v2 跨上下文 |
| Ranch Controller 路径 | `ranch/interfaces/app/` | `ranch/interfaces/`（不改原目录结构） | 评审 v2 T3 |
| shared 路径 | `shared-kernel/` | `shared/`（实际包名） | 评审 v2 路径 |
| Notification 实体 | 未显式列出 | `platform/messaging/Notification.java` + `NotificationRepository.java` | 评审 v2 T9 |

---

*Plan version: 2026-05-18 v4 (based on v2 architecture review + v4 spec corrections)*
*Design spec: `docs/superpowers/specs/2026-05-18-commerce-context-design.md`*
*Review: `docs/superpowers/reviews/2026-05-18-项目总体技术架构评审.md`*
