# 多端统一 API 契约 — 总览

> **状态**: 生效
> **日期**: 2026-05-07（重设计）
> **取代**: `docs/superpowers/specs/2026-05-07-multi-client-api-contract-design.md`（已废弃）
> **配套文档**: [MVP 后端设计规格](../superpowers/specs/2026-05-06-mvp-backend-design.md)
>
> 本文件为契约总览。各端点详情见：
> - [app-api.md](./app-api.md) — App API（`/api/v1/`，49 端点）
> - [admin-api.md](./admin-api.md) — Admin API（`/api/v1/admin/`，21 端点）
> - [open-api.md](./open-api.md) — Open API（`/api/v1/open/`，11 端点）

---

## 1. 架构总览

### 1.1 三端隔离

| 前缀 | 客户端 | 认证 | 特点 |
|------|--------|------|------|
| `/api/v1/` | App（Flutter） | JWT (Bearer) | 单租户，farm-scoped，移动优先 |
| `/api/v1/admin/` | PC Admin（Vue 3） | JWT (Bearer) | 跨租户，批量操作，管理动作 |
| `/api/v1/open/` | 第三方开发者 | API Key (Header) | 只读为主，scope 控制，严格兼容承诺 |

### 1.2 隔离层面

1. **路由空间** — 前缀不重叠，独立演进
2. **认证方式** — JWT vs API Key，不同认证中间件
3. **契约演进节奏** — Open API 最保守（12 个月兼容期），App/Admin 同步（6 个月）

### 1.3 架构红线

1. **Domain 层永远不依赖 DTO 或框架** — 纯业务逻辑，零 Spring 注解
2. **Application 层永远不按客户端类型分支** — 通用用例，客户端差异在 Adapter（Controller/DTO）层收敛

---

## 2. 通用约定

### 2.1 响应包络

**成功响应（含 data）：**

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": { }
}
```

**分页列表响应：**

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": {
    "items": [],
    "page": 1,
    "pageSize": 20,
    "total": 156
  }
}
```

**错误响应（不含 data 字段）：**

```json
{
  "code": "QUOTA_EXCEEDED",
  "message": "牧场数量已达上限",
  "requestId": "req-abc123"
}
```

**code 字段** — 全部使用**字符串枚举**（`"OK"`、`"AUTH_TOKEN_EXPIRED"` 等）。成功用 `"OK"`，错误用大写下划线格式。不使用数字码或成功/错误混合类型。

### 2.2 统一分页

所有列表接口统一使用页码式分页：

| 参数 | 位置 | 类型 | 默认值 | 说明 |
|------|------|------|--------|------|
| `page` | Query | integer | 1 | 页码（从 1 开始） |
| `pageSize` | Query | integer | 20 | 每页条数 |

**分页上限**: App/Admin 最大 200，Open API 最大 100。

**时序数据补充**: 对于 `gps_logs` 等时序查询，Phase 1 沿用页码式分页。Phase 2 评估是否需要 cursor-based 分页（`?cursor=&limit=`）作为补充。

### 2.3 HTTP 方法语义约定

| 方法 | 语义 | 适用场景 |
|------|------|---------|
| `GET` | 读取资源 | 列表、详情 |
| `POST` | 创建资源 或 非幂等动作 | 新建实体、状态变更（记录操作人和时间戳） |
| `PUT` | 幂等更新或幂等状态变更 | 更新实体信息、激活/禁用/退役 |
| `DELETE` | 删除资源 | 软删除或硬删除 |
| `PATCH` | 部分更新（预留） | Phase 1 不强制使用 |

**动作子资源的方法选择**:
- 告警操作（acknowledge / handle / archive）→ `POST`，每次执行记录操作人和时间戳，非幂等
- 设备状态变更（activate / decommission）→ `PUT`，相同请求多次执行结果一致，幂等
- 管理端状态变更（启用/禁用/锁定）→ `PUT`，幂等

### 2.4 数据格式约定

| 类型 | 格式 | 示例 | 备注 |
|------|------|------|------|
| 时间戳 | ISO 8601（毫秒精度，UTC） | `2026-05-07T10:30:00.000Z` | 数据库存储 `TIMESTAMPTZ` |
| 日期 | `yyyy-MM-dd` | `2026-05-07` | |
| ID | BIGSERIAL 序列化为字符串 | `"1"`、`"42"` | 数字 ID 以字符串形态对外暴露，前端统一用 `String` 接收 |
| 枚举 | 小写 snake_case 字符串 | `"pending"`、`"active"`、`"device_tracker"` | |
| 坐标 | WGS 84（经度在前） | `{ "lng": 112.8519, "lat": 28.2458 }` | 遵循 GeoJSON 顺序 |
| 空值 | 字段省略，不返回 `null` | — | |
| 布尔 | `true` / `false` | — | |

**枚举值扩展**: 后端可新增枚举值（非破坏性变更）。**客户端必须容错处理未知枚举值**（使用默认值或忽略），不可因新增枚举值而崩溃。

### 2.5 错误码全集

HTTP 状态码与业务错误码分离：

| HTTP | code | 含义 | 触发条件 |
|------|------|------|---------|
| 400 | `VALIDATION_ERROR` | 请求参数校验失败 | body 缺少必填字段、类型错误、格式不符 |
| 401 | `AUTH_TOKEN_EXPIRED` | JWT accessToken 已过期 | `exp` 已过 |
| 401 | `AUTH_INVALID_TOKEN` | JWT token 无效 | 签名错误、格式错误、已吊销 |
| 401 | `AUTH_API_KEY_INVALID` | API Key 无效 | Key 不存在或已撤销 |
| 401 | `AUTH_API_KEY_EXPIRED` | API Key 已过期 | `expiresAt` 已过 |
| 403 | `AUTH_FORBIDDEN` | 权限不足 | 角色/scope 无权访问该资源 |
| 403 | `TENANT_DISABLED` | 租户已禁用 | 租户 status=disabled，优先级高于所有其他校验 |
| 403 | `QUOTA_EXCEEDED` | 超出配额 | SAMPLE 阶段超软限制或 BATCH 阶段超 tier 限制 |
| 403 | `LICENSE_EXPIRED` | 设备许可证过期 | 设备安装时许可证已过期 |
| 404 | `RESOURCE_NOT_FOUND` | 资源不存在 | 请求的资源 ID 不存在或不属于当前租户 |
| 409 | `STATE_CONFLICT` | 状态冲突 | 告警非法跳转、设备状态不允许操作 |
| 409 | `DUPLICATE_RESOURCE` | 资源重复 | 重复创建、重复安装、Idempotency-Key 冲突 |
| 409 | `DEVICE_NOT_ACTIVE` | 设备未激活 | 设备 status != ACTIVE 时尝试安装 |
| 410 | `RESOURCE_DELETED` | 资源已删除 | 软删除的资源（如已删除的牲畜） |
| 422 | `FARM_SCOPE_CONFLICT` | Farm Scope 冲突 | 同时提供 path farmId 和 header `x-active-farm` |
| 429 | `RATE_LIMIT_EXCEEDED` | 速率限制 | 超出 per-key 或 per-IP 速率上限 |
| 500 | `INTERNAL_ERROR` | 服务端内部错误 | 未预期异常 |

**两个 403 的区分**:
- `AUTH_FORBIDDEN` — 当前用户角色/权限不足（认证通过但无权访问该资源）
- `TENANT_DISABLED` — 租户被禁用（任何操作均被拦截，优先级最高）

**客户端错误处理**: 客户端应**先检查 HTTP 状态码**（2xx = 成功，4xx/5xx = 失败），再解析 `body.code` 做精细化错误提示。

### 2.6 requestId

- 每个请求都生成唯一的 `requestId`
- 优先取请求头 `X-Request-Id` 的值，无则服务端自动生成 UUID v4
- 响应体和日志中均记录 `requestId`，用于全链路追踪

---

## 3. Farm Scope 硬约束

### 3.1 解析规则

| 操作类型 | farmId 来源 | 规则 |
|----------|------------|------|
| **写操作**（POST/PUT/DELETE） | 仅路径 `farms/{farmId}/` | 写操作只认路径，header 无效。无路径则 400 |
| **读操作**（GET） | 路径 `farms/{farmId}/` **或** header `x-active-farm` | 二选一，**同时提供返回 422** |

### 3.2 不适用 Farm Scope 的端点

以下端点属于用户/租户/全局级操作，不参与 Farm Scope 解析：
- `/auth/*` — 认证端点
- `/me`、`/me/*` — 当前用户操作
- `/tenants/me` — 当前租户信息
- `/farms`（不含 {farmId}） — 农场列表和创建
- `/device-licenses` — 租户级资源（见 §3.4）
- `/admin/*` — Admin 端点有独立的跨租户逻辑

### 3.3 安全约束

1. **禁止双来源**: 同一请求同时包含 path farmId 和 header `x-active-farm` → 422 `FARM_SCOPE_CONFLICT`
2. **写操作强制 path**: Ranch 领域所有写操作必须使用 `/farms/{farmId}/...`，后端只认 path 中的 farmId
3. **跨租户防御**: 校验 `farmId` 归属的 `tenantId` 等于 JWT 中的 `tid`。不匹配 → 403 `AUTH_FORBIDDEN`
4. **路径注入防御**: farmId 在 Controller 层使用 `@PathVariable Long farmId` 接收，非数字格式由 Spring 自动返回 400
5. **header 兼容模式**（仅 GET）:
   - 仅 `x-active-farm` 时视为隐式 farmId，与 path farmId 等效
   - farmId 不属于租户 → 403
   - 响应体不额外返回 farmId（客户端已知）

### 3.4 `x-active-farm` 兼容策略

- 仅限 GET 读操作，Phase 1 期间可用
- Phase 2 上线时标记废弃（`Deprecation: true` + `Sunset` 响应头）
- 废弃后保留 3 个月，之后移除
- Phase 1 期间须有集成测试保证 path 入口与 header 入口返回一致

---

## 4. 认证机制

### 4.1 JWT 认证（App / Admin）

**登录:**

```
POST /api/v1/auth/login
Content-Type: application/json

Request:
{ "phone": "13800138000", "password": "aB3$xK9@pQ2" }

Response 200:
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "dGhpcyBpcyBh...",
    "expiresIn": 3600
  }
}
```

`expiresIn` 为 accessToken 有效期（秒）。accessToken 的 `exp` 为 Unix 时间戳，客户端可解码 JWT 直接获取精确过期时刻。保留 `expiresIn` 为便利字段（避免强制客户端解码 JWT）。

**JWT Payload 结构:**

```json
{
  "sub": "42",
  "tid": "7",
  "role": "owner",
  "iat": 1746500000,
  "exp": 1746503600
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| `sub` | string | 用户 ID（BIGSERIAL 序列化为字符串） |
| `tid` | string | 所属租户 ID（BIGSERIAL 序列化为字符串） |
| `role` | string | `owner` / `worker` / `platform_admin` / `b2b_admin` |
| `iat` | number | 签发时间（Unix 秒） |
| `exp` | number | 过期时间（Unix 秒），accessToken 1h，refreshToken 7d |

**`api_consumer` 角色不使用 JWT**，仅通过 API Key 认证（见 §4.2）。

**Token 刷新（轮换）:**

```
POST /api/v1/auth/refresh
Content-Type: application/json

Request:
{ "refreshToken": "dGhpcyBpcyBh..." }

Response 200:
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": {
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "bmV3IHJlZnJl...",
    "expiresIn": 3600
  }
}
```

刷新时 refreshToken 轮换——旧 token 立即失效。Redis 存储 refreshToken 白名单，旧 token 加入黑名单。

**登出:**

```
POST /api/v1/auth/logout
Authorization: Bearer <accessToken>

Request:
{ "refreshToken": "dGhpcyBpcyBh..." }

Response 200:
{ "code": "OK", "message": "success", "requestId": "req-abc123" }
```

登出时吊销 refreshToken，accessToken 短有效期自然过期。

**权限控制层:**
- **路由级别**: Controller 注解 `@PreAuthorize` 校验角色
- **数据级别**: Application Service 注入当前用户 `tenantId`，Repository 层自动过滤
- **Farm 级别**: `FarmScopeResolver` 校验当前用户是否有权访问目标 farmId

### 4.2 API Key 认证（Open API）

**Key 格式**: `sl_live_<random32chars>` / `sl_test_<random32chars>`
- `sl_test_` 前缀的 Key 仅限测试环境使用
- 随机源: `SecureRandom`（Java）或 `crypto.randomBytes`（Node.js）
- 仅首次发放时返回完整 Key，之后不可再次获取明文

**Key 元数据（服务端存储）:**

| 字段 | 说明 |
|------|------|
| `keyId` | Key 标识（管理用，不暴露完整 Key） |
| `keyHash` | SHA-256 哈希存储（不存明文） |
| `tenantId` | 绑定租户 |
| `scopes` | 权限范围：`["livestock:read", "fence:read", "alert:read", "device:read", "gps:read", "device:register"]` |
| `status` | `active` / `disabled` / `revoked` |
| `expiresAt` | 过期时间（ISO 8601，可选；null = 永不过期） |
| `rateLimit` | 自定义速率限制（次/分钟，默认 60） |

**认证流程（逐级校验，任一步失败即拒绝）:**

```
Request → 提取 Key（Authorization: Bearer <key> 或 X-API-Key: <key>）
  → SHA-256 哈希 → 查库匹配
  → 校验 status == active
  → 校验 expiresAt 未过期（若设置）
  → 提取 tenantId + scopes
  → 校验 path 中 farmId 所属 tenantId == Key 的 tenantId
  → 校验 scope 包含请求资源
  → 检查速率限制（Redis INCR + TTL）
  → 通过 → 执行请求
```

**设备自注册专用 Key:**
- scopes 仅含 `["device:register"]`
- 不允许访问任何读取端点
- 单独速率限制（100 次/分钟，允许批量注册）

### 4.3 三端认证对照

| 维度 | App (`/api/v1/`) | Admin (`/api/v1/admin/`) | Open (`/api/v1/open/`) |
|------|----------|-----------|---------|
| 认证方式 | JWT (Bearer) | JWT (Bearer) | API Key (Header) |
| 身份粒度 | userId + tenantId + role | userId + tenantId + role | tenantId + scopes |
| Farm Scope | 路径 `farms/{farmId}/` | 路径 `farms/{farmId}/`（可跨租户） | 路径 + Key 租户绑定 |
| 权限模型 | RBAC（角色） | RBAC（角色，含 platform_admin） | Scope（能力集） |
| 速率限制 | 无 | 无 | per-key，默认 60/min |

---

## 5. 牧场切换机制

### 5.1 设计原则

前端通过 `ApiClient` 单例持有 `activeFarmId`，所有 farm-scoped 请求由 `ApiClient.farmGet/farmPost/farmPut/farmDelete` 自动注入路径前缀。GoRouter 路由不包含 farmId，切换牧场仅更新 `activeFarmId` 状态。

- **旧模式**（Mock Server）: `GET /dashboard` + `x-active-farm: farm_001` header
- **新模式**（Spring Boot）: `ApiClient.farmGet('/dashboard/summary')` → `GET /api/v1/farms/{activeFarmId}/dashboard/summary`

### 5.2 客户端交互流程

1. 用户登录后，Flutter 调用 `GET /api/v1/farms` 获取农场列表
2. 用户从列表中选择目标农场
3. `FarmSwitcherController` 调用 `SessionController.updateActiveFarm(farmId)`，同时设置 `ApiClient.instance.setActiveFarmId(farmId)`
4. GoRouter 路由保持扁平结构（`/dashboard`、`/alerts`），不含 farmId 前缀
5. 所有 ranch 资源请求通过 `ApiClient.farmGet('/...')` 自动拼接 `/farms/{activeFarmId}/...`

### 5.3 `GET /farms` 响应示例

```json
{
  "code": "OK",
  "message": "success",
  "requestId": "req-abc123",
  "data": {
    "items": [
      {
        "id": "1",
        "name": "城北牧场",
        "latitude": 28.2458000,
        "longitude": 112.8519000,
        "areaHectares": 150.50,
        "livestockCount": 120,
        "deviceCount": 45,
        "role": "owner"
      }
    ],
    "page": 1,
    "pageSize": 20,
    "total": 3
  }
}
```

### 5.4 Flutter 端变更清单

| 变更项 | 旧模式（Mock） | 新模式（ApiClient） |
|--------|--------|--------|
| 农场列表请求 | `GET /farm/my-farms`（Mock Server） | `GET /farms`（Spring Boot） |
| 切换农场 | `POST /farm/switch-farm` + header | `SessionController.updateActiveFarm()` + `ApiClient.setActiveFarmId()` |
| 所有 ranch 请求 | 不带 farm 前缀，靠 `x-active-farm` header | `ApiClient.farmGet('/...')` 自动拼接 `/farms/{activeFarmId}/...` |
| GoRouter 路由 | `/{page}` | `/{page}`（扁平结构，不含 farmId） |
| `FarmSwitcherController` | 调用 switch-farm 端点 | 本地状态管理 + `ApiClient.activeFarmId` 注入 |

---

## 6. 版本与演进策略

### 6.1 版本规则

| 前缀 | 版本承诺 | 破坏性变更策略 |
|------|---------|--------------|
| `/api/v1/` (App) | 尽量兼容，非破坏性迭代 | 破坏性变更必须新版本号 `/api/v2/`，旧版本至少保留 6 个月 |
| `/api/v1/admin/` | 与 App 同步 | 同上 |
| `/api/v1/open/` | **严格兼容承诺** | 破坏性变更必须递增 `/api/v1/open/v2/`，旧版本至少保留 12 个月 |

### 6.2 变更分类

**破坏性变更**（需递增版本号）:
- 删除或重命名已有字段
- 更改字段类型
- 更改 HTTP 方法或状态码语义
- 新增必填参数

**非破坏性变更**（不递增版本号）:
- 响应体新增字段
- 新增可选请求参数
- 新增端点
- 新增枚举值（**前提**: 客户端已实现未知枚举值容错）

### 6.3 废弃流程

| 步骤 | 动作 |
|------|------|
| 1. 标记废弃 | 响应头添加 `Deprecation: true` + `Sunset: <ISO 8601 date>` |
| 2. 文档标注 | API 文档标记为 `@deprecated`，注明替代方案 |
| 3. 过渡期 | App/Admin 至少 3 个月，Open API 至少 6 个月 |
| 4. 移除 | 过渡期结束后返回 410 Gone |

**已计划的废弃项:**

| 项目 | 标记时机 | 移除时机 |
|------|---------|---------|
| `x-active-farm` 请求头 | Phase 2 上线 | 标记后 3 个月 |
| Mock Server 全部端点 | Spring Boot Phase 1 上线 | 所有客户端迁移完成后 |

### 6.4 Phase 1 → Phase 2 新增端点

新增端点直接追加到 `/api/v1/` 下，不递增版本号：

| 上下文 | Phase 2 新增端点示例 | 挂载前缀 |
|--------|---------------------|---------|
| Health | `/farms/{farmId}/twin/fever/*`、`/twin/digestive/*`、`/twin/estrus/*`、`/twin/epidemic/*` | App + Open |
| Commerce | `/subscription/*`、`/contracts/*`、`/revenue/*` | App + Admin |
| Analytics | `/farms/{farmId}/stats/*`、`/farms/{farmId}/trends/*` | App + Admin |

---

## 7. 初始种子数据方案

Spring Boot 首次启动时通过 Flyway 迁移脚本预置以下种子数据，确保系统立即可用：

| 数据 | 说明 |
|------|------|
| **platform_admin 用户** | `phone: "13800000000"`, `password: "Admin@123"`, `role: platform_admin` |
| **SAMPLE 租户** | `name: "Demo牧场"`, `phase: SAMPLE` |
| **owner 用户** | `phone: "13800138000"`, `password: "Owner@123"`, `role: owner`, 归属 SAMPLE 租户 |
| **demo API Key** | `sl_test_` 前缀，绑定 SAMPLE 租户，scopes: `["livestock:read", "fence:read", "alert:read", "device:read", "gps:read"]` |

种子数据统一在 Flyway 迁移脚本 `V4__seed_data.sql` 中实现，密码使用 BCrypt 哈希。

---

## 8. 契约文档结构

```
docs/api-contracts/
├── api-overview.md              ← 本文件：总览、通用约定、认证、Farm Scope、版本策略
├── app-api.md                   ← /api/v1/ 全部 49 个端点（含 JSON 示例）
├── admin-api.md                 ← /api/v1/admin/ 全部 21 个端点（含 JSON 示例）
├── open-api.md                  ← /api/v1/open/ 全部 11 个端点 + 专属约定
├── changelog.md                 ← 变更日志
└── migration-guide.md           ← Mock Server → Spring Boot 迁移指南
```

每个端点文档包含：方法、路径、权限要求、请求参数/Body（含 JSON 示例）、成功响应示例、至少一种错误响应示例。

---

## 端点统计

| 前缀 | 端点数 |
|------|--------|
| App (`/api/v1/`) | 49 |
| Admin (`/api/v1/admin/`) | 21 |
| Open (`/api/v1/open/`) | 11 |
| **合计** | **81** |
