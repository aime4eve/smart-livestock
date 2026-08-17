# 仿真控制管理界面（Datagen Admin Console）设计评审

| 字段 | 值 |
|---|---|
| 评审对象 | [2026-08-17-datagen-admin-console-design.md](../specs/2026-08-17-datagen-admin-console-design.md) |
| 配套原型 | [datagen-console-prototype.html](../../marketing/datagen-console-prototype.html) |
| 评审日期 | 2026-08-17 |
| 评审人 | opencode Agent |
| 结论 | **有条件通过** — 需先处理 P0（旧端点权限边界）与 P1（两处迁移细节）后方可进入 plan 阶段 |

---

## 评审总结

方案整体质量高：farm 级开关（D5）与全局 scenario 解耦的设计正确，数据来源追踪（source 透传 + `UNKNOWN` 保守策略）完全契合项目经验判据 #11（多写源必带 source 标记），清理安全护栏（先停后清 + confirmText + 审计）闭环完整，原型与 spec 的设计令牌、交互细节高度一致。

但存在 **1 个权限边界漏洞（P0）** 和 **3 个 P1 工程细节**：spec 对现有 `DataGenAdminController` 授权现状的描述与实际不符（当前无任何 `@PreAuthorize`），类级加 `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')` 后 B2B 管理员可通过**旧全局端点**启停全局 scenario 影响所有租户，直接违背目标 2 与 D5/D6 的隔离承诺；另外 `alerts.source` 的 CHECK 约束重建与 `audit_logs` 缺少 farm/role 列两个迁移细节 spec 未定义。

**按严重度排列的发现**：

| 级别 | 编号 | 标题 |
|---|---|---|
| P0 | F1 | 旧全局端点权限边界未定义 + spec 对现状描述不实 |
| P1 | F2 | `alerts.source` CHECK 约束重建未处理，且取值域与新增列不一致 |
| P1 | F3 | `audit_logs` 无 farm_id/role 列，操作记录按 farm 过滤与角色展示缺 schema 支撑 |
| P1 | F4 | 清理条件"当前活跃安装"→ 已解绑设备的 DATAGEN 数据成为清理黑洞 |
| P1 | F5 | 初始化迁移 `enabled` 初始值与全局 scenario 状态未明确 |
| P2 | F6 | 派生数据宇宙未穷举（estrus_scores / anomaly_scores / track_points） |
| P2 | F7 | 清理预览新鲜度与 `unattributableHealthRows` 语义未定义 |
| P2 | F8 | 控制台前端未声明是否继承 FarmScopedNotifier |
| P3 | F9 | §5.3"控制器仍使用 @PreAuthorize"表述与现状不符 |
| P3 | F10 | `--surface-muted` 令牌原型与 spec 描述不一致 |
| P3 | F11 | "今日仿真数据"统计时区口径未定义 |
| P3 | F12 | 新表索引建议缺失 |

---

## P0 — 阻塞项

### F1：旧全局端点权限边界未定义 + spec 对现状描述不实

**位置**：§5.3（"控制器仍使用 `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")`"）、D4

**问题**：现状描述不实。当前 `DataGenAdminController.java:19-21` **没有任何 `@PreAuthorize` 注解**。全局 `SecurityConfig.java:44-54` 只做 URL 级 `authenticated()`，未按角色区分 `/api/v1/admin/**`；`@EnableMethodSecurity` 不会拦截未注解方法。因此当前 `/api/v1/admin/datagen/**` 对**任意登录角色（含 owner/worker）开放**——这本身是现网安全漏洞，spec 未承认该现状。

关键风险在授权方案落地后：按 spec 在类级加 `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')`，会同时放行 B2B_ADMIN 访问**旧端点**：

- `POST /api/v1/admin/datagen/scenarios/{id}/start|stop` —— 直接切换**全局** scenario 状态
- `POST /scenarios`、`GET /scenarios`、`GET /labels`、`GET /evaluation`

其中 start/stop 一旦被某 B2B 管理员调用，可停止整个 NORMAL 场景，**全租户仿真停止**——直接违背 D5/D6 与目标 2（"避免一个 B2B 管理员影响其他租户"）。新 farm-control 端点再怎么按 farm 隔离，旧端点都会绕过。

**建议**：spec 新增一节"旧 datagen 端点处置"，明确：

- 现状：`DataGenAdminController` 无方法级授权，需在本次一并收紧
- 旧端点（scenarios 增删启停 / labels / evaluation）降级为**仅 PLATFORM_ADMIN**，或随新控制台上线后下线
- 新 farm-control 端点类级 `hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')` + service 层 farm→tenant 校验（与 spec §7.1 一致）
- 测试计划 §8 后端第 1 组补一条：B2B_ADMIN 调用旧 `start/stop` 返回 403

---

## P1 — 高优先级

### F2：`alerts.source` CHECK 约束重建未处理，且取值域与新增列不一致

**位置**：§5.4"新增来源"

**问题**：`V40__add_ai_anomaly_integration.sql:38-39` 已定义：

```sql
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS source VARCHAR(16) NOT NULL DEFAULT 'RULE';
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source CHECK (source IN ('RULE','AI'));
```

spec 只写"alerts.source 增加 `DATAGEN`"，未提 **`chk_alerts_source` 必须 DROP 重建**（PostgreSQL 不支持 ALTER CONSTRAINT 改取值集）。不重建则 `INSERT alerts.source='DATAGEN'` 直接违反约束。

另需澄清取值域不一致：新增健康列枚举为 `AGENTIC_PLATFORM/DATAGEN/HTTP/MANUAL_IMPORT/UNKNOWN`，而 alerts 既有域为 `RULE/AI`。重建后 alerts 允许值应为 `RULE/AI/DATAGEN`（两套域），spec 应显式区分，避免实现时误写同一枚举。

**建议**：§5.4 补充迁移写法（仿 `V20260722100000` 的 DROP+ADD 模式）：`ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_source; ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source CHECK (source IN ('RULE','AI','DATAGEN'));`，并注明 alerts 与健康表取值域不同。

### F3：`audit_logs` 无 farm_id/role 列，操作记录按 farm 过滤与角色展示缺 schema 支撑

**位置**：§5.6（"写入现有 audit_logs。控制台'操作记录'从 audit logs 读取"）、§4.1 tab 4、§6.4 操作记录

**问题**：`V18__create_audit_logs_table.sql:2-12` 的 `audit_logs` 只有 `tenant_id / user_id / action / details JSONB / occurred_at`，**没有 farm_id，也没有角色列**。而控制台操作记录要求"按牧场过滤"且每行展示"操作者角色、时间、牧场、结果"。未定义实现路径。

**建议**：二选一并写入 spec：

1. `ALTER TABLE audit_logs ADD COLUMN farm_id BIGINT; ADD COLUMN operator_role VARCHAR(20);` + `idx_audit_logs_farm_occurred(farm_id, occurred_at DESC)`（推荐，查询直接）；
2. 或依赖 `details` JSONB 存 farmId/role，用 GIN 索引 `details @> '{"farmId":1}'` 过滤——可行但查询与索引更绕。

另注意 `event_type VARCHAR(100)`，`DatagenControlChangedEvent` / `DatagenDataClearedEvent` 均放得下，无需改。

### F4：清理条件"当前活跃安装"→ 已解绑设备的 DATAGEN 数据成为清理黑洞

**位置**：§5.5 清理范围表（"device 属于该 farm 当前活跃安装"）、§5.2

**问题**：清理与统计都依赖"当前活跃安装"回查 farm。仿真期间已生成数据、清理前已解绑/删除的设备，其 `source=DATAGEN` 的遥测/GPS/健康行**永远无法清理，且不显示在控制台预估里**——数据残留与"今日仿真数据量"口径不符。

**建议**：三选一，需 spec 明示：

1. 按 device→livestock→farm 的**持久关联**（不经"当前活跃安装"）做 farm 归属判定 + source 过滤（最彻底）；
2. 或显式声明这是安全取舍："仅清理当前仍安装设备的 DATAGEN 数据"，并接受历史残留；
3. 或 stats/preview 增加"不可清理的 DATAGEN 数据"提示，避免管理员误以为已清干净。

### F5：初始化迁移 `enabled` 初始值与全局 scenario 状态未明确

**位置**：§5.1（"初始化迁移会为已有活跃安装设备创建 control 记录，保持 test 当前演示行为不回退"）

**问题**：两条事实冲突未处理：

- `V38__create_datagen_tables.sql:36-38` 播种默认 NORMAL 场景为 `RUNNING`；
- `V20260710140000__cleanup_junk_gps_and_stop_datagen.sql:9` 已将**所有** scenario 置为 `STOPPED`。

当前 test 环境的真实状态是 datagen 全局停止。"保持 test 当前演示行为不回退"语义含糊——若初始 `enabled=true` 会在部署后意外恢复产数；若 `enabled=false` 且 scenario 非 RUNNING，控制台"启动"后仍不产数（需全局 NORMAL RUNNING 支撑）。而 F1 未处置前，旧端点可随时改动全局状态，spec 承诺的"全局 scenario 保持 RUNNING"无人兜底。

**建议**：spec 明确：(a) 初始化迁移 `enabled=false`（不自动产数）；(b) 默认 NORMAL scenario 的 RUNNING 状态由迁移保证并与 F1 的"旧端点仅 PLATFORM_ADMIN / 下线"联动，防止被 B2B 管理员改动；(c) 用一句话定义"test 演示行为不回退"指哪一层（设备范围保留 vs 产数状态）。

---

## P2 — 中等优先级

### F6：派生数据宇宙未穷举

**位置**：§5.5 不删除清单

**问题**：spec 列出"不删除"项含 `health_snapshots`、devices 运行时快照、UNKNOWN 历史数据、外部来源、schema/audit/ground truth，但**未提及以下表**的保留/处理策略：

- `estrus_scores`（发情评分，由体温/蠕动派生，DATAGEN 数据会触发）
- `anomaly_scores`（AI 异常分，按 livestock 聚合，无 source）
- `gps_quality_track_points`（`match_source=GPS_LOG` 由 gps_logs 配对派生）

其中 track_points 注释（`V20260722100000:35-36`）已声明"DataRetentionService 清理 gps_logs 时配对快照须存活"，因此 gps_logs 被清后 track_points 保留是**既有设计**，不算回归；但 estrus_scores / anomaly_scores 与 DATAGEN 的关系需显式声明（保留并自然过期，还是纳入清理），避免验收时发现"清理后发情评分还在"。

**建议**：§5.5 不删除清单补充三行（estrus_scores / anomaly_scores / gps_quality_track_points），说明保留理由，与既有 DataRetentionService 语义对齐。

### F7：清理预览新鲜度与 `unattributableHealthRows` 语义未定义

**位置**：§6.3（"清理必须重新调用 preview，不能沿用超过 30 秒的旧预估"）、§5.3 preview 响应、§5.4"存量数据原则"

**问题**：

- 30 秒新鲜度只是**前端交互约束**；后端 preview 与 delete 之间数据可能变化（runner tick 每 10s 产数、其他来源写入）。spec 已让 delete 返回实际删除量，够用，但应明示"以 delete 实际返回数为准，UI 展示该数而非 preview 数"。
- `unattributableHealthRows` 未定义语义：是"范围内 `source=UNKNOWN` 的健康行数"，还是"范围内 `source != DATAGEN` 的健康行总数"？两种口径会让管理员产生不同预期。

**建议**：明确定义 `unattributableHealthRows = 范围内该 farm 设备健康表中 source 为 UNKNOWN 的行数`（不包含 AGENTIC_PLATFORM/HTTP/MANUAL_IMPORT，它们不算"无法归属"），并注明 delete 响应以实际删除数覆盖。

### F8：控制台前端未声明是否继承 FarmScopedNotifier

**位置**：§6.2、§6.3

**问题**：本项目 AGENTS.md 有强制规则：使用 farm-scoped API 的 Controller 必须继承 `FarmScopedNotifier` 并在 build 开头 `watchActiveFarmId()`。Datagen 控制台用**显式 farmId 下拉 + query 参数**（`/console?farmId=1`），不走 `/farms/{activeFarmId}` 路径，理应**不**继承基类。但 spec 未显式声明，实施者可能误套基类，导致 activeFarmId 切换时页面被意外重建刷新。

**建议**：§6.3 补一行："本页面使用显式 farm 选择器，不走 farm-scoped API，不继承 `FarmScopedNotifier`（不依赖 activeFarmId）；如后续希望跟随顶部牧场切换，需单独决策。"

---

## P3 — 低优先级

### F9：§5.3"控制器仍使用 @PreAuthorize"表述与现状不符

**位置**：§5.3 顶部

**问题**：当前 `DataGenAdminController` 无此注解（见 F1）。"仍使用"会误导实施者跳过授权改造。

**建议**：改为"新 farm-control 端点使用 `@PreAuthorize("hasAnyRole('PLATFORM_ADMIN','B2B_ADMIN')")`（现控制器未加，需本次新增）"。

### F10：`--surface-muted` 令牌原型与 spec 描述不一致

**位置**：§6.5 令牌表 vs 原型 `:root`（`--surface-muted:#F2F0EA`）

**问题**：原型定义为实色 `#F2F0EA`；spec 表写成"surface 叠加低透明 primary/border"复合方案。Flutter 落地会出现两套理解，视觉可能漂移。

**建议**：统一为实色 `AppColors` 新 token（如 `surfaceMuted`），或在表格中给出确定的混色公式。

### F11："今日仿真数据"统计时区口径未定义

**位置**：§5.3 console stats（`todayTelemetryRows` 等）、§4.1 tab 1

**问题**：按 Asia/Shanghai 还是 UTC 切"今日"未定义。项目经验判据 #17 主张第三方时间直接存数值不换算，但这里是**聚合口径**，需显式统一（建议与既有统计一致，如 Asia/Shanghai，或标注 UTC）。

### F12：新表索引建议缺失

**位置**：§5.1 建表 DDL

**问题**：

- `datagen_control_devices` 只有 `uq_..._device (device_id)`，按 control 反向查设备（console 详情、runner 过滤）无索引，建议补 `idx_datagen_control_devices_control (control_id)`
- `datagen_farm_controls` 建议 `(tenant_id, farm_id)` 联合索引支撑 B2B 租户过滤
- `datagen_farm_controls.scenario_id` FK 建议配索引（runner 按 scenario 查询）

---

## 已核实正确的引用（无需修改）

以下 spec 论断经源码核实准确：

- `SynthesisService.java:43` 当前走 `deviceQueryPort.findActiveInstallations()`（全量活跃安装）✓
- `SynthesisRunner.java:23-39` 每 tick 遍历 RUNNING scenarios 调 `generate()`；`@ConditionalOnProperty("datagen.enabled")` ✓
- `TelemetryIngestionPortImpl.java:17-26` ingest 已透传 `TelemetrySource.DATAGEN` ✓
- `TelemetryReceivedEvent.java:16-43` **无 source 字段**；`TelemetryEventConsumer.java:64-65` 调 `processTelemetry(...)` 未传 source —— §5.4"链路变更"（事件加 source → 消费端透传）是真实新增工作，设计准确 ✓
- `gps_logs` / `device_telemetry_logs` 的 source 列及 CHECK `('AGENTIC_PLATFORM','DATAGEN','HTTP','MANUAL_IMPORT')` 存在于 `V20260729120000`（lesson #11 产物）✓
- `temperature_logs` / `rumen_motility_logs` / `activity_logs` 按月分区（`V20`），ADD COLUMN 可下推，清理按 recorded_at 分区裁剪可行 ✓
- `_PlatformAdminShell`（`main_shell.dart:220-233`）遥测导入之后为对账看板，仿真控制插两者之间与原型一致 ✓
- `_B2bAdminShell`（`main_shell.dart:352-357`）瓦片管理为末项，仿真控制置于其前与原型一致 ✓
- `app_router.dart:89-96` B2B 白名单当前仅 `/b2b/admin/*` 与 `/admin/tiles`，§6.1 需追加 `/admin/datagen` —— 计划正确 ✓
- `AppRoute` 枚举模式（`app_route.dart`）可容纳 `platformDatagen('/admin/datagen','platform-datagen','仿真控制')` ✓
- `alerts` 有 `farm_id`（Alert 模型构造含 farmId）✓
- 原型与 spec 交互一致性：4 段 tab、46×26 Switch、`确认词"清空"`、running 时清理禁用、preview 数字（3284/1842/812=5938）三处一致 ✓
- 权限模型：URL 层仅 `authenticated()`，角色控制全靠 `@PreAuthorize`（`SecurityConfig.java:44-54` + `@EnableMethodSecurity`）✓

---

## 设计亮点

1. **D5 farm 级开关与全局 scenario 解耦**：正确避免一个租户的启停操作影响他租户，是本次多租户隔离的核心正解。
2. **source 透传链设计完整**：事件加 source → 消费端透传 → 三张健康表落 source，且存量 `UNKNOWN` 采取"不猜测、不删除"保守策略，契合 lesson #11/#5 的经验判据。
3. **清理安全护栏闭环**：先停后清（D7）、preview→confirmText→事务删除、running 态拒绝、仅 DATAGEN——可逆操作无护栏、不可逆操作全护栏，分级正确。
4. **复用现有生成逻辑**：`SynthesisService` 的 TRACKER 5min / CAPSULE 15min 连续移动逻辑零改动，只换设备来源查询，回归风险低。
5. 原型 token 体系完整且与既有 `AppColors` 对齐，`prototype-to-flutter-fidelity` 可解析。

---

## 建议的后续行动

1. **[spec 修订] F1（P0）**：新增"旧 datagen 端点处置"小节，限定旧端点仅 PLATFORM_ADMIN 或下线；修正 §5.3 现状描述；测试计划补 B2B 调旧 start/stop 403 用例。
2. **[spec 修订] F2**：补 `alerts` 的 CHECK 重建迁移写法，明确 alerts 与健康表两套取值域。
3. **[spec 修订] F3**：`audit_logs` 增 farm_id/role 列（或 JSONB 方案）+ 索引，供操作记录 tab 使用。
4. **[spec 修订] F4**：清理归属判定策略三选一，明示"仅当前活跃安装"的取舍。
5. **[spec 修订] F5**：定义初始化 `enabled=false`、scenario 状态保证，消除"演示行为不回退"歧义。
6. **[spec 修订] F6-F12**：派生表清单、preview 语义、FarmScopedNotifier 声明、令牌、时区、索引等补全。
7. 修订完成并用户确认后进入 plan 阶段。
