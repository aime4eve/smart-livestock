# 后端基础设施建设需求（基于 mobile_app 现状）

## 0. 文档说明

- **目标**：在**保持 Mock 开发模式可持续可用**的前提下，把 App 从"Mock 先行 + Node 桩"过渡到**可生产部署的后端系统**，明确基础设施清单与优先级。
- **配套文档**：`api-contracts/2026-04-21-backend-api-contract.md`（字段契约） + `superpowers/specs/2026-04-20-tenant-management-design.md`（租户模块设计）。
- **前提**：当前后端（`Mobile/backend`）是 Express 5 + 内存 seed 的 Mock 服务器，不具备任何持久化、鉴权、隔离、可观测能力。MVP 后端采用 **AdonisJS v6**（TypeScript 原生，内置 Lucid ORM + VineJS + Auth）逐步替换，但在达到 Live 联调稳定前保留 Mock 作为开发兜底模式。

---

## 1. 现状画像

| 维度 | 当前实现 | 风险 |
|------|----------|------|
| 运行形态 | 单进程 Node.js，端口 3001 | 不可水平扩展 |
| 鉴权 | 三个固定 `mock-token-{role}` | 无法区分用户/租户，无过期/撤销 |
| 数据存储 | `data/*.js` 内存 seed；`fenceStore`/`tenantStore` 进程内可变 | 重启丢失，不支持并发写入 |
| 租户隔离 | 无，所有角色共享同一数据集 | 多租户伪命题，数据泄露风险 |
| 响应包络 | 自研 `res.ok` / `res.fail` | ✅ 可保留 |
| 请求 ID | 每次响应生成新 ID，不从请求头读取 | 无法贯穿链路追踪 |
| 错误处理 | 散落在各路由 `try/catch` | 无统一 500 兜底、无 async 包装 |
| 校验 | 手写 `if` | 维护成本高、契约易漂移 |
| 日志 | 仅启动日志 | 无审计、无访问、无错误采集 |
| 限流 | 无 | 易被压垮或刷接口 |
| 测试 | `geo.test.js` + `fenceStore.test.js`（非 HTTP） | 无 API 契约保障，改动易破坏 |
| 部署 | 本地 `node server.js` | 无容器化、无 CI/CD |

---

## 2. 建设目标与阶段

### P0（2-4 周，MVP 可对外联调）

目的：支撑 mobile_app `APP_MODE=live` 稳定联调、保证数据不丢失、基础安全。

1. 真实认证与 JWT
2. 持久化存储（Postgres + 迁移）
3. 租户隔离（数据层 + 中间件）
4. 统一请求/响应中间件链（requestId、错误处理、校验）
5. 结构化日志 + 访问日志
6. Docker 化 + docker-compose 本地一键起
7. HTTP 级契约测试（Supertest）

**P0 补充原则（Mock-First）**：

- `APP_MODE=mock` 必须持续可用，支撑前端完成全功能开发与回归。
- `APP_MODE=live` 采用“按链路灰度接入”：先 auth/me，再 tenant/fence/alert，再 twin/devices。
- 未完成 Live 对齐的模块，前端允许回退到 Mock repository，禁止一次性切断 Mock。

### P1（4-8 周，Demo → 生产）

8. RBAC 持久化与动态权限
9. 对象存储（图片、导入导出文件）
10. 限流与熔断
11. OpenAPI/Swagger 自动生成
12. 可观测（指标 + 分布式追踪）
13. CI/CD 流水线 + 环境分层
14. 数据库备份与恢复演练

### P2（8 周+，规模化）

15. 事件驱动（消息队列）
16. WebSocket/SSE（告警实时推送、设备在线心跳）
17. 定时任务与批处理（License 计费、统计聚合）
18. 多租户数据面隔离（schema-per-tenant 或行级策略）
19. 数据湖接入（IoT 设备遥测）
20. 压测与性能基线

---

## 3. 详细需求

### 3.1 认证与授权（P0）

**目标**：在保留开发期 `mock-token-{role}` 兼容的前提下，建立真实账户-租户-角色体系（JWT + Refresh Token）。

**实现要求**：

- `POST /api/v1/auth/login`：入参 `{ account, password }`，返回 `{ accessToken, refreshToken, expiresAt, user }`。
- Access Token：**JWT（RS256）**，Claims 包含 `userId` / `tenantId` / `role` / `permissions` / `exp` / `jti`；使用 `@maximemrf/adonisjs-jwt` 配置 `jwt` guard。
- Refresh Token：随机 128-bit，服务端持久化到 **Postgres `refresh_tokens` 表**（含 `expires_at`，P0 不引入 Redis）；P1 迁移到 Redis。
- `GET /api/v1/me` / `POST /api/v1/auth/logout` / `POST /api/v1/auth/refresh`。
- 密码：AdonisJS 内置 `Hash` 服务（argon2，cost 可配置）。Phase 2 可接 OIDC（企业微信 / 飞书）。
- **兼容层**：切换期保留 `mock-token-*` 作为开发环境白名单 token，在 `app/middleware/mock_token.ts` 中实现；生产禁用。
- **切换策略**：鉴权链按“JWT 优先，mock-token 兜底（仅 dev）”执行，保证 `APP_MODE=mock` 与 `APP_MODE=live` 可并行演进。

**AdonisJS Auth 配置**（`config/auth.ts`）：

- Guard: `jwt`（`@maximemrf/adonisjs-jwt`），配置 RS256 密钥对
- Provider: `lucid`，模型 `app/models/user.ts`
- 路由保护：`router.use(middleware.auth({ guards: ['jwt'] }))` + 自定义 `tenant_scope` 中间件注入 `ctx.tenantId`

**影响前端**：

- `mobile_app/lib/core/api/api_cache.dart` 的 `_headers(role)` 改为优先从 `SessionController` 取真实 Token。
- 在 Live 未全量覆盖前，允许 `API_ROLE` 作为开发兜底开关存在；待核心链路（auth/me/tenant/fence/alert）稳定后再移除。
- 约束：新增页面不得新增对 `API_ROLE` 的硬依赖，历史依赖按模块逐步清理。

### 3.2 数据持久化（P0）

**技术选型**：

- **PostgreSQL 16**：关系数据（租户、用户、设备、牲畜、围栏、告警）。
- **Redis 7**（P1）：限流计数、Refresh Token 黑名单；P0 不引入。
- **ORM**：**Lucid**（AdonisJS 内置，Active Record，schema-first 迁移）；放弃内存 seed store。

**迁移清单**（基于 `data/*.js`）：

| 表 | 关键字段 | 主外键 |
|----|----------|--------|
| `tenants` | id, name, status, license_total, license_used, contact_*, region, remarks, created_at, updated_at, last_updated_by | — |
| `users` | id, tenant_id, account, password_hash, name, role, mobile, notification_enabled | FK tenant_id |
| `permissions` | id, code, description | — |
| `role_permissions` | role, permission_id | — |
| `animals` | id, tenant_id, ear_tag, livestock_id, breed, age_months, weight_kg, health, fence_id, lat, lng | FK tenant/fence |
| `devices` | id, tenant_id, name, type, status, bound_ear_tag, battery_percent, signal_strength, last_sync | FK tenant |
| `fences` | id, tenant_id, name, type, status, coordinates(JSONB), alarm_enabled, version | FK tenant |
| `alerts` | id, tenant_id, type, title, occurred_at, stage, level, ear_tag, livestock_id, priority | FK tenant |
| `tenant_operation_logs` | id, tenant_id, operator_id, action, reason, payload(JSONB), created_at | 支撑租户日志 API |
| `audit_logs` | id, tenant_id, actor_id, resource, action, request_id, ip, ua, payload, created_at | 全局审计 |

**要求**：

- 所有业务表必须有 `tenant_id`（ops 账户除外）、`created_at`、`updated_at`。
- 迁移工具：`node ace migration:run`；迁移文件进 git（`database/migrations/`）。
- 数据初始化：`node ace db:seed`，Seeder 文件在 `database/seeders/`，将 `data/seed.js` 数据一次性灌入 Postgres。
- `licenseUsed` 由 `animals` 按 `tenant_id` 聚合，避免手写；Phase 2 可用物化视图或写入时维护。
- 围栏等高频并发修改资源增加 `version` 列做乐观锁（映射到 §API 契约 3.6）。

### 3.3 租户隔离（P0）

**原则**：除 `ops` 角色外，所有查询必须强制注入 `tenant_id` 过滤。

**实现路径**（从易到难）：

1. **应用层守卫**（P0）：在 `app/services/base_service.ts` 基类里统一 `.where('tenant_id', ctx.auth.user!.tenantId)`；ops 走明确的"跨租户"方法。
2. **Lucid 全局 Scope**（P1）：为各模型定义 `TenantScope`（`Model.query().withScopes(scopes => scopes.forTenant(tenantId))`），自动注入 `tenant_id`。
3. **数据库行级安全**（P2）：Postgres RLS + `SET app.tenant_id`，防御最终防线。

**必须**：

- 禁止在 Controller 层手写 SQL；所有数据访问通过 Lucid Model 或 Service。
- 编写自动化测试：`A 租户不能读取 B 租户数据`（至少覆盖 tenant/animal/device/fence/alert 五张表）。
- 将“跨租户读写被拒绝”设为 CI 门禁（不通过不得合并），避免在 Mock 与 Live 双轨阶段引入隔离回退。

### 3.4 请求链路中间件（P0）

AdonisJS 中间件在 `start/kernel.ts` 中注册，执行顺序：

**Server 级全局中间件**（所有请求）：
1. `cors`（`config/cors.ts`，生产白名单）
2. `request_id`：**优先读取 `X-Request-Id` 请求头**，否则生成 UUID v4，写入 `ctx.requestId` 并回写响应头
3. `pino_http`（结构化访问日志，关联 requestId + tenantId + userId）

**路由级具名中间件**（按需附加）：
- `auth`：`middleware.auth({ guards: ['jwt'] })`，注入 `ctx.auth.user`
- `tenant_scope`：从 `ctx.auth.user.tenantId` 注入租户上下文
- `mock_token`（仅 dev）：允许 `mock-token-{role}` 白名单通过
- `acl`：`middleware.acl('permission.code')`，基于权限码校验

**API 版本与兼容**：

- 新后端统一以 `/api/v1` 暴露；Mock 阶段保留 `/api`。
- 过渡期提供兼容策略（二选一）：
  1) 后端同时挂载 `/api` 与 `/api/v1`；  
  2) 前端以 `API_BASE_URL` 区分模式与版本。
- 禁止无公告直接切断 `/api`，需在联调验证通过后再移除。

**异常处理**：AdonisJS 全局 `app/exceptions/handler.ts`（继承 `HttpExceptionHandler`）：
- 已知业务异常（`E_VALIDATION_ERROR` / `E_UNAUTHORIZED` / `E_FORBIDDEN` / `E_ROW_NOT_FOUND` / `E_CONFLICT`）→ 对应 HTTP 状态码 + 统一包络
- 未知异常 → 500 + 记录完整堆栈到 pino，返回 `INTERNAL_ERROR` 通用消息（不泄露堆栈）

**环境变量**（`config/env.ts` Vine 校验，启动时 fail-fast）：
`NODE_ENV`、`LOG_LEVEL`、`DB_HOST/PORT/USER/PASSWORD/DATABASE`、`JWT_PRIVATE_KEY`（PEM）、`JWT_PUBLIC_KEY`（PEM）、`CORS_ORIGINS`、`PORT`。

### 3.5 参数校验与契约一致性（P0）

- 使用 **VineJS**（AdonisJS 内置）：在 `app/validators/` 下定义校验器，校验失败由框架统一转为 `E_VALIDATION_ERROR 422`，错误信息包含字段路径。
- 为以下端点**强制**实现 Validator 类：`POST /tenants`、`POST /tenants/:id/status`、`POST /tenants/:id/license`、`POST /fences`、`PUT /fences/:id`、`POST /alerts/batch-handle`、`POST /auth/login`。
- **OpenAPI**（P1）：使用 `adonis-autoswagger` 或手写 `openapi.yaml`，发布 Swagger UI 到 `/api/docs`（生产环境需鉴权保护）。

### 3.6 可观测性（P0 日志 / P1 指标追踪）

| 能力 | 方案 | 阶段 |
|------|------|------|
| 结构化日志 | `pino` + JSON 输出到 stdout，`pino-http` 记录 `method/path/status/latency/tenantId/userId/requestId` | P0 |
| 错误采集 | Sentry（Node SDK），挂到 `errorHandler` | P0 |
| 指标 | `prom-client`，暴露 `/metrics`；Prometheus + Grafana | P1 |
| 追踪 | OpenTelemetry + OTLP → Tempo/Jaeger；Trace ID 与 requestId 联动 | P1 |
| 审计日志 | 写入 `audit_logs` 表（见 §3.2）；关键写操作强制落库 | P0 |

**关键指标**：请求量 QPS、P50/P95/P99 延迟、4xx/5xx 率、DB 连接池使用率、登录成功/失败数、告警处理时效。

### 3.7 测试基础设施（P0）

当前仅 `geo` 与 `fenceStore` 数据层测试；需补：

- **契约测试（HTTP 级）**：AdonisJS 内置测试套件（`@japa/runner` + `@japa/api-client`），覆盖 §API 契约 3.1–3.11 每个端点的**成功路径 + 典型错误（401/403/404/409/422）**；测试命令 `node ace test`。
- **租户隔离测试**：在 Seeder 注入 A/B 两个租户数据，断言跨租户读写被拒绝。
- **契约快照测试**：关键 JSON 响应通过 `assert.snapshot()`，防止字段漂移。
- **CI 门槛**：`node ace test` 必须通过；覆盖率目标行数 70%，关键路径（auth/tenant/fence）90%。
- **双模式回归**：P0 阶段新增回归任务，确保 `APP_MODE=mock` 核心流程不被 Live 接入破坏。

**修复项**：
- 将 `tenantStore.test.js` 加入测试套件（迁移到 Japa）。
- 修复 `POST /alerts/batch-handle` 的 `action` 校验 / 分支不一致（见 API 契约 §3.5）。

### 3.8 CI/CD（P1）

- **CI（GitHub Actions）**：`lint → typecheck → test → build → docker build → push`。
- **环境分层**：`dev`（本地 / docker-compose）→ `staging`（内网联调）→ `prod`。
- **部署**：Kubernetes（Helm Chart）或 Docker Compose on VPS；最低需 rolling update + readiness probe。
- **密钥管理**：不入 git；本地用 `.env`（加入 `.gitignore`），线上用 K8s Secret / Vault。

### 3.9 限流与熔断（P1）

- **网关层**：`@adonisjs/limiter`（AdonisJS 官方限流包）+ Redis 存储；登录 10 次/分钟/IP，普通 API 100 次/分钟/用户。
- **熔断**：对外部依赖（GPS 服务、AI 模型、地图 API）使用 `opossum`，失败快速返回 `UPSTREAM_UNAVAILABLE 503`。

### 3.10 文件与对象存储（P1）

**用途**：牲畜照片、告警现场图、导入导出 Excel、导出 PDF。

- **选型**：MinIO（自建）或 阿里云 OSS / AWS S3。
- **上传模式**：后端签发预签名 URL，前端直传（减轻后端带宽）。
- **清理策略**：临时文件 7 天过期；正式资源绑定业务主键。

### 3.11 实时通信（P2）

**候选场景**：

- 告警实时推送（新告警 → 在线前端立即刷新）。
- 设备在线心跳（`device.lastSync` 不再轮询刷新）。
- 地图牲畜位置点（Phase 2 可视化）。

**方案**：

- 短期：SSE（`Content-Type: text/event-stream`），AdonisJS Response 原生支持。
- 长期：WebSocket（`@adonisjs/transmit` 或 Socket.IO），按 `tenantId` 分 room。

### 3.12 多租户扩展（P2）

- **规模信号**：单 schema 承载 >100 租户、或某租户数据量 >1000 万行。
- **方案**：
  - Schema-per-tenant（Postgres search_path 切换）。
  - 或 数据库-per-tenant（极高隔离，运维成本高）。
- **计费/License**：基于 `tenants.license_total` 定时任务校验 `license_used`，超限触发状态变更与通知。

### 3.13 数据导入导出与 IoT 接入（P2）

- **批量导入**：牲畜、设备支持 CSV/Excel 上传，异步任务（BullMQ + Redis）。
- **IoT 上报**：MQTT/HTTP 上报 → Kafka → 持久化到 `device_telemetry`（时序库如 TimescaleDB / InfluxDB）。
- **数据网关**：独立服务（Go/Node），对外暴露 `POST /ingest/telemetry`；不污染业务 API。

---

## 4. 技术栈推荐

| 层 | 推荐 | 备选 / 说明 |
|----|------|-------------|
| **Web 框架** | **AdonisJS v6**（TypeScript 原生，全栈框架） | Fastify（需自行组装） |
| **语言** | **TypeScript**（AdonisJS v6 原生，无需迁移配置） | — |
| **ORM** | **Lucid**（AdonisJS 内置，Active Record，支持迁移/Seeder/Factory） | Drizzle（需手动接入） |
| **校验** | **VineJS**（AdonisJS 内置，替代 Zod） | — |
| **Auth** | **`@maximemrf/adonisjs-jwt`**（JWT RS256 guard） | AdonisJS Access Tokens（opaque） |
| **哈希** | **Argon2**（AdonisJS `Hash` 服务内置） | bcrypt |
| **限流** | **`@adonisjs/limiter`**（P1） | express-rate-limit |
| **DB** | **PostgreSQL 16** | — |
| **缓存** | **Redis 7**（P1，限流/黑名单） | P0 不引入 |
| **日志** | **pino**（AdonisJS 内置 logger 底层） | winston |
| **测试** | **Japa**（AdonisJS 内置，`@japa/api-client`） | Vitest + Supertest |
| **追踪** | **OpenTelemetry**（P1） | — |
| **部署** | **Docker + docker-compose**（P0）→ **Kubernetes**（P1） | — |
| **对象存储** | **MinIO / 阿里云 OSS**（P1） | — |
| **CI** | **GitHub Actions** | — |

---

## 5. 目录结构建议

`Mobile/backend` 替换为全新 AdonisJS v6 项目（`node ace new backend --kit=api`），目录遵循 AdonisJS 约定：

```
Mobile/backend/
├── app/
│   ├── controllers/           # HTTP 控制器（薄层，只做参数校验 + 调用 service）
│   │   ├── auth_controller.ts
│   │   ├── tenants_controller.ts
│   │   ├── fences_controller.ts
│   │   ├── alerts_controller.ts
│   │   ├── animals_controller.ts
│   │   ├── devices_controller.ts
│   │   ├── stats_controller.ts
│   │   └── twin_controller.ts
│   ├── middleware/
│   │   ├── request_id_middleware.ts   # 读取/生成 X-Request-Id
│   │   ├── tenant_scope_middleware.ts # 注入 ctx.tenantId
│   │   ├── mock_token_middleware.ts   # dev 环境 mock-token 兼容层
│   │   └── acl_middleware.ts          # 权限码校验
│   ├── models/                # Lucid Active Record 模型
│   │   ├── user.ts
│   │   ├── tenant.ts
│   │   ├── animal.ts
│   │   ├── device.ts
│   │   ├── fence.ts
│   │   ├── alert.ts
│   │   ├── refresh_token.ts
│   │   └── audit_log.ts
│   ├── services/              # 业务逻辑层
│   │   ├── base_service.ts    # 泛型基类，统一注入 tenant_id
│   │   ├── auth_service.ts
│   │   ├── tenant_service.ts
│   │   ├── fence_service.ts
│   │   └── alert_service.ts
│   ├── validators/            # VineJS 校验器
│   │   ├── auth_validator.ts
│   │   ├── tenant_validator.ts
│   │   ├── fence_validator.ts
│   │   └── alert_validator.ts
│   └── exceptions/
│       └── handler.ts         # 全局异常处理（继承 HttpExceptionHandler）
├── config/
│   ├── auth.ts                # jwt guard 配置
│   ├── database.ts            # Lucid 连接配置
│   ├── cors.ts
│   └── logger.ts
├── database/
│   ├── migrations/            # Lucid 迁移文件（进 git）
│   └── seeders/
│       └── main_seeder.ts     # 对齐 data/seed.js，docker-compose 可直接 seed
├── start/
│   ├── routes.ts              # 路由注册，统一 /api/v1/ 前缀
│   └── kernel.ts              # 全局与具名中间件注册
├── tests/
│   ├── functional/            # Japa API 契约测试（@japa/api-client）
│   │   ├── auth.spec.ts
│   │   ├── tenant.spec.ts
│   │   ├── fence.spec.ts
│   │   └── tenant_isolation.spec.ts  # 跨租户隔离测试
│   └── helpers/               # 测试 seed helpers
├── adonisrc.ts
├── Dockerfile
├── docker-compose.yml         # P0: app + postgres
├── package.json
└── tsconfig.json
```

---

## 6. 实施路线图（建议）

总周期约 **12 周**（P0 约 4 周 + Sprint 3-4 约 3+3 周）。

| 迭代 | 时长 | 交付 | 对应需求 |
|------|------|------|----------|
| **Sprint 1-2**（基础框架） | 4 周 | 新建 AdonisJS v6 项目；搭建 Lucid 迁移 + Seeder（对齐 seed.js）；实现 auth + me 完整链路（JWT、中间件链、requestId、errorHandler、docker-compose）；mock_token 兼容层 | 3.1 / 3.2 / 3.4 / 3.6 |
| **Sprint 3**（业务端点） | 3 周 | 将全部现有路由移植到 AdonisJS Controller + Service + VineJS Validator；应用层租户隔离守卫；Japa 契约测试基线（auth/tenant/fence/alert） | 3.3 / 3.5 / 3.7 |
| **Sprint 4**（测试与容器化） | 3 周 | 租户隔离 Japa 测试全覆盖；审计日志落库；CI 基线（lint → typecheck → `node ace test` → docker build）；`/api/v1/health` + `/api/v1/readiness`；优雅关停 | 3.7 / 3.8 / M2 / M3 |
| **Sprint 5**（P1 起步） | 2 周 | OpenAPI（`adonis-autoswagger`）+ `@adonisjs/limiter` 限流 + Sentry + prom-client 指标 + Grafana 看板 | 3.5 / 3.6 / 3.9 |
| **Sprint 6+** | — | 对象存储、实时推送（`@adonisjs/transmit`）、IoT 网关、多租户扩展 | 3.10+ |

---

## 7. 验收标准

### P0 完成定义

- [ ] mobile_app `APP_MODE=mock` 下完成看板/地图/告警/围栏/租户/我的/孪生全路径，作为前端主开发回归基线。
- [ ] mobile_app `APP_MODE=live` 下至少打通 auth/me + tenant + fence + alert 核心链路，无 401/500。
- [ ] 服务重启后数据保留（Postgres 已持久化 seed）。
- [ ] 跨租户访问自动返回 404 或 403（不泄露存在性）。
- [ ] 所有写操作在 `audit_logs` 留痕，含 `requestId`、`actorId`、`tenantId`。
- [ ] CI 中 Japa 契约测试（`node ace test`）100% 通过；新增端点必须先补契约测试。

### P1 完成定义

- [ ] OpenAPI 文档发布到 `/api/docs`，前端可据此生成 SDK。
- [ ] 关键端点 P95 延迟 < 300ms；登录 P99 < 1s。
- [ ] Sentry 接入，错误可定位到 requestId + 堆栈。
- [ ] 至少一次完整的 DB 备份与恢复演练。

---

## 8. 风险与迁移建议

| 风险 | 缓解 |
|------|------|
| mobile_app 字段破坏性变更 | 所有契约变更先发公告，前后端并行实现 1 周过渡期；禁止静默改名 |
| JWT 切换期签名机制不一致 | 后端同时支持 `mock-token-*`（仅 dev 环境）与 JWT，生产环境强制 JWT |
| Lucid 迁移失败 | 迁移前自动备份 Postgres；`node ace migration:run` 走 CI 守护；回滚用 `node ace migration:rollback` |
| 租户隔离漏洞 | `base_service.ts` 基类强制注入 + CI 中"跨租户读写被拒"Japa 测试作门禁 |
| Refresh Token 泄露 | 设置旋转策略（每次 refresh 换新 token）+ 绑定设备指纹 |
| 内存 seed 与持久化数据双轨 | P0 完成后立即删除 `data/seed.js` 中的可变导出，改为一次性 `node ace db:seed` |

---

**需求版本**：v1.2
**更新日期**：2026-04-23
**变更说明**：在 v1.1 基础上补充 **Mock-First 双轨策略**：明确 `APP_MODE=mock` 持续可用、`APP_MODE=live` 按链路灰度接入；完善 JWT/mock-token 过渡、API `/api`→`/api/v1` 兼容策略、租户隔离 CI 门禁与双模式回归要求。
**来源**：mobile_app + backend 现状审计，配合 API 契约 v1.0
