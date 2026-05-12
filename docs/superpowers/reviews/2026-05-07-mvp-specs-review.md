# MVP 规格文档综合评审报告

> **评审日期**: 2026-05-07
> **评审范围**: 
> - `docs/superpowers/specs/2026-05-06-mvp-backend-design.md`（后端设计规格）
> - `docs/superpowers/specs/2026-05-07-multi-client-api-contract-design.md`（多端 API 契约）
> - 对照 Mobile/ 现有代码实现（Mock Server + Flutter）进行交叉验证
> 
> **代码基线**: Mobile/backend/ (Node.js Mock Server) + Mobile/mobile_app/ (Flutter)
> 
> **前提**: API 契约是 MVP Spring Boot 后端的目标态设计，Mock Server 是 Demo 阶段遗留实现。两文档之间、文档与代码之间的差异需要区分"需修正的设计冲突"与"正常的代际演进"。
> 
> **评审人**: Claude Code

---

## 一、评审概述

本次评审合并了三层对比：

1. **规格间对比** — 后端设计规格 vs API 契约，识别两文档之间的不一致
2. **规格 vs 代码对比** — 以 API 契约为目标基准，验证其设计合理性，并用现有代码中积累的领域知识发现遗漏
3. **代码验证** — 用 Mock Server 和 Flutter 的实际实现，为规格决策提供证据支持或质疑

**核心结论**: 两份规格文档共同构成了架构上高质量的 MVP 设计。Farm Scope 硬约束、三端隔离、充血模型、版本策略——这些核心设计经得起代码验证。主要问题集中在两个 P0 级冲突（code 类型、ID 类型）和若干需要对齐的细节。

---

## 二、阻断级问题 (P0)

### B1. 响应 code 字段类型冲突

这是贯穿两份规格文档和现有代码的核心不一致。

| 来源 | success code | error code |
|------|-------------|------------|
| 后端设计 §4.1 | `"OK"` (字符串) | `"AUTH_UNAUTHORIZED"` (字符串) |
| API 契约 §2.1 | `0` (数字) | `"VALIDATION_ERROR"` (字符串) |
| Mock Server envelope.js | `'OK'` (字符串) | `'AUTH_UNAUTHORIZED'` (字符串) |
| Flutter 所有校验 | `body['code'] == 'OK'` (字符串) | — |

契约存在两个问题：(1) 与另一份规格文档不一致；(2) 成功用数字 `0`、错误用字符串 `"VALIDATION_ERROR"`——同一字段两种类型，Dart `jsonDecode` 后需要用 `dynamic` 接收，且 Flutter 端 15+ 处 `code == 'OK'` 判断全部需要修改。

**建议**: 统一为**全字符串枚举**。成功用 `"OK"`，错误用 `"AUTH_TOKEN_EXPIRED"` 等。三份来源（后端设计、Mock Server、Flutter）已经事实对齐为字符串方案，契约应跟随现有共识。如果坚持数字方案，则错误码也必须全部数字化（如 `40101`），不能成功/失败两套类型。

### B2. ID 类型根本性冲突

| 来源 | ID 格式 |
|------|--------|
| 后端设计 §2 (全部 DDL) | `BIGSERIAL` (自增整数) |
| API 契约 §2.4 | `UUID v4` (字符串) |
| Mock Server | `tenant_001` 等前缀+序号字符串 |
| Flutter 端 | 所有模型用 `String` 存储 ID |

这是系统最根本的标识策略不一致。DB schema 用 BIGSERIAL 做主键，API 契约却声明对外暴露 UUID v4。代码视角的关键发现：Flutter 端所有 `id` 字段均为 `String` 类型，所以**无论后端用 BIGINT 还是 UUID，只需在 JSON 序列化时将 ID 转为字符串即可**，Flutter 端不需要改动。

三种可行方案：

- **方案 A — 全量 BIGSERIAL**: 实现简单，索引效率高，与 DB schema 和 Mock Server 惯例（整数语义的 ID）一致。Phase 1 单实例无需分布式 ID，内网部署无安全暴露顾虑。JSON 序列化时转为字符串。**推荐此方案**。
- **方案 B — 全量 UUID v4**: 分布式友好，不暴露数据规模。代价：全部 DDL 需改（主键 + 外键），PostgreSQL UUID 索引效率略低。
- **方案 C — 库内 BIGSERIAL + 对外 public_id UUID**: 额外维护一列 `public_id`，Mapper 层复杂度增加，JWT `sub` 用哪个 ID 需明确。

---

## 三、高优先级问题 (P1)

### H1. 设备 API 路径不一致

| 来源 | 设备端点路径 |
|------|------------|
| 后端设计 §4.5 | `/api/v1/devices`（租户级，通过 JWT `tid` 隔离） |
| API 契约 §3.4 | `/farms/{farmId}/devices`（牧场级） |
| Mock Server 实际 | `GET /api/v1/devices`（无 farm 前缀） |
| Flutter 实际 | `ApiCache` 调用 `/devices?pageSize=200`（无 farm 前缀） |

后端设计将 Device 划在 IoT Context，通过 JWT 中的 `tid` 做租户隔离，URL 不体现 farm。API 契约将设备挂到牧场路径下。**契约做法更符合 Farm Scope 硬约束**——设备从属于牧场，路径即权限。代码证据也支持这一方向：Flutter 端的设备页面展示的是牧场级别的设备列表。

**建议**: 后端设计统一为 `/farms/{farmId}/devices`。

### H2. GPS 数据写入通道冲突

| 来源 | GPS 写入方式 |
|------|------------|
| 后端设计 §4.5 | `POST /api/v1/devices/{id}/gps-logs`（REST 端点） |
| API 契约 §3.4 | MQTT → RocketMQ 管道，不经过 REST |
| Mock Server 实际 | 无 GPS 写入端点（数据全为预置种子） |

契约的方案更合理（量产 IoT 终端不调 REST API）。但 Phase 1 如果没有 MQTT 链路，GPS 模拟数据的注入入口必须在规格中成文——不管是保留 REST 端点标注 Phase 1 测试专用 + `@Deprecated` + `Sunset`，还是走 RocketMQ 的 test producer。

**建议**: 二选一写明主路径。若保留 REST 端点，标注 `@Deprecated` + Phase 3 移除。若走 MQ，需在部署架构中补充 test producer 的启动方式。

### H3. 后端设计缺少 Admin 和 Open API 端点

后端设计 §4 完全没有 `/api/v1/admin/` 和 `/api/v1/open/` 路由前缀，所有端点都挂在 `/api/v1/` 下。API 契约引入了 21 个 Admin 端点和 11 个 Open 端点，形成三端隔离架构。

Mock Server 同样将所有端点混合在 `/api/v1/` 下（Admin 功能如租户管理、合同、分润与 App 功能如围栏、告警共享同一路由空间），仅靠 `requirePermission` 中间件区分角色。这在 Demo 阶段可接受，但生产环境需要契约的分离设计。

**建议**: 后端设计 §4 需要补充 Admin 和 Open API 端点表，反映三端隔离架构。

### H4. device_licenses 的农场归属问题

- 后端设计: `device_licenses` 表通过 `tenant_id` 归属租户
- API 契约: 端点放在 `/farms/{farmId}/device-licenses` 下
- Mock Server: 许可证管理在 `POST /tenants/:id/license`（租户级）

许可证是商业授权（租户级概念），不应挂在农场路径下。许可证的生命周期（激活/过期/撤销）与具体农场无关。代码实践也支持这一判断——Mock Server 将许可证操作放在租户端点。

**建议**: 将 device-licenses 端点移到租户级路径（`/device-licenses`，通过 JWT `tid` 隐式隔离），或保持 `/farms/{farmId}/` 路径但后端仅用 farmId 做归属校验、实际 CRUD 在 tenant 级别。

### H5. 端点数量统计对齐

| 来源 | App 端点 | Admin 端点 | Open 端点 | 合计 |
|------|---------|-----------|----------|------|
| 后端设计 §4 | ~35（未精确统计） | 0（未设计） | 0（未设计） | ~35 |
| API 契约 §3-5 | 49 | 21 | 11 | 81 |
| Mock Server 实际 | — | — | — | ~75（但属于 Phase 2a 功能集） |

后端设计 §4 自身已声明为"草案，待独立 API 契约设计完成后替换"。应以 API 契约为清单真源，将 81 个端点回填/替换后端设计 §4。

### H6. 设备模型缺少运行时状态维度

Mock Server 和 Flutter 的设备状态为 `online/offline/lowBattery`（运行时状态），契约定义的 `INVENTORY → ACTIVE → OFFLINE → DECOMMISSIONED` 是生命周期状态。两者是互补维度，不是替代关系。

Flutter 的 `DeviceItem` 模型包含 `batteryPercent`、`signalStrength`、`lastSync` 等运行时字段，在 Demo 中已被验证为必需展示信息。

**建议**: 在契约 Device 模型中增加 `runtime_status`（online/offline/low_battery），与生命周期 `status` 字段互补。DB schema 中已有 `battery_level`、`last_online_at` 字段支持此维度。

---

## 四、中优先级问题 (P2)

### M1. 洋葱架构的实施复杂度

后端设计 §3.2 采用严格的 port/adapter 模式——每个聚合根有 domain model、JPA entity、mapper、repository interface、repository impl 五层文件。11 张表 × 5 = 约 55 个文件仅用于持久层。

**可选简化**: 评估 Spring Data JDBC（天然支持聚合根，`CrudRepository` 返回 domain object，省去 entity 和 mapper 层）。或 domain model 直接加 JPA 注解（牺牲理论纯度换速度），Phase 2 再分离。是否采纳取决于团队对 DDD 严格度的偏好。

Flutter 端的对应实践值得参考：Repository 接口在 `domain/`，Mock/Live 实现直接在 `data/` 目录下，不设独立的 entity 和 mapper 层——三层足够清晰。

### M2. RocketMQ 运维复杂度

Phase 1 仅使用 1 个 Topic（`gps-log-updated`），为它引入完整的 RocketMQ 集群过重。替代方案：

- Spring Application Events + `@Async` — 同进程异步，Phase 1 够用
- RabbitMQ — 比 RocketMQ 轻量，Docker 单容器即可
- 保持 RocketMQ（如果团队已有运维经验）

### M3. 软删除策略不统一

| 实体 | 删除策略 | 来源 |
|------|---------|------|
| 牧场 (Farm) | `status=deleted` | 后端设计 §4.6 |
| 牲畜 (Livestock) | `status=removed` | API 契约 §3.3 |
| 告警 (Alert) | 状态机 `archived`（是否等价于删除？） | 两文档一致 |

**建议**: 统一软删除字段。所有实体用 `is_deleted` boolean + `deleted_at` timestamp，或统一用 `status` 字段的 `deleted`/`removed` 值。Alert 的 `archived` 状态与软删除的关系需要明确。

### M4. 缺少 health check 端点

两份文档都没有定义 `/health` 或 `/actuator/health` 端点。Mock Server 同样没有此端点。Docker Compose + Nginx 部署需要存活检测。

### M5. API 鉴权细节缺失

- **跨上下文 livestock_id 校验**: `installations` 表通过 `livestock_id` 跨上下文引用 Ranch，安装时校验 livestock 是否存在——如果 livestock 已被软删除，安装是否允许？
- **级联删除规则**: 删除 Farm 时，关联的 livestock/fences/alerts 如何处理？后端设计 §4.6 说"如有依赖数据则拒绝删除"，但未定义"依赖数据"边界。
- **批量操作原子性**: `POST /alerts/batch-handle` 全部成功或全部失败，还是部分成功？

### M6. CORS 配置缺失

Flutter 移动端直连不涉及 CORS，但 Vue 3 PC 端从浏览器访问 Spring Boot 需要 CORS 配置。Mock Server 当前用 `cors()` 无参数全放行，生产环境不可接受。应在部署架构（后端设计 §5.3）中补充 Nginx 的 CORS 头配置或 Spring Security 的 CORS 策略。

### M7. 牧场切换机制未在契约中明确

Mock Server 有 `GET /farm/my-farms` 和 `POST /farm/switch-farm` 两个端点，Flutter 的 `FarmSwitcherController` 依赖它们实现多牧场切换。

API 契约中有 `GET /farms`（我的农场列表），但没有明确的牧场切换机制。Farm Scope 规则提到了 `x-active-farm` header 的兼容和废弃——隐含的设计是客户端通过设置 header 切换牧场。

**建议**: 在契约中明确说明：用户从 `/farms` 列表中选择目标农场后，客户端存储 farmId，后续读请求通过 `x-active-farm` header 传递（Phase 1），或直接使用 `/farms/{farmId}/...` 路径（推荐）。

### M8. 分页措辞不准确

契约 §2.2 描述为"统一使用 offset 分页"，但参数 `page`/`pageSize` 是页码式语义。Mock Server 和 Flutter 均按页码式理解和使用。**该改的是文档描述措辞**（改为"统一使用页码式分页"），参数名本身没问题。对于 gps_logs 等时序数据，可考虑 cursor-based 分页。

---

## 五、低优先级问题 (P3)

### L1. 坐标格式不一致

| 来源 | 格式 |
|------|------|
| 数据库 livestock 表 | `latitude`, `longitude`（分离列，纬前经后） |
| 数据库 fences.vertices | JSONB `[{lat, lng}, ...]`（纬度在前） |
| API 契约 §2.4 | `{ lng, lat }`（经度在前） |

GeoJSON 标准是 `[lng, lat]`（经度在前）。DB 中 fence vertices 用了 `{lat, lng}`，与 API 约定的 `{lng, lat}` 不一致。

**建议**: 统一为 GeoJSON 顺序 `[lng, lat]`。

### L2. JWT refresh token 存储未说明

API 契约提到 refreshToken 轮换（旧 token 立即失效），但未说明存储位置。Redis 中的 `jwt:blacklist` key pattern 存的是 accessToken 还是 refreshToken？建议明确：Redis 存 refreshToken 白名单/黑名单，accessToken 短有效期（1h）不存。

### L3. 日志与追踪

两份文档都没有涉及：结构化日志格式（JSON/文本）、requestId 生成与传播规则（前端传入还是后端生成？Mock Server 取 `X-Request-Id` header 或自动生成）、日志级别策略。

### L4. 数据库连接池

Docker Compose 单机部署场景下 HikariCP 默认 pool size=10 通常够用，建议在部署文档中标注。

### L5. 枚举值大小写风格

契约 §2.4 规定枚举为"小写 snake_case"（如 `device_tracker`）。但 DB schema CHECK 约束用了大写（`'SAMPLE'/'BATCH'`、`'公'/'母'`）、Mock Server 用短名（`gps`）、Flutter 用 camelCase（`DeviceType.gps`）。API 返回小写、DB 存大写——Mapper 层需要转换。

**建议**: 统一为小写 snake_case（DB 也小写），减少转换成本。Mock Server 和 Flutter 的枚举值在 Spring Boot 实现时自然对齐到契约。

### L6. 设备类型枚举命名

契约用 `device_tracker`/`capsule`/`accelerometer`；Mock Server 用 `gps`/`rumenCapsule`/`accelerometer`。契约命名更规范，建议保留。部署时通过 Mapper 层处理与旧数据的兼容。

### L7. PC 前端技术栈变更波及面

后端设计 §技术路线变更说明 提到 PC 前端从 Angular 切换为 Vue 3。当前 `PC/frontend/` 是 Angular 19 完整实现（含 Leaflet 地图、Chart.js）。CLAUDE.md 已声明"PC/ 目录暂不维护"。Vue 3 重写成本未在任一文档中预估。

### L8. ApiHttpClient 接口不完整

Flutter 的 `ApiHttpClient` 抽象接口只定义了 `get()` 和 `post()`，但 `ApiCache` 中实际使用了 `http.put()` 和 `http.delete()`（绕过了接口直接调 `http` 包）。API 契约中大量使用 PUT 和 DELETE 方法，Spring Boot 实现前需要 Flutter 侧补齐接口。

### L9. `/profile` 端点的历史冗余

Mock Server 同时有 `GET /me` 和 `GET /profile`（返回相同数据），Flutter 端也同时调用两者。契约只需保留 `/me`，`/profile` 是历史冗余，无需纳入。

### L10. 预加载场景对后端的性能影响

Flutter 的 `ApiCache.init()` 在启动时并发请求 17 个端点。如果每个请求都需要 FarmScope 解析 + 权限校验，启动延迟会累积。虽不是 API 契约层面的问题，但后端实现时需注意 FarmScope 解析效率——缓存用户-农场关系，避免每个请求查 3 张表。

---

## 六、契约设计合理性验证（代码证据）

以下契约设计在 Mock Server/Flutter 代码中得到实际使用验证，确认设计正确：

| 契约设计 | 代码证据 | 结论 |
|---------|---------|------|
| **Farm Scope 硬约束** | Mock Server 的 header-only 方式存在安全漏洞（切换 header 可越权访问），契约的 path-based 方案是精确修正 | ✅ 契约更优 |
| **三端隔离架构** | Mock Server 将 Admin 和 App 端点混合，仅靠权限中间件区分——契约的路由级隔离是正确方向 | ✅ 契约更优 |
| **告警状态机** `pending→acknowledged→handled→archived` | Mock Server 完全一致实现，含 409 非法跳转；Flutter 按四阶段筛选告警 | ✅ 完全对齐 |
| **告警操作使用 POST**（非幂等） | Mock Server 一致 | ✅ 完全对齐 |
| **认证端点** `/auth/login`、`/auth/refresh`、`/auth/logout` | Mock Server 一致 | ✅ 完全对齐 |
| **分页参数** `page`/`pageSize` | Mock Server + Flutter 一致 | ✅ 完全对齐 |
| **Device-DeviceLicense 分离** | Mock Server 通过 `POST /tenants/:id/license` 间接体现许可证是独立概念 | ✅ 方向正确 |
| **`x-active-farm` 兼容+废弃计划** | Mock Server 当前依赖它；契约的过渡策略务实合理 | ✅ 过渡方案合理 |
| **Open API 速率限制 + Idempotency-Key** | Mock Server 已实现类似机制 | ✅ 保留 |
| **JWT payload** `{ sub, tid, role, iat, exp }` | Mock Server mockTokenService 模拟类似结构 | ✅ 结构合理 |
| **API Key 格式** `sl_live_`/`sl_test_` | Mock Server 用 `sl_apikey_`——契约更规范 | ✅ 契约更优 |

---

## 七、亮点

1. **Farm Scope 硬约束** — 写操作仅路径、读操作二选一、双来源 422 拒绝。解决了 Mock Server header-only 方式的安全漏洞和隐式依赖问题
2. **三端隔离架构** — 路由空间、认证方式、演进节奏三层独立，比 Mock Server 的混合路由模式清晰得多
3. **Device-DeviceLicense 分离** — 物理设备和商业授权不同生命周期，DDD 聚合设计的正确示范
4. **充血模型示例** — Alert 状态机、Device 激活规则内聚在聚合根中，符合 DDD 核心原则
5. **TDD 测试分层** — 领域模型纯 JUnit → 应用层 Testcontainers → API 层 MockMvc，层次清晰
6. **API 版本策略** — 破坏性/非破坏性变更定义明确，废弃流程有 Sunset 机制
7. **跨上下文引用务实折中** — `installations.livestock_id` 不用 FK，应用层保证一致性，避免跨上下文 DB 耦合
8. **Idempotency-Key**（Open API）— 对第三方开发者的关键保障
9. **告警状态机端到端一致** — 从规格到 Mock Server 到 Flutter UI，四阶段筛选完全对齐

---

## 八、迁移路径

### 8.1 并行开发策略

```
Mock Server (冻结) ── 继续服务 Demo 演示
Spring Boot ──────── 按修正后的契约实现 Phase 1 端点
Flutter ──────────── mock 模式继续用 DemoSeed，live 模式逐步对接 Spring Boot
```

Flutter 的 mock/live 双模式架构天然支持这种并行开发。

### 8.2 Mock Server 的角色

Mock Server 建议**不改造**。它当前服务的是 Phase 2a Demo（数字孪生 + 订阅 + B2B），强行改造到 Phase 1 核心底座会破坏现有 Demo。它更适合作为 Phase 2 的参考实现和 Demo 演示工具。

### 8.3 Flutter 端需要的关键变更

| 变更项 | 影响范围 | 复杂度 |
|--------|---------|--------|
| 所有 API URL 加入 `/farms/{farmId}/` 前缀 | ApiCache + 各 Live Repository，约 30 处 | 中 |
| `ApiHttpClient` 补全 PUT/DELETE 方法 | `api_http_client.dart` | 小 |
| code 字段类型 | 若契约改为字符串则无需变更 | 无 |
| 设备模型增加生命周期状态字段 | `DeviceItem`、API 解析层 | 小 |
| 新增牲畜 CRUD 的 Live Repository | `features/livestock/` | 中（新功能） |
| 新增 GPS 日志、安装记录功能 | 新模块 | 中 |
| 牧场切换机制对齐契约 | `FarmSwitcherController` | 小 |

---

## 九、变更优先级汇总

| 优先级 | 编号 | 问题 | 建议动作 | 影响文档 |
|--------|------|------|---------|---------|
| **P0** | B1 | code 字段类型冲突 | 统一为全字符串枚举 | API 契约 §2.1、后端设计 §4.1 |
| **P0** | B2 | ID 类型冲突 | 统一为 BIGSERIAL + JSON 序列化为字符串 | API 契约 §2.4、后端设计 §2 |
| **P0** | H3 | 后端设计缺少 Admin/Open 端点 | 补充端点表 | 后端设计 §4 |
| **P1** | H1 | 设备 API 路径不一致 | 统一为 `/farms/{farmId}/devices` | 后端设计 §4.5 |
| **P1** | H2 | GPS 写入通道冲突 | 二选一写明，标注 Phase 过渡策略 | 后端设计 §4.5、API 契约 §3.4 |
| **P1** | H4 | device_licenses 农场归属 | 确认许可证端点路径（租户级 vs 农场级） | API 契约 §3.4 |
| **P1** | H5 | 端点数量对齐 | 以 API 契约为真源回填后端设计 | 后端设计 §4 |
| **P1** | H6 | 设备缺少运行时状态 | Device 模型增加 `runtime_status` 字段 | API 契约 §3.4、后端设计 §2.3 |
| **P2** | M1 | 洋葱架构复杂度（可选） | 评估 Spring Data JDBC 替代 | 后端设计 §3 |
| **P2** | M2 | RocketMQ 过重 | 评估 Phase 1 用 Spring Events 替代 | 后端设计 §5 |
| **P2** | M3 | 软删除策略不统一 | 定义统一软删除字段和策略 | 两文档 |
| **P2** | M4 | 缺少 health check | 补充 `/health` 端点 | 两文档 |
| **P2** | M5 | API 鉴权细节缺失 | 明确跨上下文校验、级联删除、批量原子性 | 两文档 |
| **P2** | M6 | CORS 配置缺失 | 补充 Nginx/Spring Security CORS 策略 | 后端设计 §5.3 |
| **P2** | M7 | 牧场切换机制未明确 | 契约中说明切换流程 | API 契约 §2.5 |
| **P2** | M8 | 分页描述措辞 | "offset 分页" 改为 "页码式分页" | API 契约 §2.2 |
| **P3** | L1-L10 | 各低优先级改进 | 见上文各条目 | 视情况 |

---

## 十、总体评估

两份文档共同构成了**架构上高质量的 MVP 设计**——限界上下文划分合理、Farm Scope 约束精心设计、API 版本策略成熟、充血模型示例正确。

主要问题集中在三个层面：

1. **两文档之间的不一致**（B1 code 类型、B2 ID 类型、H1 设备路径、H2 GPS 通道）——需要两个关键决策后同步修改
2. **后端设计的覆盖范围不足**（H3 缺少 Admin/Open 端点、H5 端点数量不对齐）——需以 API 契约为真源补充
3. **实施层面的务实考量**（M1 架构复杂度、M2 RocketMQ、M3 软删除、H6 设备运行时状态）——不阻塞设计方向，但影响实施效率

**修正 P0 问题后的下一步**:
1. 确保两文档的 code 类型、ID 类型达成一致
2. 后端设计 §4 补充 Admin 和 Open API 端点表
3. 对齐设备 API 路径、GPS 写入通道、device_licenses 归属
4. 评估架构简化方案（M1/M2）
5. 进入编码阶段（按 `docs/superpowers/plans/2026-05-06-mvp-phase1-implementation.md` 执行）
