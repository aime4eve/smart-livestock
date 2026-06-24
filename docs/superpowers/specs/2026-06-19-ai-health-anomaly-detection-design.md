# AI 健康异常检测设计（Phase A）

> 创建于 2026-06-19，brainstorming 产出。本文是 **Phase A 战术详设**；战略总账（方向决策、A→B→C 路线、遗留事项）见 [`2026-06-19-ai-health-roadmap.md`](./2026-06-19-ai-health-roadmap.md)。
> 实现纪律：**按真实数据标准实现，不为数据来源加分支**（roadmap 决策 #2）。

## 0. 摘要

Phase A 在三层 ai-platform 微服务骨架上，实现 **L1 无监督健康异常检测**：对每头牛的体温+蠕动+活动三维时序，跑 STL（节律剥离）+ CUSUM（突变）+ 联合检测（按规模路由 Mahalanobis/iForest）分层算法，输出"健康异常指数"，与现有规则引擎**并行增强**。Phase A 用 Workflow 透传编排（Anthropic 共识），三层为框架目标，L2/L3 接口占位。

**关联**：
- 路线图：[`2026-06-19-ai-health-roadmap.md`](./2026-06-19-ai-health-roadmap.md)
- 数据来源对接：[#55 真实遥测数据接入](https://github.com/aime4eve/smart-livestock/issues/55)（见本文 §7）
- 标注池前置：[#56 健康标注数据基础设施](https://github.com/aime4eve/smart-livestock/issues/56)

## 1. 背景与 Phase A 范围

**背景**：现有健康分析（发热/消化/发情/疫病）全是阈值规则引擎（如发热基线写死 38.50°C），误报漏报痛点明显。Phase A 用无监督检测**并行增强**（非替代）规则引擎，发现规则未覆盖的异常模式。

**Phase A 范围**：
- 检测维度：**体温 + 蠕动 + 活动三维联合**（数据现成，最能体现分层算法价值）
- **不含**：发情（是预期内变化非异常，留 Phase C 监督模型）、疫病（靠接触链图模型，#59）
- 与规则引擎关系：**并行增强**（规则按病种、AI 按偏离度，两个视角互补，零冲突）

## 2. 架构：三层 ai-platform

```
ai-platform（Python 微服务）
├── orchestration（编排层·对外入口）
│   端点：POST /ai/health/analyze
│   [Phase A: Workflow 透传 — 请求→TaskPlan→engine]
├── engine（执行层）
│   会话/上下文/agent 调度
│   [Phase A: 透传 — TaskPlan→调 capability 门面]
└── capability（能力层）
    ├── registry + router（门面）
    │   路由维度：① 能力可用性（L3→L2→L1 降级）② 数据规模（N_eff 分档选算法）
    ├── L1 health_anomaly（STL+CUSUM+联合检测）[Phase A 实心 ★]
    ├── L2 深度学习 [Phase A 接口占位，is_available()=False]
    └── L3 LLM [Phase A 接口占位，is_available()=False]

Java 后端 ──HTTP──→ orchestration
```

**Phase A 实心/空心**：orchestration/engine 透传（接口定死，未来填多 agent 不改外部调用方）；capability 填 L1 + router；L2/L3 占位。

**分层依据**：贴 Google/Bain 三层主流共识；interfaces 作为 capability 内部门面（registry+router），不独立成层。详见 roadmap §2（业界调研）。

## 3. 数据流

```
遥测（TelemetrySimulator / 真实设备）
  → TelemetryIngestionService → 时序表（temperature_logs / rumen_motility_logs / activity_logs）
  → telemetry-received (RocketMQ)
  → [现有] TelemetryEventConsumer (consumerGroup=health-telemetry-consumer)
      → HealthApplicationService.processTelemetry(...)        # 规则引擎：写规则告警
      → [Phase A 新增·同流下游] 调 HealthAnomalyService
          → 聚合去抖（Redis key=ai:dedup:{livestock_id}, TTL 60min）
          → HTTP POST /ai/health/analyze → ai-platform
              ai-platform 直连 PG 只读，按 livestock_ids + window 查时序窗口
              orchestration → engine → router(双维度) → L1 capability
              → STL+CUSUM+联合检测 → PredictResponse
          ← 返回
      → 写 anomaly_scores（时序）+ upsert health_snapshots.ai_*（最新态）
      → anomaly_score 超阈 → 写 alerts (source=AI, type=AI_ANOMALY/TEMPERATURE_ABNORMAL)
  → 前端双轨展示（规则 + AI 异常指数）
```

### 3.1 与现有 `TelemetryEventConsumer` / `HealthApplicationService` 的接入关系（评审补强 #1）

`telemetry-received` **已被现有 consumer 消费**（`health/infrastructure/mq/TelemetryEventConsumer`，`consumerGroup=health-telemetry-consumer`），委托 `HealthApplicationService.processTelemetry(deviceId, livestockId, farmId, ...)` 写规则告警。

Phase A **不新增第二个 consumer**（避免重复消费 / 职责重叠）。采用 **方案 A：复用现有流程**——`HealthAnomalyService` 作为 `processTelemetry` 的下游被调用：

- `HealthApplicationService.processTelemetry` 末尾追加 `healthAnomalyService.assess(livestockId, farmId)`；
- 去抖 + ai-platform 调用 + 写库全在 `HealthAnomalyService` 内；
- 规则引擎与 AI 检测**串行同流**，共享同一遥测事件，零重复消费。

> 方案 B（独立 consumer group `health-anomaly-consumer`）备选：与规则引擎解耦、独立扩缩容，代价是去抖状态需独立管理。Phase A 用方案 A 足够；并发压力出现时再切 B。

**触发时机**：事件驱动 + 去抖。`processTelemetry` 被调用时，按 `livestock_id` 聚合，每头牛每 30–60min 跑一次窗口检测（健康指标 30min 粒度，无需毫秒级实时）。

**去抖状态存储（评审补强 #5）**：Redis（项目已有，见 §9）。key = `ai:dedup:{livestock_id}`，value = 上次触发时间戳，TTL 60min。`processTelemetry` 命中未过期 key 则跳过本次 AI 检测（规则引擎照常执行）。重启后 TTL 自然过期，最坏 60min 后恢复触发。

## 4. 算法与特征工程

### 4.1 输入
per-livestock 三维时序窗口：`temperature`（CAPSULE）、`rumen_motility`（CAPSULE）、`activity_index`（TRACKER）。窗口 = 近 24h（检测）+ 过去 14 天（建基线），30min 粒度。

### 4.2 特征工程（★ Phase A/B 共享，前向兼容核心）

- **个体自适应基线**：每头牛用过去 14 天数据建个人基线（中位数 + MAD 稳健估计）。冷启动（新牛 <14 天）用同群/同品种群体基线兜底。在检测时**替代规则引擎写死的全局 38.50** 作为判据。
- **基线与 `baseline_temp` 生成列的边界（评审补强 #3）**：AI 个体基线是 **ai-platform 内部特征**，**不回写** `temperature_logs.baseline_temp` / `health_snapshots.baseline_temp`——这两列仍默认 38.50、服务规则引擎的 `delta` 生成列（V20：`delta GENERATED ALWAYS AS (temperature - baseline_temp) STORED`）。AI 分数走 §6.2 新增的 `ai_anomaly_score` 等独立列，与 `delta` 并存、语义不混淆。回写基线会触发写放大（每次入库先查该牛基线）并破坏生成列约束。
- **每维度滑窗特征**（精简到核心，防过拟合）：每维 3 特征（24h 均值相对基线稳健 z-score、24h 趋势斜率、近 6h STL residual 峰值）× 3 维 = 9 特征 + CUSUM 分数 ≈ **10 特征**。
- **STL 残差特征**：每维度 STL 分解（周期 24h），取 residual 分量。

### 4.3 三层检测器

| 层 | 算法 | 输入 | 输出 | 解决盲区 |
|----|------|------|------|---------|
| L1a 节律剥离 | STL 分解（周期 24h） | 原始时序 | 去昼夜节律 residual | "下午体温正常升高不是病" |
| L1b 突变检测 | CUSUM 变点 | residual 序列 | 变点分数 | "突然发病式跳变" |
| L1c 多维联合 | **router 按 N_eff 路由**：Mahalanobis（小样本）/ iForest（大样本） | 10 维特征向量 | 异常分数 | "单维不超阈但多维同时偏离" |

**L1c 按 per-individual 有效样本量 N_eff 分档路由**（roadmap 决策 #5）：
- N_eff < 30：纯规则 + 群体基线（冷启动）
- 30 ≤ N_eff < 200：per-individual Mahalanobis（**Phase A 当前数据落这档**）
- N_eff ≥ 200：iForest 可行（Phase B 真实数据积累后激活）
- 大样本 + 标注：监督模型（Phase C）

**N_eff 定义（评审补强 #4）**：过去 14 天内、三维时序（体温/蠕动/活动）**均非空**的 30min 槽位数。某维缺失的槽位不计入。N_eff 反映"可用于多维联合分析的有效观测量"，而非原始点数。

**路由切换迟滞（评审补强 #4）**：分档切换带 ±20% hysteresis 防临界抖动——升档需 N_eff 持续 ≥200（非单次碰线），降档需持续 <160。否则同一头牛在临界值会因个别缺失槽位导致算法来回切换。

> **Phase A 落地状态（2026-06-21 评审 H2）**：迟滞**未实现**，`route_by_neff` 为纯阈值。原因：迟滞需 per-individual 跨次状态（"同一头牛持续 N_eff"），Phase A 无 DB 写权限、单实例进程内 dict 多实例失效。Plan 2 Java 定时批量接入时，按 `livestock_id` 分键补状态化迟滞（Redis/PG 持久态）。临界 N_eff 抖动后果：29↔31 间 joint 项开关致分数波动，若 Java 端有告警去抖/时间窗聚合可吸收。

> Mahalanobis vs iForest 不是二选一，是按规模自动选。Phase A 实现 2 档（规则 / Mahalanobis），iForest/监督档预留接口。

### 4.4 融合与输出
- **先归一化再加权（评审补强 #10）**：三层量纲不同（STL residual、CUSUM 累积量、Mahalanobis 距离），直接加权会被大量纲项主导。各层分数先归一化到 [0,1]：STL residual 用近 14 天经验 99 分位数、CUSUM 用历史最大值、Mahalanobis 用 χ² 分布 CDF（自由度=特征维数）。
- 加权融合：`anomaly_score = w₁·stl + w₂·cusum + w₃·联合`，**Phase A 初始权重 w₁=0.3, w₂=0.3, w₃=0.4**（联合层略高，因它捕获多维耦合盲区），真实数据积累后标定。
- `anomaly_type` 按主导层：`circadian_disruption` / `abrupt_change` / `multivariate` / `normal`
- `contributions`：各层 + 各维度贡献度（可解释）

## 5. 接口契约

### 5.1 capability 统一契约（L1/L2/L3 同构）
```python
class Capability(ABC):
    level: CapabilityLevel
    def is_available(self, ctx) -> bool        # 冷启动/就绪（降级依据）
    def predict(self, req: PredictRequest) -> PredictResponse

@dataclass
class PredictResponse:
    anomaly_score: float; anomaly_type: str; contributions: dict
    capability_used: str; n_eff: int; model_meta: dict
```

### 5.2 orchestration 端点
```
POST /ai/health/analyze          # 批量
  Body: { tenant_id, farm_id, livestock_ids:[int], window_hours:24 }
  Resp: { request_id, results:[PredictResponse] }
POST /ai/health/analyze/{id}     # 单头
GET  /ai/health/live             # 存活探活（与业务 /ai/health/analyze 区分，评审补强 #9）
```
> 请求体只含 ID + 窗口参数（薄 body）；时序窗口数据由 **ai-platform 直连 PostgreSQL 只读**自行查询（见 §9.1），避免大 payload 经 HTTP 传输。

## 6. 持久化

### 6.1 `anomaly_scores` 表（新建，归属 V38，前向兼容标注池）
```sql
CREATE TABLE anomaly_scores (
    id BIGSERIAL, tenant_id BIGINT NOT NULL, farm_id BIGINT NOT NULL,
    livestock_id BIGINT NOT NULL,
    window_start TIMESTAMP NOT NULL, window_end TIMESTAMP NOT NULL,
    anomaly_score DECIMAL(4,3) NOT NULL, anomaly_type VARCHAR(32) NOT NULL,
    contributions JSONB, capability_used VARCHAR(32) NOT NULL,
    n_eff INTEGER, model_meta JSONB,
    label VARCHAR(16), labeled_by BIGINT, labeled_at TIMESTAMP,  -- 前向兼容 Phase B 标注池（预留 NULL）
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);  -- 按月分区，对齐现有 health 时序表

-- 查询索引（评审补强 #8）：分区表按 created_at 分区，业务查询需次级索引
CREATE INDEX idx_anomaly_livestock ON anomaly_scores (farm_id, livestock_id, created_at DESC);
CREATE INDEX idx_anomaly_unlabeled ON anomaly_scores (farm_id, anomaly_score DESC)
    WHERE label IS NULL;  -- 主动学习候选池（§10）：高分未标注行，避免全分区扫
```

### 6.2 `health_snapshots` 扩展（归属 V38，前端一次读到 AI 分数）
```sql
ALTER TABLE health_snapshots ADD COLUMN ai_anomaly_score DECIMAL(4,3);
ALTER TABLE health_snapshots ADD COLUMN ai_anomaly_type  VARCHAR(32);
ALTER TABLE health_snapshots ADD COLUMN ai_assessed_at   TIMESTAMP;
```

### 6.3 `alerts` 融合（加 source 列 + 扩 type 枚举）

> 归属迁移：**`V38__add_ai_anomaly_tables.sql`**（§6.1 anomaly_scores 新建 + §6.2 health_snapshots AI 列 + 本节 alerts source/type，三组合并到一个迁移）。Phase A 编号 **V38**（当前最新 V37；评审补强 #2，非"对齐 V26"）。

```sql
ALTER TABLE alerts ADD COLUMN source VARCHAR(16) NOT NULL DEFAULT 'RULE';
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source CHECK (source IN ('RULE','AI'));
-- 扩 type 枚举：约束名 chk_alerts_type（V2 建表、V26 已重建过），先 drop 再加 AI_ANOMALY
-- ⚠️ V26 现有枚举共 7 值：FENCE_BREACH/FENCE_APPROACH/ZONE_APPROACH/TEMPERATURE_ABNORMAL/DIGESTIVE_ABNORMAL/ESTRUS/EPIDEMIC
--    重建时必须全量保留（含 FENCE_APPROACH/ZONE_APPROACH），只追加 AI_ANOMALY，否则破坏围栏接近告警
ALTER TABLE alerts DROP CONSTRAINT chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH','FENCE_APPROACH','ZONE_APPROACH','TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL','ESTRUS','EPIDEMIC','AI_ANOMALY'));
```
- `anomaly_score` 超阈 → 写 `alerts`（`source='AI'`），type 映射：`abrupt_change/circadian_disruption → TEMPERATURE_ABNORMAL`、`multivariate → AI_ANOMALY`（新枚举）。注：原映射 `BEHAVIOR_ABNORMAL` 已被 V26 改名为 `DIGESTIVE_ABNORMAL`，不可再用。
- 双轨：规则告警（`RULE`，按病种）+ AI 告警（`AI`，按 anomaly_type），前端按 `source` 分组

## 7. ★ 与设备数据采集（#55）的对接关系 ★

> 本节专门说明 Phase A 设计与未实施的 [#55 真实遥测数据接入](https://github.com/aime4eve/smart-livestock/issues/55) 的对接关系。这是关键依赖点，须显式记录。

### 7.1 数据来源现状
Phase A 的输入时序数据当前由 `TelemetrySimulator` 产出 → `TelemetryIngestionService` → 时序表。**ai-platform 按真实数据标准实现，不区分数据来源**（实现纪律，roadmap 决策 #2）——对检测算法而言，模拟器数据和真实设备数据走完全一样的路径。

### 7.2 #55 完成后的对接（零改动）
#55 实施后，数据流变为：**真实设备（LoRa/NS 平台）→ `TelemetryIngestionService` → 时序表**。由于：
- ai-platform **只消费时序表**，不直接对接设备/模拟器；
- `TelemetryIngestionService` 是统一入口（模拟器和真实设备都经它写入时序表）；

→ **ai-platform 代码零改动**即可对接真实数据。这正是"实现与数据来源解耦"的收益。

### 7.3 字段契约（#55 实施时必须保证）
ai-platform L1 依赖以下时序表字段，#55 实施时真实数据**必须写入这些字段**（已核实表结构，V20）：

| 时序表 | 依赖字段 | 说明 |
|--------|---------|------|
| `temperature_logs` | `livestock_id`, `temperature`, `recorded_at` | 瘤胃体温时序 |
| `rumen_motility_logs` | `livestock_id`, `frequency`, `recorded_at` | 蠕动频率时序 |
| `activity_logs` | `livestock_id`, `activity_index`, `recorded_at` | 活动量时序 |

> #55 若改变字段命名/粒度，须同步本设计；否则 ai-platform 无法消费。

### 7.4 依赖关系
- **Phase A 不阻塞于 #55**：用现有数据流（模拟器）跑通架构与算法。
- **真实效果评估 + Phase B（真实数据 + 标注）的前置 = #55**：Phase A 的"真实确诊级"评估、Phase B 的监督模型训练，都需 #55 提供真实数据。
- **循环论证规避**：监督模型（Phase C）用规则造数据训练才有循环论证风险；该风险由 Phase C 前置 #55 天然规避，**不进 Phase A 代码**。

## 8. 评估方式（无标注场景）

| 方法 | 做法 | Phase A |
|------|------|---------|
| 对比规则引擎 | AI 高分牛 ∩ 规则告警牛重叠度（一致性）+ AI 独有检出（增量） | ✅ 主力，自动持续 |
| 专家抽检 | 兽医看 AI 高分牛时序曲线，判断异常模式合理性 | ✅ 验证领域认知 |
| 自洽性监控 | 分数稳定性、分布合理性 | ✅ 持续监控 |
| 合成注入 | 注入已知异常曲线测召回 | ✅ 可控验证 |
| 真实确诊 ground truth | 兽医确诊 + 标注 | ⏳ Phase B（前置 #55） |

### 8.1 评估不可外推风险（评审补强 #1）

Phase A 在 `TelemetrySimulator` 数据上的指标（一致性 / 召回 / 分数分布）**只验证代码路径与算法自洽性，不等于真实数据上的效果**。模拟器时序可能过于理想化或平滑，导致异常检出率、分数分布偏离真实场景，给出虚假信心。

> 这是路线图决策 #2"按真实数据标准实现"的边界澄清：**代码不分枝 ≠ 评估结论可外推**。真实效果评估必须等 #55 接入后重做（见 §7.4）。

## 9. 部署与数据访问

```
docker-compose.yml 新增 ai-platform 服务：
  Python 3.11 + FastAPI + scikit-learn + pyod + ruptures + statsmodels
  port 8000，与 app 同网络
application.yml（Java）：ai.platform.url=http://ai-platform:8000, timeout-ms 5000, circuit-breaker enabled
AnomalyScoreClient（Java）：HTTP + 熔断 + 降级（ai-platform 不可用 → 退回规则引擎）
```

### 9.1 ai-platform 数据访问层（评审补强 #6）

ai-platform 需读 Java 后端的时序表（§3、§7.3）。**采用方案 A：ai-platform 直连 PostgreSQL 只读**：

- 独立只读 DB 账号，仅授予 `temperature_logs` / `rumen_motility_logs` / `activity_logs` 三表的 `SELECT`；
- 按 request body 的 `livestock_ids` + `window_hours` 自行查窗口数据，做特征工程 + 检测；
- 数据归属仍在 Java/PG（ai-platform 只读不写，不持有数据持久化）。

**不选方案 B（Java 组装特征传 body）的原因**：STL 分解、Mahalanobis、基线估计是 Python ML 栈（statsmodels/scikit-learn）能力，挪到 Java 端需重写且失去库支持；且 24h×30min×3维 ≈ 144 点/牛的原始时序经 HTTP 传输是带宽浪费。薄 body + 直连只读查询是更干净的边界。

> 限界上下文隔离：时序表本就是多上下文共享的"数据湖"（health、analytics 均读），ai-platform 只读这三张表不破坏隔离。AI 结果回写（anomaly_scores / snapshots / alerts）仍由 Java 后端执行，ai-platform 无写权限。

## 10. 前向兼容 B 的预留

| 预留点 | 位置 | Phase B/C 激活方式 |
|--------|------|-------------------|
| 标注池钩子 | `anomaly_scores.label` 三列 | Phase B 牧工标注 `UPDATE` |
| capability 同构契约 | L1/L2/L3 同接口 | Phase B/C 激活 L2/L3，调用方零改动 |
| router 双维度 | 能力可用性 + 数据规模 | Phase B iForest 档自然激活 |
| 特征工程独立模块 | Phase A/B 共享 | Phase C 监督模型复用 |
| 降级链 L3→L2→L1 | router | 高级层就绪自动启用 |
| 主动学习衔接 | `anomaly_scores` 高分未标注行 | Phase B 标注候选池 |
| 模型版本追溯 | `model_meta` JSONB | Phase B/C 迭代回溯 |

## 11. Phase A 交付清单

| 层 | 交付物 |
|----|--------|
| Python·ai-platform | 三层骨架 + L1 health_anomaly（STL+CUSUM+Mahalanobis，router 2 档）+ `/ai/health/analyze` |
| DB·Flyway | `anomaly_scores`（新表）+ `health_snapshots` AI 列 + `alerts` source 列 |
| Java·health | `HealthAnomalyService` + `AnomalyScoreClient`（HTTP+熔断） |
| 前端·Flutter | 双轨展示（规则告警 + AI 异常指数） |
| 评估 | 对比规则 + 自洽性监控 + 合成注入测试 |

## 12. 遗留与依赖

- **#55 真实遥测数据接入**（high）：Phase A 数据来源"真实化"的对接点（见 §7），Phase B 前置。
- **#56 健康标注数据基础设施**（medium）：Phase B 前置；`anomaly_scores.label` 已预留钩子。
- 其余 AI 方向（#57–#61）见 roadmap §5。
