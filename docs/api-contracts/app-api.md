# App API 端点（`/api/v1/`）

> **端点详列数**: 115（全量；实际 117）
>
> ⚠️ **As-Built 校准（2026-06-26）**: 当前 App API 实际 **117 个端点**，本文档详列 **115 个**：Phase 1 全部（Identity 含 members/workers/owner、Ranch 含 FenceZone/V26 告警/force、IoT、ReadModel 含 ranch-overview）+ Phase 2a Commerce 9 + Phase 2b Health 15 + Phase 2c 全部 30（B2b/遥测/事件/Portal/Analytics/Tile）。与 117 的约 2 个差异来自代表性示例变体，主路径端点已全覆盖。端点真源为代码，详见 [后端实现现状 §7 API 设计](../superpowers/specs/2026-05-06-mvp-backend-design.md)。
> **认证**: JWT Bearer Token
> **Farm Scope**: 路径 `/farms/{farmId}/`（写操作强制，读操作优先）或 header `x-active-farm`（仅 GET，兼容过渡）

---

## 1. 认证（Auth）— 3 端点

### POST /auth/login

登录，手机号 + 密码 → JWT token。

```
Request:
{ "phone": "13800138000", "password": "aB3$xK9@pQ2" }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-001",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "dGhpcyBpcyBh...",
    "expiresIn": 3600
  }
}

Error 401:
{ "code": "AUTH_INVALID_TOKEN", "message": "手机号或密码错误", "requestId": "req-001" }
```

### POST /auth/refresh

刷新 Token（refreshToken 轮换，旧 token 立即失效）。

```
Request:
{ "refreshToken": "dGhpcyBpcyBh..." }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-002",
  "data": { "accessToken": "eyJhbGciOi...", "refreshToken": "bmV3IHJlZnJl...", "expiresIn": 3600 }
}

Error 401:
{ "code": "AUTH_INVALID_TOKEN", "message": "refreshToken 无效或已过期", "requestId": "req-002" }
```

### POST /auth/logout

登出，吊销 refreshToken。

```
Request:
{ "refreshToken": "dGhpcyBpcyBh..." }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-003" }
```

---

## 2. 身份（Identity）— 12 端点

### GET /tenants/me

当前租户信息。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-004",
  "data": {
    "id": "7",
    "name": "Demo牧场",
    "contactName": "张三",
    "contactPhone": "13800138000",
    "phase": "sample"
  }
}
```

### PUT /tenants/me

更新当前租户信息。权限: owner。

```
Request:
{ "name": "新名称", "contactName": "李四", "contactPhone": "13900139000" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-005", "data": { "id": "7", "name": "新名称", ... } }
```

### GET /me

当前用户信息。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-006",
  "data": { "id": "42", "username": "zhangsan", "name": "张三", "phone": "13800138000", "role": "owner", "tenantId": "7" }
}
```

### PUT /me

更新当前用户信息。

```
Request:
{ "name": "张三丰", "phone": "13800138001" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-007", "data": { "id": "42", "name": "张三丰", ... } }
```

### PUT /me/password

修改密码。

```
Request:
{ "oldPassword": "aB3$xK9@pQ2", "newPassword": "nEw4$pW0#zX9" }

Response 200:
{ "code": "OK", "message": "密码修改成功", "requestId": "req-008" }

Error 400:
{ "code": "VALIDATION_ERROR", "message": "原密码错误", "requestId": "req-008" }
```

### GET /farms

当前用户的农场列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-009",
  "data": {
    "items": [
      { "id": "1", "name": "城北牧场", "latitude": 28.2458000, "longitude": 112.8519000, "areaHectares": 150.50, "livestockCount": 120, "deviceCount": 45, "role": "owner" },
      { "id": "2", "name": "城南牧场", "latitude": 28.2300000, "longitude": 112.8600000, "areaHectares": 80.00, "livestockCount": 60, "deviceCount": 20, "role": "worker" }
    ],
    "page": 1, "pageSize": 20, "total": 2
  }
}
```

### POST /farms

创建农场。权限: owner。

```
Request:
{ "name": "东山牧场", "latitude": 28.3000000, "longitude": 112.9500000, "areaHectares": 200.00 }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-010", "data": { "id": "3", "name": "东山牧场", ... } }

Error 403:
{ "code": "QUOTA_EXCEEDED", "message": "牧场数量已达上限", "requestId": "req-010" }
```

### GET /farms/{farmId}

农场详情。权限: 该农场成员。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-011", "data": { "id": "1", "name": "城北牧场", "latitude": 28.2458000, "longitude": 112.8519000, "areaHectares": 150.50, "livestockCount": 120, "deviceCount": 45 } }

Error 403:
{ "code": "AUTH_FORBIDDEN", "message": "无权访问该农场", "requestId": "req-011" }
```

### PUT /farms/{farmId}

更新农场信息。权限: owner。

```
Request:
{ "name": "城北牧场（扩建）", "areaHectares": 200.00 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-012", "data": { "id": "1", "name": "城北牧场（扩建）", ... } }
```

### GET /farms/{farmId}/members

农场成员列表。权限: owner。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-013",
  "data": {
    "items": [
      { "userId": "42", "userName": "张三", "role": "owner", "status": "active" },
      { "userId": "43", "userName": "李四", "role": "worker", "status": "active" }
    ],
    "page": 1, "pageSize": 20, "total": 2
  }
}
```

### POST /farms/{farmId}/members

添加成员。权限: owner。

```
Request:
{ "phone": "13900139000", "role": "worker" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-014", "data": { "userId": "44", "userName": "王五", "role": "worker" } }

Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "该用户已是农场成员", "requestId": "req-014" }
```

### DELETE /farms/{farmId}/members/{userId}

移除成员。权限: owner。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-015" }
```

### PUT /farms/{farmId}/owner

变更牧场主（B2B Admin 操作）。当前 ACTIVE OWNER 分配置 DISABLED，新 owner 置 OWNER/ACTIVE。

```
Request:
{ "ownerId": 123 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-015a", "data": { "farmId": 1, "ownerId": 123 } }

Error 403:
{ "code": "AUTH_FORBIDDEN", "message": "不能跨租户变更牧场主", "requestId": "req-015a" }
```

> **members vs workers**：上方 `members` 端点把**已存在用户**关联到牧场（操作 user_farm_assignment）；下方 `workers` 端点**创建并管理 worker 账号本身**（创建 User + 自动建分配，含改资料/启停/重置密码）。

### POST /farms/{farmId}/workers

创建牧工账号（role 固定 WORKER，自动绑定本牧场）。

```
Request:
{ "phone": "13900000088", "name": "新牧工", "password": "xxx" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-015b", "data": { "id": "202", "name": "新牧工", "phone": "13900000088", "role": "worker", "status": "active" } }

Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "该手机号已注册", "requestId": "req-015b" }
```

### PUT /farms/{farmId}/workers/{userId}

更新牧工资料（name/phone 可选）。

```
Request:
{ "name": "新牧工（改名）", "phone": "13900000089" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-015c", "data": { "id": "202", "name": "新牧工（改名）", "phone": "13900000089", "role": "worker", "status": "active" } }
```

> 跨租户 → `AUTH_FORBIDDEN` "无权操作该用户"。

### PUT /farms/{farmId}/workers/{userId}/status

启用/禁用牧工。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-015d", "data": { "id": "202", "status": "disabled" } }
```

> `status` 仅识别 `active`/`disabled`。

### PUT /farms/{farmId}/workers/{userId}/reset-password

重置牧工密码。

```
Request:
{ "password": "newXxx" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-015e" }
```

---

## 3. 牧场（Ranch）

### 3.1 牲畜 — 5 端点

#### GET /farms/{farmId}/livestock

牲畜列表。支持筛选: `?keyword=&gender=male&status=healthy`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-016",
  "data": {
    "items": [
      {
        "id": "101",
        "farmId": "1",
        "livestockCode": "LIV-1-001",
        "breed": "安格斯牛",
        "gender": "male",
        "birthDate": "2024-03-15",
        "weight": 450.50,
        "healthStatus": "healthy",
        "lastLatitude": 28.2459123,
        "lastLongitude": 112.8521004,
        "lastPositionAt": "2026-05-07T10:25:00.000Z",
        "devices": [
          { "deviceCode": "SN-TRK-00001", "devEui": "70B3D57ED0040002", "deviceType": "tracker", "runtimeStatus": "online" }
        ]
      }
    ],
    "page": 1, "pageSize": 20, "total": 120
  }
}
```

#### POST /farms/{farmId}/livestock

新增牲畜。权限: owner。

```
Request:
{ "livestockCode": "LIV-1-050", "breed": "西门塔尔牛", "gender": "female", "birthDate": "2025-01-10", "weight": 380.00 }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-017", "data": { "id": "150", "livestockCode": "LIV-1-050", ... } }

Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "牲畜编号已存在", "requestId": "req-017" }
```

#### GET /farms/{farmId}/livestock/{livestockId}

牲畜详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-018", "data": { "id": "101", "livestockCode": "LIV-1-001", ... } }
```

#### PUT /farms/{farmId}/livestock/{livestockId}

更新牲畜信息。权限: owner。

```
Request:
{ "breed": "安格斯牛（纯种）", "weight": 460.00, "healthStatus": "warning" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-019", "data": { "id": "101", "breed": "安格斯牛（纯种）", ... } }
```

#### DELETE /farms/{farmId}/livestock/{livestockId}

删除牲畜（软删除，设置 status = removed）。权限: owner。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-020" }

Error 410:
{ "code": "RESOURCE_DELETED", "message": "该牲畜已删除", "requestId": "req-020" }
```

### 3.2 围栏 — 5 端点

#### GET /farms/{farmId}/fences

围栏列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-021",
  "data": {
    "items": [
      {
        "id": "301",
        "farmId": "1",
        "name": "北区围栏",
        "vertices": [
          { "lng": 112.8500, "lat": 28.2440 },
          { "lng": 112.8550, "lat": 28.2440 },
          { "lng": 112.8550, "lat": 28.2480 },
          { "lng": 112.8500, "lat": 28.2480 }
        ],
        "color": "#4CAF50",
        "status": "active"
      }
    ],
    "page": 1, "pageSize": 20, "total": 5
  }
}
```

#### POST /farms/{farmId}/fences

创建围栏。权限: owner。

```
Request:
{ "name": "东区围栏", "vertices": [{ "lng": 112.8560, "lat": 28.2440 }, { "lng": 112.8600, "lat": 28.2440 }, { "lng": 112.8600, "lat": 28.2480 }, { "lng": 112.8560, "lat": 28.2480 }], "color": "#2196F3" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-022", "data": { "id": "302", "name": "东区围栏", ... } }

Error 403:
{ "code": "QUOTA_EXCEEDED", "message": "围栏数量已达上限", "requestId": "req-022" }
```

#### GET /farms/{farmId}/fences/{fenceId}

围栏详情（含坐标点）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-023", "data": { "id": "301", "name": "北区围栏", "vertices": [...], ... } }
```

#### PUT /farms/{farmId}/fences/{fenceId}

更新围栏。权限: owner。

```
Request:
{ "name": "北区围栏（扩建）", "vertices": [{ "lng": 112.8490, "lat": 28.2430 }, ...], "color": "#FF5722" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-024", "data": { "id": "301", "name": "北区围栏（扩建）", ... } }
```

#### DELETE /farms/{farmId}/fences/{fenceId}

删除围栏。权限: owner。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-025" }
```

#### PUT /farms/{farmId}/fences/{fenceId}/force

强制更新围栏（绕过乐观锁，平台管理员专用）。当普通 PUT 因版本冲突（`STATE_CONFLICT`）失败时使用。

```
Request:
{ "version": 3, "vertices": [{ "lng": 112.8490, "lat": 28.2430 }], "name": "北区围栏（强制更名）", "color": "#FF5722" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-025a", "data": { "id": "301", "name": "北区围栏（强制更名）", "version": 4, "active": true, "fenceType": "sub" } }
```

> 权限: `PLATFORM_ADMIN`（`@PreAuthorize`）；`version` 必填（缺失 NPE）；`vertices` 元素支持 `lat/lng` 或 `latitude/longitude`。

### 3.3 告警 — 7 端点

#### GET /farms/{farmId}/alerts

告警列表。筛选: `?status=pending&severity=critical&startTime=2026-05-01T00:00:00.000Z&endTime=2026-05-07T23:59:59.000Z`。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-026",
  "data": {
    "items": [
      {
        "id": "501",
        "farmId": "1",
        "livestockId": "101",
        "livestockCode": "LIV-1-001",
        "fenceId": "301",
        "fenceName": "北区围栏",
        "type": "fence_breach",
        "status": "pending",
        "severity": "warning",
        "message": "牛只 LIV-1-001 越出北区围栏",
        "createdAt": "2026-05-07T10:25:00.000Z"
      }
    ],
    "page": 1, "pageSize": 20, "total": 8
  }
}
```

#### GET /farms/{farmId}/alerts/{alertId}

告警详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-027", "data": { "id": "501", "type": "fence_breach", "status": "pending", "acknowledgedBy": null, "acknowledgedAt": null, "handledBy": null, "handledAt": null, ... } }
```

#### POST /farms/{farmId}/alerts/{alertId}/acknowledge

确认告警（pending → acknowledged）。权限: owner/worker。记录操作人和时间戳。

```
Request: (empty body — 操作人从 JWT 提取)

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-028", "data": { "id": "501", "status": "acknowledged", "acknowledgedBy": "42", "acknowledgedAt": "2026-05-07T10:30:00.000Z" } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "只有 pending 状态的告警可以确认", "requestId": "req-028" }
```

#### POST /farms/{farmId}/alerts/{alertId}/handle

处理告警（acknowledged → handled）。权限: owner。记录操作人和时间戳。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-029", "data": { "id": "501", "status": "handled", "handledBy": "42", "handledAt": "2026-05-07T10:45:00.000Z" } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "只有 acknowledged 状态的告警可以处理", "requestId": "req-029" }
```

#### POST /farms/{farmId}/alerts/{alertId}/archive

归档告警（handled → archived）。权限: owner。记录操作人和时间戳。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-030", "data": { "id": "501", "status": "archived", ... } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "只有 handled 状态的告警可以归档", "requestId": "req-030" }
```

#### POST /farms/{farmId}/alerts/batch-handle

批量处理告警。权限: owner。

```
Request:
{ "alertIds": ["501", "502", "503"] }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-031", "data": { "handledCount": 3 } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "告警 502 不是 acknowledged 状态", "requestId": "req-031" }
```

> ⚠️ **V26 告警状态机变迁**：上方 acknowledge/handle/archive/batch-handle 为 **legacy 端点**（`@Deprecated` 但仍可调用），其中 acknowledge 内部委派 markRead、handle 委派 dismissAlert。实际状态机已从旧的 `pending → acknowledged → handled → archived` 改为通知中心模型 **`ACTIVE → DISMISSED / AUTO_RESOLVED`**（`AlertStatus` 枚举仅这 3 值）。推荐使用下方新端点。

#### POST /farms/{farmId}/alerts/{alertId}/read

标记单条告警已读。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-031a", "data": { "id": 501, "status": "ACTIVE", "read": true, "type": "FENCE_BREACH", "severity": "WARNING" } }
```

#### POST /farms/{farmId}/alerts/{alertId}/dismiss

驳回告警（ACTIVE → DISMISSED）。权限: owner / B2B_ADMIN。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-031b", "data": { "id": 501, "status": "DISMISSED", "resolvedType": "DISMISSED", "resolvedAt": "2026-05-07T10:45:00Z" } }
```

#### POST /farms/{farmId}/alerts/batch-read

批量标记已读。

```
Request:
{ "alertIds": ["501", "502", "503"] }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-031c", "data": { "count": 3 } }
```

> `alertIds` 必填（空 → `VALIDATION_ERROR`）；`count` 为实际成功标记数。

### 3.4 重点监测区（FenceZone）— 2 端点

> 围栏内的重点监测区域（如水源点、饲喂区），与 Fence 缓冲区（buffer）是不同概念。仅 2 端点（无单查/更新/删除）。

#### GET /farms/{farmId}/fence-zones

列出重点监测区。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-031d",
  "data": {
    "items": [ { "id": 401, "fenceId": 301, "farmId": 1, "name": "饮水点A", "zoneType": "WATER_SOURCE", "vertices": [{ "lng": 112.85, "lat": 28.24 }], "alertRadius": 30, "severity": "WARNING", "active": true } ]
  }
}
```

#### POST /farms/{farmId}/fence-zones

创建重点监测区。权限: owner / B2B_ADMIN。

```
Request:
{ "fenceId": 301, "name": "饮水点A", "zoneType": "WATER_SOURCE", "vertices": [{ "lng": 112.85, "lat": 28.24 }], "alertRadius": 30, "severity": "WARNING" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-031e", "data": { "id": 401, "fenceId": 301, "name": "饮水点A", "zoneType": "WATER_SOURCE", "alertRadius": 30, "severity": "WARNING", "active": true } }
```

> `fenceId` 必填（缺失 NPE）；`alertRadius` 默认 20；`severity` 默认 "INFO"，无枚举校验。

---

## 4. 物联网（IoT）

### 4.1 设备 — 6 端点

设备有两个维度状态：
- `status`: 生命周期状态（`inventory` / `active` / `offline` / `decommissioned`）
- `runtimeStatus`: 运行时状态（`online` / `offline` / `low_battery`），由心跳实时更新

#### GET /farms/{farmId}/devices

设备列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-032",
  "data": {
    "items": [
      {
        "id": "201",
        "tenantId": "7",
        "farmId": "1",
        "deviceCode": "DEV-2026-00001",
        "deviceType": "device_tracker",
        "status": "active",
        "runtimeStatus": "online",
        "batteryLevel": 85,
        "firmwareVersion": "v2.1.3",
        "devEui": "70B3D57ED004A1B2",
        "lastOnlineAt": "2026-05-07T10:29:00.000Z",
        "installedLivestockId": "101",
        "installedLivestockCode": "LIV-1-001"
      }
    ],
    "page": 1, "pageSize": 20, "total": 45
  }
}
```

#### POST /farms/{farmId}/devices

注册设备。权限: owner。

```
Request:
{ "deviceCode": "DEV-2026-00050", "deviceType": "device_tracker", "devEui": "70B3D57ED004A2C3", "firmwareVersion": "v2.1.3" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-033", "data": { "id": "250", "deviceCode": "DEV-2026-00050", "status": "inventory", ... } }
```

#### GET /farms/{farmId}/devices/{deviceId}

设备详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-034", "data": { "id": "201", ... } }
```

#### PUT /farms/{farmId}/devices/{deviceId}

更新设备信息。权限: owner。

```
Request:
{ "deviceCode": "DEV-2026-00001-UPDATED", "firmwareVersion": "v2.1.4" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-035", "data": { "id": "201", ... } }
```

#### PUT /farms/{farmId}/devices/{deviceId}/activate

激活设备（inventory → active）。权限: owner。幂等。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-036", "data": { "id": "201", "status": "active" } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "仅 inventory 状态的设备可激活", "requestId": "req-036" }
```

#### PUT /farms/{farmId}/devices/{deviceId}/decommission

退役设备（→ decommissioned）。权限: owner。幂等。退役后自动卸载关联安装记录。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-037", "data": { "id": "201", "status": "decommissioned" } }
```

### 4.2 设备许可证 — 4 端点

许可证是**租户级资源**（购买方为 tenant，绑定 device + tenant）。挂载在 `/device-licenses`（JWT `tid` 隐式隔离），不走 Farm Scope。原因：(1) 许可证生命周期与具体牧场无关；(2) INVENTORY 设备尚未安装到牧场时无 farm 可挂；(3) 多牧场 owner 需要跨牧场查看许可证汇总。

#### GET /device-licenses

许可证列表（当前租户全部）。权限: owner。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-038",
  "data": {
    "items": [
      { "id": "L-001", "deviceId": "201", "deviceCode": "DEV-2026-00001", "licenseKey": "sl_lic_... (仅显示前缀)", "status": "active", "activatedAt": "2026-04-01T00:00:00.000Z", "expiresAt": "2027-04-01T00:00:00.000Z" }
    ],
    "page": 1, "pageSize": 20, "total": 10
  }
}
```

#### GET /device-licenses/{licenseId}

许可证详情。权限: owner。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-039", "data": { "id": "L-001", "licenseKey": "sl_lic_... (仅显示前缀)", ... } }
```

#### POST /device-licenses

申请许可证（绑定到指定设备）。权限: owner。

```
Request:
{ "deviceId": "250", "expiresAt": "2027-05-07T00:00:00.000Z" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-040", "data": { "id": "L-011", "licenseKey": "sl_lic_a1b2c3...", ... } }

Error 403:
{ "code": "QUOTA_EXCEEDED", "message": "许可证数量已达上限", "requestId": "req-040" }
```

#### PUT /device-licenses/{licenseId}/revoke

撤销许可证（→ revoked）。权限: owner。幂等。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-041", "data": { "id": "L-001", "status": "revoked" } }

Error 409:
{ "code": "STATE_CONFLICT", "message": "许可证已被撤销", "requestId": "req-041" }
```

### 4.3 安装记录 — 4 端点

#### GET /farms/{farmId}/installations

安装记录列表。权限: owner/worker。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-042",
  "data": {
    "items": [
      { "id": "IN-001", "deviceId": "201", "deviceCode": "SN-TRK-00001", "livestockId": "101", "livestockCode": "LIV-1-001", "installedAt": "2026-04-15T09:00:00.000Z", "removedAt": null, "operatorId": "42", "operatorName": "张三" }
    ],
    "page": 1, "pageSize": 20, "total": 15
  }
}
```

#### POST /farms/{farmId}/installations

安装设备到牲畜。权限: owner。

安装前校验:
1. device 存在且属于当前租户
2. device.status == active
3. device 关联的许可证有效（未过期、未撤销）
4. livestock 存在且属于当前农场
5. 该设备未被其他牲畜安装（removedAt IS NULL）
6. 该牲畜未安装其他同类型设备

```
Request:
{ "deviceId": "250", "livestockId": "150" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-043", "data": { "id": "IN-016", "deviceId": "250", "livestockId": "150", "installedAt": "2026-05-07T11:00:00.000Z" } }

Error 409:
{ "code": "DEVICE_NOT_ACTIVE", "message": "设备未激活，无法安装", "requestId": "req-043" }
Error 403:
{ "code": "LICENSE_EXPIRED", "message": "设备许可证已过期", "requestId": "req-043" }
Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "该设备已安装在其他牲畜上", "requestId": "req-043" }
```

#### GET /farms/{farmId}/installations/{installationId}

安装记录详情。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-044", "data": { "id": "IN-001", ... } }
```

#### PUT /farms/{farmId}/installations/{installationId}/uninstall

拆卸设备。权限: owner。幂等。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-045", "data": { "id": "IN-001", "removedAt": "2026-05-07T12:00:00.000Z" } }
```

### 4.4 GPS 定位 — 2 端点

#### GET /farms/{farmId}/gps-logs/latest

全场最新 GPS 坐标（每头已安装追踪器的牲畜取最新一条 GPS 记录）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-046",
  "data": {
    "items": [
      { "deviceId": "201", "livestockId": "101", "livestockCode": "LIV-1-001", "lng": 112.8521004, "lat": 28.2459123, "accuracy": 3.50, "recordedAt": "2026-05-07T10:25:00.000Z" }
    ]
  }
}
```

#### GET /farms/{farmId}/livestock/{livestockId}/gps-logs

单牲畜 GPS 历史轨迹。`?startTime=2026-05-01T00:00:00.000Z&endTime=2026-05-07T23:59:59.000Z&page=1&pageSize=100`。

实现路径: livestock → installation → device → gps_logs（通过 livestockId 找到当前安装的设备，再查该设备的 gps_logs）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-047",
  "data": {
    "items": [
      { "lng": 112.8515000, "lat": 28.2451000, "accuracy": 5.00, "recordedAt": "2026-05-07T09:00:00.000Z" },
      { "lng": 112.8520000, "lat": 28.2455000, "accuracy": 4.20, "recordedAt": "2026-05-07T09:15:00.000Z" },
      { "lng": 112.8521004, "lat": 28.2459123, "accuracy": 3.50, "recordedAt": "2026-05-07T10:25:00.000Z" }
    ],
    "page": 1, "pageSize": 100, "total": 48
  }
}
```

---

## 5. 读模型（Read Models）— 2 端点

### GET /farms/{farmId}/dashboard/summary

看板汇总。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-048",
  "data": {
    "livestockCount": 120,
    "onlineDeviceCount": 42,
    "activeAlertCount": 8,
    "fenceCount": 5,
    "healthSummary": { "healthy": 110, "warning": 8, "critical": 2 }
  }
}
```

### GET /farms/{farmId}/map/overview

地图总览（牲畜实时位置 + 围栏轮廓 + 告警标记）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-049",
  "data": {
    "livestock": [
      { "id": "101", "livestockCode": "LIV-1-001", "lng": 112.8521004, "lat": 28.2459123, "healthStatus": "healthy", "alertCount": 0 }
    ],
    "fences": [
      { "id": "301", "name": "北区围栏", "vertices": [...], "color": "#4CAF50" }
    ],
    "alerts": [
      { "id": "501", "type": "fence_breach", "severity": "warning", "lng": 112.853000, "lat": 28.249000 }
    ]
  }
}
```

### GET /farms/{farmId}/ranch-overview

牧场总览聚合（统计 + 场景汇总 + 待办 + 围栏 + 牲畜标记 + 告警 + 围栏/健康维度汇总 + 监测区；单端点聚合 Dashboard/Map/Health 等读模型）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-049a",
  "data": {
    "overallStats": { "totalLivestock": 120, "healthyRate": 0.92, "alertCount": 8, "criticalCount": 2, "deviceOnlineRate": 0.85, "inFenceRate": 0.95 },
    "sceneSummary": {
      "fever": { "abnormalCount": 5, "criticalCount": 2 },
      "digestive": { "abnormalCount": 1, "watchCount": 3 },
      "estrus": { "highScoreCount": 4 },
      "epidemic": { "abnormalRate": 0.03 }
    },
    "pendingTasks": [ { "id": "fever-101", "title": "LIV-1-001 体温危急", "subtitle": "41.2°C", "routePath": "fever", "severity": "High" } ],
    "fences": [ { "id": 301, "name": "北区围栏", "active": true, "type": "sub", "color": "#4CAF50", "points": [], "areaHectares": 5.0, "livestockCount": 80, "version": 3 } ],
    "livestockMarkers": [ { "livestockId": "101", "livestockCode": "LIV-1-001", "latitude": 28.2459, "longitude": 112.8521, "healthStatus": "healthy", "primaryAlert": null } ],
    "alerts": [ { "id": 501, "type": "FENCE_BREACH", "severity": "WARNING", "status": "ACTIVE", "message": "越界", "livestockId": 101, "fenceId": 301, "occurredAt": "2026-05-07T10:25:00Z", "read": false, "distance": 120.5, "direction": "north" } ],
    "fenceAlertSummary": { "301": 3 },
    "healthAlertSummary": { "TEMPERATURE_ABNORMAL": 2 },
    "fenceZones": [ { "id": 401, "fenceId": 301, "name": "饮水点A", "zoneType": "WATER_SOURCE", "vertices": [], "alertRadius": 30, "severity": "WARNING", "active": true } ]
  }
}
```

> 权限: 已认证，`verifyFarmOwnership` 校验（farm 不存在 → `RESOURCE_NOT_FOUND`；跨租户 → `AUTH_FORBIDDEN`）。为前端牧场首页提供一次性聚合（替代分别调 dashboard/map/health 多端点）。

---

## 6. 商业（Commerce）— 9 端点（Phase 2a）

> **权限**: 仅需已认证（JWT 解析出 tenantId），无角色限制；数据按 tenantId 隔离。
> 含 SubscriptionController（订阅自助，6 端点）与 CommerceController（合作方合同/分润视角，3 端点）。
> 金额单位均为**分**（cents）。

### GET /subscription

当前租户的订阅信息。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c1",
  "data": {
    "id": 801, "tenantId": 7, "tier": "STANDARD",
    "billingModel": "direct", "status": "ACTIVE", "billingCycle": "monthly",
    "startedAt": "2026-05-01T00:00:00Z", "expiresAt": "2026-06-01T00:00:00Z",
    "trialEndsAt": null, "cancelledAt": null,
    "effectiveTier": "STANDARD"
  }
}

Error 404:
{ "code": "SUBSCRIPTION_NOT_FOUND", "message": "Subscription not found for tenant: 7", "requestId": "req-c1" }
```

### GET /subscription/plans

各 Tier 定价目录（硬编码自 `SubscriptionTier` 枚举）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c2",
  "data": [
    { "tier": "BASIC", "monthlyPriceCents": 0, "includedLivestock": 50, "overagePriceCents": 40 },
    { "tier": "STANDARD", "monthlyPriceCents": 1400, "includedLivestock": 200, "overagePriceCents": 30 },
    { "tier": "PREMIUM", "monthlyPriceCents": 2800, "includedLivestock": 1000, "overagePriceCents": 15 },
    { "tier": "ENTERPRISE", "monthlyPriceCents": -1, "includedLivestock": -1, "overagePriceCents": -1 }
  ]
}
```

> ENTERPRISE 为定制价（字段 -1），对其调用计费接口返回 `ENTERPRISE_CUSTOM_PRICING`（400）。

### POST /subscription/checkout

结账/升级订阅。`tier`、`billingCycle` 均必填。

```
Request:
{ "tier": "PREMIUM", "billingCycle": "monthly" }

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c3",
  "data": { "id": 801, "tenantId": 7, "tier": "PREMIUM", "status": "ACTIVE", "billingCycle": "monthly", "effectiveTier": "PREMIUM", "...": "..." }
}

Error 400:
{ "code": "INVALID_BILLING_MODEL", "message": "Unsupported billing cycle: weekly", "requestId": "req-c3" }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot changeTier: current status is SUSPENDED", "requestId": "req-c3" }
```

### PUT /subscription/tier

升级订阅等级。`tier` 必填；`billingCycle` 可省略（回退到订阅现有值）。

```
Request:
{ "tier": "PREMIUM" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-c4", "data": { "...SubscriptionResponse": "..." } }
```

### POST /subscription/cancel

取消订阅（仅 ACTIVE / TRIAL 可调）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c5",
  "data": { "id": 801, "tier": "STANDARD", "status": "CANCELLED", "cancelledAt": "2026-05-20T00:00:00Z", "...": "..." }
}

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot cancel: current status is CANCELLED", "requestId": "req-c5" }
```

### GET /subscription/usage

订阅用量摘要。查询参数 `featureKey`（可选）：非空且订阅激活、对应 gate 为 FILTER 时返回 `retentionDays`。

```
Response 200（有订阅）:
{
  "code": "OK", "message": "success", "requestId": "req-c6",
  "data": {
    "subscriptionId": 801, "tier": "STANDARD", "status": "ACTIVE",
    "effectiveTier": "STANDARD", "includedLivestock": 200, "overagePriceCents": 30,
    "retentionDays": 30
  }
}

Response 200（无订阅）:
{ "code": "OK", "message": "success", "requestId": "req-c6", "data": { "tier": "BASIC", "status": "FREE" } }
```

> `effectiveTier`：试用期内返回 `PREMIUM`（试用享高级），否则为实际 tier。

### GET /contracts/me

当前租户合同（合作方视角，分润模式下查看自己的合同）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c7",
  "data": {
    "id": 901, "tenantId": 7, "contractNumber": "CT-2026-001",
    "billingModel": "revenue_share", "effectiveTier": "PREMIUM",
    "revenueShareRatio": 0.15, "status": "ACTIVE",
    "signedBy": 1, "signedAt": "2026-05-01T00:00:00Z",
    "startedAt": "2026-05-01T00:00:00Z", "expiresAt": "2027-05-01T00:00:00Z"
  }
}

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "Contract not found for tenant: 7", "requestId": "req-c7" }
```

### GET /revenue/periods

当前租户的结算周期列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c8",
  "data": [
    {
      "id": 701, "contractId": 901, "tenantId": 7,
      "periodStart": "2026-05-01", "periodEnd": "2026-05-31",
      "grossAmount": 200000, "platformShare": 170000, "partnerShare": 30000,
      "revenueShareRatio": 0.15, "status": "PLATFORM_CONFIRMED", "settledAt": null
    }
  ]
}
```

### POST /revenue/periods/{id}/confirm

合作方确认结算周期（`PLATFORM_CONFIRMED` → `PARTNER_CONFIRMED`）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-c9",
  "data": { "id": 701, "status": "PARTNER_CONFIRMED", "...": "..." }
}

Error 403:
{ "code": "AUTH_FORBIDDEN", "message": "无权操作此结算周期", "requestId": "req-c9" }

Error 409:
{ "code": "STATE_CONFLICT", "message": "Cannot confirmByPartner: expected PLATFORM_CONFIRMED but was PENDING", "requestId": "req-c9" }
```

> 三步对账：`PENDING` →（平台 confirm）→ `PLATFORM_CONFIRMED` →（合作方 confirm，本端点）→ `PARTNER_CONFIRMED` →（settle）→ `SETTLED`。settle 由 Admin 端或调度触发。

---

## 7. 健康分析（Health）— 15 端点（Phase 2b）

> **基路径**: `/api/v1/farms/{farmId}/health`（5 个 Controller 共用）。除标注外均为 GET。
>
> **权限与 Farm Scope**：Health Controller **无 `@PreAuthorize`**，访问控制由全局 `FarmScopeInterceptor` 统一处理 —— GET 为 READ scope（path 或 `x-active-farm` header 二选一，同时给则 409 `FARM_SCOPE_CONFLICT`），POST/DELETE 为 WRITE scope（必须走 path farmId）。OWNER/WORKER/B2B_ADMIN 仅可访问本租户 farm，PLATFORM_ADMIN 可跨租户。
>
> ⚠️ **实现注意（如实在契约中标注）**：
> 1. 服务层方法虽接收 `farmId`，但**未用它过滤 livestock 归属**（如 `getFeverDetail(farmId, livestockId)` 仅按 livestockId 查），存在跨 farm 查到他人牲畜的潜在越权点。
> 2. 数据保留窗口受订阅 tier 的 feature gate 控制：fever detail 硬上限 **72h**、digestive detail 硬上限 **24h**；`health_score`/`estrus_detect` feature 未启用时，对应图表端点**不报错**，返回 `[]` 或 `null`。
> 3. `/health/stats` 的三条 7 天趋势曲线当前由 `Math.random()` 生成，**非真实聚合数据**；`/health/overview` 的 `deviceOnlineRate`/`healthTrend`/`livestockTrend` 为硬编码占位。
> 4. snapshot 不存在的 detail 端点返回占位（`status="NORMAL"`、`"暂无数据"`、空数组），不报错。

**关键阈值**（来自代码常量）：体温基线 38.5°C；FEVER delta 1.0/1.5，CRITICAL delta 2.0 或绝对 ≥41.0°C，持续 2h 升级；蠕动基线 3.0，LOW 比值 0.7、ABNORMAL 比值 0.5；发情 score = step×0.4 + temp×0.3 + distance×0.3，≥70 建议配种；疫情 abnormalRate >0.15 警戒 / >0.05 关注。

### GET /farms/{farmId}/health/overview

健康总览（统计 + 四场景汇总 + 待办任务）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h1",
  "data": {
    "stats": {
      "totalLivestock": 120, "healthyRate": 0.92, "alertCount": 8,
      "criticalCount": 2, "deviceOnlineRate": 0.92, "healthTrend": "稳定", "livestockTrend": "↑2"
    },
    "sceneSummary": {
      "fever": { "abnormalCount": 5, "criticalCount": 2 },
      "digestive": { "abnormalCount": 1, "watchCount": 3 },
      "estrus": { "highScoreCount": 4, "breedingAdvice": true },
      "epidemic": { "status": "正常", "abnormalRate": 0.03 }
    },
    "pendingTasks": [
      { "id": "fever-101", "title": "LIV-1-001 体温危急", "subtitle": "41.2°C", "routePath": "fever", "severity": "High" }
    ]
  }
}
```

> `deviceOnlineRate`/`healthTrend`/`livestockTrend` 当前为硬编码占位；`pendingTasks` 仅对 CRITICAL 温度或 ABNORMAL 蠕动的牲畜生成。

### GET /farms/{farmId}/health/stats

健康统计（7 天趋势 + 分布）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h2",
  "data": {
    "summary": { "totalLivestock": 120, "healthyRate": 0.92, "alertCount": 8, "criticalCount": 2, "avgTemperature": 38.6, "avgMotility": 3.1 },
    "temperatureTrend": [ { "date": "2026-05-15", "value": 38.6 } ],
    "healthRateTrend": [ { "date": "2026-05-15", "value": 0.92 } ],
    "alertTrend": [ { "date": "2026-05-15", "value": 8.0 } ],
    "healthDistribution": { "healthy": 110, "warning": 8, "critical": 2 }
  }
}
```

> ⚠️ 三条 7 天趋势曲线当前由 `Math.random()` 生成，非真实数据；`healthDistribution` 键为 `healthy`/`warning`/`critical`。

### GET /farms/{farmId}/health/fever

发热牲畜列表（仅返回 `TempStatus != NORMAL`，即 ELEVATED/FEVER/CRITICAL）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h3",
  "data": {
    "items": [
      { "livestockId": "101", "livestockCode": "LIV-1-001", "breed": "安格斯牛",
        "baselineTemp": 38.5, "currentTemp": 40.2, "delta": 1.7, "status": "FEVER",
        "conclusion": "体温偏高，建议隔离观察" }
    ]
  }
}
```

### GET /farms/{farmId}/health/fever/{livestockId}

发热详情（基线/当前/delta/状态/结论/近期温度序列）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h4",
  "data": {
    "livestockId": "101", "livestockCode": "LIV-1-001",
    "baselineTemp": 38.5, "currentTemp": 40.2, "status": "FEVER",
    "conclusion": "体温偏高，建议隔离观察",
    "recent72h": [ { "temperature": 40.2, "timestamp": "2026-05-20T10:00:00Z" } ]
  }
}
```

> `recent72h` 实际窗口 = `min(retentionDays("temperature_monitor") × 24, 72)` 小时（硬上限 72h）；snapshot 不存在时返回占位 `status="NORMAL"`、`conclusion="暂无数据"`、`recent72h=[]`。

### GET /farms/{farmId}/health/fever/{livestockId}/duration

发热持续时长图（按日累计发热小时数）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h5",
  "data": [ { "date": "2026-05-20", "hours": 3.5 }, { "date": "2026-05-19", "hours": 2.0 } ]
}
```

> Feature gate `health_score` 未启用 → 返回 `[]`（不报错）。窗口 = `min(retentionDays("health_score"), 7)` 天；温度 > 39.5°C（基线+1.0）的每条日志按 0.5 小时累计。

### GET /farms/{farmId}/health/estrus

发情评分列表（每头牲畜最新评分，score > 0，按 score 降序）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h6",
  "data": {
    "items": [
      { "livestockId": "101", "livestockCode": "LIV-1-001", "breed": "安格斯牛", "gender": "母",
        "score": 78, "stepIncreasePercent": 320, "tempDelta": 0.6, "distanceDelta": 2200,
        "timestamp": "2026-05-20T08:00:00Z", "advice": "High estrus，建议 12h 内配种" }
    ]
  }
}
```

### GET /farms/{farmId}/health/estrus/{livestockId}

发情详情（最新评分 + 三维子分 + 近 7 条趋势）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h7",
  "data": {
    "livestockId": "101", "livestockCode": "LIV-1-001",
    "score": 78, "stepIncreasePercent": 320, "tempDelta": 0.6, "distanceDelta": 2200,
    "timestamp": "2026-05-20T08:00:00Z", "advice": "High estrus，建议 12h 内配种",
    "trend7d": [ { "score": 78, "timestamp": "2026-05-20T08:00:00Z" }, { "score": 55, "timestamp": "2026-05-19T08:00:00Z" } ]
  }
}
```

> 评分公式：`score = stepScore×0.4 + tempScore×0.3 + distanceScore×0.3`。触发需近 7 条 activity（≥3）+ 近 7 条 temperature（≥2），数据不足时不评分，查询返回 `score=0, advice="Not in estrus", trend7d=[]`。

### GET /farms/{farmId}/health/estrus/{livestockId}/activity

活动量对比（近 24h vs 前 24h）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h8",
  "data": {
    "recentSteps": 8500, "baselineSteps": 2100,
    "recentDistance": 3200.0, "baselineDistance": 800.0,
    "recentActivityIndex": 95.5, "baselineActivityIndex": 35.2
  }
}
```

> Feature gate `estrus_detect` 未启用 → `data` 为 `null`（字段因 `@JsonInclude(NON_NULL)` 不出现，仅返回 code/message/requestId）。

### GET /farms/{farmId}/health/digestive

消化异常牲畜列表（仅返回 `MotilityStatus != NORMAL`，即 LOW/ABNORMAL）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h9",
  "data": {
    "items": [
      { "livestockId": "102", "livestockCode": "LIV-1-002", "breed": "西门塔尔牛",
        "motilityBaseline": 3.0, "currentFrequency": 1.2, "status": "ABNORMAL",
        "advice": "蠕动异常偏低，建议检查饲料与饮水" }
    ]
  }
}
```

### GET /farms/{farmId}/health/digestive/{livestockId}

消化详情（基线/状态/建议/近期蠕动序列）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h10",
  "data": {
    "livestockId": "102", "livestockCode": "LIV-1-002",
    "motilityBaseline": 3.0, "status": "ABNORMAL", "advice": "蠕动异常偏低，建议检查饲料与饮水",
    "recent24h": [ { "frequency": 1.2, "intensity": 25.0, "timestamp": "2026-05-20T10:00:00Z" } ]
  }
}
```

> `recent24h` 实际窗口 = `min(retentionDays("peristaltic_monitor") × 24, 24)` 小时（硬上限 24h）；snapshot 不存在返回占位 `status="NORMAL"`、`advice="暂无数据"`。

### GET /farms/{farmId}/health/digestive/{livestockId}/heatmap

消化强度热力图（24 小时分布）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h11",
  "data": [
    { "hour": 0, "intensity": 28.5, "abnormal": true },
    { "hour": 1, "intensity": 0.0, "abnormal": false }
  ]
}
```

> 固定 24 元素（0-23 点）；Feature gate `health_score` 未启用 → 返回 `[]`（非 24 元素）。`abnormal` = `intensity > 0 && intensity < 30.0`。

### GET /farms/{farmId}/health/epidemic

疫情总览（群体指标 + 接触记录 + 风险等级）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h12",
  "data": {
    "metrics": { "avgTemperature": 38.6, "avgActivity": 0, "abnormalRate": 0.03, "totalLivestock": 120, "abnormalCount": 4 },
    "contacts": [
      { "fromId": "101", "fromCode": "LIV-1-001", "toId": "102", "toCode": "LIV-1-002", "proximity": 3.5, "lastContact": "2026-05-20T09:00:00Z" }
    ],
    "riskLevel": "正常"
  }
}
```

> `riskLevel`：abnormalRate > 0.15 → "警戒"；> 0.05 → "关注"；否则 "正常"。`contacts` 仅取前 20 条。`avgActivity` 当前恒为 0（实现传入 ZERO）。

### GET /farms/{farmId}/health/epidemic/contacts/{livestockId}

接触网络（源牲畜的接触图谱 + 三维风险评分）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-h13",
  "data": {
    "sourceLivestockId": "101", "sourceLivestockCode": "LIV-1-001", "diseaseType": "口蹄疫", "markedAt": "2026-05-20T00:00:00Z",
    "contacts": [
      { "livestockId": "102", "livestockCode": "LIV-1-002", "proximityMeters": 3.5, "contactDurationMinutes": 45,
        "lastContactAt": "2026-05-20T09:00:00Z", "hoursAgo": 3, "timeScore": 40, "distanceScore": 35, "durationScore": 25,
        "totalRiskScore": 100, "riskLevel": "HIGH" }
    ]
  }
}
```

> 仅保留近 72h 接触。三维评分：time（≤24h→40/≤48h→25/其余→12）+ distance（<5m→35/<15m→25/<30m→15/其余→5）+ duration（>30min→25/>15→18/>5→10/其余→3）；total ≥ 70 HIGH / ≥ 40 MEDIUM / 否则 LOW。

### POST /farms/{farmId}/health/epidemic/mark

标记病畜（将该牲畜作为源的所有接触记录打上 diseaseType）。

```
Request:
{ "livestockId": 101, "diseaseType": "口蹄疫" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-h14" }
```

> WRITE scope，必须走 path farmId。无 ContactTrace 记录则静默无操作（仍 200，`data=null`）。

### DELETE /farms/{farmId}/health/epidemic/mark/{livestockId}

取消病畜标记（清除 diseaseType / markedAt）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-h15" }
```

> WRITE scope；无 trace 则静默无操作。

---

## 8. B 端管理后台（B2bController）— 12 端点（Phase 2c）

> **基路径**: `/api/v1/b2b`。**权限**: 需 `ROLE_B2B_ADMIN`（方法体内 `requireB2bAdmin()` 校验，非 `@PreAuthorize` 注解；缺失 → `AUTH_FORBIDDEN` / 403）。
>
> ⚠️ **实现注意**：所有响应为内联 `Map`（无独立 DTO）；`dashboard` 的 `contractExpiresAt` 实际写入的是合同 `startDate`（字段名误导），`region` 恒为空串、`monthlyRevenue`/`deviceOnlineRate` 恒为 0（占位）；移除牧工为**软删除**（status → DISABLED）。

### GET /b2b/dashboard

B 端控制台概览（牧场/牲畜/设备/牧工/告警汇总 + 农场列表 + 待处理告警）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-b1",
  "data": {
    "totalFarms": 3, "totalLivestock": 240, "totalDevices": 80, "totalWorkers": 6, "pendingAlerts": 4,
    "farms": [
      { "id": 1, "name": "示范牧场", "status": "active", "ownerName": "张三", "livestockCount": 120, "workerCount": 3, "deviceCount": 40, "region": "", "latitude": 28.24, "longitude": 112.85, "areaHectares": 50.0 }
    ],
    "alertSummary": [
      { "farmId": 1, "farmName": "示范牧场", "severity": "WARNING", "type": "FENCE_BREACH", "message": "LIV-1-001 越界", "livestockId": 101 }
    ],
    "contractStatus": "ACTIVE", "contractExpiresAt": "2026-05-01T00:00:00Z",
    "billingModel": null, "partnerName": null, "monthlyRevenue": 0.0, "deviceOnlineRate": 0.0
  }
}
```

> `contractExpiresAt` 实为合同 `startDate`（代码 bug）；合同/告警查询异常被吞，无合同时相关字段为 `null`。

### GET /b2b/contract

当前合同与订阅信息。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-b2",
  "data": {
    "id": "901", "status": "ACTIVE", "effectiveTier": "ACTIVE", "revenueShareRatio": 0.15,
    "startedAt": "2026-05-01T00:00:00Z", "expiresAt": "2027-05-01T00:00:00Z", "signedBy": null,
    "billingModel": "合作伙伴A", "contractId": "合作伙伴A", "serviceTier": "ACTIVE", "serviceStatus": "ACTIVE"
  }
}
```

> ⚠️ 此端点字段多处占位：`effectiveTier`/`serviceTier` 实为 status、`billingModel`/`contractId` 实为 partnerName。无合同时返回部分字段或空 map。

### GET /b2b/farms

列出租户所有牧场（含统计）。无分页。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-b3",
  "data": {
    "items": [ { "id": "1", "name": "示范牧场", "workerCount": 3, "livestockCount": 120, "deviceCount": 40, "latitude": 28.24, "longitude": 112.85, "areaHectares": 50.0 } ],
    "totalWorkers": 6, "offlineWorkerCount": 0
  }
}
```

### GET /b2b/farms/{farmId}/workers

列出指定牧场 ACTIVE 成员。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-b4",
  "data": { "items": [ { "id": "201", "role": "WORKER", "status": "ACTIVE", "assignedAt": "2026-05-01T00:00:00Z", "name": "李四", "phone": "13900000001" } ], "total": 3 }
}

Error 403:
{ "code": "AUTH_FORBIDDEN", "message": "无权访问该牧场", "requestId": "req-b4" }
```

### POST /b2b/farms/{farmId}/workers

分配牧工到牧场。

```
Request:
{ "workerId": 201 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-b5", "data": { "userId": 201, "farmId": 1, "role": "WORKER" } }

Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "牧工已在该牧场中", "requestId": "req-b5" }
```

> 校验：`workerId` 必填；用户不存在 → 404；跨租户 → `AUTH_FORBIDDEN` "不能跨租户分配牧工"。

### DELETE /b2b/farms/{farmId}/workers/{workerId}

移除牧工（软删除，status → DISABLED，非物理删除）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-b6" }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "该牧工不在此牧场中", "requestId": "req-b6" }
```

### GET /b2b/available-workers

可分配（未占用）的 worker 列表。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-b7",
  "data": { "items": [ { "id": "202", "name": "王五", "role": "worker", "status": "active", "phone": "13900000002" } ], "total": 2 }
}
```

### GET /b2b/users

列出租户所有用户（可选 role 过滤）。无分页。

```
查询参数: role（可选，Role 枚举名如 WORKER/OWNER/B2B_ADMIN，大小写不敏感）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-b8",
  "data": { "items": [ { "id": 201, "name": "李四", "phone": "13900000001", "role": "WORKER" } ], "total": 6 }
}
```

### POST /b2b/users

创建牧工用户（role 固定 WORKER，密码 BCrypt 加密）。

```
Request:
{ "phone": "13900000003", "name": "赵六", "password": "xxx" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-b9", "data": { "id": "203", "name": "赵六", "phone": "13900000003", "role": "worker" } }

Error 409:
{ "code": "DUPLICATE_RESOURCE", "message": "该手机号已注册", "requestId": "req-b9" }
```

### PUT /b2b/users/{userId}

更新牧工信息（仅可改 WORKER 角色用户；name/phone 可选）。

```
Request:
{ "name": "李四新", "phone": "13900000011" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-b10", "data": { "id": "201", "name": "李四新", "phone": "13900000011", "role": "worker" } }
```

> 校验：用户不存在 → 404；跨租户或非 WORKER 角色 → `AUTH_FORBIDDEN`；phone 改动时查重。

### PUT /b2b/users/{userId}/status

启停牧工。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-b11", "data": { "id": "201", "status": "disabled" } }
```

> `status` 仅识别 `active`/`disabled`；底层调 `user.deactivate()` / `user.activate()`。

### PUT /b2b/users/{userId}/reset-password

重置牧工密码。

```
Request:
{ "password": "newXxx" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-b12" }
```

---

## 9. 设备遥测与事件上报 — 2 端点（Phase 2c）

### POST /farms/{farmId}/telemetry

设备遥测上报（真实数据通道；唯一的 GPS/遥测写入端点）。

```
Request:
{
  "deviceId": 201,
  "readings": [
    { "recordedAt": "2026-05-20T10:00:00Z", "batteryLevel": 85, "latitude": 28.2459, "longitude": 112.8521, "temperature": 38.6, "motilityFrequency": 3.2 }
  ]
}

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-t1", "data": { "deviceId": 201, "processed": 1 } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "设备不存在: 201", "requestId": "req-t1" }

Error 409:
{ "code": "STATE_CONFLICT", "message": "设备未激活: INVENTORY", "requestId": "req-t1" }
```

> ⚠️ **`farmId` 路径变量仅占位，不参与校验** —— 真实 farmId 由 设备 → 安装 → 牲畜 链路解析，客户端传入的 farmId 与设备归属不一致也能成功。
> **readings 透传**：`temperature`/`motilityFrequency`/`activity` 等字段 controller 不校验，全部塞入 `TelemetryReceivedEvent`（发 RocketMQ `telemetry-received`），由 health 消费者按 device_type 分流（CAPSULE → 温度+蠕动+活动；TRACKER → GPS+活动）。仅 TRACKER 的 `latitude`/`longitude` 触发 GPS 日志写入。
> 校验链：设备须 `ACTIVE` 且有活跃安装记录、牲畜存在，否则 404/409。
> ⚠️ 已知行为：单批多 reading 时若某条触发异常会回滚整批事务，但响应的 `processed` 仍在循环内自增（可能误导客户端）。

### POST /analytics/events

前端事件批量上报（瓦片下载/缓存、围栏离线编辑、离线会话等）。

```
Request（顶层为数组）:
[
  { "event": "tile_download_completed", "regionName": "changsha", "bytes": 1048576 },
  { "event": "fence_offline_edit", "fenceId": 301 }
]

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-e1" }

Error 400:
{ "code": "VALIDATION_ERROR", "message": "事件数量超限，最多 100 条", "requestId": "req-e1" }
```

> ⚠️ **不落库，仅 `log.debug`**。事件类型白名单（大小写敏感）：`tile_download_completed/failed/evicted`、`tile_cache_hit/miss`、`fence_sync_conflict`、`fence_offline_edit`、`offline_session`；白名单外事件静默跳过不报错。每请求上限 100 条。

---

## 10. 开发者门户与 API 用量 — 11 端点（Phase 2c）

> **Portal**（`/api/v1/portal/keys`，7 端点）租户自助 API Key 管理；**Analytics 用量**（`/api/v1/analytics/usage`，4 端点）租户查看 API 用量。均无 `@PreAuthorize`，靠 `TenantContext` 隔离，跨租户操作 Key → `AUTH_FORBIDDEN`。
>
> ⚠️ **重要**：API Key **明文从不返回**（所有端点仅返回 `prefix`，含创建时）—— 与"创建时返回一次明文"的常见假设不符。`Portal` 列表为**伪分页**（page/pageSize 仅回显未切片）。Portal 的 usage/dashboard 查询参数 `from`/`to` 未加 `@DateTimeFormat`，Analytics 用量端点则加了（严格 ISO `yyyy-MM-dd`）。

**KeySummary 结构**（所有返回 Key 的端点共用，**不含明文 keyValue/tenantId**）：`id`(Long)、`keyName`(String)、`prefix`(String)、`status`(String：`ACTIVE`/`REVOKED`)、`scopes`(逗号分隔 String)、`requestsPerMinute`(int)、`dailyQuota`(int)、`description`(String)、`createdAt`(ISO-8601)、`lastUsedAt`(ISO-8601)。

### GET /portal/keys

列出当前租户的 API Key。

```
查询参数: page（默认 1）、pageSize（默认 20）—— 均仅回显，未切片

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-p1",
  "data": {
    "items": [ { "id": 301, "keyName": "默认 Key", "prefix": "sl_live_abcd", "status": "ACTIVE", "scopes": "livestock:read,fence:read,alert:read", "requestsPerMinute": 60, "dailyQuota": 20000, "description": "", "createdAt": "2026-05-01T00:00:00Z", "lastUsedAt": "2026-05-20T10:00:00Z" } ],
    "page": 1, "pageSize": 20, "total": 1
  }
}
```

> `total` 等于全量条数（未分页切片）。

### POST /portal/keys

创建 API Key。

```
Request（字段均可选，有默认值）:
{ "name": "移动端 Key", "scopes": "livestock:read,fence:read,alert:read", "requestsPerMinute": 60, "dailyQuota": 20000, "description": "App 用" }

Response 201:
{ "code": "OK", "message": "success", "requestId": "req-p2", "data": { "id": 302, "keyName": "移动端 Key", "prefix": "sl_live_ef01", "...": "..." } }
```

> ⚠️ 响应**不含明文 key**，仅返回 `prefix`（若产品需要一次性下发明文，需改后端）。默认值：name="默认 Key"、scopes="livestock:read,fence:read,alert:read"、rpm=60、dailyQuota=20000。无重复 name 校验、无 rpm/quota 范围校验。

### PUT /portal/keys/{keyId}

更新 Key 名称/描述（仅此两字段可改；rpm/quota/scopes 不可由此端点改）。

```
Request:
{ "name": "重命名 Key", "description": "更新描述" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-p3", "data": { "id": 302, "keyName": "重命名 Key", "description": "更新描述", "...": "..." } }

Error 404:
{ "code": "RESOURCE_NOT_FOUND", "message": "API Key not found", "requestId": "req-p3" }
```

> 跨租户 → `AUTH_FORBIDDEN` "无权操作此 API Key"。

### PUT /portal/keys/{keyId}/status

启停 Key。

```
Request:
{ "status": "disabled" }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-p4", "data": { "id": 302, "status": "REVOKED" } }
```

> `status` 仅识别 `active`/`disabled`；`disabled` 走 `revokeApiKey`（返回 `REVOKED`，语义为吊销），`active` 改回 `ACTIVE`（同一凭据，prefix/secret 不变）。

### DELETE /portal/keys/{keyId}

删除 Key（**物理删除，不可恢复**）。

```
Response 200:
{ "code": "OK", "message": "success", "requestId": "req-p5" }
```

### GET /portal/keys/{keyId}/usage

单 Key 用量总览。

```
查询参数: from、to（LocalDate，yyyy-MM-dd，必填，未加 @DateTimeFormat）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-p6",
  "data": { "totalCalls": 12000, "successCalls": 11950, "errorCalls": 50, "avgResponseMs": 125.5, "from": "2026-05-01", "to": "2026-05-31" }
}
```

### GET /portal/keys/dashboard

租户级用量总览（按 tenantId 聚合，非单 key）。

```
查询参数: from、to（必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-p7", "data": { "totalCalls": 50000, "successCalls": 49800, "errorCalls": 200, "avgResponseMs": 130.0, "from": "2026-05-01", "to": "2026-05-31" } }
```

### GET /analytics/usage/overview

租户级用量总览（按租户+时间区间聚合）。

```
查询参数: from、to（ISO yyyy-MM-dd，必填，@DateTimeFormat ISO.DATE）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-u1", "data": { "totalCalls": 50000, "successCalls": 49800, "errorCalls": 200, "avgResponseMs": 130.0, "from": "2026-05-01", "to": "2026-05-31" } }
```

### GET /analytics/usage/trend

租户级按日趋势。

```
查询参数: from、to（ISO yyyy-MM-dd，必填）

Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-u2",
  "data": [ { "date": "2026-05-20", "totalCalls": 1800, "successCalls": 1790, "errorCalls": 10, "avgResponseMs": 128 } ]
}
```

### GET /analytics/usage/api-keys/{apiKeyId}/overview

单 Key 用量总览。

```
路径变量: apiKeyId；查询参数: from、to（ISO yyyy-MM-dd，必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-u3", "data": { "totalCalls": 12000, "successCalls": 11950, "errorCalls": 50, "avgResponseMs": 125.5, "from": "2026-05-01", "to": "2026-05-31" } }
```

> ⚠️ service 层未显式校验 key 归属，越权 key（非本租户）**不返回 403，而是返回空聚合（全 0）**。

### GET /analytics/usage/api-keys/{apiKeyId}/trend

单 Key 按日趋势。

```
路径变量: apiKeyId；查询参数: from、to（ISO yyyy-MM-dd，必填）

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-u4", "data": [ { "date": "2026-05-20", "totalCalls": 400, "successCalls": 398, "errorCalls": 2, "avgResponseMs": 120 } ] }
```

> 同上，越权 key 返回空列表非 403。

---

## 11. 离线地图瓦片 — 5 端点（Phase 2c）

> **基路径**: `/api/v1/farms/{farmId}`（TileApp 4 端点）+ `/api/v1/farms/{farmId}/offline-map`（TileController 1 端点）。均无 `@PreAuthorize`，靠 farm 所有权校验（`farm.tenantId == currentTenant`）。
>
> ⚠️ **实现注意**：触发任务的 bbox **硬编码**（以牧场坐标为中心 ±0.15 度，约 16km），zoom **固定 11-15**（App 不可配）；`FarmTileStatusDto.coverageRatio` 在 `getFarmTileStatus` 路径下**恒为 0**；`currentTenant==null` 时跳过所有权校验（安全弱化点，与 Portal/Analytics 严格模式不同）。

### POST /farms/{farmId}/tile-tasks

触发离线瓦片生成任务。无请求体（后端按牧场坐标自动算 bbox）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-tl1",
  "data": {
    "farmId": 1,
    "regions": [ { "regionId": 11, "regionName": "custom-farm-1", "status": "pending", "fileSize": null, "fileName": null, "md5": null } ],
    "coverageRatio": 0, "coverageWarning": false
  }
}

Error 400:
{ "code": "VALIDATION_ERROR", "message": "牧场未设置坐标，无法生成离线地图", "requestId": "req-tl1" }
```

> 状态机：若已有相交 TileRegion → 复用（FarmTileTask 置 `ready`/`pending`）；否则新建 custom 任务（regionName=`custom-farm-{farmId}`，minZoom=11，maxZoom=15）。inflight 任务去重不重复创建。

### GET /farms/{farmId}/tile-status

查询瓦片任务状态。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-tl2",
  "data": { "farmId": 1, "regions": [ { "regionId": 11, "regionName": "changsha-z12", "status": "ready", "fileSize": 5242880, "fileName": "changsha.mbtiles", "md5": "a1b2c3d4..." } ], "coverageRatio": 0, "coverageWarning": false }
}
```

### GET /farms/{farmId}/tile-source

获取在线瓦片源 URL（仅返回 status ∈ `ready`/`downloaded` 且 region ready 的源）。

```
Response 200:
{
  "code": "OK", "message": "success", "requestId": "req-tl3",
  "data": [ { "sourceName": "changsha-z12", "tileUrl": "http://172.22.1.123:18080/tiles/changsha-z12/{z}/{x}/{y}.png" } ]
}
```

> `tileUrl` 是**在线瓦片服务 URL 模板**（含 `{z}/{x}/{y}` 占位，非签名下载链接）；base-url 来自配置 `app.tile-server.base-url`（默认 `http://172.22.1.123:18080`）。

### POST /farms/{farmId}/tile-download-log

记录下载行为（不更新 FarmTileTask 状态）。

```
Request:
{ "farmTileTaskId": 21, "userId": 1, "deviceInfo": "iPhone 15", "bytesDownloaded": 5242880 }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-tl4" }
```

> `farmTileTaskId`/`userId` 必填（缺失 NPE）；仅写日志，不把 `ready` 变 `downloaded`。

### GET /farms/{farmId}/offline-map

下载牧场离线地图（mbtiles 文件）。

```
查询参数: regionName（可选，指定区域名，可带或不带 .mbtiles 后缀）

Response 200（非 ApiResponse 信封，直接返回二进制文件流）:
  Content-Type: application/x-sqlite3
  Content-Disposition: attachment; filename="changsha.mbtiles"
  Body: <mbtiles 文件字节>
```

> ⚠️ 此端点**不走 ApiResponse 信封**，直接返回 `FileSystemResource` 文件流；**非预签名 URL、无过期**，靠租户校验 + 路径穿越防御（`normalize()` 后须 `startsWith` tiles 目录）保护。
> 匹配逻辑：传 `regionName` → 先直连 `/data/{name}[.mbtiles]`，找不到再在 `regions.json` 模糊匹配；不传 → 按牧场坐标在 `regions.json` 的 bounds 命中。无命中 → 404 空 body。
> 牧场不存在 → 404；跨租户 → 403。本端点不写下载日志（由 `tile-download-log` 单独上报）。
