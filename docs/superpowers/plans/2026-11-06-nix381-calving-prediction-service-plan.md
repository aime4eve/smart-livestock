# 实施计划：CalvingPredictionService 分娩预警算法（NIX-381，仿真验证口径）

- 立项依据：Linear NIX-381 + `docs/superpowers/requirements/2026-11-06-calving-prediction-service.md`（2026-11-06 用户裁决立项；同日裁决"仿真验证口径即当前交付验收"）
- 分支：自 master 新开 `feature/calving-prediction-service`（NIX-380 PR #138 未合并不阻塞：体温与活动通道均不依赖其归一化机制，触碰面已按"新文件为主"压缩）
- 状态：**未获批编码（AGENTS §3）**——本计划经用户批准后按 Task 串行执行
- 红线：datagen 仿真数字不得冒充真实效果；对外禁"约 15 小时"表述（smaXtec 商业宣称，无同行评审依据）；学术锚点 = Costa Jr 2016 / Burfeind 2011 / Macmillan 2022 / Pahl 2014

## 设计定稿（四段方案确认项）

### 触发模型与调用链

不走红情遥测事件驱动（临产是 24–48h 慢趋势，逐遥测评分浪费且噪声大），走**周期调度器逐头评估**：

```
CalvingPredictionScheduler（fixedDelay，默认 1h，对齐 IndividualBaselineLearningScheduler 模式）
  → snapshotRepo.findRecentlyActive(24h, maxPerPoll) 枚举有近期体温遥测的牲畜
  → 逐头：feature gate 检查（farm→tenant→tier→feature_gates.calving_warning，租户解析法 Task 0 对齐 HealthAnomalyService）
  → CalvingPredictionApplicationService.evaluate(livestockId)（REQUIRES_NEW 短事务）
      → 读体温 72h + 活动 56h（findWindowByLivestockId 现成半开窗）
      → 读最近 BREEDING 事件（PhysiologyQueryPort，先验通道）
      → CalvingPredictionService（domain 纯内核）打分 + 估算预计分娩窗
      → 稳态零写入；score ≥ 50 或跨越报警/解除线时：写 calving_predictions + 定向 UPDATE health_snapshots.calving_risk_score
      → 告警桥接服务 syncCalvingAlert：≥70 建单（hasActiveAlert 去重）、<55 解除、55–70 维持现状态（双阈值迟滞，免 Redis 状态）
  → RanchCommandPort.createAlert / resolveAlert → alerts 表（AlertInfo 走 messageKey/messageArgs，双语 MessageSource）
```

调度器 fixedDelay 天然不重叠、无第二触发源（v1 不做管理端手动重评 API），**不需要 Redis 节流**。

### 特征口径（v1 三通道，全部绝对水平对比——吸取 NIX-380"短窗增幅失灵"教训，负分支钳 0）

1. **体温净降**（主分量）：`tempDrop = refLevel − currentLevel`
   - `currentLevel` = 近 6h 温度均值；`refLevel` = 24h 前 / 48h 前两个**同相位** 6h 窗的池化均值（消昼夜项 0.4℃ 振幅，口径对齐 NIX-380 池化基线窗）
   - 阶梯初稿（全可配置，仿真回归调参定稿）：≥0.30℃→100（Burfeind 24h 口径）；≥0.20→70；≥0.12→45；<0.12→0；回升（负值）→钳 0
   - 样本守卫：当前窗 ≥minCurrentTempSamples（30min 粒度默认 8 点）且参考窗同数，不足则本分量不可用
2. **活动升高**：`activityRatio = 近 8h 活动指数均值 ÷ 24h/48h 前同相位 8h 窗池化均值`
   - 阶梯初稿：≥1.5→100（生成器 P13=Macmillan 口径）；≥1.3→70；≥1.15→45；否则 0
   - 步数/距离不参与（仿真中由活动派生，非独立信号）；样本守卫同上
3. **配种先验**（可选分量）：最近 `physiology_events.BREEDING` 的 `occurred_at` → 妊娠天数
   - [270, 293] 天（荷斯坦 283d ±10）→ 先验正常；<250 天 → 总分乘抑制系数 0.5（降误报）；>300 天或无事件 → 中性
   - 开关 `useBreedingPrior` 默认 true，事件缺失时权重归一到前两通道（对齐 NIX-380 归一化做法）
4. **综合**：权重 0.45 / 0.35 / 0.20（先验不可用时按可用分量归一化），clamp [0,100]
5. **终段回升检测**（⚠ 开放问题 5）：检测"前 12h 内 ≥0.2℃ 净降且近 3h 回升 ≥0.12℃"作为加分项。**仿真生成器只建模了线性渐降（无回升段），该分量数值不可由本次仿真背书**——默认开启、报告如实标注；若要求更强口径可默认关闭

### 预计分娩时间窗（估算，文案用"预计"措辞）

- 体温渐降首次持续越阈（−0.15℃ 连续 2 采样点）时刻 tOnset → 初窗 [tOnset+24h, tOnset+48h]（Costa 渐降期口径）
- 活动升高已现 → 收窄为 [now+2h, now+16h]（~8h 活动升高口径，窗宽放宽兜噪声）
- 配种先验可用 → 与 [283d−3d, 283d+7d] 取交集；空交集时保留体征窗（先验与体征矛盾，报告告警正文不带窗）
- 输出 `expected_window_start/end` + 中点 `expected_calving_at`（存 calving_predictions，告警正文带格式化窗）

### 数据与 DDL（单迁移 V20261106100000__calving_prediction.sql 四节）

1. `ALTER TABLE health_snapshots ADD COLUMN calving_risk_score INT`（NULL=从未评估）
2. `CREATE TABLE calving_predictions`：`id, livestock_id NOT NULL, farm_id NOT NULL, risk_score INT NOT NULL, temp_drop_celsius DECIMAL(4,2), activity_ratio DECIMAL(5,2), prior_enabled BOOLEAN, expected_window_start TIMESTAMP NULL, expected_window_end TIMESTAMP NULL, predicted_at TIMESTAMP NOT NULL` + 审计四列对齐 estrus_scores（`baseline_used DECIMAL(5,2), baseline_source VARCHAR(12), baseline_computed_at, baseline_algorithm_version VARCHAR(16)`）+ 索引 `(livestock_id, predicted_at DESC)`、`(farm_id, predicted_at DESC)`。建表风格精确对齐 V20 estrus_scores（Task 0 核对原文）
3. `chk_alerts_type` DROP+ADD 重建 14→15 值追加 `CALVING_WARNING`（V40 / V20260925100000 范本）
4. `feature_gates` seed `calving_warning`：basic/standard `lock` FALSE，premium/enterprise `none` TRUE（对齐 estrus_detect；retention_days NULL，本 gate 不涉留存；ON CONFLICT DO UPDATE）

### 落库与快照写入纪律

- 写入仅在 `score ≥ 50` 或跨越 70/55 线时发生（稳态零写入，100 头×1h 稳态无行增长）
- `health_snapshots.calving_risk_score` 用**定向 UPDATE**（模式对齐 `updateLearnedBaseline`），禁整实体 save（40-Pitfalls 2026-11-02 脏写回教训）
- calving_predictions 带审计四列快照盖章值（对齐 estrus_scores 审计口径）

### 告警与可见面

- 桥扩展：`HealthAlertBridgeService` 增 `TYPE_CALVING = "CALVING_WARNING"` + `syncCalvingAlert(snapshot, source)` 公开方法（供调度链定向调用，不动既有 syncAlertsWithSnapshot 三规则语义）；`hasStateChanged` 增 prevCalvingScore 重载
- `AlertType` 枚举 +15 值；`AlertWorkbenchService.HEALTH_TYPES` 加 CALVING_WARNING（scene 归 health；episode 板 v1 不加第五块）
- `StaleHealthAlertReconciler.HEALTH_TYPES` 加 CALVING_WARNING（快照分 <55 的陈单自愈）
- 地图联动（⚠ 开放问题 2）：`RanchOverviewApplicationService.deriveHealthStatus` 增 `calvingRiskScore >= 70 → "WARNING"`——维持告警桥注释"地图与告警中心必须一致"不变量；severity=WARNING
- 告警正文：`alert.health.calving=牲畜 [{0}] 临产风险偏高：{1} 分，预计分娩窗口 {2}`（中英双语同步；窗格式化走评估服务，farm 时区 TenantZoneResolver）
- DATAGEN source 透传告警 ticket（mapSource 既有语义）

### i18n 与前端

- 后端 `messages_zh/en.properties`：`alert.health.calving` 双语
- Flutter：`alert_summary` 分类映射（health 组）、`alert_card` 图标/色、告警过滤条类型集、admin `feature_gate_models.dart` + `featCalvingWarning`（arb 双语同步）；`flutter gen-l10n` + `flutter analyze` 校验

### 仿真评估管道（datagen 侧，验收依据）

- `CalvingSeriesReplayer`（镜像 EstrusSeriesReplayer）：event-time 重放温度/活动序列 → 分数序列 → ≥70 首次穿越；episode 合并 gap≤24h
- 评估指标（SimulationEvaluationService 扩展或新 CalvingEvaluationService）：
  - **检出**：PREPARTUM 头首穿越时刻早于 `ground_truth_labels.prepartum.period_end`（=产犊时刻）→ 提前量 = period_end − 首穿越
  - **提前量分布**：min / median / max（小时）
  - **误报率**：非 PREPARTUM 头（CLEAN/WATER/FEVER/ESTRUS/DETACHED）的告警 episode 数（episode 口径）
  - DEFAULT（38.50）/ LEARNED 双侧各判
- ⚠ 开放问题 3：规模 **100 头 × 14 天 × 30min × 3 seed**（20261105 复现 + 20261108/20261109 新 seed），每 seed 约 10 头产前牛
- 报告 note 沿用 `simulation.evaluation.note` 仿真口径红线；报告落 `docs/reports/`

### 验收标准（逐条可判定，工单口径）

1. 全新库 Flyway 跑通（Journey 真库基类跑全量迁移 + remote-integration-test）
2. 内核单测全绿：阶梯边界 / 负钳 0 / 权重归一化 / 先验抑制 / 同相位窗 / 窗口估算
3. Journey 集成测试：PREPARTUM 形态序列 → calving_predictions 行 + CALVING_WARNING ACTIVE + 快照列；回落 → AUTO_RESOLVED；重复评估不重复建单；gate 锁定时评估跳过
4. `./scripts/precheck-ci.sh` 全绿；与 NIX-380 分支冲突面为零（若 #138 先合并，rebase 后冲突核对）
5. 三 seed 仿真回归（⚠ 开放问题 4 判据初稿）：检出 ≥7/10、误报 ≤2 episode、提前量中位数 ≥6h——不达标则调参迭代并如实留痕，不得放宽判据凑数
6. dev 部署 + 浏览器端到端：PREPARTUM 造态 → 告警中心可见 CALVING_WARNING（中英文）→ 卡片/过滤/详情正常；（若联动获批）地图 marker 变色
7. 评估报告落档（仿真口径红线注记 + 提前量分布表）；对外表述按"路线图能力 → 仿真验证完成"分级

## Tasks（串行，每步过验证再进下一步；子智能体逐 Task 实施、主智能体评审，AGENTS §3 执行准则）

- **Task 0 细节核实 + 归档**：核实 ①HealthAnomalyService 调度上下文的租户/档位解析法 ②V20 estrus_scores 精确 DDL ③LivestockHealthState record 字段 ④Flutter alert_summary 分类映射点 ⑤SimulationHerdGenerateRequest 规模参数 ⑥HealthSubscriptionPort 在调度线程的行为。验证：核实结论写入本节追记；分支创建 + 本计划提交落档
- **Task 1 迁移 + 持久层**：V20261106100000 四节 + HealthSnapshot 加列 + CalvingPrediction 实体/域模型/仓储（含定向 UPDATE）。验证：compileJava + 实体/列静态对账（§5b 清单）+ schema 对齐单测
- **Task 2 配置 + 纯内核**：CalvingPredictionProperties + CalvingPredictionService + 单测。验证：单测全绿（无 Spring、纯构造，AssertJ）
- **Task 3 应用层 + 告警**：CalvingPredictionApplicationService + Scheduler + 桥 syncCalvingAlert + hasStateChanged 重载 + AlertType/工作台/自愈白名单 + deriveHealthStatus（若联动）+ 单测。验证：单测全绿（Mockito 风格对齐 EstrusNormalizedScoringTest）
- **Task 4 回放器 + 评估扩展**：CalvingSeriesReplayer + datagen 评估指标 + 单测（手算 oracle 锁，对齐 NIX-380 回放器测试风格）。验证：单测全绿
- **Task 5 Journey 集成测试**：CalvingPredictionJourneyTest（造态→评估→告警→解除→去重→gate 门控全链）。验证：`./scripts/remote-integration-test.sh --with-journey --target CalvingPredictionJourneyTest` 绿
- **Task 6 i18n + 前端**：messages 双语 + Flutter 分类/图标/门控/arb。验证：compileJava + `flutter gen-l10n` 零缺失 + `flutter analyze` 干净
- **Task 7 全量收口**：precheck-ci 全绿 → dev 部署 → 三 seed 仿真回归 → 浏览器端到端冒烟（中英文）→ 评估报告落档 → 提交推送 + `gh run list` 盯绿。验证：全部留证

## 风险与对策

1. **调度线程无租户上下文**：gate 检查需 farm→tenant→tier 链；Task 0 核实 HealthAnomalyService 同款取法后对齐，不自行发明
2. **health_snapshots 三方并发写**（基线学习调度器/遥测链/本调度器）：短 REQUIRES_NEW + 定向 UPDATE，禁整实体 save
3. **误报治理**：临产低频高影响；70/55 双阈值迟滞 + 先验抑制 + 阈值全可配置，仿真回归先行调参
4. **NIX-380 合并冲突**：改动以新文件为主；`HealthApplicationService` 本单零触碰（基线判定在新服务内按 `usesLearnedBaseline` 同口径小实现并注释去重遗留，留待后续统一抽取）
5. **仿真红线**：报告/文案带仿真口径注记；回升分量不可由本次仿真背书（开放问题 5）；对外禁 15h
6. **分区表与批量**：体温/活动按月分区，72h/56h 窗口查询走 recorded_at 索引；100 头逐头串行短查询，量级无虞

## 开放问题（⚠ 待用户批准本计划时裁决；未否决即按推荐执行）

1. **calving_predictions 表**——按推荐"建表"落笔（工单原文"另议"）
2. **地图 marker 联动**——按推荐"联动"落笔（若否决，桥一致性注释加放宽说明）
3. **评估规模 100 头 × 14 天 × 3 seed**——按推荐落笔
4. **终验判据数值**（检出 ≥7/10、误报 ≤2、提前量中位 ≥6h）为初稿，回归迭代可修订但须留痕
5. **终段回升分量默认开启**——仿真管道未生成回升形态，该分量数值不可由本次仿真背书，报告如实标注；可改默认关闭

## Task 0 执行追记（2026-11-06，已获用户批准"同意，继续"；⚠ 1-5 全按推荐执行）

六项核实结论（全部已到源码原文级）：

1. **调度线程 gate 检查缺口（真缺陷，实施必须绕开）**：`HealthSubscriptionPortImpl.resolveTier` 读 `TenantContext.getCurrentTenant()`，调度线程无上下文 → 回落 `basic` → 锁定档 gate 全判 false → 分娩评估被静默全跳。`HealthAnomalyScheduler` 的 `@Value("${ai.assessment.tenant-id:1}")` 写死租户是单租户简化，不可照抄。**修法定稿**：`HealthSubscriptionPort` 增显式租户变体 `hasFeatureForTenant(Long tenantId, String featureKey)`（ACL 实现内按显式 tenantId 查订阅档位，不碰 ThreadLocal）；租户来源 = `farms.tenant_id`（identity 模块 `Farm.tenantId` + `FarmRepository.findById` 现成，health→identity 直注 bean 有 `TenantZoneResolver` 先例），经 health 的 `RanchQueryPort` 增 `findTenantIdByFarm(Long farmId)` 暴露。
2. **estrus_scores 精确 DDL**（V20 L106-120）：`farm_id NOT NULL REFERENCES farms(id)`、`livestock_id NOT NULL`（无 FK）、`score INTEGER CHECK 0-100`、索引 `(farm_id, scored_at DESC)` / `(livestock_id, scored_at DESC)` / 部分索引 `score>=70`。calving_predictions 按此风格 + 审计四列自始内联（基线审计列是 V20261104100000 后补的，本表一步到位）。
3. **LivestockHealthState**（`ranch/domain/port/HealthQueryPort.java` L13）：`(livestockId, tempStatus, motilityStatus, estrusScore int, currentTemp, currentMotility, activityStatus)`。地图联动需给该 record 增 `calvingRiskScore Integer`，连带 health 侧 HealthQueryPort 实现映射 + `deriveHealthStatus`（null 安全：null 不参与判定）——并入 Task 3。
4. **Flutter 侧无 type→group 映射**：告警列表分组计数由后端 `AlertApplicationService.GROUP_HEALTH`（L43-44，5 值）预计算后下发（`AlertSummaryDto.TypeGroupCounts`），**后端 GROUP_HEALTH 加 CALVING_WARNING 是分组可见的必要改动**；Flutter 只消费分组计数与 type 字符串，Task 6 枚举卡片/过滤的分支点。
5. **SimulationHerdGenerateRequest**（SimulationDtos L26-33）：`(farmId, livestockIds, deviceIds, days, granularityMinutes, seed, farmZoneId)`——100 头评估按显式 100 个 ID 传参即可，无规模上限障碍。
6. **health 的 RanchQueryPortImpl**（`@Component("healthRanchQueryPort")`）直接注入 ranch 的 `LivestockRepository`/`AlertRepository`——跨模块仓储直注是既有形态，增 identity `FarmRepository` 注入合规。

分支：`feature/calving-prediction-service`（自 origin/master 新建），本计划 + 本追记随 Task 0 提交落档。

## 设计迭代（Task 2 评审裁决，2026-11-06）

Task 2 交付后主智能体评审抓到三处仿真口径缺陷（子智能体如实上报未擅自改，评审定案退回修正）：

1. **onset 字面口径必误**：相邻样本对降幅 ≥0.15℃ 在 30min 粒度真渐降（36h 降 0.3℃ ≈ 0.004℃/步）上永不触发、在饮水谷（2.3–4.9℃/2 网格点）上必误触发——与 NIX-380"短窗增幅失灵"同构。**裁决=改水平口径**：滚动 6h 尾窗均值 vs 同相位池化参考水平 ≥0.15℃ 持续 2 评估点，onset 取连续段首点。
2. **饮水谷主导体温通道**：仿真噪声 SD 0.4 + 每日约 10 次饮水谷，6h 均值波动远大于阶梯间距。**裁决=内核加共享 excludeWindows 静态过滤**（半开窗），生产编排与回放器统一先过滤饮水事件窗再进内核；窗口统计维持均值（NIX-380 实证池化 mean 优于 median，靠排除不靠稳健统计量）；Task 4 评估须统计非产前牛 rebound 命中率。
3. **先验交集按字面空转**：体征窗 ≤now+48h 永远早于 now+7d 上界，截断永不生效。**裁决=先验窗直接计算** [now+(280−g)×24h, now+(290−g)×24h] 与体征窗求交，交空=矛盾保留原窗（WindowEstimate.priorConflict 标记，子智能体合理增补）。

另接受子智能体自主决定（均合理）：抑制=先验 0 分保权重+总分×0.5 双重压分（保守方向正确）；rebound 固定 3h 块（12h 回看 4 块，块样本门槛复用 minRefTempSamples）；特征值 2 位 HALF_UP 先舍入再评分（与落库精度一致）；配置校验超集+独立配置测试类 8 例。

Task 2 产物：内核 6 API + 测试 34 例全绿 + 配置测试 8 例全绿（提交 6f249926）；变异检查实证（注入 4 错 → 6 用例失败 → 还原 sha256 一致）。修正落盘为 Task 2b 提交。

## 设计迭代（Task 2b 评审裁决，2026-11-06）

Task 2b 修正后（onset 水平口径/饮水窗排除/先验交集，51 测试绿+变异检查）子智能体上报四条量化风险，评审裁决：

1. **饮水排除×样本门槛冲突**（白天 6h 窗排除覆盖 ~86% 后仅 ~1.6 样本<门槛 8）→ 裁决=接受体温通道"夜间/干净间隙可用"形态：排除窗对齐基线学习口径 `[event_start, event_end+120min]`、**只作用于体温通道**；白天评估体温分量自然不可用；Task 4 评估报告必须按 herd class 报告体温通道可用率。
2. **噪声与信号同量级**（SD(tempDrop)≈0.26℃ vs 真信号 0.2–0.3℃）→ 三道防线：①**单通道封顶**：体温分量不可用时总分封 `singleChannelCapNoTemp=60`（<alertThreshold）——活动日包络方差使活动单通道不足以告警，分娩预警以体温为主证据；②**告警持续性**（Task 3 范围）：score≥70 需连续 2 次调度评估（状态复用 calving_risk_score 列：prev≥70 且 new≥70 才建单，首次越线只落分；无需 Redis）；③解除 <55 立即。阈值/持续性终值待 Task 4 仿真标定（判据初稿已批可迭代留痕）。
3. **onset 检出滞后 ~21h**（0.15 阈值/渐降斜率+6h 窗滞后）使 [onset+24h, onset+48h] 整窗错过分娩 → 默认改 **[onset+2h, onset+30h]**（Burfeind"检出即 24h 内"口径），Task 4 再标定。
4. **活动通道不排除饮水窗**（仿真饮水不影响活动；排除会杀死白天 2–16h 窗主信号）→ 排除契约仅体温。

Task 3 指引（子智能体上报有效）：排除窗数据源 `DrinkingEventJpaRepository` 现成查询；`now` 用调度触发时刻（半开窗不含 now，防前视）；`activityRiseSeen := activityRatioScore(ratio,p)>0` 编排与回放统一；`activity_ratio` 落库前 clamp DECIMAL(5,2) 上限；展示窗 `start=max(start, now)`。

## 设计迭代（Task 2c 评审裁决与检出率结构修正，2026-11-06）

Task 2c 落地后（单通道封顶 60/onset 窗 [+2h,+30h]/活动不排除，56 测试绿+变异检查）子智能体推演检出率上限：白天体温全灭+封顶下，"只有分娩落在当地约 04:00–12:30 的牛可检出"，检出率天花板 ~1/3、提前量 ~5h，验收 5 大概率不达标。

**评审裁决（两步走）**：

1. **结构修正先行（Task 2d，不等仿真）**：白天体温全灭是确定性结构漏洞（饮水排除覆盖 ~86% 白天）→ 体温通道改**陈窗选择**：拖尾 `staleWindowMaxLagHours=24` 内最新干净 6h 窗（t0），参考窗**锚定 t0** 同相位池化（相对观测窗对齐昼夜项，锚 now 会系统性偏移）；产前渐降持续 ≥24h，夜窗信号白天可读，体温通道从 ~4h/天变为首个干净夜窗后近连续可用。配套 `detectOnset` 参考水平改**逐点锚定**（评估点 t 各自取 t−24h/−48h 参考窗；原 now 固定参考在 36h+ 扫描上会制造白天伪 onset）。
2. **新增三个共享配置**（Task 3/4 消费）：`drinkingExclusionBufferMinutes=120`（排除窗=[event_start, event_end+buffer]，可调到谷核窄窗做标定迭代）、`alertPersistencePoints=2`、`staleWindowMaxLagHours=24`。
3. **先验通道对检出率的地位**（Task 4 评估设计依据）：仿真生成器不产 BREEDING 事件 → 无先验场景下检出需体温≥中档∧活动≥中档，提前量由活动升高窗（末 8h）主导 ~5–8h；有先验场景（真实部署有配种记录）体温中档+先验即 79 分，提前量可至 ~12h。**Task 4 必须双场景评估**：A=无配种记录（保守，验收判据作用于此）、B=有配种记录（以真值产犊倒推 283d 合成配种日期，如实标注为"记录可用场景"非预测能力）；报告分列。
4. incidental 确认：先验-only（体温活动双缺）也封 60 语义正确（无生理证据最多提示级）。
