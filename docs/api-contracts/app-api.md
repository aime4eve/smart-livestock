# App API 端点（`/api/v1/`）

> **端点总数**: 49
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
