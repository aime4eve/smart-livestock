# AI 健康智能路线图（Roadmap）

> 创建于 2026-06-19，brainstorming 产出。本文是**战略总账**：记录 AI 引入的方向决策、A→B→C 演进路线、遗留事项。Phase A 详细设计见单独的 design doc（待写）。
> 更新于 2026-06-19：① 架构从"sidecar"演进为"**三层 ai-platform 微服务**"（业界调研验证，见 §2）；② 确立"**按真实数据标准实现**"纪律（见决策 #2）。

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

## 2. 架构依据（业界调研 2026-06-19）

经联网调研，本架构核心骨架符合业界主流强共识：

- **[Google Agent 白皮书](https://developer.aliyun.com/article/1665861)**：编排层（orchestration layer）是 agent 认知架构核心；复杂度"可简可繁，有些就是基于决策规则的简单计算" → 支持 Phase A 最简编排。
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

Java 后端 ──HTTP──→ orchestration 端点
```

## 4. A→B→C 演进路线图

### Phase A — 无监督异常检测（Workflow 模式，三层骨架 + L1）
- **架构**：三层 ai-platform，orchestration/engine 透传，capability 填 L1 + router 双维度路由
- **数据**：当前时序数据流（`TelemetrySimulator` 产出），按真实数据标准实现检测全流程
- **算法**：STL（节律剥离）→ CUSUM（突变）→ 联合检测（router 按 N_eff 选 Mahalanobis/iForest）→ 融合
- **衔接**：异常分数持久化 → Phase B 标注候选池

### Phase B — 真实数据 + 标注（中期）
- **前置**：#55 真实遥测、#56 标注基础设施
- **主动学习**：用 Phase A 异常指数筛选高分样本优先标注
- 真实数据涌入后，router 的 iForest 档自然激活

### Phase C — 监督预测模型（远期）
- **前置**：真实数据攒够（数百头牛 × 数月）+ 标注（#55 天然规避循环论证）
- 监督式分类/预测；深度学习评估；特征从 Phase A 继承
- **L2/L3 capability 激活，orchestration 从 Workflow 升级为 Agent（多 agent 协同）**

## 5. 遗留事项总账（issue 双向链接）

| Issue | 事项 | 阶段 | 优先级 |
|-------|------|------|--------|
| [#55](https://github.com/aime4eve/smart-livestock/issues/55) | 真实遥测数据接入 | Phase B 前置阻塞 | high |
| [#56](https://github.com/aime4eve/smart-livestock/issues/56) | 健康标注数据基础设施 | Phase B 前置阻塞 | medium |
| [#57](https://github.com/aime4eve/smart-livestock/issues/57) | 监督式健康预测模型 | Phase C | low |
| [#58](https://github.com/aime4eve/smart-livestock/issues/58) | 发情检测（模式识别，非异常检测） | Phase C | low |
| [#59](https://github.com/aime4eve/smart-livestock/issues/59) | 疫病传播风险预测（contact_traces 图模型） | 探索 backlog | low |
| [#60](https://github.com/aime4eve/smart-livestock/issues/60) | LLM 牧场助手（对话 + RAG） | 探索 backlog（独立方向） | low |
| [#61](https://github.com/aime4eve/smart-livestock/issues/61) | 行为识别（需先补加速度原始时序采集） | backlog | low |

## 6. Phase A 设计待定项（design 阶段解决，非遗留）

- [ ] **个体自适应基线**：窗口长度 + 冷启动策略
- [ ] **触发时机**：事件驱动 + 去抖（倾向每头牛每 30–60min）
- [ ] **Phase A 评估方式**：无标注如何验证（人工抽检 / 对比规则引擎 / 合成标注集）
- [ ] **双轨前端展示**：规则告警（按病种）+ AI 异常指数（按偏离度）两视角如何不混乱
- [ ] **异常分数持久化表 schema**：前向兼容 Phase B 标注池
- [ ] **capability 接口抽象**：L1/L2/L3 统一契约（`predict`）

## 7. 关联文档

- Phase A 详细设计：`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`（待写）
- 现有健康上下文：`docs/superpowers/specs/2026-05-31-health-context-design.md`
- 遥测接入设计：`docs/superpowers/specs/2026-06-03-iot-telemetry-ingestion-design.md`、`docs/superpowers/specs/2026-06-04-telemetry-redesign-spec.md`

## 8. 关键认知修正（防再犯）

- **加速度计数据可得**：V25 只移除"独立 `ACCELEROMETER` 设备类型"，tracker/capsule 遥测仍上报 `accelX/Y/Z`。行为识别数据源可得，非"暂缓"。详见 #61。
- **实现纪律**：按真实数据标准实现，不为数据来源（模拟器/真实）加特殊分支。客观事实可记录为背景，但不渗透为代码逻辑。详见决策 #2。
- **架构三层非四层**：interfaces 是 capability 内部门面（registry+router），不独立成层 —— 贴 Google/Bain 主流。
