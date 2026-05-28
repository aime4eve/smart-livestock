# 智慧畜牧 App API 契约（Mock 先行版）

## 1. 文档目标
- 服务当前 App 先行开发，先保证前端有稳定契约可依赖。
- 后端未建设期间，`mobile_app` 使用本地 Mock Repository 实现同构数据。
- 后续联调时，后端按本文契约提供 HTTP 接口；前端仅替换 DataSource/Repository 实现。

## 2. 角色与权限

### 2.1 角色枚举
| role | 说明 |
|------|------|
| `owner` | 牧场主，可见业务端全部主流程与租户后台页签 |
| `worker` | 牧工，可见地图/告警/我的/围栏查看，无后台入口 |
| `ops` | 平台运维，仅进入租户后台，不进入牧场业务页面 |

### 2.2 权限码
| permission | 说明 |
|------------|------|
| `dashboard:view` | 查看看板 |
| `map:view` | 查看地图与轨迹 |
| `alert:view` | 查看告警 |
| `alert:ack` | 确认告警 |
| `alert:handle` | 处理告警 |
| `alert:archive` | 归档告警 |
| `alert:batch` | 批量处理告警 |
| `fence:view` | 查看围栏 |
| `fence:manage` | 新增/编辑/删除围栏 |
| `tenant:view` | 查看租户后台 |
| `tenant:create` | 开通租户 |
| `tenant:toggle` | 禁用/启用租户 |
| `license:manage` | 调整 license |
| `profile:view` | 查看我的页 |

## 3. 通用约定

### 3.1 响应包络
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_20260327_xxx",
  "data": {}
}
```

### 3.2 分页结构
列表接口统一使用：
```json
{
  "items": [],
  "page": 1,
  "pageSize": 20,
  "total": 0
}
```

### 3.3 六类界面状态映射
| UI 状态 | HTTP/业务语义 |
|---------|---------------|
| `normal` | 成功返回数据 |
| `loading` | 前端请求中，不对应后端固定响应 |
| `empty` | 成功返回空列表/空结果 |
| `error` | 5xx 或未知异常 |
| `forbidden` | 403 无权限 |
| `offline` | 网络不可用/超时/本地缓存回退 |

### 3.4 错误码
| code | HTTP | 含义 |
|------|------|------|
| `AUTH_UNAUTHORIZED` | 401 | 未登录或 token 失效 |
| `AUTH_FORBIDDEN` | 403 | 无权访问资源 |
| `TENANT_DISABLED` | 403 | 租户已禁用 |
| `RESOURCE_NOT_FOUND` | 404 | 资源不存在 |
| `VALIDATION_ERROR` | 422 | 参数校验失败 |
| `CONFLICT` | 409 | 并发更新冲突 |
| `UPSTREAM_UNAVAILABLE` | 503 | 地图/GPS 上游不可用 |
| `INTERNAL_ERROR` | 500 | 服务内部异常 |

## 4. 鉴权与会话

### 4.1 登录后当前用户信息
- `GET /api/me`
- 角色：已登录用户
- 用途：前端登录后拉取 `role` 与 `permissions`，作为菜单与按钮的单一事实来源

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "userId": "u_001",
    "tenantId": "t_001",
    "name": "张三",
    "role": "owner",
    "permissions": [
      "dashboard:view",
      "map:view",
      "alert:view",
      "alert:ack",
      "alert:handle",
      "alert:archive",
      "alert:batch",
      "fence:view",
      "fence:manage",
      "tenant:view",
      "license:manage",
      "profile:view"
    ]
  }
}
```

## 5. 看板

### 5.1 看板汇总
- `GET /api/dashboard/summary`
- 权限：`dashboard:view`

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "metrics": [
      { "key": "animal_total", "title": "牲畜总数", "value": "128" },
      { "key": "device_online", "title": "在线设备", "value": "96" },
      { "key": "alert_pending", "title": "未处理告警", "value": "7" },
      { "key": "health_watch", "title": "健康关注", "value": "12" }
    ],
    "lastSyncAt": "2026-03-27T09:30:00+08:00"
  }
}
```

## 6. 地图与轨迹

### 6.1 轨迹筛选查询
- `GET /api/map/trajectories`
- 权限：`map:view`

Query 参数：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `animalId` | string | 是 | 耳标/牲畜 ID |
| `range` | enum(`24h`,`7d`,`30d`) | 是 | 回放区间 |

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "animals": [
      { "id": "animal_001", "earTag": "耳标-001" },
      { "id": "animal_002", "earTag": "耳标-002" },
      { "id": "animal_003", "earTag": "耳标-003" }
    ],
    "selectedAnimalId": "animal_002",
    "selectedRange": "7d",
    "summaryText": "地图占位 · 耳标-002 · d7",
    "points": [],
    "fallbackList": [
      { "label": "耳标-001 · 最近点" },
      { "label": "耳标-002 · 最近点" }
    ]
  }
}
```

错误补充：
- `UPSTREAM_UNAVAILABLE`：地图/GPS 服务不可用，前端回退列表展示

## 7. 告警中心

### 7.1 告警列表
- `GET /api/alerts`
- 权限：`alert:view`

Query 参数：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `stage` | enum(`pending`,`acknowledged`,`handled`,`archived`) | 否 | 状态筛选 |
| `page` | int | 否 | 默认 `1` |
| `pageSize` | int | 否 | 默认 `20` |

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "items": [
      {
        "id": "alert_001",
        "title": "越界 · 耳标-001",
        "occurredAt": "2026-03-26T10:12:00+08:00",
        "stage": "pending",
        "level": "warning"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 1
  }
}
```

### 7.2 确认告警
- `POST /api/alerts/{alertId}/ack`
- 权限：`alert:ack`

请求：
```json
{
  "remark": "已收到，准备处理"
}
```

### 7.3 处理告警
- `POST /api/alerts/{alertId}/handle`
- 权限：`alert:handle`

请求：
```json
{
  "result": "已驱离回围栏内",
  "remark": "现场处理完成"
}
```

### 7.4 归档告警
- `POST /api/alerts/{alertId}/archive`
- 权限：`alert:archive`

请求：
```json
{
  "remark": "闭环完成"
}
```

### 7.5 批量处理
- `POST /api/alerts/batch-handle`
- 权限：`alert:batch`

请求：
```json
{
  "alertIds": ["alert_001", "alert_002"],
  "action": "ack"
}
```

## 8. 围栏

### 8.1 围栏列表
- `GET /api/fences`
- 权限：`fence:view`

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "items": [
      {
        "id": "fence_001",
        "name": "北区围栏",
        "status": "active",
        "alarmEnabled": true
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 1
  }
}
```

### 8.2 新增围栏
- `POST /api/fences`
- 权限：`fence:manage`

请求：
```json
{
  "name": "北区围栏",
  "type": "polygon",
  "coordinates": [
    [120.1001, 30.2001],
    [120.1002, 30.2002]
  ],
  "alarmEnabled": true
}
```

### 8.3 编辑围栏
- `PUT /api/fences/{fenceId}`
- 权限：`fence:manage`

### 8.4 删除围栏
- `DELETE /api/fences/{fenceId}`
- 权限：`fence:manage`

## 9. 租户后台

### 9.1 租户列表
- `GET /api/tenants`
- 权限：`tenant:view`

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "items": [
      {
        "id": "tenant_001",
        "name": "华东示范牧场",
        "status": "active",
        "licenseUsed": 428,
        "licenseTotal": 500
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 1
  }
}
```

### 9.2 开通租户
- `POST /api/tenants`
- 权限：`tenant:create`

### 9.3 启用/禁用租户
- `POST /api/tenants/{tenantId}/status`
- 权限：`tenant:toggle`

请求：
```json
{
  "status": "disabled"
}
```

### 9.4 调整 license
- `POST /api/tenants/{tenantId}/license`
- 权限：`license:manage`

请求：
```json
{
  "licenseTotal": 600
}
```

## 10. 我的

### 10.1 当前用户资料
- `GET /api/profile`
- 权限：`profile:view`

响应：
```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req_xxx",
  "data": {
    "userId": "u_001",
    "name": "张三",
    "mobile": "13800000000",
    "tenantName": "华东示范牧场",
    "notificationEnabled": true
  }
}
```

## 11. Mock 对齐规则
- HTTP 层 DTO 应与上述 `data` 结构保持一致；前端内部 ViewModel 允许做轻量映射，但页面不得直接拼接假数据常量。
- 页面只关心：展示字段、可操作权限、状态枚举；不关心 Mock 还是 Live 来源。
- `AppMode.live` 在后端未接入前允许回退到 Mock 数据，但必须走独立 live repository/provider 分支。

## 12. 联调前检查项
- `/api/me` 的 `role` 与 `permissions` 必须先打通，否则菜单和按钮级权限无法切换到单一事实来源。
- 地图接口必须明确 `points` 为空时是否允许展示 fallbackList。
- 告警接口必须保证状态机合法：`pending -> acknowledged -> handled -> archived`。
- 围栏与租户接口需要约定 403/409/422 的稳定错误码，避免前端误判为通用异常。
