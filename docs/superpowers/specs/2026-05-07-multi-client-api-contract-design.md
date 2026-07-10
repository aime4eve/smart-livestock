# 多端统一 API 契约设计

> **状态**: ❌ 已废弃 — 由 `docs/api-contracts/` 目录下的新契约文档取代（2026-05-07 重设计）
> **废弃原因**: 评审发现 P0/P1 问题（code 类型不一致、ID 策略冲突、牧场切换过渡缺失、错误码不完备），决定从零重写 API 契约。
> **新契约位置**: `docs/api-contracts/api-overview.md` + `app-api.md` + `admin-api.md` + `open-api.md`
> **日期**: 2026-05-07
> **范围**: MVP Phase 1（Identity + Ranch + IoT 上下文）
> **前置文档**: [MVP 后端设计规格](./2026-05-06-mvp-backend-design.md)

---

## 1. 架构总览

### 1.1 三端隔离

| 前缀 | 客户端 | 认证 | 特点 |
|------|--------|------|------|
| `/api/v1/` | App（Flutter） | JWT (Bearer) | 单租户，farm-scoped，移动优先 |
| `/api/v1/admin/` | PC Admin（Vue 3） | JWT (Bearer) | 跨租户，批量操作，管理动作 |
| `/api/v1/open/` | 第三方开发者 | API Key (Header) | 只读为主，scope 控制，严格兼容承诺 |

### 1.2 隔离点

隔离发生在三个层面：

1. **路由空间** — 前缀不重叠，独立演进
2. **认证方式** — JWT vs API Key，不同的认证中间件
3. **契约演进节奏** — Open API 最保守（12 个月兼容期），App/Admin 同步（6 个月）

### 1.3 两条红线

1. **Domain 层永远不依赖 DTO 或框架** — 纯业务逻辑，零 Spring 注解
2. **Application 层永远不按客户端类型分支** — 通用用例，客户端差异在 Adapter（Controller/DTO）层收敛

客户端差异优先收敛在 Adapter 层。允许端点专属 Application 用例（如 Admin 批量操作、Open API 幂等性/配额）。Domain 模型最大化复用。

---

## 2. 通用约定

### 2.1 响应包络

**成功响应：**

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": { ... }
}
```

**分页列表响应：**

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": {
    "items": [...],
    "page": 1,
    "pageSize": 20,
    "total": 156
  }
}
```

### 2.2 统一分页（三端共享）

所有列表接口统一使用页码式分页：

| 参数 | 位置 | 默认值 | 说明 |
|------|------|--------|------|
| `page` | Query | 1 | 页码（从 1 开始） |
| `pageSize` | Query | 20 | 每页条数 |

分页上限：App/Admin 最大 200，Open API 最大 100。

### 2.3 错误码

**HTTP 状态码 + 业务错误码分离：**

- HTTP 状态码：传输层语义（401 未认证、403 无权限、404 不存在）
- 业务错误码（`code` 字段）：业务语义精确描述

| HTTP | 业务错误码 | 含义 |
|------|-----------|------|
| 400 | `VALIDATION_ERROR` | 请求参数校验失败 |
| 401 | `AUTH_TOKEN_EXPIRED` | Token 已过期 |
| 401 | `AUTH_INVALID_TOKEN` | Token 无效 |
| 401 | `AUTH_API_KEY_INVALID` | API Key 无效 |
| 401 | `AUTH_API_KEY_EXPIRED` | API Key 已过期 |
| 403 | `AUTH_FORBIDDEN` | 无权限访问该资源 |
| 403 | `TENANT_DISABLED` | 租户已禁用 |
| 404 | `RESOURCE_NOT_FOUND` | 资源不存在 |
| 409 | `STATE_CONFLICT` | 状态冲突（如告警非法跳转） |
| 409 | `DUPLICATE_RESOURCE` | 资源已存在 |
| 422 | `FARM_SCOPE_CONFLICT` | 同时提供 path 和 header 的 farmId |
| 429 | `RATE_LIMIT_EXCEEDED` | 超出速率限制 |
| 500 | `INTERNAL_ERROR` | 服务端内部错误 |

**两个 403 的区分：**
- `AUTH_FORBIDDEN` — 当前用户角色/权限不足（认证通过但无权）
- `TENANT_DISABLED` — 租户被禁用（任何操作均被拦截，优先级最高）

### 2.4 数据格式约定

| 类型 | 格式 | 示例 |
|------|------|------|
| 时间戳 | ISO 8601（毫秒精度） | `2026-05-07T10:30:00.000Z` |
| 日期 | `yyyy-MM-dd` | `2026-05-07` |
| ID | BIGSERIAL 序列化为字符串 | `"1"`、`"42"`（数字 ID 以字符串形态对外暴露） |
| 枚举 | 小写 snake_case 字符串 | `pending`、`active`、`device_tracker` |
| 坐标 | WGS 84（经度在前） | `{ "lng": 112.8519, "lat": 28.2458 }` |
| 空值 | 字段省略（不返回 null） | — |

### 2.5 Farm Scope 硬约束

| 操作类型 | farmId 来源 | 规则 |
|----------|------------|------|
| **写操作**（POST/PUT/DELETE） | 仅路径 `farms/{farmId}/` | 写操作只认路径，header 无效 |
| **读操作**（GET） | 路径 `farms/{farmId}/` 或 header `x-active-farm` | 二选一，同时提供返回 422 |

Farm Scope 不适用于以下端点（用户/租户级操作，非农场级）：
- `/auth/*` — 认证端点
- `/me`、`/me/*` — 当前用户操作
- `/tenants/me` — 当前租户信息
- `/farms`（列表/创建） — 尚未进入农场上下文
- `/admin/*` — 管理端点有独立的跨租户逻辑

`x-active-farm` header 为现有 Mock Server 兼容保留，Spring Boot 实现中所有读操作优先使用路径参数。该 header 在 Phase 2 上线时标记废弃（`Deprecation: true`），3 个月后移除。

---

## 3. App API 端点（`/api/v1/`）

### 3.1 认证

| 方法 | 路径 | 用途 |
|------|------|------|
| `POST` | `/auth/login` | 登录（phone + password → token） |
| `POST` | `/auth/refresh` | 刷新 Token（refreshToken 轮换） |
| `POST` | `/auth/logout` | 登出（注销 refreshToken） |

### 3.2 身份（Identity）

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/tenants/me` | 当前租户信息 |
| `PUT` | `/tenants/me` | 更新当前租户信息 |
| `GET` | `/me` | 当前用户信息 |
| `PUT` | `/me` | 更新当前用户信息 |
| `PUT` | `/me/password` | 修改密码 |
| `GET` | `/farms` | 我的农场列表 |
| `POST` | `/farms` | 创建农场 |
| `GET` | `/farms/{farmId}` | 农场详情 |
| `PUT` | `/farms/{farmId}` | 更新农场信息 |
| `GET` | `/farms/{farmId}/members` | 农场成员列表 |
| `POST` | `/farms/{farmId}/members` | 添加成员（邀请新用户到农场） |
| `DELETE` | `/farms/{farmId}/members/{userId}` | 移除成员 |

### 3.3 牧场（Ranch）

**牲畜：**

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/livestock` | 牲畜列表（支持 `?keyword=&gender=&status=`） |
| `GET` | `/farms/{farmId}/livestock/{livestockId}` | 牲畜详情 |
| `POST` | `/farms/{farmId}/livestock` | 新增牲畜 |
| `PUT` | `/farms/{farmId}/livestock/{livestockId}` | 更新牲畜信息 |
| `DELETE` | `/farms/{farmId}/livestock/{livestockId}` | 删除牲畜（软删除，设置 status = removed） |

**围栏：**

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/fences` | 围栏列表 |
| `GET` | `/farms/{farmId}/fences/{fenceId}` | 围栏详情（含坐标点） |
| `POST` | `/farms/{farmId}/fences` | 创建围栏 |
| `PUT` | `/farms/{farmId}/fences/{fenceId}` | 更新围栏 |
| `DELETE` | `/farms/{farmId}/fences/{fenceId}` | 删除围栏 |

**告警：**

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/alerts` | 告警列表（支持 `?level=&status=&startTime=&endTime=`） |
| `GET` | `/farms/{farmId}/alerts/{alertId}` | 告警详情 |
| `POST` | `/farms/{farmId}/alerts/{alertId}/acknowledge` | 确认告警（pending → acknowledged） |
| `POST` | `/farms/{farmId}/alerts/{alertId}/handle` | 处理告警（acknowledged → handled） |
| `POST` | `/farms/{farmId}/alerts/{alertId}/archive` | 归档告警（handled → archived） |
| `POST` | `/farms/{farmId}/alerts/batch-handle` | 批量处理告警 |

告警状态机：`pending → acknowledged → handled → archived`，非法跳转返回 409 `STATE_CONFLICT`。

**状态变更 HTTP 方法说明：** 告警操作使用 `POST`（非幂等——记录操作人和时间戳），管理端状态变更使用 `PUT`（幂等——相同请求产生相同结果）。

### 3.4 物联网（IoT）

**设备：**

设备有两个维度的状态：(1) 生命周期状态 `status`（INVENTORY / ACTIVE / OFFLINE / DECOMMISSIONED）；(2) 运行时状态 `runtimeStatus`（online / offline / low_battery），由设备心跳和遥测数据实时更新。

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/devices` | 设备列表 |
| `POST` | `/farms/{farmId}/devices` | 注册设备 |
| `GET` | `/farms/{farmId}/devices/{deviceId}` | 设备详情 |
| `PUT` | `/farms/{farmId}/devices/{deviceId}` | 更新设备信息 |
| `PUT` | `/farms/{farmId}/devices/{deviceId}/activate` | 激活设备（INVENTORY → ACTIVE） |
| `PUT` | `/farms/{farmId}/devices/{deviceId}/decommission` | 退役设备（→ DECOMMISSIONED） |

**设备许可证：**

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/device-licenses` | 许可证列表 |
| `GET` | `/farms/{farmId}/device-licenses/{licenseId}` | 许可证详情 |
| `POST` | `/farms/{farmId}/device-licenses` | 申请许可证 |
| `PUT` | `/farms/{farmId}/device-licenses/{licenseId}/revoke` | 撤销许可证（→ REVOKED） |

**安装记录：**

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/installations` | 安装记录列表 |
| `POST` | `/farms/{farmId}/installations` | 安装设备到牲畜 |
| `GET` | `/farms/{farmId}/installations/{installationId}` | 安装记录详情 |
| `PUT` | `/farms/{farmId}/installations/{installationId}/uninstall` | 拆卸设备 |

**GPS 定位：**

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/gps-logs/latest` | 全场最新 GPS 坐标 |
| `GET` | `/farms/{farmId}/livestock/{livestockId}/gps-logs` | 单牲畜 GPS 历史（支持 `?startTime=&endTime=`） |

**GPS 数据写入：** GPS 坐标通过 MQTT → RocketMQ 管道接入，不经过 REST API。Phase 1 使用模拟数据注入（通过 RocketMQ test producer 或保留 `POST /farms/{farmId}/devices/{deviceId}/gps-logs` 测试专用端点，标注 `@Deprecated`，Phase 3 移除），Phase 3 接入真实 IoT 设备。

### 3.5 读模型（Read Models）

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/farms/{farmId}/dashboard/summary` | 看板汇总（牲畜数/在线设备数/活跃告警数/围栏数） |
| `GET` | `/farms/{farmId}/map/overview` | 地图总览（牲畜位置 + 围栏轮廓 + 告警标记） |

**App API 共计 49 个端点。**

---

## 4. Admin API 端点（`/api/v1/admin/`）

设计原则：Admin 只新增后台特化端点（跨租户视图、管理动作、批量操作、审计）。基础资源操作复用 `/api/v1/` 同一套端点，admin 角色可访问任意 farm 数据。

### 4.1 租户管理

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/admin/tenants` | 跨租户列表（`?status=&phase=&keyword=&page=&pageSize=`） |
| `POST` | `/admin/tenants` | 创建租户（后台代建） |
| `GET` | `/admin/tenants/{tenantId}` | 租户详情（含农场数/用户数/设备数聚合统计） |
| `PUT` | `/admin/tenants/{tenantId}/status` | 启用/禁用租户（`{ status: "active" \| "disabled" }`） |
| `PUT` | `/admin/tenants/{tenantId}/phase` | 变更阶段（`{ phase: "sample" \| "batch" }`） |

### 4.2 用户管理

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/admin/users` | 跨租户用户列表（`?tenantId=&farmId=&role=&status=&keyword=&page=&pageSize=`） |
| `POST` | `/admin/users` | 创建用户（指定 tenantId + role） |
| `GET` | `/admin/users/{userId}` | 用户详情（含关联农场列表） |
| `PUT` | `/admin/users/{userId}` | 更新用户信息（姓名、手机、角色） |
| `PUT` | `/admin/users/{userId}/status` | 启用/禁用/锁定（`{ status: "active" \| "disabled" \| "locked" }`） |
| `POST` | `/admin/users/{userId}/reset-password` | 重置密码 |

### 4.3 农场管理

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/admin/farms` | 跨租户农场列表（`?tenantId=&status=&keyword=&page=&pageSize=`） |
| `POST` | `/admin/farms` | 为任意租户创建农场（body 含 `tenantId`） |
| `GET` | `/admin/farms/{farmId}` | 农场详情（admin 视图，含牲畜数/设备数/告警数） |
| `PUT` | `/admin/farms/{farmId}/status` | 启用/禁用农场 |

### 4.4 跨租户聚合

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/admin/dashboard` | 平台总览（租户数/农场数/用户数/设备数/活跃告警数，按天趋势） |

### 4.5 审计

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/admin/audit-logs` | 操作审计日志（`?tenantId=&userId=&action=&startTime=&endTime=&page=&pageSize=`） |

### 4.6 API Key 管理

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/admin/api-keys` | 列出所有 Key（`?tenantId=&status=`） |
| `POST` | `/admin/api-keys` | 创建 Key（`{ tenantId, name, scopes[], expiresInDays }`） |
| `PUT` | `/admin/api-keys/{keyId}/status` | 启用/禁用 Key |
| `DELETE` | `/admin/api-keys/{keyId}` | 撤销 Key（不可恢复） |

### 设计要点

1. **无 Ranch/IoT Admin 端点** — admin 访问任意农场的牲畜/围栏/告警/设备，直接复用 `/api/v1/farms/{farmId}/...`，通过角色权限放行
2. **跨租户筛选** — 所有列表接口支持 `tenantId` 筛选参数
3. **status 动作用 PUT** — 状态变更是幂等操作
4. **审计日志** — Phase 1 先做查询接口，写入由 Application Service 内部完成

**Admin API 共计 21 个端点。**

---

## 5. Open API 端点（`/api/v1/open/`）

设计原则：路径结构与 App API 对齐，便于开发者理解。以读操作为主，唯一写操作是 IoT 设备自注册。

### 5.1 牲畜（只读）

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/open/farms/{farmId}/livestock` | 牲畜列表 |
| `GET` | `/open/farms/{farmId}/livestock/{livestockId}` | 牲畜详情 |

### 5.2 围栏（只读）

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/open/farms/{farmId}/fences` | 围栏列表 |
| `GET` | `/open/farms/{farmId}/fences/{fenceId}` | 围栏详情（含坐标点） |

### 5.3 告警（只读）

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/open/farms/{farmId}/alerts` | 告警列表（`?level=&status=&startTime=&endTime=`） |
| `GET` | `/open/farms/{farmId}/alerts/{alertId}` | 告警详情 |

### 5.4 设备与定位（只读）

| 方法 | 路径 | 用途 |
|------|------|------|
| `GET` | `/open/farms/{farmId}/devices` | 设备列表 |
| `GET` | `/open/farms/{farmId}/devices/{deviceId}` | 设备详情 |
| `GET` | `/open/farms/{farmId}/gps-logs/latest` | 全场最新 GPS 坐标（批量） |
| `GET` | `/open/farms/{farmId}/livestock/{livestockId}/gps-logs` | 单牲畜 GPS 历史（`?startTime=&endTime=`） |

### 5.5 IoT 设备自注册（写入）

| 方法 | 路径 | 用途 |
|------|------|------|
| `POST` | `/open/devices/register` | 设备上报序列号自注册（`{ serialNo, deviceType, firmwareVersion }`） |

该端点使用设备专用 API Key（非开发者 Key），认证后自动绑定到 Key 所属租户。设备创建后进入 INVENTORY 状态（租户级，尚未分配到农场），后续通过 App API `POST /farms/{farmId}/installations` 安装到具体牲畜时关联农场。

### Open API 专属约定

| 维度 | 规则 |
|------|------|
| **认证** | `Authorization: Bearer <api-key>` 或 `X-API-Key: <api-key>` |
| **Farm Scope** | API Key 绑定 tenantId，farmId 通过路径传入；Key 无权访问非本租户的农场 |
| **速率限制** | 每分钟 60 次（默认），响应头返回 `X-RateLimit-Limit` / `X-RateLimit-Remaining` / `X-RateLimit-Reset` |
| **幂等性** | POST 请求支持 `Idempotency-Key` 请求头，相同 key 24h 内返回缓存结果 |
| **分页上限** | `pageSize` 最大 100 |
| **版本锁定** | 破坏性变更必须递增 URL 版本（如 `/api/v1/open/v2/`） |

### 设计要点

1. **路径对齐** — `/open/farms/{farmId}/...` 与 App API 一致
2. **只读边界** — 除设备自注册外不写入业务数据
3. **Phase 1 范围** — 不含 Health 上下文，Phase 2 按同模式扩展 `/open/farms/{farmId}/twin/...`
4. **API Key 管理** — 放 Admin API，Phase 1 不做租户自助管理

**Open API 共计 11 个端点。**

---

## 6. 认证机制

### 6.1 JWT 认证（App / Admin）

**登录流程：**

```
POST /api/v1/auth/login
Body: { phone, password }
Response: { accessToken, refreshToken, expiresIn }
```

**JWT Payload 结构：**

```json
{
  "sub": "userId",
  "tid": "tenantId",
  "role": "owner",
  "iat": 1746500000,
  "exp": 1746503600
}
```

| 字段 | 说明 |
|------|------|
| `sub` | 用户 ID |
| `tid` | 所属租户 ID |
| `role` | 角色：`owner` / `worker` / `platform_admin` / `b2b_admin` |
| `iat` | 签发时间 |
| `exp` | 过期时间（accessToken 1h，refreshToken 7d） |

**Token 刷新：**

```
POST /api/v1/auth/refresh
Body: { refreshToken }
Response: { accessToken, refreshToken, expiresIn }
```

刷新时 refreshToken 轮换（旧 token 立即失效）。

**权限控制层：**
- 路由级别：Controller 注解 `@PreAuthorize` 校验角色
- 数据级别：Application Service 注入当前用户 tenantId，Query 层自动追加租户条件
- Farm 级别：`FarmScopeResolver` 校验当前用户是否有权访问目标 farmId

### 6.2 API Key 认证（Open API）

**Key 格式：** `sl_live_<random32chars>` / `sl_test_<random32chars>`

**Key 元数据（服务端存储）：**

| 字段 | 说明 |
|------|------|
| `keyId` | Key 标识（管理用，不暴露完整 Key） |
| `keyHash` | SHA-256 存储（不存明文） |
| `tenantId` | 绑定租户 |
| `scopes` | 权限范围：`["livestock:read", "fence:read", "alert:read", "device:read", "gps:read", "device:register"]` |
| `status` | `active` / `disabled` / `revoked` |
| `expiresAt` | 过期时间（可选，null = 永不过期） |
| `rateLimit` | 自定义速率限制（默认 60/min） |

**认证流程：**

```
Request → 提取 Key → SHA-256 → 查库匹配
  → 校验 status、expiresAt
  → 提取 tenantId + scopes
  → 校验 path 中 farmId 属于该 tenantId
  → 校验 scope 包含请求资源
  → 检查速率限制（Redis INCR + TTL）
  → 通过 → 执行请求
```

**设备自注册专用 Key：**
- scopes 仅含 `["device:register"]`
- 不允许访问任何读取端点
- 单独速率限制（100/min，允许批量注册）

### 6.3 三端认证对照

| 维度 | App (`/api/v1/`) | Admin (`/api/v1/admin/`) | Open (`/api/v1/open/`) |
|------|----------|-----------|---------|
| 认证方式 | JWT (Bearer) | JWT (Bearer) | API Key (Header) |
| 身份粒度 | userId + tenantId + role | userId + tenantId + role | tenantId + scopes |
| Farm Scope | 路径 `farms/{farmId}/` | 路径 `farms/{farmId}/`（可跨租户） | 路径 + Key 租户绑定 |
| 权限模型 | RBAC（角色） | RBAC（角色，含 platform_admin） | Scope（能力集） |
| 速率限制 | 无（或宽松全局限制） | 无 | per-key，默认 60/min |

---

## 7. 版本与演进策略

### 7.1 版本规则

| 前缀 | 版本承诺 | 破坏性变更策略 |
|------|---------|--------------|
| `/api/v1/` (App) | 尽量兼容，非破坏性迭代 | 破坏性变更必须新版本号 `/api/v2/`，旧版本至少保留 6 个月 |
| `/api/v1/admin/` | 与 App 同步 | 同上 |
| `/api/v1/open/` | **严格兼容承诺** | 破坏性变更必须递增 `/api/v1/open/v2/`，旧版本至少保留 12 个月 |

**破坏性变更定义（三端统一）：**
- 删除或重命名已有字段
- 更改字段类型
- 更改 HTTP 方法或状态码语义
- 新增必填参数

**非破坏性变更（无需版本号递增）：**
- 响应体新增字段（客户端忽略未知字段）
- 新增可选请求参数
- 新增端点
- 新增枚举值（客户端需容错）

### 7.2 阶段演进路径

**Phase 1 → Phase 2 新增端点（不破坏现有）：**

| 上下文 | Phase 2 新增端点示例 | 挂载前缀 |
|--------|---------------------|---------|
| Health | `/farms/{farmId}/twin/fever/*`、`/twin/digestive/*`、`/twin/estrus/*`、`/twin/epidemic/*` | App + Open |
| Commerce | `/subscription/*`、`/contracts/*`、`/revenue/*` | App + Admin |
| Analytics | `/farms/{farmId}/stats/*`、`/farms/{farmId}/trends/*` | App + Admin |

新增端点直接追加到 `/api/v1/` 下，不递增版本号。

### 7.3 废弃流程

| 步骤 | 动作 |
|------|------|
| 1. 标记废弃 | 响应头添加 `Deprecation: true` + `Sunset: <date>` |
| 2. 文档标注 | API 文档标记为 `@deprecated`，注明替代方案 |
| 3. 过渡期 | 至少 3 个月（Open API 至少 6 个月） |
| 4. 移除 | 过渡期结束后返回 410 Gone |

**已计划的废弃项：**

| 项目 | 状态 | 计划移除 |
|------|------|---------|
| `x-active-farm` 请求头 | Phase 2 上线时标记废弃 | 废弃后 3 个月 |

### 7.4 契约文档管理

```
docs/api-contracts/
├── api-overview.md              ← 三端总览（前缀、认证、通用约定）
├── app-api.md                   ← /api/v1/ 全部端点
├── admin-api.md                 ← /api/v1/admin/ 全部端点
├── open-api.md                  ← /api/v1/open/ 全部端点 + 专属约定
└── changelog.md                 ← 变更日志（日期 + 变更内容 + 影响范围）
```

每个端点文档包含：方法、路径、请求参数/Body、响应示例、错误码、权限要求、版本状态。

---

## 端点统计

| 前缀 | 端点数 |
|------|--------|
| App (`/api/v1/`) | 49 |
| Admin (`/api/v1/admin/`) | 21 |
| Open (`/api/v1/open/`) | 11 |
| **合计** | **81** |

---

## 与现有 Mock Server 的关系

本契约为 MVP Spring Boot 后端的目标 API 设计。现有 Node.js Mock Server 继续服务 Demo 阶段，Spring Boot 上线后逐步替换。

迁移路径：
1. Spring Boot 实现全部端点
2. Flutter App 切换 `API_BASE_URL` 指向 Spring Boot
3. PC Admin（Vue 3）对接 `/api/v1/admin/`
4. Open API 上线后对外发布
5. Mock Server 保留作为开发/测试参考，不再演进
