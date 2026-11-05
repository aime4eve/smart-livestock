# 实施计划：发情评分时间窗归一化（NIX-380，阻断级）

- 日期：2026-11-06；状态：已获用户批准（四段方案 + 全部推荐项"采纳一并解决"）
- 需求正本：`docs/superpowers/requirements/2026-11-06-estrus-scoring-window-normalization.md`
- 工单：NIX-380（High/阻断级，NIX-158/286 前置 3）
- 分支：`feature/estrus-scoring-window-normalization`（自 master@e36eaa63）
- 口径红线：仿真验证口径——仿真结论仅限管道与方法学验证，任何时候不得表述为真实效果；真实数据评估为试点后增强（用户裁决 2026-11-06）

## 设计定稿（四段方案确认项）

### 特征口径（NORMALIZED 路径，替代"最近 3 条 vs 其余 4 条"短窗环比）

```
活动分量(0.4)：activityRatio = mean(activityIndex, 当前窗) / median(activityIndex, 安静态基线窗)
  ├─ 通道优先级（裁决）：activityIndex > stepCount（单通道内不混用；降级同构比值）
  ├─ 两者皆缺 → 分量 null
距离分量(0.3)：distanceRatio = mean(distanceMeters, 当前窗) / median(distanceMeters, 基线窗)；缺失 → null
温度分量(0.3)：不动——最新温度 − 快照基线（LEARNED/DEFAULT 38.50，沿用 effectiveEstrusBaseline 单点判定）
分量缺失 → 剩余权重归一化（CAPSULE-only 必需设计：缺距离 → 活动0.571/温度0.429）
守卫：当前窗活动样本≥4 且基线窗样本≥4 且温度样本≥2 且 活动+温度两分量至少各一可用，否则跳过评分
```

### 分量阶梯（初稿，全可配置，仿真回归调参定稿）

- 活动比值分档：`≥3.0 → 95；≥2.0 → 80；≥1.5 → 45；1.0–1.5 线性 0–45；<1.0 → 0`（锚定文献 P8 发情期活动 ×2–4）
- 距离比值分档：与活动同构起步（3.0/2.0/1.5 同阈值），仿真 FP 不达标再独立调
- 温度分量：沿用现 `scoreTempDelta`（RRT +0.55℃ ≈ 41 分 ×0.429 ≈ 17.6 分贡献）
- 收敛判据：ratio≈3 中段 + 温度项 ≈ 72 分越线；FEVER（活动不高）/PREPARTUM（×1.5 末 8h）不触发

### 窗口参数（EstrusScoringProperties 初稿）

| 参数 | 默认 | 说明 |
|---|---|---|
| mode | NORMALIZED | LEGACY=旧口径回滚开关（单点判定，同 usesLearnedBaseline 先例） |
| currentWindowHours | 6 | 当前对比窗 |
| baselineWindowOffsetHours | 24 | 基线窗与当前窗的隔离带 |
| baselineWindowHours | 24 | 安静态基线窗 [−48h, −24h] |
| minCurrentActivitySamples / minBaselineActivitySamples | 4 / 4 | 样本门槛（时间窗取数，非记录条数） |
| minTemperatureSamples | 2 | 与现守卫一致 |
| 活动阶梯 6 值 / 距离阶梯 6 值 | 3.0/95, 2.0/80, 1.5/45 | 调参不改代码 |
| SQL 读数钳制 | 600 行 | 5min 耳标 48h≈576 帧，防窗口查询失控 |

- 算法版本（裁决）：**日志留存**——常量 `ESTRUS-FEATURE-V2` + slf4j，不落库（工单 DDL 无变更约束）；estrus_scores 审计四列语义不变
- 性能：窗口查询走既有 `findWindowByLivestockId`（分区表 livestock_id+recorded_at 索引），新带 Limit 重载钳制
- 回放器同步（硬约束）：`EstrusSeriesReplayer` 是生产公式逐位复刻，生产改口径必须同改；提供 NORMALIZED 与 LEGACY 双路径，`SimulationEvaluationService`/`BaselineEvaluationService` 按 properties.mode 选择——LEGACY 路径兼作"报告数字复现"工具
- 明确不做：70 阈值/加权结构/advice 文案不动；温度分量不动；基线学习器不动；标签窗对齐逻辑不动；无 DDL、无前端、无 l10n 改动

### 验收标准（逐条可判定）

1. 仿真回归：同参数 30 头×14 天×30min，ESTRUS 标签窗检出 ≥5/6、FP ≤2（episode 口径），DEFAULT 与 LEARNED 两基线分别通过
2. 验收增强（裁决）：**报告同 seed 复现 + 2 个新 seed 泛化**——同 seed 对齐报告量级，新 seed 证明阶梯不依赖特定事件相位
3. 真库 Journey 集成测试通过（远程 Testcontainers，含全新库 validate）
4. dev 端到端冒烟：遥测落库→评分落库→审计列正确→≥70 告警桥触发
5. precheck-ci.sh 全绿 + push 后两条 CI 盯绿
6. 回滚验证：开关切 LEGACY 后新评分恢复旧口径（单测 + dev 冒烟双向）
7. CAPSULE-only 单测：仅 activityIndex（stepCount/distance 全 null）完整评分

## Tasks（串行，每步过验证再进下一步；Task 0 视觉保真不适用——纯后端算法无 UI）

### Task 0：需求单状态同步 + 本计划归档（本文档）
需求单第 6 行"未获批编码"→"已获批"（2026-11-03 评审教训：状态必须同步）。
验证：两文件口径一致。

### Task 1：配置类 + 评分内核 + 单测
`EstrusScoringProperties`（模式仿 `BaselineLearningProperties`）+ `EstrusAnalysisService` 新增 `calculateScoreNormalized(activityRatio, tempDelta, distanceRatio)`（三分量可空 + 权重归一化 + 比值阶梯；旧方法原样保留）。
验证：compileJava；单测覆盖阶梯边界（1.0/1.5/2.0/3.0）、归一化三形态（缺距离/缺步数走 activityIndex/仅 activityIndex）、全 null 返 0、旧方法行为逐位不变。

### Task 2：triggerEstrusScoring 改造 + 单测
`HealthApplicationService`：mode 分支（LEGACY 原路径逐位保留）+ NORMALIZED 窗口读数（当前窗/基线窗，Limit 钳制重载）+ 特征计算（activityIndex>stepCount 降级、均值/中位数）+ 守卫重定义 + 审计照旧（四列）+ `ESTRUS-FEATURE-V2` 日志。
验证：单测覆盖开关双路径（LEGACY 输出与现状一致）、CAPSULE-only、守卫三态（样本不足/冷启动/仅温度不评分）、无步数降级、算法版本日志；compileJava + 目标测试绿。

### Task 3：回放器同步 + 评估服务适配 + 单测
`EstrusSeriesReplayer` 双路径（NORMALIZED 复刻新口径逐位语义；LEGACY 保留现公式）；`SimulationEvaluationService`/`BaselineEvaluationService` 按 mode 选择；episode 对齐逻辑不动。
验证：单测——LEGACY 重放与既有回归测试数字一致（锁旧口径）、NORMALIZED 构造序列检出行为正确；compileJava + 目标测试绿。

### Task 4：Journey 集成测试
真库（远程 Testcontainers）：窗口查询/钳制、评分落库、审计四列、开关切换、全新库 validate。
验证：`./scripts/remote-integration-test.sh` 目标 Journey 真实绿。

### Task 5：全量验证 + 仿真回归 + dev 部署 + 冒烟
`./scripts/precheck-ci.sh` 全绿 → 部署 dev → 仿真回归（同 seed 复现 + 2 新 seed，两基线各 ≥5/6、FP≤2；不达则调 EstrusScoringProperties 阶梯迭代）→ dev 端到端冒烟（含回滚开关双向）→ push + CI 盯绿。
验证：验收标准 1–6 逐条留证；五件套交付。

## 风险与对策（四段方案已确认，实施中盯）

- 窗口读数性能：Limit 钳制 + 分区索引；5min 耳标高频帧是压力上限场景
- 基线窗被上一事件污染（真实 21 天周期）：中位数鲁棒 + 24h 隔离带 + FP≤2 兜底；真实周期验证属试点范围
- 存量 estrus_scores 新旧口径混存无版本列：日志留存 + 时间断点可追溯（裁决接受）
- 初稿阶梯不达验收：参数全可配置，Task 5 调参迭代不改代码

## 执行收口（2026-11-06 追记）

全 Task 串行完成（Task 1-4 各经主智能体评审，Task 5a/5b 分段执行），**验收七条全过**。

### 设计迭代（三次取证驱动修正，均超出初稿参数范畴、有实证记录）

1. **同相位基线窗**（编码前定稿修正）：当前窗 vs [−48h,−24h] 异相窗会把活动昼夜包络（昼 U(30,90)/夜 U(5,25) 差 3–18 倍）混进比值 → 改为 24h 整数倍同时相窗 ×3 池化。
2. **mean/mean 替代 mean/median**（`72c3a078`，首轮回归 FP 9–21 触发取证）：日/夜双峰分布上跨 06:00 日界窗仅含少数白天帧，mean 被抬而池化 median 藏在夜间簇 → 清理牛比值虚高 2.1 → 每个清晨边界批量误报。同相位窗昼夜混合比逐日相同，mean/mean 估计同一量。**既有测试期望零变化**（常数夹具中位数=均值）。
3. **阶梯 high 档 95→100 + 温度负钳 0**（`0b74fab2`）：逐位置三通道追踪实锤比值非瓶颈（18 标签窗 maxRatio 全 ≥2.58），漏检卡在 `scoreTempDelta` 负分支无下限（饮水谷 −2…−14℃ → tempScore −100…−700 拖整分归 0）。比基线凉不是发情反证 → 归一化路径负值钳 0；钳后 act+dist=66.5 差 3.5 分 → 持续 ≥2× 同相位双通道上升即最大站立发情信号，high 档 100 使其自足 70 线。窗口参数不变（cw6h/offset24h×3/rung2.0）。
4. **告警桥断链修复**（`44dc9b5c`，dev 冒烟发现）：领域仓库每次 `findByLivestockId` 经 mapper 返回新实例，评分落在内部重读实例而桥比对调用方实例 → ≥70 翻转永远不可见 → 无 ESTRUS 告警。legacy 时代 episodes=0 从未暴露。修复=调用方实例传入评分路径复用。属既有架构缺口，被本单首次踩通。

### 终验数字（dev 在线，判据 ≥5/6 检出且 FP≤2，双侧各判）

| seed | DEFAULT 侧 | LEARNED 侧 |
|---|---|---|
| 20261105（同 seed） | TP=5 FN=1 FP=1 ✓ | 同左 ✓ |
| 20261106 | TP=6 FN=0 FP=2 ✓ | 同左 ✓ |
| 20261107 | TP=5 FN=1 FP=2 ✓ | 同左 ✓ |

- LEGACY 锚点轮（seed 20261105，mode=LEGACY）：与 2026-11-05 报告数字**逐位一致**（两侧 0/0/0/0/6），管道可比性成立
- 基线学习质量：MAE 0.135–0.154（与上轮 0.147 同量级），hit02 0.70–0.83
- dev 端到端冒烟：真实 HTTP ingest → 评分落库（70/增幅列 200/米差 120.00/审计四列 LEARNED）→ 快照联动 → ESTRUS WARNING 告警创建（RULE）；守卫四态验证（温度样本不足正确拒绝评分）
- 回滚开关：Journey 真库 LEGACY 对照用例 ✓；CAPSULE-only ✓
- 验证链：目标单测 93/93 绿 + 远程 Journey 6/6 ×3 轮 + precheck 全绿 + Backend CI 绿（flaky：DrinkingEventJourneyTest 既有债，同 commit 重跑绿）
- 造态清理归零：livestock 69 / devices 118 / sim_runs 0 / 零残留
- 交付口径：**仿真验证口径**——机制与 dev 验证完成；真实效果待试点（real-only 复核红线不变）
- 遗留记录：①告警桥同事务重复建警 2 条（防重查询看不到未提交行，既有小瑕疵，另立小单）②CAPSULE-only 无距离时单活动通道数学上不可达 70（57 封顶），真实胶囊检出依赖前置 2（步数/距离派生）或温度正贡献 ③DrinkingEventJourneyTest flaky 债
