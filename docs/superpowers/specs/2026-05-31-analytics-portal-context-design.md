# Analytics + API Portal 限界上下文设计规格

**日期**: 2026-05-31
**状态**: 设计中
**范围**: MVP Phase 2c — Analytics（统计聚合 + 趋势分析）+ API Portal（开发者门户 + 频率限制 + API Key 自管理）
**前置**: Phase 2b Health 已实施完成
**目标**: 从 Phase 1 的 stub 实现（静态 rate limit header、无统计、API Key 仅管理员管理）升级为生产级能力

---

## 1. 限界上下文定位

### 1.1 在 DDD 架构中的位置

本上下文拆分为两个子域，共享基础设施但职责独立：

```
com.smartlivestock/
├── analytics/              ← 新增：统计聚合 + 趋势分析
│   ├── domain/
│   │   ├── model/
│   │   │   ├── ApiCallLog.java          (聚合根：每次 API 调用记录)
│   │   │   ├── ApiUsageDaily.java       (聚合根：日聚合统计)
│   │   │   ├── ApiUsageMonthly.java     (值对象：月度聚合)
│   │   │   └── TrendPoint.java          (值对象：趋势数据点)
│   │   └── repository/
│   │       ├── ApiCallLogRepository.java
│   │       └── ApiUsageDailyRepository.java
│   ├── application/
│   │   ├── service/
│   │   │   ├── AnalyticsApplicationService.java
│   │   │   └── UsageAggregationService.java
│   │   └── dto/
│   │       ├── UsageOverviewDto.java
│   │       ├── UsageTrendDto.java
│   │       └── ApiCallLogDto.java
│   ├── infrastructure/
│   │   └── persistence/
│   │       ├── entity/    (3 JPA Entity)
│   │       ├── mapper/
│   │       └── repository/
│   └── interfaces/
│       ├── app/           (租户级)
│       │   └── AnalyticsAppController.java
│       └── admin/         (平台级)
│           └── AnalyticsAdminController.java
│
├── portal/                 ← 新增：API Portal + Key 自管理 + 频率限制
│   ├── domain/
│   │   ├── model/
│   │   │   ├── ApiKey.java              (从 identity 迁移，扩展字段)
│   │   │   ├── ApiKeyStatus.java        (枚举：ACTIVE / DISABLED / EXPIRED)
│   │   │   ├── RateLimitPolicy.java     (值对象：频率限制策略)
│   │   │   └── ApiKeyScopes.java        (值对象：权限范围)
│   │   ├── service/
│   │   │   ├── RateLimitService.java    (领域服务：限流判定)
│   │   │   └── ApiKeyLifecycleService.java
│   │   └── repository/
│   │       └── ApiKeyRepository.java
│   ├── application/
│   │   ├── service/
│   │   │   ├── PortalApplicationService.java
│   │   │   └── RateLimitApplicationService.java
│   │   └── dto/
│   │       ├── ApiKeyCreateRequest.java
│   │       ├── ApiKeyResponse.java
│   │       └── PortalDashboardDto.java
│   ├── infrastructure/
│   │   ├── persistence/
│   │   │   ├── entity/
│   │   │   ├── mapper/
│   │   │   └── repository/
│   │   └── ratelimit/
│   │       └── RedisRateLimitService.java  (Redis 滑动窗口实现)
│   └── interfaces/
│       ├── app/
│       │   └── PortalAppController.java    (租户自管理 Key)
│       └── admin/
│           └── PortalAdminController.java  (平台审批 + 全局管理)
│
├── shared/
│   ├── security/
│   │   ├── ApiKeyAuthFilter.java         (升级：记录调用日志)
│   │   └── RateLimitInterceptor.java     (新增：全局限流拦截器)
│   └── ...
```

### 1.2 与其他限界上下文的关系

```
Identity ──(tenantId, userId)──→ Analytics
    ↑                               ↑
    │ (apiKey 表迁移)               │ (调用日志)
Portal ←────────────────────── Open API Controllers
    │                                   │
    └─────(rateLimitPolicy)─────────────┘
```

- **Identity**: ApiKey 从 identity 迁移到 portal（Phase 1 已有 api_keys 表，Phase 2c 扩展字段）
- **Analytics**: 接收所有 Open API 调用日志，聚合统计
- **Portal**: 管理 Key 生命周期、限流策略，提供开发者门户
- **Shared**: RateLimitInterceptor 作为全局拦截器，在 API Key Auth 之后执行

---

## 2. 核心领域模型

### 2.1 ApiCallLog（API 调用日志）

每次 Open API 调用产生一条记录，用于统计和审计。

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | PK |
| apiKeyId | BIGINT | 关联 api_keys.id |
| tenantId | BIGINT | 关联 tenants.id |
| endpoint | VARCHAR(200) | 请求路径，如 `/open/farms/1/devices` |
| method | VARCHAR(10) | HTTP 方法 |
| statusCode | INT | HTTP 响应码 |
| responseTimeMs | INT | 响应时间（毫秒） |
| ipAddress | VARCHAR(45) | 客户端 IP |
| userAgent | VARCHAR(500) | User-Agent |
| requestedAt | TIMESTAMP | 请求时间 |
| farmId | BIGINT | 请求的 farmId（可选） |

**数据策略**: 保留 90 天明细，90 天后仅保留日聚合。通过定时任务清理。

### 2.2 ApiUsageDaily（日聚合统计）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGSERIAL | PK |
| apiKeyId | BIGINT | 关联 api_keys.id |
| tenantId | BIGINT | 关联 tenants.id |
| usageDate | DATE | 统计日期 |
| totalCalls | INT | 总调用次数 |
| successCalls | INT | 成功次数（2xx） |
| errorCalls | INT | 失败次数（4xx/5xx） |
| avgResponseMs | INT | 平均响应时间 |
| p95ResponseMs | INT | P95 响应时间 |
| topEndpoints | JSONB | 按端点分组统计 `{"/open/farms/1/devices": 120, ...}` |

**唯一约束**: `(apiKeyId, usageDate)`

### 2.3 RateLimitPolicy（频率限制策略）

嵌入 ApiKey 中的值对象，非独立表。

| 字段 | 说明 | 默认值 |
|------|------|--------|
| requestsPerMinute | 每分钟最大请求数 | 60 |
| burstSize | 允许的突发请求数 | 10 |
| dailyQuota | 每日请求配额（0=无限） | 0 |

不同 SubscriptionTier 对应不同默认策略：
- basic: 30/min, 5000/day
- standard: 60/min, 20000/day
- premium: 120/min, 100000/day
- enterprise: 自定义

### 2.4 ApiKey 扩展字段（在现有 api_keys 表上 ALTER）

| 新增字段 | 类型 | 说明 |
|------|------|------|
| scopes | VARCHAR(500) | 权限范围，逗号分隔：`livestock:read,fence:read,device:read,device:register` |
| requestsPerMinute | INT DEFAULT 60 | 每分钟限制 |
| dailyQuota | INT DEFAULT 0 | 日配额（0=无限） |
| lastUsedAt | TIMESTAMP | 已有，升级为每次调用更新 |
| description | VARCHAR(500) | Key 用途描述 |

---

## 3. 数据库迁移

### V22__create_analytics_portal_tables.sql

```sql
-- 1. 扩展 api_keys 表
ALTER TABLE api_keys
    ADD COLUMN IF NOT EXISTS scopes VARCHAR(500) DEFAULT 'livestock:read,fence:read,alert:read,device:read,gps:read',
    ADD COLUMN IF NOT EXISTS requests_per_minute INT DEFAULT 60,
    ADD COLUMN IF NOT EXISTS daily_quota INT DEFAULT 0,
    ADD COLUMN IF NOT EXISTS description VARCHAR(500),
    ADD COLUMN IF NOT EXISTS role VARCHAR(50) DEFAULT 'api_consumer';

-- 2. API 调用日志表
CREATE TABLE api_call_logs (
    id BIGSERIAL PRIMARY KEY,
    api_key_id BIGINT REFERENCES api_keys(id),
    tenant_id BIGINT NOT NULL,
    endpoint VARCHAR(200) NOT NULL,
    method VARCHAR(10) NOT NULL,
    status_code INT NOT NULL,
    response_time_ms INT,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    farm_id BIGINT,
    requested_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_call_logs_key_date ON api_call_logs(api_key_id, requested_at);
CREATE INDEX idx_call_logs_tenant_date ON api_call_logs(tenant_id, requested_at);
CREATE INDEX idx_call_logs_requested_at ON api_call_logs(requested_at);

-- 3. 日聚合统计表
CREATE TABLE api_usage_daily (
    id BIGSERIAL PRIMARY KEY,
    api_key_id BIGINT NOT NULL REFERENCES api_keys(id),
    tenant_id BIGINT NOT NULL,
    usage_date DATE NOT NULL,
    total_calls INT NOT NULL DEFAULT 0,
    success_calls INT NOT NULL DEFAULT 0,
    error_calls INT NOT NULL DEFAULT 0,
    avg_response_ms INT,
    p95_response_ms INT,
    top_endpoints JSONB DEFAULT '{}',
    UNIQUE(api_key_id, usage_date)
);

CREATE INDEX idx_usage_daily_tenant_date ON api_usage_daily(tenant_id, usage_date);
```

### V23__seed_portal_data.sql

```sql
-- 示例 API Key（仅用于开发测试）
INSERT INTO api_keys (tenant_id, key_name, key_hash, key_prefix, status, scopes, requests_per_minute, daily_quota, description, role, created_at)
VALUES (
    1,
    '测试开发者 Key',
    '<bcrypt_hash>',
    'sl_live_',
    'ACTIVE',
    'livestock:read,fence:read,alert:read,device:read,gps:read',
    60,
    5000,
    'Phase 2c 开发测试用',
    'api_consumer',
    NOW()
);

-- 示例调用日志（过去 7 天的模拟数据）
-- 通过 Java 种子或应用启动时生成
```

---

## 4. API 端点设计

### 4.1 Analytics — App 端（租户自查看）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/analytics/usage` | 当前租户的 API 使用概览 |
| GET | `/api/v1/analytics/usage/trend` | 使用趋势（按天/周/月） |
| GET | `/api/v1/analytics/usage/logs` | 最近的调用日志明细 |
| GET | `/api/v1/analytics/usage/endpoints` | 按端点分组的调用统计 |

**Usage Overview 响应示例**:
```json
{
  "code": "OK",
  "data": {
    "totalCalls": 12580,
    "successRate": 0.98,
    "avgResponseMs": 45,
    "period": "2026-05",
    "quotaUsed": 12580,
    "quotaLimit": 20000,
    "topEndpoints": [
      {"endpoint": "/open/farms/1/devices", "calls": 5200},
      {"endpoint": "/open/farms/1/livestock", "calls": 3800}
    ]
  }
}
```

**Usage Trend 响应示例**:
```json
{
  "code": "OK",
  "data": {
    "granularity": "daily",
    "points": [
      {"date": "2026-05-24", "totalCalls": 450, "successCalls": 445, "errorCalls": 5, "avgResponseMs": 42},
      {"date": "2026-05-25", "totalCalls": 480, "successCalls": 478, "errorCalls": 2, "avgResponseMs": 38}
    ]
  }
}
```

### 4.2 Analytics — Admin 端（平台级）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/admin/analytics/tenants/{tenantId}/usage` | 指定租户使用概览 |
| GET | `/api/v1/admin/analytics/global` | 全平台统计 |
| GET | `/api/v1/admin/analytics/top-consumers` | 消耗排行 |

### 4.3 Portal — App 端（开发者自管理 Key）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/portal/keys` | 列出我的 API Keys |
| POST | `/api/v1/portal/keys` | 创建新 Key |
| PUT | `/api/v1/portal/keys/{keyId}` | 更新 Key 名称/描述 |
| PUT | `/api/v1/portal/keys/{keyId}/status` | 启用/禁用 Key |
| DELETE | `/api/v1/portal/keys/{keyId}` | 删除 Key |
| GET | `/api/v1/portal/keys/{keyId}/usage` | 单 Key 使用统计 |
| GET | `/api/v1/portal/dashboard` | 开发者门户仪表盘 |

**创建 Key 响应示例**:
```json
{
  "code": "OK",
  "data": {
    "id": 15,
    "keyName": "生产环境 Key",
    "prefix": "sl_live_1a2b",
    "rawKey": "sl_live_1a2b3c4d5e6f7g8h9i0j...",
    "scopes": ["livestock:read", "fence:read", "device:read"],
    "requestsPerMinute": 60,
    "dailyQuota": 20000,
    "status": "ACTIVE",
    "createdAt": "2026-05-31T10:00:00Z",
    "warning": "请妥善保存 rawKey，创建后不可再次查看"
  }
}
```

### 4.4 Portal — Admin 端（平台审批 + 全局管理）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/v1/admin/portal/keys` | 全局 Key 列表 |
| PUT | `/api/v1/admin/portal/keys/{keyId}/rate-limit` | 调整限流策略 |
| PUT | `/api/v1/admin/portal/keys/{keyId}/scopes` | 调整权限范围 |
| POST | `/api/v1/admin/portal/keys/{keyId}/approve` | 审批 Key 申请 |
| GET | `/api/v1/admin/portal/stats` | 全局 Key 统计 |

---

## 5. 核心流程

### 5.1 API 调用全链路

```
请求进入
  → ApiKeyAuthFilter（解析 Key，设置 TenantContext）
    → RateLimitInterceptor（查 Redis 计数器，判定限流）
      → Controller（业务处理）
        → ResponseBodyAdvice（记录调用日志 → 异步入库）
  ← 响应（含 RateLimit 头）
```

### 5.2 频率限制实现（Redis 滑动窗口）

```
Key: ratelimit:{apiKeyId}:{window}
Value: Sorted Set (score=timestamp, member= requestId)

每次请求:
1. ZREMRANGEBYSCORE key 0 (now - 60s)     // 清理过期条目
2. ZCARD key                                // 当前窗口计数
3. if count >= limit → 429 Too Many Requests
4. ZADD key now requestId                   // 记录本次请求
5. EXPIRE key 120                           // 续期
```

### 5.3 日聚合任务

每日 00:05 执行：
1. 聚合前一天 `api_call_logs` → `api_usage_daily`（按 apiKeyId 分组）
2. 计算 totalCalls, successCalls, errorCalls, avgResponseMs, p95ResponseMs
3. 清理 90 天前的 `api_call_logs` 明细

### 5.4 ApiKey 自管理流程

```
开发者登录 App（role=api_consumer 或 owner/b2b_admin）
  → 访问"API 授权"页面
    → 查看已有 Keys 列表
      → 创建新 Key（选择 scopes，设置名称）
        → 系统生成 rawKey（仅展示一次）
          → Key 立即可用于 Open API 调用
```

---

## 6. 权限与 Scope 定义

### 6.1 Scope 常量

| Scope | 说明 | 对应 Open API 端点 |
|-------|------|-------------------|
| `livestock:read` | 读取牲畜数据 | `/open/farms/{id}/livestock` |
| `fence:read` | 读取围栏数据 | `/open/farms/{id}/fences` |
| `alert:read` | 读取告警数据 | `/open/farms/{id}/alerts` |
| `device:read` | 读取设备数据 | `/open/farms/{id}/devices` |
| `device:register` | 设备自注册 | `/open/devices/register` |
| `gps:read` | 读取 GPS 数据 | `/open/farms/{id}/gps-logs/*` |
| `health:read` | 读取健康数据（Phase 2b 扩展） | `/open/farms/{id}/health/*` |

### 6.2 Scope 校验

在 `ApiKeyAuthFilter` 或新增 `ScopeInterceptor` 中：
- 解析请求路径 → 映射到所需 scope
- 校验 ApiKey.scopes 是否包含所需 scope
- 不包含则返回 403 `AUTH_FORBIDDEN`

---

## 7. 前端对接

### 7.1 新增 Flutter 功能模块

| 模块 | 页面 | 说明 |
|------|------|------|
| `api_authorization` | KeyListPage | 已有骨架，补充 CRUD + 统计 |
| `api_authorization` | KeyCreatePage | 创建新 Key（选 scopes） |
| `api_authorization` | KeyDetailPage | 单 Key 详情 + 使用图表 |
| `api_authorization` | UsageDashboardPage | 使用概览 + 趋势图 |

### 7.2 新增 Flutter 数据层

```
features/api_authorization/
  data/
    portal_api_repository.dart
    analytics_api_repository.dart
  domain/
    portal_repository.dart        (接口)
    analytics_repository.dart     (接口)
    api_key_model.dart
    usage_model.dart
  presentation/
    api_authorization_controller.dart
    usage_controller.dart
```

---

## 8. 实施计划（8 个 Task）

### T1: 数据库迁移 + 种子数据
- V22 建表（api_call_logs, api_usage_daily, api_keys 扩展字段）
- V23 种子数据
- **验证**: 迁移成功执行，表结构正确

### T2: Domain Model + Repository
- ApiCallLog, ApiUsageDaily, RateLimitPolicy, ApiKeyScopes
- JPA Entity + Repository Impl
- **验证**: 单元测试通过

### T3: 频率限制引擎
- RedisRateLimitService（滑动窗口）
- RateLimitInterceptor（全局拦截）
- 升级 Open API 响应头（动态 X-RateLimit-Remaining）
- **验证**: 超限返回 429 + 正确的 RateLimit 头

### T4: 调用日志收集
- 在 ApiKeyAuthFilter 后增加日志记录（异步，不阻塞请求）
- ApiCallLogRepository 批量写入
- **验证**: Open API 调用后 db 中有日志记录

### T5: Analytics 聚合 + 查询
- UsageAggregationService（日聚合定时任务）
- AnalyticsApplicationService + Controller
- 日志清理任务（90 天）
- **验证**: 聚合数据正确，趋势查询返回合理数据

### T6: Portal API Key 自管理
- PortalAppController（租户 CRUD + dashboard）
- PortalAdminController（全局管理 + 限流策略调整）
- ApiKey 生成（secure random + bcrypt hash）
- **验证**: 创建/列表/禁用/删除 Key 全流程

### T7: Scope 校验
- ScopeInterceptor 或在 ApiKeyAuthFilter 中增加 scope 检查
- 路径到 scope 的映射表
- **验证**: 无 scope 的 Key 被拒绝

### T8: 前端对接
- Flutter Portal/Analytics Repository + Controller
- KeyListPage, KeyCreatePage, KeyDetailPage, UsageDashboardPage
- 使用图表（fl_chart 或 syncfusion）
- **验证**: 开发者可创建 Key、查看统计、管理 Key 生命周期

---

## 9. 与 Phase 1 的兼容性

| Phase 1 现状 | Phase 2c 变化 | 兼容策略 |
|---|---|---|
| API Key 仅 platform_admin 通过 admin API 管理 | 新增租户自管理 Portal API | admin API 保留，新增 portal API |
| 静态 rate limit header | Redis 动态计数 + 真实限流 | header 格式不变，值变为真实数据 |
| 无 scope，Key 有全部权限 | 新增 scope 字段，默认值保持全部权限 | 老 Key 的 scopes 字段自动填充默认值 |
| 无调用日志 | 新增 api_call_logs 表 | 不影响现有功能 |
| AnalyticsController 仅接收前端事件 | 扩展为完整的统计查询服务 | 前端事件接收保持兼容 |

---

## 10. 非目标（Phase 3）

- Webhook/回调通知
- API 版本管理（自动文档生成）
- 沙盒环境（mock 响应）
- 计费系统集成（按 API 调用量计费）
- GraphQL 网关
