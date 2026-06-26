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

## 4. A→B→C 演进路线图

### Phase A — 无监督异常检测（Workflow 模式，三层骨架 + L1）
- ✅ **已交付**（2026-06-26，commit `79c5fd22`）：三层 ai-platform Python 微服务，14 task TDD，67 tests passed
- **架构**：三层 ai-platform，orchestration/engine 透传，capability 填 L1 + router 双维度路由
- **数据**：当前时序数据流（`TelemetrySimulator` 产出），按真实数据标准实现检测全流程
- **算法**：STL（节律剥离）→ CUSUM（突变）→ 联合检测（router 按 N_eff 选 Mahalanobis/iForest）→ 融合
- **未完成**：Java 后端集成（原 Plan 2）、Flutter 双轨前端（原 Plan 3）移入 Phase B
- **衔接**：异常分数持久化 → Phase B 标注候选池

### Phase B — 合成数据基座 + 全链路集成（中期）

> **修订（2026-06-26，决策 #10）**：原 Phase B 前置 = #55 真实遥测 + #56 标注基础设施。现 #55 短期不具备条件（无真实硬件数据源），Phase B 重新定位为**在合成数据上构建完整端到端链路**，不再被真实数据阻塞。

**核心认知转变**：`TelemetrySimulator` 从"临时占位"升级为**一等合成数据引擎**。其注入的已知异常标记（`abnormalTemp`/`abnormalMotility`/`inEstrus`）本身就是 ground-truth 标签，使标注和评估流程可以在合成数据上闭环验证。真实数据到达后只需重训练模型，不需改管道。

**交付物**：
1. **合成数据引擎增强**：`TelemetrySimulator` 升级为可控标注的数据生成器
   - 异常从静态 boolean 升级为**时序模式**（渐起→峰值→恢复曲线）
   - 异常类型扩展（低热/高热/慢性消化/急性消化/跛行），多维度关联（发热+活动降低=病态）
   - 导出 ground-truth 标签表（每头牛的异常时段、类型、严重度），供评估和标注
2. **标注基础设施（#56）**：在合成数据上闭环
   - `anomaly_scores.label` 列已在 Phase A design §6.1 预留
   - 标注 UI（牧工/兽医标注流程）；合成数据自动标注、真实数据人工标注，管道同构
3. **Java 后端集成（原 Plan 2）**：打通 ai-platform ↔ Java
   - V38 迁移（`anomaly_scores` + `health_snapshots` AI 列 + `alerts.source`）
   - `HealthAnomalyService` + `AnomalyScoreClient`（HTTP + 熔断降级）
   - `TelemetryEventConsumer` 下游接入（方案 A：复用现有 consumer）
4. **Flutter 双轨前端（原 Plan 3）**：规则告警 + AI 异常指数并排展示
5. **评估框架**：利用合成 ground-truth 计算精确率/召回率/F1
   - 合成数据的评估优势：knows exact ground truth → 可计算硬指标
   - 限制声明：合成数据上的指标不等于真实数据效果（design §8.1 仍有效），但在管道验证和回归测试层面有确定性价值

**退出条件**：全链路在合成数据上跑通（模拟器→入库→AI 检测→Java 写库→前端展示→标注闭环），且对模拟器注入的已知异常能正确检出。

### Phase C — 监督模型 + 行为识别（合成训练→真实迁移）（远期）

> **修订（2026-06-26，决策 #10）**：原 Phase C 前置 = Phase B 真实数据 + 标注攒够。现前置 = Phase B 完成（合成数据基座就绪）。监督模型可在合成标注数据上训练，真实数据到达后做迁移学习/微调。

1. **监督式健康分类器（#57）**：合成数据提供已知标签，可训练分类而非仅异常检测
   - 发热 vs 正常、消化异常 vs 正常等分类器；特征从 Phase A 继承
   - 真实数据到达后重训练/微调
2. **行为识别（#61 + #63）**：反刍/进食/躺卧/行走/产犊
   - 协议层（0x40 行为窗口上报）+ 合成行为数据生成
   - 先规则后 ML；详见 #63 行为分析设计
3. **发情模式识别（#58）**：从异常检测升级为模式识别
4. **真实数据迁移（#55 落地后）**：不再是阻塞项，变为增强项——重训练 + 验证合成训练模型在真实分布上的表现
5. **L2/L3 capability 激活**：orchestration 从 Workflow 升级为 Agent（多 agent 协同）
## 5. 遗留事项总账（issue 双向链接）

| Issue | 事项 | 阶段 | 优先级 |
|-------|------|------|--------|
| [#55](https://github.com/aime4eve/smart-livestock/issues/55) | 真实遥测数据接入 | ~~Phase B 阻塞~~ → Phase C 增强项（真实数据迁移） | ~~high~~ → medium |
| [#56](https://github.com/aime4eve/smart-livestock/issues/56) | 健康标注数据基础设施 | **Phase B 内**（合成数据上实现） | medium |
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
