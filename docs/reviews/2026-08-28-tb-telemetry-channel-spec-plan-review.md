# TB 遥测直连通道 spec/plan 评审意见（NIX-179 Phase 1）

> **评审对象**：
> - `docs/superpowers/specs/2026-08-28-tb-telemetry-channel-design.md`（Status: 评审修订，待整改验证）
> - `docs/superpowers/plans/2026-08-28-tb-telemetry-channel-plan.md`
> **评审日期**：2026-08-28 · **方法**：16 项事实断言逐条对照代码库（子代理核查 + 主评审抽验）+ Linear NIX-179 现状核对
> **评审基线**：分支 `nix/tb-telemetry-channel` 当前 HEAD（迁移已至 V20260828130000）

---

## 一、核心结论

**❌ 需返修（文档侧整体返工 + 代码侧一个真实缺口开单）——但设计骨架值得保留。**

最关键的发现不是任何单条错误，而是**文档与代码的时序错位**：spec/plan 按「待实施设计」的口径写作，但 TB 通道在当前分支上**已基本实现**——`TbClient`、`TbTelemetryChannel`、`TbTelemetryFrameParser`、`TbDeviceBinding` 全套、迁移 V20260828110000/120000/130000、三个测试类俱在；Linear NIX-179 已 In Progress 且附《Phase 1 dev 验证记录（2026-08-28）》附件。文档没有回填实现后的现实，导致**五处核心断言与代码不符**，其中两处是验收前提级错误（P1-F1 重放吸收、P1-F3 告警门控），会直接误导 Phase 2/3 设计与后续维护者。

建议将文档定位从「待实施设计」改为「实现对齐版」：先按本评审 §四 整改事实错误，再补一节「实现差异记录」，然后才是 NIX-179 的收尾验证。

---

## 二、事实核查总表（16 项）

| # | spec/plan 断言 | 判定 | 证据（文件:行） |
|---|---------------|------|----------------|
| 1 | 通道层：Dispatcher 5min 扫 platform_device_id → TelemetrySyncJob → blade report-record/page → toReadings | ⚠️ 大体属实但**「内部 RocketMQ → Worker」一跳已废弃**（`agentic-platform.sync.use-rocketmq=true` 才激活且无人发消息；现路径 Dispatcher:100-106 有界线程池直调，类注释说明因积压移除 MQ） | AgenticPlatformSyncDispatcher.java:67,95,100-106；AgenticPlatformSyncWorker.java:27 |
| 2 | 入库层：ingest 四参单事务含快照+五时序表+告警+游标；GPS 特例异步 | ⚠️ 四参签名属实（:72）；GPS outbox→Scheduler 属实；**「单事务」不成立**：temperature/rumen_motility/activity 经 SpringEventPublisher→RocketMQ `telemetry-received`→HealthApplicationService **异步独立事务**写入；**anomaly_scores 无活跃写入方**（assess() 被注释） | TelemetryIngestionService.java:72,132-135；SpringEventPublisher.java:54-58；HealthApplicationService.java:112-119 |
| 3 | TelemetrySource 现有四值，本次新增 THINGSBOARD | ❌ **已含 THINGSBOARD 共五值**（实现先行） | TelemetrySource.java:6-17 |
| 4 | 「告警评估仅对 AGENTIC_PLATFORM 来源触发」 | ⚠️ **仅设备告警（tamper/低电量）属实**（TelemetryIngestionService:115-117）；**围栏告警来源无关**（GpsLogEventConsumer:60-65 仅排除 MANUAL_IMPORT，THINGSBOARD 照常触发 FENCE_BREACH/APPROACH）；AI 异常告警全来源停用 | TelemetryIngestionService.java:115-117；GpsLogEventConsumer.java:60-65,114-133 |
| 5 | 崩溃重放由 (device_id, report_time/recorded_at) 唯一约束吸收 | ❌ **四张时序表均为按月分区、PK (id, 时间列)、无 (device_id, time) 唯一约束**；唯一约束仅 GPS 两表（uq_gps_logs_device_recorded_at 等）；temperature 另有应用层 existsBy 去重；**motility/activity/device_telemetry_logs 无任何去重** | V20260709120000:56；V20:18,51,84；V20260720120000:32；HealthApplicationService.java:146-148 |
| 6 | TLV fallback 覆盖 capsule；tracker 无 fallback 按失败帧处理 | ✅ decodeHexFallback 非 CAPSULE 返回 null（TbTelemetryFrameParser:125-133）；blade 侧同样仅 capsule | TbTelemetryFrameParser.java:125-133 |
| 7 | 加速度转换 + GPS clamp 沿用 | ✅（clamp 细节：\|值\|≥1000 置 null 防 DECIMAL 溢出 + ingest 层 \|lat\|>90 丢弃，spec 措辞略粗但方向正确） | AgenticPlatformReportData.java:131-150；TbTelemetryChannel.java:125-134 |
| 8 | stepNumber 累计→增量在 ingest 内 | ✅ computeStepDelta（ingest:108-109,156-176） | TelemetryIngestionService.java:156-176 |
| 9 | 迁移命名 V20260828110000__… | ⚠️ 符合近期时间戳式惯例——**但该文件已存在**（连同 120000/130000），plan Task 1 将其描述为待建 | db/migration/V2026082811* |
| 10 | `smartlivestock.tb.*` 配置前缀 | ✅ 已落地 application.yml:94-104（8 键）绑 TbProperties，无冲突；且**全部键有真实消费者**（对照 parking NIX-170 死配置教训，此项过关） | application.yml:94-104；TbProperties.java:9 |
| 11 | scripts/deploy.sh dev | ✅ | scripts/deploy.sh:5,12 |
| 12 | devices 表游标/标识字段 | ✅/⚠️ platform_device_id（partial unique + 软删重建）、last_telemetry_synced_at ✅；EUI 字段实名 **dev_eui VARCHAR(16)**（spec 绑定表 device_eui VARCHAR(32)，无碍但不一致）；「lastActiveTime 预检」是 **blade 远端字段**非本地列（本地近似 last_online_at 语义不同） | V20260709120000:13,21,23-24；V3:16-17 |
| 13 | 非 ACTIVE 设备 ingest 抛 STATE_CONFLICT | ✅（ingest:80-83；TB 通道先自查 ACTIVE 且逐帧 STATE_CONFLICT fail-open） | TelemetryIngestionService.java:80-83 |
| 14 | Phase 3 需 tenant-scoped 查询（TenantContext 可复用） | ✅ shared/tenant/TenantContext（ThreadLocal）在库 | shared/tenant/TenantContext.java:9 |
| 15 | Dispatcher 经 RocketMQ 派发 | ⚠️ 同第 1 条——MQ 桥在但该跳已退场；Spring→MQ 桥仍服务于 telemetry-received/GPS 事件 | SpringEventPublisher.java:54-58 |
| 16 | （评审推论）blade-exclusion=true 的设备「完全没有告警评估」 | ❌ 不成立：围栏告警照常触发；**真正丢失的是设备告警 tamper/低电量**（详见 P1-F3） | 同第 4 条 |

---

## 三、发现项

### P1（验收前提级 / 数据正确性）

**F1｜重放吸收断言失实——at-least-once 重放将产生重复行**
spec §4.2-6 与 §5.3 两处声称「崩溃重放允许，重复由 (device_id, report_time)/(device_id, recorded_at) 唯一约束吸收」。实测：temperature/rumen_motility/activity/device_telemetry_logs 四表**均无该唯一约束**（按月分区表，PK 含 id），唯一约束只在 GPS 两表；temperature 有应用层 existsBy 去重，**其余三表连应用层去重都没有**。游标保存滞后于 ingest 的崩溃窗口真实存在（ingest:132-135），一旦发生，三表写重复行且无兜底。
这正是 smart-parking 审计 NIX-174（B3-F2 去重竞态）同类问题——那边靠唯一索引+异常归类吸收，这边连索引都不存在。
**整改方向**：① 分区表补 (device_id, recorded_at) 唯一索引（按月分区内唯一即可，需评估分区键组合）或 ② temperature 的 existsBy 模式推广到其余三表，或 ③ 显式接受重复并在 spec 标注「重放可能产生少量重复时序行，下游聚合幂等」。三选一，写入 spec §5.3 并补回归。

**F2｜spec §3「现有架构基线」三处失实，已丧失基线资格**
① 「内部 RocketMQ → Worker」派发跳已被移除（积压原因改线程池直调）；② 「单事务入库」不成立（三张时序表异步独立事务）；③ anomaly_scores 写入是死路径（assess() 注释，任何来源都不产 AI 告警）。spec 作为「现状基线 + 设计依据」，这三处会直接误导 Phase 2/3 的设计决策（例如 Phase 2 若依赖「单事务原子性」推游标语义即踩坑）。
**整改方向**：§3 重写为实际拓扑（Dispatcher→线程池直调；ingest 同事务面 vs MQ 异步面分开画）；「入库下游零改动」目标句需限定为「同事务面零改动，异步面经既有事件流自然承接」。

**F3｜告警门控前提失实 + blade-exclusion 的功能损失未决策**
spec §8 验收写「告警评估按现有设计仅对 AGENTIC_PLATFORM 来源触发，TB 来源暂不触发告警」——对围栏告警**不成立**（THINGSBOARD 照常触发 FENCE_BREACH/APPROACH）；而真正的损失被一笔带过：**blade-exclusion=true 路由到 TB 的设备将失去 tamper/低电量设备告警**（门控在 TelemetryIngestionService:115-117）。这不是理论风险：该开关存在的意义就是把设备切到 TB 单源。
**整改方向**：① 修正 §8 表述（区分三类告警路径）；② 显式决策：Phase 1 是否将设备告警门控放开到 THINGSBOARD 来源（一行条件的改动），或接受损失并写入 §9 风险 + blade-exclusion 文档标注「启用后设备告警停报」。

### P2（文档治理 / 一致性）

**F4｜normalizeSource 将 THINGSBOARD 归一为 UNKNOWN——「下游零改动」前提被实现打破**
HealthApplicationService:122-127 白名单四值，THINGSBOARD→"UNKNOWN"：时序表 source 审计值失真，temperature 的 (device_id, recorded_at, source) 去重键含 source，语义漂移。spec §2 目标 2「入库下游零改动」需修正，且应把 normalizeSource 白名单补 THINGSBOARD 列入整改（一行改动 + 回归）。

**F5｜文档定位与代码现状矛盾**
spec Status「待整改验证」、plan Task 1「新增枚举/建迁移」、Task 7「按 Task 1-6 修正实现」——全部描述的是**已存在的产物**。读者无法判断哪些是设计意图、哪些已落地。**整改**：文档头部改「实现对齐版（实现先行，本文回填）」，plan 各 Task 标注实际完成状态，Task 7 改为「验证收尾」口径。

**F6｜种子绑定环境耦合与一致性维护缺位**
① 迁移内种子含 TB **test 环境**的 deviceId UUID——TB 环境迁移/重建后种子失效，且 Flyway 不可重放；建议标注种子为 test-env-scoped，或改存 PENDING + 运行期 resolveDeviceId 晋级（三变体解析器本来就是干这个的）。② tb_device_bindings.device_eui VARCHAR(32) vs devices.dev_eui VARCHAR(16)，且无 FK/一致性维护说明（设备换 EUI/软删后绑定悬挂）；至少补「绑定有效性随 last_verified_at 周期校验」的说明（列已设计，语义未写）。

**F7｜binding_status 缺 CHECK 约束**
PENDING/RESOLVED/INVALID 三值仅靠应用层枚举，迁移未加 CHECK——正是 parking 审计 NIX-167（CHECK 值域）教训的直接适用场景。建议迁移补 `CHECK (binding_status IN (...))` 并纳入一致性脚本校验项。

**F8｜plan Task 7 引用的「P1/P2 评审项」无清单锚点**
「确认 P1/P2 评审项全部关闭」——上一轮评审项在哪记录、共几条、逐条关闭状态，plan 内无枚举无链接。若在 Linear 评论中也应回链。追溯断链，整改后评审者无法验证关闭完整性。

---

## 四、设计亮点（返修时保留）

1. **游标纪律**：连续成功前缀边界 + at-least-once 显式声明 + limit 截断收窄续拉「禁止推进游标丢尾部帧」——完整吸收了 parking NIX-80 D12 的教训。
2. **fail-open ≠ 故障回退的语义显式化**（§5.7/§5.8 + 评审修订结论 3）：把「隔离」与「回退」两个易混概念分开声明，并把「TB 故障期采集延迟」的后果写实——这是很多同类设计缺失的诚实度。
3. **同帧单次入库的 authoritative 判据**（decodeStatus=true 且映射非空才抑制 dataHex）+ TLV 覆盖面诚实标注（tracker 无 fallback 不装懂）。
4. **安全卫生**：凭据 env 注入不落库 + 「密码曾在会话暴露，上线前轮换」主动写入风险节。
5. **Phase 切分与「明确不做」清单**：canonical 去重推迟的触发条件（确有双源并存需求）、耳标不承诺、Phase 3 多租户前置条件（tenant-scoped 查询 + 显式 tenant-id 配置）都给出了可判定的边界。
6. **三变体解析防随机绑定**：多变体命中不同设备标 INVALID 而非猜测，与 parking 绑定仲裁同思路。

---

## 五、整改清单（按执行序）

| # | 动作 | 类型 | 关联 |
|---|------|------|------|
| 1 | spec §3 架构基线重写（MQ 跳移除 / 单事务面 vs 异步面 / anomaly 死路径） | 文档 | F2 |
| 2 | spec §5.3/§4.2-6 重放吸收方案三选一并落地（约束 or existsBy 推广 or 显式接受） | 代码+文档 | F1 |
| 3 | 设备告警门控决策：放开 THINGSBOARD 或风险标注 + exclusion 文档加注 | 决策+代码/文档 | F3 |
| 4 | normalizeSource 白名单补 THINGSBOARD + 回归 | 代码 | F4 |
| 5 | 文档定位改「实现对齐版」，plan 标注各 Task 实际状态，Task 7 改验证收尾口径 | 文档 | F5 |
| 6 | 种子环境耦合标注或改 PENDING 运行期晋级；绑定一致性说明补齐 | 文档（可选代码） | F6 |
| 7 | binding_status CHECK 迁移 + 一致性脚本校验项 | 代码 | F7 |
| 8 | plan Task 7 回链上一轮评审项清单 | 文档 | F8 |

建议 F1/F3/F4/F7 在 NIX-179 内闭环（属 Phase 1 验收完备性）；文档侧 1/5/6/8 随本轮修订完成。

---

## 六、证据索引

- 代码：TelemetrySource.java:6-17 · TelemetryIngestionService.java:72,80-83,100-103,108-109,115-117,132-135,156-176,266-278 · AgenticPlatformSyncDispatcher.java:53-62,67,82-88,95,100-106,118-134 · AgenticPlatformSyncWorker.java:27 · SpringEventPublisher.java:54-58 · HealthApplicationService.java:112-119,122-127,146-148 · GpsLogEventConsumer.java:60-65,114-133 · TbTelemetryFrameParser.java:56-67,125-133 · TbTelemetryChannel.java:64-67,118-134 · TbProperties.java:9 · application.yml:94-104 · AgenticPlatformReportData.java:73-76,131-150 · shared/tenant/TenantContext.java:9 · scripts/deploy.sh:5,12
- 迁移：V20260709120000:13,21,23-24,56 · V20:18,51,84 · V3:16-17 · V20260720120000:32 · V20260822200000:17 · V20260828100000/110000/120000/130000（已存在）
- Linear：NIX-179（In Progress，Parent NIX-142，附《Phase 1 dev 验证记录 2026-08-28》）
