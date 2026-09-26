# 牲畜位置与状态统一实时同步架构 Plan 评审意见

| 字段 | 值 |
|---|---|
| 评审对象 | 会话内 Plan 全文《牲畜位置与状态统一实时同步架构》（Phase 1 轮询 / Phase 2 Outbox / Phase 3 SSE） |
| 评审日期 | 2026-09-26 |
| 评审人 | Kimi Code Agent |
| 评审方式 | Plan 每条后端/前端假设对照实际代码核实（后端 `smart-livestock-server/`、前端 `Mobile/mobile_app/`），关键结论均落地到文件与行号 |
| 结论 | **有条件通过** — 架构方向（revision 增量同步 + 位置快照表 + Outbox + SSE 通知后 API 对账）是成熟正确的模式，与仓库已有的 `gps_ingestion_tasks` outbox 一脉相承；但 **3 项 P0 与代码事实直接冲突，按现状实施会直接做错或 Flyway 起不来**，另有一批 P1 定义缺口，修订后方可进入编码 |

---

## 评审总结

Plan 的总体设计判断是成立的：把"位置"与"状态"拆成两条独立 revision 主线、用快照表承载最新位置、前端统一 Signal Store、SSE 只做"通知"而权威数据仍走 API 对账——这些都是正确取舍。细节设计也有亮点：cursor 复合格式 `status:position`、freshness 四级分级、无定位不返回假坐标、请求失败保留旧数据只标 stale、Outbox 不作为权威状态、`FOR UPDATE SKIP LOCKED` 支持多实例。

但核实发现 Plan 有**三处与代码事实直接冲突的硬伤**（P0）：回填 SQL 引用了 `gps_logs` 不存在的列、Phase 2 迁移版本号与今天已存在的迁移撞号、"GPS 落库同事务更新快照"的挂点与现有异步 outbox 架构（AGENTS.md 硬性规则）冲突。此外有一批实施前必须澄清的定义缺口（P1）：`livestock.last_latitude/longitude` 与新快照表的双写权威问题、statusRevision 的写路径改造清单缺失、farm 行锁热点、5 秒承诺与 5 秒轮询周期的数学矛盾等。

**按严重度排列的发现**：

| 级别 | 编号 | 标题 |
|---|---|---|
| P0 | F1 | 回填 SQL 引用 `gps_logs.livestock_id / farm_id`，两列均不存在，迁移会直接报错 |
| P0 | F2 | Phase 2 迁移版本号 `V20260926100000` 与今天已存在的迁移撞号，Flyway 会拒绝启动 |
| P0 | F3 | "GPS 落库同事务更新快照"挂点与现有异步 outbox 架构冲突，违反 AGENTS.md 硬性规则 |
| P1 | F4 | 新快照表与 `livestock.last_latitude/last_longitude` 双写并存，权威归属未裁决 |
| P1 | F5 | statusRevision 递增涉及 6+ 个分散业务事务，Plan 未列写路径改造清单，遗漏即静默失效 |
| P1 | F6 | `farm_signal_revisions` 新牧场插入钩子缺失；farm 单行计数器存在行锁热点 |
| P1 | F7 | "最多 5 秒"承诺与"每 5 秒轮询一次"存在数学矛盾，DoD 不可验证 |
| P1 | F8 | cursor 过旧 / 超前 / 无效的处理未定义（首次 `0:0` 之外的边界） |
| P1 | F9 | 快照 `source` 词表与现有 CHECK 约束枚举不一致（`'UNKNOWN'`/`'DEVICE'` 均不在枚举内） |
| P1 | F10 | 前端地图现有围栏状态推导逻辑与 Signal Store 双源冲突，旧端点退役/共存策略缺失 |
| P1 | F11 | 状态聚合读取的服务归属未定义；`/signals/map` 无牲畜上限的性能口径缺失 |
| P2 | F12 | Flutter Web 端 SSE 无先例且有真实技术障碍，Phase 3 需要先做 spike |
| P2 | F13 | 越权（跨 farm）校验、`recorded_at` 时区纪律、已删牲畜行为等边角未定义 |
| P2 | F14 | Phase 1 体量过大（后端 6+ 写路径 + 聚合查询 + 前端整个 sync 层 + 两页改造），建议再拆 |
| P3 | F15 | 既有文案（帮助 FAQ"每 30 秒自动刷新"）与 30s 轮询旧代码需同步清理 |

---

## P0 — 阻断级（与代码事实冲突，按现状实施会做错）

### F1：回填 SQL 引用不存在的列

**位置**：Plan「Backend Data Model」第 4 条回填 SQL（`SELECT ... g.livestock_id, g.farm_id, ... g.source FROM gps_logs g WHERE g.livestock_id IS NOT NULL`）。

**代码事实**：`gps_logs` 建表于 `smart-livestock-server/src/main/resources/db/migration/V3__create_iot_tables.sql:57-66`，列只有 `id, device_id, latitude, longitude, accuracy, recorded_at, created_at`（`recorded_at` 后由 `V20260710160000__fix_gps_logs_timestamp_timezone.sql:4` 改为 TIMESTAMPTZ；`source` 由 `V20260729120000__nix79_manual_import_source.sql:7-11` 后加）。**没有 `livestock_id`，也没有 `farm_id`**。牲畜关联路径是 `gps_logs → devices → installations (removed_at IS NULL) → livestock`（`V3__create_iot_tables.sql:42-53`）。

**后果**：迁移在全新库直接报错，dev/test 部署即失败（经验 #20：迁移必须全新库跑通）。

**修订建议**：回填改为三表 JOIN，按 `devices → installations(removed_at IS NULL) → livestock` 解析 livestock_id 与 farm_id；注意同一 device 历史安装到不同牲畜时，严格讲应按 `recorded_at` 落在安装区间内解析，至少要用当前 active installation 并注明近似语义。

### F2：Phase 2 迁移版本号撞号

**位置**：Plan「Phase 2 Outbox Migration」`V20260926100000__create_signal_event_outbox.sql`。

**代码事实**：`smart-livestock-server/src/main/resources/db/migration/V20260926100000__epidemic_contact_workbench.sql` **已存在**（当前最新迁移）。Flyway 对同版本不同文件会直接报错拒绝启动；`application.yml:23-28` 的 `out-of-order: true` 只解决乱序，不解决撞号。

**修订建议**：Phase 1 用晚于 `V20260926100000` 的时间戳（同日更早版本虽有 out-of-order 兜底，但审计上易混淆）；Phase 2 另行取号。

### F3：「同事务」挂点与异步 GPS 架构冲突

**位置**：Plan「Backend Data Model」第 5 条——"GPS 位置在后端事务落库时同步更新 `livestock_location_snapshots`"、"更新动作与 GPS 写入在同一数据库事务"。

**代码事实**：GPS 写入是 **outbox 异步两段写**，不存在单一的"GPS 落库事务"：

1. `TelemetryIngestionService.ingest()`（`iot/application/TelemetryIngestionService.java:77-129`）主事务只写 `gps_ingestion_tasks`（`enqueueGps()`，`:323-358`）。AGENTS.md §2 硬性规则：**不要在 ingest 事务里重新直写 GPS**。
2. `GpsIngestionTaskScheduler`（`iot/application/GpsIngestionTaskScheduler.java:28-61`）每 500ms 轮询 → `GpsIngestionTaskProcessor`（独立事务）→ `GpsLogApplicationService.logGps()`（`iot/application/GpsLogApplicationService.java:24-36`）——**gps_logs 唯一写入口**。
3. livestock 维度的位置更新（`livestock.last_latitude/last_longitude`）在更下游：RocketMQ 消费者 `GpsLogEventConsumer.onMessage()`（`ranch/infrastructure/mq/GpsLogEventConsumer.java:47-141`，`:89-90` 调 `livestock.updatePosition()`），又是另一个异步事务。

**后果**：Plan 没有指明挂点，实施者只有两个现实选择，且各有代价，必须在 Plan 中裁决：

- **挂 `GpsLogApplicationService.logGps()`（iot 侧，与 gps_logs 同事务）**：满足"同事务"，但该层只有 device 维度，livestock/farm 需再查 active installation，引入 iot → ranch 的跨 context 读依赖。
- **挂 `GpsLogEventConsumer`（ranch 侧，有 livestock/farm 上下文）**：链路位置正确，但与 gps_logs 落库是两个事务，"同事务"承诺要改写成"最终一致、正常链路延迟 <1s"。

**修订建议**：推荐挂 `GpsLogEventConsumer`（与现有 `updatePosition()`、围栏越界判定同点，一处改动同时维护快照与 last_*），并在 Plan 中把"同事务"措辞改为与所选挂点一致的准确描述；同时复核"5 秒"预算在 ingest → 500ms 调度 → MQ 消费这条链路上的占用。

---

## P1 — 实施前必须澄清

### F4：快照表与 `livestock.last_*` 双写权威未裁决

`livestock.last_latitude/last_longitude/last_position_at` 已存在（`V2__create_ranch_tables.sql:16-18`），现有地图/总览的位置数据实际来自这条链（`GpsLogEventConsumer.java:89`）。新增 `livestock_location_snapshots` 后两套"最新位置"并存，Plan 未说明：谁是权威？旧字段是否下线？`RanchOverviewApplicationService.getOverview()`（`ranch/application/RanchOverviewApplicationService.java:55-224`）和 `MapController`（`ranch/interfaces/MapController.java:29-54`）是否改读快照表？不裁决必然数据漂移。

### F5：statusRevision 写路径改造清单缺失

状态源分散在 6+ 个独立事务中：`AlertApplicationService`、`HealthApplicationService`（`health/application/service/HealthApplicationService.java:117,901,915`）、`HealthAnomalyService`（`:68,73` 为 `REQUIRES_NEW`，同事务递增需特别处理）、`GpsLogEventConsumer`（围栏）、`DeviceApplicationService` / `InstallationApplicationService`、`LivestockApplicationService`、`FenceApplicationService` 等。Plan 只列了"哪些变化算状态变化"，没有列出**要在哪些类的哪些事务点插入 revision 递增**的改造清单，也没有"任一写路径遗漏即前端静默不更新"的回归防护（建议每个写路径配一条集成测试断言 revision 递增）。工作量被显著低估。

### F6：`farm_signal_revisions` 生命周期与并发

- 迁移只回填存量 farms；**新建牧场的插入钩子缺失**——新 farm 无 revision 行，Signal API 行为未定义（报错？懒创建？）。
- farm 单行计数器在高频 GPS 下是行锁热点：每条新位置都 `position_revision += 1`，同牧场多设备并发上报会在该行串行化。需写明并发策略（原子 `UPDATE ... SET position_revision = position_revision + 1 RETURNING`，避免先读后写），并评估对 ingest 吞吐的影响。

### F7：「最多 5 秒」与「5 秒轮询」数学矛盾

轮询周期 5 秒意味着平均延迟 2.5s、最坏延迟 = 5s（周期）+ 后端链路（ingest→500ms 调度→MQ→快照）+ 对齐抖动，**最坏必然超过 5 秒**。DoD 第 3/4 条"最多 5 秒刷新"不可验证。修订方向二选一：缩短轮询周期（如 3s）为链路留出预算；或把 DoD 改为"轮询周期 ≤5s，端到端 P95 ≤ X 秒"的可测量口径。Phase 3 的 SSE 才能真正满足"最多 5 秒"。

### F8：cursor 边界未定义

Plan 只定义了首次 `cursor=0:0&includeGeometry=true` 和"相同 cursor 返回 changed=false"。未定义：cursor 远旧于当前（前端休眠数小时后）是否返回全量位置/状态；cursor 超前（缓存错乱）；`livestockIds` 含已删除牲畜；`livestockIds` 为空串 / 超 200 个时的错误码。这些边界不定，前后端会各自猜测实现。

### F9：快照 `source` 词表不一致

`gps_logs.source` 有 CHECK 约束，枚举为 `AGENTIC_PLATFORM/THINGSBOARD/DATAGEN/HTTP/MANUAL_IMPORT`（`V20260828120000__tb_source_in_check_constraints.sql:9-12`，VARCHAR(20)）。Plan 回填用 `COALESCE(g.source, 'UNKNOWN')`，而 `gps_logs.source` 是 NOT NULL 无空值；响应示例又出现 `"source": "DEVICE"`——`'UNKNOWN'` 和 `'DEVICE'` 都不在枚举内。需定义快照 `source` 的合法词表并与现有枚举对齐。

### F10：前端双源冲突与旧端点策略

- 地图围栏状态现状是前端自行推导：`ranch_page.dart:154-188` 先由 ACTIVE 告警建 `fenceStatusMap`，再用 `fencePolygonContainsLatLng` 做 GPS-围栏包含补判。Plan 说"围栏预警状态来自 Signal Store"，但未声明**删除还是保留**这套前端推导——并存即双源不一致。
- 地图现有 30s `Timer.periodic` 轮询（`ranch_page.dart:70-75`）、`MapController` 的 `/map` 与 `/map/overview`（其中 `alertCount` 硬编码为 0，`MapController.java:44`）、前端 `ranch-overview` 数据源（`ranch_api_repository.dart:9-12`）的退役/共存策略均未提。Signal API 的 `alerts.activeCount/unreadCount` 正好填 alertCount 假数据这个坑，应明确写入 Plan。
- 合规提醒：`signal_sync_controller` 使用 farm-scoped API，按 AGENTS.md §5 必须继承 `FarmScopedNotifier/FarmScopedAsyncNotifier`（`lib/core/api/farm_scoped_controller.dart:11-26`）并在 `build()` 首行 `watchActiveFarmId()`；生命周期感知轮询有现成先例 `lib/core/widgets/auto_refresh_listener.dart:15-79` 可复用。

### F11：聚合读取归属与 map 端点性能口径

- 健康/AI/围栏/设备/告警五域目前无统一查询服务，最接近的是 `RanchOverviewApplicationService` 的应用层 join。Plan 未指定 Signal 聚合读落在哪个 context（建议 ranch 或新建 signal 模块，明确复用/抽取现有聚合逻辑）。
- `/signals/livestock` 限 200 头，但 `/signals/map` 的 `livestockSignals`/`positionUpdates` 无上限说明；大牧场（数千头）每次 changed 全量返回的报文大小与序列化成本需给出口径。

---

## P2 — 应在 Plan 修订中补充

### F12：Flutter Web 端 SSE 技术风险

前端当前零 SSE/WebSocket 先例（pubspec 无相关依赖，`package:http` 在 Web 平台对流式响应支持受限，EventSource 需借助 `dart:html`/`package:web` 或引入新依赖）。Phase 3 的 ticket + SSE 设计本身合理（ticket 绑定用户/租户/牧场、heartbeat、Last-Event-ID、多标签上限都对），但**应在 Phase 3 启动前先做一个最小 spike 验证 Flutter Web 的 SSE 收流方案**，否则推送层可能卡住、退化为长期轮询。

### F13：边角语义

- 越权：`/signals/*` 需走现有鉴权与 farm 归属校验，Plan 只提了未登录 401，未提跨 farm 越权用例。
- `recorded_at` 已是 TIMESTAMPTZ；按经验 #17，第三方时间字段直接用原始数值不换算，前后端都不做 `toUtc()`——freshness 的 `ageSeconds` 计算应写明遵守此纪律。
- 已删牲畜：快照 `ON DELETE CASCADE` 已覆盖位置；`livestockIds` 请求含已删 id 时的行为（忽略还是报错）未定义。

### F14：Phase 1 体量过大

Phase 1 实际包含：2 张表 + 回填、6+ 写路径 revision 改造、五域状态聚合读、2 个新端点、前端整个 `lib/core/sync/` 层、牲畜卡片多徽标、地图数据源切换、13 个 i18n key、Playwright 验证。建议拆为 1a（后端表 + 端点 + 最小前端联调）与 1b（前端 Signal Store + 两页切换 + 保真验证），降低单次合并风险。Worktree 分阶段策略本身合理，保持。

---

## P3 — 顺手项

### F15：旧轮询与文案清理

牧场页 30s 轮询（`ranch_page.dart:70-75`）、帮助 FAQ"列表每 30 秒自动刷新"（`app_zh.arb` 约 :480 行）等既有表述需在切换后同步更新，避免文档与行为漂移。

---

## 修订后放行条件

1. F1 回填 SQL 改为 `devices → installations → livestock` 的正确 JOIN 并在全新库验证。
2. F2/F3 迁移取号与"同事务"挂点裁决写入 Plan。
3. F4 裁决快照表与 `livestock.last_*` 的权威关系。
4. F5 给出 statusRevision 写路径改造清单 + 每条路径的 revision 递增测试要求。
5. F7 把"5 秒"改为可测量口径。
6. F8/F9/F10/F11 的边界与策略逐项补入 Plan。

以上 6 条落实后，Plan 可进入编码阶段（按 AGENTS.md §3，编码本身仍需用户批准）。
