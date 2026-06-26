# datagen 限界上下文设计规格 — 数据合成与评估

> 版本: 1.0 | 日期: 2026-06-26 | 状态: 待评审
> 战略依据：[AI 健康路线图](./2026-06-19-ai-health-roadmap.md) §4 Phase B（决策 #10）

## 1. 概述

datagen 限界上下文负责**可控合成数据生成 + ground-truth 标签管理 + AI 评估**。它把原 `TelemetrySimulator`（混在 IoT 上下文里）拆出来，升级为独立的洋葱架构上下文，使合成数据从"临时占位"成为一等公民。

### 为什么需要这个上下文

`TelemetrySimulator` 当前在 IoT 上下文中混了两件事：模拟设备输出（IoT 职责）和注入已知异常（ML/数据职责）。问题：

- 异常标签（`abnormalTemp`/`abnormalMotility`/`inEstrus`）是 boolean，无时序模式、无持续时间、无 ground-truth 记录
- IoT 不应关心"数据是合成的还是真实的"——它是被动接收管道
- 评估 AI 检测结果需要对比预测 vs ground truth，但 ground truth 从未持久化
- #55 真实设备接入后，IoT 加真实适配器，模拟器留在里面会越来越别扭

datagen 把这些职责收拢：合成数据生成、异常注入、ground-truth 标签持久化、评估指标计算都在一个上下文内内聚。

### 与"数据治理"的关系

datagen 不是企业级数据治理（MDM/质量/血缘/合规）。它是数据治理的一个聚焦子集——"让数据可用、可标注、可评估"。真实数据到来后可自然扩张（加质量监控、血缘），但不提前建。

### Phase B 定位

datagen 是 Phase B 的**第一块交付物**，也是其余四块（标注、Java 集成、前端、评估）的数据基础。

---

## 2. 架构

### 2.1 DDD 洋葱架构

```
datagen/
├── domain/
│   ├── model/
│   │   ├── AnomalyPattern          — 异常类型枚举（值对象）
│   │   ├── SynthesisScenario       — 合成场景（聚合根：哪些牛、什么异常、什么时间段）
│   │   └── GroundTruthLabel        — ground-truth 标签（实体）
│   └── port/
│       ├── TelemetryIngestionPort  — ACL：把读数喂给 IoT 标准管道
│       ├── DeviceQueryPort         — ACL：查活跃安装列表
│       └── AnomalyScoreQueryPort   — ACL：查 AI 预测结果（评估用）
├── application/
│   ├── SynthesisService            — 按 scenario 生成读数 + 写标签 + 喂管道
│   ├── SynthesisRunner             — @Scheduled 定时触发，替代 TelemetrySimulator
│   ├── GroundTruthLabelService     — 标签 CRUD（自动标注 + 手动标注同入口）
│   └── EvaluationService           — 对比 AI 预测 vs ground truth，输出指标
├── infrastructure/
│   ├── persistence/
│   │   ├── SynthesisScenarioJpaEntity / Repository
│   │   └── GroundTruthLabelJpaEntity / Repository
│   └── acl/
│       ├── TelemetryIngestionPortImpl  — 委托 IoT TelemetryIngestionService.ingest()
│       ├── DeviceQueryPortImpl         — 委托 IoT InstallationRepository
│       └── AnomalyScoreQueryPortImpl   — 委托 Health anomaly_scores 表只读
└── interfaces/
    └── admin/
        └── DataGenAdminController   — 触发/停止/配置场景/查看评估指标
```

### 2.2 上下文映射

```
[datagen] ──ACL: TelemetryIngestionPort──> [IoT]
           （调 TelemetryIngestionService.ingest()，IoT 不知道数据来源）

[datagen] ──ACL: DeviceQueryPort────────> [IoT]
           （查活跃安装列表：哪些设备该生成数据）

[datagen] ──ACL: AnomalyScoreQueryPort──> [Health]
           （读 anomaly_scores 表，评估时对比 AI 预测 vs ground truth）

[ai-platform Python] ──reads──> PG 时序表（不变）
                     ──reads──> datagen ground_truth_labels（评估对齐）
```

**ACL 方向**：datagen 是调用方（Customer-Supplier 中 datagen 是 Customer，IoT/Health 是 Supplier）。datagen 通过 port 接口依赖，不直接 import IoT/Health 的内部类。

**IoT 零改动**：`TelemetryIngestionService.ingest(deviceId, readings, recordedAt)` 接口不变。datagen 调用它就像真实设备调它一样——设备校验、安装查找、写时序表、发 RocketMQ 事件，全链路不变。

---

## 3. 域模型

### 3.1 AnomalyPattern（值对象·枚举）

替代 `TelemetrySimulator` 的 boolean 标记。每种异常有明确的生理参数和时序形态。

```java
public enum AnomalyPattern {
    // 发热类
    LOW_GRADE_FEVER("低热", 38.5, 39.5, Duration.ofHours(6), "gradual_rise"),
    HIGH_FEVER("高热", 39.5, 41.0, Duration.ofHours(3), "abrupt_spike"),

    // 消化类
    CHRONIC_MOTILITY_DROP("慢性蠕动下降", null, null, Duration.ofDays(2), "gradual_decline"),
    ACUTE_MOTILITY_DROP("急性蠕动停滞", null, null, Duration.ofHours(8), "abrupt_drop"),

    // 行为类（为 Phase C 行为识别预留）
    ESTRUS("发情", null, null, Duration.ofHours(18), "activity_surge"),
    LAMENESS("跛行", null, null, Duration.ofDays(1), "activity_drop"),

    NORMAL("正常", null, null, null, "baseline");
    // ...
}
```

**时序形态**（`temporalShape`）替代 boolean——异常不再是"开关"，而是有渐起、峰值、恢复的曲线：

```
gradual_rise:    基线 → 缓慢上升(2-4h) → 平台期 → 缓慢恢复(2-4h) → 基线
abrupt_spike:    基线 → 突跳(30min) → 平台期 → 恢复
gradual_decline: 基线 → 缓慢下降(12-24h) → 低谷 → 恢复
abrupt_drop:     基线 → 突降(1h) → 低谷 → 恢复
activity_surge:  基线 → 步数激增(2-3x) 持续 12-24h → 恢复
activity_drop:   基线 → 步数骤降(0.3x) 持续 → 恢复
```

### 3.2 SynthesisScenario（聚合根）

一个合成场景 = "给哪些牛、注入什么异常、在什么时间段"。

```java
@Entity
class SynthesisScenario {
    Long id;
    String name;                    // 场景名称（如 "冬季发热潮"）
    ScenarioStatus status;          // DRAFT / RUNNING / STOPPED
    AnomalyPattern pattern;         // 异常类型
    Double penetrationRate;         // 注入比例（如 0.15 = 15% 的牛注入异常）
    Instant windowStart;            // 异常开始时间
    Instant windowEnd;              // 异常结束时间
    Integer intervalSeconds;        // 生成间隔（默认 30s，与原 simulator 一致）
    List<Long> targetLivestockIds;  // 目标牛列表（空 = 全部活跃安装的牛）
}
```

### 3.3 GroundTruthLabel（实体）

**核心资产**——每条标签记录一头牛在一个时段内的真实状态。合成数据自动生成，真实数据人工标注，管道同构。

```java
@Entity
class GroundTruthLabel {
    Long id;
    Long livestockId;
    AnomalyPattern pattern;     // 正常 or 异常类型
    Instant periodStart;        // 时段开始
    Instant periodEnd;          // 时段结束
    LabelSource source;         // SYNTHETIC（自动）/ MANUAL（人工）
    Double severity;            // 严重度 0-1（合成注入可控，人工标注主观打分）
    Long labeledBy;             // 人工标注者 ID（合成为 null）
    Instant labeledAt;
    String note;                // 备注
}

enum LabelSource { SYNTHETIC, MANUAL }
```

---

## 4. 数据库设计

### 4.1 Flyway 迁移（V38）

> 迁移编号取决于实施顺序。若 AI anomaly_scores 表（Phase A design §6.1）先落地则本迁移顺延。设计层面不绑死编号。

```sql
-- V38__create_datagen_tables.sql

-- 合成场景
CREATE TABLE synthesis_scenarios (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'DRAFT'
        CHECK (status IN ('DRAFT','RUNNING','STOPPED')),
    pattern VARCHAR(40) NOT NULL,
    penetration_rate DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    interval_seconds INTEGER NOT NULL DEFAULT 30,
    target_livestock_ids BIGINT[],
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Ground-truth 标签（核心表）
CREATE TABLE ground_truth_labels (
    id BIGSERIAL PRIMARY KEY,
    livestock_id BIGINT NOT NULL,
    pattern VARCHAR(40) NOT NULL,
    period_start TIMESTAMP NOT NULL,
    period_end TIMESTAMP NOT NULL,
    source VARCHAR(10) NOT NULL DEFAULT 'SYNTHETIC'
        CHECK (source IN ('SYNTHETIC','MANUAL')),
    severity DECIMAL(3,2),
    labeled_by BIGINT,
    labeled_at TIMESTAMP,
    note TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- 查询索引
CREATE INDEX idx_gtl_livestock_period ON ground_truth_labels (livestock_id, period_start, period_end);
CREATE INDEX idx_gtl_pattern ON ground_truth_labels (pattern, period_start);
```

**种子数据**：建表后插入一个默认合成场景（`"默认持续合成"`，`NORMAL` pattern，100% 渗透率），替代原 `telemetry.simulator.enabled=true` 的行为。

---

## 5. 合成数据生成流程

### 5.1 SynthesisRunner（替代 TelemetrySimulator 的 @Scheduled）

```java
@Component
@ConditionalOnProperty(name = "datagen.enabled", havingValue = "true", matchIfMissing = true)
class SynthesisRunner {
    @Scheduled(fixedRateString = "${datagen.interval-ms:30000}")
    void run() {
        List<SynthesisScenario> active = scenarioRepo.findByStatus(RUNNING);
        for (SynthesisScenario scenario : active) {
            synthesisService.generate(scenario);
        }
    }
}
```

### 5.2 SynthesisService.generate() 流程

```
SynthesisService.generate(scenario):
  1. 查活跃安装列表（DeviceQueryPort → IoT InstallationRepository）
  2. 对每个 livestockId：
     a. 查该牛的 GroundTruthLabel（当前时段有没有注入中的异常）
     b. 根据 scenario.pattern + temporalShape 生成读数：
        - NORMAL：基线 + 昼夜节律 + 噪声（复用现有 SimulatorState 逻辑）
        - 异常：基线 × temporalShape 曲线（渐起/峰值/恢复）
     c. 组装 readings Map（与 TelemetrySimulator 输出格式一致）
     d. 调 TelemetryIngestionPort.ingest(deviceId, readings, now)
        → IoT 全链路执行（校验/写时序/发事件），零感知
  3. 若异常时段刚开始 → 写 GroundTruthLabel(source=SYNTHETIC)
  4. 若异常时段结束 → 更新 label periodEnd
```

### 5.3 异常注入决策（替代 SimulationState 的随机 boolean）

```
现有（TelemetrySimulator）:
  state.abnormalTemp = rng.nextDouble() < 0.05;  // 进程级 boolean，重启重置

datagen:
  scenario.pattern = HIGH_FEVER, penetrationRate = 0.15
  → 每个 scenario 周期，从目标牛中按 15% 随机选 N 头注入异常
  → 注入时写 GroundTruthLabel(start=now, end=now+scenario.duration)
  → 后续周期查 label 判断"还在异常期" → 继续按 temporalShape 生成
  → periodEnd 到了 → 回归 NORMAL 基线
```

**对比优势**：

| 维度 | 原 TelemetrySimulator | datagen |
|------|----------------------|---------|
| 异常形态 | boolean 开关 | 时序曲线（渐起/峰值/恢复） |
| Ground truth | 无 | 持久化标签表 |
| 可控性 | 进程级随机，重启重置 | 场景配置，可启停、可指定目标 |
| 多维度关联 | 各维度独立随机 | 发热+活动降低=病态（可组合） |
| 评估 | 不可能 | 可计算精确率/召回率 |

---

## 6. 评估流程

### 6.1 EvaluationService

```
EvaluationService.evaluate(scenario, evaluationWindow):
  1. 查 ground_truth_labels（该窗口内的标签）
  2. 查 anomaly_scores（AnomalyScoreQueryPort → Health 表，同一窗口）
  3. 按时间对齐：
     - label: [start, end] + pattern
     - score: timestamp + anomaly_score + anomaly_type
  4. 计算指标（per-pattern + overall）:
     - TP = AI 高分 ∩ label 异常 且时段重叠
     - FP = AI 高分 ∩ label 正常
     - FN = AI 低分 ∩ label 异常
     - TN = AI 低分 ∩ label 正常
     → precision = TP / (TP + FP)
     → recall = TP / (TP + FN)
     → F1 = 2 × P × R / (P + R)
  5. 输出评估报告
```

### 6.2 评估的诚实声明

合成数据上的评估指标**只验证管道正确性和算法自洽性**，不代表真实数据效果（design §8.1 不可外推风险仍有效）。但合成数据的优势是**knows exact ground truth**——可以精确计算硬指标，做回归测试。真实数据到来后需重做评估。

---

## 7. 从 TelemetrySimulator 迁移

### 7.1 迁移策略

不是"删除 TelemetrySimulator 再建 datagen"，而是：

1. **新建 datagen 上下文**（SynthesisRunner + SynthesisService + 标签表）
2. **迁移读数生成逻辑**：`generateTrackerReadings` / `generateCapsuleReadings` 的基线+噪声逻辑搬到 datagen 的 SynthesisService，异常注入逻辑重写为 scenario 驱动
3. **切换配置开关**：`telemetry.simulator.enabled` → `datagen.enabled`，application.yml 改配置
4. **删除 TelemetrySimulator.java**：确认 datagen 产出相同格式的 readings Map，IoT 全链路不变后删除

### 7.2 不迁移的部分

- `SimulationState`（进程内随机状态）→ 被 SynthesisScenario + GroundTruthLabel（持久化）替代
- `@ConditionalOnProperty(name = "telemetry.simulator.enabled")` → 改为 `datagen.enabled`
- `GpsSimulator`（独立的 GPS 模拟器）→ 暂不迁移，Phase B 聚焦健康数据
- GPS 生成逻辑 → **前置依赖**：先实施 [`GPS 模拟数据收敛设计`](./2026-06-26-gps-simulator-consolidation-design.md)（随机游走 + 删除 GpsSimulator），收敛后 GPS 逻辑随 TelemetrySimulator 整体迁移进 `SynthesisService.generateTrackerReadings()`，无需额外工作

---

## 8. 与 Phase B 其余交付物的关系

| Phase B 交付物 | 依赖 datagen 的点 |
|---------------|-----------------|
| ~~标注基础设施（#56）~~ | ~~Phase B~~ -> Phase C。合成数据自动标注无需标注 UI；#56 移至 Phase C（真实数据到来后才需人工标注）|
| Java 后端集成（原 Plan 2） | ai-platform 评估时读 ground_truth_labels 对齐预测 |
| Flutter 双轨前端 | 评估指标可在管理后台展示 |
| 评估框架 | EvaluationService 直接消费 ground_truth_labels |

---

## 8A. 运行时约束（评审 P1 #7/#8）

### 内存状态与重启恢复（P1 #7）

SynthesisState（per-livestock 基线偏移 + 活跃异常追踪）是内存态（ConcurrentHashMap）。应用重启后：
- SynthesisState 丢失（tempBaselineOffset、activePattern、anomalyStart/End）
- GroundTruthLabel 持久化了，但 SynthesisState 不知道

**处置（已知简化）**：重启后 SynthesisState 从头创建。正在进行的异常注入中断——SynthesisState.activePattern 为 null，GroundTruthLabel.periodEnd 仍指向原定结束时间（成为孤儿标签）。新周期由 selectAnomalyTargets 重新选择目标。

**影响**：开发期间频繁重启会产生少量孤儿标签。EvaluationService 评估时，孤儿标签的时段内有 label 无对应异常数据，计为 FN（假阴性），轻微拉低 recall。

**未来改进（Phase C）**：SynthesisState.createOrRestore() 从 DB 查活跃 SYNTHETIC 标签恢复异常状态。Phase B 不做，记为已知简化。

### 事务边界（P1 #8）

SynthesisService.generate() **不加 @Transactional**。理由：
- generate() 是批量循环（遍历所有活跃安装），每头牛的 ingest() 已有自己的事务边界（IoT TelemetryIngestionService.ingest @Transactional）
- 若 generate() 加 @Transactional 且传播 REQUIRED，单头 ingest() 失败会回滚外层事务——包括已成功写入的其他牛的数据
- GroundTruthLabel 写入用独立方法调用（@Transactional(propagation=REQUIRES_NEW)），避免与 ingest 事务耦合

参考原 TelemetrySimulator：它在 @Transactional 方法内 catch 了所有 ingest 异常不外抛，实际效果是成功部分写入。datagen 明确去掉 @Transactional 更干净。

## 9. 配置

```yaml
# application.yml
datagen:
  enabled: ${DATAGEN_ENABLED:true}
  interval-ms: ${DATAGEN_INTERVAL_MS:30000}
  default-scenario:
    pattern: NORMAL
    penetration-rate: 1.0
```

- `datagen.enabled=true` 替代 `telemetry.simulator.enabled=true`
- 默认场景 `NORMAL` = 所有活跃安装的牛持续生成正常基线数据（与现有行为等价）
- 需要注入异常时通过 admin API 创建 scenario（`HIGH_FEVER` + 15% 渗透率等）

---

## 10. Admin API

```
POST   /api/v1/admin/datagen/scenarios          — 创建合成场景
GET    /api/v1/admin/datagen/scenarios          — 列出场景
POST   /api/v1/admin/datagen/scenarios/{id}/start — 启动
POST   /api/v1/admin/datagen/scenarios/{id}/stop  — 停止
GET    /api/v1/admin/datagen/labels             — 查 ground-truth 标签
POST   /api/v1/admin/datagen/labels             — 手动添加标注（MANUAL）
GET    /api/v1/admin/datagen/evaluation         — 查评估指标
```

> Admin API 路径，仅 platform_admin / b2b_admin 可访问。

---

## 11. 前向兼容

| 扩展点 | 当前 | 未来 |
|--------|------|------|
| AnomalyPattern | 6 种 + NORMAL | Phase C 加行为类（反刍异常/进食异常/产犊前兆） |
| LabelSource | SYNTHETIC / MANUAL | 真实数据到来后 MANUAL 为主 |
| 评估 | 二分类（异常/正常） | Phase C 多分类 confusion matrix |
| 数据来源 | 合成 | #55 真实设备到来后，datagen 评估管道不变，只多一个数据来源 |
