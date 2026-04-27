# 后端基础设施需求 — 评审报告

**被审文档**：`docs/2026-04-21-backend-infra-requirements.md` v1.0
**配套文档**：`docs/api-contracts/2026-04-21-backend-api-contract.md` v1.0、`docs/superpowers/specs/2026-04-20-tenant-management-design.md` v1.1
**评审日期**：2026-04-21
**评审依据**：后端代码现状审计（`Mobile/backend/`，22 文件，1,630 行）、前端 CLAUDE.md 技术路线、API 契约文档

---

## 综合评审结论：有条件通过

方案现状画像精准、阶段划分务实、技术选型合理，是一份质量较高的基础设施规划。但存在 **1 个方向性矛盾**、**2 个高风险项** 和 **7 个重要遗漏**，修订后方可进入实施。

**评分**：7.5 / 10

---

## 一、核心优点

| # | 优点 | 说明 |
|---|------|------|
| 1 | **现状画像精准** | 对内存 seed、mock token、无持久化、无鉴权等问题的梳理与实际代码高度吻合（后端仅 1,630 行、2 个 npm 依赖） |
| 2 | **P0/P1/P2 分层务实** | 先跑通再加固的思路正确，P0 聚焦"数据不丢 + 基础安全 + 可联调" |
| 3 | **租户隔离三层递进** | 应用层守卫 → ORM 中间件 → RLS，从易到难的防御纵深策略 |
| 4 | **兼容层设计** | mock-token 白名单（仅 dev 环境）+ 生产禁用的过渡方案，平滑衔接前后端 |
| 5 | **契约快照测试** | `toMatchSnapshot` 防字段漂移，对前后端联调至关重要 |
| 6 | **技术选型表清晰** | 每层都有推荐和备选，决策理由可追溯 |
| 7 | **迁移清单完整** | 10 张表的字段、主外键关系、JSONB 用法均已列出 |

---

## 二、严重问题（必须解决）

### S1. 技术栈方向性矛盾

**问题**：`Mobile/CLAUDE.md` 明确写有：

> MVP 后端 (待实现): **FastAPI + Python**

而基础设施文档推荐保留 **Express 5 + TypeScript**。两份文档对后端技术路线的指引完全相反。

**影响**：在未解决分歧之前，任何实施工作都可能造成返工。

**建议**：

- **推荐保留 Express + TS**：现有 Mock Server 已是 Node 生态（Express 5 + 10 个路由模块），迁移成本远低于用 Python 重写
- 更新 `Mobile/CLAUDE.md`，删除 "MVP 后端 (待实现): FastAPI + Python" 行，改为 "MVP 后端：Express 5 + TypeScript + Prisma + PostgreSQL"
- 同步更新根目录 `CLAUDE.md` 中对应描述

### S2. Sprint 时间线过于激进

**问题**：当前后端仅 1,630 行纯 JS，2 个 npm 依赖。文档中 Sprint 1（2 周）包含 "TS 迁移 + Express 中间件链 + 结构化日志 + 错误处理统一 + requestId 贯穿"，实质上是**从零构建新后端框架**，而非"迁移"。

**各 Sprint 工作量评估**：

| Sprint | 文档排期 | 实际范围 | 合理排期 |
|--------|----------|----------|----------|
| Sprint 1 | 2 周 | 重写 server.js + 全部 middleware + TS 配置 + 日志 + 错误处理 | 3-4 周 |
| Sprint 2 | 2 周 | 重写所有 routes/ + data/ 层为 Prisma + 迁移脚本 + 租户隔离 | 4 周 |
| Sprint 3 | 2 周 | JWT + Refresh Token + 前端接入 + 审计日志 | 3 周 |
| Sprint 4 | 2 周 | Zod 校验 + Supertest 测试 + CI + Docker | 3 周 |

**建议**：

- 合并 Sprint 1-2 为 **"基础框架迁移"（4 周）**，先跑通 auth + me 一个端点的完整 TS + Prisma + 测试链路，再铺开到全部端点
- Sprint 3 拆为 **"认证改造"（3 周）**，单独聚焦 JWT + 前端对接
- 总时间从 8 周调整为 **12 周**（约 3 个月）

### S3. Redis 在 P0 引入过早

**问题**：Redis 在 P0 仅用于 Refresh Token 存储和 session 缓存。对于 MVP 阶段、单实例部署的系统，增加了一个额外服务的运维负担。

**建议**：

- P0 阶段 Refresh Token 存储在 Postgres 的 `refresh_tokens` 表中，带 `expires_at` 字段，通过定时清理过期记录
- Redis 推迟到 P1 引入限流功能时再部署
- 相应调整 docker-compose.yml，P0 仅包含 `app + postgres`

---

## 三、重要遗漏（需补充到文档）

### M1. API 版本控制

**缺失**：无 URL 版本前缀或 Header 版本协商机制。

**风险**：第一版不加版本前缀成本极低，后期改造需修改所有端点路径和前端调用。

**建议**：P0 必须包含。路由注册改为 `app.use('/api/v1', v1Router)`，一行改动即可。前端 `API_BASE_URL` 相应改为 `http://127.0.0.1:3001/api/v1`。

### M2. 健康检查端点

**缺失**：无 `/health` 和 `/readiness` 端点。Docker 化和 K8s 部署均依赖这两个探针。

**建议**：P0 必须包含：

- `GET /health` → `{ status: "ok" }`（不鉴权，检查进程存活）
- `GET /readiness` → 检查 DB 连接 + 可选 Redis 连接，返回 `{ status: "ready", checks: { db: "ok" } }`

### M3. 优雅关停

**缺失**：无 SIGTERM/SIGINT 处理。进程被终止时 DB 连接、正在处理的请求可能被截断。

**建议**：P0 补充 graceful shutdown 逻辑：

```
SIGTERM → 停止接收新请求 → 等待现有请求完成 (max 10s) → 关闭 DB 连接池 → 退出
```

### M4. 事务管理

**缺失**：文档未提及事务边界。围栏创建、租户创建等操作涉及多表写入，需事务保证一致性。

**建议**：

- 在 Repository 层明确事务语义
- Prisma 支持 `prisma.$transaction()`，关键写操作必须用事务包裹：
  - 创建租户（tenants + audit_logs）
  - 批量告警处理（alerts + audit_logs）
  - 删除租户（tenants + animals/devices/fences 级联清理）

### M5. 连接池配置

**缺失**：未提及 Prisma 连接池参数。

**建议**：

- 在 `DATABASE_URL` 中配置 `connection_limit=10&pool_timeout=20`
- 或在 `schema.prisma` 中通过 `datasource` 的 `relationMode` 和连接参数配置
- 生产环境根据实例规格调整连接数上限

### M6. 数据初始化（Seed）

**缺失**：文档提到"迁移文件进 git"但未说明如何将现有 mock seed 数据导入 Postgres。这直接影响 `docker-compose up` 后是否能立即联调。

**建议**：

- 添加 `prisma/seed.ts`，将 `data/seed.js`（50 头牲畜、100 设备、18 告警、6 租户、4 围栏、30 头孪生数据）的结构一次性灌入 Postgres
- 在 `package.json` 中配置 `"prisma": { "seed": "ts-node prisma/seed.ts" }`
- Docker 化后通过 `docker-compose up` 自动执行 seed

### M7. 幂等性设计

**缺失**：写操作无幂等性保障。网络重试可能导致重复创建租户、重复处理告警。

**建议**：P1 阶段为关键写操作（创建租户、批量处理告警）支持 `Idempotency-Key` 请求头：

- 服务端基于 `idempotency_keys` 表去重
- 同一 Key 在 24 小时内返回首次执行结果
- 前端在写操作按钮点击时生成 UUID 作为 Key

---

## 四、设计改进建议

### D1. `licenseUsed` 聚合性能

**现状**：文档建议 `licenseUsed` 由 `animals` 按 `tenant_id` 聚合。

**风险**：租户列表页（可能 100+ 租户）每次查询都聚合 `animals` 表，在数据量增长后性能堪忧。

**建议**：

- P0：使用物化字段 `tenants.license_used`，在 animals 表 INSERT/DELETE 时触发更新
- P2：可改为物化视图或事件驱动更新

### D2. 分页策略

**现状**：仅提到 offset 分页（`page/pageSize`）。

**风险**：大数据量表深页查询（如 `page=1000`）性能随 offset 增大线性退化。

**建议**：

- P0 用 offset 够用（当前数据量小）
- 设计时预留 cursor-based 分页接口（`?cursor=xxx`），为 P2 做准备

### D3. 错误处理细节

**现状**：`errorHandler` 仅提"不泄露堆栈"，缺少错误分类。

**建议**：区分三类错误：

| 错误类型 | HTTP | 处理方式 |
|----------|------|----------|
| 已知业务错误（40x） | 400/401/403/404/409/422 | 返回具体 code + message |
| 未知异常 | 500 | 记录完整堆栈到日志，返回通用 "INTERNAL_ERROR" |
| Prisma 特有错误 | 自动映射 | 唯一约束冲突 → 409，外键约束 → 400，连接失败 → 503 |

### D4. `shared/repository/` 封装

**现状**：目录结构建议 `shared/repository/tenant-scoped Prisma 封装`，但未明确接口。

**建议**：明确为泛型基类模式：

```
shared/
├── base.repository.ts    # 泛型基类，CRUD 操作自动注入 tenant_id
├── errors.ts             # 统一业务异常（NotFound, Forbidden, Conflict, Validation）
└── logger.ts             # pino 封装，关联 requestId + tenantId
```

### D5. 环境变量管理

**现状**：仅列出变量名，未说明校验机制。

**建议**：

- 使用 Zod 定义 `envSchema`，启动时校验必要变量是否存在、格式是否正确
- 缺少关键变量时进程立即退出并打印明确错误信息
- 示例：`JWT_PRIVATE_KEY` 必须是 PEM 格式、`DATABASE_URL` 必须是有效 PostgreSQL 连接串

### D6. 告警批量操作 Bug 修复

**现状**：API 契约文档 §3.5 指出 `POST /alerts/batch-handle` 的 `action` 校验与分支判断不一致。

**建议**：此 Bug 应在 P0 前修复（当前 Mock Server 即可修复），不需要等 TS 迁移。修复成本极低（约 5 行代码）。

---

## 五、与现有系统的一致性检查

| 检查项 | 状态 | 说明 |
|--------|------|------|
| API 契约对齐 | ✅ | 端点定义与 API 契约文档一致 |
| 响应包络兼容 | ✅ | 保留 `{ code, message, requestId, data }` 格式 |
| 告警状态机 | ✅ | 四阶段迁移 + 409 冲突与现有实现一致 |
| 角色权限体系 | ✅ | 三角色 + permission 码与 `middleware/auth.js` 一致 |
| 租户管理 Phase 1 | ⚠️ | 基础设施文档要求租户 Phase 1 即实现审计日志，但租户设计文档 Phase 1 仅含基本 CRUD，需对齐 |
| 前端模式切换 | ✅ | mock-token 兼容层设计合理 |
| `npm test` 覆盖 | ⚠️ | `tenantStore.test.js` 未纳入 `npm test` 脚本，需修复 |
| 孪生模块 | ✅ | twin_seed.js 286 行数据完整，迁移清单中未遗漏 |

---

## 六、修订优先级总结

### 必须在实施前完成

| # | 项目 | 紧迫度 | 工作量 |
|---|------|--------|--------|
| S1 | 统一技术栈决策（Express+TS vs FastAPI+Python），更新所有文档 | 🔴 阻塞 | 0.5 天 |
| S2 | 调整 Sprint 时间线为 12 周，合并 Sprint 1-2 | 🔴 阻塞 | 0.5 天 |
| M1 | 添加 API 版本前缀 `/api/v1/` | 🔴 阻塞 | 0.5 天 |

### P0 实施时必须包含

| # | 项目 | 说明 |
|---|------|------|
| S3 | Redis 推迟到 P1 | P0 用 Postgres 存储 Refresh Token |
| M2 | 健康检查端点 `/health` + `/readiness` | Docker/K8s 探针依赖 |
| M3 | 优雅关停 SIGTERM 处理 | 防止数据丢失 |
| M4 | 事务管理 | Prisma `$transaction()` |
| M5 | 连接池配置 | Prisma `connection_limit` |
| M6 | `prisma/seed.ts` 数据初始化 | docker-compose 一键可用 |
| D6 | 告警 batch-handle Bug 修复 | 当前 Mock Server 即可修 |

### P1 实施时纳入

| # | 项目 | 说明 |
|---|------|------|
| M7 | 幂等性 Idempotency-Key | 关键写操作去重 |
| D1 | `licenseUsed` 物化字段 | 避免实时聚合 |
| D3 | Prisma 错误映射 | 自动转为业务错误码 |
| D5 | 环境变量 Zod 校验 | 启动时 fail-fast |

---

## 七、评审结论

这份方案展现了扎实的系统工程思维，现状分析和优先级分层是亮点。主要问题集中在：

1. **技术栈矛盾未决** — CLAUDE.md 与本文档对后端语言/框架的指引相反
2. **Sprint 排期过于乐观** — 1,630 行纯 JS Mock Server → TS + Prisma + 分层架构，8 周不够
3. **缺少运维基本能力** — 健康检查、优雅关停、API 版本控制

**建议**：解决 S1-S3 三个严重问题 + 补充 M1-M3 后，方案可进入实施阶段。

---

**评审版本**：v1.0
**评审日期**：2026-04-21
**评审人**：arch-reviewer
