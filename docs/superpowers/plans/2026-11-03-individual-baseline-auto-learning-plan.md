# 实施计划：健康个体体温基线自动学习

- 日期：2026-11-04
- 状态：已获用户批准执行（用户指令"执行计划"，2026-11-04）
- 需求正本：`docs/superpowers/requirements/2026-11-03-individual-baseline-auto-learning.md`
- 评审依据：知识库 `10-Projects/02-smart-livestock/2026-11-03-个体体温基线自动学习任务评审.md`
- 执行方式：按 AGENTS §3 逐 Task 串行推进，每个 Task 先过验证步骤再进下一个；主智能体评审产物后放行。
- 分支：`feature/individual-baseline-auto-learning`（自 `master@d8239eaba`）

## 0. Context 与验收边界

当前健康快照固定 38.50℃ 基线（`HealthSnapshotJpaRepository.ensureSnapshotExists`），发情评分读取最近温度日志中最老一条的 `baselineTemp`（`HealthApplicationService.calculateTempDelta`），个体差异成为评分噪声。本任务交付**可追溯、可回滚**的个体基线学习机制与 dev 方法验证。

**本期完成**：默认 10 天（7–14 可配置）事件时间滑动窗；安静态样本准入（疾病/发热/饮水/离体/来源排除）；加权均值与波动带；DEFAULT/LEARNED 冷启动；发情评分切换有效基线并留存审计；fever 详情 API 透出；管理端手动重算与只读 A/B 评估；dev 造态验证与回滚演练。

**明确不做**：不改 `EstrusAnalysisService` 阈值分档；不实现 CalvingPredictionService；不改对外文案/15 小时口径；不部署 test/86/223；不做昼夜分层与多胶囊校准；**不把 DATAGEN/SYNTHETIC/告警数量变化称为真实效果**。

**验收对照表（需求原文 → 本计划落点）**

| 需求验收要点 | 本期落点 | 状态口径 |
|---|---|---|
| 学习后基线 vs 兽医手工校准值偏差（试点真实数据） | 不在本期；机制实现 + dev 造态方法验证 | 待试点真实数据 |
| 发情评分误报率对比（默认 vs 学习基线） | 本期交付**同输入机制对比**（基线/tempDelta/总分/≥70 分评分点/告警 episode 数量，只读 A/B 端点）；真实误报率需独立人工负例标签 | 机制对比完成；真实 FPR/FNR 待试点 |
| 存量快照默认基线行为不变，学习只增不改历史 | 迁移只加列；历史温度日志/评分零回改；回归测试锁定 | 本期关闭 |
| 真库集成测试（经验 #19）+ dev 端到端冒烟 | Journey 测试（远程 Testcontainers）+ dev 造态 curl 冒烟 + 回滚演练 | 本期关闭 |

## 1. 核心实现契约

### 1.1 事件时间、来源与更新时机
- 窗口统一按 `recorded_at`：`[asOf − windowDays, asOf)`；到达时间只用于调度触发，不参与窗口界定。
- 生产学习仅接受来源白名单（默认 `AGENTIC_PLATFORM,THINGSBOARD,HTTP,MANUAL_IMPORT`，可配置）；`DATAGEN`、`UNKNOWN` 不参与。
- 当前遥测先按既有基线完成健康评估（快照/告警/发情）；学习在独立调度事务执行，**新基线只影响后续日志与评分，不回改历史**。
- 学习样本按 `(device_id, recorded_at, source)` 逻辑去重；不给存量分区表补唯一索引（避免历史重复行炸迁移，教训 #20 同族）。

### 1.2 样本准入（顺序执行，记录排除原因）
1. 生理合理范围（35–43℃，复用 `MIN/MAX_PLAUSIBLE_TEMP` 语义）＋来源白名单；离体/环境读数剔除。
2. 人工 `ILLNESS/RECOVERY` 疾病窗口排除（`physiology_events`）。
3. 发热排除分两态：
   - **DEFAULT 冷启动**：不得用默认 38.5℃ 基线产生的 `TEMPERATURE_ABNORMAL` 告警一票否决；仅人工疾病窗口＋稳健离群过滤兜底。
   - **已 LEARNED**：用**学习前的冻结基线**计算 delta，排除 ELEVATED/FEVER/CRITICAL 样本、活跃告警窗口及退热缓冲（复用 `feverWindowsForLivestock` 的缓冲语义）。
4. 饮水排除：`drinking_events` 区间 ＋ 恢复窗（谷底≠恢复结束，Cantor 2018：恢复可 ~103min；恢复窗取 120min）；夜批未识别的近期温谷由 median/MAD 稳健过滤兜底。
5. 活动判据：仅当窗口内存在有效 `activityIndex` 时启用"低活动"筛选（低于该个体近期中位数）；**活动缺失 ≠ 零活动**，回退夜间样本（牧场→租户→平台时区链，`TenantZoneResolver`；禁用 UTC/服务器时区/固定上海时区）。一帧多温度点与帧尾单活动记录按 ±15min 容差关联。

### 1.3 统计、加权与冷启动
- 候选样本先 median/MAD 稳健去离群（MAD=0 时用最小波动阈值 0.05℃ 兜底，不误删全部样本）。
- 按牧场本地日分组；日合格条件：≥`min-samples-per-day`（默认 2）个准入样本。合格日 ≥`min-qualified-days`（默认 7）才允许 DEFAULT→LEARNED。
- 样本权重 = `1/当日合格样本数`（同日总权重恒为 1，密集补传不压过其他日期）。
- 基线 = 加权均值；波动带 = 加权总体标准差 ±2σ；全部 BigDecimal 固定精度（scale=2, HALF_UP）。
- **窗口重算为权威**：在线消息只触发；权重/n_eff 只统计当前窗口；乱序/重复输入必须得到同一结果（确定性测试锁定）。
- 样本不足：保持 DEFAULT 与 38.50。已 LEARNED 后新窗口不达标：**保留**最后一次学习值/样本数/窗口/计算时间不伪写，仅记录陈旧告警日志供运维观察（stale 不落库字段，走日志）。

### 1.4 调度、事务与并发
- 复用 `HealthAnomalyScheduler` 模式：`IndividualBaselineLearningScheduler` 定时扫描近期活跃（有温度数据）牲畜、`max-per-poll` 上限、逐头独立事务、单头失败不中断批次、Redis/DB 牲畜级互斥防并发覆盖；走统一调度池（`SchedulerPoolConfig`）。
- 每头重算间隔节流（默认 ≥30min），避免高频遥测变高频全窗扫描；手动重算端点绕过节流供 dev/运维补偿。
- 学习事务只更新快照基线相关字段（禁整实体回写其他健康状态，防脏写回教训）。

### 1.5 消费、审计与回滚
- `HealthApplicationService.triggerEstrusScoring/calculateTempDelta` 改读**当前快照有效基线**（LEARNED→学习值，DEFAULT→38.50），不再取最老日志基线；`EstrusAnalysisService` 零改动。
- `estrus_scores` 新增 `baseline_used/baseline_source/baseline_computed_at/baseline_algorithm_version`（历史行不回改，NULL=旧口径）。
- 新温度日志写入实际 `baseline_source`；`delta` 生成列不变。
- 每日发热时长图改为按每条日志自身 delta（温度−该行基线）判超标，消除学习后固定 39.5℃ 的口径矛盾；`health_score` 门控与阈值常数不变。
- 开关：`smartlivestock.health.baseline-learning.enabled`（学习调度）与 `apply-learned`（消费切换）。**回滚 = 双开关关闭**：消费方回 DEFAULT 行为、新日志回默认基线，学习字段/审计保留；已写学习数据的恢复另立前向迁移（有 `estrus_scores` 审计支撑），不声称 Flyway down。

## 2. 串行 Tasks 与验证步骤

### Task 0：冻结需求与计划（本文件）
- 归档本计划；需求文件状态改为"已批准"并引用本计划。
- 验证：两文件口径一致（波动带/误报率/待试点三处无冲突），无未定决策点。

### Task 1：迁移、配置与模型字段
- 新增 Flyway 迁移（版本号取当时最新递增）：`health_snapshots` 加 `baseline_source(VARCHAR(12) NOT NULL DEFAULT 'DEFAULT' + CHECK)/baseline_sample_count/baseline_qualified_days/baseline_window_start/baseline_computed_at/baseline_band_low/baseline_band_high(DECIMAL(5,2))/baseline_algorithm_version(VARCHAR(16))`；`temperature_logs` 加 `baseline_source`（同 V20260817160000 的 NOT NULL DEFAULT + CHECK 模式）；`estrus_scores` 加四个审计列。
- `BaselineLearningProperties`（`@ConfigurationProperties(prefix="smartlivestock.health.baseline-learning")`，仿 `TbProperties`）＋ application.yml；`@PostConstruct` 校验窗口 7–14、合格日/每日样本下限、白名单非空。
- 同步 `HealthSnapshot/TemperatureLog/EstrusScore` 领域模型、JPA 实体、`HealthMapper`、相关 DTO；实体↔DDL 全量静态对账（DECIMAL 精度、CHECK 值域、无 SELECT * 于生成列）。
- 验证：`./gradlew compileJava` 过；远程全新库 Flyway+Hibernate validate 过（`remote-integration-test.sh --target`）；存量行 DEFAULT 行为测试绿。

### Task 2：纯学习内核
- 新增 `IndividualBaselineLearningService`（应用层编排）＋ `BaselineSampleAdmissionPolicy`/`BaselineStatisticsCalculator`（domain 纯计算）：准入→分组加权→median/MAD→均值/波动带→冷启动判定，排除原因可追溯（内存结构，不入库）。
- 验证：单测覆盖正常偏高个体可学习、发热触发点剔除、饮水恢复段、离体、活动缺失回退夜间、DATAGEN/UNKNOWN 拒绝、窗口边界、MAD=0、密集补传权重、乱序确定性、DEFAULT/LEARNED/陈旧三分支。

### Task 3：仓储、调度与真库写路径
- 扩展温度/活动/快照仓储：事件时间窗查询、来源筛选、逻辑去重、逐头乐观更新；新增调度器与牲畜级互斥。
- 新增 `IndividualBaselineLearningJourneyTest`（Testcontainers）：遥测写入→日志→快照→学习→后续新日志携带学习基线；断言历史行零回改、并发/重复样本结果一致。
- 验证：目标单测绿；`./scripts/remote-integration-test.sh --with-journey --target IndividualBaselineLearningJourneyTest` 真实执行记录结果。

### Task 4：发情消费与 fever 详情
- 改 `calculateTempDelta` 基线读取点＋评分审计四列写入；`apply-learned=false` 时行为与现状逐字节一致（回归锁）。
- `GET /health/fever/{livestockId}` 详情扩展基线来源/样本数/合格日/波动带/窗口/计算时间；API 契约文档同步；Flutter 不动。
- 验证：DEFAULT/LEARNED 两分支单测、开关回滚、审计列断言、发情阈值分档零改动、历史日志零回改、发热图口径一致。

### Task 5：管理端手动重算与只读 A/B 评估
- `POST /api/v1/admin/health/baseline-learning/recalculate`（PLATFORM_ADMIN/B2B_ADMIN，仿 DrinkingRecalcAdminController 权限口径）；`POST .../evaluations`（`@Transactional(readOnly=true)`，仿 BehaviorEvaluationService）。
- A/B 输入＝同一牲畜＋同一 recorded_at 窗口，输出 DEFAULT 与 LEARNED 两套基线/tempDelta/总分/≥70 分评分点/告警 episode 数量；响应体明示"机制对比，非误报率"。
- 验证：权限拒绝、跨牧场输入校验、只读（无写 SQL）、同输入对照、空数据/坏时间窗。

### Task 6：dev 造态、冒烟与回滚演练
- 新增 `scripts/baseline-learning-dev-smoke.sh`（或分步 SQL）：专用测试牲畜/设备、`MANUAL_IMPORT` 来源、≥10 天温度＋活动序列、明确时间窗；备份快照→造态→清理→恢复配对。
- 部署 dev 后执行并留 curl 证据：① 初始 DEFAULT/38.50；② 造态＋手动重算→LEARNED/合格日/样本数/窗口/波动带；③ 新遥测日志携带学习基线、estrus 详情 tempDelta/baselineUsed 变化；④ evaluations 同输入对比输出；⑤ 历史日志/评分零回改（SQL 计数断言）；⑥ 双开关关闭→回 DEFAULT 行为→恢复开启→清理造态恢复快照。
- 验证：全部 curl 输出与清理/恢复证据入交付说明；失败如实报告。

### Task 7：全量门禁、独立评审与交付
- `./gradlew compileJava`＋全部目标测试＋远程真库＋`./scripts/precheck-ci.sh` 全绿；push 后 `gh run list` 盯 Backend CI 绿，红即修。
- 派独立只读子代理评审 Diff（四轮评审六条硬规则＋契约检查项），主智能体复核修复。
- 交付五件套：改动文件/Diff 说明、测试×验收映射、实际命令与结果、未验证项与试点边界、监控日志/回滚。状态口径=**"机制与 dev 验证完成，真实效果待试点"**。

## 3. 文件范围

- **新增**：Flyway 迁移、`BaselineLearningProperties`、`IndividualBaselineLearningService`＋准入/统计计算器、`IndividualBaselineLearningScheduler`、admin 重算/评估 Controller＋DTO、Journey 集成测试、内核单测、dev smoke 脚本。
- **修改**：`HealthApplicationService`、`HealthSnapshot/TemperatureLog/EstrusScore`（domain+JPA+mapper）、`HealthDtos`、相关 Repository、`application.yml`、API 契约文档。
- **复用不复制**：`HealthAnomalyScheduler` 逐头调度、`DrinkingEventDetectionService.feverWindowsForLivestock` 疾病窗口缓冲、`DrinkingSummaryService` 合格日语义、`TenantZoneResolver` 时区链、`EstrusAnalysisService` 纯评分入口、Behavior evaluations 只读端点边界。

## 4. 试点后置项（不阻塞本期）

兽医手工校准 MAE/bias、人工负例上的真实 FPR/FNR/有效覆盖率、昼夜/季节分层、多胶囊更换校准——待试点真实数据，另立工单评估；达标后方可作为临产算法（NIX-158/286）的已验证前置。

## 5. 交付记录（2026-11-04 执行完毕）

### 5.1 逐 Task 验证结果（全部实际执行）

| Task | 验证 | 实际结果 |
|---|---|---|
| 0 | 需求/计划口径一致 | 波动带=±2σ、误报率降级为机制对比、待试点三处口径冻结一致；无未决标记 |
| 1 | compileJava | EXIT=0（主智能体复跑）；全新库 Flyway+validate 由 Task 3 Journey 覆盖 |
| 2 | 内核单测 | BaselineLearningCalculatorTest 17/17（后增 2 例=19/19，0 失败，JUnit XML） |
| 3 | 远程 Journey | `remote-integration-test.sh --with-journey --target IndividualBaselineLearningJourneyTest` 🟢（主智能体复跑两次，含全新库 Flyway+Hibernate validate） |
| 4 | 消费/审计/透出 | EstrusBaselineConsumptionTest 6/6 + TelemetryTest 20/20 + 内核回归；发热图全 DEFAULT 行与旧 39.5 口径逐字节等价有边界用例锁定 |
| 5 | 管理端/A-B | BaselineEvaluationServiceTest 5/5；只读断言（never save）；重构后 Journey 远程回归 🟢 |
| 6 | dev 端到端 | 见 §5.2 六步证据 |
| 7 | 全量门禁 | precheck-ci.sh 两轮全绿（首轮 + 评审修复后复跑）；独立评审 P0=0 |

### 5.2 dev 端到端冒烟证据（2026-11-04，dev=172.22.1.123:19080，库 sl-dev-postgres-1/smart_livestock）

专用造态：livestock_id=85（BL-SMOKE-001）+ 胶囊设备 163（BLSMK0000001）+ 活跃安装 + DEFAULT 快照；已全部清理（leftover=0）。

1. **初始态** `GET /farms/1/health/fever/85` → `baselineTemp=38.5, baselineSource=DEFAULT`，证据字段全 null ✓
2. **造态**：8 天×3 夜间样本（UTC 13:30/14:30/15:30=上海本地 21:30/22:30/23:30，值 39.30/39.40/39.50，MANUAL_IMPORT）+ 5 条低活动记录 ✓
3. **手动重算** `POST /admin/health/baseline-learning/recalculate {livestockId:85}` → `learnedNow=true, baselineTemp=39.4, qualifiedDays=8` ✓
4. **详情透出** → `baselineSource=LEARNED, sampleCount=24, qualifiedDays=8, windowStart=2026-10-26T13:30Z, band=[39.24,39.56], version=V1` ✓
5. **真实遥测帧**（datagen 管道：设备加入 farm1 分配集→ingest→MQ→健康消费）：新温度日志 `temp=38.23 baseline=39.40 flag=LEARNED`；新 estrus 行 `score=0 delta=-1.17 baseline_used=39.40 baseline_source=LEARNED algo=V1 src=DATAGEN`（来源如实标注）✓
6. **只读 A/B** `POST /admin/health/baseline-learning/evaluations` → 同输入 15 个评分点两侧一致，defaultSide 38.5/lastDelta=-0.27 vs learnedSide 39.4/lastDelta=-1.17，note 免责在响应体 ✓
7. **历史零回改**：`rewritten=0`（24 条 MANUAL_IMPORT 行全部保持 38.50/DEFAULT）✓
8. **回滚双向演练**：`.env.dev` 加 `SMARTLIVESTOCK_HEALTH_BASELINE_LEARNING_APPLY_LEARNED=false` + `docker compose --env-file .env.dev up -d app` → 新入库帧 `baseline=38.50/DEFAULT`、新评分行 `used=38.50/DEFAULT` ✓；移除开关重建 → 新帧 `baseline=39.40/LEARNED`（id 22499453）✓
9. **清理**：造态牲畜/设备/安装/快照/时序行/分配集/遥测帧全删，dev 复原（DATAGEN_ENABLED=true、.env.dev 无残留开关行）✓

### 5.3 演练抓到的缺陷（已修复）

1. **ingestTemperature 未受 apply-learned 门控**（回滚时新日志仍携带学习基线，违反 §1.5"新日志恢复默认基线"）——改为复用 `usesLearnedBaseline` 单点判定；新增回归用例 `ingest_withSwitchOff_newLogsCarryDefaultBaseline`（6/6 绿）；修复后 dev 重部署 + 远程 Journey 回归 🟢。
2. **运维坑（非产品缺陷）**：手工 `docker compose up -d app` 不带 `--env-file .env.dev` 时，`DATAGEN_ENABLED: ${DATAGEN_ENABLED:-false}` 插值默认把 datagen 关掉、帧静默停摆——恢复必须 `docker compose --env-file .env.dev -p sl-dev -f docker-compose.dev.yml up -d app`。已写入冒烟脚本注释。

### 5.4 独立评审结论与处置（2026-11-04）

P0=0；P1×2 已修复：①冒烟脚本 run_sql 未定义/发布帧 id 未接线（脚本重写为可运行形态）②LEARNED 重学缺逐样本发热剔除（新增 `FEVER_ELEVATED`：样本对冻结前基线 delta≥1.0 即剔除，补 2 用例，19/19 绿）。P2×5：③审计 algorithm_version 改读快照盖章值（已修）④免责文案走 MessageSource 三文件键 `health.baseline.evaluationNote`（已修）⑤消费整实体 save 与学习定向 UPDATE 的回写竞态（窄窗自愈 ≤15min，记录为已知边界）⑥重算响应把异常与数据不足合并（DTO 已注明，记录为边界）⑦回滚窗口内 fever 详情展示与实际消费口径短暂不一致（文档化口径，记录为边界）。

### 5.5 交付五件套

1. **改动文件**：新增 16（迁移/配置类/内核 5 类/组装器/服务/调度器/评估服务/DTO×2/AdminController/Journey/3 测试类/smoke 脚本）；修改 19（三表 domain+JPA+mapper、HealthApplicationService、HealthDtos、repository 三层、application.yml、messages×3、app-api.md、既有测试构造器×3）；`build.number` 为部署副产物不入库。
2. **验证命令与结果**：见 §5.1/§5.2，全部实际执行；无"仅代码审阅"项。
3. **已知边界**：消费侧整实体 save 竞态（自愈）；异常与数据不足同型响应；回滚窗口 fever 详情口径；多胶囊/昼夜分层未做；`n_eff` 未单列字段（窗口证据=admittedSampleCount/qualifiedDays）。
4. **上线运维**：回滚=双开关关闭（`SMARTLIVESTOCK_HEALTH_BASELINE_LEARNING_ENABLED=false` 停学习、`..._APPLY_LEARNED=false` 回默认消费），无需迁移回退；监控看应用日志关键字 `Baseline learned for livestock` / `baseline stale` / `Baseline throttle unavailable`。
5. **后续建议**：试点真实数据评估兽医 MAE/bias 与真实 FPR/FNR 后另立工单；达标后本机制作为 NIX-158/286 临产算法前置。**交付状态口径：机制与 dev 验证完成，真实效果待试点。**
