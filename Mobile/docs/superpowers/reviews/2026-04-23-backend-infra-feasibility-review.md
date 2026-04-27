# 后端基础设施需求技术可落地性评审（联调 + AdonisJS v6）

**被审文档**：`Mobile/docs/2026-04-21-backend-infra-requirements.md`  
**评审范围**：仅评估技术可落地性（不评估时间、人力、预算）  
**评审对象**：`mobile_app` 与 `backend` 当前实现 + 目标 AdonisJS v6 方案  
**评审日期**：2026-04-23  

---

## 1. 评审方法与判定标准

### 1.1 判定标准

- **可落地**：现有实现与目标方案兼容，主要是工程迁移与实现工作。
- **有条件可落地**：方向可行，但存在明确技术断点，需先完成最小改造集。
- **当前不可落地**：现状与目标存在结构性冲突，不先改架构/协议无法稳定联调。

### 1.2 证据口径

- 前端证据：`mobile_app/lib/core/api/api_cache.dart`、`mobile_app/lib/main.dart`、`mobile_app/lib/app/session/*`、live repository 与租户/围栏页面调用链。
- 后端证据：`backend/server.js`、`backend/middleware/*.js`、`backend/routes/*.js`、`backend/data/*.js`。
- 契约证据：需求文档 `3.1~3.13` 目标条目。

---

## 2. 总体结论（双结论）

### 2.1 前后端联调可落地性：**有条件可落地（Mock-First）**

当前联调路径可跑通，且 `APP_MODE=mock` 已可支撑前端完整功能开发。  
目标方案要求 `Session 驱动 JWT/refresh + tenant scope`，与当前前端会话/请求头机制存在断点。  
只要先完成认证与会话桥接、版本路径兼容与最小租户隔离闭环，并保持 Mock 模式可持续回归，联调可落地。

### 2.2 后端 AdonisJS v6 基建与接口实现：**可落地**

当前 Express Mock 已具备清晰路由边界、权限码模式、统一包络和业务状态机（告警、围栏、租户）。  
迁移到 AdonisJS v6 的技术方向成立；主要风险是迁移质量（鉴权链、中间件链、持久化和测试门禁），非技术选型不可行。

---

## 3. 链路级评审（先链路，再章节映射）

## 3.1 认证与会话链路

**现状证据**
- 前端 `ApiCache` 通过 `_headers(role)` 固定注入 `Bearer mock-token-$role`。
- `main.dart` 在 live 模式启动时使用编译期 `API_ROLE` 调用 `ApiCache.instance.init(apiRole)`。
- `SessionController` 当前只保存 `DemoRole`，没有 access/refresh token 模型。
- 后端 `auth.js` 通过 `TOKEN_MAP` 映射三个固定 token，`auth/login` 仅返回 `{ token, role }`。

**目标要求**
- `3.1` 要求 JWT（RS256）+ refresh token 持久化 + `/auth/refresh` 与 `/auth/logout`。

**判定**：**有条件可落地**

**阻塞点**
- 前端认证上下文不携带 token 生命周期（只有 role）。
- 前端多处页面直接使用 `apiRoleFromEnvironment` 发写操作，绕过 session。

**最小改造**
1. 在 `AppSession` 增加 `accessToken/refreshToken/expiresAt`。
2. `ApiCache` 请求头改为从 session 读取 token；保留 dev mock-token 兼容层。
3. 前端所有新增远端写操作入口统一通过 session token；历史 `API_ROLE` 入口按链路灰度下线，不做一次性硬切。

---

## 3.2 租户与权限链路

**现状证据**
- 后端路由已通过 `requirePermission('tenant:*')`、`requirePermission('license:manage')` 控制权限。
- 但租户数据来自进程内 `tenantStore`，无 `tenant_id` 隔离边界。
- 前端租户模块 live repository 基于 `ApiCache.tenants` 拉取，尚未体现租户上下文。

**目标要求**
- `3.3` 要求非 ops 查询强制注入 `tenant_id`，并覆盖跨租户隔离测试。

**判定**：**有条件可落地**

**阻塞点**
- 当前权限是“角色权限”，不是“租户内权限”；数据层没有 tenant 过滤能力。

**最小改造**
1. AdonisJS service 基类强制 tenant scope（ops 走显式跨租户方法）。
2. 落地跨租户访问拒绝测试（tenant/animal/device/fence/alert）。
3. 前端 tenant 管理接口请求带上用户上下文，避免继续“全局数据视角”。

---

## 3.3 围栏写入链路

**现状证据**
- 前端围栏写入已具备 409/422 错误消息映射（`fenceSaveErrorMessageForStatusCode`）。
- 后端围栏路由已提供 CRUD 与参数校验（422/404），但数据仍在内存 store。
- 需求文档要求围栏引入 `version` 乐观锁。

**目标要求**
- `3.2`、`3.5` 中持久化 + 校验 + 并发保护。

**判定**：**有条件可落地**

**阻塞点**
- 当前 PUT 未体现版本冲突检测逻辑；重启丢数据。

**最小改造**
1. `fences` 表落地 `version` 字段并在更新时做版本校验。
2. API 契约返回统一冲突码（409）与当前前端错误提示语义对齐。
3. 前端提交围栏更新时传 `version`，成功后刷新缓存。

---

## 3.4 告警状态机链路

**现状证据**
- 后端单条状态迁移 `pending -> acknowledged -> handled -> archived` 已实现并在非法跳转时返回 409。
- 批量接口 `POST /alerts/batch-handle` 校验存在分支语义不一致（`action` 与判断分支耦合问题）。

**目标要求**
- `3.7` 要求契约测试覆盖成功和典型错误路径。

**判定**：**有条件可落地**

**阻塞点**
- 批量操作行为不稳定会直接影响联调可靠性。

**最小改造**
1. 先修复 batch-handle 分支一致性（P0 前完成）。
2. 补齐告警相关 HTTP 契约测试（单条 + 批量 + 冲突场景）。

---

## 3.5 孪生与设备读链路

**现状证据**
- 前端 `ApiCache.init()` 启动时并发预拉 dashboard/map/alerts/fences/tenants/profile/twin/devices 多端点。
- live repositories 读取缓存，未初始化时 fallback 到 mock repository。
- 后端已有对应路由实现（`/twin/*`, `/devices`）。

**目标要求**
- 与 `3.2` 持久化、`3.4` 请求链路、`3.6` 可观测性衔接。

**判定**：**可落地**

**风险点（非阻塞）**
- 大规模数据时启动全量预拉会放大冷启动成本；后续可改“按页面懒加载 + 局部缓存”。

---

## 3.6 后端基础设施与运行链路（AdonisJS v6）

**现状证据**
- 当前 `server.js` 为单文件装配：CORS、JSON、envelope、路由注册、404 fallback。
- `envelope` 已有统一响应结构，但 requestId 为服务端每次生成，不读取 `X-Request-Id`。
- 无持久化、无全局异常收口、无 HTTP 级测试门禁、无容器化编排。

**目标要求**
- `3.2`~`3.8`：Postgres 持久化、中间件链、异常处理、日志、测试、Docker。

**判定**：**可落地**

**关键前提**
- 需要完整替换为 AdonisJS v6 项目骨架，不能在现有 Express 单文件上增量拼接。

---

## 4. 与需求文档 3.1~3.13 的映射判定

| 条目 | 判定 | 结论摘要 |
|---|---|---|
| 3.1 认证与授权 | 有条件可落地 | 后端可实现 JWT；前端需从 `API_ROLE/mock-token` 迁移到 session token，并保留 dev 兼容过渡 |
| 3.2 数据持久化 | 可落地 | 迁移到 Postgres + Lucid 技术上直接可行 |
| 3.3 租户隔离 | 有条件可落地 | 方向正确；需先形成 tenant scope 最小闭环并补隔离测试 |
| 3.4 请求链路中间件 | 可落地 | AdonisJS 中间件机制天然匹配目标；需补 requestId 透传 |
| 3.5 参数校验与契约 | 可落地 | VineJS 可承接；关键是覆盖必须端点与错误码一致性 |
| 3.6 可观测性 | 可落地 | pino/Sentry 在 Node 生态可直接落地 |
| 3.7 测试基础设施 | 有条件可落地 | 需要从数据层测试升级到 HTTP 契约测试门禁 |
| 3.8 CI/CD | 可落地 | GitHub Actions + Docker 流程可直接建设 |
| 3.9 限流与熔断 | 可落地 | P1 引入 `@adonisjs/limiter` 合理 |
| 3.10 文件与对象存储 | 可落地 | 预签名上传方案与当前架构兼容 |
| 3.11 实时通信 | 可落地 | SSE/WS 可在 AdonisJS 生态推进 |
| 3.12 多租户扩展 | 可落地 | schema/RLS 可作为 P2 演进路径 |
| 3.13 数据导入导出与 IoT | 可落地 | 与业务 API 解耦建设可行 |

---

## 5. 最小可落地整改集（按阻塞优先级）

## 5.1 P0-Blocker（不完成无法稳定联调）

1. **双模式基线**：明确 `APP_MODE=mock` 作为前端主开发回归基线，避免 Live 接入破坏已完成功能。
2. **认证桥接**：前端 session 持有 token，替代新增页面中的 `API_ROLE` 直连。
3. **双鉴权过渡**：后端 JWT guard + dev `mock-token` 兼容中间件并行。
4. **版本路径策略**：明确 `/api` 与 `/api/v1` 兼容/切换策略，避免前端整体中断。
5. **租户隔离闭环**：数据访问层强制 tenant 过滤，补跨租户拒绝测试。

## 5.2 P0-Critical（可跑但高风险）

1. requestId 透传：优先读 `X-Request-Id`，全链路回写与日志关联。
2. 全局异常处理收口：统一业务错误映射 + 500 兜底。
3. HTTP 契约测试门禁：auth/tenant/fence/alert 作为首批强制覆盖。
4. 修复 `alerts/batch-handle` 语义不一致问题。

## 5.3 P1+（不阻塞首轮联调）

1. Redis（限流/黑名单）  
2. OpenAPI 自动发布  
3. 指标与追踪（Prometheus/OpenTelemetry）  
4. 对象存储与预签名上传  

---

## 6. 联调切换建议（技术路径）

建议采用“Mock-First 双轨过渡，逐页替换”：

1. 后端先提供 JWT 登录与 `mock-token` dev 白名单并存；
2. 前端先改登录态与请求头来源（session token），不立即重构全部 repository；
3. 先打通 auth/me + tenant + fence + alert 主链路；
4. 孪生与设备保留缓存机制，后续再做懒加载优化；
5. 全部关键链路通过契约测试并完成双模式回归后，再移除历史 `API_ROLE` 与 mock-token 直连入口。

---

## 7. 最终评审结论

在不评估时间与人力的前提下，本需求文档对应的技术方案结论为：

- **前后端联调：有条件可落地**
- **AdonisJS v6 基建与接口实现：可落地**

当前不存在“技术栈不可行”问题。  
真正的落地成败取决于是否先完成双模式基线治理、认证桥接、tenant scope 闭环与 HTTP 契约测试门禁这四类关键改造。

---

**评审版本**：v1.1  
**更新说明**：与需求文档 v1.2 对齐，明确采用 Mock-First 双轨策略（Mock 持续可用、Live 灰度接入）。  
**评审人**：codex-agent

---

## 8. 双模式验收清单（执行门禁）

- [ ] `APP_MODE=mock` 下核心主流程可完整跑通（登录、看板、地图、告警、围栏、租户、我的、孪生）。
- [ ] `APP_MODE=live` 下已打通 auth/me + tenant + fence + alert 主链路，且无新增 401/500。
- [ ] 同一功能在 mock/live 下关键交互结果一致（状态流转、错误提示、权限边界）。
- [ ] CI 同时包含契约测试与跨租户隔离测试门禁，失败即阻断合并。
- [ ] 仅在双模式回归连续通过后，才允许移除历史 `API_ROLE` / `mock-token` 直连入口。
