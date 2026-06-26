# AI 健康智能路线图（Roadmap）

> 创建于 2026-06-19，brainstorming 产出。本文是**战略总账**：记录 AI 引入的方向决策、A→B→C 演进路线、遗留事项。Phase A 详细设计见单独的 design doc（待写）。
> 更新于 2026-06-19：① 架构从"sidecar"演进为"**三层 ai-platform 微服务**"（业界调研验证，见 §2）；② 确立"**按真实数据标准实现**"纪律（见决策 #2）。
> 更新于 2026-06-26：③ Phase A 已交付（Python 微服务，14 task TDD，67 tests passed）；④ **Phase B/C 数据策略修订**（决策 #10）——合成数据升为一等公民，Phase B 不再阻塞于 #55 真实遥测，全链路在合成数据上闭环；#55 从 Phase B 阻塞项降为 Phase C 增强项。

## 1. 决策链（防遗忘：为什么这么选）

| # | 决策点 | 结论 | 核心理由 |
|---|--------|------|----------|
| 1 | AI 引入方向 | **健康/发情预测**（4 候选选 1） | 数据资产最匹配（体温/蠕动/活动时序已分区），命中现有规则引擎痛点 |
| 2 | **实现纪律** | **按真实数据标准实现，不为数据来源加分支** | 当前时序数据由 `TelemetrySimulator` 生成（真实遥测接入在 #55/Phase 3），但 ai-platform **不区分数据来源**——无监督检测对模拟器数据和真实数据走完全一样的路径。不为"假数据"加临时阈值/架构验证/降级绑定等实现负担。监督模型的循环论证风险由 Phase C 前置 #55 天然规避，不进 Phase A 代码 |
| 3 | 演进策略 | **A→B→C 前向兼容** | 特征工程/分数 B 直接继承；A 高分样本 = B 标注种子（主动学习） |
| 4 | Phase A 形态 | **无监督分层异常检测** | 不需标注，按真实数据流程做时序异常检测 |
| 5 | 算法选型 | **router 按 per-individual 有效样本量 N_eff 分档路由**（规则 / Mahalanobis / iForest / 监督） | 不固定单一算法；小样本用稳健统计，大样本升级 iForest/DL。iForest vs Mahalanobis 不是二选一，是按规模自动选 |
| 6 | 平台形态 | **ai-platform 微服务**（独立，非 sidecar），能力分级 L1/L2/L3 + 降级 + 冷启动 | 统一所有 AI 方向；降级链是**通用可用性设计**（新牧场冷启动、模型未就绪） |
| 7 | 分层架构 | **三层**（orchestration / engine / capability），interfaces 作为 capability 内部门面（registry+router） | 贴 Google/Bain 主流共识；orchestration 对外、engine 执行/会话、capability 分级降级可插拔 |
| 8 | Phase A 模式 | **Workflow**（Anthropic 共识），三层为框架目标、最简透传编排 | Phase A 只有 L1 无 LLM/多 agent，用 Workflow 防过度设计 |
| 9 | Phase A 范围 | **体温+蠕动+活动三维联合 + 与规则引擎并行增强** | 不预设病种（符合无监督本质），与规则引擎零冲突 |
| 10 | **Phase B/C 数据策略** | **合成数据升为一等公民，Phase B 不阻塞于 #55** | `TelemetrySimulator` 的已知异常注入（`abnormalTemp`/`abnormalMotility`/`inEstrus`）本身就是 ground-truth 标签，使标注/评估/训练全链路在合成数据上闭环。#55 从 Phase B 阻塞项降为 Phase C 增强项（真实数据迁移）。合成数据与真实数据的唯一差距是"模型在真实分布上的效果"——这是模型验证问题，不是管道构建问题。详见 §4 |
| 11 | **双轨制架构** | **datagen 横向轨道 × Phase 能力里程碑** | datagen 独立为限界上下文后，路线图从线性列表升级为矩阵。datagen 是贯穿全周期的基础设施（v1→v2→v3），Phase A/B/C 是 AI 能力里程碑（每个依赖 datagen 某版本）。阶段边界是"AI 能做什么"，不是"数据从哪来"。详见 §4 |

## 2. 架构依据（业界调研 2026-06-19）

经联网调研，本架构核心骨架符合业界主流强共识：

- **[Google Agents 白皮书](https://www.kaggle.com/whitepaper-agents)**：编排层（orchestration layer）是 agent 认知架构核心；复杂度"可简可繁，有些就是基于决策规则的简单计算" → 支持 Phase A 最简编排。
- **[Bain 三层 Agentic 平台](https://www.bain.com/insights/the-three-layers-of-an-agentic-ai-platform/)**：应用与编排层是"指挥中心"，会话/上下文/状态归入编排层 → 印证三层、orchestration/engine 合并倾向。
- **[Anthropic《Building Effective Agents》](https://www.anthropic.com/research/building-effective-agents)**：Workflows（预定义路径）vs Agents（LLM 自主）；"最有效 agent 用简单可组合模式，非复杂框架" → Phase A 是 Workflow。
- **LLM Routing/Cascading**：[Model Cascading（cheap→capable 逐级升级）](https://www.getmaxim.ai/articles/top-5-llm-routing-techniques/) / [Three-Tier model stack](https://www.mindstudio.ai/blog/set-up-ai-model-router-llm-stack-c2610) / fallback configurable → L1→L3 分级降级是生产标准。
- **[Semantic Kernel](https://devblogs.microsoft.com/agent-framework/guest-blog-orchestrating-ai-agents-with-semantic-kernel-plugins-a-technical-deep-dive/)**：Plugins = standardized wrappers around agent capabilities → capability 可插拔。

**结论**：核心骨架（orchestration 对外 + engine 执行/会话 + capability 分级降级可插拔）是业界共识；原"四层"为个人细化，采纳**三层**贴主流；Phase A 按 Anthropic 共识用 Workflow，三层为演进目标（Phase C 真正需要多 agent 时再从 Workflow 升级为 Agent）。

## 3. 三层 ai-platform 结构（Phase A 实心/空心）

```
ai-platform（Python 微服务）
├── orchestration（编排层·对外入口）
│   端点：POST /ai/health/analyze 等
│   [Phase A: Workflow 透传 — 请求→TaskPlan→engine]
├── engine（执行层）
│   会话/上下文/agent 调度
│   [Phase A: 透传 — TaskPlan→调 capability 门面]
└── capability（能力层）
    ├── registry + router（门面 = 原 interfaces）
    │   路由维度：① 能力可用性（L3→L2→L1 降级，通用可用性）
    │            ② 数据规模（per-individual N_eff 分档选算法）
    │   [Phase A 实心：2 档路由（规则 / Mahalanobis）]
    ├── L1 health_anomaly（STL+CUSUM+按规模路由的联合检测）[Phase A 实心 ★核心]
    ├── L2 深度学习 [Phase A 接口占位]
    └── L3 LLM [Phase A 接口占位]

Java 后端 ──HTTP──→ orchestration 端点（Java 写 anomaly_scores/snapshots/alerts）
```

**为何 Phase A 就建三层（回应 YAGNI 质疑，评审 #2）**：orchestration/engine 在 Phase A 透传，是为了**固定对外接口契约**（端点 URL、engine→capability 调用协议），使 Phase B/C 填充多 agent / L2 / L3 时**不破坏调用方**。若 Phase A 只建一层直接调 capability，Phase C 升级 Agent 编排时外部调用方须重写——透传是接口投资，非空壳。

**数据写入路径（评审小问题）**：Java 后端单向调 ai-platform 取 `PredictResponse`，由 **Java 后端**写 `anomaly_scores` / `health_snapshots` / `alerts`（见 design doc §3 数据流）。ai-platform 不回调 Java，无出向依赖。

## 4. 演进路线图（双轨制：datagen 横向轨道 × Phase 能力里程碑）

> **架构修订（2026-06-26）**：datagen 独立为限界上下文后，路线图从线性列表升级为**矩阵结构**。datagen 是一条**贯穿所有阶段的横向基础设施轨道**，有自己的版本演进；Phase A/B/C 是 AI 能力里程碑，每个里程碑依赖 datagen 的某个版本。

### datagen 横向轨道（基础设施，贯穿全周期）

| 版本 | 范围 | 服务于 | 设计文档 |
|------|------|--------|---------|
| **v1** | 合成数据引擎（Scenario 驱动 + 时序异常曲线）+ ground-truth 标签表 + 评估框架 | Phase B | [`2026-06-26-datagen-context-design.md`](./2026-06-26-datagen-context-design.md) |
| **v2** | 行为数据生成（反刍/进食/躺卧波形）+ 多分类评估 + 真实数据适配层 | Phase C | 待设计 |
| **v3** | 数据质量监控 + 数据血缘（真实数据到来后扩张为广义数据治理） | 未来 | — |

> datagen 不是"做完 Phase B 就结束"的子任务。Phase C 需要它生成行为数据、做多分类评估，未来真实数据到来需要它做质量监控。它和 AI 能力轨道**平行演进**。

### Phase A — 无监督异常检测（Workflow 模式，三层骨架 + L1）
- ✅ **已交付**（2026-06-26，commit `79c5fd22`）：三层 ai-platform Python 微服务，14 task TDD，67 tests passed
- **架构**：三层 ai-platform，orchestration/engine 透传，capability 填 L1 + router 双维度路由
- **数据**：当前时序数据流（`TelemetrySimulator` 产出），按真实数据标准实现检测全流程
- **算法**：STL（节律剥离）→ CUSUM（突变）→ 联合检测（router 按 N_eff 选 Mahalanobis/iForest）→ 融合
- **衔接**：异常分数持久化 → Phase B 标注候选池

### Phase B — L1 端到端集成（AI 能力里程碑）

> **目标**：L1 异常检测从孤岛 Python 服务变为**完整端到端可用产品**——合成数据生成 → 入库 → AI 检测 → Java 写库 → 前端展示 → 标注/评估闭环。

**依赖**：datagen-v1（合成引擎 + ground truth + 评估）

**交付物**：

| # | 交付物 | 上下文 | 说明 |
|---|--------|--------|------|
| 1 | datagen-v1 | **datagen**（新建） | 迁移 `TelemetrySimulator` → Scenario 驱动合成 + GroundTruthLabel + EvaluationService。详见 [datagen 设计](./2026-06-26-datagen-context-design.md) |
| 2 | Java 后端集成 | **health**（扩展） | V38 迁移（`anomaly_scores` + `health_snapshots` AI 列 + `alerts.source`）+ `HealthAnomalyService` + `AnomalyScoreClient`（HTTP 熔断降级）+ `TelemetryEventConsumer` 下游接入 |
| 3 | Flutter 双轨前端 | **Mobile**（扩展） | 规则告警 + AI 异常指数并排展示 |
| 4 | 评估报告 | **datagen** | EvaluationService 消费 datagen 标签 × health 预测，输出精确率/召回率/F1 |

**退出条件**：全链路在合成数据上闭环（datagen 场景→IoT 入库→ai-platform 检测→Java 写库→前端展示→评估报告），且对注入的已知异常（如 HIGH_FEVER）能正确检出。

> **标注基础设施（#56）移至 Phase C**（2026-06-26 修订）：合成数据的 ground truth 在生成时即确定（`source=SYNTHETIC`），Phase B 无需人工标注环节。标注 UI 和 `source=MANUAL` 流程的真正使用场景是真实数据到来——那时兽医/牧工需要确认某头牛是否真的生病。`anomaly_scores.label` 列继续保留（Phase A 已预留 NULL），不投入建设。

**为什么 datagen-v1 不在 Phase B 编号"第一块"**：它是 Phase B 的**前置基础设施**，不是 Phase B 内部的线性第一步。交付物 2-4 依赖它，但它的生命周期超出 Phase B——Phase C 还要扩展为 v2。

### Phase C — 监督模型 + 行为识别（AI 能力里程碑）

> **目标**：AI 从无监督异常检测升级为**监督分类 + 行为识别**，并在真实数据到来时做迁移。

**依赖**：datagen-v2（行为数据生成 + 多分类评估）

**交付物**：

| # | 交付物 | 上下文 | 说明 |
|---|--------|--------|------|
| 1 | datagen-v2 | **datagen**（扩展） | 行为波形合成（反刍咀嚼节律/进食 biting/躺卧静态分量）+ 多分类 confusion matrix 评估 + 真实数据适配层（#55 落地后切换数据源） |
| 2 | 监督式健康分类器（#57） | **ai-platform** L2 | 合成标注数据训练分类（发热/消化/正常），特征从 Phase A 继承；真实数据到达后重训练 |
| 3 | 行为识别（#61 + #63） | **ai-platform** + **iot** | 反刍/进食/躺卧/行走/产犊；协议层（0x40）+ 合成行为数据（datagen-v2）+ 先规则后 ML；详见 [#63 设计](./2026-06-23-behavior-analysis-design.md) |
| 4 | 发情模式识别（#58） | **ai-platform** | 从异常检测升级为模式识别 |
| 5 | 真实数据迁移（#55） | **datagen** + **ai-platform** | #55 从阻塞项变为增强项：datagen 切换数据源 + ai-platform 重训练 + 验证合成训练模型在真实分布上的表现 |
| 6 | L2/L3 capability 激活 | **ai-platform** | orchestration 从 Workflow 升级为 Agent（多 agent 协同） |
| 7 | 标注基础设施（#56） | **datagen** + **health** | 真实数据到来后兽医/牧工标注流程：标注 UI + `source=MANUAL` 标签 + 主动学习候选池（`anomaly_scores.label` 高分未标注行优先标注）。合成数据无需此环节，从 Phase B 移入 |

### 阶段依赖总览

```
datagen 轨道:  v1 ────────────────────── v2 ────────────── v3
                  │                        │                  │
Phase A (done)    │                        │                  │
Phase B ◄─────────┘                        │                  │
Phase C ◄──────────────────────────────────┘                  │
未来 ◄────────────────────────────────────────────────────────┘
```

**关键认知**：阶段边界是**AI 能做什么**，不是**数据从哪来**。datagen 负责数据可用性（合成→真实无缝切换），AI capability 负责检测/分类/预测能力。两者解耦演进。
## 5. 遗留事项总账（issue 双向链接）

| Issue | 事项 | 阶段 | 优先级 |
|-------|------|------|--------|
| [#55](https://github.com/aime4eve/smart-livestock/issues/55) | 真实遥测数据接入 | ~~Phase B 阻塞~~ → Phase C 增强项（真实数据迁移） | ~~high~~ → medium |
| [#56](https://github.com/aime4eve/smart-livestock/issues/56) | 健康标注数据基础设施 | ~~Phase B~~ → Phase C（真实数据到来后才需人工标注） | medium |
| [#57](https://github.com/aime4eve/smart-livestock/issues/57) | 监督式健康预测模型 | Phase C（合成训练→真实迁移） | low |
| [#58](https://github.com/aime4eve/smart-livestock/issues/58) | 发情检测（模式识别，非异常检测） | Phase C | low |
| [#59](https://github.com/aime4eve/smart-livestock/issues/59) | 疫病传播风险预测（contact_traces 图模型） | backlog | — |
| [#60](https://github.com/aime4eve/smart-livestock/issues/60) | LLM 牧场助手（对话 + RAG） | backlog（独立方向） | — |
| [#61](https://github.com/aime4eve/smart-livestock/issues/61) | 行为识别（需先补加速度原始时序采集） | ~~backlog~~ → Phase C（合成训练先行） | low |
| [#63](https://github.com/aime4eve/smart-livestock/issues/63) | 牲畜行为分析（反刍/进食/睡眠/产犊） | Phase C（与 #61 合并） | low |

## 6. Phase A 设计待定项 → 已交付 design doc（评审核实）

> Phase A design doc（`2026-06-19-ai-health-anomaly-detection-design.md`）已交付，下列待定项全部解决，标注对应章节。评审 #4/#5/#6（router 阈值、冷启动兜底、触发时机）已在 §4.2/§4.3 落定。

| 原待定项 | 状态 | design doc 章节 |
|---------|------|----------------|
| 个体自适应基线（窗口+冷启动） | ✅ | §4.2（14 天基线 + 群体兜底） |
| 触发时机（去抖） | ✅ | §3（每头牛 30–60min 窗口） |
| 评估方式（无标注） | ✅ | §8 四法 + §8.1 不可外推风险 |
| 双轨前端展示 | ✅ | §6.3（source 分组双轨） |
| 异常分数表 schema | ✅ | §6.1（anomaly_scores + 标注预留） |
| capability 接口抽象 | ✅ | §5.1（L1/L2/L3 同构契约） |
| router N_eff 分档阈值（评审 #4/#5 补） | ✅ | §4.3（<30 / 30–200 / ≥200 / +标注） |
| N_eff 极小冷启动兜底（评审 #6 补） | ✅ | §4.3 + §4.2（<30 纯规则 + 群体基线） |

## 7. 关联文档

- Phase A 详细设计：`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`（待写）
- 现有健康上下文：`docs/superpowers/specs/2026-05-31-health-context-design.md`
- 遥测接入设计：`docs/superpowers/specs/2026-06-03-iot-telemetry-ingestion-design.md`、`docs/superpowers/specs/2026-06-04-telemetry-redesign-spec.md`

## 8. 关键认知修正（防再犯）

- **加速度计数据可得**：V25 只移除"独立 `ACCELEROMETER` 设备类型"，tracker/capsule 遥测仍上报 `accelX/Y/Z`。行为识别数据源可得，非"暂缓"。详见 #61。
- **实现纪律**：按真实数据标准实现，不为数据来源（模拟器/真实）加特殊分支。客观事实可记录为背景，但不渗透为代码逻辑。详见决策 #2。
- **架构三层非四层**：interfaces 是 capability 内部门面（registry+router），不独立成层 —— 贴 Google/Bain 主流。
- **合成数据非降级**（2026-06-26 修订）：原路线图将模拟器数据定位为临时占位、必须等真实数据。修订后认识到：合成数据的已知异常标签使它在管道开发、标注、评估方面优于真实数据（真实数据反而需要人工标注才知道 ground truth）。合成数据无法证明的是模型在真实分布上的效果——但这是模型验证问题，不是管道构建问题。两者应分开管理。详见决策 #10。
