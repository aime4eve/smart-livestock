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
│   │   ├── ScenarioType.java           — 场景类型枚举（HEALTH / FENCE_BREACH / FENCE_APPROACH）
│   │   ├── AnomalyPattern.java         — 健康异常类型枚举（6 异常 + NORMAL）
│   │   ├── TemporalShape.java          — 时序形态枚举
│   │   ├── ScenarioStatus.java         — 场景状态枚举
│   │   ├── LabelSource.java            — 标签来源枚举
│   │   ├── SynthesisScenario.java      — 聚合根（支持健康 + 围栏双维度）
│   │   └── GroundTruthLabel.java       — 实体
│   ├── repository/
│   │   ├── SynthesisScenarioRepository.java
│   │   └── GroundTruthLabelRepository.java
│   └── port/
│       ├── TelemetryIngestionPort.java  — ACL: 喂数据给 IoT
│       ├── DeviceQueryPort.java         — ACL: 查活跃安装
│       ├── AnomalyScoreQueryPort.java   — ACL: 查 AI 预测结果（评估用）
│       └── FenceQueryPort.java          — ACL: 查围栏几何（围栏越界场景用）
├── application/
│   ├── SynthesisService.java            — 三层合成：基线 → 健康调制 → 围栏位移
│   ├── SynthesisRunner.java             — @Scheduled 定时触发
│   ├── GroundTruthLabelService.java     — 标签 CRUD
│   ├── EvaluationService.java           — 评估框架
│   └── dto/
│       ├── EvaluationReport.java
│       ├── MetricResult.java
│       ├── ScenarioDto.java
│       └── CreateScenarioRequest.java
├── infrastructure/
│   ├── persistence/  (entity / Spring Data / impl / mapper)
│   └── acl/
│       ├── TelemetryIngestionPortImpl.java
│       ├── DeviceQueryPortImpl.java
│       ├── AnomalyScoreQueryPortImpl.java
│       └── FenceQueryPortImpl.java       — 委托 ranch FenceRepository + livestock
└── interfaces/
    └── admin/
        └── DataGenAdminController.java
```

### 2.2 上下文映射

```
[datagen] ──ACL: TelemetryIngestionPort──> [IoT]
           （调 TelemetryIngestionService.ingest()，IoT 不知道数据来源）

[datagen] ──ACL: DeviceQueryPort────────> [IoT]
           （查活跃安装列表：哪些设备该生成数据）

[datagen] ──ACL: FenceQueryPort─────────> [Ranch]
           （查目标牲畜所属牧场的围栏几何，用于围栏越界场景）

[datagen] ──ACL: AnomalyScoreQueryPort──> [Health]
           （读 anomaly_scores 表，评估时对比 AI 预测 vs ground truth）

[ai-platform Python] ──reads──> PG 时序表（不变）
                     ──reads──> datagen ground_truth_labels（评估对齐）
```

**围栏 ACL 新增**：datagen 通过 `FenceQueryPort` 查询 ranch 的 `FenceRepository`（围栏顶点 + buffer zone），但不依赖围栏检测逻辑——围栏检测由 `GpsLogEventConsumer` → `FenceBreachDetector` 完成，datagen 只负责"把牛移动到围栏外"。

---

## 3. 域模型

### 3.1 ScenarioType（枚举·场景维度）

datagen 支持两个维度：健康异常和空间越界。

```java
public enum ScenarioType {
    HEALTH,          // 健康异常注入（温度/蠕动/活动调制）
    FENCE_BREACH,    // 围栏越界（GPS 移到围栏外）
    FENCE_APPROACH   // 围栏接近（GPS 移到 buffer zone 内）
}
```

### 3.2 AnomalyPattern（值对象·枚举）

**修订（2026-06-26）：多维度关联调制**。每种异常不再是单维度调制，而是影响多个读数字段，与 ai-platform 三维联合检测配套。

```java
public enum AnomalyPattern {
    // 发热类：温度升高 + 活动降低（发烧时牛变迟钝）
    LOW_GRADE_FEVER("low_grade_fever", 38.5, 39.5, Duration.ofHours(6), TemporalShape.GRADUAL_RISE),
    HIGH_FEVER("high_fever", 39.5, 41.0, Duration.ofHours(3), TemporalShape.ABRUPT_SPIKE),

    // 消化类：蠕动下降 + 温度可能微升（消化问题常伴低热）
    CHRONIC_MOTILITY_DROP("chronic_motility_drop", null, null, Duration.ofDays(2), TemporalShape.GRADUAL_DECLINE),
    ACUTE_MOTILITY_DROP("acute_motility_drop", null, null, Duration.ofHours(8), TemporalShape.ABRUPT_DROP),

    // 行为类：活动骤变 + 蠕动相应变化
    ESTRUS("estrus", null, null, Duration.ofHours(18), TemporalShape.ACTIVITY_SURGE),
    LAMENESS("lameness", null, null, Duration.ofDays(1), TemporalShape.ACTIVITY_DROP),

    NORMAL("normal", null, null, null, TemporalShape.BASELINE);
}
```

**多维度关联调制规则**（替代单维度调制）：

| Pattern | temperature | motility | activityIndex | stepCount |
|---------|-------------|----------|---------------|-----------|
| LOW_GRADE_FEVER | +intensity*(tempMax-38.5) | -intensity*20% | **-intensity*40%** | -intensity*30% |
| HIGH_FEVER | +intensity*(tempMax-38.5) | -intensity*30% | **-intensity*60%** | -intensity*50% |
| CHRONIC_MOTILITY_DROP | **+intensity*0.5C** | -intensity*60% | -intensity*20% | -intensity*15% |
| ACUTE_MOTILITY_DROP | 基线 | -intensity*80% | -intensity*30% | -intensity*20% |
| ESTRUS | 基线+0.3C | 基线 | **+intensity*80%** | **+intensity*150%** |
| LAMENESS | 基线 | -intensity*10% | **-intensity*70%** | **-intensity*70%** |

> **activityIndex 调制修复**：原实现 activityIndex 永远是随机值不受异常影响，导致 ai-platform 的三维联合检测在活动维度看不到异常。现在每种异常都调制 activityIndex，确保三维度同步偏离。

### 3.3 SynthesisScenario（聚合根）

**修订**：增加 `scenarioType` 区分健康场景和围栏场景。

```java
public class SynthesisScenario extends AggregateRoot {
    private String name;
    private ScenarioStatus status;
    private ScenarioType scenarioType;    // 新增：HEALTH / FENCE_BREACH / FENCE_APPROACH
    private AnomalyPattern pattern;       // HEALTH 场景用，FENCE 场景为 null
    private double penetrationRate;
    private Instant windowStart;
    private Instant windowEnd;
    private int intervalSeconds;
    private List<Long> targetLivestockIds;
}
```

### 3.4 GroundTruthLabel（实体）

```java
public class GroundTruthLabel extends Entity {
    private Long livestockId;
    private AnomalyPattern pattern;     // 健康标签用（含 NORMAL）
    private ScenarioType scenarioType;  // 新增：标签维度（HEALTH / FENCE_BREACH / FENCE_APPROACH）
    private Instant periodStart;
    private Instant periodEnd;
    private LabelSource source;
    private double severity;
    private Long labeledBy;
    private Instant labeledAt;
    private String note;
}
```

---

## 4. 数据库设计

### 4.1 Flyway 迁移修订

**V38 已实施**，需追加 V39 扩展列：

```sql
-- V39__extend_datagen_for_fence_scenarios.sql

-- synthesis_scenarios: 增加 scenario_type 列
ALTER TABLE synthesis_scenarios ADD COLUMN scenario_type VARCHAR(20) NOT NULL DEFAULT 'HEALTH'
    CHECK (scenario_type IN ('HEALTH','FENCE_BREACH','FENCE_APPROACH'));

-- ground_truth_labels: 增加 scenario_type 列
ALTER TABLE ground_truth_labels ADD COLUMN scenario_type VARCHAR(20) NOT NULL DEFAULT 'HEALTH'
    CHECK (scenario_type IN ('HEALTH','FENCE_BREACH','FENCE_APPROACH'));
```

> V38 种子数据的默认场景需要回填 `scenario_type = 'HEALTH'`（ALTER DEFAULT 已覆盖）。

---

## 5. 合成数据生成流程

### 5.1 三层合成模型

```
SynthesisService.generate(scenario)
  │
  ├── 第 1 层：基线数据生成（所有场景都执行）
  │   generateTrackerReadings / generateCapsuleReadings → 正常昼夜节律 + 噪声
  │
  ├── 第 2 层：健康场景叠加（scenarioType = HEALTH 时执行）
  │   calculateIntensity(state, now) → 按 AnomalyPattern 多维度关联调制
  │   调制：temperature / motility / activityIndex / stepCount
  │
  └── 第 3 层：围栏场景叠加（scenarioType = FENCE_BREACH/APPROACH 时执行）
      FenceQueryPort.findFencesByFarmId(farmId) → 查围栏几何
      → calculateFenceTarget(fence, scenarioType) → 计算目标坐标
      → 覆盖 readings["latitude"] / ["longitude"]
      → 写 GroundTruthLabel(scenarioType=FENCE_BREACH)
```

### 5.2 围栏越界 GPS 位移

```java
/**
 * FENCE_BREACH: 把 GPS 坐标移到围栏外（距离边界 ~50m 处）
 * FENCE_APPROACH: 把 GPS 坐标移到 buffer zone 内（围栏外但接近边界）
 */
private void applyFenceDisplacement(SynthesisState state, SynthesisScenario scenario,
        Long livestockId, Instant now) {
    // 1. 查牲畜所属牧场 + 围栏
    List<FenceInfo> fences = fenceQueryPort.findFencesByLivestockId(livestockId);
    if (fences.isEmpty()) return;

    // 2. 选一个活跃围栏
    FenceInfo fence = pickFence(fences);
    List<CoordinateInfo> vertices = fence.vertices();

    // 3. 计算围栏边界框
    double minLat = vertices.stream().mapToDouble(v -> v.latitude().doubleValue()).min().getAsDouble();
    double maxLat = ...; double minLng = ...; double maxLng = ...;

    // 4. FENCE_BREACH: 移到边界框外 ~50m
    if (scenario.getScenarioType() == ScenarioType.FENCE_BREACH) {
        state.currentLat = maxLat + 0.0005;  // ~50m beyond north edge
        state.currentLng = (minLng + maxLng) / 2;
    }
    // 5. FENCE_APPROACH: 移到 buffer zone（接近边界但仍在 buffer 内）
    else if (scenario.getScenarioType() == ScenarioType.FENCE_APPROACH) {
        state.currentLat = maxLat - 0.0001;  // just inside, near edge
        state.currentLng = (minLng + maxLng) / 2;
    }

    // 6. 写 ground-truth 标签
    GroundTruthLabel label = new GroundTruthLabel();
    label.setScenarioType(scenario.getScenarioType());
    label.setLivestockId(livestockId);
    label.setPeriodStart(now);
    label.setPeriodEnd(now.plus(Duration.ofMinutes(30)));  // 一个周期越界
    ...
}
```

> GPS 位移产生坐标后，走标准管道：`ingest()` → `extractAndLogGps()` → `gps_logs` → `GpsLogUpdatedEvent` → `GpsLogEventConsumer` → `FenceBreachDetector` → 告警。围栏检测链路零改动。

### 5.3 健康场景 activityIndex 调制（修复）

```java
// 原实现（错误）：activityIndex 不受异常影响
readings.put("activityIndex", round(hourFactor * rng.nextDouble(30, 80), 1));

// 修订：activityIndex 受 AnomalyPattern + intensity 调制
double baseActivity = hourFactor * rng.nextDouble(30, 80);
double activityMod = getActivityModulation(pattern, intensity);
readings.put("activityIndex", round(baseActivity * (1.0 + activityMod), 1));

// 多维度调制函数
private double getActivityModulation(AnomalyPattern pattern, double intensity) {
    return switch (pattern) {
        case LOW_GRADE_FEVER -> -intensity * 0.4;   // 发烧活动减少
        case HIGH_FEVER -> -intensity * 0.6;
        case CHRONIC_MOTILITY_DROP -> -intensity * 0.2;
        case ACUTE_MOTILITY_DROP -> -intensity * 0.3;
        case ESTRUS -> intensity * 0.8;             // 发情活动增加
        case LAMENESS -> -intensity * 0.7;          // 跛行活动大减
        case NORMAL -> 0.0;
    };
}
```

---

## 6. 评估流程

### 6.1 EvaluationService（扩展双维度评估）

```
EvaluationService.evaluate(from, to, scoreThreshold)
  ├── HEALTH 维度评估
  │   ground_truth_labels (scenarioType=HEALTH) × anomaly_scores
  │   → precision/recall/F1 per AnomalyPattern
  │
  └── FENCE 维度评估
      ground_truth_labels (scenarioType=FENCE_BREACH) × alerts (type=FENCE_BREACH)
      → 越界检测召回率（注入的越界是否都产生了告警）
```

### 6.2 评估的诚实声明

合成数据上的评估指标只验证管道正确性和算法自洽性，不代表真实数据效果（design §8.1 不可外推风险仍有效）。

---

## 7. 从 TelemetrySimulator 迁移

### 7.1 迁移策略

✅ **已完成**（Task 1-13）：TelemetrySimulator 已删除，datagen SynthesisService 接管全部合成数据生成。

### 7.2 当前实现缺口（需补充）

| 缺口 | 严重度 | 说明 |
|------|--------|------|
| 围栏越界场景 | P0 | ScenarioType.FENCE_BREACH/APPROACH + FenceQueryPort + GPS 位移 |
| activityIndex 调制 | P0 | 原实现不调制活动维度，ai-platform 三维退化为二维 |
| 多维度关联调制 | P1 | 每种异常只影响单维度，缺少关联（发烧+活动降低=病态） |
| 首次部署基线积累 | P2 | ai-platform 需 14 天基线数据，首次部署时 N_eff < 30 |

---

## 8. 与 Phase B 其余交付物的关系

| 交付物 | 依赖 datagen 的点 |
|--------|-----------------|
| ~~标注基础设施(#56)~~ | ~~Phase B~~ -> Phase C |
| Java 后端集成 | datagen 生成的健康数据经 IoT 入库 → ai-platform 检测 → anomaly_scores |
| Flutter 双轨前端 | 前端展示健康告警 + 围栏告警 |
| 评估报告 | HEALTH 维度：datagen 标签 × ai-platform 预测；FENCE 维度：datagen 标签 × ranch 告警 |

---

## 8A. 运行时约束（评审 P1 #7/#8）

### 内存状态与重启恢复（P1 #7）

SynthesisState（per-livestock 基线偏移 + 活跃异常/越界追踪 + GPS 位置）是内存态。应用重启后丢失。正在进行的异常注入或围栏越界中断，产生少量孤儿标签。

**已知简化（Phase B）**：重启后从头创建，孤儿标签影响轻微。

### 事务边界（P1 #8）

SynthesisService.generate() **不加 @Transactional**。每头牛的 ingest() 有自己的事务边界。GroundTruthLabel 写入走独立方法（@Transactional(propagation=REQUIRES_NEW)）。

---

## 9. 配置

```yaml
datagen:
  enabled: ${DATAGEN_ENABLED:true}
  interval-ms: ${DATAGEN_INTERVAL_MS:30000}
```

---

## 10. Admin API

```
POST   /api/v1/admin/datagen/scenarios          — 创建合成场景（含 scenarioType）
GET    /api/v1/admin/datagen/scenarios          — 列出场景
POST   /api/v1/admin/datagen/scenarios/{id}/start — 启动
POST   /api/v1/admin/datagen/scenarios/{id}/stop  — 停止
GET    /api/v1/admin/datagen/labels             — 查 ground-truth 标签
GET    /api/v1/admin/datagen/evaluation         — 查评估指标
```

---

## 11. 前向兼容

| 扩展点 | 当前 | 未来 |
|--------|------|------|
| ScenarioType | HEALTH / FENCE_BREACH / FENCE_APPROACH | Phase C 加 BEHAVIOR（反刍/进食/躺卧） |
| AnomalyPattern | 6 种 + NORMAL | Phase C 加行为类 |
| LabelSource | SYNTHETIC / MANUAL | 真实数据到来后 MANUAL 为主 |
| 评估 | 二分类（异常/正常）+ 越界召回 | Phase C 多分类 confusion matrix |
| 数据来源 | 合成 | #55 真实设备到来后，datagen 评估管道不变 |
