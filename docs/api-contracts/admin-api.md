# Admin API 端点（`/api/v1/admin/`）

> **端点总数**: 59（Phase 1 + Phase 2a Commerce + Phase 2c；与实际对齐）
>
> ⚠️ **As-Built 校准（2026-06-26）**: 当前 Admin API 实际 **59 个端点**，本文档已**全量详列 59 个**：Phase 1 全部（含 TenantAdmin 补全的 `PUT /admin/tenants/{id}` 与 `GET /admin/tenants/{id}/farms`）+ Phase 2a Commerce 21 + Phase 2c（瓦片 7 / API 用量 3 / Portal 5）。端点真源为代码，详见 [后端实现现状 §7 API 设计](../superpowers/specs/2026-05-06-mvp-backend-design.md)。
> **认证**: JWT Bearer Token（role = platform_admin）
> **特点**: 跨租户视图，批量操作，管理动作。基础资源操作复用 App API 端点，admin 角色可访问任意 farm 数据。

---

## 1. 租户管理 — 7 端点

### GET /admin/tenants

跨租户列表。筛选: `?status=active&phase=sample&keyword=&page=1&pageSize=20`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A01",
  "data": {
    "items": [
      {
        "id": "7",
        "name": "Demo牧场",
        "contactName": "张三",
        "contactPhone": "13800138000",
        "phase": "sample",
        "status": "active",
        "farmCount": 3,
        "userCount": 5,
        "deviceCount": 10,
        "createdAt": "2026-01-15T08:00:00.000Z"
      }
    ],
    "page": 1, "pageSize": 20, "total": 42
  }
}
```

### POST /admin/tenants

创建租户（后台代建）。

```
Request:
{ "name": "新城牧场", "contactName": "李四", "contactPhone": "13900139000", "phase": "sample" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-A02", "data": { "id": "43", "name": "新城牧场", "phase": "sample" } }
```

### GET /admin/tenants/{tenantId}

租户详情（含聚合统计）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A03",
  "data": {
    "id": "7", "name": "Demo牧场", "contactName": "张三", "contactPhone": "13800138000", "phase": "sample", "status": "active",
    "farmCount": 3, "userCount": 5, "deviceCount": 10, "activeLicenseCount": 8,
    "createdAt": "2026-01-15T08:00:00.000Z", "updatedAt": "2026-05-01T12:00:00.000Z"
  }
}
```

### PUT /admin/tenants/{tenantId}/status

启用/禁用租户。幂等。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A04", "data": { "id": "7", "status": "disabled" } }

Error 422:
{ "code": "VALIDATION_ERROR", "message": "status 必须为 active 或 disabled", "requestId": "req-A04" }
```

### PUT /admin/tenants/{tenantId}/phase

变更租户阶段（sample ↔ batch）。幂等。

```
Request:
{ "phase": "batch" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A05", "data": { "id": "7", "phase": "batch" } }
```

> ⚠️ 实际仅 `sample → batch` 调 `transitionToBatch` 执行真实迁移；`batch → sample` 仅回显不迁移（非真正双向）。

### PUT /admin/tenants/{tenantId}

更新租户基本信息（name / contactName / contactPhone）。

```
Request:
{ "name": "Demo牧场（更名）", "contactName": "张三", "contactPhone": "13800138001" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A05b", "data": { "id": "7", "name": "Demo牧场（更名）", "phase": "sample" } }
```

### GET /admin/tenants/{tenantId}/farms

列出租户下的农场。

```
查询参数: page（默认 1）、pageSize（默认 20）—— 仅回显，未切片

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A05c",
  "data": {
    "items": [ { "id": "1", "tenantId": "7", "name": "主牧场", "latitude": 28.24, "longitude": 112.85, "areaHectares": 50.0 } ],
    "page": 1, "pageSize": 20, "total": 1
  }
}

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "租户不存在: 7", "requestId": "req-A05c" }
```

> ⚠️ **租户管理实现注意**：list/detail 的 `status` 字段恒为 `"active"`（Tenant 领域模型暂无 status 字段）；`PUT .../status` 为 **stub**（校验取值与租户存在性，但**未持久化**，注释标注 "pending Tenant domain model status field extension"）；list 的 `status`/`phase`/`keyword` 筛选参数与 `deviceCount` 当前**未真实生效**（deviceCount 恒 0，筛选未实际应用）。

---

## 2. 用户管理 — 6 端点

### GET /admin/users

跨租户用户列表。筛选: `?tenantId=7&farmId=1&role=owner&status=active&keyword=张三&page=1&pageSize=20`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A06",
  "data": {
    "items": [
      { "id": "42", "username": "zhangsan", "name": "张三", "phone": "13800138000", "role": "owner", "tenantId": "7", "tenantName": "Demo牧场", "status": "active", "farmCount": 2, "lastLoginAt": "2026-05-07T09:00:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 156
  }
}
```

### POST /admin/users

创建用户（指定 tenantId + role）。

```
Request:
{ "phone": "13900139000", "name": "王五", "role": "worker", "tenantId": "7", "password": "Worker@123" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-A07", "data": { "id": "157", "username": "13900139000", "name": "王五", "role": "worker", "tenantId": "7" } }

Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "该手机号已注册", "requestId": "req-A07" }
```

### GET /admin/users/{userId}

用户详情（含关联农场列表）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A08",
  "data": {
    "id": "42", "username": "zhangsan", "name": "张三", "phone": "13800138000", "role": "owner", "tenantId": "7", "status": "active",
    "farms": [
      { "farmId": "1", "farmName": "城北牧场", "role": "owner", "assignedAt": "2026-01-15T08:00:00.000Z" },
      { "farmId": "2", "farmName": "城南牧场", "role": "owner", "assignedAt": "2026-02-01T10:00:00.000Z" }
    ],
    "lastLoginAt": "2026-05-07T09:00:00.000Z", "createdAt": "2026-01-15T08:00:00.000Z"
  }
}
```

### PUT /admin/users/{userId}

更新用户信息。

```
Request:
{ "name": "张三丰", "phone": "13800138001", "role": "owner" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A09", "data": { "id": "42", "name": "张三丰", ... } }
```

### PUT /admin/users/{userId}/status

启用/禁用/锁定用户。幂等。

```
Request:
{ "status": "locked" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A10", "data": { "id": "42", "status": "locked" } }

Error 422:
{ "code": "VALIDATION_ERROR", "message": "status 必须为 active、disabled 或 locked", "requestId": "req-A10" }
```

### POST /admin/users/{userId}/reset-password

重置密码。

```
Request:
{ "newPassword": "Reset@123" }

Response 200:
{ "code": "OK", "message": "密码已重置", "requestId": "req-A11" }
```

---

## 3. 农场管理 — 4 端点

### GET /admin/farms

跨租户农场列表。筛选: `?tenantId=7&status=active&keyword=&page=1&pageSize=20`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A12",
  "data": {
    "items": [
      { "id": "1", "tenantId": "7", "tenantName": "Demo牧场", "name": "城北牧场", "status": "active", "livestockCount": 120, "deviceCount": 45, "userCount": 5, "createdAt": "2026-01-15T08:00:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 128
  }
}
```

### POST /admin/farms

为任意租户创建农场。

```
Request:
{ "tenantId": "7", "name": "西山牧场", "latitude": 28.2500000, "longitude": 112.8400000, "areaHectares": 100.00 }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-A13", "data": { "id": "129", "name": "西山牧场", ... } }
```

### GET /admin/farms/{farmId}

农场详情（admin 视图，含聚合统计）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A14",
  "data": { "id": "1", "tenantId": "7", "name": "城北牧场", "status": "active", "livestockCount": 120, "deviceCount": 45, "userCount": 5, "activeAlertCount": 8, "createdAt": "2026-01-15T08:00:00.000Z" }
}
```

### PUT /admin/farms/{farmId}/status

启用/禁用农场。幂等。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A15", "data": { "id": "1", "status": "disabled" } }
```

---

## 4. 跨租户聚合 — 1 端点

### GET /admin/dashboard

平台总览（租户数、农场数、用户数、设备数、活跃告警数的当前值和按天趋势）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A16",
  "data": {
    "summary": { "tenantCount": 42, "farmCount": 128, "userCount": 156, "deviceCount": 520, "activeAlertCount": 64 },
    "trends": [
      { "date": "2026-05-01", "newTenants": 2, "newUsers": 5, "newDevices": 12, "resolvedAlerts": 8 },
      { "date": "2026-05-02", "newTenants": 1, "newUsers": 3, "newDevices": 8, "resolvedAlerts": 6 }
    ]
  }
}
```

---

## 5. 审计 — 1 端点

### GET /admin/audit-logs

操作审计日志。筛选: `?tenantId=7&userId=42&action=alert.acknowledge&startTime=2026-05-01T00:00:00.000Z&endTime=2026-05-07T23:59:59.000Z&page=1&pageSize=20`。

Phase 1 先做查询接口，写入由 Application Service 内部通过领域事件自动完成。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A17",
  "data": {
    "items": [
      { "id": "AU-001", "tenantId": "7", "userId": "42", "userName": "张三", "action": "alert.acknowledge", "resourceType": "alert", "resourceId": "501", "detail": "确认告警: 牛只越界", "ip": "172.22.1.100", "createdAt": "2026-05-07T10:30:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 230
  }
}
```

---

## 6. API Key 管理 — 4 端点

### GET /admin/api-keys

列出所有 Key。筛选: `?tenantId=7&status=active&page=1&pageSize=20`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A18",
  "data": {
    "items": [
      { "keyId": "key_abc123", "tenantId": "7", "tenantName": "Demo牧场", "name": "Demo Key", "prefix": "sl_test_a1b2", "scopes": ["livestock:read", "fence:read", "alert:read", "device:read", "gps:read"], "status": "active", "expiresAt": null, "rateLimit": 60, "lastUsedAt": "2026-05-07T10:00:00.000Z", "createdAt": "2026-03-01T08:00:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 15
  }
}
```

### POST /admin/api-keys

创建 Key。

```
Request:
{ "tenantId": "7", "name": "新客户 Key", "scopes": ["livestock:read", "fence:read", "alert:read"], "expiresInDays": 365 }

Response 201:
{
  "code": "OK", "message": "success", "requestId": "req-A19",
  "data": { "keyId": "key_def456", "prefix": "sl_live_c3d4", "apiKey": "sl_live_c3d4e5f6g7h8i9j0k1l2m3n4o5p6q7r8", "scopes": ["livestock:read", "fence:read", "alert:read"], "expiresAt": "2027-05-07T00:00:00.000Z", "rateLimit": 60 }
}
```

注意：`apiKey` 完整明文仅在创建响应中返回一次，之后不可再次获取。

### PUT /admin/api-keys/{keyId}/status

启用/禁用 Key。幂等。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A20", "data": { "keyId": "key_abc123", "status": "disabled" } }
```

### DELETE /admin/api-keys/{keyId}

撤销 Key（不可恢复）。状态变为 revoked，Key 立即失效。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A21" }
```

---

## 7. 商业（Commerce）— 21 端点（Phase 2a）

> **权限**: 全部需 `ROLE_PLATFORM_ADMIN`（方法体内 `requirePlatformAdmin()` 校验，非 admin → `AUTH_FORBIDDEN` / 403）。
> 金额单位均为**分**（cents）；日期 `yyyy-MM-dd`；时间 ISO-8601。
> 状态机非法跳转统一 `STATE_CONFLICT` / 409，消息形如 `Cannot {action}: expected {X} but was {Y}`。

**订阅管理（AdminSubscriptionController，3 端点）**

### GET /admin/subscriptions

分页列出全部订阅，可按 status/tier 过滤。

| 参数 | 类型 | 必填 | 默认 | 说明 |
|------|------|------|------|------|
| page | int | 否 | 1 | ⚠️ 仅回显，当前实现未真正切片（items 为全量过滤结果） |
| pageSize | int | 否 | 20 | 同上，仅回显 |
| status | String | 否 | — | `SubscriptionStatus`（大小写不敏感） |
| tier | String | 否 | — | `SubscriptionTier`（大小写不敏感） |

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A22",
  "data": {
    "items": [
      { "id": 801, "tenantId": 7, "tier": "STANDARD", "billingModel": "direct", "status": "ACTIVE", "billingCycle": "monthly", "effectiveTier": "STANDARD", "startedAt": "...", "expiresAt": "...", "trialEndsAt": null, "cancelledAt": null }
    ],
    "page": 1, "pageSize": 20, "total": 1
  }
}
```

### GET /admin/subscriptions/{id}

订阅详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A23", "data": { "id": 801, "...SubscriptionResponse": "..." } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "Subscription not found: 801", "requestId": "req-A23" }
```

### PUT /admin/subscriptions/{id}/status

变更订阅状态。`targetStatus` 仅接受 `SUSPENDED` / `ACTIVE` / `CANCELLED`。

```
Request:
{ "targetStatus": "SUSPENDED" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A24", "data": { "id": 801, "status": "SUSPENDED", "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot suspend: expected ACTIVE but was FREE", "requestId": "req-A24" }
```

> 映射：`SUSPENDED`→suspend（需 ACTIVE）；`ACTIVE`→reactivate（需 SUSPENDED/CANCELLED）；`CANCELLED`→cancel（需 ACTIVE/TRIAL）。

**合同管理（AdminContractController，6 端点）**

### GET /admin/contracts

列出 ACTIVE 合同。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A25",
  "data": [ { "id": 901, "tenantId": 7, "contractNumber": "CT-2026-001", "billingModel": "revenue_share", "effectiveTier": "PREMIUM", "revenueShareRatio": 0.15, "status": "ACTIVE", "...": "..." } ] }
```

### POST /admin/contracts

创建合同草稿（→ DRAFT）。`billingModel="revenue_share"` 时 `revenueShareRatio` 必填且须 (0,1)。

```
Request:
{ "tenantId": 7, "contractNumber": "CT-2026-002", "billingModel": "revenue_share", "effectiveTier": "PREMIUM", "revenueShareRatio": 0.15 }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-A26", "data": { "id": 902, "status": "DRAFT", "...": "..." } }

Error 400:
{ "code": "INVALID_REVENUE_SHARE_RATIO", "message": "Revenue share ratio must be > 0 and < 1", "requestId": "req-A26" }
```

### GET /admin/contracts/{id}

合同详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A27", "data": { "id": 902, "...ContractResponse": "..." } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "Contract not found: 902", "requestId": "req-A27" }
```

### PUT /admin/contracts/{id}

修改草稿合同（仅 DRAFT 可改；传 null 字段表示不改）。

```
Request:
{ "effectiveTier": "ENTERPRISE", "revenueShareRatio": 0.20 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A28", "data": { "id": 902, "status": "DRAFT", "effectiveTier": "ENTERPRISE", "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot updateDraft: expected DRAFT but was ACTIVE", "requestId": "req-A28" }
```

### POST /admin/contracts/{id}/sign

签署合同（DRAFT → ACTIVE）。无请求体；`signedBy` 取自认证 principal。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A29", "data": { "id": 902, "status": "ACTIVE", "signedBy": 1, "signedAt": "2026-05-20T00:00:00Z", "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot sign: expected DRAFT but was ACTIVE", "requestId": "req-A29" }
```

### PUT /admin/contracts/{id}/status

变更合同状态。`targetStatus` 仅 `SUSPENDED` / `ACTIVE` / `TERMINATED`。

```
Request:
{ "targetStatus": "TERMINATED" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A30", "data": { "id": 902, "status": "TERMINATED", "...": "..." } }
```

> 映射：`SUSPENDED`→suspend（需 ACTIVE）；`ACTIVE`→reactivate（需 SUSPENDED）；`TERMINATED`→terminate（需 ACTIVE）。

**分润对账（AdminRevenueController，5 端点）**

### GET /admin/revenue/periods

分页列出全部结算周期（跨租户）。⚠️ 同 `subscriptions` 列表，page/pageSize 仅回显未切片。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A31",
  "data": {
    "items": [
      { "id": 701, "contractId": 901, "tenantId": 7, "periodStart": "2026-05-01", "periodEnd": "2026-05-31", "grossAmount": 200000, "platformShare": 170000, "partnerShare": 30000, "revenueShareRatio": 0.15, "status": "PLATFORM_CONFIRMED", "settledAt": null }
    ],
    "page": 1, "pageSize": 20, "total": 1
  }
}
```

### GET /admin/revenue/periods/{id}

结算周期详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A32", "data": { "id": 701, "...RevenuePeriodResponse": "..." } }
```

### POST /admin/revenue/calculate

触发月度结算计算（合同须 ACTIVE）。返回该合同最新一条周期。

```
Request:
{ "contractId": 901, "periodStart": "2026-05-01", "periodEnd": "2026-05-31", "grossAmountCents": 200000 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A33", "data": { "id": 701, "status": "PENDING", "grossAmount": 200000, "platformShare": 170000, "partnerShare": 30000, "...": "..." } }

Error 409:
{ "code": "CONTRACT_NOT_ACTIVE", "message": "Contract is not active: 901", "requestId": "req-A33" }

Error 400:
{ "code": "VALIDATION_ERROR", "message": "Gross amount must be non-negative", "requestId": "req-A33" }
```

### POST /admin/revenue/periods/{id}/confirm

平台确认（PENDING → PLATFORM_CONFIRMED）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A34", "data": { "id": 701, "status": "PLATFORM_CONFIRMED", "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot confirmByPlatform: expected PENDING but was PLATFORM_CONFIRMED", "requestId": "req-A34" }
```

### POST /admin/revenue/periods/{id}/recalculate

重算结算周期（非 SETTLED 状态可调，重算后回退为 PENDING）。

```
Request:
{ "grossAmountCents": 210000 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A35", "data": { "id": 701, "status": "PENDING", "grossAmount": 210000, "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot recalculate a settled period", "requestId": "req-A35" }
```

> 完整对账链：`PENDING` →（confirm，本端点 5.4）→ `PLATFORM_CONFIRMED` →（合作方在 App 端 /revenue/periods/{id}/confirm）→ `PARTNER_CONFIRMED` →（settle）→ `SETTLED`。settle 未在 Admin Controller 暴露端点，由 RevenueApplicationService 内部或调度触发。

**授权服务（AdminServiceController，5 端点）**

> 直接操作 `SubscriptionService` 聚合并发布领域事件（未走 ApplicationService 层）。`serviceKey` 仅存 SHA-256 哈希 + 前 8 位 prefix。

### GET /admin/subscription-services

分页列出授权服务。✅ 此端点**真正分页**（subList 切片）。可按 `tenantId` 过滤。

| 参数 | 类型 | 必填 | 默认 |
|------|------|------|------|
| page | int | 否 | 1 |
| pageSize | int | 否 | 20 |
| tenantId | Long | 否 | — |

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A36",
  "data": {
    "items": [
      { "id": 601, "tenantId": 7, "serviceName": "gps-tracking", "serviceKeyPrefix": "a1b2c3d4", "effectiveTier": "premium", "deviceQuota": 200, "status": "ACTIVE", "lastHeartbeatAt": "2026-05-20T00:00:00Z", "startedAt": "2026-05-01T00:00:00Z", "expiresAt": "2027-05-01T00:00:00Z" }
    ],
    "page": 1, "pageSize": 20, "total": 1
  }
}
```

### POST /admin/subscription-services

开通授权服务（→ PROVISIONED）。

```
Request:
{ "tenantId": 7, "serviceName": "gps-tracking", "serviceKey": "sk_live_abcd1234...", "tier": "PREMIUM", "deviceQuota": 200 }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-A37", "data": { "id": 602, "status": "PROVISIONED", "serviceKeyPrefix": "a1b2c3d4", "...": "..." } }
```

> `serviceKey` 明文不存储、不回显，仅返回 `serviceKeyPrefix`（哈希前 8 位）。

### GET /admin/subscription-services/{id}

服务详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A38", "data": { "id": 602, "...serviceMap": "..." } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "Subscription service not found: 602", "requestId": "req-A38" }
```

### PUT /admin/subscription-services/{id}/status

变更服务状态。`targetStatus` 仅 `ACTIVE` / `EXPIRED`。`ACTIVE` 仅当当前为 PROVISIONED 合法（激活后 expiresAt 设为 365 天后）。

```
Request:
{ "targetStatus": "ACTIVE" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A39", "data": { "id": 602, "status": "ACTIVE", "expiresAt": "2027-05-20T00:00:00Z", "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot activate: expected PROVISIONED but was ACTIVE", "requestId": "req-A39" }
```

### PUT /admin/subscription-services/{id}/quota

调整设备配额（仅 ACTIVE / GRACE_PERIOD 可调）。

```
Request:
{ "deviceQuota": 500 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A40", "data": { "id": 602, "deviceQuota": 500, "...": "..." } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot adjustQuota: current status is EXPIRED", "requestId": "req-A40" }
```

**功能门禁（AdminFeatureGateController，2 端点）**

> 直接操作 `FeatureGate` JPA 实体（绕过领域层，不发布事件）。

### GET /admin/feature-gates

列出全部功能门禁（4 tier × 7 featureKey）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A41",
  "data": [
    { "id": 1, "tier": "BASIC", "featureKey": "health_monitoring", "gateType": "LOCK", "limitValue": null, "retentionDays": null, "isEnabled": false },
    { "id": 9, "tier": "STANDARD", "featureKey": "advanced_analytics", "gateType": "FILTER", "limitValue": null, "retentionDays": 30, "isEnabled": true }
  ]
}
```

### PUT /admin/feature-gates/{id}

更新门禁配置（所有字段可选，仅传出的字段更新）。

```
Request:
{ "limitValue": 300, "isEnabled": true }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A42", "data": { "id": 2, "tier": "BASIC", "featureKey": "fence_management", "gateType": "LIMIT", "limitValue": 300, "retentionDays": null, "isEnabled": true } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "Feature gate not found: 999", "requestId": "req-A42" }
```

> `gateType`：`NONE`（直接放行）/ `LOCK`（看 isEnabled）/ `LIMIT`（currentUsage < limitValue）/ `FILTER`（按 retentionDays 过滤数据保留期）。

---

## 8. 瓦片管理（TileAdminController）— 7 端点（Phase 2c）

> **权限**: `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN', 'B2B_ADMIN')")` —— ⚠️ **双角色**（PLATFORM_ADMIN **或** B2B_ADMIN），与本文档其他 admin 端点的单角色 `ROLE_PLATFORM_ADMIN` 不同。
> **基路径**: `/api/v1/admin/tiles`。
> ⚠️ regions 端点按 `name` upsert（无则新建、有则全字段更新）；tasks 创建无去重（每次调用新建）；`TileGenerationTaskDto.createdAt` 恒为 null。

### GET /admin/tiles/regions

列出全部瓦片区域。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A43",
  "data": [ { "id": 11, "name": "changsha-z12", "minLon": 112.80, "minLat": 28.20, "maxLon": 112.90, "maxLat": 28.30, "minZoom": 11, "maxZoom": 15, "fileName": "changsha.mbtiles", "fileSize": 5242880, "md5": "a1b2c3d4...", "generatedAt": "2026-05-01T00:00:00Z", "status": "ready" } ]
}
```

### POST /admin/tiles/regions

新增/更新区域（upsert by name）。

```
Request:
{ "name": "changsha-z12", "minLon": 112.80, "minLat": 28.20, "maxLon": 112.90, "maxLat": 28.30, "minZoom": 11, "maxZoom": 15, "fileName": "changsha.mbtiles", "fileSize": 5242880, "md5": "a1b2c3d4...", "status": "ready" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A44", "data": { "id": 11, "name": "changsha-z12", "...": "..." } }
```

> `name` 必填（upsert 键）；`minZoom` 默认 11、`maxZoom` 默认 15；字段缺失会抛 NPE/ClassCast（500，未防御）。

### GET /admin/tiles/tasks

列出生成任务（可选 status 过滤）。无分页。

```
查询参数: status（可选，pending/running/done/failed）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A45",
  "data": [ { "id": 21, "regionId": 11, "regionName": "changsha-z12", "minLon": 112.80, "minLat": 28.20, "maxLon": 112.90, "maxLat": 28.30, "minZoom": 11, "maxZoom": 15, "status": "done", "triggeredBy": "system", "tileCount": 4400, "fileSizeMb": 5.0, "coverageRatio": 0.95, "customRegion": false, "errorMessage": null, "progress": "100%", "startedAt": "2026-05-01T00:00:00Z", "finishedAt": "2026-05-01T01:00:00Z", "createdAt": null } ]
}
```

> `createdAt` 恒为 null（DTO from() 未映射）。

### GET /admin/tiles/tasks/{id}

任务详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A46", "data": { "id": 21, "status": "done", "...": "..." } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "任务不存在: 21", "requestId": "req-A46" }
```

### POST /admin/tiles/tasks

创建生成任务（无去重，每次新建）。

```
Request:
{ "regionName": "changsha-z13", "minLon": 112.80, "minLat": 28.20, "maxLon": 112.90, "maxLat": 28.30, "minZoom": 11, "maxZoom": 15, "coverageRatio": 0.9, "isCustomRegion": false }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A47", "data": { "id": 22, "status": "pending", "...": "..." } }
```

### PUT /admin/tiles/tasks/{id}/status

更新任务状态（状态机驱动，含副作用）。

```
Request:
{ "status": "done", "tileCount": 4400, "fileSizeMb": 5.0, "progress": "100%" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A48", "data": { "id": 21, "status": "done", "...": "..." } }
```

> 副作用：`status=running` 自动设 `startedAt`；`status=done/failed` 自动设 `finishedAt`；**`status=done` 时推进该任务 regionId 下所有 pending 的 FarmTileTask 为 ready**（仅非 custom 任务）。status 值未做白名单校验（任意字符串可写，仅这 4 值有副作用）。

### GET /admin/tiles/farm-tasks

列出所有农场的瓦片状态。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A49",
  "data": [ { "farmId": 1, "regions": [ { "regionId": 11, "regionName": "changsha-z12", "status": "ready", "fileSize": 5242880, "fileName": "changsha.mbtiles", "md5": "a1b2c3d4..." } ], "coverageRatio": 0, "coverageWarning": false } ]
}
```

> `coverageRatio`/`coverageWarning` 恒为 0/false（本端点未计算）；仅返回 farm_tile_task 表中有记录的农场。

---

## 9. API 用量管理（AnalyticsAdminController）— 3 端点（Phase 2c）

> **基路径**: `/api/v1/admin/analytics`。⚠️ **权限**：本 Controller **无任何 Controller 级/方法级权限校验**（既无 `@PreAuthorize` 也无 `requirePlatformAdmin()`），与本文档其他 admin 端点风格不一致，疑似遗漏 —— 实际可达性取决于全局 SecurityConfig（/admin/** 是否被统一保护）。建议部署时确认。
> 日期参数均 `@DateTimeFormat(ISO.DATE)`（严格 `yyyy-MM-dd`）。

### GET /admin/analytics/tenants/{tenantId}/usage/overview

租户用量概览（跨租户，指定 tenantId + 时间区间）。

```
路径变量: tenantId；查询参数: from、to（ISO yyyy-MM-dd，必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A50", "data": { "totalCalls": 50000, "successCalls": 49800, "errorCalls": 200, "avgResponseMs": 130.0, "from": "2026-05-01", "to": "2026-05-31" } }
```

### GET /admin/analytics/tenants/{tenantId}/usage/trend

租户用量按日趋势。

```
路径变量: tenantId；查询参数: from、to（ISO yyyy-MM-dd，必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A51", "data": [ { "date": "2026-05-20", "totalCalls": 1800, "successCalls": 1790, "errorCalls": 10, "avgResponseMs": 128 } ] }
```

### POST /admin/analytics/aggregate

手动触发某日聚合（补跑）。

```
查询参数: date（ISO yyyy-MM-dd，必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A52", "data": "Aggregation completed for 2026-05-20" }
```

> ⚠️ 当日无日志则**不写任何记录**，但仍返回 `"Aggregation completed"`（响应字符串与是否真聚合无关）。聚合按 apiKeyId 分组生成/覆盖 api_usage_daily（含 totalCalls/successCalls/errorCalls/avgResponseMs/p95ResponseMs/topEndpoints top5）。定时任务每天 00:05 UTC 自动聚合前一天。

---

## 10. API Key 平台管理（PortalAdminController）— 5 端点（Phase 2c）

> **基路径**: `/api/v1/admin/portal/keys`。**权限**: 方法体内 `requirePlatformAdmin()`，仅认 `ROLE_PLATFORM_ADMIN`（⚠️ **不含 B2B_ADMIN**，与 TileAdminController 不同）。
> ⚠️ **实现注意**：`listAllKeys` 不传 `tenantId` 时恒返回空列表（"平台列出全部 key"未实现，仅支持按租户过滤，且伪分页）；`getStats` 硬编码空列表，统计恒为 0；`rate-limit`/`scopes` 无范围/格式校验，任意值可写入。

### GET /admin/portal/keys

列出（按租户过滤）API Key。

```
查询参数: page（默认 1）、pageSize（默认 20）、tenantId（可选 —— ⚠️ 不传则返回空列表）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-A53",
  "data": {
    "items": [ { "id": 301, "keyName": "默认 Key", "prefix": "sl_live_abcd", "tenantId": 7, "status": "ACTIVE", "scopes": "livestock:read,fence:read,alert:read", "requestsPerMinute": 60, "dailyQuota": 20000, "createdAt": "2026-05-01T00:00:00Z" } ],
    "page": 1, "pageSize": 20, "total": 1
  }
}
```

> ⚠️ 必须传 `tenantId` 才有数据；`page`/`pageSize` 仅回显未切片（total = items.size）。

### PUT /admin/portal/keys/{keyId}/rate-limit

调整限流配额。

```
Request:
{ "requestsPerMinute": 120, "dailyQuota": 50000 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A54", "data": { "id": 301, "requestsPerMinute": 120, "dailyQuota": 50000 } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "API Key not found", "requestId": "req-A54" }
```

> 字段均可选（未提供则保留原值）；⚠️ 无上下限校验，可为负数。

### PUT /admin/portal/keys/{keyId}/scopes

修改权限范围。

```
Request:
{ "scopes": "livestock:read,livestock:write,fence:read" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A55", "data": { "id": 301, "scopes": "livestock:read,livestock:write,fence:read" } }
```

> `scopes` 必填（null → `VALIDATION_ERROR`）；⚠️ 无格式/合法性校验，任意字符串接受。

### POST /admin/portal/keys/{keyId}/approve

审批 PENDING Key。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A56", "data": { "id": 301, "status": "ACTIVE" } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Key 状态不是 PENDING，无法审批", "requestId": "req-A56" }
```

> 仅 `status == "PENDING"` 可审批 → 写回 `ACTIVE`；key 不存在 → 404。

### GET /admin/portal/keys/stats

Key 状态统计。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A57", "data": { "total": 0, "active": 0, "revoked": 0, "pending": 0 } }
```

> ⚠️ 实现中 `all = List.of()` 硬编码空列表，**统计恒为 0**（端点无实际数据来源）。

---

## 设计要点

1. **无 Ranch/IoT Admin 端点** — admin 访问任意农场的牲畜/围栏/告警/设备，直接复用 App API 的 `/api/v1/farms/{farmId}/...` 端点，通过 platform_admin 角色在 Farm Scope 校验中放行跨租户访问
2. **跨租户筛选** — 所有列表接口支持 `tenantId` 筛选参数
3. **status 动作用 PUT** — 状态变更是幂等操作，使用 PUT
4. **审计日志** — Phase 1 先做查询接口，写入由 Application Service 内部通过领域事件自动完成（AlertStatusChanged、DeviceActivated 等）
5. **API Key 安全** — 完整 Key 明文仅在创建时返回一次，之后仅返回 keyId 和 prefix。禁止通过任何查询接口暴露完整 Key
