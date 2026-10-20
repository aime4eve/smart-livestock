# 超级管理员「登录后选角色进入系统」设计方案

- 日期：2026-10-19
- 状态：**设计稿，待用户裁决后才能编码**（AGENTS.md 硬性规则 2026-09-05）
- 类型：feature 级（跨认证/权限/前端导航），按流程应在编码前补 HTML 高保真原型（仅「角色选择器」一个新页面需要原型）

---

## 1. 需求

1. 提供一个**超级管理员账号**：密码验证成功后，先不进入任何业务界面，而是**选择要以哪种角色类型进入系统**（平台管理员 / 租户管理员 / 牧场主 / 牧工）。
2. 选定后，以该角色的完整身份正常使用系统（所有该角色可见的页面、可做的操作）。
3. **租户受限角色**（B2B_ADMIN / OWNER / WORKER 都绑定租户）要设计好如何支撑：以哪个租户身份进入、进入后隔离如何生效。

典型场景：售后支持、客户演示、排障——需要一个账号能看到"客户视角的真实系统"，而不是只能看平台管理台。

## 2. 现状事实（代码证据）

| # | 事实 | 证据 |
|---|---|---|
| 1 | 角色是 `users` 表单字段，5 值枚举 `OWNER/WORKER/PLATFORM_ADMIN/B2B_ADMIN/API_CONSUMER` | `identity/domain/model/Role.java:3-9`；CHECK 约束 `V1__create_identity_tables.sql:40` |
| 2 | JWT 只带 `sub`(userId)/`tid`(tenantId)/`role` 三个 claim，HS256，60 分钟，无状态、无吊销 | `shared/security/JwtTokenProvider.java:32-44`；`application.yml:43-46` |
| 3 | 每请求上下文纯靠 JWT：authority=`ROLE_<role>`、`TenantContext`=tid，**不查库** | `shared/security/JwtAuthenticationFilter.java:34-66` |
| 4 | 行级隔离全部是"手动 where tenantId"，租户 Id 来源统一是 `TenantContext` | 如 `iot/infrastructure/persistence/SpringDataDeviceRepository.java:16-58` |
| 5 | PLATFORM_ADMIN 的 tid=null，租户域端点对其基本不可用（`/farms` 返回空、`/tenants/me` 404），只能走 `/api/v1/admin/**`（编程式 `requirePlatformAdmin()`，检查的是 SecurityContext authority） | `identity/interfaces/admin/TenantAdminController.java:299-309` |
| 6 | 登录链路：标识符解析 → isActive → 租户生命周期门禁（deleted/disabled 拒登）→ BCrypt → 发 token；响应 `{accessToken, user{role, tenantId, mustChangePassword…}}` | `identity/application/AuthApplicationService.java:27-55` |
| 7 | 强制改密锁：`mustChangePassword` 时除白名单（含整个 `/api/v1/auth/**`）外全部返回 `PASSWORD_CHANGE_REQUIRED` | `shared/security/PasswordChangeRequiredInterceptor.java:29-60` |
| 8 | **refresh 只复制 `sub/tid/role`，其余 claim 会丢**；且 refresh 会从库重读用户、响应返回 DB 行 | `JwtTokenProvider.java:96-101`；`AuthApplicationService.java:83-95` |
| 9 | `GET /farms` 只按 tenantId 过滤，**不按 user_farm_assignments 过滤**；但 `createFarm` 从库回读用户角色再判权 | `identity/interfaces/FarmController.java:35-46`；`FarmController.java:51-60` |
| 10 | 无任何 impersonate/switch/sudo 机制（全库 grep 无命中）；最接近的先例是 `x-active-farm` 同租户牧场切换 | 双向探查确认 |
| 11 | 审计设施现成：`audit_logs`（user_id/tenant_id/action/details JSONB/farm_id/operator_role）+ 管理端查询 | `V18__create_audit_logs_table.sql`；`identity/interfaces/admin/AuditLogController.java:22-65` |
| 12 | 前端：登录成功即按 role 直达首页（router redirect 分支），`AppSession.role` 是唯一权威；`UserRole.fromString` 未知值静默 fallback worker；无租户选择 UI；牧场切换器/activeFarmId 三写模式成熟 | `lib/app/app_router.dart:84-135`；`lib/core/models/user_role.dart:23-26` |
| 13 | 租户有 `status('active'|'disabled')` + `deleted_at`；试点到期属 licensing 模块，`LicenseEnforcementInterceptor` 按请求拦截租户上下文（排除 `/api/v1/admin/**`） | `tenants` 表 `V20261012140000`；`shared/security/LicenseEnforcementInterceptor.java:42,83` |

## 3. 方案选型

| 方案 | 思路 | 结论 |
|---|---|---|
| **A. 上下文重签 token（推荐）** | 超管登录拿"根 token"（只用于选身份）；选定目标角色+租户后，服务端校验并签发一张**与真实用户 token 结构完全相同**的"上下文 token"（role/tid = 目标值），仅额外多一个 `act` 标记 claim 供审计 | ✅ 业务侧鉴权/隔离**零改动**（它们只读 claim）；无数据污染；可审计 |
| B. 真实成员行落地 | 给超管在每个租户建真实的 users 行/成员行 | ❌ 数据污染（成员列表、租户数、审计混入假用户）；新租户要同步建；license/席位语义被搅 |
| C. 前端模拟角色 | 只改 UI 显示，token 不变 | ❌ 服务端 `@PreAuthorize`/`TenantContext` 直接拒绝，纯安全幻觉，不可行 |
| D. 服务端会话 | 引入 session 表做有状态上下文、可吊销 | ❌ 从无状态改有状态是架构级变更（refresh/logout/全部假设重写），当前收益不匹配 |

**推荐 A**，并把 B 的 UX 优点（"像选成员身份一样自然"）融进选择器交互。

## 4. 推荐方案详细设计

### 4.1 身份模型：SUPER_ADMIN「只登录，不办事」

- 新增第 6 个角色值 `SUPER_ADMIN`（`Role.java` + users CHECK 约束迁移）。
- **根 token（role=SUPER_ADMIN, tid=null）唯一的用途**：调两个新端点（查可选上下文、切换上下文）、改自己密码、登出。它不带任何既有 authority，`requirePlatformAdmin()` 与所有 `@PreAuthorize` 都不认它——所以平台工作也必须"以 PLATFORM_ADMIN 身份进入"后再做，模型完全统一：**超管永远经由上下文使用系统**（与需求原文一致："选择后可以用该类角色正常使用系统"）。
- 普通用户完全无感：5 个既有角色登录路径、token、权限一行不改。

### 4.2 令牌设计

```
根 token:      sub=超管userId, tid=null, role=SUPER_ADMIN
上下文 token:   sub=超管userId, tid=目标租户, role=目标角色,
               act={sub:超管userId, role:"SUPER_ADMIN"}   ← RFC 8693 风格的"代操作"标记
```

- 上下文 token 除 `act` 外与真实用户 token **逐 claim 同构**：`JwtAuthenticationFilter` 照常设 authority 与 TenantContext → 所有 `@PreAuthorize`、`requirePlatformAdmin()`、手动 where tenantId 全部按目标角色/租户生效，**这就是"租户限制零成本支撑"的原理**。
- `sub` 保持超管真实 userId：审计外键、`recordLogin` 等按 userId 的机制不破坏。
- TTL 与普通 token 一致（60 分钟）；refresh 链两个必修点：
  1. `JwtTokenProvider.refreshToken` 必须原样复制 `act`（现状只复制三个 claim，会静默丢标记——事实 #8）。
  2. `AuthApplicationService.refresh` 在 `act` 存在时，响应的 `user` 必须按 **token claim 合成**（role=目标角色、tenantId=目标租户），不能再返回 DB 行（现状返回超管真实行，会把前端会话身份冲掉——事实 #8）。
- 客户端持有双 token：`root_token`（选择器用）+ `access_token`（当前上下文）。存 `JwtStorage`，保护级别与今天的单 token 相同；登出/`clear()` 一并清除。

### 4.3 新端点契约（挂在 `/api/v1/auth/` 下，`@PreAuthorize("hasRole('SUPER_ADMIN')")`）

```
GET /api/v1/auth/entry-contexts
→ data: {
    roles:  [ {role:"PLATFORM_ADMIN", tenantScoped:false},
              {role:"B2B_ADMIN",      tenantScoped:true},
              {role:"OWNER",          tenantScoped:true},
              {role:"WORKER",         tenantScoped:true} ],   // API_CONSUMER 不可选
    tenants:[ {id, name, status, phase, timezone, farmCount} ] // 排除 deleted；disabled 标注可灰显
  }

POST /api/v1/auth/switch-context        // Authorization 用根 token
  { "role": "OWNER", "tenantId": 2 }    // PLATFORM_ADMIN 时无 tenantId
→ data: { accessToken, user:{role:"OWNER", tenantId:2,…}, impersonated:true }
```

| 校验门（switch 时逐项） | 失败错误 |
|---|---|
| 调用方必须是 SUPER_ADMIN 根 token（上下文 token 不可再切换，防越权） | 403 `auth.contextSwitchForbidden` |
| `mustChangePassword=true` 时拒绝（`/auth/**` 在改密白名单里，服务内必须自查，防绕过改密锁——事实 #7） | 403 `PASSWORD_CHANGE_REQUIRED` |
| 目标角色 ∈ {PLATFORM_ADMIN, B2B_ADMIN, OWNER, WORKER}（禁 API_CONSUMER、禁 SUPER_ADMIN 自我提权） | 422 `auth.roleNotSelectable` |

> 白名单排除 API_CONSUMER 的实证（2026-10-19 grep 核实）：后端除 `Role.java` 枚举定义外**零引用**——没有任何 `@PreAuthorize`/编程式检查包含它，它的真实通道是 `X-API-Key`（ApiKeyAuthFilter，principal=apiKeyId），不经过登录发 token 链路；若允许"以 API_CONSUMER 进入"只会得到一个所有角色校验接口全 403 的空壳会话（前端还会误落牧场页）。WORKER 与 OWNER 共用牧场端 Shell，仅权限子集不同，横幅同款。
| 租户存在且未删除 | 404 `auth.tenantNotFound` |
| 租户 status=disabled | **已裁决（2026-10-19）：允许进入**，前端显著警示确认（售后排障）；服务端不拦截 |
| 租户 deleted | 404 拒绝（一律不可进入） |
| 试点/licensing 到期 | **已裁决：switch 时即拒绝** 409 `auth.tenantTrialExpired`（优于进入后被拦截器逐请求打回） |

- 复用 `/auth/**` 既有登录限流；每次 switch 写一条审计（§4.6）。
- 响应保持 `AuthTokenDto` 同构 + 新增可选 `impersonated` 布尔，前端解析零改造。

### 4.4 租户受限场景的支撑（用户核心提问）

1. **进入时**：租户型角色在选择器里二级选择租户（名称搜索 + 状态徽标 + 牧场数）；选定后 switch 请求带 tenantId，服务端过 §4.3 全部门。
2. **进入后**：上下文 token 的 `tid`=目标租户 → `TenantContext` 生效 → 全库手动 where tenantId 的行级隔离**原样工作**，看到的数据与该租户真实用户完全一致——这正是选方案 A 的原因。
3. **牧场维度不选、不新建机制**：进入 OWNER/WORKER 后，现有 `GET /farms`（只按租户过滤，事实 #9）返回该租户全部牧场，`FarmSwitcher` + `activeFarmId` 三写模式 + `FarmScopedNotifier` 刷新链**原样复用**，与真实用户体验一致。
4. **停用/删除租户**：**已裁决（2026-10-19）**——disabled 可进入但选择器/确认页显著警示（售后排障场景）；deleted 一律不可见不可进。
5. **到期租户**：**已裁决**——switch 时即拒绝（409），排障豁免暂不做。

### 4.5 必须修复的「从库回读角色」点（方案 A 的唯一已知代价）

**清点结论表（2026-10-19 实施时全库 grep 核实，Task 4 产出）**：

| 调用点 | 用途 | 处置 |
|---|---|---|
| `FarmController.createFarm` | 请求者角色判权 | **已修**：改读 SecurityContext authority；回归测试 `FarmControllerCreateFarmTest`（OWNER 上下文 201 且零回读 / WORKER 403 / 根 token 403） |
| `FarmApplicationService.autoAssignOwner` | 建场后给创建者挂 OWNER 成员 | **保持现状（有意）**：按库角色 SUPER_ADMIN 跳过挂载——避免超管上下文建场污染租户成员表（代码注释已写明） |
| `datagen/DatagenOperatorContextResolver` | datagen 操作者角色解析 | **无需改**：实测读 SecurityContext authorities（token），非库回读（设计稿此前的怀疑有误，已纠正） |
| `OwnerWorkerController.findTenantWorker` / `B2bController:466/516/555` | 目标牧工归属/角色校验 | 无需改（目标用户，非请求者） |
| `B2bController:75/250` / `FarmController:142` / `FarmController.changeOwner:200` | 成员列表 enrichment / 新牧场主校验 | 无需改（展示数据 / 目标用户） |
| `MeController:34/50/147` | 本人资料/改密 | 无需改（sub 指向真实账号=设计语义：上下文中改密即改超管真实密码；前端不消费 GET /me） |
| `UserAdminController:192/223/313/344` | 管理端目标用户操作 | 无需改（入口 requirePlatformAdmin 按 authority 守卫，上下文 PLATFORM_ADMIN token 天然通过） |
| `PasswordChangeRequiredInterceptor:56` | 改密锁判定 | 无需改（按真实账号标志拦截，对上下文请求同样生效——安全增益） |

### 4.6 审计

- `audit_logs` 新事件 `AUTH_CONTEXT_SWITCHED`：`user_id`=超管、`tenant_id`=目标租户、`operator_role`=目标角色、`details`={targetRole, ip, 设备信息}；退出/切换写 `AUTH_CONTEXT_EXITED`（best-effort，与现有写入风格一致）。
- 上下文 token 的 `act` claim 让未来任何审计点都能标注"代操作"；现有管理端 `GET /api/v1/admin/audit-logs` 直接可查。

### 4.7 前端流程与 UI

**登录流**（改 `app_router.dart` redirect + 新选择器页）：

```
登录页（密码验证 200）
  → mustChangePassword？→ 既有改密锁（优先级不变，在角色分支之前）
  → role=SUPER_ADMIN？→ /select-context（角色选择器）
       ① 角色卡片：平台管理员 / 租户管理员 / 牧场主 / 牧工
       ② 租户型角色 → 二级租户列表（搜索 + 状态徽标 + 牧场数）
       ③ 确认 → switch-context（用 root token）→ 存上下文 token → 按目标角色进入对应首页
  → 其余角色 → 现有直达逻辑（一行不改）
```

- `UserRole` 增加 `superAdmin` 值（**必须与后端同批发版**：旧客户端遇未知 role 会 fallback worker，`user_role.dart:23-26`）。
- 选择器页走 feature 流程第 1 步补 HTML 高保真原型（令牌确认后锁定）。
- **身份横幅**：处于上下文时，三个 Shell（平台侧栏 / B2B 侧栏 / 牧场底导 AppBar）常驻标识"超管代登 · 以【租户 X · 角色 Y】身份操作"+「切换身份 / 退出该身份」；退出=换回根 token 回选择器（根 token 过期则引导重新登录）。
- `SessionController` 新增 `enterContext/exitContext`；`AppSession` 增加 `impersonated` 等字段；`JwtStorage` 增加 `root_token`/`root_user_info` 两把 key 并纳入 `clear()`。
- App 重启恢复**上下文会话**（连续性优先），根 token 一并恢复供横幅切换用。
- 所有新文案走 `AppLocalizations`（zh/en arb 同步）。

### 4.8 安全清单

- 根 token 无任何业务 authority；switch 端点限 SUPER_ADMIN；目标角色白名单；上下文 token 不可再 switch。
- `mustChangePassword` 在 switch 服务内自查（补 `/auth/**` 白名单绕过漏洞）。
- 登录探针防护不变（错误文案保持泛化）；超管账号同样受密码策略、停用、租户门禁（超管 tenantId=null，不受租户门禁影响）。
- 无 token 吊销是**既有姿态**（60 分钟短 TTL），上下文 token 与之一致，不引入新风险面；多端各自独立会话，每次 switch 均审计。
- 种子超管账号：Flyway 迁移 + BCrypt 三步验证（AGENTS.md §4.2），`must_change_password=TRUE`，激活策略对齐 `V20260907120000__admin_bootstrap.sql` 的平台管理员处理。

## 5. 边界情况

| 场景 | 处理 |
|---|---|
| 目标租户无牧场 | 允许进入（OWNER/WORKER 首页空态即现有空态） |
| 上下文中 token 过期 | 走现有 refresh（§4.2 两个必修点保证身份不漂移） |
| 上下文中登出 | 清全部 key（含 root），回登录页 |
| 根 token 过期、想换身份 | 横幅提示重新登录 |
| 多设备同时以不同身份 | 各自独立，审计逐次记录 |
| 超管在上下文中改自己密码 | 改的是超管真实账号（sub 指向），`mustChangePassword` 锁对上下文请求依然生效（拦截器按路径全局生效） |
| B2B 控制台内"本租户"语义 | tid=目标租户，天然正确 |

## 6. 实施清单（批准后执行；按用户偏好一次性完整实现，不分期）

**后端**（smart-livestock-server）
1. 迁移①：users.role CHECK 增 `SUPER_ADMIN` + 超管种子行（BCrypt 三步验证、must_change_password=TRUE、bootstrap 策略对齐）。
2. `Role.java` 增 `SUPER_ADMIN`；`JwtTokenProvider` 支持 `act` claim + refresh 复制 `act`。
3. `AuthApplicationService`：`listEntryContexts` / `switchContext`（§4.3 全部门 + 审计写入）；`refresh` 对 `act` token 合成 effective user。
4. `AuthController` 两个新端点（`@PreAuthorize SUPER_ADMIN`）。
5. 「DB 回读角色」清点与修复（§4.5，独立 Task + grep 清单）。
6. `messages_zh/en.properties` 双语新错误文案；单元/集成测试（switch 各门、refresh 保 claim、createFarm 以 OWNER 上下文走通）。

**前端**（Mobile/mobile_app）
1. `UserRole.superAdmin` + router 分支（改密锁优先级保持在前）。
2. 角色选择器页（先出 HTML 高保真原型走确认流程）。
3. `SessionController.enterContext/exitContext` + `AppSession`/`JwtStorage` 扩展。
4. `ApiClient.entryContexts/switchContext`（显式传根 token）。
5. 三 Shell 身份横幅 + 「我的」页切换入口；arb 双语同步 + `gen-l10n` + `analyze`。
6. `docs/api-contracts/app-api.md` 契约补记（顺带修既有 login 契约漂移）。

**部署验证**（收口验证 #25 全项）
- dev 部署后 curl 冒烟：超管登录 200 → entry-contexts 列出租户 → switch OWNER@租户2（200，claim 带 act）→ `GET /farms` 非空 → 以 OWNER 上下文 `POST /farms` 201（实证回读修复）→ audit_logs 有 SWITCHED 行 → 退出再 switch B2B_ADMIN 走通控制台接口。
- Flutter Web 内建浏览器走查：登录→选择器→OWNER 上下文→牧场页/横幅/退出，截图留证；可达性倒查（选择器仅超管登录可达、横幅三个 Shell 全挂载）。
- 前后端**同批部署**（旧前端遇 SUPER_ADMIN 会 fallback worker）。

## 7. 验收标准

1. 超管登录后必经选择器；四类角色均可进入且各自首页/操作与真实用户一致（平台台/B2B 控制台/牧场主/牧工）。
2. 租户隔离不破：OWNER@租户A 看不到租户 B 任何数据（抽查 devices/farms/livestock）。
3. 横幅常驻、退出/切换可用；改密锁优先级不被绕过。
4. 每次 switch 落审计；audit 查询端点可见。
5. refresh 后身份不漂移（上下文角色与横幅不变）。
6. 既有 5 角色回归：登录直达、权限、牧场切换全部原样。

## 8. 裁决记录（2026-10-19，用户"按建议"全部采纳）

| # | 问题 | 裁决 |
|---|---|---|
| 1 | disabled 租户可否进入 | **可进入 + 显著警示**（售后排障）；deleted 一律不可 |
| 2 | 退出身份是否保留根 token 免密重选 | **保留**（60 分钟内免密切换） |
| 3 | 上下文内直接切另一上下文 | **支持**（横幅"切换"弹出快速切换 sheet，同一端点、根 token 调用） |
| 4 | 试点到期租户 | **switch 时即拒**（409），排障豁免暂不做 |
| 5 | 超管种子账号 | 账号 **`Admin@hkt.com`**（2026-10-20 用户裁决由 `Admin@HKT` 改名，`V20261020100000` 前向改名迁移——已应用的种子迁移不可原地改）、初始密码 `Admin@2026`（满足 8 位四类策略）。实施要点（已核实 LoginIdentifiers.java:13/91 + SpringDataUserRepository.java:13-17）：两种账号形式都含 `@` → 登录分类走 EMAIL 通道 → 归一化小写 → `findByLoginIdentifier` 按 `LOWER(account)` 命中，**登录链路可用**；但 `isValidAccount` 不允许 `@`，所有 API 建号/改号路径会拒绝该格式 → **此账号只能由 Flyway 种子 SQL 创建**（且仍存账号列非邮箱列——`Admin@hkt.com` 虽是合法邮箱格式，存账号列使经验证的写路径永远造不出同名碰撞，唯一索引兜底）。BCrypt 哈希入迁移 + 三步验证；`must_change_password=TRUE`，改密后不追记文档 |

状态（2026-10-19 晚更新）：**已全部实现并部署 dev 验证通过**（Task 0-10 完成、冒烟 12 项全绿、审计落库、前后端零回归）；待用户集成测试 → 提交 git；实施偏差与冒烟明细见 `../plans/2026-10-19-super-admin-context-entry-plan.md` 执行结果表。
