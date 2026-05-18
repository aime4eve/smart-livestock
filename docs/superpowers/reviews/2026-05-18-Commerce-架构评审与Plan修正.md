# Commerce 限界上下文 — 架构评审与 Plan 修正

**日期**: 2026-05-18
**评审对象**: `docs/superpowers/specs/2026-05-18-commerce-context-design.md` (Spec) + `docs/superpowers/plans/2026-05-18-commerce-context-plan.md` (Plan)
**决策**: 以 Plan 为准更新 Spec
**状态**: 已完成

---

## 1. 评审发现

Plan 在多处偏离了经三轮评审的 Spec，部分简化丢失了重要的业务语义。以下按模块记录所有偏差及修正决策。

### 1.1 技术栈评价

| 技术 | 评价 |
|------|------|
| Spring Boot 3.3.0 + Java 17 | 合理，稳定 LTS 版本 |
| JPA + Hibernate + Mapper 隔离 | DDD 社区推荐做法，Domain 不受注解污染。5 个聚合根的 Mapper 开销可接受 |
| PostgreSQL 16 | 合理，DECIMAL 精度、部分索引原生支持 |
| Redis 7 | Spec 提到配额缓存但 Plan 未实现，需补充 |
| RocketMQ 5.1 | build.gradle 引入但 Plan 完全未使用。**决策：MVP 不引入，微服务拆分时再接入** |
| Flyway | 合理 |
| Testcontainers | 合理，但 Plan 缺少 Flyway+JPA 端到端集成测试 |

### 1.2 架构风险

| 风险 | 严重度 | 处理 |
|------|--------|------|
| Spec-Plan 偏差（7-8 处业务语义差异） | 高 | 本次修正全部对齐 |
| 领域事件无消费方 | 中 | 新增 Spring ApplicationEvent + notification 表 |
| Redis 缓存未落地 | 中 | feature_gates 缓存延后，MVP 直接查 DB |
| 跨上下文直接依赖（Commerce → Ranch Repository） | 中 | UsageResolver 通过 shared 层接口解耦 |
| 多实例定时任务无分布式锁 | 低 | MVP 单实例，水平扩展前加 `@SchedulerLock` |

---

## 2. 逐模块修正记录

### 2.1 SubscriptionTier 定价

**Plan 原始**：元为单位，固定超量 ¥20/百头
**Spec 原始**：分为单位，按 Tier 分级超量（¥1-3/头/月）
**修正后**：统一 USD 美分，基础价取 Plan，超量逻辑取 Spec

```java
BASIC(0, 50, 40)         // $0, 50头, 超出 $0.40/头/月
STANDARD(1400, 200, 30)  // $14, 200头, 超出 $0.30/头/月
PREMIUM(2800, 1000, 15)  // $28, 1000头, 超出 $0.15/头/月
ENTERPRISE(-1, -1, -1)   // 定制

// 字段: monthlyPriceCents, includedLivestock, overagePriceCents
// 超量: (livestockCount - includedLivestock) * overagePriceCents
```

全部定价硬编码在代码中，后续替换为 API 获取。无汇率转换逻辑。

### 2.2 Subscription 聚合根

**Plan 缺失 → 补充 3 项：**

| 补充项 | 理由 |
|--------|------|
| `billingModel` 字段 | 从 Tenant 快照，决定订阅的业务处理路径（direct/revenue_share/licensed/api_usage） |
| `cancelledAt` 字段 | 商业敏感操作必须记录时间戳，用于计费裁剪、审计、争议处理 |
| `recoverFromRenewalFailure()` 方法 | 续费失败宽限期内补缴恢复，无此方法则宽限期无意义 |

**最终字段：**
```
id, tenantId, tier, billingModel(补), status, billingCycle,
startedAt, expiresAt, trialEndsAt, cancelledAt(补)
```

**最终状态机：**
```
startTrial() → TRIAL
  ├─ expireTrial() → FREE (tier=BASIC)
  ├─ cancel() → CANCELLED (记录 cancelledAt)
  └─ activate(tier, billingCycle, expiresAt) → ACTIVE
       ├─ changeTier(newTier) → ACTIVE (可从 TRIAL/FREE/ACTIVE)
       ├─ suspend() → SUSPENDED → reactivate() → ACTIVE
       ├─ markRenewalFailed() → RENEWAL_FAILED
       │    ├─ recoverFromRenewalFailure() → ACTIVE (MVP 未触发) (补)
       │    └─ downgradeAfterRenewalFailure() → FREE
       ├─ cancel() → CANCELLED
       └─ markExpired() → EXPIRED

effectiveTier(): TRIAL → PREMIUM, 其他 → 实际 tier
```

### 2.3 Contract 聚合根

**Plan 缺失 → 补充 4 项：**

| 补充项 | 理由 |
|--------|------|
| DRAFT 状态 | 合同草稿流程，Admin 创建后需显式签署生效 |
| `effectiveTier` | B2B 合同决定子租户的服务等级，无此字段则分润无法关联等级 |
| `signedBy` | 审计必需，记录谁签署了合同 |
| `startedAt` | 合同生效日期独立于签署日期 |

**最终字段：**
```
id, tenantId, contractNumber, billingModel, effectiveTier(补),
revenueShareRatio(BigDecimal), signedBy(补), signedAt,
startedAt(补), expiresAt, status
```

**ContractStatus 枚举：**
```
DRAFT(补), ACTIVE, SUSPENDED, EXPIRED, TERMINATED
```

**最终状态机：**
```
create() → DRAFT → sign(userId) → ACTIVE
  ├─ suspend() → SUSPENDED → reactivate() → ACTIVE
  ├─ terminate() → TERMINATED
  └─ markExpired() → EXPIRED
```

**分润计算：** `calculateRevenueShare(grossAmount)` 返回 `RevenueShareResult(platformShare, partnerShare)`，int 美分。

### 2.4 RevenuePeriod 聚合根

**Plan 缺失 → 补充 2 项：**

| 补充项 | 理由 |
|--------|------|
| `tenantId` | 直接租户引用，避免通过 contractId JOIN 查询 |
| `revenueShareRatio` 快照 | 合同比例未来可能修改，历史结算必须保留当时的比例 |

**最终字段：**
```
id, contractId, tenantId(补),
periodStart, periodEnd,
grossAmount(美分), platformShare(美分), partnerShare(美分),
revenueShareRatio(快照, 补),
status, settledAt
```

**`totalDeviceFee`/`totalLivestock` 不冗余存储**：可从其他表追溯，未来加独立 BillingDetail 表。

**状态机**（与 Spec 一致）：
```
PENDING → confirmByPlatform() → PLATFORM_CONFIRMED
  → confirmByPartner() → PARTNER_CONFIRMED
  → settle() → SETTLED
```

### 2.5 SubscriptionService 聚合根

**Plan 缺失 → 补充 4 项：**

| 补充项 | 理由 |
|--------|------|
| `effectiveTier` | Licensed 服务的核心——授人以 Tier，degrade() 时需要知道从什么等级降级 |
| `deviceQuota` | Licensed 按设备数计费的上限，无此字段无法执行设备超量拒绝 |
| `startedAt` | 服务启动时间独立于创建时间 |
| 实例字段代替类常量 | `heartbeatIntervalHrs`/`gracePeriodDays` 用实例字段，MVP 默认值写死在工厂方法中，后续改可配置时领域模型零改动 |

**MVP 激活机制变更：先实现离线 License 文件（场景 C），后续扩展在线心跳（场景 A/B）。**

**最终字段：**
```
id, tenantId, serviceName, serviceKeyPrefix, serviceKeyHash,
effectiveTier(补), deviceQuota(补),
status, lastHeartbeatAt, graceEndsAt, startedAt(补), expiresAt,
heartbeatIntervalHrs(实例字段, 默认24), gracePeriodDays(实例字段, 默认7)
```

**最终状态机（完整定义，MVP 部分触发）：**
```
provision() → PROVISIONED (生成 License 文件)
  → activate() → ACTIVE (验证 License 文件签名)
     ├─ recordHeartbeat() → 更新时间戳 (MVP 未触发)
     ├─ checkHeartbeat() → GRACE_PERIOD (MVP 未触发)
     │    ├─ recordHeartbeat() → ACTIVE (恢复, MVP 未触发)
     │    └─ degrade() → DEGRADED (MVP 未触发)
     ├─ revoke() → EXPIRED
     └─ License 文件到期 → EXPIRED (MVP: 定时任务检查)
```

### 2.6 FeatureGate + 配额引擎

**Plan 缺失 → 补充 4 项：**

| 补充项 | 理由 |
|--------|------|
| filter gateType（`retentionDays`） | 数据保留天数门控（如 basic 告警历史 7 天 vs enterprise 365 天） |
| QuotaApplicationService 检查订阅状态 | 两道防线：先确认订阅活跃，再检查门控规则。无第一道则 SUSPENDED 租户可绕过 |
| `allowedWithRetention(days)` | filter 类型专用，查询层裁剪数据范围 |
| UsageResolver 签名改为纯值 | `resolve(tenantId, farmId)` 替代 `resolve(tenantId, HttpServletRequest)`，HTTP 对象不出 interfaces 层 |

**FeatureGate 最终字段：**
```
tier, featureKey, gateType("none"/"lock"/"limit"/"filter"),
limitValue(Integer), retentionDays(Integer), isEnabled(Boolean)
```

**QuotaApplicationService 最终依赖：**
```
SubscriptionRepository + FeatureGateRepository
```

**三种 gateType 各归其位：**
- lock / limit → QuotaInterceptor 拦截（请求时）
- filter → Application Service 调用 `getRetentionDays()` 裁剪查询范围（查询时）

**HTTP 泄漏点修正：**

| 位置 | 修正 |
|------|------|
| UsageResolver 接口 | `resolve(tenantId, farmId)` 纯值签名 |
| FarmFenceUsageResolver | farmId 由 QuotaInterceptor 传入，不从 request 提取 |
| FarmLivestockUsageResolver | 同上 |
| QuotaInterceptor | interfaces 层从 request 提取纯值后传给 service（正确，无需改） |

### 2.7 领域事件

**Plan 仅有 4 个事件且无发布/消费机制 → 扩展为 24 个事件 + Spring ApplicationEvent 发布 + notification 表消费。**

#### Subscription 事件（6 个）

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| SubscriptionCreatedEvent | `startTrial()` / `activate()` | Identity: TenantPhase SAMPLE→BATCH |
| SubscriptionTierChangedEvent | `changeTier()` / `expireTrial()` / `downgradeAfterRenewalFailure()` | Ranch/IoT: 更新配额缓存 |
| SubscriptionSuspendedEvent | `suspend()` | Ranch/IoT: 限制功能访问 |
| SubscriptionReactivatedEvent | `reactivate()` / `recoverFromRenewalFailure()` | Ranch/IoT: 恢复功能访问 |
| SubscriptionCancelledEvent | `cancel()` | 通知: 告知 owner |
| SubscriptionExpiredEvent | `markExpired()` | Ranch/IoT: 限制功能访问 |

#### Contract 事件（5 个）

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| ContractCreatedEvent | `create()` | 无（内部审计） |
| ContractSignedEvent | `sign()` | Identity: 创建 Partner 子 Tenant |
| ContractSuspendedEvent | `suspend()` | 通知: 告知合作方 |
| ContractTerminatedEvent | `terminate()` | 通知: 告知合作方 |
| ContractExpiredEvent | `markExpired()` | 通知: 告知合作方 |

#### RevenuePeriod 事件（4 个）

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| RevenuePeriodCreatedEvent | `calculate()` | 通知: 告知合作方有待确认结算 |
| RevenuePlatformConfirmedEvent | `confirmByPlatform()` | 通知: 告知合作方可确认 |
| RevenuePartnerConfirmedEvent | `confirmByPartner()` | 通知: 触发结算 |
| RevenueSettledEvent | `settle()` | 通知: 结算完成通知 |

#### SubscriptionService 事件（6 个）

| 事件 | 触发点 | 消费方 |
|------|--------|--------|
| ServiceActivatedEvent | `activate()` | 通知: 服务上线 |
| ServiceHeartbeatLostEvent | `checkHeartbeat()` | 通知: 运维告警 |
| ServiceHeartbeatRecoveredEvent | GRACE_PERIOD 中 `recordHeartbeat()` | 通知: 关闭告警工单 |
| ServiceDegradedEvent | `degrade()` | Ranch/IoT: 配额降为 BASIC |
| ServiceQuotaAdjustedEvent | `adjustQuota()` | Ranch/IoT: 更新配额缓存 |
| ServiceRevokedEvent | `revoke()` / `expire()` | Ranch/IoT: 停止服务 |

#### 发布机制

```
聚合根.registerEvent()
    ↓
ApplicationService.save() 后 → Spring ApplicationEventPublisher.publishEvent()
    ↓
NotificationEventListener（同步，同事务内）
    ├─ 写入 notification 表（前端拉取）
    └─ 跨上下文处理（Identity/Ranch/IoT 的 ApplicationListener）
```

MVP 不引入 RocketMQ，单体应用内 Spring ApplicationEvent 足够。微服务拆分时换传输层。

### 2.8 ErrorCode

**Commerce 新增 9 个：**

```java
ENTERPRISE_CUSTOM_PRICING,     // Enterprise 不走自动计费
INVALID_BILLING_MODEL,         // 无效的 billingModel 值
INVALID_REVENUE_SHARE_RATIO,   // 分润比例不在 0~1
SUBSCRIPTION_NOT_FOUND,        // 租户无订阅记录
SUBSCRIPTION_NOT_ACTIVE,       // 订阅非活跃状态
CONTRACT_NOT_ACTIVE,           // 合同非生效状态
SERVICE_KEY_MISMATCH,          // License 签名校验失败
SERVICE_LICENSE_EXPIRED,       // License 文件已过期
SETTLEMENT_DUPLICATE_CONFIRM,  // 重复确认结算
```

复用已有：`QUOTA_EXCEEDED`、`LICENSE_EXPIRED`、`STATE_CONFLICT`（覆盖所有状态机非法跳转）。

### 2.9 API 端点

共 30 个端点。

#### App API（9 个）

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

#### Admin API（21 个）

**订阅管理（AdminSubscriptionController，3 个）：**

| 方法 | 路径 |
|------|------|
| GET | `/admin/subscriptions` |
| GET | `/admin/subscriptions/{id}` |
| PUT | `/admin/subscriptions/{id}/status` |

**合同管理（AdminContractController，6 个）：**

| 方法 | 路径 |
|------|------|
| GET | `/admin/contracts` |
| POST | `/admin/contracts` |
| GET | `/admin/contracts/{id}` |
| PUT | `/admin/contracts/{id}` |
| POST | `/admin/contracts/{id}/sign` |
| PUT | `/admin/contracts/{id}/status` |

**分润结算（AdminRevenueController，5 个）：**

| 方法 | 路径 |
|------|------|
| GET | `/admin/revenue/periods` |
| GET | `/admin/revenue/periods/{id}` |
| POST | `/admin/revenue/calculate` |
| POST | `/admin/revenue/periods/{id}/confirm` |
| POST | `/admin/revenue/periods/{id}/recalculate` |

**Licensed 服务管理（AdminServiceController，5 个）：**

| 方法 | 路径 |
|------|------|
| GET | `/admin/subscription-services` |
| POST | `/admin/subscription-services` |
| GET | `/admin/subscription-services/{id}` |
| PUT | `/admin/subscription-services/{id}/status` |
| PUT | `/admin/subscription-services/{id}/quota` |

**功能门控配置（AdminFeatureGateController，2 个）：**

| 方法 | 路径 |
|------|------|
| GET | `/admin/feature-gates` |
| PUT | `/admin/feature-gates/{id}` |

#### Ranch 修改（2 个加注解）

| Controller | 修改 |
|-----------|------|
| FenceController | `createFence()` 加 `@QuotaCheck(feature = "fence_management")` |
| LivestockController | `registerLivestock()` 加 `@QuotaCheck(feature = "livestock_management")` |

---

## 3. DDL 最终汇总

V6 迁移：6 张新表 + 1 张 ALTER + 1 张 notifications + 44 条种子数据 + 1 个序列。

### subscriptions

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

### contracts

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

### revenue_periods

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

### subscription_services

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

### feature_gates

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

### notifications

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

### tenants ALTER

```sql
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS type VARCHAR(20);
ALTER TABLE tenants ADD COLUMN IF NOT EXISTS billing_model VARCHAR(20) DEFAULT 'direct';
UPDATE tenants SET type = 'rancher', billing_model = 'direct' WHERE type IS NULL;
```

### 种子数据

44 条 feature_gates（none 16 + limit 16 + lock 8 + filter 4），覆盖 8 个 feature_key × 4 tier。
1 条示例订阅（owner 租户 trial）。
1 个合同编号序列。

详见 DDL 文件。

---

## 4. 定时任务（已确认修正）

| Job | 频率 | 逻辑 |
|-----|------|------|
| TrialExpiryJob | 每小时 | status=TRIAL AND expires_at < now → expireTrial() |
| SubscriptionExpiryJob | 每小时 | status=ACTIVE AND expires_at < now → markRenewalFailed()（进入 7 天宽限期） |
| RenewalFailedExpiryJob | 每天 2:00 | status=RENEWAL_FAILED 超过 7d → downgradeAfterRenewalFailure() |
| HeartbeatCheckJob | 每 6 小时 | ACTIVE 的 SubscriptionService → checkHeartbeat()（MVP 未触发，预留） |
| LicenseExpiryJob | 每天 4:00 | 检查 License 文件是否到期 → expire() |
| ContractExpiryJob | 每天 5:00 | ACTIVE AND expires_at < now → markExpired() |
| RevenueCalculationJob | 每月 1 日 3:00 | ACTIVE 合同 → 计算分润 → 生成 RevenuePeriod |

---

## 5. 修正汇总

| 模块 | Plan→Spec 偏差数 | 补充项 |
|------|-----------------|--------|
| SubscriptionTier | 3 | 定价单位/数值/超量逻辑全部重新定义 |
| Subscription | 3 | billingModel + cancelledAt + recoverFromRenewalFailure |
| Contract | 4 | DRAFT + effectiveTier + signedBy + startedAt |
| RevenuePeriod | 2 | tenantId + revenueShareRatio 快照 |
| SubscriptionService | 4 | effectiveTier + deviceQuota + startedAt + 实例字段 |
| FeatureGate + 配额 | 4 | filter 类型 + 订阅状态检查 + retention + 纯值签名 |
| 领域事件 | 20 | 从 4 个扩展到 24 个，新增 Spring Event + notification 表 |
| ErrorCode | 0 | 新增 9 个，无修正 |
| API 端点 | 0 | 从 12 个扩展到 30 个 |
| DDL | 7 | 6 张新表 + notifications + tenants ALTER |

---

*评审生成日期: 2026-05-18*
*关联文档:*
- *Spec: `docs/superpowers/specs/2026-05-18-commerce-context-design.md`*
- *Plan: `docs/superpowers/plans/2026-05-18-commerce-context-plan.md`*
