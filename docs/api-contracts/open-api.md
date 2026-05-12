# Open API 端点（`/api/v1/open/`）

> **端点总数**: 11
> **认证**: API Key（`Authorization: Bearer <api-key>` 或 `X-API-Key: <api-key>`）
> **Farm Scope**: API Key 绑定 tenantId，farmId 通过路径传入；Key 无权访问非本租户的农场
> **设计原则**: 路径与 App API 对齐，以读操作为主，唯一写操作是 IoT 设备自注册

---

## Open API 专属约定

| 维度 | 规则 |
|------|------|
| **认证** | `Authorization: Bearer <api-key>` 或 `X-API-Key: <api-key>` |
| **速率限制** | 每分钟 60 次（默认），`/open/devices/register` 为 100/min。响应头含 `X-RateLimit-Limit` / `X-RateLimit-Remaining` / `X-RateLimit-Reset` |
| **幂等性** | POST 请求支持 `Idempotency-Key` 请求头。相同 key 24h 内返回缓存的响应（HTTP status + headers + body）。Key 冲突（不同 body 相同 key）返回 409 `DUPLICATE_RESOURCE`。Redis 存储，TTL 24h |
| **分页上限** | `pageSize` 最大 100 |
| **版本锁定** | 破坏性变更递增 URL 版本（如 `/api/v1/open/v2/`），旧版本至少保留 12 个月 |
| **Phase 1 范围** | 不含 Health 上下文；Phase 2 按同模式扩展 `/open/farms/{farmId}/twin/...` |

---

## 1. 牲畜（只读）— 2 端点

### GET /open/farms/{farmId}/livestock

牲畜列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-O01",
  "data": {
    "items": [
      { "id": "101", "livestockCode": "LIV-1-001", "breed": "安格斯牛", "gender": "male", "healthStatus": "healthy", "lastLatitude": 28.2459123, "lastLongitude": 112.8521004, "lastPositionAt": "2026-05-07T10:25:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 120
  }
}
```

### GET /open/farms/{farmId}/livestock/{livestockId}

牲畜详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-O02", "data": { "id": "101", "livestockCode": "LIV-1-001", "breed": "安格斯牛", ... } }
```

---

## 2. 围栏（只读）— 2 端点

### GET /open/farms/{farmId}/fences

围栏列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-O03",
  "data": {
    "items": [
      { "id": "301", "name": "北区围栏", "vertices": [{ "lng": 112.8500, "lat": 28.2440 }, ...], "color": "#4CAF50", "status": "active" }
    ],
    "page": 1, "pageSize": 20, "total": 5
  }
}
```

### GET /open/farms/{farmId}/fences/{fenceId}

围栏详情（含坐标点）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-O04", "data": { "id": "301", "name": "北区围栏", "vertices": [...], ... } }
```

---

## 3. 告警（只读）— 2 端点

### GET /open/farms/{farmId}/alerts

告警列表。筛选: `?severity=critical&status=pending&startTime=2026-05-01T00:00:00.000Z&endTime=2026-05-07T23:59:59.000Z`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-O05",
  "data": {
    "items": [
      { "id": "501", "type": "fence_breach", "status": "pending", "severity": "warning", "livestockId": "101", "livestockCode": "LIV-1-001", "message": "牛只越出围栏", "createdAt": "2026-05-07T10:25:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 8
  }
}
```

### GET /open/farms/{farmId}/alerts/{alertId}

告警详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-O06", "data": { "id": "501", "type": "fence_breach", "status": "pending", ... } }
```

---

## 4. 设备与定位（只读）— 4 端点

### GET /open/farms/{farmId}/devices

设备列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-O07",
  "data": {
    "items": [
      { "id": "201", "deviceCode": "DEV-2026-00001", "deviceType": "device_tracker", "status": "active", "runtimeStatus": "online", "batteryLevel": 85, "lastOnlineAt": "2026-05-07T10:29:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 45
  }
}
```

### GET /open/farms/{farmId}/devices/{deviceId}

设备详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-O08", "data": { "id": "201", "deviceCode": "DEV-2026-00001", "deviceType": "device_tracker", "status": "active", "runtimeStatus": "online", ... } }
```

### GET /open/farms/{farmId}/gps-logs/latest

全场最新 GPS 坐标（批量）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-O09",
  "data": {
    "items": [
      { "deviceId": "201", "livestockId": "101", "livestockCode": "LIV-1-001", "lng": 112.8521004, "lat": 28.2459123, "accuracy": 3.50, "recordedAt": "2026-05-07T10:25:00.000Z" }
    ]
  }
}
```

### GET /open/farms/{farmId}/livestock/{livestockId}/gps-logs

单牲畜 GPS 历史。`?startTime=2026-05-01T00:00:00.000Z&endTime=2026-05-07T23:59:59.000Z&page=1&pageSize=100`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-O10",
  "data": {
    "items": [
      { "lng": 112.8515000, "lat": 28.2451000, "accuracy": 5.00, "recordedAt": "2026-05-07T09:00:00.000Z" }
    ],
    "page": 1, "pageSize": 100, "total": 48
  }
}
```

---

## 5. IoT 设备自注册（写入）— 1 端点

### POST /open/devices/register

设备上报序列号自注册。**唯一的 Open API 写入端点**。

使用设备专用 API Key（scopes 仅含 `["device:register"]`），不允许访问任何读取端点。

设备创建后进入 `inventory` 状态（租户级，尚未分配到农场）。后续通过 App API `POST /api/v1/farms/{farmId}/installations` 安装到具体牲畜时关联农场。

支持 `Idempotency-Key` 幂等性保障。

```
Request:
{ "serialNo": "SN-2026-00001", "deviceType": "device_tracker", "firmwareVersion": "v2.1.3" }

Response 201:
{
  "code": "OK", "message": "success", "requestId": "req-O11",
  "data": { "id": "251", "deviceCode": "DEV-2026-00051", "deviceType": "device_tracker", "status": "inventory", "tenantId": "7" }
}

Error 401:
{ "code": "AUTH_FORBIDDEN", "message": "该 Key 无权执行设备注册", "requestId": "req-O11" }

Error 409 (Idempotency-Key 冲突):
{ "code": "DUPLICATE_RESOURCE", "message": "Idempotency-Key 已被使用", "requestId": "req-O11" }
```

---

## 响应头示例

Open API 所有响应均携带速率限制头：

```
HTTP/1.1 200 OK
X-RateLimit-Limit: 60
X-RateLimit-Remaining: 58
X-RateLimit-Reset: 1746504120
```

使用 Idempotency-Key 时的响应头：

```
HTTP/1.1 200 OK
Idempotency-Key: idem-abc123
X-Idempotency-Status: HIT
```

---

## Phase 1 排除说明

以下 App API 端点**不暴露给 Open API**：

| 端点 | 排除原因 |
|------|---------|
| `/farms/{farmId}/dashboard/summary` | 读模型聚合了实时计算逻辑，内部指标定义可能变更 |
| `/farms/{farmId}/map/overview` | 地图总览字段结构不稳定，Phase 2 评估后考虑开放 |
| 所有写操作（除设备自注册） | Open API 保持只读边界 |
| 设备许可证、安装记录 | 属于租户内部管理操作，不适合第三方访问 |

Phase 2 引入 Health Context 后按同模式扩展 `/open/farms/{farmId}/twin/...`。
