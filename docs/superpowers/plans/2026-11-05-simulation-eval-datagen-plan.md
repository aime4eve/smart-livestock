# 实施计划：datagen 文献参数仿真——基线效果评估与分娩预警数据前置（dev 预演）

- 日期：2026-11-05；状态：已获用户批准（计划确认）
- 需求正本：`docs/superpowers/requirements/2026-11-05-simulation-eval-datagen.md`
- 分支：`feature/simulation-eval-datagen`（自 master@dd84400d）
- 结论口径红线：仿真只产"管道与方法学验证"结论，不冒充真实效果（AGENTS §2）

## 范围裁决（用户未逐项确认，按推荐执行）

①分娩侧只做数据+标签+形态验证，`CalvingPredictionService` 另批；②全局 `SynthesisService` 参数不动，评估走独立生成器。

## Tasks（串行，每步过验证再进下一步）

### Task 0：需求单+本计划归档（本文档）
验证：两文件口径一致。

### Task 1：文献取证文档
`docs/research/2026-11-05-牛群仿真参数文献取证.md`——P1–P16 参数表（值/单位/出处 URL/可信度）+ 反推项标注（离体形态/挤奶伪影/手工校准误差带推导）+ 两处口径纠偏（Cantor 103min=极端灌服工况，均值 57.75±38.7min；"产前 15h"=smaXtec 商业宣称，学术 24–48h −0.2~−0.4℃）。
验证：逐条带出处；反推项显式标注。

### Task 2：迁移+生成器+单测
- 迁移 `V20261105100000__simulation_runs_truth.sql`：`simulation_runs`(id, seed, params JSONB, herd_size, days, created_by/at) + `simulation_truth_baselines`(run_id, livestock_id, true_baseline DECIMAL(5,2), herd_class VARCHAR CHECK IN CLEAN/WATER/FEVER/ESTRUS/PREPARTUM/DETACHED, created_at)。
- `SimulationHerdGenerationService`（datagen.application）：确定性（seed）生成 N×D 天 30min 粒度序列；每头 μᵢ~N(39.0,0.4) 截断[38.6,39.5] + 昼夜 0.4℃ 余弦峰相 23:30 + 挤奶双峰伪影 + AR(1) 噪声 SD0.4 + 饮水 bout ~10/日（深 2.3–4.9、恢复 58±39min 指数形状）；事件配比：发情（~20% 头、×3 活动 8–30h、RRT+0.55）、产前（~10% 头、24–48h RRT −0.3 渐降 + 末 8h 活动×1.5、产犊时刻标签）、疾病发热（+0.8℃ over μᵢ，12–24h）、离体段（25–35℃ 摆动、活动缺失）；活动通道带昼夜形态+步数（活动强度派生）；JDBC batch 直插 temperature_logs/activity_logs（source=DATAGEN）；标签走 GroundTruthLabelRepository（SYNTHETIC）；真值写两表；端点 `POST /api/v1/admin/datagen/simulation/herd`（PLATFORM_ADMIN）。
- 验证：单测断言形态（产前降幅/发情增幅/温谷深度与恢复/离体 35–43 门卫/个体分布截断/确定性同 seed 同结果）；compileJava。

### Task 3：回放组件重构+评估端点+Journey
- 抽 `EstrusSeriesReplayer`（共享同输入回放，DEFAULT/LEARNED 候选基线各算一遍评分点/episode），`BaselineEvaluationService` 改为复用（行为不变，回归测试锁）。
- `SimulationEvaluationService` + `POST /api/v1/admin/datagen/simulation/evaluation`（readOnly）：runId → 每头 recalculate(bypassThrottle) → learned vs 真值 MAE/bias/±0.1/±0.2 命中率（分层 herd_class）+ 手工校准代理（真值+ε~N(0,0.2)）+ 发情标签窗 vs 回放 episode 的 TP/FP/FN（DEFAULT/LEARNED 两侧）；响应声明走 MessageSource 键 `simulation.evaluation.note`。
- Journey `SimulationEvaluationJourneyTest`：建牲畜/设备 → 生成器造 3 头×3 天小规模 → 配置白名单加 DATAGEN → recalculate → 评估端点断言真值命中/标签对齐。
- 验证：单测绿 + `remote-integration-test.sh --with-journey --target SimulationEvaluationJourneyTest` 真实绿。

### Task 4：dev 实测+报告+清理
部署 dev → `.env.dev` 白名单加 DATAGEN（带 `--env-file` 重建）→ 造 30 头×14 天 → 全量 recalculate → 评估 → 报告 `docs/reports/2026-11-05-simulation-baseline-calving-prep.md`（分层 MAE/bias 表、发情 TP/FP/FN 对比表、产前形态数据充分性结论、仿真口径声明）→ 清理（simulation 两表按 run 删 + 业务行删）。
验证：curl 证据逐项入报告；清理 leftover=0。

### Task 5：门禁+评审+PR
`precheck-ci.sh` 全绿 + 独立只读评审（P0=0）+ PR（标题不带工单号）+ 盯两流水线绿。
交付口径："仿真管道与方法学验证完成；真实效果待试点数据"。

## 明确不做
CalvingPredictionService 实现 / 全局 SynthesisService 文献化 / 发情时间窗归一化 / FCM/APNs / 真实数据评估（均另批，见需求单红线）。

## 主要文件
新增：迁移 1、SimulationHerdGenerationService、SimulationEvaluationService、DataGenSimulationController、SimulationDtos、EstrusSeriesReplayer、Journey+单测、文档 4 份。
修改：BaselineEvaluationService（复用回放组件）、messages*.properties、dev .env.dev（一行白名单）。
