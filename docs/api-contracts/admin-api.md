# Admin API 端点（`/api/v1/admin/`）

> **端点总数**: 123（Phase 1 + Phase 2a Commerce + Phase 2c + GPS 质量检查 + NIX-79 遥测导入 + 仿真控制台 + NIX-184 部署授权与试点授权；与实际对齐）
>
> ⚠️ **As-Built 校准（2026-06-26）**: 当前 Admin API 实际 **110 个端点**，本文档已**全量详列 110 个**：Phase 1 全部（含 TenantAdmin 补全的 `PUT /admin/tenants/{id}` 与 `GET /admin/tenants/{id}/farms`）+ Phase 2a Commerce 21 + Phase 2c（瓦片 7 / API 用量 3 / Portal 5）+ GPS 质量检查 51。端点真源为代码，详见 [后端实现现状 §7 API 设计](../superpowers/specs/2026-05-06-mvp-backend-design.md)。2026-07-29 NIX-79 新增遥测数据导入 2 端点（§12）；2026-08-17 新增仿真控制台 5 端点（§13），总数 117。2026-09-03 NIX-184 新增部署授权与试点授权 5 端点（§14）。
> **认证**: JWT Bearer Token（本文件多数端点要求 platform_admin；仿真控制台允许 platform_admin / b2b_admin，B2B 管理员限定本租户）
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
      { "id": 12, "keyName": "Demo Key", "prefix": "sk_live_a1b2c3d4e5f", "role": "admin", "scopes": "livestock:read,fence:read,alert:read,device:read,gps:read", "status": "ACTIVE", "tenantId": 7, "expiresAt": "", "lastUsedAt": "2026-05-07T10:00:00Z", "createdAt": "2026-03-01T08:00:00Z" }
    ],
    "page": 1, "pageSize": 20, "total": 15
  }
}
```

### POST /admin/api-keys

创建 Key。`scopes` 接受字符串数组或逗号分隔字符串，逐个校验（未知 scope 返回 400 `VALIDATION_ERROR`）；限流默认 60 次/分钟、20000 次/日。`role` 可选（默认 `admin`）。

```
Request:
{ "tenantId": 7, "name": "新客户 Key", "scopes": ["livestock:read", "fence:read", "alert:read"] }

Response 201:
{
  "code": "OK", "message": "success", "requestId": "req-A19",
  "data": { "id": 15, "keyName": "新客户 Key", "prefix": "sk_live_c3d4e5f67", "role": "admin", "rawKey": "sk_live_c3d4e5f6…（64 位十六进制）", "scopes": "livestock:read,fence:read,alert:read" }
}
```

注意：`rawKey` 完整明文仅在创建响应中返回一次，之后不可再次获取。删除 Key 前须先 `PUT /admin/api-keys/{keyId}/status` 置为 `disabled`（对 ACTIVE Key 直接 DELETE 返回 `STATE_CONFLICT`）。

### PUT /admin/api-keys/{keyId}/status

启用/禁用 Key。幂等。`status` 仅接受 `active` / `disabled`。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-A20", "data": { "keyId": "key_abc123", "status": "disabled" } }
```

### DELETE /admin/api-keys/{keyId}

删除 Key（不可恢复）。仅非 ACTIVE 状态可删，否则 `STATE_CONFLICT`。

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

## 11. GPS 质量检查（GpsQualityAdminController）— 51 端点

> **基路径**: `/api/v1/admin/gps-quality`。**权限**: `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`。
> 测试模型（NIX-21 重构）：以 `GpsQualityTest` 为顶层资源，无 session 间接层。支持四种测试类型：`STATIC`（单 RTK 点）、`DYNAMIC`（路线）、`TRAJECTORY`（导入 RTK 轨迹）、`LINE`（标准轨迹线）。
> ⚠️ platform_admin 无租户上下文，GPS 质量检查回退到 `FALLBACK_TENANT_ID = 1L`（demo 租户）；生产环境需在请求体中指定租户（代码标注 TODO）。
> 状态值：`READY`（已创建，可生成报告）、`DEVICE_PENDING`（设备未在 blade 平台注册）、`FAILED`（注册或数据拉取失败）。报告仅 `READY` 状态可生成（`STATE_CONFLICT`）。

**RTK 参考点（4 端点）**

### GET /gps-quality/rtk-points

列出全部 RTK 参考点，可按 `locationName` 过滤。

```
查询参数: locationName（可选）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G01",
  "data": [ { "id": 1, "locationName": "牛舍A", "pointLabel": "P1", "latitude": 28.2400000, "longitude": 112.8500000, "dmsLat": null, "dmsLng": null, "createdAt": "2026-07-01T00:00:00Z" } ]
}
```

### POST /gps-quality/rtk-points

创建 RTK 参考点（decimal 经纬度或 DMS 字符串二选一）。

```
Request:
{ "locationName": "牛舍B", "pointLabel": "P2", "latitude": 28.2500000, "longitude": 112.8600000 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G02", "data": { "id": 2, "locationName": "牛舍B", "pointLabel": "P2", "latitude": 28.2500000, "longitude": 112.8600000 } }
```

### PUT /gps-quality/rtk-points/{id}

更新 RTK 参考点（全字段覆盖）。

```
Request:
{ "locationName": "牛舍B（更新）", "pointLabel": "P2-updated", "latitude": 28.2510000, "longitude": 112.8610000 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G03", "data": { "id": 2, "...": "..." } }
```

### DELETE /gps-quality/rtk-points/{id}

删除 RTK 参考点。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G04", "data": null }
```

**设备（2 端点）**

### GET /gps-quality/devices

列出全部追踪器设备（`device_type = TRACKER`）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G05", "data": [ { "id": 10, "deviceCode": "DEV-001", "platformBound": false } ] }
```

### GET /gps-quality/devices/{deviceId}/gps-logs

查询设备 GPS 日志（轨迹可视化用），支持时间范围 + 采样。

```
路径变量: deviceId
查询参数: startTime / endTime（ISO-8601，可选）、sampleSize（可选，> 0 时按均匀采样返回）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G06", "data": { "items": [ { "...GpsLogDto": "..." } ], "total": 500 } }
```

> 三种模式：有 sampleSize → 均匀采样；有 startTime+endTime 无 sampleSize → 全量；无参数 → 设备全部日志。

**测试（3 端点）**

### GET /gps-quality/tests

按 `deviceId` 列出测试。⚠️ 不传 `deviceId` 返回空列表。

```
查询参数: deviceId（可选）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G07",
  "data": [ { "id": 101, "deviceCode": "DEV-001", "deviceId": 10, "testType": "STATIC", "rtkPointId": 1, "routeId": null, "startedAt": "2026-07-16T16:00:00Z", "endedAt": null, "status": "READY", "errorMessage": null, "note": null, "batchImportId": null, "createdAt": "2026-07-16T16:05:00Z" } ] }
```

### POST /gps-quality/tests

创建测试。通过 `eui` 自动 find-or-create 设备（eui 为主路径）；`testType` 默认 `STATIC`。

```
Request:
{ "eui": "a84041XXXXXX", "deviceCode": "DEV-001", "testType": "STATIC", "rtkPointId": 1, "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T16:10:00Z" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G08", "data": { "id": 102, "status": "READY", "...": "..." } }
```

> `startedAt` / `endedAt` 支持 offset-aware（`...Z`）和 naive local（`...000`）两种格式；naive 值按 UTC 面值解释（lesson #17）。

### DELETE /gps-quality/tests/{id}

删除测试。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G09", "data": null }
```

**检查列表（3 端点）**

### GET /gps-quality/checks

分页列出检查记录，支持 status / eui / deviceId 过滤。

```
查询参数: status（可选）、eui（可选）、deviceId（可选）、page（默认 0）、size（默认 20）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G10",
  "data": { "items": [ { "id": 101, "...GpsQualityTestDto": "..." } ], "page": 0, "pageSize": 20, "total": 5 }
}
```

### POST /gps-quality/checks

创建检查（同 `POST /tests`，但 `eui` 必填）。

```
Request:
{ "eui": "a84041XXXXXX", "testType": "DYNAMIC", "routeId": 1, "startedAt": "2026-07-16T16:00:00Z" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G11", "data": { "id": 103, "status": "READY", "...": "..." } }

Error 422:
{ "code": "VALIDATION_ERROR", "message": "eui is required", "requestId": "req-G11" }
```

### DELETE /gps-quality/checks/by-device/{deviceId}

删除指定设备的全部检查记录。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G12", "data": { "deleted": 5 } }
```

**批量导入（6 端点）**

### POST /gps-quality/batch/parse

解析 Excel 预检（不持久化）：逐行校验并返回 per-row `preStatus`（OK/WARN/ERROR）。

```
Content-Type: multipart/form-data
表单字段: file

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G13",
  "data": { "totalRows": 10, "okCount": 8, "warnCount": 1, "errorCount": 1,
    "rows": [ { "rowIndex": 1, "eui": "a84041XXXXXX", "deviceCode": "DEV-001", "testType": "STATIC", "refName": "牛舍A", "rtkPointId": 1, "routeId": null, "startedAt": "2026-07-16T16:00:00Z", "endedAt": null, "preStatus": "OK", "message": null } ] }
}
```

### POST /gps-quality/batch/import

导入 Excel：逐行创建测试 + 设备注册，返回 batchId。

```
Content-Type: multipart/form-data
表单字段: file、excludeRows（可选，逗号分隔行号）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G14",
  "data": { "batchId": 201, "totalRows": 10, "totalSuccess": 7, "totalPending": 2, "totalFailed": 1,
    "rows": [ { "rowIndex": 1, "status": "SUCCESS", "eui": "a84041XXXXXX", "deviceCode": "DEV-001", "deviceId": 10, "checkId": 101, "message": null } ] }
}
```

> `status`：`SUCCESS` / `DEVICE_PENDING` / `FAILED` / `SKIPPED`。

### GET /gps-quality/batch/template

下载 Excel 模板（`Content-Disposition: attachment`，`.xlsx`）。

### POST /gps-quality/batch/retry-registration

重试 `DEVICE_PENDING` 检查的设备注册（可指定 `checkIds`，不传则重试全部 PENDING）。

```
Request（可选）:
{ "checkIds": [101, 102] }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G16", "data": [ { "rowIndex": 0, "status": "SUCCESS", "...RowResult": "..." } ] }
```

### POST /gps-quality/batch/retry-row

重试单行（手动指定参数创建测试）。

```
Request:
{ "eui": "a84041XXXXXX", "testType": "STATIC", "rtkPointId": 1, "startedAt": "2026-07-16T16:00:00Z" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G17", "data": { "rowIndex": 0, "status": "READY", "eui": "a84041XXXXXX", "deviceCode": null, "deviceId": 10, "checkId": 104, "message": null } }
```

### DELETE /gps-quality/batch/{batchId}

删除整个批次（级联删除该批次下全部检查记录）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G18", "data": null }
```

**报告（2 端点）**

### GET /gps-quality/tests/{id}/report

生成 STATIC 测试质量报告（含统计 + 散点图数据）。仅 `READY` 状态可调用。

```
路径变量: id
查询参数: excludeSuspect（默认 false，排除 stepNumber > 0 的可疑点）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G19",
  "data": {
    "testId": 101, "rtkPointId": 1, "locationName": "牛舍A", "label": "P1",
    "rtkLatitude": 28.2400000, "rtkLongitude": 112.8500000,
    "deviceId": 10, "deviceCode": "DEV-001", "deviceEui": "a84041XXXXXX",
    "excludeSuspect": false, "grade": "USABLE",
    "stats": { "totalPoints": 120, "suspectPoints": 5, "effectivePoints": 115, "meanError": 8.5, "p50": 6.2, "p95": 15.3, "p99": 22.1, "maxError": 28.4, "jitterDiameter": 45.2, "outlierCount": 3, "grade": "USABLE", "within15m": 0.85, "within25m": 0.95, "within40m": 0.99 },
    "scatter": [ { "latitude": 28.24001, "longitude": 112.85002, "error": 2.3, "recordedAt": "2026-07-16T16:01:00Z", "suspect": false } ]
  }
}

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot generate report for test 101: status is DEVICE_PENDING", "requestId": "req-G19" }
```

### GET /gps-quality/tests/{id}/dynamic-report

生成 DYNAMIC 测试质量报告（路线驱动匹配 + 误差分布）。可选 `threshold`（匹配阈值，米）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G20",
  "data": {
    "testId": 103, "deviceId": 10, "deviceCode": "DEV-001", "deviceEui": "a84041XXXXXX",
    "routeId": 1, "routeName": "测试路线A", "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T17:00:00Z",
    "threshold": 30.0, "grade": "EXCELLENT",
    "stats": { "routePointCount": 5, "matchedCount": 5, "missedCount": 0, "ambiguousCount": 0, "transitCount": 200, "inOrder": true, "coverage": 100.0, "meanError": 3.2, "p50": 2.8, "p95": 5.1, "maxError": 7.3 },
    "perPoint": [ { "rtkPointId": 1, "locationName": "牛舍A", "label": "P1", "sequenceNo": 1, "passed": true, "ambiguous": false, "error": 3.1, "matchedAt": "2026-07-16T16:02:00Z" } ],
    "passes": [ { "sequenceNo": 1, "latitude": 28.24001, "longitude": 112.85002, "rtkLatitude": 28.24000, "rtkLongitude": 112.85000, "error": 3.1, "ambiguous": false, "recordedAt": "2026-07-16T16:02:00Z" } ],
    "staticComparison": { "staticTestId": 101, "staticP95": 15.3, "staticGrade": "USABLE", "deltaP95": -10.2 }
  }
}
```

**RTK 轨迹导入（NIX-22，8 端点）**

### GET /gps-quality/trajectory/template

下载 CSV 轨迹导入模板（`Content-Disposition: attachment`，`.csv`）。

### POST /gps-quality/trajectory/parse

解析 + 配对预览（不持久化）：逐行匹配设备坐标。

```
Content-Type: multipart/form-data
表单字段: file、toleranceSec（默认 60，范围 1..3600）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G22",
  "data": { "totalRows": 100, "validRows": 95, "invalidRows": 5, "deviceCount": 2, "filePaired": 50, "logPaired": 40, "unpaired": 5,
    "rows": [ { "rowNo": 1, "deviceEui": "a84041XXXXXX", "collectedAt": "2026-07-16T16:00:00Z", "rtkLatitude": 28.2400000, "rtkLongitude": 112.8500000, "deviceLatitude": 28.24001, "deviceLongitude": 112.85002, "matchMode": "FILE", "error": null, "matchedRecordedAt": null, "timeDiffSec": null } ],
    "autoRegisteredEuis": [] }
}
```

> `matchMode`：`FILE`（文件含设备坐标）/ `GPS_LOG`（从 gps_logs 配对）/ `UNPAIRED` / `INVALID`。

### POST /gps-quality/trajectory/import

导入轨迹文件：每设备创建一条 `TRAJECTORY` 测试 + 配对快照。

```
Content-Type: multipart/form-data
表单字段: file、toleranceSec（默认 60，范围 1..3600）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G23",
  "data": { "createdCount": 2, "skippedCount": 0, "autoRegisteredCount": 1,
    "devices": [ { "deviceEui": "a84041XXXXXX", "testId": 201, "status": "CREATED", "totalPoints": 50, "filePaired": 30, "logPaired": 15, "unpaired": 5 } ] }
}
```

> `status`：`CREATED` / `SKIPPED_DUPLICATE`。

### POST /gps-quality/trajectory/register-device

手动注册设备（find-or-create by EUI），返回平台绑定状态。

```
Request:
{ "eui": "a84041XXXXXX", "deviceCode": "DEV-001" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G24", "data": { "id": 10, "deviceCode": "DEV-001", "platformBound": true } }

Error 422:
{ "code": "VALIDATION_ERROR", "message": "eui is required", "requestId": "req-G24" }
```

### GET /gps-quality/tests/{id}/trajectory-report

生成 TRAJECTORY 测试报告（从持久化配对快照读取，不重新查询 gps_logs）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G25",
  "data": {
    "testId": 201, "deviceCode": "DEV-001", "deviceEui": "a84041XXXXXX",
    "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T17:00:00Z",
    "toleranceSec": 60, "grade": "USABLE",
    "totalPoints": 50, "filePaired": 30, "logPaired": 15, "unpaired": 5, "pairRate": 0.9,
    "meanError": 6.2, "p50": 4.8, "p95": 12.1, "maxError": 20.5,
    "points": [ { "sequenceNo": 1, "collectedAt": "2026-07-16T16:00:00Z", "rtkLatitude": 28.2400000, "rtkLongitude": 112.8500000, "deviceLatitude": 28.24002, "deviceLongitude": 112.85001, "error": 2.5, "matchSource": "FILE", "timeDiffSec": null, "nearestGpsLogSec": null } ],
    "staticComparison": { "staticTestId": 101, "staticP95": 15.3, "staticGrade": "USABLE", "deltaP95": -3.2 }
  }
}
```

> `matchSource`：`FILE` / `GPS_LOG` / `UNPAIRED`。

### POST /gps-quality/tests/{id}/re-pair

重新配对 TRAJECTORY 测试：重新查询 gps_logs，更新配对快照，返回刷新后的报告。

```
路径变量: id
查询参数: toleranceSec（必填，范围 1..3600）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G26", "data": { "testId": 201, "...": "..." } }
```

### GET /gps-quality/comparison/trajectory

跨设备 TRAJECTORY 对比：每设备最新 READY TRAJECTORY 测试。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G27",
  "data": { "devices": [ { "testId": 201, "deviceId": 10, "deviceCode": "DEV-001", "totalPoints": 50, "paired": 45, "pairRate": 0.9, "meanError": 6.2, "p50": 4.8, "p95": 12.1, "grade": "USABLE", "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T17:00:00Z" } ] }
}
```

### GET /gps-quality/tests/{id}/trajectory

获取 TRAJECTORY 测试的散点图数据（复用 report 的 scatter 字段，单独端点供前端按需加载）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G28", "data": [ { "latitude": 28.24001, "longitude": 112.85002, "error": 2.3, "recordedAt": "2026-07-16T16:01:00Z", "suspect": false } ] }
```

**对比（2 端点）**

### GET /gps-quality/comparison

STATIC 多设备对比（同一 RTK 参考点下所有测试）。不传 `rtkPointId` 返回 `null`。

```
查询参数: rtkPointId（可选）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G29",
  "data": {
    "rtkPointId": 1, "locationName": "牛舍A", "label": "P1",
    "devices": [ { "testId": 101, "deviceId": 10, "deviceCode": "DEV-001", "grade": "USABLE", "p95": 15.3, "meanError": 8.5, "effectivePoints": 115, "within15m": 0.85, "within25m": 0.95, "within40m": 0.99, "locationName": "牛舍A", "pointLabel": "P1" } ]
  }
}
```

### GET /gps-quality/comparison/dynamic

DYNAMIC 多设备对比（同一路线下每设备最新 READY 动态测试）。

```
查询参数: routeId（必填）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G30",
  "data": {
    "routeId": 1, "routeName": "测试路线A",
    "devices": [ { "deviceId": 10, "deviceCode": "DEV-001", "checkId": 103, "coverage": 100.0, "matchedCount": 5, "missedCount": 0, "ambiguousCount": 0, "inOrder": true, "meanError": 3.2, "p50": 2.8, "p95": 5.1, "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T17:00:00Z" } ]
  }
}
```

**动态测试路线（6 端点）**

### GET /gps-quality/dynamic-routes

列出全部动态测试路线。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G31", "data": [ { "id": 1, "name": "测试路线A", "description": "南北向 500m", "createdAt": "2026-07-01T00:00:00Z", "updatedAt": "2026-07-01T00:00:00Z" } ] }
```

### POST /gps-quality/dynamic-routes

创建路线。

```
Request:
{ "name": "测试路线B", "description": "环形 1km" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G32", "data": { "id": 2, "name": "测试路线B", "...": "..." } }
```

### PUT /gps-quality/dynamic-routes/{id}

更新路线名称/描述。

```
Request:
{ "name": "测试路线B（更新）", "description": "环形 2km" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G33", "data": { "id": 2, "...": "..." } }
```

### DELETE /gps-quality/dynamic-routes/{id}

删除路线。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G34", "data": null }
```

### GET /gps-quality/dynamic-routes/{id}/points

列出路线下的有序 RTK 参考点序列。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G35", "data": [ { "id": 11, "routeId": 1, "rtkPointId": 1, "sequenceNo": 1, "...": "..." } ] }
```

### PUT /gps-quality/dynamic-routes/{id}/points

替换路线的 RTK 点序列（全量覆盖）。

```
Request:
[ { "rtkPointId": 1, "sequenceNo": 1 }, { "rtkPointId": 2, "sequenceNo": 2 } ]

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G36", "data": null }
```

**标准轨迹线 NIX-68（7 端点）**

### GET /gps-quality/track-lines

列出全部标准轨迹线候选（tenant 过滤）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G37",
  "data": [ { "id": 301, "name": "主干道线A", "status": "SELECTED", "pointCount": 120, "lengthM": 1500.0, "startLng": 112.850, "startLat": 28.240, "sourceFile": "track-a.xlsx", "createdAt": "2026-07-20T00:00:00Z" } ] }
```

> `status`：`CANDIDATE` / `SELECTED`（非排他标记，可多条 SELECTED）。

### POST /gps-quality/track-lines/parse

解析 XLSX 预览（不持久化）：去重 + 长度计算。

```
Content-Type: multipart/form-data
表单字段: file

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G38",
  "data": { "defaultName": "主干道线A", "rawPointCount": 125, "pointCount": 120, "removedDuplicates": 5, "invalidPoints": 0, "lengthMeters": 1500.0, "startLng": 112.850, "startLat": 28.240, "endLng": 112.860, "endLat": 28.250, "metadataWarning": null,
    "previewPoints": [ { "sequenceNo": 1, "lng": 112.850, "lat": 28.240 } ] }
}
```

> 仅信任坐标列，文件元数据（时间/长度列）不信任（spec D6）。

### POST /gps-quality/track-lines/import

导入 XLSX：创建一条 `CANDIDATE` 候选（append-only，重复导入新建记录，spec D3）。

```
Content-Type: multipart/form-data
表单字段: file、name（可选，默认从文件元数据推断）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G39", "data": { "id": 302, "name": "主干道线B", "status": "CANDIDATE", "...": "..." } }
```

### POST /gps-quality/track-lines/{id}/select

标记为 `SELECTED`。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G40", "data": { "id": 301, "status": "SELECTED", "...": "..." } }
```

### POST /gps-quality/track-lines/{id}/unselect

取消 `SELECTED` 标记（回退为 `CANDIDATE`）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G41", "data": { "id": 301, "status": "CANDIDATE", "...": "..." } }
```

### DELETE /gps-quality/track-lines/{id}

删除轨迹线候选。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G42", "data": null }
```

### GET /gps-quality/track-lines/{id}/points

列出轨迹线的有序坐标点。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G43", "data": [ { "sequenceNo": 1, "lng": 112.850, "lat": 28.240 } ] }
```

**LINE 检查 NIX-68（3 端点）**

### GET /gps-quality/line-checks/devices

列出在指定时间窗口内有 gps_logs 数据的设备。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G44", "data": [ { "deviceCode": "DEV-001", "deviceId": 10, "pointCount": 500, "firstRecordedAt": "2026-07-16T16:00:00Z", "lastRecordedAt": "2026-07-16T17:00:00Z" } ] }
```

### POST /gps-quality/line-checks

为每设备创建一条 READY LINE 测试（同步完成空间匹配 + 结果快照，spec D4）。

```
Request:
{ "trackLineId": 301, "deviceCodes": ["DEV-001", "DEV-002"] }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G45", "data": { "devices": [ { "testId": 401, "deviceCode": "DEV-001", "sampleCount": 120, "grade": "EXCELLENT" } ] } }

Error 422:
{ "code": "VALIDATION_ERROR", "message": "trackLineId is required", "requestId": "req-G45" }
```

### POST /gps-quality/line-checks/refresh

刷新某标准轨迹线的全部 LINE 测试（删除旧测试 + 快照，从所有有 gps_logs 的设备重新创建）。

```
查询参数: trackLineId（必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G46", "data": { "devices": [ { "testId": 411, "deviceCode": "DEV-001", "sampleCount": 120, "grade": "EXCELLENT" } ] } }
```

**LINE 报告 NIX-68（5 端点）**

### GET /gps-quality/tests/{id}/line-report

LINE 测试质量报告（统计摘要，读自结果快照）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G47",
  "data": {
    "testId": 401, "deviceCode": "DEV-001", "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T17:00:00Z",
    "trackLineId": 301, "trackLineName": "主干道线A", "grade": "EXCELLENT",
    "sampleCount": 120, "tripCount": 3, "meanDeviation": 4.2, "p50": 3.1, "p95": 8.5, "maxDeviation": 15.2,
    "within15mPct": 95.0, "within25mPct": 99.0, "within40mPct": 100.0
  }
}
```

### GET /gps-quality/tests/{id}/line-report/track

LINE 测试的轨迹线坐标点快照（测试时捕获的 point-list）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G48", "data": [ { "sequenceNo": 1, "lng": 112.850, "lat": 28.240 } ] }
```

### GET /gps-quality/tests/{id}/line-report/deviations

LINE 测试的逐点偏差（按时间升序）。

```
查询参数: limit（可选，限制返回条数）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-G49", "data": [ { "sequenceNo": 1, "recordedAt": "2026-07-16T16:01:00Z", "lng": 112.850, "lat": 28.240, "deviationM": 2.3, "segmentNo": 1 } ] }
```

### GET /gps-quality/checks/summary

设备统一摘要：每类型最新 READY 测试（spec 7.5）。

```
查询参数: deviceCode（必填）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G50",
  "data": { "items": [
    { "checkType": "STATIC", "testId": 101, "endedAt": "2026-07-16T16:10:00Z", "grade": "USABLE", "keyMetric": "p95 15.3m" },
    { "checkType": "LINE", "testId": 401, "endedAt": "2026-07-16T17:00:00Z", "grade": "EXCELLENT", "keyMetric": "mean 4.2m · p95 8.5m" }
  ] }
}
```

> 无测试的类型不在列表中出现。

### GET /gps-quality/comparison/line

LINE 跨设备对比（统计表 + 标准轨迹线折线，spec 7.6）。

```
查询参数: trackLineId（必填）、deviceCode（可选，传入时返回该设备的轨迹点）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-G51",
  "data": {
    "trackLine": [ { "sequenceNo": 1, "lng": 112.850, "lat": 28.240 } ],
    "rows": [ { "testId": 401, "deviceCode": "DEV-001", "sampleCount": 120, "tripCount": 3, "mean": 4.2, "p50": 3.1, "p95": 8.5, "max": 15.2, "within15mPct": 95.0, "within25mPct": 99.0, "within40mPct": 100.0, "grade": "EXCELLENT", "startedAt": "2026-07-16T16:00:00Z", "endedAt": "2026-07-16T17:00:00Z" } ],
    "deviceTrack": [ { "sequenceNo": 1, "lng": 112.8501, "lat": 28.2401 } ]
  }
}
```

> `deviceTrack` 仅当传入 `deviceCode` 时非 null。

---

## 12. 遥测数据导入（TelemetryImportAdminController）— 2 端点（NIX-79）

> **基路径**: `/api/v1/admin/telemetry-import`。**权限**: `@PreAuthorize("hasRole('PLATFORM_ADMIN')")`。
> 用途：blade 平台故障丢失遥测数据时，手工导入平台导出的设备历史数据文件（xlsx，列：数据类型/帧计数器/数据(hex)/RSSI/SNR/创建时间）。
> 两段式：`parse` 解析预览（**零持久化**）→ `import` 落库（经 `TelemetryIngestionService.ingest()`，source=`MANUAL_IMPORT`）。
> tenant 解析同 GPS 质量检查：无租户上下文时回退 `FALLBACK_TENANT_ID = 1L`。
> 约束：文件名须以 16 位 DevEUI 开头；设备须已注册且 `ACTIVE`、`TRACKER` 类型，否则整文件报错；单文件 ≤ 5000 行；仅解码牛羊追踪器固件协议（`68 6B 74` 帧头 TLV），协议外帧跳过不计错误；时间列按 UTC 原值入库；幂等——(device_id, report_time) 已存在的行判重跳过。
> 隔离性：导入数据不触发设备告警、不推进平台同步游标、不改写设备运行时快照、GPS 点不参与围栏越界检测（不补发历史告警、不回写牲畜当前位置）。

### POST /telemetry-import/parse

解析预览：分类统计 + 设备匹配结果 + 逐行状态，不落库。

```
Request: multipart/form-data，字段 file（.xlsx）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-B01",
  "data": {
    "totalRows": 408, "uplinkRows": 396, "decodableRows": 390, "importableRows": 387,
    "gpsPointRows": 387, "duplicateRows": 3, "skippedRows": 18, "invalidRows": 0,
    "device": { "matched": true, "devEui": "0095690600028577", "deviceCode": "28577", "deviceType": "TRACKER", "livestockName": "HKT13", "farmName": "Demo 牧场", "error": null },
    "rows": [
      { "rowNo": 2, "frameCounter": "119", "recordTime": "2026-07-23T16:09:11Z", "battery": 99, "latitude": 28.246777, "longitude": 112.851138, "stepCount": 27, "status": "IMPORTABLE", "error": null },
      { "rowNo": 5, "frameCounter": "115", "recordTime": "2026-07-23T16:05:49Z", "battery": 99, "latitude": 28.245320, "longitude": 112.850498, "stepCount": 2, "status": "DUPLICATE", "error": null },
      { "rowNo": 7, "frameCounter": null, "recordTime": null, "battery": null, "latitude": null, "longitude": null, "stepCount": null, "status": "SKIPPED_DOWNLINK", "error": null }
    ]
  }
}

Error 400（文件名无 DevEUI 前缀）:
{ "code": "VALIDATION_ERROR", "message": "文件名须以 16 位设备 DevEUI 开头", "requestId": "req-B01" }
```

> `device.matched=false` 时 `error` 为原因 message key（`error.telemetryImport.deviceNotRegistered` / `deviceNotActive` / `unsupportedDeviceType`），整文件不可导入。
> `rows[].status`：`IMPORTABLE`（将导入）/ `DUPLICATE`（重复）/ `SKIPPED_DOWNLINK`（下行帧）/ `SKIPPED_UNSUPPORTED`（协议外帧）/ `INVALID`（行错误，`error` 为 message key，如 `error.telemetryImport.invalidTime`）。

### POST /telemetry-import/import

执行导入：同 parse 管线，IMPORTABLE 行按时间升序逐行入库；单行失败计数继续，不整体回滚。

```
Request: multipart/form-data，字段 file（.xlsx）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-B02",
  "data": { "telemetryCreated": 387, "gpsCreated": 387, "duplicateSkipped": 3, "skippedRows": 18, "invalidRows": 0, "failedRows": 0, "devEui": "0095690600028577", "deviceCode": "28577" }
}

Error 400（设备未注册）:
{ "code": "VALIDATION_ERROR", "message": "设备未注册: 0095690600028577", "requestId": "req-B02" }
```

---



## 13. 仿真控制台与行为数据集（DataGenConsoleController / DataGenBehaviorController）— 9 端点

> **基路径**: `/api/v1/admin/datagen`。**权限**: `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")`。
> `PLATFORM_ADMIN` 可访问任意 farm；`B2B_ADMIN` 仅可访问当前 tenant 下的 farm，跨 tenant 返回 `AUTH_FORBIDDEN`。
> 同路径下的既有全局端点（`/scenarios`、`/scenarios/{id}/start|stop`、`/labels`、`/evaluation`）仅允许 `PLATFORM_ADMIN`，不再向 owner / worker / B2B 管理员暴露全局 scenario 控制。
> 控制粒度为 farm + device assignment：启用时设备范围不能为空；历史 assignment 软删除保留，供 DATAGEN 数据清理归属使用。

### POST /admin/datagen/behavior/datasets

生成并持久化 Phase C 行为摘要数据集。仅生成五分钟 `PROTOCOL_SUMMARY`，不写入 IoT 遥测表；同一 canonical scenario definition 幂等返回既有 dataset。

```
Request:
{
  "scenarioId": "behavior-smoke",
  "seed": 1001,
  "generatorVersion": "behavior-generator-v1",
  "startAt": "2026-08-23T00:00:00Z",
  "endAt": "2026-08-24T00:00:00Z",
  "subjects": [
    { "tenantId": 1, "farmId": 1, "livestockId": 10, "deviceId": 5,
      "baselineRollDegrees": 8, "baselinePitchDegrees": -4, "capsuleMotilityBaseline": 3.2 }
  ],
  "initialWeights": [4, 3, 2, 1, 0.2],
  "realism": { "noiseStdDevG": 0.003, "sampleDropoutRate": 0.01, "missingWindowRate": 0.02, "eventRate": 0.01 }
}

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D06",
  "data": {
    "id": "0d5f6f97-7ff6-3c61-99f1-58209e83b221", "scenarioId": "behavior-smoke", "seed": 1001,
    "generatorVersion": "behavior-generator-v1", "dataSource": "DATAGEN", "status": "READY",
    "startAt": "2026-08-23T00:00:00Z", "endAt": "2026-08-24T00:00:00Z",
    "episodeCount": 18, "windowCount": 288, "labelCount": 1128,
    "splitCounts": { "TRAIN": 288 }, "dominantCounts": { "...": 0 }, "qualityCounts": { "FULL_0X40": 282, "UNKNOWN": 6 },
    "alreadyExists": false
  }
}
```

> 请求最多 50 个 subject、20,000 个窗口；时间边界必须按 5 分钟对齐且最长 31 天。`dataSource` 由 dataset 拥有，split 由 livestock/episode assignment 表治理。当前 `initialWeights` 顺序为 `LYING, RUMINATING, FEEDING, WALKING, OTHER`，transition matrix 首版使用默认 semi-Markov 矩阵。

### GET /admin/datagen/behavior/datasets/{id}

查看 dataset 状态、窗口/episode/label 数量和 split、dominant、input quality 分布。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-D07", "data": { "...": "同 POST 响应 data，alreadyExists=false" } }
```

### POST /admin/datagen/behavior/evaluations

评估指定 datasets。非 debug 请求拒绝混合 `data_source`；`datasetSplit` 可为 `TRAIN` / `VALIDATION` / `TEST` / `ALL`。C4/C5 未产出 predictions 前返回显式 `NO_PREDICTIONS`，不会用 ground truth 伪造模型指标。

```
Request:
{ "datasetIds": ["0d5f6f97-7ff6-3c61-99f1-58209e83b221"], "datasetSplit": "TEST", "allowMixedDebug": false }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D08",
  "data": {
    "state": "NO_PREDICTIONS", "reportType": "PIPELINE_ONLY", "debug": false,
    "missingPredictionWindows": 43,
    "datasetIds": ["0d5f6f97-7ff6-3c61-99f1-58209e83b221"],
    "dataSources": ["DATAGEN"], "generatorVersions": ["behavior-generator-v1"], "modelVersions": [],
    "sourceCounts": { "DATAGEN": 43 }, "inputQualityCounts": { "FULL_0X40": 43 },
    "splitCounts": { "TEST": 43 }, "livestockCounts": { "dataset-id:10": 43 },
    "dominantMetrics": { "...": 0 }, "facetMetrics": [], "boundaryMetrics": { "...": 0 }, "eventMetrics": { "...": 0 }
  }
}
```

> 完整报告包含 dominant confusion/top-2/macro/weighted F1、四个 facet 的 per-label metrics 与 Hamming loss、one-window transition boundary F1、事件合并/漏检/检测 latency。合成数据报告必须携带 `PIPELINE_ONLY`，不得解释为真实世界效果。`allowMixedDebug=true` 时 payload 会置 `debug=true`，仅用于诊断。

### POST /admin/datagen/behavior/datasets/{datasetId}/models/train

触发 ai-platform 在单个合成 `DATAGEN` dataset 上执行 C5 L2 预训练。Java 侧先完成 dataset/farm scope 校验；训练标签只来自 `behavior_window_labels`，不读取 `behavior_predictions`。

```
Request:
{
  "requestedCapability": "L2_SUPERVISED",
  "modelName": "behavior-l2",
  "modelVersion": "v1",
  "minimumSupport": 1,
  "randomSeed": 149
}

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D09",
  "data": {
    "datasetId": "765e8c53-4130-38a7-b011-9af9dfe7671c",
    "modelName": "behavior-l2", "modelVersion": "v1", "artifactHash": "64-hex",
    "manifest": {
      "featureVersion": "v1", "featureSchemaHash": "64-hex",
      "datasetDefinitionDigest": "64-hex", "generatorVersion": "behavior-generator-v1",
      "trainWindowCount": 210, "validationWindowCount": 72,
      "reportType": "PIPELINE_ONLY", "syntheticPretraining": true
    }
  }
}
```

> 仅支持 `L2_SUPERVISED`。模型 artifact 由 ai-platform 内部持久卷管理，manifest 必须绑定 feature schema、dataset definition、generator/model 版本与 artifact hash；同名同版本禁止覆盖。当前训练要求 dataset 同时包含 `TRAIN` 与 `VALIDATION` split，且每个主导类和 facet label 满足最低支持数。

### POST /admin/datagen/behavior/datasets/{datasetId}/analyze

对 dataset 内 `model_compatible=true` 窗口执行行为分析，并按 `(window_id, model_name, model_version)` 幂等写 `behavior_predictions`。

```
Request:
{ "requestedCapability": "L1_RULE" }

或 L2:
{ "requestedCapability": "L2_SUPERVISED", "modelName": "behavior-l2", "modelVersion": "v1" }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D10",
  "data": { "datasetId": "765e8c53-4130-38a7-b011-9af9dfe7671c", "capabilityLevel": "L1_RULE", "predictionCount": 12 }
}
```

> L1 只输出 `LYING` / `WALKING` / `OTHER` 粗粒度 dominant 及 posture/locomotion，不输出 rumination 或 feeding。L2 必须提供兼容模型版本。数据集跨 tenant/farm、存在 schema 不匹配、预测结果与请求窗口不一致或 ai-platform 失败时不会部分落库。

### GET /admin/datagen/farms

列出当前管理员可见的牧场仿真控制摘要。平台管理员返回全部未删除牧场，B2B 管理员仅返回本租户牧场。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D01",
  "data": {
    "items": [
      { "farmId": 1, "farmName": "Main Ranch", "tenantId": 1, "tenantName": "Demo Tenant", "enabled": true, "selectedDeviceCount": 16 }
    ],
    "total": 1
  }
}
```

### GET /admin/datagen/console

获取单个牧场的控制台快照。首次访问会确保默认 `NORMAL` scenario、farm control 存在，但不会把 farm 置为启用。

```
查询参数: farmId（必填）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D02",
  "data": {
    "farm": { "farmId": 1, "farmName": "Main Ranch", "tenantId": 1, "tenantName": "Demo Tenant", "enabled": true, "selectedDeviceCount": 16 },
    "enabled": true,
    "scenario": { "id": 1, "name": "默认持续合成", "type": "normal" },
    "rules": {
      "trackerIntervalSeconds": 300, "capsuleIntervalSeconds": 900,
      "fenceExcursionProbability": 0.02, "fenceExcursionMinMinutes": 10, "fenceExcursionMaxMinutes": 30,
      "healthEventProbability": 0.005, "feverDurationMinMinutes": 240, "feverDurationMaxMinutes": 480,
      "motilityDurationMinMinutes": 480, "motilityDurationMaxMinutes": 720
    },
    "devices": [
      {
        "deviceId": 5, "deviceCode": "TRK-001", "devEui": "001a0102ff000650", "deviceType": "TRACKER",
        "livestockId": 10, "livestockCode": "ST-10", "runtimeStatus": "ONLINE",
        "selected": true, "eligible": true, "ineligibleReason": null,
        "lastGeneratedAt": "2026-08-17T08:00:00Z"
      }
    ],
    "stats": {
      "statsTimeZone": "Asia/Shanghai", "selectedTotal": 16, "selectedTrackerCount": 8, "selectedCapsuleCount": 8,
      "todayTelemetryRows": 3284, "todayGpsRows": 1842, "todayHealthRows": 812,
      "lastGeneratedAt": "2026-08-17T08:00:00Z"
    },
    "operations": [
      { "id": 91, "action": "START", "operatorId": 3, "operatorRole": "B2B_ADMIN", "occurredAt": "2026-08-17T08:00:00Z", "summary": "datagenConsoleOperationStart" }
    ]
  }
}

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "牧场不存在: 1", "requestId": "req-D02" }
```

> `today*` 按 `Asia/Shanghai` 自然日计算。`devices[].ineligibleReason` 为后端 i18n message key（当前合法设备为未软删、ACTIVE、TRACKER/CAPSULE 且当前安装在同名 farm 的设备）。`operations[].summary` 是前端 i18n key。

### PUT /admin/datagen/control/{farmId}

保存 farm 启停状态并全量替换当前 active 设备范围。启用时至少选择一台设备；任一设备不合法则整个请求失败，不会部分保存。

```
Request:
{ "enabled": true, "deviceIds": [5, 6, 133, 134] }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-D03", "data": { "farmId": 1, "enabled": true, "selectedDeviceCount": 4 } }

Error 400:
{ "code": "VALIDATION_ERROR", "message": "启用仿真时必须指定至少一台设备", "requestId": "req-D03" }
```

> 启停和设备范围可在一次请求完成。重新启用会清理内存中的设备 due schedule，使下一轮合成按新范围及时生成；关闭仅停用 farm control，不停止全局默认 scenario。操作写入 farm-scoped audit log。

### PUT /admin/datagen/rules/{farmId}

按牧场保存仿真规则，不改变启停状态和设备范围。运行中保存会清理当前 active 设备 due schedule，下一批调度按新规则生成。

```
Request:
{
  "trackerIntervalSeconds": 300, "capsuleIntervalSeconds": 900,
  "fenceExcursionProbability": 0.02, "fenceExcursionMinMinutes": 10, "fenceExcursionMaxMinutes": 30,
  "healthEventProbability": 0.005, "feverDurationMinMinutes": 240, "feverDurationMaxMinutes": 480,
  "motilityDurationMinMinutes": 480, "motilityDurationMaxMinutes": 720
}

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-D03b", "data": { "...": "同 console.rules" } }

Error 400:
{ "code": "VALIDATION_ERROR", "message": "仿真规则配置无效", "requestId": "req-D03b" }
```

> 允许范围：TRACKER 60-3600 秒；CAPSULE 300-7200 秒；围栏外出概率 0-0.2、持续 5-120 分钟；健康异常概率 0-0.1；发热与消化动力下降持续均为 120-1440 分钟。所有持续范围必须 `min <= max`。健康异常触发后仍按现有逻辑 50/50 选择发热或消化动力下降。

### POST /admin/datagen/clear/preview

预估指定时间范围内可安全归属到该 farm 历史 device assignment 的 `source=DATAGEN` 数据量。该接口不修改数据。

```
Request:
{ "farmId": 1, "rangeType": "LAST_24_HOURS", "from": null, "to": null }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D04",
  "data": {
    "telemetryRows": 3284, "gpsRows": 1842, "temperatureRows": 612, "motilityRows": 96, "activityRows": 104,
    "estrusRows": 18, "anomalyRows": 0, "alertRows": 12,
    "unattributableHealthRows": 0, "unattributableAlertRows": 4,
    "limitationKey": "datagenConsoleCrossFarmLimit"
  }
}
```

> `rangeType`: `LAST_24_HOURS` / `LAST_7_DAYS` / `ALL` / `CUSTOM`。`CUSTOM` 必须提供 `from < to`；其它 range 忽略 `from` / `to`，按服务器当前时间计算。`limitationKey` 供 UI 展示跨 farm 历史归属限制。

### POST /admin/datagen/clear

停止仿真后清理 DATAGEN 数据。必须输入确认词 `"清空"`（中英文界面均相同）；事务内执行删除并写入 `CLEAR_DATA` 审计。

```
Request:
{ "farmId": 1, "rangeType": "LAST_24_HOURS", "from": null, "to": null, "confirmText": "清空" }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-D05",
  "data": { "telemetryRows": 3282, "gpsRows": 1840, "temperatureRows": 610, "motilityRows": 96, "activityRows": 104, "estrusRows": 18, "anomalyRows": 0, "alertRows": 12, "unattributableHealthRows": 0, "unattributableAlertRows": 4, "limitationKey": "datagenConsoleCrossFarmLimit" }
}

Error 409:
{ "code": "STATE_CONFLICT", "message": "请先停止仿真后再清理数据", "requestId": "req-D05" }
```

> 清理范围包含该 farm 历史 assignment 设备的 `device_telemetry_logs` / `gps_logs` / `temperature_logs` / `rumen_motility_logs` / `activity_logs`，以及该 farm 的 `estrus_scores` / `anomaly_scores` / `alerts` 中 `source=DATAGEN` 的行。真实来源、`UNKNOWN` 健康数据、历史 `RULE` alerts、health snapshot、设备 runtime snapshot、GPS 质量点、接触追踪和 ground truth label 均保留。
> `device_telemetry_logs` / `gps_logs` 没有 farm 字段；首版按设备历史 assignment 归属清理。设备跨 farm 迁移后，其 DATAGEN 行可能随任一历史归属 farm 的清理被删除，但不会影响非 DATAGEN 数据。

---

## 14. 部署授权与试点授权（DeploymentLicenseAdminController / CloudPilotLicenseController）— 5 端点（NIX-184）

> **基路径**: `/api/v1/admin/deployment-license`（地端部署授权 4 端点）+ `/api/v1/admin/tenants/{tenantId}/pilot-license`（云端试点授权 1 端点）。
> **权限**: 全部要求 `ROLE_PLATFORM_ADMIN`（手写 `requirePlatformAdmin()` 守卫，TenantAdminController 先例）。SecurityContext 无 Authentication → 401 `AUTH_INVALID_TOKEN`；已认证但非 platform_admin → 403 `AUTH_FORBIDDEN`（message key `license.pilot.platformAdminRequired`）。
> **模式互斥（HOSTED/ONPREM，配置键 `SMARTLIVESTOCK_LICENSE_MODE`）**:

| 端点 | HOSTED（厂商托管） | ONPREM（客户机房离线） |
|------|------------------|----------------------|
| POST /admin/tenants/{tenantId}/pilot-license | ✅ 需 `SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=true`；否则 403 | ❌ 403 `AUTH_FORBIDDEN`（`license.pilot.modeForbidden`） |
| GET /admin/deployment-license/mode | ✅ | ✅（唯一全模式端点，供前端功能探测） |
| GET /admin/deployment-license/enrollment | ❌ 403 `AUTH_FORBIDDEN`（`license.onpremOnly`） | ✅ |
| POST /admin/deployment-license | ❌ 403 `AUTH_FORBIDDEN`（`license.onpremOnly`） | ✅ |
| GET /admin/deployment-license/current | ❌ 403 `AUTH_FORBIDDEN`（`license.onpremOnly`） | ✅ |

> **ONPREM 联动行为**：订阅由导入授权驱动，commerce 自助订阅/人工订阅变更端点被 `LicenseModeGuard.requireSelfServiceAllowed()` 拒绝（403 `LICENSE_REQUIRED`，`license.selfServiceDisabled`）。授权拦截器（ONPREM）放行清单：`/api/v1/auth/**`、`/api/v1/me/**`、`/api/v1/admin/deployment-license/**`、`/api/v1/admin/tenants/**`、`/health`；其余业务 API 在 PENDING_ACTIVATION / SUSPENDED 下返回 403 `LICENSE_REQUIRED`。
> **ID 序列化**：响应 record 中的 `Long` 字段（tenantId 等）按 JSON 数字输出；pilot-license 端点在 Controller 内显式 `String.valueOf(tenantId)`，其 `tenantId` 为字符串。时间字段均为 ISO-8601 Instant（UTC）。

### POST /admin/tenants/{tenantId}/pilot-license

开通（或延长）租户 365 天云端试点：无订阅 → 创建 TRIAL（trialEndsAt = now + 365d）；活跃 TRIAL → 延长到 `max(currentTrialEndsAt, now + 365d)`（不缩短）；其他订阅状态 → 409。无请求体。授权/拒绝均写审计（PILOT_LICENSE_GRANT / PILOT_LICENSE_REJECTED）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-L01",
  "data": { "tenantId": "3", "status": "TRIAL", "trialEndsAt": "2027-09-03T08:00:00Z" }
}

Error 409:
{ "code": "STATE_CONFLICT", "message": "...", "requestId": "req-L01" }
```

| 错误码 | HTTP | 触发条件 |
|--------|------|---------|
| AUTH_INVALID_TOKEN | 401 | 未认证（无 Authentication） |
| AUTH_FORBIDDEN | 403 | 非 platform_admin；或 ONPREM 模式 / `SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=false`（`license.pilot.modeForbidden`） |
| STATE_CONFLICT | 409 | 订阅存在且不是活跃 TRIAL（FREE/ACTIVE/SUSPENDED/CANCELLED/EXPIRED/RENEWAL_FAILED 等，`license.pilot.stateConflict`，参数为当前状态） |

### GET /admin/deployment-license/mode

报告部署模式与试点授权可用性。全模式可用（前端启动探测）。

```
Response 200（ONPREM）:
{ "code": "OK", "message": "success", "requestId": "req-L02",
  "data": { "mode": "ONPREM", "pilotLicenseEnabled": false } }

Response 200（HOSTED 且试点开启）:
{ "code": "OK", "message": "success", "requestId": "req-L02",
  "data": { "mode": "HOSTED", "pilotLicenseEnabled": true } }
```

> `pilotLicenseEnabled` = `SMARTLIVESTOCK_PILOT_LICENSE_ENABLED=true` **且** mode == HOSTED。

| 错误码 | HTTP | 触发条件 |
|--------|------|---------|
| AUTH_INVALID_TOKEN | 401 | 未认证 |
| AUTH_FORBIDDEN | 403 | 非 platform_admin |

### GET /admin/deployment-license/enrollment?tenantId=

返回（或惰性创建）租户的安装登记：`installationId` 首次生成后保持稳定；`fingerprintHash` 每次从宿主机身份源实时读取（release 环境 = Linux `/etc/machine-id`），指纹变化会刷新登记。`installationId`/`fingerprintHash` 供 issuer 签发绑定授权。

```
查询参数: tenantId（必填，Long）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-L03",
  "data": {
    "tenantId": 7,
    "installationId": "0d5f6f97-7ff6-3c61-99f1-58209e83b221",
    "fingerprintHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "publicKeyId": "sl-license-2026q3",
    "supportedPublicKeyIds": ["sl-license-2026q3"],
    "generatedAt": "2026-09-03T08:00:00Z"
  }
}
```

| 错误码 | HTTP | 触发条件 |
|--------|------|---------|
| AUTH_INVALID_TOKEN / AUTH_FORBIDDEN | 401 / 403 | 未认证 / 非 platform_admin |
| AUTH_FORBIDDEN | 403 | HOSTED 模式调用（`license.onpremOnly`） |

### POST /admin/deployment-license?tenantId=

导入离线授权文件（multipart/form-data）。导入驱动租户订阅映射（§9 规则），因此 `confirm=true` 强制确认。校验管线：envelope 结构 → SHA-256 payload 摘要 → Ed25519 验签 → 绑定三元组（tenant + installation + 实时指纹）→ 时间窗 → 配额预检 → 订阅映射。**被拒绝的导入不改动订阅与运行时状态**，只写审计事件（payload 可验签时另写 REJECTED 记录）。成功导入后旧 CURRENT 记录标记 REPLACED，运行时置 VALID。

```
Content-Type: multipart/form-data
表单字段: file（.sllicense UTF-8 文本，≤ 512 KiB）、confirm（必须为 true）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-L04",
  "data": {
    "tenantId": 7, "licenseId": "5f0a1c2e-8b3d-4e5f-a6b7-c8d9e0f1a2b3",
    "licenseType": "ACTIVE", "tier": "PREMIUM", "effectiveTier": "PREMIUM",
    "expiresAt": "2027-09-03T00:00:00Z", "runtimeStatus": "VALID"
  }
}

Error 403:
{ "code": "LICENSE_BINDING_MISMATCH", "message": "...", "requestId": "req-L04" }
```

| 错误码 | HTTP | 触发条件 |
|--------|------|---------|
| VALIDATION_ERROR | 400 | `confirm` 缺失/false（`license.import.confirmRequired`）；`file` 缺失/为空（`license.import.fileRequired`）；文件 > 512 KiB（`license.import.fileTooLarge`）；文件不可读（`license.import.fileUnreadable`）；未登记先导入（`license.import.notEnrolled`） |
| LICENSE_INVALID | 403 | envelope JSON 结构非法 / keyId 不在公钥注册表 / payloadSha256 不匹配 / Ed25519 验签失败（`license.invalid`） |
| LICENSE_EXPIRED | 403 | 授权 expiresAt 早于当前时间（`license.import.expired`） |
| LICENSE_BINDING_MISMATCH | 403 | tenantId / installationId / fingerprintHash 任一与预期绑定不符（`license.bindingMismatch`） |
| LICENSE_QUOTA_EXCEEDED | 403 | 牲畜/围栏/牧工/设备任一 featureKey 现用量超 payload 配额（`license.import.quotaExceeded`） |
| STATE_CONFLICT | 409 | TRIAL 类型授权无法映射当前订阅（订阅已降级 FREE 或非活跃 TRIAL，`license.import.trialDowngradeRejected`；须改用 ACTIVE 类型续费授权） |

> 订阅映射：TRIAL 授权仅允许「无订阅 / 活跃 TRIAL」；ACTIVE 授权允许从 TRIAL / FREE / ACTIVE 映射到 ACTIVE（SUSPENDED 等由 commerce 领域守卫拒绝）。

### GET /admin/deployment-license/current?tenantId=

租户授权全景：当前授权记录、运行时状态、订阅映射、防篡改锚点（单调时间 `maxObservedAt`）与最近一次校验结果。

```
查询参数: tenantId（必填，Long）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-L05",
  "data": {
    "tenantId": 7,
    "installationId": "0d5f6f97-7ff6-3c61-99f1-58209e83b221",
    "fingerprintHash": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
    "runtimeStatus": "VALID",
    "licenseId": "5f0a1c2e-8b3d-4e5f-a6b7-c8d9e0f1a2b3",
    "licenseType": "ACTIVE", "tier": "PREMIUM", "effectiveTier": "PREMIUM",
    "issuedAt": "2026-09-03T00:00:00Z", "expiresAt": "2027-09-03T00:00:00Z",
    "acceptedAt": "2026-09-03T08:00:00Z",
    "lastValidatedAt": "2026-09-03T08:05:00Z",
    "lastResult": "VALID", "lastErrorCode": null,
    "maxObservedAt": "2026-09-03T08:05:00Z",
    "protectionReason": null,
    "subscriptionStatus": "ACTIVE", "subscriptionTrialEndsAt": null
  }
}
```

> 未导入授权时 `runtimeStatus` 为 `PENDING_ACTIVATION`，`licenseId`/`licenseType`/`tier` 等授权字段为 null，`installationId`/`fingerprintHash` 在已登记后仍有值。

| 错误码 | HTTP | 触发条件 |
|--------|------|---------|
| AUTH_INVALID_TOKEN / AUTH_FORBIDDEN | 401 / 403 | 未认证 / 非 platform_admin |
| AUTH_FORBIDDEN | 403 | HOSTED 模式调用（`license.onpremOnly`） |

### runtime 状态机简表（ONPREM，设计 §9）

| runtimeStatus | 含义 | 业务 API | 订阅映射 |
|---------------|------|---------|---------|
| PENDING_ACTIVATION | 未导入可用授权 | 阻断（403 `LICENSE_REQUIRED`，`license.pendingActivation`）；登录/授权管理可达 | 未由授权驱动 |
| VALID | 当前授权通过签名/绑定/时间全部校验 | 放行 | TRIAL 授权 → TRIAL（trialEndsAt = expiresAt）；ACTIVE 授权 → ACTIVE / payload tier |
| EXPIRED | 超过 expiresAt（调度器降级，非 SUSPENDED） | 放行（能力受 FeatureGate 限制） | 降级 FREE/BASIC（ACTIVE/TRIAL/RENEWAL_FAILED → FREE，FREE 幂等）；CURRENT 记录与授权原文保留，可被续费授权 REPLACED；数据不删除 |
| SUSPENDED | 保护性冻结：时间回拨超容差（`LICENSE_TIME_ROLLBACK`）/ 签名或绑定失效（`PROTECTION_LICENSE_INVALID` / `PROTECTION_BINDING_MISMATCH`） | 仅登录与授权管理可达，其余全部 403 `LICENSE_REQUIRED`（含 Open API） | 订阅为 ACTIVE 时挂起为 SUSPENDED（TRIAL/FREE 不动）；解除 = 恢复正确时间 / 消除失配原因，调度器重验后自愈回 VALID（订阅按授权重映射） |

> 调度器：ONPREM 下应用启动时及按 `SMARTLIVESTOCK_LICENSE_VALIDATION_CRON`（默认 `0 */5 * * * *`，每 5 分钟）对全部已登记租户重跑校验管线；HOSTED 为 no-op。时间容差 `SMARTLIVESTOCK_LICENSE_TIME_TOLERANCE`（默认 PT2M）。手工改库会在下个周期自愈并留事件（`deployment_license_events`）。

---

## 设计要点

1. **无 Ranch/IoT Admin 端点** — admin 访问任意农场的牲畜/围栏/告警/设备，直接复用 App API 的 `/api/v1/farms/{farmId}/...` 端点，通过 platform_admin 角色在 Farm Scope 校验中放行跨租户访问
2. **跨租户筛选** — 所有列表接口支持 `tenantId` 筛选参数
3. **status 动作用 PUT** — 状态变更是幂等操作，使用 PUT
4. **审计日志** — Phase 1 先做查询接口，写入由 Application Service 内部通过领域事件自动完成（AlertStatusChanged、DeviceActivated 等）
5. **API Key 安全** — 完整 Key 明文仅在创建时返回一次，之后仅返回 keyId 和 prefix。禁止通过任何查询接口暴露完整 Key
