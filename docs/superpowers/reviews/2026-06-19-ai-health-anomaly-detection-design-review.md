# 评审：AI 健康异常检测设计（Phase A）

> 评审对象：`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`
> 评审日期：2026-06-19
> 评审方式：文档内容与代码库（`smart-livestock-server/` 现有迁移、Java 类）交叉核实

## 总体评价

作为 Phase A 战术详设，本文完成度高：三层架构、算法分层（STL+CUSUM+联合检测）、特征工程（10 特征）、接口契约、持久化 schema、评估方式、#55 对接关系、前向兼容预留都覆盖到了。§7（与 #55 对接）尤其扎实，字段契约经过核实与 V20 表结构一致。

但评审中发现 **1 个重大遗漏**（未提及已存在的 `TelemetryEventConsumer`）、**2 个与代码库不符的事实**、**若干设计待补强点**。下面按严重程度分级。

---

## 🔴 重大问题（必须改）

### 1. §3 完全没提到已存在的 `TelemetryEventConsumer`，新 `HealthAnomalyService` 接入点不清

**事实核实**：health 上下文**已存在** `src/main/java/com/smartlivestock/health/infrastructure/mq/TelemetryEventConsumer.java`，它：
- 已经在消费 `telemetry-received` topic（`consumerGroup = "health-telemetry-consumer"`）；
- 委托给 `HealthApplicationService.processTelemetry(...)` 处理遥测、写规则告警。

**文档问题**：§3 数据流画的是"`telemetry-received` → `HealthAnomalyService`（Java·health 上下文）"，仿佛要新建一个消费入口。但文档**完全没提**现有的 `TelemetryEventConsumer` 和 `HealthApplicationService`，也没说明新的 `HealthAnomalyService` 与它们的关系：
- 是新增**第二个 consumer group**（同 topic 两个 group，各自独立消费）？
- 还是在**现有 `HealthApplicationService.processTelemetry` 里**追加调用 `HealthAnomalyService`？
- 还是把 `HealthAnomalyService` 做成被 `processTelemetry` 调用的下游？

**影响**：这是 Phase A 的核心接入点。如果实现者照文档字面新建一个 listener，会与现有 consumer 重复消费/职责重叠；去抖聚合逻辑（每头牛 30–60min）也无处安放。**这是文档最大缺陷，必须在设计阶段解决**。

**建议**：§3 增加一节"与现有 `TelemetryEventConsumer` / `HealthApplicationService` 的关系"，明确二选一：
- 方案 A（推荐）：复用现有 consumer，在 `HealthApplicationService.processTelemetry` 末尾追加去抖 + 调用 `HealthAnomalyService`。零新 listener。
- 方案 B：新增独立 consumer group（如 `health-anomaly-consumer`），与规则引擎 consumer 解耦。需说明去抖状态放哪（Redis？内存？）。

### 2. §6.3 迁移版本号过时：文档说"对齐 V26"，实际已到 V37

**事实核实**：`src/main/resources/db/migration/` 最新迁移是 `V37__add_tile_task_progress.sql`。

**文档问题**：§6.3 写"若需更细，实现时对齐 V26 type 修订加 `AI_ANOMALY`"。V26 是历史版本，Phase A 新迁移应编号为 **V38+**，不是"对齐 V26"。

**建议**：改为"Phase A 新增迁移编号 V38（或当前最新+1），若需细化告警类型，在该迁移中 ALTER `chk_alerts_type` 追加 `AI_ANOMALY`"。另外 §6 三处 `ALTER`/`CREATE` 都应注明归属的具体迁移文件名（如 `V38__add_ai_anomaly_tables.sql`），与项目"每迁移一文件"的惯例对齐。

---

## 🟡 中等问题（建议改）

### 3. §4.2"个体自适应基线"未处理 `temperature_logs.baseline_temp` 生成列冲突

**事实核实**：`V20__create_health_tables.sql` 的 `temperature_logs` 表已有：
```sql
baseline_temp DECIMAL(5,2) NOT NULL DEFAULT 38.50,
delta DECIMAL(5,2) GENERATED ALWAYS AS (temperature - baseline_temp) STORED
```
`delta` 是**生成列**，强依赖 `baseline_temp`。

**文档问题**：§4.2 说"个体自适应基线替代规则引擎写死的全局 38.50"，但没说明：
- 个体基线算出来后，要不要回写 `temperature_logs.baseline_temp`？（如果要，每次写入都需先查该牛基线，写放大）
- 还是在 ai-platform 内部独立维护基线、不碰 `temperature_logs`？（那 `delta` 列继续用 38.50，与 AI 基线并存，语义割裂）
- `health_snapshots.baseline_temp`（同样默认 38.50）是否要被 AI 基线覆盖？

**建议**：§4.2 补一句明确边界——AI 个体基线是 **ai-platform 内部特征**，不回写 `temperature_logs.baseline_temp`（该列继续服务规则引擎）；或反之，说明回写策略。否则实现时会撞上生成列约束。

### 4. §4.3 router 阈值已给出，但"N_eff 如何计算"缺失

文档 §4.3 给出了分档（N_eff<30 / 30≤N_eff<200 / ≥200）——这点比 roadmap 进步了（roadmap 评审已指出阈值缺失，这里补上了 ✅）。

但**N_eff 本身怎么算没定义**：是"过去 14 天该牛 30min 粒度的样本数"？还是"去重后的有效观测数"？缺失值（某维无数据）怎么计入？这直接影响路由稳定性——同一头牛在不同窗口 N_eff 抖动会导致算法来回切换。

**建议**：§4.3 补 N_eff 的精确定义（如"过去 14 天三维均非空的 30min 槽位数"），并说明切换阈值是否带迟滞（hysteresis，避免临界值抖动）。

### 5. §3 去抖状态存储未定义

§3 说"聚合去抖（per-livestock 每 30–60min）"，但去抖/聚合的状态（上次触发时间、缓冲的样本）存在哪没写：
- 内存（重启丢失，重启后可能立即触发或长时间不触发）？
- Redis（与现有架构一致，但增加依赖）？
- 数据库？

**建议**：§3 明确去抖状态存储。鉴于项目已有 Redis（§9 docker-compose 提到 Redis），倾向 Redis（key 如 `ai:dedupe:{livestock_id}`，TTL 60min）。

### 6. §9 部署未说明 ai-platform 的数据访问方式

§9 说 ai-platform 是独立 Python 微服务，但它要读 Java 后端的 PostgreSQL 时序表（§3、§7.3）。文档没说明：
- ai-platform **直连 PostgreSQL**（需共享 DB 连接配置、跨语言 ORM）？
- 还是 **Java 后端把窗口数据打包**通过 `/ai/health/analyze` 的 request body 传给 ai-platform？

§5.2 的请求体是 `{ tenant_id, farm_id, livestock_ids, window_hours }`——只有 ID 和窗口参数，**没有时序数据**。这意味着 ai-platform 要自己去 DB 取数。但 ai-platform 用什么凭据连 PG？连哪个 schema？跨服务直连 DB 是否符合项目的限界上下文隔离原则？

**建议**：§9 补 ai-platform 的数据访问层设计。两种主流选择：
- 方案 A：ai-platform 直连 PG 只读副本/只读账号，仅 SELECT 时序表。
- 方案 B：Java 端组装特征向量，放入 request body 传给 ai-platform（ai-platform 纯无状态计算，不碰 DB）。

方案 B 更符合"ai-platform 只做检测、不持有数据"的定位，且 §5.2 的薄请求体应相应加厚（传特征而非只传 ID）。**这是架构级决策，文档应明确**。

---

## 🟢 小问题

### 7. §7.1 类名不准确：`TelemetryIngestion` 实际是 `TelemetryIngestionService`
代码库中是 `com.smartlivestock.iot.application.TelemetryIngestionService`，文档 §3/§7.1 写的 `TelemetryIngestion` 少了 `Service` 后缀。建议统一全称，避免实现时找不着类。

### 8. §6.1 `anomaly_scores` 表缺索引
分区表按 `created_at`，但常见查询是"查某牛某农场最新分数"或"查某农场高分未标注行"。缺 `(farm_id, livestock_id)` 和 `(label IS NULL)` 的索引建议。§10"主动学习衔接"依赖"高分未标注行"查询，无索引会全表扫分区。

### 9. §5.2 `GET /ai/health` 描述为"存活检查"，但 REST 语义上应为 `/ai/health` 是健康探活、`/ai/health/analyze` 是业务——命名易混。建议探活用 `/ai/health/live` 或 `/healthz`，避免与业务路径 `/ai/health/analyze` 同前缀歧义。

### 10. §4.4 融合权重 `w₁·stl + w₂·cusum + w₃·联合` 说"Phase A 设定，真实数据积累后标定"，但没给 Phase A 的**初始值**和**归一化方式**（三者量纲不同：STL residual、CUSUM 分数、Mahalanobis 距离不在同一尺度）。直接加权会让大量纲项主导。建议补"各层分数先 min-max 或分位数归一化到 [0,1]，再加权"。

---

## ✅ 做得好的地方

- **§7 与 #55 对接**：字段契约表经过核实，与 V20 表结构完全一致（`frequency`/`temperature`/`activity_index`/`recorded_at`），"零改动对接"论证成立。这是全文最扎实的部分。
- **§4.3 router 阈值**：回应了 roadmap 评审的 high 级意见，给出了具体分档（<30 / 30–200 / ≥200），并标注"Phase A 当前数据落 Mahalanobis 档"。
- **§8 评估方式**：无标注场景下的 4 种验证手段（对比规则/专家抽检/自洽性/合成注入）覆盖完整，且诚实标注"真实确诊 ground truth"留给 Phase B。
- **§10 前向兼容预留**：7 个预留点都标注了 Phase B/C 激活方式，主动学习衔接清晰。
- **§4.2 特征精简到 10 维**：明确"防过拟合"，符合 Phase A 不过度设计的原则。

---

## 🔧 建议修改清单（优先级排序）

| 优先级 | 修改项 | 位置 |
|--------|--------|------|
| **high** | 补"与现有 `TelemetryEventConsumer`/`HealthApplicationService` 的接入关系"（复用 vs 新 listener） | §3 新增小节 |
| **high** | 迁移版本号 V26 → V38+，三处 DDL 标注归属迁移文件名 | §6.3 / §6.1 / §6.2 |
| **medium** | 明确 AI 个体基线与 `temperature_logs.baseline_temp` 生成列的边界 | §4.2 |
| **medium** | 补 N_eff 精确定义 + 路由切换迟滞 | §4.3 |
| **medium** | 明确去抖状态存储（倾向 Redis） | §3 |
| **medium** | 明确 ai-platform 数据访问方式（直连 PG vs request body 传特征） | §9 / §5.2 |
| **low** | `TelemetryIngestion` → `TelemetryIngestionService` | §3 / §7.1 |
| **low** | `anomaly_scores` 补查询索引建议 | §6.1 |
| **low** | 探活端点改名避免与业务路径歧义 | §5.2 |
| **low** | 融合权重补初始值 + 归一化方式 | §4.4 |
