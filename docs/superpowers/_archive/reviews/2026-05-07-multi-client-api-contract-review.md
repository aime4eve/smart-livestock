# 多端统一 API 契约评审报告

> **评审日期**: 2026-05-07
> **评审文档**: `docs/superpowers/specs/2026-05-07-multi-client-api-contract-design.md`
> **对照基线**: Mobile/backend/ (Node.js Mock Server 路由 + Open API)、Mobile/mobile_app/ (Flutter ApiCache 实际请求)、后端设计规格 (2026-05-06-mvp-backend-design.md)
> **注**: 契约是 MVP Phase 1 目标态设计。Mock Server 承载的是 Phase 2a Demo 功能集，端点集合不重叠是正常的代际演进，不视为冲突。
> **前置评审**: `2026-05-07-mvp-specs-review.md` 覆盖了两文档间对比的 P0/P1 问题（code 字段类型、ID 类型、设备路径等）。本文档聚焦 API 设计质量、完备性、与 Flutter 消费端的对齐、认证流程、版本策略。

---

## 一、评审范围与方法

评审从四个维度切入：

1. **RESTful 设计质量** — 资源命名、HTTP 方法语义、路径结构、状态码使用
2. **消费端对齐** — 以 Flutter ApiCache 和 Live Repository 的实际请求模式为基准，验证契约是否覆盖真实调用需求，识别契约遗漏和过渡策略空白
3. **完备性审查** — 错误码覆盖、认证流程完整性、Farm Scope 边界条件、分页与过滤约定
4. **演进可行性** — 版本策略、废弃流程、Phase 1→Phase 2 扩展路径

---

## 二、RESTful 设计质量

### 2.1 资源命名

契约的资源路径设计在以下方面一致且规范：

| 维度 | 做法 | 评价 |
|------|------|------|
| **资源名** | 复数名词（`/livestock`、`/fences`、`/alerts`、`/devices`） | ✅ REST 惯例 |
| **嵌套层级** | 最多 2 层（`/farms/{farmId}/livestock/{livestockId}`） | ✅ 控制合理 |
| **动作子资源** | `POST .../acknowledge`、`.../handle`、`.../archive` | ✅ 比自定义动词更 RESTful |
| **批量操作** | `POST .../batch-handle` | ✅ 独立端点清晰 |
| **kebab-case** | `device-licenses`、`gps-logs`、`batch-handle` | ✅ URL 统一风格 |

**发现 1: 动作子资源的 HTTP 方法选择值得商榷。**

契约 §3.3 中告警状态变更使用 `POST`：
```
POST /farms/{farmId}/alerts/{alertId}/acknowledge
POST /farms/{farmId}/alerts/{alertId}/handle
POST /farms/{farmId}/alerts/{alertId}/archive
```

而设备状态变更使用 `PUT`：
```
PUT /farms/{farmId}/devices/{deviceId}/activate
PUT /farms/{farmId}/devices/{deviceId}/decommission
```

契约自己给出的理由是"告警操作为非幂等（记录操作人和时间戳），管理端状态变更用 PUT（幂等）"。这个区分是合理的，但应在 §2 通用约定中作为统一原则成文，而非散落在 §3.3 和 §3.4 的注释中。

**建议**: 在 §2 通用约定中增加一条"HTTP 方法语义约定"，明确：
- `PUT` 用于幂等状态变更（相同请求多次执行结果一致）
- `POST` 用于非幂等状态变更（每次执行产生新的副作用，如记录操作人+时间戳）
- `PATCH` 保留用于部分更新（当前契约未使用，但可预留）

### 2.2 路径结构的一致性

App API 的 Ranch 资源统一挂载在 `/farms/{farmId}/` 下，这是 Farm Scope 硬约束的具体化。路径结构设计合理。

**发现 2: device-licenses 挂载在 farm 路径下与领域归属冲突。**

契约 §3.4 将设备许可证端点放在 `/farms/{farmId}/device-licenses`，但许可证是**租户级**概念（购买方是 tenant，许可证绑定 device 和 tenant）。Mock Server 实际将许可证操作放在 `POST /tenants/:id/license`（租户级路径）。见后端深度评审 H4 项。

**建议**: 评估 device-licenses 是否应移到租户级路径（`/device-licenses`，通过 JWT `tid` 隐式隔离），或保持 `/farms/{farmId}/` 但明确其仅通过 farmId 做归属于该租户的校验，实际查询在 tenant 级别。

**发现 3: GPS 日志路径跨两级资源。**

```
GET /farms/{farmId}/gps-logs/latest           ← 农场级
GET /farms/{farmId}/livestock/{livestockId}/gps-logs  ← 牲畜级
```

这两个端点的资源层级不一致——前者是农场下直接挂 gps-logs（逻辑上是"农场下所有设备的 GPS"），后者是农场下牲畜下挂 gps-logs。实际上牲畜不直接产生 GPS 日志，GPS 日志属于设备，设备安装在牲畜上。当前路径是一个合理的简化（前端按牲畜查 GPS 是首要用例），但后端实现时需要明确 JOIN 路径：`livestock → installation → device → gps_logs`。

**建议**: 在契约中对该端点增加简要说明："通过 livestockId 关联 installation 表和 gps_logs 表，返回该牲畜当前安装设备的 GPS 历史数据"。

### 2.3 分页设计

契约统一使用页码式分页（`page`/`pageSize`），分页上限三端不同（App/Admin 200，Open 100）。设计合理。

**发现 4: gps_logs 等时序数据可能需要 cursor-based 分页。**

对于 `GET /farms/{farmId}/livestock/{livestockId}/gps-logs?startTime=&endTime=`——如果时间范围内有数万条记录，页码式分页的 `OFFSET` 在 PostgreSQL 中性能会下降。但 Phase 1 使用模拟数据，数据量可控，页码式足够。

**建议**: 当前设计可保留。在 Phase 2 设计时序数据查询时评估是否需要增加 cursor-based 分页作为补充（`?cursor=&limit=`），保留 `page`/`pageSize` 作为默认方式。

---

## 三、消费端对齐评审

### 3.1 Flutter 当前请求模式

Flutter `ApiCache.init()` 启动时并发请求 17 个端点。契约对这些端点的覆盖情况：

| Flutter 当前请求 | 契约 Phase 1 | 状态 |
|-----------------|-------------|------|
| `GET /dashboard/summary` | ✅ `GET /farms/{farmId}/dashboard/summary` | 路径变更（增加 farm 前缀） |
| `GET /map/trajectories?animalId=&range=` | ⚠️ `GET /farms/{farmId}/map/overview` | 端点语义不同，需迁移 |
| `GET /alerts?pageSize=100` | ✅ `GET /farms/{farmId}/alerts` | 路径变更 |
| `GET /fences?pageSize=100` | ✅ `GET /farms/{farmId}/fences` | 路径变更 |
| `GET /tenants?pageSize=100` | ❌ 不在 Phase 1 App API 中 | Mock Server 租户列表，契约是 tenant-scoped（`/tenants/me`） |
| `GET /profile` | ✅ `GET /me`（等价，`/profile` 是历史冗余） | 路径归一 |
| `GET /twin/overview` | ❌ Phase 2 | 数字孪生功能 |
| `GET /twin/fever/list` 等 | ❌ Phase 2 | 同上 |
| `GET /devices?pageSize=200` | ✅ `GET /farms/{farmId}/devices` | 路径变更 |
| `GET /subscription/*` 系列 | ❌ Phase 2 Commerce | 订阅功能 |
| `GET /farm/my-farms` | ⚠️ 隐式映射到 `GET /farms` | 端点语义类似，但缺少 `activeFarmId` 字段 |
| `GET /farms/{farmId}/workers` | ✅ `GET /farms/{farmId}/members` | 名称变更（workers→members） |

**结论**: 契约 Phase 1 的端点集合与 Flutter 当前调用集合之间有**结构性偏移**：契约仅覆盖核心底座（Identity + Ranch + IoT 只读模型），而 Flutter 当前承载的是 Phase 2a Demo 功能（数字孪生、订阅、多租户管理）。这在代际演进中是预期内的。

### 3.2 过渡期关键问题

**发现 5: 牧场切换机制从 header 迁移到 path 的过渡路径不完整。**

当前 Flutter 的 `FarmSwitcherController` 依赖以下端点：
```
GET  /farm/my-farms     → 返回 { farms: [...], activeFarmId: "..." }
POST /farm/switch-farm   → 设置 active farm
```

所有后续请求通过 `x-active-farm` header 携带当前农场上下文。

契约的 Farm Scope 设计将这一模式替换为：
- `GET /farms` 返回当前用户的农场列表
- 客户端存储选中的 `farmId`
- 所有 ranch 资源请求使用 `/farms/{farmId}/...` 路径

**缺失**: 契约未明确说明 Flutter 端从"header-based 切换"到"path-based 导航"的过渡步骤：
1. `FarmSwitcherController` 的 `switchFarm()` 方法是否保留？还是改为直接更新 GoRouter 的路径参数？
2. 对于农场级别的页面（如看板、地图），URL 如何变化？当前是 `/dashboard` → 未来应是 `/farms/{farmId}/dashboard`？

**建议**: 在契约 §2.5 或新增的迁移附录中，补充 Flutter 端的牧场切换机制变更说明。至少明确：
- GoRouter 中所有农场级别路由从 `/{page}` 改为 `/{farmId}/{page}`
- `FarmSwitcher` 选择农场后通过 `GoRouter.go('/{farmId}/dashboard')` 而非设置 header
- `GET /farms` 的响应体结构（建议包含 `activeFarmId` 提示字段）

### 3.3 预加载端点数量评估

Flutter 当前启动时并发请求 17 个端点。契约 Phase 1 范围内的等效端点约 7 个（dashboard、map、alerts、fences、devices、me、farms）。每个请求经过 Farm Scope 解析 + JWT 校验 + 数据库查询，响应时间约 50-200ms。并发 7 个请求的总耗时取决于最慢的那个（≈200ms），完全可接受。

**建议**: Phase 1 实现时确保 Farm Scope 解析有缓存（用户-农场关系缓存），避免每个请求查 3 张表。

---

## 四、认证流程评审

### 4.1 JWT 认证流程

契约 §6.1 定义的 JWT 流程完整且合理：

```
POST /auth/login     → { accessToken, refreshToken, expiresIn }
POST /auth/refresh   → { accessToken, refreshToken, expiresIn }  (轮换)
POST /auth/logout    → 注销 refreshToken
```

**发现 6: `expiresIn` 字段在 JWT payload 中已有 `exp` claim，存在冗余。**

客户端可以通过解码 JWT 的 `exp` 字段计算剩余有效期，不需要服务端额外返回 `expiresIn`。但从开发者体验角度，显式返回 `expiresIn`（秒数）减少了客户端的 JWT 解码负担。

**评估**: 保留 `expiresIn` 是合理的 DX 选择，但需在响应文档中注明其语义（"Token 有效期，单位秒"），避免与 `exp`（Unix 时间戳）混淆。

**发现 7: 登录请求体与 Mock Server 不一致。**

| 来源 | 请求体 |
|------|--------|
| 契约 §6.1 | `{ phone, password }` |
| Mock Server | `{ role }`（角色名，直接分配 mock token） |

这是预期差异——Mock Server 无真实认证。但契约应补充：Phase 1 的初始租户和用户如何创建（是否有种子数据脚本或 `/admin/tenants` 端点预创建）。

**发现 8: 缺少 `api_consumer` 角色的 JWT payload 支持。**

契约 §6.1 JWT payload 中 `role` 字段列出四种：`owner`、`worker`、`platform_admin`、`b2b_admin`，但 **缺失 `api_consumer`**。后端设计规格 §1.2 定义了五种 Role（含 api_consumer）。ApiConsumer 是否通过 JWT 登录？还是仅使用 API Key？如果 ApiConsumer 也需要登录获取 token，需补充该角色。

**建议**: 明确 `api_consumer` 的认证方式。如果仅使用 API Key（不通过 JWT），在 §6.1 中注明"api_consumer 角色不适用 JWT 认证，使用 API Key 认证（见 §6.2）"。

### 4.2 API Key 认证

契约 §6.2 的 API Key 设计质量高：

- Key 格式区分 live/test：`sl_live_` / `sl_test_`
- 存储使用 SHA-256 hash（不存明文）
- 设备自注册专用 Key 有独立的 scope 和速率限制
- 认证流程包含 tenantId 归属校验和 scope 校验

**发现 9: 缺少 API Key 首次发放流程。**

契约定义了 Admin API 中的 Key 管理端点（`POST /admin/api-keys`），但未说明：第一个 platform_admin 如何创建？第一个 API Key 如何生成？是否通过数据库种子脚本预置？

**建议**: 在部署/实施计划中补充初始数据种子方案，至少包含：一个 platform_admin 用户、一个 SAMPLE 租户、一个 demo API Key。

---

## 五、错误码评审

### 5.1 错误码覆盖度

契约 §2.3 定义了 14 个业务错误码。对照后端设计规格的领域模型，评估覆盖是否充分：

| 场景 | 契约错误码 | 覆盖 |
|------|-----------|------|
| 参数校验失败 | `VALIDATION_ERROR` (400) | ✅ |
| Token 过期 | `AUTH_TOKEN_EXPIRED` (401) | ✅ |
| Token 无效 | `AUTH_INVALID_TOKEN` (401) | ✅ |
| API Key 无效 | `AUTH_API_KEY_INVALID` (401) | ✅ |
| API Key 过期 | `AUTH_API_KEY_EXPIRED` (401) | ✅ |
| 权限不足 | `AUTH_FORBIDDEN` (403) | ✅ |
| 租户已禁用 | `TENANT_DISABLED` (403) | ✅ |
| 资源不存在 | `RESOURCE_NOT_FOUND` (404) | ✅ |
| 告警非法状态跳转 | `STATE_CONFLICT` (409) | ✅ |
| 资源重复（如重复安装） | `DUPLICATE_RESOURCE` (409) | ✅ |
| Farm Scope 冲突 | `FARM_SCOPE_CONFLICT` (422) | ✅ |
| 速率限制 | `RATE_LIMIT_EXCEEDED` (429) | ✅ |
| 内部错误 | `INTERNAL_ERROR` (500) | ✅ |
| **SAMPLE 阶段超配额** | ❌ 缺失 | 规格 §1.3 有软限制（fence 20/device 10） |
| **BATCH 阶段超 tier 限制** | ❌ 缺失 | 规格 §1.3 有硬门控 |
| **牲畜软删除后操作** | ❌ 缺失 | `DELETE livestock` 后再次操作应返回？ |
| **设备未激活时安装** | ❌ 缺失 | 安装前需校验 `device.status == ACTIVE` |
| **许可证过期时设备安装** | ❌ 缺失 | 安装前需校验许可证有效 |

**建议**: 补充以下错误码：
- `QUOTA_EXCEEDED` (403) — SAMPLE 阶段超配额或 BATCH 阶段超 tier 限制
- `RESOURCE_DELETED` (410) — 软删除的资源（如已删除的牲畜）
- `DEVICE_NOT_ACTIVE` (409) — 设备未激活时尝试安装
- `LICENSE_EXPIRED` (403) — 许可证过期

### 5.2 Flutter 端的错误码使用

Flutter `ApiCache` 中所有判断均为 `body['code'] == 'OK'`，未检查具体错误码做差异化处理。例外是 `fenceSaveErrorMessageForStatusCode()` 方法基于 HTTP 状态码（409、422）做消息映射——这说明 Flutter 端依赖 HTTP 状态码多于业务错误码。

**建议**: 在契约中明确——HTTP 状态码是客户端优先判断的维度，业务错误码用于日志/调试/更精确的错误提示。客户端应始终先检查 HTTP 状态码（2xx = 成功，4xx/5xx = 失败），再解析 body.code 做精细化处理。

---

## 六、Farm Scope 评审

### 6.1 设计质量

Farm Scope 硬约束（§2.5）是契约中设计质量最高的部分之一。三规则：
1. 写操作仅路径
2. 读操作二选一（路径优先，header 兼容）
3. 双来源返回 422

这个设计解决了 Mock Server 当前 header-only 方式的两个安全漏洞：切换 header 可越权访问其他农场、审计日志无法确定实际操作农场。

### 6.2 缺失: 路径注入防御

契约未说明 `farmId` 路径参数的格式校验。如果在 Spring Boot 中 farmId 是 `BIGSERIAL`（数字），应明确：
- Controller 层接受 `@PathVariable Long farmId`
- 非数字输入由 Spring 自动返回 400
- 不需要额外的格式校验

### 6.3 缺失: 读操作 header 兼容模式的具体行为

契约 §2.5 声明"读操作 GET 可仅用 header（兼容模式）"，但未说明：
- 兼容模式的 Farm Scope 解析结果是否与 path 模式完全一致？
- 如果 header 中的 farmId 不属于该租户，是 403 还是 404？
- 响应中是否回显实际使用的 farmId？

**建议**: 补充读操作兼容模式的精确行为规范：
- 仅 `x-active-farm` 时，视为隐式 farmId，与 path farmId 等效
- farmId 不属于租户 → 403 `AUTH_FORBIDDEN`
- 响应体不额外返回 farmId（客户端已知）

---

## 七、Open API 设计评审

### 7.1 设计原则执行

契约 §5 的 Open API 设计遵守了既定的设计原则：

- ✅ 路径与 App API 对齐（`/open/farms/{farmId}/...`）
- ✅ 只读边界（仅设备自注册是写操作）
- ✅ API Key 认证（非 JWT）
- ✅ 速率限制（60/min 默认）
- ✅ 幂等性支持（Idempotency-Key 请求头）
- ✅ 版本锁定（破坏性变更递增 URL）

### 7.2 与 Mock Server Open API 的差异

Mock Server 当前的 Open API（`routes/openApiRoutes.js`）采用了**三层 tier 模型**（free/growth/scale），按 tier 门控端点可用性。契约的 Open API 没有 tier 概念——所有 11 个端点对所有持有有效 API Key 的开发者开放。

**评审**: 契约选择不在 Phase 1 引入 Open API tier 是务实的。Phase 1 的核心目标是"提供稳定可用的 API 基础"，tier 门控作为 Phase 2 Commerce Context 的商业化功能更合适。

**建议**: 在契约 §5 或 §7.2 中注明：Phase 2 引入 Commerce Context 后，Open API 可增加 tier 维度的端点门控和速率差异化。

### 7.3 缺少的 Open API 端点

契约 Phase 1 的 Open API 仅覆盖 11 个端点（牲畜/围栏/告警/设备/GPS 只读 + 设备自注册），不包含：
- Dashboard 汇总（`GET /open/farms/{farmId}/dashboard/summary`）
- Map 总览（`GET /open/farms/{farmId}/map/overview`）

**评审**: 这两个读模型端点理论上也适合 Open API（第三方可能需要展示看板和地图），但契约选择不在 Phase 1 暴露。建议在 §5 设计要点中注明排除了哪些 App API 端点以及原因（如"读模型端点聚合了业务逻辑，不宜直接暴露给第三方"）。

### 7.4 Idempotency-Key 实现方案缺失

契约 §5 提到"POST 请求支持 `Idempotency-Key` 请求头，相同 key 24h 内返回缓存结果"，但未说明实现方式：
- 缓存存储位置：Redis 还是应用内存？
- 缓存内容：完整 HTTP 响应（含状态码和响应头）还是仅 body？
- key 冲突处理: 如果两个不同的 POST body 使用了相同的 Idempotency-Key？

**建议**: 补充 Idempotency-Key 的实现规范。推荐：Redis 存储 key → (status, headers, body) 映射，TTL 24h。key 冲突时返回 409 `DUPLICATE_RESOURCE`，注明"Idempotency-Key 已被使用"。

---

## 八、版本与演进策略评审

### 8.1 版本规则

契约 §7.1 的版本规则明确且可操作：
- App/Admin 破坏性变更保留旧版本 6 个月
- Open API 破坏性变更保留旧版本 12 个月
- 非破坏性变更（新增字段、端点、枚举值）不递增版本号

**发现 10: 枚举值新增需要客户端容错策略。**

契约将"新增枚举值"归类为非破坏性变更。这要求客户端对此有容错处理——遇到未知枚举值时不崩溃。当前 Flutter 端的枚举解析代码（如 `ApiCache._parseDeviceItem` 中的 `switch` 语句）**没有 default 容错**——如果后端返回未知的 `deviceType`，`switch` 会走 `_` 分支（已有，`_ => DeviceType.accelerometer`），但如果后端返回未知的 `status`，也会走 `_ => DeviceStatus.lowBattery`。

**建议**: 在契约 §7.1 中增加一条客户端要求："客户端必须容错处理未知枚举值（使用默认值或忽略），不可因新增枚举值而崩溃"。这是服务端可新增枚举值的前提条件。

### 8.2 Phase 1→2 扩展路径

契约 §7.2 列出了 Phase 2 新增端点的挂载位置：
- Health → `/farms/{farmId}/twin/*`（App + Open）
- Commerce → `/subscription/*`、`/contracts/*`、`/revenue/*`（App + Admin）
- Analytics → `/farms/{farmId}/stats/*`、`/farms/{farmId}/trends/*`（App + Admin）

**发现 11: Health 上下文路径与 Mock Server 不一致。**

Mock Server 的数字孪生路径是 `/twin/fever/list`（无 farm 前缀），而契约规划为 `/farms/{farmId}/twin/fever/list`。这是正确的——Health 数据属于 Farm Scope，应该加 farm 前缀。但在 Phase 2 迁移时需更新 Flutter 端所有 twin 相关路由。

**建议**: 在实施计划中标注 Phase 2 迁移时需要更新的 Flutter 路由清单。

### 8.3 `x-active-farm` 废弃计划

契约 §7.3 计划在 Phase 2 上线时标记废弃 `x-active-farm` header，3 个月后移除。这个计划是务实的，但需要明确检查点：
- 废弃标记的条件："Phase 2 上线" 定义为 Spring Boot 后端 Phase 2 功能部署到生产环境
- 3 个月倒计时的起点：`Deprecation: true` 响应头首次出现在生产响应中
- 移除条件：确认所有客户端（Flutter、Vue 3、第三方 SDK）已迁移到 path-based 方式

---

## 九、契约文档管理评审

契约 §7.4 规划的契约文档结构合理：
```
docs/api-contracts/
├── api-overview.md
├── app-api.md
├── admin-api.md
├── open-api.md
└── changelog.md
```

**发现 12: 每个端点缺少请求/响应 Body 的 JSON Schema。**

当前契约文档以 prose 表格定义端点，但未包含每个端点的请求 Body 和响应 Body 的 JSON 结构示例。这对于实施是不够的——开发者需要一个可直接参考的 JSON 结构。

**建议**: 在 `app-api.md`、`admin-api.md`、`open-api.md` 中，为每个端点补充：
- Request Body JSON 示例（含字段说明）
- Response Body JSON 示例（成功和至少一种错误）
- 查询参数说明（类型、必填/可选、默认值）

### 8.4 缺少 `api_consumer` 角色的 JWT payload 支持（移至 §6.1 已讨论）

已在发现 8 中覆盖。

---

## 十、问题汇总与优先级

### P0 — 阻断实施

| 编号 | 问题 | 建议 |
|------|------|------|
| C1 | 牧场切换过渡路径不完整 | 补充 Flutter 端从 header-based 到 path-based 的迁移步骤和 GoRouter 路由变更说明 |
| C2 | 缺少初始种子数据方案 | 明确 platform_admin 创建、租户创建、API Key 首次发放的种子脚本 |

### P1 — 影响质量

| 编号 | 问题 | 建议 |
|------|------|------|
| C3 | 错误码体系不完整 | 补充 QUOTA_EXCEEDED、RESOURCE_DELETED、DEVICE_NOT_ACTIVE、LICENSE_EXPIRED |
| C4 | device-licenses 农场归属冲突 | 评估是否改到租户级路径（JWT tid 隔离） |
| C5 | Idempotency-Key 实现规范缺失 | 补充存储位置、缓存内容、key 冲突处理规则 |
| C6 | 每个端点缺少 JSON 示例 | 在独立的 api-contracts 文档中补充请求/响应 Body 示例 |
| C7 | 读操作 header 兼容模式行为不精确 | 补充隐式 farmId 的校验和返回行为规范 |

### P2 — 改进

| 编号 | 问题 | 建议 |
|------|------|------|
| C8 | GPS 日志路径跨资源层级的实现路径需说明 | 补充 JOIN 路径注释（livestock→installation→device→gps_logs） |
| C9 | `api_consumer` 角色认证方式需澄清 | 明确 api_consumer 使用 API Key 非 JWT |
| C10 | 缺少 HTTP 方法语义统一原则 | 在 §2 中增加 PUT/POST/PATCH 用法约定 |
| C11 | Open API 缺少排除端点的理由说明 | 注明为何不暴露 dashboard/map 端点给 Open API |
| C12 | 枚举值容错要求未对客户端声明 | 在契约中增加客户端容错要求条款 |
| C13 | `expiresIn` 与 `exp` 的冗余说明 | 在文档中注明 expiresIn 为秒数，exp 为 Unix 时间戳 |

---

## 十一、总体评估

API 契约文档在以下方面表现出色：

1. **三端隔离架构** — 路由空间 + 认证方式 + 演进节奏三层隔离，从 Mock Server 的混合路由模式中升维
2. **Farm Scope 硬约束** — 写操作仅路径、读操作二选一、双来源 422 拒绝——三规则精确实用，解决了 header-only 的安全漏洞
3. **统一分页与响应包络** — `{ code, message, requestId, data }` 格式三端一致，分页 `page/pageSize` 简单可靠
4. **版本策略** — 破坏性/非破坏性变更定义明确，废弃流程有 Sunset 机制，Open API 严格兼容承诺
5. **Open API 设计** — 速率限制 + Idempotency-Key + 设备自注册专用 Key，为第三方开发者提供了生产级保障

主要改进空间集中在：
- **过渡策略不完整** — 从 Mock Server header-based 到契约 path-based 的迁移步骤缺乏具体说明
- **JSON 示例缺失** — 81 个端点的请求/响应 Body 需在独立文档中补全
- **错误码补充** — 配额超出、软删除资源、设备未激活等场景的错误码
- **Idempotency-Key 实现规范** — Open API 的幂等性保障需成文

**核心建议**: 优先完成 P0 项（过渡路径 + 种子数据方案），然后进入独立 API 文档的编写（补充每个端点的 JSON 示例和错误响应），最后在 Phase 1 编码中按此契约实现端点。

---

## 附录 A: 契约端点与 Flutter 请求对照表

| Flutter 当前调用 | HTTP | 契约 Phase 1 等价端点 | Phase |
|-----------------|------|---------------------|-------|
| `/auth/login` | POST | `/auth/login` | P1 |
| `/dashboard/summary` | GET | `/farms/{farmId}/dashboard/summary` | P1 |
| `/map/trajectories` | GET | `/farms/{farmId}/map/overview`（语义调整） | P1 |
| `/alerts` | GET | `/farms/{farmId}/alerts` | P1 |
| `/fences` | GET/POST/PUT/DELETE | `/farms/{farmId}/fences` | P1 |
| `/tenants?pageSize=100` | GET | `/tenants/me`（改为 tenant-scoped） | P1 |
| `/tenants/{id}` | GET/PUT/DELETE | 无（契约无 admin 外 tenant CRUD） | — |
| `/tenants/{id}/status` | POST | `/admin/tenants/{id}/status` | P1 |
| `/tenants/{id}/license` | POST | 无等价（契约无 license 调整端点） | — |
| `/tenants/{id}/devices` | GET | `/admin/devices?tenantId=`（需确认） | P2 |
| `/profile` | GET | `/me` | P1 |
| `/twin/*` | GET | 无（Phase 2 Health Context） | P2 |
| `/devices` | GET | `/farms/{farmId}/devices` | P1 |
| `/subscription/*` | GET/POST | 无（Phase 2 Commerce） | P2 |
| `/b2b/*` | GET/POST | 无（Phase 2 Commerce） | P2 |
| `/farm/my-farms` | GET | `/farms` | P1 |
| `/farm/switch-farm` | POST | 无（改为路径-based 导航） | P1 |
| `/farms/{farmId}/workers` | GET | `/farms/{farmId}/members` | P1 |
| `/revenue/periods` | GET/POST | 无（Phase 2 Commerce） | P2 |
| `/contracts/*` | GET | 无（Phase 2 Commerce） | P2 |

## 附录 B: Mock Server 当前端点与契约对照（Phase 1 相关部分）

| Mock Server | 契约 Phase 1 | 差异 |
|------------|-------------|------|
| `GET /fences` | `GET /farms/{farmId}/fences` | 增加 farm 前缀 + Farm Scope |
| `POST /fences` | `POST /farms/{farmId}/fences` | 同上 |
| `PUT /fences/{id}` | `PUT /farms/{farmId}/fences/{id}` | 同上 |
| `DELETE /fences/{id}` | `DELETE /farms/{farmId}/fences/{id}` | 同上 |
| `POST /alerts/{id}/acknowledge` | `POST /farms/{farmId}/alerts/{id}/acknowledge` | 增加 farm 前缀 |
| `GET /devices` | `GET /farms/{farmId}/devices` | 增加 farm 前缀 |
| `GET /me` | `GET /me` | ✅ 一致 |
| `GET /profile` | 无（归一为 `/me`） | 冗余端点移除 |
| `POST /auth/login` (role) | `POST /auth/login` (phone+password) | 认证方式变更 |
| `GET /dashboard/summary` | `GET /farms/{farmId}/dashboard/summary` | 增加 farm 前缀 |
| `GET /farm/my-farms` | `GET /farms` | 端点路径简化 |
| `POST /farm/switch-farm` | 无 | 改为客户端路径导航 |
