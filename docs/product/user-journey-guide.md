# 用户旅程与权限说明文档（基于代码实现）

> 本文档基于智慧畜牧系统（Smart Livestock）**实际代码实现**编写，描述各角色的登录、认证、权限与端到端旅程。
> 所有权限/流程声明均标注源文件路径，便于追溯。
> **基线**：2026-09-20，基于当前工作区代码（分支 `nix/219-gateway-position-distance`）。上一版 2026-06-11（`master`）；与旧版差异主要来自：NIX-52 告警中心重设计（通知中心模型）、NIX-191 强制改密、NIX-214 设备配置规则、NIX-219/220 网关注册与覆盖诊断、GPS 质量与遥测导入、datagen 控制台、部署授权（NIX-184）等。
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
> `UserRole.fromString` 遇到未知角色会 `debugPrint` 并回退为 `worker`（`user_role.dart` 的 `_unknown`）。
> 前端角色辅助 getter（`user_role.dart:37-42`）：`canAccessAdminTab`（仅 owner，见 [7.3](#73-管理租户) —— 已成死权限）、`isPlatformAdmin`、`isB2bAdmin`、`isApiConsumer`、`isOwner`、`isWorker`。

---

## 2. 登录与认证机制

### 2.1 登录端点

**控制器**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/AuthController.java`

| 方法 | 路径 | 认证 | 说明 |
|------|------|------|------|
| POST | `/api/v1/auth/login` | 公开（permitAll） | 手机号 + 密码登录，返回 JWT |
| POST | `/api/v1/auth/refresh` | 公开（permitAll） | body 携带当前 accessToken，重新签发（30 分钟宽限期） |
| POST | `/api/v1/auth/logout` | 公开（permitAll） | 无状态登出，客户端丢弃 token |

> 匿名可达的其他端点（`SecurityConfig.java:44-71`）：`/health`、`GET /api/v1/deployment-info`（登录页公开部署描述符，`DeploymentInfoController` 2026-09-04）、`GET /api/v1/admin/deployment-license/enrollment` 与 `POST /api/v1/admin/deployment-license`（NIX-184 首证书窗口，`DeploymentLicenseAdminController`）。
> 改密不在 AuthController：`PUT /api/v1/me/password` 在 `MeController`（见 2.8）。

### 2.2 登录流程

**后端服务**：`smart-livestock-server/src/main/java/com/smartlivestock/identity/application/AuthApplicationService.java:25-38`

```
POST /api/v1/auth/login { phone, password }
  → AuthApplicationService.login(LoginCommand)
      1. userRepository.findByPhone(phone) → 找不到则 AUTH_INVALID_TOKEN「手机号或密码错误」
      2. user.isActive() == false → AUTH_FORBIDDEN「用户已停用」（deactivate 为终态，不可重新激活）
      3. passwordHasher.matches(password, user.passwordHash) → 不匹配则「手机号或密码错误」
      4. user.recordLogin()  // 更新 lastLoginAt
      5. jwtTokenProvider.generateToken(userId, tenantId, role.name())
  → 返回 { token, user: UserDto }   // UserDto 携带 boolean mustChangePassword
```

> **login 本身不检查 mustChangePassword**；该标志由拦截器 `PasswordChangeRequiredInterceptor` 在每次请求时拦截（见 2.8）。

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

**安全配置**：`smart-livestock-server/src/main/java/com/smartlivestock/shared/security/SecurityConfig.java:44-105`

- 会话策略：`STATELESS`（无服务端会话）。
- 过滤器链：`JwtAuthenticationFilter`（在 `UsernamePasswordAuthenticationFilter` 之前）→ `ApiKeyAuthFilter`（在 JWT 过滤器之后，仅在 JWT 未建立认证时介入）。
- 公开路径：`/api/v1/auth/login`、`/api/v1/auth/refresh`、`/api/v1/auth/logout`、`/health`、`GET /api/v1/deployment-info`、`GET /api/v1/admin/deployment-license/enrollment`、`POST /api/v1/admin/deployment-license`。
- 其余所有请求 `authenticated()`（含 `/api/v1/open/**`）。401 返回统一错误体 `{"code":"AUTH_INVALID_TOKEN","message":"未认证，请先登录",...}`。
- CORS：`http://localhost:*`、`http://127.0.0.1:*`、`http://172.22.1.123:*`、`https://ah.hkttech.cn`。

**JWT 过滤器**：`shared/security/JwtAuthenticationFilter.java:34-74`

```
从 Authorization: Bearer {token} 提取 token
  → 校验有效 → 解析 userId / tenantId / role
  → SecurityContext 设置 Authentication（authority = "ROLE_" + role）
  → TenantContext.setCurrentTenant(tenantId)
  → finally: TenantContext.clear()  // 线程级，请求结束清理
```

> 解析失败仅 `log.warn`，不中断请求；后续由 `authenticated()` 规则决定是否 401。

**拦截器链**（`shared/WebMvcConfig.java:42-85`，顺序）：
`passwordChangeRequired` → `license` → `open-scope/rate-limit`（仅 `/api/v1/open/**`）→ `apiCallLog` → `farmScope` → `quota`。

### 2.5 Token 刷新

**后端** `JwtTokenProvider.refreshToken(token)`（`JwtTokenProvider.java:82-101`，`REFRESH_GRACE_MS = 30 * 60 * 1000`）：
- token 有效 → 直接用其 claims 重新签发。
- token 已过期 → 接受过期 **30 分钟以内**的 token，重新签发；超过宽限期返回 `null`。
- token 无效/损坏 → 返回 `null`，刷新接口抛 `AUTH_INVALID_TOKEN「Token 无法刷新，请重新登录」`。

**前端自动刷新**（`Mobile/mobile_app/lib/core/api/api_client.dart:190-263`）：`_withRefreshRetry` 捕获 `401 && code == 'AUTH_INVALID_TOKEN'` → `_tryRefresh()`（并发合并为单次 `POST /auth/refresh`，body 携带当前可能已过期的 token）→ 成功则保存新 token 并重试原请求；失败则 `JwtStorage.clear()`。401 响应处理时**故意不清 token**（清掉会饿死并发中的 refresh，导致永久登出）。

### 2.6 Open API 的 API Key 认证

**过滤器**：`shared/security/ApiKeyAuthFilter.java`

- 适用于 `/api/v1/open/**`（面向第三方/API 消费者）。
- 仅在 JWT 未建立认证时生效（JWT 优先）。
- API Key 提取方式：请求头 `X-API-Key`；或 `Authorization: Bearer sk_live_...`（前缀 `sk_live_`）。
- 校验通过 → 设置 `Authentication`（authority = `ROLE_` + key.role，默认 `ADMIN`）+ `TenantContext` + 请求属性 `apiKey`；校验失败 → 401，`{"code":"AUTH_API_KEY_INVALID","message":"API Key 无效"}`。
- **Scope 校验**：`shared/scope/ScopeInterceptor.java`（仅 `/api/v1/open/**` 注册，`WebMvcConfig.java:67-68`）。scope 清单：`livestock:read, fence:read, alert:read, device:read, device:register, gps:read, health:read, *`；URI→scope 映射后缺 scope 返回 403。
- **频率限制**：open-scope 拦截器链中的 rate-limit 环节（Analytics 上下文）。

### 2.7 前端会话管理

**控制器**：`Mobile/mobile_app/lib/app/session/session_controller.dart`
**会话状态**：`Mobile/mobile_app/lib/app/session/app_session.dart:30-57`

```
SessionController.login(phone, password)
  → ApiClient.instance.login(...)  // 调用后端 /auth/login
  → 解析 role → UserRole.fromString
  → state = AppSession.authenticated(role, accessToken, userId, ..., tenantId, username,
                                    mustChangePassword: user['mustChangePassword'] == true)
  → owner/worker 且非强制改密时后台预取 loadFarms()
  → GoRouter 监听 sessionControllerProvider（refreshListenable），自动触发 redirect

updateActiveFarm(farmId)  // 切换牧场
  → state.copyWith(activeFarmId)
  → ApiClient.setActiveFarmId(farmId)
  → JwtStorage.saveActiveFarmId(farmId)  // 本地持久化

markPasswordChanged()  // NIX-191：清除强制改密锁（:57-59）

logout()
  → ApiClient.logout()
  → state = AppSession.loggedOut
  → setActiveFarmId(null)
```

- `AppSession.isLoggedIn` 判定依据：`role != null`。
- **初始恢复**（`main.dart:64-101` `_restoreSession`）：读持久化 JWT → 过期/无效即清空回登录页；恢复 `activeFarmId` 回 `ApiClient`；**恢复路径未读取 mustChangePassword**（重启后强制改密锁默认失效，见 [7.7](#77-会话恢复不读-mustchangepassword)）。

### 2.8 强制改密（NIX-191，2026-09 新增）

**触发来源**：
- `UserAdminController` 新增用户 `POST /api/v1/admin/users`（`UserAdminController.java:95-147`）：密码缺省 `Default@123`，构造时第 5 参 `mustChangePassword=true` —— **平台管理员新建用户首登强制改密**。
- `UserAdminController` 重置密码 `POST /api/v1/admin/users/{userId}/reset-password`（`:248-269`）：运营者重置的密码视为「他人凭证」，**重新武装强制改密**。
- 对照：`B2bController` 创建 WORKER（`:390-427`）与重置牧工密码（`:514-540`）**均不置/不武装该标志**（见 [7.8](#78-b2b-重置密码不重新武装强制改密)）。

**后端拦截**：`shared/security/PasswordChangeRequiredInterceptor.java:27-41`
`must_change_password == true` 的账户，除白名单外所有 API 抛 `PASSWORD_CHANGE_REQUIRED` → HTTP **403**。白名单前缀：`/api/v1/auth/`、`/api/v1/me/password`、`/api/v1/deployment-info`、`/api/v1/admin/deployment-license/`；精确匹配：`/api/v1/me`、`/api/v1/deployment-info`、`/health`。

**前端闭环**：
1. 登录响应 `mustChangePassword == true` → `AppSession.mustChangePassword`（`session_controller.dart:33`）。
2. 路由 redirect 把所有位置锁定到 `/me/password-change`（`app_router.dart:94-97`）。
3. `ForcedPasswordChangePage`（顶层路由，位于所有 Shell 之外，`app_router.dart:144-148`）：`PUT /me/password`，body `{oldPassword, newPassword}`；新密码校验 **≥10 位且含字母+数字**（后端 `MeController.java:111-114` 同规则）。
4. 成功后写新 hash、清除 `must_change_password`（`User.completePasswordChange()`），前端 `markPasswordChanged()` 并按角色跳转：`platformAdmin → /ops/admin`，否则 `/ranch`。

### 2.9 种子登录凭据

| 角色 | 手机号 | 密码 | 说明 |
|------|--------|------|------|
| platform_admin | `13800000000` | `123` | 平台级管理，无租户归属（V20260907 admin bootstrap） |
| b2b_admin | `13900139000` | `123` | B 端管理员，关联 Demo 租户 |
| owner | `13800138000` | `123` | Demo 租户 owner，关联主牧场 |
| worker | `13800138001` | `123` | Demo 租户牧工，主牧场 |

> 密码哈希经 BCrypt 生成并写入 Flyway seed 迁移。修改种子密码须遵循「生成时验证 → 写入迁移 → 部署后 curl 验证」三步流程（可用 `scripts/verify-seed-hash.sh`）。**对外交付环境须轮换公开凭据。**

---

## 3. 路由守卫与访问控制

### 3.1 Redirect 规则

**路由守卫**：`Mobile/mobile_app/lib/app/app_router.dart:84-135`

| 优先级 | 条件 | 行为 |
|------|------|------|
| 1 | 未登录（`!session.isLoggedIn`） | 任何非 `/login` 页面 → `/login` |
| 2 | `mustChangePassword == true` | 所有位置锁定 → `/me/password-change` |
| 3 | `platformAdmin` | 仅放行 `/ops/admin` 与 `/admin/` 前缀，其余 → `/ops/admin` |
| 4 | `b2bAdmin` | 放行 `/b2b/admin` 前缀 + `/admin/datagen` + `/admin/tiles`，其余 → `/b2b/admin` |
| 5 | owner/worker 访问 `/login` 或 `/ops/admin` | → `/ranch` |
| 6 | **任何非上述放行的角色**访问 `/admin` 或 `/admin/*`（含 owner） | → `/ranch` |
| 7 | 访问 `/mine/workers` 且 `role != owner` | → `/ranch` |

> ⚠️ 与旧文档差异：旧版写「已登录访问 `/admin`（owner 除外）→ `/ranch`」；**当前代码 owner 同样被重定向**（`app_router.dart:123-127` 注释明确「/admin/** 管理页仅平台管理员可入」）。owner 的后台管理 Tab 已不可达（见 [7.3](#73-管理租户)）。

### 3.2 各角色默认落地页（首页）

> owner 和 worker 登录后默认落地页是 **`/ranch`（RanchPage，牧场页）**。

| 角色 | 登录后首页 | Shell |
|------|-----------|-------|
| platform_admin | `/ops/admin`（平台后台租户列表） | 无 Shell，纯 Scaffold |
| b2b_admin | `/b2b/admin`（B 端概览） | 左侧 NavigationRail |
| owner | `/ranch`（牧场页） | 底部导航栏 |
| worker | `/ranch`（牧场页） | 底部导航栏 |

> 登录页本身不显式 `context.go`，依赖 GoRouter `refreshListenable` 由 redirect 决定落地页（`login_page.dart:39-72`）。登录页另含 License 模式徽标/横幅（NIX-184）、待激活「复制登记信息」按钮、语言切换。

### 3.3 路由定义

**路由表**：`Mobile/mobile_app/lib/app/app_route.dart`（AppRoute 枚举，47 项，路径唯一来源）

- **owner / worker 共用（App 端，MainShell 底部导航栏）**：
  `/ranch`、`/twin`（含 `/twin/fever`、`/twin/fever/:livestockId`、`/twin/digestive[/:id]`、`/twin/estrus[/:id]`、`/twin/epidemic`、`/twin/epidemic/contacts`）、`/alerts`、`/mine`、`/fence`、`/fence/form`、`/fence/conflict`、`/devices`、`/stats`、`/livestock`、`/livestock/:id`、`/mine/gateways`、`/mine/gateways/:gatewayId`、`/mine/coverage-diagnostics`、`/mine/api-auth`、`/mine/help`、`/subscription`、`/subscription/plans`、`/subscription/checkout`。
- **owner 独有（守卫层面）**：仅 `/mine/workers`（牧工管理）。其余共用路由对 worker 无前端限制（写操作由 `RolePermission` 控制按钮可用性）。
- **owner 不可达**：`/admin`（枚举仍存在但**无 GoRoute 注册**，redirect 直接重定向 `/ranch`）。
- **platform_admin**：`/ops/admin`（+ `create` / `:id` / `:id/edit` 子路由），以及 `/admin/contracts`、`/admin/revenue`、`/admin/subscriptions`、`/admin/deployment-license`、`/admin/api-auth`、`/admin/audit-logs`、`/admin/feature-gates`、`/admin/analytics`、`/admin/tiles`、`/admin/device-profile-rules`、`/admin/gps-quality`、`/admin/telemetry-import`、`/admin/datagen`、`/admin/gateway-overview`。
- **b2b_admin**：`/b2b/admin`、`/b2b/admin/farms`、`/b2b/admin/farms/create`、`/b2b/admin/farms/:farmId`（牧工详情）、`/b2b/admin/contract`、`/b2b/admin/revenue`、`/b2b/admin/revenue/:id`；例外放行 `/admin/tiles`（瓦片管理）与 `/admin/datagen`（仿真控制台，后端允许 B2B_ADMIN）。
- **顶层（Shell 外）**：`/login`、`/me/password-change`（不在枚举内）、`/farm/create`（创建牧场向导）、`/offline/tiles`（离线地图管理）、`/dashboard`（遗留）。

**弹层形态的功能（无独立路由）**：
- **告警详情**：底部弹层 `showAlertDetailSheet`（`features/pages/alerts_page.dart:557-559` / `features/alerts/presentation/widgets/alert_detail_sheet.dart`）；`/alerts` 支持 query 参数 `category` / `fenceId` 过滤。
- **设备开通向导**：底部弹层 `TbDeviceWizardSheet`（`features/devices/presentation/widgets/tb_device_wizard_sheet.dart:29`），由设备页 `showModalBottomSheet` 打开。

---

## 4. 权限矩阵（基于代码）

系统存在 **三层** 权限控制，分别在不同层面生效：

1. **前端路由守卫**（`app_router.dart`）— 控制页面可见性（第 3 节）。
2. **前端操作权限**（`role_permission.dart`）— 控制页面内按钮/动作的可用性。
3. **后端方法权限**（Controller 的 `@PreAuthorize` / `requirePlatformAdmin()` / 手写校验）— 控制接口调用的最终授权。

### 4.1 前端操作权限

**来源**：`Mobile/mobile_app/lib/core/permissions/role_permission.dart`（`apiConsumer` 在所有方法下均为 false）

| 操作（方法） | owner | worker | platform_admin | b2b_admin |
|-------------|:-----:|:------:|:--------------:|:---------:|
| `canAddFence` / `canEditFence` / `canDeleteFence` | ✅ | ✗ | ✗ | ✗ |
| `canAcknowledgeAlert` | ✅ | ✅ | ✗ | ✗ |
| `canHandleAlert` / `canArchiveAlert` / `canBatchAlerts` | ✅ | ✗ | ✗ | ✗ |
| `canTwinBreedingAction`（数智孪生繁育操作） | ✅ | ✗ | ✗ | ✗ |
| `canManageSubscription` | ✅ | ✗ | ✗ | ✗ |
| `canCreateTenant` / `canEditTenant` / `canDeleteTenant` / `canToggleTenantStatus` / `canAdjustLicense`（均委托 `canManageTenants`） | ✅ | ✗ | ✅ | ✗ |
| `canManageTenants` | ✅ | ✗ | ✅ | ✗ |
| `canReviewApiAuthorizations` | ✅ | ✗ | ✅ | ✗ |
| `canViewContract` | ✗ | ✗ | ✗ | ✅ |
| `canViewB2bDashboard` | ✗ | ✗ | ✗ | ✅ |
| `canViewRevenue` | ✗ | ✗ | ✅ | ✅ |
| `canCreateFarm` | ✗ | ✗ | ✅ | ✅ |
| `canManageContracts` / `canCalculateRevenue` | ✗ | ✗ | ✅ | ✗ |
| `canManageSubscriptionServices` | ✗ | ✗ | ✅ | ✗ |
| `canManageSubfarmWorkers` | ✗ | ✗ | ✗ | ✅ |

### 4.2 后端方法权限

**(A) 声明式 `@PreAuthorize`**（Ranch / IoT 业务接口写操作）

| Controller | 端点操作 | 注解 |
|------------|---------|------|
| `LivestockController` | 牲畜创建/更新/删除（3 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `FenceController` | 围栏创建（POST）、轨迹解析（POST /track-parse）、删除 | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `FenceController` | 围栏强制覆盖（PUT /{fenceId}/force） | `hasRole('PLATFORM_ADMIN')` |
| `FenceController` | 围栏更新（PUT /{fenceId}） | **无注解**（内部乐观锁，STATE_CONFLICT→409 携带 serverVersion/serverVertices） |
| `FenceZoneController` | 围栏区域（POST） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `DeviceController` | 设备创建/更新/激活/平台注册/退役/删除（6 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `InstallationController` | 安装/卸载（2 处） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `TbDeviceProvisioningController` | TB 设备开通向导（类级） | `hasAnyRole('OWNER','B2B_ADMIN')` |
| `GatewayRegistryController` | 网关查询/位置更新 | `hasAnyRole('OWNER','WORKER','B2B_ADMIN')` |
| `GatewayDistanceController` / `LivestockRoamController` | 查询 | `hasAnyRole('OWNER','WORKER','B2B_ADMIN')` |
| `CoverageDiagnosticController` | 覆盖诊断 | `hasAnyRole('OWNER','WORKER','B2B_ADMIN','PLATFORM_ADMIN')` |

> 读操作（GET）普遍无注解——仅需登录（`authenticated()`）。Ranch/IoT **写操作不含 worker**。

**(B) 代码内 `requirePlatformAdmin()`**（仅 PLATFORM_ADMIN）

| Controller（`/api/v1/admin/*`） | 说明 |
|--------------------------------|------|
| `TenantAdminController`（/admin/tenants） | 8 个方法逐个校验 |
| `UserAdminController`（/admin/users） | 7 个方法逐个校验（`:271-281`） |
| `FarmAdminController`（/admin/farms）、`AuditLogController`（/admin/audit-logs）、`DashboardAdminController`（/admin/dashboard）、`ApiKeyAdminController`（/admin/api-keys） | identity Admin 系列 |
| `AdminContractController`（/admin/contracts）、`AdminRevenueController`（/admin/revenue）、`AdminSubscriptionController`（/admin/subscriptions）、`AdminServiceController`（/admin/subscription-services）、`AdminFeatureGateController`（/admin/feature-gates） | Commerce Admin 系列 |
| `PortalAdminController`（/admin/portal/keys） | Analytics Admin |
| `DeploymentLicenseAdminController`（/admin/deployment-license） | 除 enrollment/import（匿名）外逐方法校验；`CloudPilotLicenseController`（/admin/tenants license 子路径）同 |

**(C) 类级 `@PreAuthorize`**（双角色或单角色）

| Controller（`/api/v1/admin/*`） | 注解 |
|--------------------------------|------|
| `TileAdminController`（/admin/tiles） | `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')` |
| `DeviceProfileRuleAdminController`（/admin/device-profile-rules，NIX-214） | `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')` |
| `GatewayAdminController`（/admin/gateways）、`GovernanceAdminController`（/admin/governance）、`PresenceAdminController`（/admin/presence/thresholds） | `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')` |
| `DataGenConsoleController`（/admin/datagen console/control/rules/clear）、`DataGenBehaviorController`（/admin/datagen/behavior） | `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')` |
| `GpsQualityAdminController`（/admin/gps-quality） | `hasRole('PLATFORM_ADMIN')` |
| `TelemetryImportAdminController`（/admin/telemetry-import） | `hasRole('PLATFORM_ADMIN')` |
| `DataGenAdminController`（/admin/datagen 方法级 ×6） | `hasRole('PLATFORM_ADMIN')` |

> ⚠️ `AnalyticsAdminController`（/admin/analytics）**无任何权限注解/校验**，仅靠 URL `authenticated()` —— 任意登录角色可调（见 [7.6](#76-analyticsadmincontroller-无权限校验)）。

**(D) B2B API**：`B2bController`（`/api/v1/b2b`，2026-06-01 新增）内部 `requireB2bAdmin()`（检查 `ROLE_B2B_ADMIN`）+ `requireTenantId()`。端点：dashboard、contract、farms、farms/{id}/workers 增删查、available-workers、users 增改/状态/重置密码（创建固定 WORKER）。

**(E) 创建牧场**（App API，`POST /api/v1/farms`）

**来源**：`identity/interfaces/FarmController.java:49-60`

```java
if (!user.isOwner() && !user.getRole().name().equals("B2B_ADMIN")) {
    throw new ApiException(ErrorCode.AUTH_FORBIDDEN, "仅 owner 或 b2b_admin 可创建牧场");
}
```

> 允许 OWNER 或 B2B_ADMIN。owner 自建时 `ownerId = userId`；b2b_admin 创建时可指定 `ownerId` 分配给 owner。

### 4.3 三层权限对照速查

| 能力 | 前端 RolePermission | 后端实际 |
|------|---------------------|---------|
| 创建牧场 | `platformAdmin \|\| b2bAdmin` | `OWNER \|\| B2B_ADMIN` |
| 管理租户 | `owner \|\| platformAdmin` | 仅 `PLATFORM_ADMIN`（requirePlatformAdmin） |
| Ranch/IoT 写操作 | `canEditFence` 仅 owner | `OWNER \|\| B2B_ADMIN` |
| 告警标记已读 | `owner \|\| worker`（确认按钮） | **任意登录用户**（POST /alerts/{id}/read） |
| 告警 dismiss | owner（前端 canHandleAlert） | `OWNER \|\| B2B_ADMIN` |
| 批量 dismiss | owner | 复用 deprecated `/batch-handle`（`OWNER\|B2B_ADMIN`），worker 调用 403 |
| Tile 管理 | — | `PLATFORM_ADMIN \|\| B2B_ADMIN` |
| 设备配置规则 | — | `PLATFORM_ADMIN \|\| B2B_ADMIN` |
| GPS 质量 / 遥测导入 | — | 仅 `PLATFORM_ADMIN` |
| /admin/analytics | — | **任意登录用户**（无注解） |

---

## 5. 各角色用户旅程

### 5.1 platform_admin（平台管理员）

```
登录（13800000000 / 123，tenantId=null）
  → 重定向到 /ops/admin（租户列表，TenantListPage）
  → 创建租户（TenantCreatePage）→ 进入租户详情（TenantDetailPage）
  → 在租户详情新增用户：b2b_admin / owner / worker（UserAdminController）
      · 默认密码 Default@123，mustChangePassword=true → 用户首登强制改密
  → 管理租户启停、License 调整（CloudPilotLicense）
  → 重置用户密码 → 该密码视为「他人凭证」，重新武装强制改密
  → /admin/contracts 合同管理（AdminContractController）
  → /admin/revenue 对账看板与分润计算（AdminRevenueController）
  → /admin/subscriptions 订阅服务管理（AdminSubscriptionController）
  → /admin/deployment-license 部署授权（NIX-184；enrollment/import 匿名可达）
  → /admin/api-keys、/admin/portal/keys 审批 API 授权（ApiKeyAdminController）
  → /admin/audit-logs 审计日志
  → /admin/feature-gates 功能门控
  → /admin/analytics 用量分析（后端无权限注解，见 7.6）
  → /admin/tiles 瓦片管理
  → /admin/device-profile-rules 设备配置规则（NIX-214）
  → /admin/gps-quality GPS 质量检验/报告/RTK 真值点（NIX-15/20/21/68）
  → /admin/telemetry-import 遥测手动导入（NIX-79）
  → /admin/datagen 仿真控制台与行为数据（datagen v2）
  → /admin/gateway-overview 网关治理总览（NIX-219/220）
```

**权限**：Admin API 大部分要求 `ROLE_PLATFORM_ADMIN`。可访问 `/ops/admin/*` 与 `/admin/*`，不能访问普通 App 业务页（路由守卫强制重定向）。

### 5.2 b2b_admin（B 端管理员）

```
登录（13900139000 / 123，归属 Demo 租户）
  → 重定向到 /b2b/admin（概览看板，B2bDashboardPage）
  → /b2b/admin/farms 创建牧场 → 分配给 owner（FarmController: OWNER|B2B_ADMIN 可创建）
  → /b2b/admin/farms/:farmId 管理旗下牧工（B2bWorkerDetailPage）
      · 创建牧工（固定 WORKER 角色，不置强制改密）
      · 重置牧工密码（不重新武装强制改密，见 7.8）
  → /b2b/admin/contract 查看合同信息（canViewContract）
  → /b2b/admin/revenue[/:id] 对账与分润明细（canViewRevenue）
  → 例外放行：/admin/tiles 瓦片管理、/admin/datagen 仿真控制台（后端均允许 B2B_ADMIN）
```

**权限**：锁定在 `/b2b/admin/*` + 两个例外页。后端 Ranch/IoT 写操作（`hasAnyRole('OWNER','B2B_ADMIN')`）允许 b2b_admin 操作牲畜/围栏/设备/告警。设备配置规则、网关治理、datagen 对 b2b_admin 开放。

### 5.3 owner（牧场主）

```
登录（13800138000 / 123，归属 Demo 租户）
  → [若 mustChangePassword=true] 锁定 /me/password-change 强制改密 → 改密后回 /ranch
  → 重定向到 /ranch（牧场页，默认首页）
  → /twin 数智孪生：GPS 地图、牲畜概览、健康预警
      · /twin/fever(/:livestockId) 发热、/twin/digestive(/:id) 消化、
        /twin/estrus(/:id) 发情、/twin/epidemic(+contacts) 疫病
  → /alerts 告警中心（NIX-52 通知中心）：
      · 标记已读（单条/批量）· dismiss 处理（ACTIVE→DISMISSED）
      · 详情弹层：标签/时间线/地图定位/查看轨迹
  → /fence 围栏管理：创建 / 编辑（乐观锁冲突 409 可选强制覆盖） / 删除
  → /livestock/:id 牲畜详情：主数据、绑定设备（GPS+胶囊，单设备解绑）、
      72h 体温 / 24h 蠕动 / 7 天发情评分（自动刷新）、位置信息
  → /devices 设备管理：设备列表、开通向导（TB 自动配置弹层）、安装到牲畜、解绑、轨迹
  → /mine/gateways(/:id) 网关注册与位置、/mine/coverage-diagnostics 覆盖诊断（NIX-219/220）
  → /stats 数据统计、/offline/tiles 离线地图管理
  → /subscription/plans → /subscription/checkout 订阅升级（FeatureGate 按 tier 门控）
  → /mine/workers 牧工管理：添加 / 移除牧工
  → /mine/api-auth API 授权管理（canReviewApiAuthorizations）
  → /farm/create 创建牧场向导（后端允许 OWNER）
  ✗ /admin 前缀全部被守卫重定向回 /ranch（owner 后台 Tab 已不可达，见 7.3）
```

**权限**：可见全部 App 页面 + 牧工管理 + 订阅。Ranch/IoT 写操作允许。可创建牧场（后端 OWNER）。

### 5.4 worker（牧工）

```
登录（账号由 owner/admin 创建；平台管理员创建的账号首登强制改密）
  → 重定向到 /ranch（牧场页）
  → /twin 数智孪生：查看地图、牲畜位置（只读；网关/漫游查询允许 WORKER）
  → /alerts 告警中心：标记已读（单条/批量，后端任意登录用户可调）
      · 批量 dismiss 走 deprecated /batch-handle → 后端 403（见 7.4）
      · 不可 dismiss 处理（canHandleAlert=false，后端 OWNER|B2B_ADMIN）
  → /fence 围栏：只查看（canEditFence=false）
  → /mine 个人资料、牧场切换
  ✗ /mine/workers 被守卫拦截 → 重定向到 /ranch
  ✗ /admin 前缀被守卫拦截 → 重定向到 /ranch
```

**权限**：4 个 Tab（牧场/孪生/告警/我的）。网关注册/位置更新、覆盖诊断允许 WORKER（NIX-219/220）。

### 5.5 api_consumer（API 开发者）

- 仅通过 Open API（`/api/v1/open/**`）访问，使用 API Key 认证（`X-API-Key` 或 `Bearer sk_live_...`）。
- 认证后经 `ScopeInterceptor` 做 scope 校验（`livestock:read / fence:read / alert:read / device:read / device:register / gps:read / health:read / *`），缺 scope 返回 403。
- 受频率限制约束（rate-limit 拦截器）。
- 设备注册：`OpenDeviceRegisterController` 走 `device:register` scope。
- 无 App 端 UI（开发者门户 Phase 2c：`/mine/api-auth` 与 `/admin/api-keys`、`/admin/portal/keys` 承担 Key 生命周期管理）。

---

## 6. 核心业务流程

### 6.1 平台入驻链

```
platform_admin
  → 创建租户（TenantAdminController，requirePlatformAdmin）
  → 在租户下新增 b2b_admin / owner / worker（UserAdminController，requirePlatformAdmin）
      · 新账号密码 Default@123，mustChangePassword=true

b2b_admin（或 owner）
  → 创建牧场（FarmController，OWNER|B2B_ADMIN 可创建）
  → b2b_admin 创建时指定 ownerId 分配给 owner

owner
  → 管理牲畜、围栏、告警、牧工（日常运营）
```

> 约束（代码现状）：牧场可由 OWNER 或 B2B_ADMIN 创建；租户与用户的创建仅限 PLATFORM_ADMIN；新账号首登一律强制改密。

### 6.2 牧场作用域（activeFarmId）传递机制

> ⚠️ activeFarmId **不**随 JWT 传递，而是由前端在请求 URL 路径中编码。

**前端**：`Mobile/mobile_app/lib/core/api/api_client.dart:81-122`

```dart
farmGet(suffix)  => get('/farms/$_activeFarmId$suffix');   // farmId 编码进 URL path
farmPost(suffix) => post('/farms/$_activeFarmId$suffix');
farmPut(suffix)  => put('/farms/$_activeFarmId$suffix');
farmDelete(suffix) => delete('/farms/$_activeFarmId$suffix');
// 另有 farmUploadFile / farmDeleteJson 同模式；_activeFarmId 为 null 时抛 StateError
```

- `_activeFarmId` 由 `SessionController.updateActiveFarm` 设置，并持久化到 `JwtStorage`。
- 请求头只携带 `Content-Type`、`Accept-Language`、`Authorization: Bearer {token}`，**不**发送 `x-active-farm`。

**后端**：`shared/scope/FarmScopeInterceptor.java:31-109` + `FarmScopeResolver.java`（拦截 `/api/v1/farms/*/**`、`/api/v1/open/farms/*/**`、`/api/v1/admin/tenants/*/farms/*/**`）

- 从 URL path 提取 farmId（`FarmIdPathParser`，`farms` 后一段为数字），或从请求头 `x-active-farm` 读取。
- 无 path farmId 直接放行。
- **写操作**（非 GET/HEAD/OPTIONS）：必须由 path 提供 farmId；仅 header → `VALIDATION_ERROR`；path+header 同给 → `FARM_SCOPE_CONFLICT`。
- **读操作**：path 或 header 任一即可；同给 → `FARM_SCOPE_CONFLICT`。
- 归属校验 `existsByIdAndTenantId`，不属于当前租户 → `AUTH_FORBIDDEN「无权访问该牧场」`。
- **跳过归属校验**：`/api/v1/open/` 路径、`ROLE_PLATFORM_ADMIN`、API Key 认证（`TenantContext == null` 判定）。
- `FARM_SCOPE_CONFLICT` → HTTP **409**。

**牧场切换刷新规则**：使用 farm-scoped API 的 Controller 必须继承 `FarmScopedNotifier` / `FarmScopedAsyncNotifier`（`core/api/farm_scoped_controller.dart`），在 `build()` 调用 `watchActiveFarmId()` 以声明对 activeFarmId 的依赖，确保切换时自动重建。违反的典型症状：切换牧场后页面仍显示旧数据。

### 6.3 告警模型与状态机（NIX-52 通知中心，2026-09 重设计）

> ⚠️ 与旧版文档差异：旧「pending → acknowledged → handled → archived」状态机已废弃。

**告警状态**（`ranch/domain/model/Alert.java:65-94`）：

```
ACTIVE ──手动 dismiss──→ DISMISSED
ACTIVE ──规则自动恢复──→ AUTO_RESOLVED
```

- 只有 `ACTIVE` 可 dismiss，否则抛 `STATE_CONFLICT` → HTTP **409**。
- **已读状态与告警状态解耦**：按用户存 `alert_read_status` 表（`AlertApplicationService`）。

**端点**（`ranch/interfaces/AlertController.java`，`/api/v1/farms/{farmId}`）：

| 端点 | 权限 | 说明 |
|------|------|------|
| `GET /alerts`、`GET /alerts/summary`、`GET /alerts/{alertId}` | 登录即可 | 读 |
| `POST /alerts/{alertId}/read` | 任意登录用户 | 标记已读（按当前用户） |
| `POST /alerts/batch-read` | 任意登录用户 | 批量标记已读 |
| `POST /alerts/{alertId}/dismiss` | `OWNER\|B2B_ADMIN` | 处理（ACTIVE→DISMISSED） |
| ~~`POST /alerts/{alertId}/acknowledge`~~ | @Deprecated | 转发 markRead |
| ~~`POST /alerts/{alertId}/handle`~~ | @Deprecated，`OWNER\|B2B_ADMIN` | 转发 dismiss |
| ~~`POST /alerts/{alertId}/archive`~~ | @Deprecated，`OWNER\|B2B_ADMIN` | 归档 |
| ~~`POST /alerts/batch-handle`~~ | @Deprecated，`OWNER\|B2B_ADMIN` | 循环 dismiss，跳过不可处理项（前端批量 dismiss 仍复用，见 7.4/7.9） |

### 6.4 订阅与功能门控

- **订阅层级**（`SubscriptionTier`）：basic / standard / premium / enterprise。
- 配额引擎在后端 Commerce 上下文实现；前端 `FeatureGate` 按 tier 控制功能可见性。
- 低 tier 访问高 tier 功能时显示升级提示覆盖层；`ApiCache` 预加载时按 tier 过滤数据范围。
- 拦截器链含 `license` 与 `quota` 环节（见 2.4）。

---

## 7. 已知不一致点

> 本节列出代码现状与旧文档 / 前后端声明之间的差异。以**代码实际行为**为准。

### 7.1 默认落地页

- **代码**：owner / worker 登录后重定向到 `/ranch`（`app_router.dart` redirect）。
- **旧文档**：`customer-journey.md` 称 owner 登录重定向到 `/twin`。
- **结论**：以代码为准，首页为 `/ranch`。

### 7.2 创建牧场角色

- **后端**（`FarmController.java:49-60`）：允许 `OWNER` 或 `B2B_ADMIN`。
- **前端**（`role_permission.dart`）：`canCreateFarm = platformAdmin || b2bAdmin`（不含 owner）。
- **结论**：后端允许 owner 创建牧场，前端 `RolePermission` 未授予该能力；owner 是否能走通 `/farm/create` 取决于页面是否绕过 `RolePermission` 直接使用路由。

### 7.3 管理租户角色与 owner 后台入口

- **后端**（`TenantAdminController` / `UserAdminController`）：`requirePlatformAdmin()` 仅 `PLATFORM_ADMIN`。
- **前端**（`role_permission.dart`）：`canManageTenants = owner || platformAdmin`。
- **路由**（`app_router.dart:123-127`）：`/admin` 与 `/admin/*` 对 **owner 同样重定向回 `/ranch`**；`AppRoute.admin` 枚举存在但无 GoRoute 注册。
- **结论**：owner 对租户的管理权限是**死权限**——前端授了能力，但没有任何可达入口，后端也会拒绝。owner 后台管理 Tab（旧版含租户信息/订阅管理）已实际移除；订阅管理走 `/subscription`。

### 7.4 worker 告警权限（新模型下已部分收敛）

- **前端**：worker 可确认告警（`canAcknowledgeAlert = owner || worker`）→ 实际调用 `POST /alerts/{id}/read`，后端**任意登录用户**放行 → **一致，可用**。
- **批量 dismiss**：前端复用 deprecated `POST /alerts/batch-handle`（`alerts_api_repository.dart:75-76` 注释），后端 `OWNER|B2B_ADMIN` → worker 批量处理会被 **403**。
- **结论**：worker 单条确认可用；批量 dismiss 是残留缺口（前端应按角色隐藏该按钮）。

### 7.5 Ranch 写操作角色范围

- **后端**：Ranch/IoT 写操作（围栏/牲畜/设备/告警 dismiss）`hasAnyRole('OWNER','B2B_ADMIN')`，含 b2b_admin。
- **前端**：`canEditFence` 等仅 owner（不含 b2b_admin）。
- **结论**：后端对 b2b_admin 开放 Ranch 写操作，但前端 `RolePermission` 未授予 b2b_admin 编辑围栏能力（B 端控制台本就无这些页面入口，实际影响有限）。

### 7.6 AnalyticsAdminController 无权限校验

- **代码**（`analytics/interfaces/admin/AnalyticsAdminController.java` 全文）：无 `@PreAuthorize`、无 `requirePlatformAdmin()`。
- **结论**：`/admin/analytics`（含 `POST /aggregate`）仅要求登录，任意角色（owner/worker/b2b_admin）带 JWT 均可调用——前端路由挡住了，但 API 层裸奔。建议补类级 `@PreAuthorize`。

### 7.7 会话恢复不读 mustChangePassword

- **代码**（`main.dart:91-100`）：`_restoreSession` 从持久化 JWT 恢复登录态时未恢复 `mustChangePassword`（默认 false）。
- **结论**：首登未改密的账号在刷新/重启页面后，前端不再锁 `/me/password-change`（后端拦截器仍在，业务接口会 403，仅白名单接口可用）——用户会陷入「页面能看、操作全 403」的状态，直到重新登录。建议 JWT claims 或 `/me` 响应中带出该标志。

### 7.8 B2B 重置密码不重新武装强制改密

- **代码**：`UserAdminController.reset-password`（平台）重置后 `reconstituteMustChangePassword(true)`——视为「他人凭证」重新武装；`B2bController.reset-password`（B 端重置牧工密码）**不武装**。
- **结论**：行为不一致。B 端重置的密码同样属于「他人下发的初始凭证」，建议对齐。

### 7.9 旧告警端点 deprecated 但前端仍复用

- **代码**：`/acknowledge`、`/handle`、`/archive`、`/batch-handle` 均已 `@Deprecated`；前端批量 dismiss 仍复用 `/batch-handle`（`alerts_api_repository.dart:75-76`）。
- **结论**：短期可用（deprecated 未删除），长期应给后端补 `batch-dismiss` 端点或前端改为循环 dismiss。

### 7.10 FenceController 更新端点无 @PreAuthorize

- **代码**：`PUT /{fenceId}` 无角色注解（创建/删除均有 `OWNER|B2B_ADMIN`），仅靠内部乐观锁（STATE_CONFLICT→409）兜底；`PUT /{fenceId}/force` 强制覆盖才要求 PLATFORM_ADMIN。
- **结论**：任意登录角色（含 worker）技术上可发起围栏更新（受乐观锁与前端入口限制）。与其他写端点的注解风格不一致，建议补齐。

---

## 8. 关键代码索引

| 关注点 | 文件路径 |
|--------|---------|
| 后端角色枚举 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/model/Role.java` |
| User 聚合（停用/激活终态、强制改密） | `smart-livestock-server/src/main/java/com/smartlivestock/identity/domain/model/User.java` |
| 登录控制器 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/AuthController.java` |
| 登录/刷新服务 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/application/AuthApplicationService.java` |
| 改密端点 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/MeController.java` |
| 强制改密拦截器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/PasswordChangeRequiredInterceptor.java` |
| JWT 生成/校验/刷新 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/JwtTokenProvider.java` |
| JWT / API Key 过滤器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/JwtAuthenticationFilter.java`、`ApiKeyAuthFilter.java` |
| 安全配置 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/security/SecurityConfig.java` |
| 拦截器链注册 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/WebMvcConfig.java` |
| Open API scope 校验 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/scope/ScopeInterceptor.java` |
| 牧场作用域拦截器/解析器 | `smart-livestock-server/src/main/java/com/smartlivestock/shared/scope/FarmScopeInterceptor.java`、`FarmScopeResolver.java`、`shared/web/FarmIdPathParser.java` |
| 创建牧场（角色校验） | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/FarmController.java` |
| Admin 租户/用户管理 | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/admin/TenantAdminController.java`、`UserAdminController.java` |
| B2B API | `smart-livestock-server/src/main/java/com/smartlivestock/identity/interfaces/b2b/B2bController.java` |
| Ranch @PreAuthorize | `smart-livestock-server/src/main/java/com/smartlivestock/ranch/interfaces/{Livestock,Fence,FenceZone,Alert}Controller.java` |
| 告警域模型 | `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/Alert.java` |
| IoT @PreAuthorize | `smart-livestock-server/src/main/java/com/smartlivestock/iot/interfaces/{DeviceController,GatewayRegistryController,GatewayDistanceController,LivestockRoamController,CoverageDiagnosticController,TbDeviceProvisioningController}.java` |
| Admin 系列权限 | `identity/interfaces/admin/`、`commerce/interfaces/admin/`、`analytics/interfaces/admin/`、`iot/interfaces/admin/`、`datagen/interfaces/admin/`、`licensing/interfaces/`（详见 4.2） |
| 前端角色枚举 | `Mobile/mobile_app/lib/core/models/user_role.dart` |
| 前端操作权限 | `Mobile/mobile_app/lib/core/permissions/role_permission.dart` |
| 前端路由守卫 | `Mobile/mobile_app/lib/app/app_router.dart` |
| 前端路由表 | `Mobile/mobile_app/lib/app/app_route.dart` |
| 前端会话控制器/状态 | `Mobile/mobile_app/lib/app/session/session_controller.dart`、`app_session.dart` |
| 强制改密页 | `Mobile/mobile_app/lib/features/auth/presentation/forced_password_change_page.dart` |
| 前端 API 客户端（farm scope / 401 刷新） | `Mobile/mobile_app/lib/core/api/api_client.dart` |
| FarmScoped 基类 | `Mobile/mobile_app/lib/core/api/farm_scoped_controller.dart` |
| 告警 API 仓库（新模型映射） | `Mobile/mobile_app/lib/features/alerts/data/alerts_api_repository.dart` |
| 告警详情弹层 | `Mobile/mobile_app/lib/features/alerts/presentation/widgets/alert_detail_sheet.dart` |
| 设备开通向导弹层 | `Mobile/mobile_app/lib/features/devices/presentation/widgets/tb_device_wizard_sheet.dart` |
| 前端登录页 | `Mobile/mobile_app/lib/features/auth/login_page.dart` |

---

*文档基线：2026-09-20 · 基于当前工作区代码（分支 `nix/219-gateway-position-distance`）核实。上一版 2026-06-11。*
