# API 版本与认证迁移设计

## 1. 背景

当前 `Mobile/` 项目处于高保真 Demo 向 MVP 后端迁移阶段。Flutter 端已支持 `APP_MODE=mock|live`，live 模式通过 `API_BASE_URL` 调用 Node.js Mock Server。后端基础设施需求文档计划引入 AdonisJS v6、PostgreSQL、JWT、租户隔离与统一中间件链，同时要求 Mock-First 开发模式继续可用。

现有 API 契约以 `/api` 为基础路径，新后端规划统一暴露 `/api/v1`。认证也将从固定 `mock-token-{role}` 迁移到真实 JWT。若不先定义版本与认证迁移策略，前后端联调会面临路由不一致、认证双轨失控、回滚困难和兼容层长期分叉等风险。

本设计聚焦两个专项问题：

1. `/api` 到 `/api/v1` 的版本迁移与长期兼容治理。
2. JWT 与 `mock-token-{role}` 的认证链、功能开关和观测策略。

## 2. 目标

- 新版本前端默认走 `/api/v1`。
- 后端长期保留 `/api` 兼容入口，支持旧客户端自然升级。
- `/api` 与 `/api/v1` 共享同一套 controller、service、model、validator，不分叉业务逻辑。
- 认证链固定为 `JWT -> mock-token`，`mock-token` 是否启用由功能开关控制。
- `APP_MODE=mock` 持续可用，`APP_MODE=live` 可按链路灰度联调。
- 回滚时只需要切回前端 `API_BASE_URL=/api`，后端无需回滚代码。

## 3. 非目标

- 不在本设计中实现完整 AdonisJS 后端。
- 不重新定义所有业务端点字段，字段契约仍以 `docs/api-contracts/2026-04-21-backend-api-contract.md` 为基础。
- 不设计 P1/P2 的对象存储、实时通信、IoT 网关等能力。
- 不要求一次性下线 `/api` 或一次性移除 `mock-token`。

## 4. 已确认决策

| 决策项 | 结论 |
|--------|------|
| 时间窗口 | 4 周以上，中长期演进 |
| API 迁移策略 | 前端先切到 `/api/v1`，后端保留 `/api` |
| `/api` 兼容窗口 | 长期保留，直到客户端自然升级 |
| `mock-token` 策略 | 功能开关控制 |
| 推荐方案 | 方案 1：前端先切 + 后端双版本路由 + 认证策略开关 |

## 5. 总体架构

### 5.1 路由边界

后端同时挂载两组 API 前缀：

- `/api/v1/*`：规范契约入口，所有新前端默认使用。
- `/api/*`：长期兼容入口，服务旧客户端与回滚场景。

两组前缀都路由到同一组控制器和服务。`/api` 不拥有独立业务语义，只在必要时通过 adapter 做入参或出参兼容。

```text
Flutter APP_MODE=live
  -> API_BASE_URL=/api/v1
  -> AdonisJS routes
  -> version middleware
  -> auth chain
  -> controller
  -> service
  -> model / database

Legacy client or rollback
  -> API_BASE_URL=/api
  -> same controller/service
  -> optional compatibility adapter
```

### 5.2 单一业务实现源

后端必须遵守以下约束：

- controller 只负责参数接收、调用 validator 和调用 service。
- service 承载业务规则、租户隔离、状态机和审计逻辑。
- model 只表达持久化结构和关系。
- validator 只表达接口入参契约。
- `/api` 与 `/api/v1` 不允许复制两套 controller 或 service。

如需兼容旧字段或历史 ID 格式，只能放在 adapter 中，且 adapter 不得写业务规则。

## 6. 路由设计

### 6.1 双前缀注册

AdonisJS 路由建议按模块注册，并通过函数复用同一套路由定义：

```text
registerApiRoutes('/api')
registerApiRoutes('/api/v1')
```

每个请求进入后先解析 API 版本：

- `/api/v1/*` 标记为 `apiVersion=v1`
- `/api/*` 标记为 `apiVersion=legacy`

`apiVersion` 进入日志、指标和错误上下文。

### 6.2 新功能默认策略

- 新功能先定义在 `/api/v1` 契约中。
- 默认不要求回映射到 `/api`。
- 只有确认旧客户端需要该能力时，才增加 `/api` adapter，并登记兼容债。

### 6.3 回滚策略

前端构建通过 `API_BASE_URL` 控制目标 API：

- 正常：`API_BASE_URL=http://127.0.0.1:3001/api/v1`
- 回滚：`API_BASE_URL=http://127.0.0.1:3001/api`

回滚不改变后端代码、不切换数据库、不改变服务实现，只改变前端入口路径。

## 7. 认证链设计

### 7.1 中间件顺序

API 请求建议使用固定顺序：

1. `cors`
2. `request_id`
3. `access_log`
4. `api_version`
5. `auth_chain`
6. `tenant_scope`
7. `acl`

`request_id` 优先读取 `X-Request-Id`，无值时生成 UUID v4，并回写响应头。

### 7.2 JWT 优先

`auth_chain` 首先尝试 JWT：

- Header 使用 `Authorization: Bearer <token>`。
- JWT 使用 RS256。
- Claims 至少包含 `userId`、`tenantId`、`role`、`permissions`、`exp`、`jti`。
- JWT 校验成功后注入 `ctx.auth.user`、`ctx.tenantId` 和 `ctx.authMode='jwt'`。

### 7.3 mock-token 兜底

当 JWT 校验失败或 token 不是 JWT 格式时，才允许进入 `mock-token` 分支。

`mock-token` 分支必须同时满足：

- `ENABLE_MOCK_TOKEN=true`
- 当前环境符合 `MOCK_TOKEN_ALLOWED_ENVS`
- token 匹配 `mock-token-owner`、`mock-token-worker` 或 `mock-token-ops`

通过后注入模拟用户上下文，并设置 `ctx.authMode='mock'`。

如果 JWT 与 mock-token 都失败，返回：

```json
{
  "code": "AUTH_UNAUTHORIZED",
  "message": "unauthorized",
  "requestId": "req_xxx"
}
```

### 7.4 功能开关

新增环境变量：

| 变量 | 示例 | 说明 |
|------|------|------|
| `ENABLE_MOCK_TOKEN` | `false` | 是否启用 mock-token 兜底 |
| `MOCK_TOKEN_ALLOWED_ENVS` | `dev,staging` | 允许 mock-token 的环境列表 |
| `MOCK_TOKEN_BREAK_GLASS` | `false` | 生产环境紧急演练开关，默认禁止 |
| `MOCK_TOKEN_BREAK_GLASS_EXPIRES_AT` | ISO-8601 | 生产紧急开关过期时间 |
| `API_DEFAULT_VERSION` | `v1` | 前端和文档默认 API 版本 |
| `JWT_PUBLIC_KEY` | PEM | JWT 公钥 |
| `JWT_PRIVATE_KEY` | PEM | JWT 私钥 |

这些变量进入 `config/env.ts`，启动时校验。配置不合法时 fail-fast，避免生产误开。

mock-token 开关遵循以下矩阵：

| 环境 | 默认值 | 允许开启条件 | 违规处理 |
|------|--------|--------------|----------|
| `dev` | 可开启 | `ENABLE_MOCK_TOKEN=true` | 无 |
| `staging` | 默认关闭 | `ENABLE_MOCK_TOKEN=true` 且环境在 `MOCK_TOKEN_ALLOWED_ENVS` | 启动失败 |
| `production` | 强制关闭 | 仅允许临时 break-glass：`ENABLE_MOCK_TOKEN=true`、`MOCK_TOKEN_BREAK_GLASS=true`、`MOCK_TOKEN_BREAK_GLASS_EXPIRES_AT` 未过期 | 启动失败并记录配置错误 |

生产 break-glass 只用于应急演练或事故恢复，必须在审计日志中记录启用时间、操作者、过期时间和原因。常规实施计划不得依赖该能力。

### 7.5 审计与响应头

建议在响应头中回写：

- `X-Request-Id`
- `X-Api-Version: legacy|v1`
- `X-Auth-Mode: jwt|mock`

生产环境如担心泄露内部信息，可只在日志中记录 `authMode`，响应头由环境开关控制。

### 7.6 登录、刷新与登出

认证迁移不仅包含中间件校验，还包含前端获取和刷新 token 的完整链路。

`POST /api/v1/auth/login`：

- 入参：`{ account, password }`
- 返回：`{ accessToken, refreshToken, expiresAt, user }`
- `user` 至少包含 `userId`、`tenantId`、`name`、`role`、`permissions`、`tenantName`

`POST /api/v1/auth/refresh`：

- 入参：`{ refreshToken }`
- 返回新的 `accessToken`、`refreshToken`、`expiresAt`
- Refresh Token 采用旋转策略，每次刷新后旧 token 失效

`POST /api/v1/auth/logout`：

- 使当前 Refresh Token 失效
- Access Token 依靠短过期时间自然失效，后续可引入黑名单

前端迁移要求：

- `ApiCache` 和 live repository 不再从 `API_ROLE` 推导 `mock-token` 作为首选认证来源。
- 登录成功后由会话层保存 `accessToken`、`refreshToken`、`expiresAt` 和 `user`。
- `_headers()` 优先读取会话层真实 `accessToken`。
- 仅当 `ENABLE_MOCK_TOKEN=true` 且处于开发兜底路径时，才允许生成或使用 `mock-token-{role}`。
- `API_ROLE` 可在过渡期保留为开发兜底，但新增 live 模块不得新增对它的硬依赖。

## 8. 兼容契约策略

### 8.1 规范主线

`/api/v1` 是唯一规范契约源。字段定义、枚举、错误码、分页结构都以 `/api/v1` 文档为准。

`/api` 是兼容入口，不再定义新语义。

### 8.2 字段演进规则

- 新增字段：直接加到 `/api/v1`，保持向后兼容。
- 字段重命名：禁止直接改名，必须采用“新增新字段 + 保留旧字段 + 发布公告 + 观测使用率 + 再评估下线”。
- 字段删除：只允许在下一大版本处理；`/api` 长期保留时由 adapter 兜底。
- 枚举扩展：新增值前先确认前端默认分支，不允许导致旧客户端崩溃。

### 8.3 错误语义一致

`/api` 与 `/api/v1` 必须返回同一组业务错误码，例如：

- `AUTH_UNAUTHORIZED`
- `AUTH_FORBIDDEN`
- `RESOURCE_NOT_FOUND`
- `CONFLICT`
- `VALIDATION_ERROR`
- `INTERNAL_ERROR`

兼容层不得改变错误含义。跨租户访问建议统一返回 `RESOURCE_NOT_FOUND`，避免泄露资源存在性；如确需 `AUTH_FORBIDDEN`，必须在端点契约中显式说明。

### 8.4 response_adapter

引入轻量 adapter，只处理兼容差异：

- 旧字段别名映射。
- 历史 ID 格式转换，例如 `alert-001` 与 `alert_001`。
- 旧客户端需要但 `/api/v1` 已调整的响应结构。

adapter 禁止：

- 查询数据库。
- 修改业务状态。
- 承载权限判断。
- 承载租户隔离。

### 8.5 兼容债台账

每个兼容映射必须登记：

| 字段 | 说明 |
|------|------|
| 兼容项 | 例如 `alert id hyphen alias` |
| 影响端点 | 例如 `/api/alerts` |
| 引入原因 | 旧客户端仍依赖 |
| owner | 负责人 |
| 引入日期 | 日期 |
| 风险等级 | low / medium / high |
| 移除条件 | 调用占比低于阈值或旧版本停止维护 |

每月审查一次 `/api` 调用占比和兼容债台账，防止兼容层无限增长。

### 8.6 长期兼容矩阵

长期保留 `/api` 不代表所有新能力都必须回映射。需要维护一份兼容矩阵，建议放在 API 契约文档或独立 `docs/api-contracts/api-compatibility-matrix.md`。

首批矩阵：

| 模块 | `/api` 兼容要求 | `/api/v1` 要求 | 说明 |
|------|-----------------|----------------|------|
| auth / me | 长期保留登录、当前用户查询 | 规范源 | `/profile` 见 §8.7 |
| tenant | 长期保留 Phase 1 CRUD 与状态/License | 规范源 | 旧字段由 adapter 映射 |
| fence | 长期保留列表、详情、创建、更新、删除 | 规范源 | `version` 冲突语义必须一致 |
| alert | 长期保留列表、单条状态迁移、批量处理 | 规范源 | `action` 统一为 `ack|handle|archive` |
| dashboard / map / devices / twin | 保留当前前端已预加载端点 | 规范源 | 路由等价测试可分阶段补齐 |
| stats / livestock 扩展 | 默认不回映射 | 规范源 | 旧客户端确需时登记兼容债 |

每个矩阵项必须有 owner、测试状态和最后审查日期。若某端点不再回映射 `/api`，必须说明不影响旧客户端已依赖能力。

### 8.7 `/me` 与 `/profile` 迁移

`/me` 是认证用户规范投影，`/profile` 是历史“我的页”投影。迁移策略：

- `/api/v1/me` 作为规范端点，返回用户、租户、权限和前端常用 profile 字段。
- `/api/v1/profile` 可作为 `/me` 的轻量 alias，过渡期保留。
- `/api/profile` 长期保留并通过 adapter 调用同一用户投影。
- 前端新代码优先使用 `/me`；旧的 `ApiCache.profile` 可在迁移计划中逐步改为从 `/me` 派生。
- 两个端点认证要求一致，字段差异必须写入兼容矩阵。

## 9. 前端协作策略

### 9.1 API_BASE_URL

新版本前端默认配置：

```text
API_BASE_URL=http://127.0.0.1:3001/api/v1
```

本地 Web 开发继续使用 `127.0.0.1`，避免浏览器将 `localhost` 解析到 IPv6。

### 9.2 禁止新增硬编码

前端新增 live repository 不得硬编码 `/api`，所有路径必须基于 `API_BASE_URL` 拼接。

### 9.3 APP_MODE=mock 保持独立

`APP_MODE=mock` 不应依赖 `/api` 或 `/api/v1`。Mock repository 与本地 seed 继续作为前端主开发回归基线。

### 9.4 APP_MODE=live 灰度

`APP_MODE=live` 按核心链路灰度：

1. auth / me
2. tenant
3. fence
4. alert
5. devices / twin / stats

某条链路尚未稳定时，可在 repository 层回退到 Mock 数据，但必须记录日志或调试信息，避免静默掩盖后端问题。

核心链路的回退边界：

- auth/me、tenant、fence、alert 在验收测试中不得静默回退 Mock。
- 允许回退的页面必须展示或记录数据源标记，例如 `source=mockFallback`。
- 自动化测试需要断言 live 核心链路确实发生 HTTP 请求，并且响应头或调试字段显示 `apiVersion=v1`。
- 若核心链路请求失败，应进入错误态或离线态，而不是渲染 Mock 成功态。

## 10. 测试策略

### 10.1 路由等价测试

对核心端点分别请求 `/api/*` 与 `/api/v1/*`，断言：

- 响应包络一致。
- HTTP 状态码一致。
- 业务 `code` 一致。
- 核心字段一致。
- 仅 adapter 声明的兼容字段允许差异。

首批覆盖：

- `POST /auth/login`
- `GET /me`
- `GET /tenants`
- `POST /tenants`
- `GET /fences`
- `POST /fences`
- `GET /alerts`
- `POST /alerts/:id/ack`
- `POST /alerts/batch-handle`

第二批覆盖当前 live 预加载端点：

- `GET /dashboard/summary`
- `GET /map/trajectories`
- `GET /profile`
- `GET /devices`
- `GET /twin/overview`
- `GET /twin/fever/list`
- `GET /twin/digestive/list`
- `GET /twin/estrus/list`
- `GET /twin/epidemic/summary`
- `GET /twin/epidemic/contacts`

第一批是实施计划的进入门槛；第二批是 `APP_MODE=live` 全路径验收门槛。

### 10.2 认证链测试

覆盖以下场景：

| 场景 | 期望 |
|------|------|
| 有效 JWT | 通过，`authMode=jwt` |
| 无效 JWT + mock-token 关闭 | `401 AUTH_UNAUTHORIZED` |
| 合法 mock-token + 开关开启 | 通过，`authMode=mock` |
| 合法 mock-token + 开关关闭 | `401 AUTH_UNAUTHORIZED` |
| mock-token 开关配置不合法 | 服务启动失败 |

### 10.3 前端回归测试

- `APP_MODE=mock` 下看板、地图、告警、围栏、租户、我的、孪生主路径继续可用。
- `APP_MODE=live + /api/v1` 下 auth/me、tenant、fence、alert 主链路可用。
- `APP_MODE=live + /api` 下核心链路可作为回滚方案可用。
- `APP_MODE=live` 核心链路测试必须断言数据源来自真实 API，不允许 Mock 回退伪装成功。

### 10.4 已知契约问题前置修复

专项实施前或第 3 阶段必须处理：

- `/alerts/batch-handle` 的 `action` 统一为 `ack|handle|archive`。
- `alert-001` 与 `alert_001` 命名风格统一或建立 adapter。
- `/me` 与 `/profile` 字段投影对齐，优先补齐 `tenantName` 等前端使用字段。
- 围栏 `version` 字段进入更新契约，冲突返回 `409 CONFLICT`。

## 11. 可观测与验收

### 11.1 日志字段

所有 API 访问日志必须包含：

- `requestId`
- `apiVersion`
- `authMode`
- `tenantId`
- `userId`
- `method`
- `path`
- `status`
- `latencyMs`

### 11.2 指标

至少建立以下指标：

- `/api` 与 `/api/v1` 请求占比。
- mock-token 使用率。
- JWT 校验失败率。
- 401 / 403 / 409 / 422 / 500 占比。
- 核心端点 P95 延迟。

### 11.3 验收标准

- `APP_MODE=mock` 继续可用。
- `APP_MODE=live` 默认请求 `/api/v1`。
- 前端回滚到 `/api` 不需要后端回滚代码。
- JWT 与 mock-token 行为有自动化测试覆盖。
- 登录、刷新、登出和前端 token 来源有端到端迁移任务。
- 路由等价测试覆盖核心链路。
- `APP_MODE=live` 核心链路验收能证明数据来自真实 API。
- 日志与指标能解释每个请求的 API 版本和认证模式。
- 新功能文档默认只写 `/api/v1`，如需 `/api` 兼容必须登记兼容债。

## 12. 里程碑

### 阶段 1：契约与开关基线

- 定义 `/api/v1` 为规范契约源。
- 前端默认 `API_BASE_URL` 指向 `/api/v1`。
- 后端新增 `ENABLE_MOCK_TOKEN`、`MOCK_TOKEN_ALLOWED_ENVS`、`API_DEFAULT_VERSION`。
- 后端新增生产 break-glass 校验规则与自动化测试。
- 建立兼容债台账模板。
- 建立 `/api` 长期兼容矩阵。

### 阶段 2：双路由与认证链

- 后端挂载 `/api` 与 `/api/v1`。
- 两者共享同一 controller 和 service。
- 实现 `JWT -> mock-token` 认证链。
- 实现登录、刷新、登出与前端 token 读取路径。
- 日志记录 `apiVersion` 与 `authMode`。

### 阶段 3：核心链路联调

- 覆盖 auth/me、tenant、fence、alert。
- 修复 `/alerts/batch-handle`、ID 命名、`/me` 与 `/profile` 字段对齐等已知契约问题。
- 增加路由等价测试与认证链测试。

### 阶段 4：治理与观测

- 上线 `/api` 与 `/api/v1` 流量观测。
- 每月审查兼容债台账。
- 新功能默认只以 `/api/v1` 为契约源。
- 旧端确需支持时才加 adapter。

## 13. 风险与缓解

| 风险 | 缓解 |
|------|------|
| `/api` 与 `/api/v1` 逻辑分叉 | 强制复用 controller/service，路由等价测试作门禁 |
| mock-token 被误用于生产 | `config/env.ts` 启动校验，日志审计 `authMode=mock` |
| 前端仍从 `API_ROLE` 获取 token | 会话层真实 token 优先，新增 live 模块禁止依赖 `API_ROLE` |
| 兼容层无限增长 | 兼容债台账 + 月度审查 + 新功能默认不回映射 |
| 前端静默回退 Mock 掩盖问题 | live repository 回退必须有日志或调试提示 |
| 字段重命名破坏旧客户端 | 新旧字段并行，观测后再考虑下线 |
| 回滚后行为不一致 | `/api` 与 `/api/v1` 共用业务实现，回滚仅切 API_BASE_URL |

## 14. 后续工作

本设计确认后，下一步应创建实施计划，拆分为可执行任务：

1. 前端 `API_BASE_URL` 默认值与硬编码扫描。
2. 后端双路由注册与 `api_version` 中间件。
3. `auth_chain` 中间件与环境变量校验。
4. JWT 登录、刷新、登出与前端 token 来源迁移。
5. response adapter、兼容债台账与长期兼容矩阵。
6. 路由等价测试、认证链测试和真实 API 数据源断言。
7. 核心链路 live 联调与回滚演练。

