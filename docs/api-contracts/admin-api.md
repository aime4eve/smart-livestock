# Admin API 端点（`/api/v1/admin/`）

> **端点总数**: 21
> **认证**: JWT Bearer Token（role = platform_admin）
> **特点**: 跨租户视图，批量操作，管理动作。基础资源操作复用 App API 端点，admin 角色可访问任意 farm 数据。

---

## 1. 租户管理 — 5 端点

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

## 设计要点

1. **无 Ranch/IoT Admin 端点** — admin 访问任意农场的牲畜/围栏/告警/设备，直接复用 App API 的 `/api/v1/farms/{farmId}/...` 端点，通过 platform_admin 角色在 Farm Scope 校验中放行跨租户访问
2. **跨租户筛选** — 所有列表接口支持 `tenantId` 筛选参数
3. **status 动作用 PUT** — 状态变更是幂等操作，使用 PUT
4. **审计日志** — Phase 1 先做查询接口，写入由 Application Service 内部通过领域事件自动完成（AlertStatusChanged、DeviceActivated 等）
5. **API Key 安全** — 完整 Key 明文仅在创建时返回一次，之后仅返回 keyId 和 prefix。禁止通过任何查询接口暴露完整 Key
