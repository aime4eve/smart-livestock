# 用户旅程与权限说明文档（基于代码实现）

> 本文档基于智慧畜牧系统（Smart Livestock）**实际代码实现**编写，描述各角色的登录、认证、权限与端到端旅程。
> 所有权限/流程声明均标注源文件路径，便于追溯。
> 代码现状与旧文档 `docs/customer-journey.md` 之间的差异，集中列入末尾「[已知不一致点](#7-已知不一致点)」一节。

---

## 目录

1. [角色总览](#1-角色总览)
2. [登录与认证机制](#2-登录与认证机制)
3. [路由守卫与访问控制](#3-路由守卫与访问控制)
4. [权限矩阵（基于代码）](#4-权限矩阵基于代码)
5. [各角色用户旅程](#5-各角色用户旅程)
6. [核心业务流程](#6-核心业务流程)
7. [已知不一致点](#7-已知不一致点)
8. [关键代码索引](#8-关键代码索引)

---

## 1. 角色总览

系统在后端定义 5 种角色枚举，前端有对应的 `UserRole` 枚举一一映射。

**后端角色枚举**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/model/Role.java`

```java
public enum Role {
    OWNER, WORKER, PLATFORM_ADMIN, B2B_ADMIN, API_CONSUMER
}
```

**前端角色枚举**：`Mobile/mobile_app/lib/core/models/user_role.dart`

| 后端 Role | 前端 UserRole | wireName | 操作端 | Shell 类型 | tenantId 归属 |
|-----------|---------------|----------|--------|-----------|--------------|
| `PLATFORM_ADMIN` | `platformAdmin` | `platform_admin` | 平台后台 `/ops/admin` | 无 Shell，纯 Scaffold | `null`（平台级，无租户归属） |
| `B2B_ADMIN` | `b2bAdmin` | `b2b_admin` | B 端控制台 `/b2b/admin` | 左侧 NavigationRail | 归属所属租户 |
| `OWNER` | `owner` | `owner` | 移动端 App | 底部导航栏（4-5 Tab） | 归属所属租户 |
| `WORKER` | `worker` | `worker` | 移动端 App | 底部导航栏（4 Tab） | 归属所属租户 |
| `API_CONSUMER` | `apiConsumer` | `api_consumer` | 开发者门户（Open API） | 无 App 端 UI | 归属所属租户 |

> `PLATFORM_ADMIN` 的 `tenantId` 为 `null`，是平台级身份，不归属任何租户。其余 4 种角色均归属某一租户。
> `UserRole.fromString` 遇到未知角色会 `debugPrint` 并回退为 `worker`（见 `user_role.dart` 的 `_unknown`）。

---

## 2. 登录与认证机制

### 2.1 登录端点

**控制器**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/AuthController.java`

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| POST | `/api/v1/auth/login` | 公开（permitAll） | 手机号 + 密码登录，返回 JWT |
| POST | `/api/v1/auth/refresh` | 公开（permitAll） | 刷新 access token（30 分钟宽限期） |
| POST | `/api/v1/auth/logout` | 公开（permitAll） | 无状态登出，客户端丢弃 token |

> 三个端点在 `SecurityConfig` 中 `permitAll()`（见下文 2.4）。

### 2.2 登录流程

**后端服务**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/application/AuthApplicationService.java`

```
POST /api/v1/auth/login { phone, password }
  → AuthApplicationService.login(LoginCommand)
      1. userRepository.findByPhone(phone) → 找不到则 AUTH_INVALID_TOKEN「手机号或密码错误」
      2. user.isActive() == false → AUTH_FORBIDDEN「用户已停用」
      3. passwordHasher.matches(password, user.passwordHash) → 不匹配则「手机号或密码错误」
      4. user.recordLogin()  // 更新 lastLoginAt
      5. jwtTokenProvider.generateToken(userId, tenantId, role.name())
  → 返回 { token, user: UserDto }
```

**注意**：用户停用后无法登录（`deactivate()` 为终态，不可重新激活，见 `User.java`）。停用状态校验发生在登录与刷新两处。

### 2.3 JWT 结构

**提供者**：`smart-livestock-server/src/main/java/com/smartlivestock/shared/security/JwtTokenProvider.java`

| Claim | 含义 | 来源 |
|-------|------|------|
| `subject` | userId（字符串） | `generateToken(userId, ...)` |
| `tid` | tenantId（Long） | 登录用户的 `user.tenantId` |
| `role` | 角色名（如 `OWNER`、`PLATFORM_ADMIN`） | `user.role.name()` |
| `iat` | 签发时间 | `new Date()` |
| `exp` | 过期时间 | `now + jwt.access-expiration` |

- 签名算法：HMAC（`Keys.hmacShaKeyFor(secret)`），密钥来自配置 `jwt.secret`。
- **JWT 中不含 farmId**。牧场作用域（activeFarmId）由前端 `SessionController` 管理，通过请求 URL 路径传递给后端（见 6.2）。

### 2.4 请求认证与上下文

**安全配置**：`smart-livestock-server/src/main/java/com/smartlivestock/shared/security/SecurityConfig.java`

- 会话策略：`STATELESS`（无服务端会话）。
- 过滤器链：`JwtAuthenticationFilter`（在 `UsernamePasswordAuthenticationFilter` 之前）→ `ApiKeyAuthFilter`（在 JWT 过滤器之后）。
- 公开路径：`/api/v1/auth/login`、`/api/v1/auth/refresh`、`/api/v1/auth/logout`、`/health`。
- 其余所有请求 `authenticated()`（含 `/api/v1/open/**`）。
- CORS 允许来源：`http://localhost:*`、`http://127.0.0.1:*`、`http://172.22.1.123:*`。

**JWT 过滤器**：`smart-livestock-server/src/main/java/com/smartlivestock/shared/security/JwtAuthenticationFilter.java`

```
从 Authorization: Bearer {token} 提取 token
  → 校验有效 → 解析 userId / tenantId / role
  → SecurityContext 设置 Authentication（authority = "ROLE_" + role）
  → TenantContext.setCurrentTenant(tenantId)
  → finally: TenantContext.clear()  // 线程级，请求结束清理
```

> 解析失败仅 `log.warn`，不中断请求；后续由 `authenticated()` 规则决定是否 401。401 时返回统一错误体：
> `{"code":"AUTH_INVALID_TOKEN","message":"未认证，请先登录",...}`。

### 2.5 Token 刷新

`JwtTokenProvider.refreshToken(token)`：
- token 有效 → 直接用其 claims 重新签发。
- token 已过期 → 接受过期 **30 分钟以内**（`REFRESH_GRACE_MS = 30 * 60 * 1000`）的 token，重新签发；超过宽限期返回 `null`。
- token 无效/损坏 → 返回 `null`，刷新接口抛 `AUTH_INVALID_TOKEN「Token 无法刷新，请重新登录」`。

### 2.6 Open API 的 API Key 认证

**过滤器**：`smart-livestock-server/src/main/java/com/smartlivestock/shared/security/ApiKeyAuthFilter.java`

- 适用于 `/api/v1/open/**`（面向第三方/API 消费者）。
- 仅在 JWT 未建立认证时生效（JWT 优先）。
- API Key 提取方式：
  - 请求头 `X-API-Key`；或
  - `Authorization: Bearer sk_live_...`（前缀 `sk_live_`）。
- 校验通过 → 设置 `Authentication`（authority = `ROLE_` + key.role，默认 `ADMIN`）+ `TenantContext` + 请求属性 `apiKey`。
- 校验失败 → 401，`{"code":"AUTH_API_KEY_INVALID","message":"API Key 无效"}`。

### 2.7 前端会话管理

**控制器**：`Mobile/mobile_app/lib/app/session/session_controller.dart`
**会话状态**：`Mobile/mobile_app/lib/app/session/app_session.dart`

```
SessionController.login(phone, password)
  → ApiClient.instance.login(...)  // 调用后端 /auth/login
  → 解析 role → UserRole.fromString
  → state = AppSession.authenticated(role, accessToken, userId, userName, phone, tenantId, username)
  → GoRouter 监听 sessionControllerProvider，自动触发 redirect

updateActiveFarm(farmId)  // 切换牧场
  → state.copyWith(activeFarmId)
  → ApiClient.setActiveFarmId(farmId)
  → JwtStorage.saveActiveFarmId(farmId)  // 本地持久化

logout()
  → ApiClient.logout()
  → state = AppSession.loggedOut
  → setActiveFarmId(null)
```

- `AppSession.isLoggedIn` 判定依据：`role != null`。
- Web 端通过 `initialSessionProvider` 在 `main.dart` 覆盖，实现刷新页面后恢复登录态（从 `JwtStorage` 读取持久化 token）。

### 2.8 种子登录凭据

| 角色 | 手机号 | 密码 | 说明 |
|------|--------|------|------|
| platform_admin | `13800000000` | `123` | 平台级管理，无租户归属 |
| b2b_admin | `13900139000` | `123` | B 端管理员，关联 Demo 租户（V13 seed） |
| owner | `13800138000` | `123` | Demo 租户 owner，关联主牧场 |

> 密码哈希经 BCrypt 生成并写入 Flyway seed 迁移。修改种子密码须遵循「生成时验证 → 写入迁移 → 部署后 curl 验证」三步流程。

---

## 3. 路由守卫与访问控制

### 3.1 Redirect 规则

**路由守卫**：`Mobile/mobile_app/lib/app/app_router.dart`（`redirect` 函数）

| 条件 | 行为 |
|------|------|
| 未登录（`!session.isLoggedIn`） | 任何非 `/login` 页面 → `/login` |
| `platformAdmin` | 仅放行 `/ops/admin/*` 与 `/admin/*`，其余 → `/ops/admin` |
| `b2bAdmin` | 仅放行 `/b2b/admin/*`，其余 → `/b2b/admin` |
| 已登录访问 `/login` 或 `/ops/admin/*` | → `/ranch` |
| 已登录访问 `/admin`（owner 除外） | → `/ranch` |
| 访问 `/mine/workers` 且 `role != owner` | → `/ranch` |

### 3.2 各角色默认落地页（首页）

> ⚠️ **重要**：owner 和 worker 登录后默认落地页是 **`/ranch`（RanchPage，牧场页）**，不是 `/twin`。这与旧文档描述不一致（见 [第 7 节](#71-默认落地页)）。

| 角色 | 登录后首页 | Shell |
|------|-----------|-------|
| platform_admin | `/ops/admin`（平台后台） | 无 Shell，纯 Scaffold |
| b2b_admin | `/b2b/admin`（B 端概览） | 左侧 NavigationRail |
| owner | `/ranch`（牧场页） | 底部导航栏 |
| worker | `/ranch`（牧场页） | 底部导航栏 |

### 3.3 路由定义

**路由表**：`Mobile/mobile_app/lib/app/app_route.dart`（`AppRoute` 枚举，路径唯一来源）

- **owner / worker（App 端）** — 位于 `ShellRoute(MainShell)` 内，共用底部导航栏：
  `/ranch`、`/twin`（含 `/twin/fever`、`/twin/fever/:livestockId`、`/twin/digestive[/:id]`、`/twin/estrus[/:id]`、`/twin/epidemic`）、`/alerts`、`/mine`、`/fence`、`/fence/form`、`/devices`、`/stats`、`/livestock/:id`。
- **owner 独有（App 端）** — `/admin`（后台 Tab）、`/mine/workers`（牧工管理）、`/admin/contracts`、`/admin/revenue`、`/admin/subscriptions`、`/admin/api-auth`、`/admin/audit-logs`、`/admin/feature-gates`、`/admin/analytics`、`/admin/tiles`、`/mine/api-auth`、`/subscription/plans`、`/subscription/checkout`、`/farm/create`、`/offline/tiles`、`/fence/conflict`。
- **platform_admin** — `/ops/admin`、`/ops/admin/create`、`/ops/admin/:id`、`/ops/admin/:id/edit`（租户管理），以及 `/admin/*`（合同/对账/订阅服务/API 授权/审计/门控/分析/瓦片）。
- **b2b_admin** — `/b2b/admin`、`/b2b/admin/farms`、`/b2b/admin/farms/create`、`/b2b/admin/farms/:farmId`、`/b2b/admin/contract`、`/b2b/admin/revenue`、`/b2b/admin/revenue/:id`。
- **worker 限制** — `/admin`、`/mine/workers` 被守卫拦截重定向到 `/ranch`；其他 App 页面可访问，但写操作受前端 `RolePermission` 限制（见第 4 节）。

---

## 4. 权限矩阵（基于代码）

系统存在 **三层** 权限控制，分别在不同层面生效：

1. **前端路由守卫**（`app_router.dart`）— 控制页面可见性（第 3 节）。
2. **前端操作权限**（`role_permission.dart`）— 控制页面内按钮/动作的可用性。
3. **后端方法权限**（Controller 的 `@PreAuthorize` 或代码内 `requirePlatformAdmin()`）— 控制接口调用的最终授权。

### 4.1 前端操作权限

**来源**：`Mobile/mobile_app/lib/core/permissions/role_permission.dart`

| 操作（方法） | owner | worker | platform_admin | b2b_admin |
|-------------|:-----:|:------:|:--------------:|:---------:|
| `canAddFence` / `canEditFence` / `canDeleteFence` | ✅ | ✗ | ✗ | ✗ |
| `canAcknowledgeAlert` | ✅ | ✅ | ✗ | ✗ |
| `canHandleAlert` / `canArchiveAlert` / `canBatchAlerts` | ✅ | ✗ | ✗ | ✗ |
| `canTwinBreedingAction`（数智孪生繁育操作） | ✅ | ✗ | ✗ | ✗ |
| `canManageSubscription` | ✅ | ✗ | ✗ | ✗ |
| `canManageTenants`（含 create/edit/delete/toggle/license） | ✅ | ✗ | ✅ | ✗ |
| `canReviewApiAuthorizations` | ✅ | ✗ | ✅ | ✗ |
| `canViewContract` | ✗ | ✗ | ✗ | ✅ |
| `canViewB2bDashboard` | ✗ | ✗ | ✗ | ✅ |
| `canViewRevenue` | ✗ | ✗ | ✅ | ✅ |
| `canCreateFarm` | ✗ | ✗ | ✅ | ✅ |
| `canManageContracts` / `canCalculateRevenue` | ✗ | ✗ | ✅ | ✗ |
| `canManageSubscriptionServices` | ✗ | ✗ | ✅ | ✗ |
| `canManageSubfarmWorkers` | ✗ | ✗ | ✗ | ✅ |

> 注：`canManageTenants = owner || platformAdmin`，`canCreateFarm = b2bAdmin || platformAdmin`，`canViewRevenue = platformAdmin || b2bAdmin`，`canReviewApiAuthorizations = platformAdmin || owner`。这些与后端实现存在差异（见 [第 7 节](#7-已知不一致点)）。

### 4.2 后端方法权限

后端权限有两种实现方式：声明式 `@PreAuthorize` 注解 与 代码内 `requirePlatformAdmin()` 手动校验。

**(A) 声明式 `@PreAuthorize`**（Ranch / IoT 业务接口写操作）

| Controller | 端点操作 | 注解 |
|------------|---------|------|
| `LivestockController` | 牲畜创建/更新/删除（3 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `FenceController` | 围栏创建/删除（2 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `FenceController` | 围栏导入（1 处） | `hasRole('PLATFORM_ADMIN')` |
| `FenceZoneController` | 围栏区域（1 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `AlertController` | 告警状态变更（4 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `DeviceController` | 设备绑定/解绑（4 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |

> **关键**：后端 Ranch/IoT **写操作不含 worker**。worker 在前端可「确认告警」，但后端告警接口 `@PreAuthorize` 仅允许 OWNER/B2B_ADMIN，实际调用会被拒（差异见 [第 7 节](#74-worker-权限前后端边界)）。

**(B) 代码内 `requirePlatformAdmin()`**（Admin API）

**来源**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/admin/UserAdminController.java:268`

```java
private void requirePlatformAdmin() {
    Authentication auth = SecurityContextHolder.getContext().getAuthentication();
    boolean isAdmin = auth.getAuthorities().stream()
        .anyMatch(a -> a.getAuthority().equals("ROLE_PLATFORM_ADMIN"));
    if (!isAdmin) throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "需要 platform_admin 角色");
}
```

| Admin Controller（`/api/v1/admin/*`） | 权限要求 |
|---------------------------------------|---------|
| `TenantAdminController`（`/admin/tenants`） | `requirePlatformAdmin()`（仅 PLATFORM_ADMIN） |
| `UserAdminController`（`/admin/users`） | `requirePlatformAdmin()`（仅 PLATFORM_ADMIN） |
| `FarmAdminController`（`/admin/farms`） | Admin 系列 |
| `AuditLogController`（`/admin/audit-logs`） | Admin 系列 |
| `ApiKeyAdminController`（`/admin/api-keys`） | Admin 系列 |
| `DashboardAdminController`（`/admin/dashboard`） | Admin 系列 |
| `AdminContractController`（`/admin/contracts`） | Commerce Admin |
| `AdminRevenueController`（`/admin/revenue`） | Commerce Admin |
| `AdminSubscriptionController`（`/admin/subscriptions`） | Commerce Admin |
| `AdminServiceController`（`/admin/subscription-services`） | Commerce Admin |
| `AdminFeatureGateController`（`/admin/feature-gates`） | Commerce Admin |
| `AnalyticsAdminController`（`/admin/analytics`） | Analytics Admin |
| `PortalAdminController`（`/admin/portal/keys`） | Analytics Admin |
| `TileAdminController`（`/admin/tiles`） | `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")` |

> 其中 `TenantAdminController` 和 `UserAdminController` 明确用 `requirePlatformAdmin()` 仅允许 PLATFORM_ADMIN。

**(C) 创建牧场**（App API，`/api/v1/farms`）

**来源**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/FarmController.java:58`

```java
if (!user.isOwner() && !user.getRole().name().equals("B2B_ADMIN")) {
    throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "仅 owner 或 b2b_admin 可创建牧场");
}
```

> 允许 OWNER 或 B2B_ADMIN。owner 自建时 `ownerId = userId`；b2b_admin 创建时可指定 `ownerId` 分配给 owner。

### 4.3 三层权限对照速查

| 能力 | 前端 RolePermission | 后端实际 |
|------|---------------------|---------|
| 创建牧场 | `b2bAdmin \|\| platformAdmin` | `OWNER \|\| B2B_ADMIN` |
| 管理租户 | `owner \|\| platformAdmin` | 仅 `PLATFORM_ADMIN`（requirePlatformAdmin） |
| Ranch/IoT 写操作 | `canEditFence` 仅 owner | `OWNER \|\| B2B_ADMIN` |
| 确认告警 | `owner \|\| worker` | `OWNER \|\| B2B_ADMIN`（不含 worker） |
| Tile 管理 | — | `PLATFORM_ADMIN \|\| B2B_ADMIN` |

---

## 5. 各角色用户旅程

### 5.1 platform_admin（平台管理员）

```
登录（13800000000 / 123，tenantId=null）
  → 重定向到 /ops/admin（租户列表，TenantListPage）
  → 创建租户（TenantCreatePage）→ 进入租户详情（TenantDetailPage）
  → 在租户详情新增用户：b2b_admin / owner / worker（UserAdminController）
  → 管理租户启停、License 调整
  → /admin/contracts 合同管理（AdminContractController）
  → /admin/revenue 对账看板与分润计算（AdminRevenueController）
  → /admin/subscriptions 订阅服务管理（AdminSubscriptionController）
  → /admin/api-keys、/admin/portal/keys 审批 API 授权（ApiKeyAdminController）
  → /admin/audit-logs 审计日志
  → /admin/analytics 用量分析
  → /admin/feature-gates 功能门控
  → /admin/tiles 瓦片管理
```

**权限**：Admin API 全部要求 `ROLE_PLATFORM_ADMIN`。可访问 `/ops/admin/*` 与 `/admin/*`，不能访问普通 App 业务页（路由守卫强制重定向）。

### 5.2 b2b_admin（B 端管理员）

```
登录（13900139000 / 123，归属 Demo 租户）
  → 重定向到 /b2b/admin（概览看板，B2bDashboardPage）
  → /b2b/admin/farms 创建牧场 → 分配给 owner（FarmController: OWNER|B2B_ADMIN 可创建）
  → /b2b/admin/farms/:farmId 管理旗下牧工（B2bWorkerDetailPage）
  → /b2b/admin/contract 查看合同信息（canViewContract）
  → /b2b/admin/revenue[/:id] 对账与分润明细（canViewRevenue）
```

**权限**：锁定在 `/b2b/admin/*`。后端 Ranch/IoT 写操作（`hasAnyRole('OWNER','B2B_ADMIN')`）允许 b2b_admin 操作牲畜/围栏/设备/告警。Tile 管理对 b2b_admin 开放。

### 5.3 owner（牧场主）

```
登录（13800138000 / 123，归属 Demo 租户）
  → 重定向到 /ranch（牧场页，默认首页）
  → /twin 数智孪生：GPS 地图、牲畜概览、健康预警（fever/digestive/estrus/epidemic）
  → /alerts 告警管理：确认 / 处理 / 归档 / 批量（canHandle/Archive/Batch）
  → /fence 围栏管理：创建 / 编辑 / 删除（canEditFence）
  → /devices 设备管理：GPS 追踪器、瘤胃胶囊（OWNER 可写）
  → /livestock/:id 牲畜详情
  → /admin 后台 Tab：租户信息、订阅管理
  → /admin/contracts、/admin/revenue、/admin/subscriptions（owner 可见但后端 Admin API 要求 PLATFORM_ADMIN）
  → /mine/workers 牧工管理：添加 / 移除牧工
  → /mine/api-auth API 授权管理（canReviewApiAuthorizations）
  → /subscription/plans → /subscription/checkout 订阅升级
  → /stats 数据统计、/offline/tiles 离线地图、/farm/create 创建牧场
```

**权限**：可见全部 App 页面 + 后台 + 牧工管理 + 订阅。Ranch/IoT 写操作允许。可创建牧场（OWNER）。

### 5.4 worker（牧工）

```
登录（账号由 owner/admin 创建）
  → 重定向到 /ranch（牧场页）
  → /twin 数智孪生：查看地图、牲畜位置（只读）
  → /alerts 告警：确认告警（canAcknowledgeAlert），不可处理/归档
  → /fence 围栏：只查看（canEditFence=false）
  → /mine 个人资料、牧场切换
  ✗ /admin、/mine/workers 被守卫拦截 → 重定向到 /ranch
```

**权限**：4 个 Tab（牧场/孪生/告警/我的）。前端允许确认告警；但注意后端告警接口 `@PreAuthorize` 不含 worker（差异见 [第 7 节](#74-worker-权限前后端边界)）。

### 5.5 api_consumer（API 开发者）

- 仅通过 Open API（`/api/v1/open/**`）访问，使用 API Key 认证（`X-API-Key` 或 `Bearer sk_live_...`）。
- 无 App 端 UI（开发者门户 MVP Phase 2c 规划中）。
- 受频率限制约束。

---

## 6. 核心业务流程

### 6.1 平台入驻链

```
platform_admin
  → 创建租户（TenantAdminController，requirePlatformAdmin）
  → 在租户下新增 b2b_admin / owner / worker（UserAdminController，requirePlatformAdmin）

b2b_admin（或 owner）
  → 创建牧场（FarmController，OWNER|B2B_ADMIN 可创建）
  → b2b_admin 创建时指定 ownerId 分配给 owner

owner
  → 管理牲畜、围栏、告警、牧工（日常运营）
```

> 约束（代码现状）：牧场可由 OWNER 或 B2B_ADMIN 创建；租户与用户的创建仅限 PLATFORM_ADMIN。

### 6.2 牧场作用域（activeFarmId）传递机制

> ⚠️ 重要澄清：activeFarmId **不**随 JWT 传递，而是由前端在请求 URL 路径中编码。

**前端**：`Mobile/mobile_app/lib/core/api/api_client.dart`

```dart
farmGet(suffix)  => get('/farms/$_activeFarmId$suffix');   // farmId 编码进 URL path
farmPost(suffix) => post('/farms/$_activeFarmId$suffix');
farmPut(suffix)  => put('/farms/$_activeFarmId$suffix');
farmDelete(suffix) => delete('/farms/$_activeFarmId$suffix');
```

- `_activeFarmId` 由 `SessionController.updateActiveFarm` 设置，并持久化到 `JwtStorage`。
- 请求头只携带 `Content-Type` 和 `Authorization: Bearer {token}`，**不**发送 `x-active-farm`。

**后端**：`smart-livestock-server/src/main/java/com/smartlivestock/shared/scope/FarmScopeInterceptor.java` + `FarmScopeResolver.java`

- 从 URL path 提取 farmId（`FarmIdPathParser.extractFarmId`），或从请求头 `x-active-farm` 读取。
- **禁止**同时提供 path farmId 和 header（读写均禁止，抛 `FARM_SCOPE_CONFLICT`）。
- 写操作：必须由 path 提供 farmId（不接受仅 header）。
- 读操作：path 或 header 任一即可。
- 校验牧场归属租户（`PLATFORM_ADMIN` 和 Open API 跳过此校验）。
- 解析结果存入 `request.setAttribute("resolvedFarmId", farmId)`。

**牧场切换刷新规则**：使用 farm-scoped API 的 Controller 必须继承 `FarmScopedNotifier` / `FarmScopedAsyncNotifier`（`core/api/farm_scoped_controller.dart`），在 `build()` 调用 `watchActiveFarmId()` 以声明对 activeFarmId 的依赖，确保切换时自动重建。违反的典型症状：切换牧场后页面仍显示旧数据。

### 6.3 告警状态机

```
pending → acknowledged → handled → archived
```

| 转换 | 前端允许角色（RolePermission） | 后端注解 |
|------|------------------------------|---------|
| pending → acknowledged（确认） | owner, worker | `hasAnyRole('OWNER','B2B_ADMIN')` |
| acknowledged → handled（处理） | owner | 同上 |
| handled → archived（归档） | owner | 同上 |
| 非法跳转 | — | 返回 409 Conflict |

### 6.4 订阅与功能门控

- **订阅层级**（`SubscriptionTier`）：basic / standard / premium / enterprise。
- 配额引擎在后端 Commerce 上下文实现；前端 `feature-flags`（mock）/`FeatureGate` 按 tier 控制功能可见性。
- 低 tier 访问高 tier 功能时显示升级提示覆盖层；`ApiCache` 预加载时按 tier 过滤数据范围。

---

## 7. 已知不一致点

> 本节列出代码现状与旧文档 `docs/customer-journey.md` / 前后端声明之间的差异。以**代码实际行为**为准。

### 7.1 默认落地页

- **代码**：owner / worker 登录后重定向到 `/ranch`（`app_router.dart` redirect，`AppRoute.ranch.path`）。
- **旧文档**：称 owner 登录重定向到 `/twin`。
- **结论**：以代码为准，首页为 `/ranch`。

### 7.2 创建牧场角色

- **后端**（`FarmController.java:58`）：允许 `OWNER` 或 `B2B_ADMIN`。
- **前端**（`role_permission.dart`）：`canCreateFarm = b2bAdmin || platformAdmin`（不含 owner）。
- **结论**：后端允许 owner 创建牧场，但前端 `RolePermission` 未授予 owner 该能力。UI 上 owner 的创建牧场入口（`/farm/create`）是否实际可触发，取决于页面是否绕过 `RolePermission` 直接使用路由。

### 7.3 管理租户角色

- **后端**（`TenantAdminController` / `UserAdminController`）：`requirePlatformAdmin()` 仅 `PLATFORM_ADMIN`。
- **前端**（`role_permission.dart`）：`canManageTenants = owner || platformAdmin`。
- **结论**：前端授权 owner 管理租户，但后端 Admin API 会以 `AUTH_FORBIDDEN` 拒绝非 platform_admin 调用。

### 7.4 worker 权限前后端边界

- **前端**：worker 可确认告警（`canAcknowledgeAlert = owner || worker`）。
- **后端**：告警接口 `@PreAuthorize("hasAnyRole('OWNER','B2B_ADMIN')")` **不含 worker**。
- **结论**：worker 在 UI 上点「确认告警」，实际请求会被后端 403 拒绝。

### 7.5 Ranch 写操作角色范围

- **后端**：Ranch/IoT 写操作（围栏/牲畜/设备/告警）`hasAnyRole('OWNER','B2B_ADMIN')`，含 b2b_admin。
- **前端**：`canEditFence` 等仅 owner（不含 b2b_admin）。
- **结论**：后端对 b2b_admin 开放 Ranch 写操作，但前端 `RolePermission` 未授予 b2b_admin 编辑围栏能力。

---

## 8. 关键代码索引

| 关注点 | 文件路径 |
|--------|---------|
| 后端角色枚举 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/model/Role.java` |
| User 聚合（停用/激活终态） | `smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/model/User.java` |
| 登录控制器 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/AuthController.java` |
| 登录/刷新服务 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/application/AuthApplicationService.java` |
| JWT 生成/校验/刷新 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/JwtTokenProvider.java` |
| JWT 过滤器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/JwtAuthenticationFilter.java` |
| API Key 过滤器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/ApiKeyAuthFilter.java` |
| 安全配置 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/SecurityConfig.java` |
| 牧场作用域拦截器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/scope/FarmScopeInterceptor.java` |
| 牧场作用域解析器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/scope/FarmScopeResolver.java` |
| 创建牧场（角色校验） | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/FarmController.java` |
| Admin 租户管理 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/admin/TenantAdminController.java` |
| Admin 用户管理 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/admin/UserAdminController.java` |
| Ranch @PreAuthorize | `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/{Livestock,Fence,FenceZone,Alert}Controller.java` |
| IoT @PreAuthorize | `smart-livestock-server/src/main/java/com/smartlivestock/iot/interfaces/DeviceController.java` |
| 前端角色枚举 | `Mobile/mobile_app/lib/core/models/user_role.dart` |
| 前端操作权限 | `Mobile/mobile_app/lib/core/permissions/role_permission.dart` |
| 前端路由守卫 | `Mobile/mobile_app/lib/app/app_router.dart` |
| 前端路由表 | `Mobile/mobile_app/lib/app/app_route.dart` |
| 前端会话控制器 | `Mobile/mobile_app/lib/app/session/session_controller.dart` |
| 前端会话状态 | `Mobile/mobile_app/lib/app/session/app_session.dart` |
| 前端 API 客户端（farm scope） | `Mobile/mobile_app/lib/core/api/api_client.dart` |
| 前端登录页 | `Mobile/mobile_app/lib/features/auth/login_page.dart` |

---

*文档生成日期：2026-06-11 · 基于 `master` 分支实际代码实现。*
