# 后端 API 契约（基于 mobile_app 现状反向梳理）

## 0. 文档说明

- **目标**：以 `Mobile/mobile_app` 当前代码为真实依据，统一梳理 App 已调用 / 将调用的所有后端接口，固化字段与行为契约。
- **区别于**：`mobile-app-mock-api-contract.md` 为早期 Mock 先行版本，本文档为**代码落地后**的修订版，包含新增端点（孪生、设备、牲畜详情、统计）与实际字段差异。
- **真实来源**：`Mobile/mobile_app/lib/core/api/api_cache.dart`、各 `features/*/data/live_*.dart`、`Mobile/backend/routes/*.js`、`Mobile/backend/data/*.js`。
- **覆盖版本**：Phase 1（MVP 可联调） + Phase 2（扩展字段与端点）标注。

---

## 1. 全局约定

### 1.1 Base URL

| 形态 | URL |
|------|-----|
| 开发（Web） | `http://127.0.0.1:3001/api/v1` |
| 开发（Native） | `http://localhost:3001/api/v1` |
| 回滚兼容（Web） | `http://127.0.0.1:3001/api` |
| 回滚兼容（Native） | `http://localhost:3001/api` |
| 编译期覆盖 | `--dart-define=API_BASE_URL=<url>` |

所有新接口以 `/api/v1` 为规范入口；文档接下来只写版本前缀之后的部分。`/api` 长期保留为兼容入口，兼容承诺见 `api-compatibility-matrix.md`。

### 1.2 响应包络

**成功**：

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {}
}
```

**失败**：

```json
{
  "code": "VALIDATION_ERROR",
  "message": "name is required",
  "requestId": "req_xxx"
}
```

- `code` 为业务语义码（见 §1.6），HTTP 状态码与之对应。
- 失败响应**不包含 `data` 字段**；前端以 `code` 判断，不依赖 HTTP 状态文本。
- `requestId` 由服务端生成并在响应头 `X-Request-Id` 中也可回传（Phase 2 强制）。

### 1.3 分页结构

列表型 `data`：

```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

- 默认 `page=1`，`pageSize=20`；最大 `pageSize=200`。
- App 预加载阶段使用 `pageSize=100/200` 拉大页（见 §2.2），后续收敛为服务端分页。

### 1.4 时间与 ID

| 项 | 约定 |
|----|------|
| 时间 | ISO-8601 带时区，优先 `+08:00`（示例：`2026-04-21T10:20:00+08:00`） |
| 租户 ID | `tenant_{n}`，`n` 为数字（当前 seed：`tenant_001` … `tenant_006`） |
| 用户 ID | `user_{role}` / `user_{n}` |
| 动物 ID | `animal_{nnn}`；耳标 `SL-2024-{nnn}` |
| 设备 ID | `dev_{type}_{nnn}`（示例：`dev_gps_001`） |
| 告警 ID | `alert_{nnn}`（**注意**：当前 seed 使用 `alert-001` 连字符风格，联调前需统一为下划线） |
| 围栏 ID | `fence_{nnn}` |

### 1.5 鉴权

- Header：`Authorization: Bearer <token>`。
- **当前 Mock Token**：`mock-token-owner` / `mock-token-worker` / `mock-token-ops`。
- **Phase 2 升级**：改为真实 JWT（见基础设施文档）；本契约保持 Bearer 机制不变，仅替换 token 生成与校验实现。
- 除 `POST /auth/login` 外，所有接口都必须带 Authorization Header。

### 1.6 错误码清单

| code | HTTP | 含义 |
|------|------|------|
| `AUTH_UNAUTHORIZED` | 401 | 未登录或 Token 失效 |
| `AUTH_FORBIDDEN` | 403 | 已登录但无权限 |
| `TENANT_DISABLED` | 403 | 租户已禁用 |
| `RESOURCE_NOT_FOUND` | 404 | 资源不存在 |
| `CONFLICT` | 409 | 状态/并发冲突（如告警状态机迁移冲突、围栏更新版本冲突） |
| `VALIDATION_ERROR` | 422 | 参数校验失败 |
| `RATE_LIMITED` | 429 | 超过限流（Phase 2） |
| `INTERNAL_ERROR` | 500 | 服务内部异常 |
| `UPSTREAM_UNAVAILABLE` | 503 | 上游（GPS、AI）不可用 |

### 1.7 权限码

| permission | 说明 | 默认持有角色 |
|------------|------|--------------|
| `dashboard:view` | 看板 | owner / worker |
| `map:view` | 地图与轨迹 | owner / worker |
| `alert:view` / `:ack` / `:handle` / `:archive` / `:batch` | 告警分级 | owner（全部）/ worker（view + ack） |
| `fence:view` / `:manage` | 围栏查看 / 增删改 | owner / worker |
| `livestock:view` / `:edit` | 牲畜信息 | owner / worker |
| `device:view` / `:manage` | 设备 | owner |
| `twin:view` | 数字孪生 | owner |
| `stats:view` | 统计 | owner |
| `tenant:view` / `:create` / `:edit` / `:toggle` / `:delete` | 租户管理 | ops |
| `license:manage` | License 配额 | ops |
| `profile:view` | 我的 | 全部 |

---

## 2. 预加载与缓存

### 2.1 ApiCache 启动预加载

`APP_MODE=live` 时，App 在启动阶段通过 `ApiCache.init(role)` **并行**请求以下端点，失败任一不阻塞启动：

1. `GET /dashboard/summary`
2. `GET /map/trajectories?animalId=animal_001&range=24h`
3. `GET /alerts?pageSize=100`
4. `GET /fences?pageSize=100`
5. `GET /tenants?pageSize=100`
6. `GET /profile`
7. `GET /twin/overview`
8. `GET /twin/fever/list`
9. `GET /twin/digestive/list`
10. `GET /twin/estrus/list`
11. `GET /twin/epidemic/summary`
12. `GET /twin/epidemic/contacts`
13. `GET /devices?pageSize=200`

**服务端要求**：以上端点必须在 1.5s 内响应，否则前端回退到 Mock Repository。

### 2.2 写操作后强制刷新

| 写操作 | 触发的刷新 GET |
|--------|----------------|
| 租户 CRUD / 状态 / License | `GET /tenants?pageSize=100` |
| 围栏 CRUD | `GET /fences?pageSize=100` + `GET /map/trajectories` |
| 告警状态迁移 | `GET /alerts?pageSize=100` |

---

## 3. 端点详述

> 表格约定：
> - ✅ 已实现、🟡 已实现但字段不齐 / 行为不符、🔴 未实现（需新建）、⚪ 已实现但 App 尚未对接。

### 3.1 鉴权（`/auth`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| ✅ | `POST` | `/auth/login` | 登录（Mock 仅按 role 签发 token） |

**Request**：

```json
{ "role": "owner" }
```

**Response `data`**：

```json
{ "token": "mock-token-owner", "role": "owner" }
```

**Phase 2 升级**：入参改为 `{ account, password }` 或 OIDC 回调；响应增加 `expiresAt`、`refreshToken`。

---

### 3.2 当前用户（`/me`、`/profile`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| ✅ | `GET` | `/me` | 返回当前 Token 关联用户 |
| ✅ | `GET` | `/profile` | 我的页（与 `/me` 字段重叠，App 同时使用） |

**`GET /me` Response `data`**：

```json
{
  "userId": "user_owner",
  "tenantId": "tenant_001",
  "name": "牧场主-演示",
  "role": "owner",
  "permissions": ["dashboard:view", "..."]
}
```

**`GET /profile` Response `data`**（App 使用字段）：

```json
{
  "userId": "user_owner",
  "name": "牧场主-演示",
  "mobile": "138****0001",
  "tenantName": "示例牧场",
  "notificationEnabled": true
}
```

**契约对齐项**：`/me` 与 `/profile` 应共享同一用户视图投影，`tenantName` 需在两者均返回；**Phase 2** 合并为单一 `/me` 端点并弃用 `/profile`。

---

### 3.3 看板（`/dashboard`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| 🟡 | `GET` | `/dashboard/summary` | 看板指标 |

**Response `data`**：

```json
{
  "metrics": [
    { "key": "alert-pending", "title": "待处理告警", "value": "12" },
    { "key": "cattle-count",  "title": "在栏头数",   "value": "1,280" }
  ],
  "lastSyncAt": "2026-04-21T10:20:00+08:00"
}
```

- `metrics[].key`：稳定字符串，前端拼为 `dashboard-metric-{key}` 作为 Widget Key。
- `metrics[].value`：**字符串**（支持千分位、百分号等格式化）。
- **对齐点**：`lastSyncAt` 当前 App 未使用但后端已返回，保留但标注可选。

---

### 3.4 地图与轨迹（`/map`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| ✅ | `GET` | `/map/trajectories` | 牲畜轨迹 + 围栏 |

**Query**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `animalId` | string | 否 | 默认首头 |
| `range` | enum | 是 | `24h` / `7d` / `30d` |

**Response `data`**：

```json
{
  "animals": [
    {
      "id": "animal_001",
      "earTag": "SL-2024-001",
      "lat": 43.81,
      "lng": 87.62,
      "boundaryStatus": "inside"
    }
  ],
  "selectedAnimalId": "animal_001",
  "selectedRange": "24h",
  "summaryText": "过去 24 小时采样 24 点",
  "points": [
    { "lat": 43.81, "lng": 87.62, "ts": "2026-04-21T09:00:00+08:00" }
  ],
  "fences": [ /* 围栏对象（见 3.6）*/ ],
  "fallbackList": []
}
```

- `boundaryStatus`：`inside` / `outside`（服务端判定后给出，避免前端再做几何运算）。
- `points`：按小时/天降采样（由后端决定采样频率）。

---

### 3.5 告警（`/alerts`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| ✅ | `GET` | `/alerts` | 列表（支持 stage 过滤、分页） |
| ✅ | `POST` | `/alerts/:id/ack` | 确认 |
| ✅ | `POST` | `/alerts/:id/handle` | 处理 |
| ✅ | `POST` | `/alerts/:id/archive` | 归档 |
| 🟡 | `POST` | `/alerts/batch-handle` | 批量（实现与契约不一致，见下） |

**`GET /alerts` Query**：`stage`（`pending`/`acknowledged`/`handled`/`archived`）、`page`、`pageSize`。

**`AlertItem` 字段**：

```json
{
  "id": "alert_001",
  "title": "耳标 SL-2024-017 体温异常",
  "occurredAt": "2026-04-21T08:15:00+08:00",
  "level": "critical",
  "type": "health",
  "stage": "pending",
  "earTag": "SL-2024-017",
  "livestockId": "1017"
}
```

- `level`：`critical` → P0；`warning` → P1；其他 → P2（前端映射）。
- `stage` 状态机：`pending → acknowledged → handled → archived`；**非法迁移返回 `409 CONFLICT`**。

**`POST /alerts/batch-handle`**：

```json
{ "alertIds": ["alert_001", "alert_002"], "action": "ack" }
```

- `action` 合法值：`ack` / `handle` / `archive`（对应单条端点的动词）。
- **当前后端实现 Bug**：校验使用 `pending/acknowledged/…` 而分支判断 `ack/…`，**需修复为统一 `ack/handle/archive`**（与契约一致）。
- Response：

```json
{
  "updated": 2,
  "errors": [{ "id": "alert_003", "error": "CONFLICT", "currentStage": "handled" }]
}
```

---

### 3.6 围栏（`/fences`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| ✅ | `GET` | `/fences` | 列表 |
| ✅ | `GET` | `/fences/:id` | 详情 |
| ✅ | `POST` | `/fences` | 创建 |
| ✅ | `PUT` | `/fences/:id` | 更新 |
| ✅ | `DELETE` | `/fences/:id` | 删除 |

**`Fence` 字段**：

```json
{
  "id": "fence_001",
  "name": "A 区草场",
  "type": "polygon",
  "alarmEnabled": true,
  "status": "active",
  "coordinates": [[87.62, 43.81], [87.63, 43.82], [87.63, 43.80]],
  "version": 3
}
```

- `type`：`polygon` / `circle` / `rectangle`。
- `coordinates`：`[lng, lat]` 对数组，多边形要求 ≥ 3 个点；圆形/矩形的坐标含义由 `type` 确定（Phase 2 明确）。
- `status`：`active` / `inactive`。
- **`version` 字段必须新增**：用于并发更新时判断冲突（PUT 时带上旧 version，服务端比较后再写）。不匹配返回 `409 CONFLICT`。
- **返回字段补充**：`livestockCount`（可选，由服务端基于 `animals.fenceId` 聚合）、`areaHectares`（Phase 2）。

**Create / Update Body**：

```json
{
  "name": "A 区草场",
  "type": "polygon",
  "coordinates": [[87.62, 43.81], "..."],
  "alarmEnabled": true,
  "status": "active"
}
```

**Delete Response `data`**：返回被删除围栏完整对象（App `fence_form_page` 依赖回显）。

---

### 3.7 租户（`/tenants`）

| 状态 | Method | Path | Phase | 说明 |
|------|--------|------|-------|------|
| ✅ | `GET` | `/tenants` | 1 | 列表 |
| ⚪ | `GET` | `/tenants/:id` | 1 | 详情（`ApiCache.fetchTenantDetail` 已实现但 App 尚未使用） |
| ✅ | `POST` | `/tenants` | 1 | 创建 |
| ✅ | `PUT` | `/tenants/:id` | 1 | 更新（当前仅 `name`） |
| ✅ | `DELETE` | `/tenants/:id` | 1 | 删除 |
| ✅ | `POST` | `/tenants/:id/status` | 1 | 启用/禁用 |
| ✅ | `POST` | `/tenants/:id/license` | 1 | 调整配额 |
| 🔴 | `GET` | `/tenants/:id/devices` | 2 | 设备列表（详情页卡片） |
| 🔴 | `GET` | `/tenants/:id/logs` | 2 | 操作日志 |
| 🔴 | `GET` | `/tenants/:id/stats` | 2 | 统计概览 |

**Phase 1 `Tenant` 字段**：

```json
{
  "id": "tenant_001",
  "name": "示例牧场",
  "status": "active",
  "licenseUsed": 38,
  "licenseTotal": 100
}
```

**Phase 2 扩展字段**（后端 seed 先行补齐）：

```json
{
  "contactName": "张三",
  "contactPhone": "13800000000",
  "contactEmail": "zhang@example.com",
  "region": "新疆-伊犁",
  "remarks": "xxx",
  "createdAt": "2026-04-01T10:00:00+08:00",
  "updatedAt": "2026-04-20T09:15:00+08:00",
  "lastUpdatedBy": "user_ops"
}
```

**`GET /tenants` Query**：

| 参数 | 类型 | 默认 | 说明 |
|------|------|------|------|
| `page` / `pageSize` | int | 1 / 20 | 分页 |
| `status` | enum | - | `active` / `disabled` / 缺省表示全部 |
| `search` | string | - | 名称模糊匹配（Phase 1 仅 name，Phase 2 可含联系人） |
| `sort` | enum | `licenseUsage` | `name` / `licenseUsage` / `createdAt`（Phase 2） / `updatedAt`（Phase 2） |
| `order` | enum | `desc` | `asc` / `desc` |

**写操作 Body 契约**（严格对齐前端）：

| Path | Body |
|------|------|
| `POST /tenants` | `{ "name": "...", "licenseTotal": 100 }` |
| `PUT /tenants/:id` | `{ "name": "..." }`（Phase 2 增加联系人/备注） |
| `POST /tenants/:id/status` | `{ "status": "active" \| "disabled" }` |
| `POST /tenants/:id/license` | `{ "licenseTotal": 200 }` — **参数名禁止使用 `newQuota`** |
| `DELETE /tenants/:id` | 无 body；支持 query `reason=...`（Phase 2 写入日志） |

**删除返回**：`data: { id }` 或完整租户对象（建议返回完整对象以便 App 即时显示"已删除"态）。

---

### 3.8 设备（`/devices`）

| 状态 | Method | Path | Phase | 说明 |
|------|--------|------|-------|------|
| 🟡 | `GET` | `/devices` | 1 | 列表（权限应为 `device:view`，现复用 `dashboard:view`） |
| 🔴 | `GET` | `/devices/:id` | 2 | 详情 |
| 🔴 | `POST` | `/devices/:id/bind` | 2 | 绑定/更换耳标 |

**`DeviceItem` 字段**：

```json
{
  "id": "dev_gps_001",
  "name": "GPS-001",
  "type": "gps",
  "status": "online",
  "boundEarTag": "SL-2024-001",
  "batteryPercent": 82,
  "signalStrength": 4,
  "lastSync": "2026-04-21T09:55:00+08:00"
}
```

- `type`：`gps` / `rumenCapsule` / `accelerometer`。
- `status`：`online` / `offline` / `lowBattery`。
- `signalStrength`：0-5 格。

---

### 3.9 牲畜（`/livestock`）🔴 全部未实现

| 状态 | Method | Path | Phase | 说明 |
|------|--------|------|-------|------|
| 🔴 | `GET` | `/livestock` | 2 | 列表（分页/筛选） |
| 🔴 | `GET` | `/livestock/:earTag` | 1 | 详情（App `LiveLivestockRepository` 占位需求） |
| 🔴 | `PUT` | `/livestock/:earTag` | 2 | 更新基础信息 |

**`LivestockDetail` Response `data`**（映射 `LivestockDetail`）：

```json
{
  "earTag": "SL-2024-001",
  "livestockId": "0001",
  "breed": "西门塔尔",
  "ageMonths": 18,
  "weightKg": 420,
  "health": "healthy",
  "fenceId": "fence_001",
  "lat": 43.81,
  "lng": 87.62,
  "devices": [
    { "id": "dev_gps_001", "type": "gps", "status": "online" }
  ],
  "bodyTemp": 38.5,
  "activityLevel": "normal",
  "ruminationFreq": 62,
  "lastLocation": {
    "lat": 43.81, "lng": 87.62, "timestamp": "2026-04-21T09:55:00+08:00"
  }
}
```

- `health`：`healthy` / `watch` / `abnormal`。

---

### 3.10 统计（`/stats`）🔴 全部未实现

| 状态 | Method | Path | Phase | 说明 |
|------|--------|------|-------|------|
| 🔴 | `GET` | `/stats/health` | 2 | 健康摘要 |
| 🔴 | `GET` | `/stats/alerts` | 2 | 告警摘要 |
| 🔴 | `GET` | `/stats/devices` | 2 | 设备摘要 |

**Query**：`timeRange`（`7d` / `30d` / `90d`）。

**`/stats/health` `data`**（对齐 `StatsHealthSummary`）：

```json
{
  "totalLivestock": 1280,
  "healthyCount": 1200,
  "watchCount": 56,
  "abnormalCount": 24,
  "trend": [ { "date": "2026-04-14", "healthyRate": 0.93 } ]
}
```

**`/stats/alerts` `data`**：

```json
{
  "totalAlerts": 156,
  "byStage": { "pending": 12, "acknowledged": 22, "handled": 90, "archived": 32 },
  "byLevel": { "critical": 14, "warning": 92, "info": 50 },
  "trend": [ { "date": "2026-04-14", "count": 10 } ]
}
```

**`/stats/devices` `data`**：

```json
{
  "totalDevices": 100,
  "onlineCount": 88,
  "offlineCount": 8,
  "lowBatteryCount": 4,
  "byType": { "gps": 50, "rumenCapsule": 30, "accelerometer": 20 }
}
```

---

### 3.11 数字孪生（`/twin`）

| 状态 | Method | Path | 说明 |
|------|--------|------|------|
| ✅ | `GET` | `/twin/overview` | 总览（指标 + 场景摘要 + 待办） |
| ✅ | `GET` | `/twin/fever/list` | 体温异常列表 |
| ✅ | `GET` | `/twin/fever/:id` | 体温详情 |
| ✅ | `GET` | `/twin/digestive/list` | 消化健康列表 |
| ✅ | `GET` | `/twin/digestive/:id` | 消化详情 |
| ✅ | `GET` | `/twin/estrus/list` | 发情列表 |
| ✅ | `GET` | `/twin/estrus/:id` | 发情详情 |
| ✅ | `GET` | `/twin/epidemic/summary` | 疫病摘要 |
| ✅ | `GET` | `/twin/epidemic/contacts` | 接触追踪 |

**`/twin/overview` `data`**：

```json
{
  "stats": {
    "totalLivestock": 1280,
    "healthyRate": 0.94,
    "alertCount": 12,
    "criticalCount": 2,
    "deviceOnlineRate": 0.88,
    "livestockCaption": "在栏 1280 头",
    "alertCaption": "待处理 12 条",
    "healthCaption": "健康率 94%",
    "deviceCaption": "在线 88%",
    "healthTrend": [0.92, 0.93, 0.94, "..."],
    "livestockTrend": [1270, 1275, 1280, "..."]
  },
  "sceneSummary": {
    "fever":     { "abnormalCount": 4, "criticalCount": 1 },
    "digestive": { "abnormalCount": 3, "watchCount": 8 },
    "estrus":    { "highScoreCount": 5, "breedingAdvice": true },
    "epidemic":  { "status": "safe", "abnormalRate": 0.02 }
  },
  "pastureBanner": { "headline": "...", "detail": "..." },
  "pendingTasks": [
    {
      "id": "task_001",
      "title": "处理 4 条体温告警",
      "subtitle": "最近 24 小时",
      "routePath": "/fever",
      "severity": "high"
    }
  ]
}
```

**`/twin/fever/list` 每项**：

```json
{
  "livestockId": "1017",
  "baselineTemp": 38.5,
  "threshold": 39.5,
  "recent72h": [ { "temperature": 38.7, "timestamp": "2026-04-21T09:00:00+08:00" } ],
  "status": "abnormal",
  "conclusion": "持续升高，建议巡查"
}
```

**`/twin/digestive/list` 每项**：

```json
{
  "livestockId": "1017",
  "motilityBaseline": 60,
  "status": "watch",
  "advice": "关注反刍节律",
  "recent24h": [ { "frequency": 58, "intensity": 0.7, "timestamp": "..." } ]
}
```

**`/twin/estrus/list` 每项**：

```json
{
  "livestockId": "1017",
  "score": 0.82,
  "stepIncreasePercent": 0.35,
  "tempDelta": 0.4,
  "distanceDelta": 1200,
  "timestamp": "2026-04-21T08:00:00+08:00",
  "advice": "建议安排配种",
  "trend7d": [ { "score": 0.7, "timestamp": "2026-04-15T08:00:00+08:00" } ]
}
```

**`/twin/epidemic/summary` `data`**：

```json
{
  "avgTemperature": 38.6,
  "avgActivity": 1.2,
  "abnormalRate": 0.02,
  "totalLivestock": 1280,
  "abnormalCount": 24
}
```

**`/twin/epidemic/contacts` 每项**：

```json
{
  "fromId": "animal_001",
  "toId": "animal_017",
  "lastContact": "2026-04-20T15:30:00+08:00",
  "proximity": 0.4
}
```

---

## 4. 端点差距汇总（需立即补齐）

### Phase 1（MVP 必需）

| 端点 | 目的 | 阻塞功能 |
|------|------|----------|
| `GET /livestock/:earTag` | 牲畜详情 | `LiveLivestockRepository` 联调 |
| `GET /me` 与 `/profile` 字段对齐 | 消除两端点重复 | 我的页 |
| `POST /alerts/batch-handle` 修复 `action` 值 | 契约一致性 | 批量处理 |

### Phase 2（扩展）

| 端点 | 目的 |
|------|------|
| `GET /tenants/:id/{devices,logs,stats}` | 租户详情页 Phase 2 卡片 |
| `GET /stats/{health,alerts,devices}` | 统计页 |
| `GET /livestock` + `PUT /livestock/:earTag` | 牲畜列表与编辑 |
| `GET /devices/:id` + `POST /devices/:id/bind` | 设备详情与绑定 |
| 租户 seed 扩展字段 | 联系人/地区/备注/时间戳 |

### 非端点契约缺口

1. **`API_ROLE` 与登录角色不一致**：App 预加载固定用 `API_ROLE`，但租户写操作使用 Session 的 role。应改为登录后获取真实 Token，不再区分两套角色来源。
2. **告警/租户 ID 命名风格不一致**：seed 中 `alert-001`、`animal_001` 混用。联调前需统一为下划线风格（见 §1.4）。
3. **租户 `licenseUsed` 计算口径**：当前 seed 手写，未来应由后端基于 `animals` 表按 `tenantId` 聚合后计算。
4. **围栏并发保护缺失**：无 `version` 字段，当前多人编辑可能互相覆盖。

---

## 5. 验收标准

- 所有 Phase 1 端点在 Postman/HTTP 级测试（Supertest）下返回包络 + 错误码均符合 §1.2 / §1.6。
- `mobile_app` 在 `APP_MODE=live` 下完成以下闭环：
  - 登录 → 预加载 → 看板/地图/告警/围栏/租户/我的/孪生首页均可渲染。
  - 租户创建、状态切换、License 调整、删除后列表即时刷新。
  - 围栏创建、编辑、删除后地图同步刷新。
  - 告警状态迁移与批量处理成功，非法迁移返回 409。
- 所有响应字段名、枚举值、分页结构与本文 §3 一致，**不得在联调过程中私自改名**。

---

**契约版本**：v1.0（代码落地版）
**生成日期**：2026-04-21
**来源**：mobile_app + backend 现状 + `2026-04-20-tenant-management-design.md`
