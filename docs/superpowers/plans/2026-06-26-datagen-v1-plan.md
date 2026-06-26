# datagen-v1 实施计划（数据合成与评估上下文）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
> **版本: 2.0（评审修订版）** — 修复 P0×2 + P1×6，详见 `reviews/2026-06-26-datagen-design-and-plan-review.md`

**Goal:** 新建 `datagen` 限界上下文（DDD 洋葱架构），将 `TelemetrySimulator` 的随机 boolean 异常注入升级为 Scenario 驱动的可控合成数据引擎，持久化 ground-truth 标签，并实现评估框架。datagen 通过 ACL 端口调用 IoT 的 `TelemetryIngestionService.ingest()`，IoT 零改动。

**Architecture:** `datagen/domain`(model + repository interfaces + ports) → `datagen/application`(SynthesisService + SynthesisRunner + GroundTruthLabelService + EvaluationService) → `datagen/infrastructure`(persistence impl + acl) → `datagen/interfaces`(DataGenAdminController)。

**Tech Stack:** Java 17 + Spring Boot 3.3 + JPA/Hibernate + Flyway + Lombok + JUnit 5。

**关联文档:**
- 设计规格：`docs/superpowers/specs/2026-06-26-datagen-context-design.md`
- 战略路线图：`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md` §4 Phase B
- 评审：`docs/superpowers/reviews/2026-06-26-datagen-design-and-plan-review.md`
- **GPS 前置依赖**：`docs/superpowers/specs/2026-06-26-gps-simulator-consolidation-design.md`（随机游走 + 删除 GpsSimulator，必须在 Task 7/12 之前实施）

**评审修复清单（P0/P1 嵌入此版）：**
- P0 #2 Task 重排 → persistence 提前到 service 之前
- P1 #3 设计文档 §8 已在 spec 修复
- P1 #4 domain repository 接口层 → Task 4 新增
- P1 #5 SynthesisScenario extends AggregateRoot → Task 3
- P1 #6 AnomalyScoreQueryPortImpl 用 PersistenceException → Task 5
- P1 #7 内存状态重启 → Task 7 已知简化声明
- P1 #8 事务边界 → Task 7 generate() 去掉 @Transactional

---

## File Structure

```
smart-livestock-server/src/main/java/com/smartlivestock/datagen/
├── domain/
│   ├── model/
│   │   ├── AnomalyPattern.java
│   │   ├── TemporalShape.java
│   │   ├── ScenarioStatus.java
│   │   ├── LabelSource.java
│   │   ├── SynthesisScenario.java       — extends AggregateRoot（评审 P1 #5）
│   │   └── GroundTruthLabel.java
│   ├── repository/                       — domain repository 接口（评审 P1 #4）
│   │   ├── SynthesisScenarioRepository.java
│   │   └── GroundTruthLabelRepository.java
│   └── port/
│       ├── TelemetryIngestionPort.java
│       ├── DeviceQueryPort.java
│       └── AnomalyScoreQueryPort.java
├── application/
│   ├── SynthesisService.java
│   ├── SynthesisRunner.java
│   ├── GroundTruthLabelService.java
│   ├── EvaluationService.java
│   └── dto/
│       ├── EvaluationReport.java
│       ├── MetricResult.java
│       ├── ScenarioDto.java              — Admin API DTO（评审 P2 #11）
│       └── CreateScenarioRequest.java
├── infrastructure/
│   ├── persistence/
│   │   ├── entity/
│   │   │   ├── SynthesisScenarioJpaEntity.java
│   │   │   └── GroundTruthLabelJpaEntity.java
│   │   ├── SynthesisScenarioJpaRepository.java   — Spring Data
│   │   ├── GroundTruthLabelJpaRepository.java     — Spring Data
│   │   ├── JpaSynthesisScenarioRepositoryImpl.java — implements domain interface
│   │   ├── JpaGroundTruthLabelRepositoryImpl.java
│   │   └── mapper/
│   │       ├── SynthesisScenarioMapper.java
│   │       └── GroundTruthLabelMapper.java
│   └── acl/
│       ├── TelemetryIngestionPortImpl.java
│       ├── DeviceQueryPortImpl.java
│       └── AnomalyScoreQueryPortImpl.java
└── interfaces/
    └── admin/
        └── DataGenAdminController.java
```

---

## Task 1: Flyway 迁移

**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V38__create_datagen_tables.sql`

- [ ] **Step 1: V38 迁移 + 默认场景种子**

```sql
-- V38__create_datagen_tables.sql
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

CREATE INDEX idx_gtl_livestock_period ON ground_truth_labels (livestock_id, period_start, period_end);
CREATE INDEX idx_gtl_pattern ON ground_truth_labels (pattern, period_start);
CREATE INDEX idx_ss_status ON synthesis_scenarios (status);

-- 默认场景：替代原 telemetry.simulator.enabled=true 行为
INSERT INTO synthesis_scenarios (name, status, pattern, penetration_rate, window_start, window_end, interval_seconds)
VALUES ('默认持续合成', 'RUNNING', 'NORMAL', 1.0, NOW(), NOW() + INTERVAL '365 days', 30);
```

> **评审 P2 #10（历史数据无标签）**：V38 之后的历史遥测数据不补标。评估窗口从 datagen 启用后开始。

- [ ] **Step 2: 编译验证 + Commit**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

---

## Task 2: 领域枚举

**Files:**
- Create: `datagen/domain/model/AnomalyPattern.java`
- Create: `datagen/domain/model/TemporalShape.java`
- Create: `datagen/domain/model/ScenarioStatus.java`
- Create: `datagen/domain/model/LabelSource.java`

- [ ] **Step 1: TemporalShape（含 intensityFactor 三段式曲线）**

每种 shape 的 `intensityFactor(progress)` 返回 0.0-1.0 强度：渐起(0-0.3) → 平台(0.3-0.7) → 渐落(0.7-1.0)。

- [ ] **Step 2: AnomalyPattern（6 异常 + NORMAL，携带温度范围/持续时间/temporalShape）**

- [ ] **Step 3: ScenarioStatus(DRAFT/RUNNING/STOPPED) + LabelSource(SYNTHETIC/MANUAL)**

- [ ] **Step 4: 单元测试 TemporalShapeTest（intensityFactor 全分支覆盖）**

- [ ] **Step 5: 编译 + 测试 + Commit**

Run: `./gradlew test --tests "*.datagen.domain.*" 2>&1 | tail -10`

---

## Task 3: 领域模型 — SynthesisScenario + GroundTruthLabel

**Files:**
- Create: `datagen/domain/model/SynthesisScenario.java`
- Create: `datagen/domain/model/GroundTruthLabel.java`

- [ ] **Step 1: SynthesisScenario extends AggregateRoot（评审 P1 #5）**

> **评审 P1 #5 修复**：继承 `shared.domain.AggregateRoot`（带域事件收集），而非 `Entity`。场景启动/停止可注册 `ScenarioStartedEvent` / `ScenarioStoppedEvent`。

```java
public class SynthesisScenario extends AggregateRoot {
    private ScenarioStatus status;
    // start() / stop() / isActiveAt() 方法...
}
```

- [ ] **Step 2: GroundTruthLabel extends Entity（overlaps 方法）**

- [ ] **Step 3: 单元测试 SynthesisScenarioTest（start/stop/isActiveAt）**

- [ ] **Step 4: 编译 + 测试 + Commit**

---

## Task 4: domain repository 接口（评审 P1 #4 新增）

**Files:**
- Create: `datagen/domain/repository/SynthesisScenarioRepository.java`
- Create: `datagen/domain/repository/GroundTruthLabelRepository.java`

> **评审 P1 #4 修复**：项目模式是三层 repository（domain 接口 → Spring Data → impl + mapper）。application 层注入 domain 接口，不直接依赖 Spring Data。

- [ ] **Step 1: domain repository 接口**

```java
package com.smartlivestock.datagen.domain.repository;

public interface SynthesisScenarioRepository {
    SynthesisScenario save(SynthesisScenario scenario);
    Optional<SynthesisScenario> findById(Long id);
    List<SynthesisScenario> findByStatus(ScenarioStatus status);
    List<SynthesisScenario> findAll();
}

public interface GroundTruthLabelRepository {
    GroundTruthLabel save(GroundTruthLabel label);
    List<GroundTruthLabel> findByLivestockIdAndPeriodOverlap(Long livestockId, Instant from, Instant to);
    List<GroundTruthLabel> findByPatternAndPeriod(AnomalyPattern pattern, Instant from, Instant to);
}
```

> domain 接口返回 **domain 类型**（SynthesisScenario / GroundTruthLabel），不返回 JPA Entity。

- [ ] **Step 2: 编译 + Commit**

---

## Task 5: ACL 端口接口 + 实现

**Files:**
- Create: 3 port 接口 + 2 DTO + 3 ACL 实现类

- [ ] **Step 1: port 接口（TelemetryIngestionPort / DeviceQueryPort / AnomalyScoreQueryPort）**

- [ ] **Step 2: ACL 实现类**

> **评审 P1 #6 修复**：`AnomalyScoreQueryPortImpl` 用 `PersistenceException`（JPA 标准异常基类）替代 `Exception`，并缓存可用性标志避免每次触发异常：

```java
@Component
@RequiredArgsConstructor
public class AnomalyScoreQueryPortImpl implements AnomalyScoreQueryPort {
    private final EntityManager entityManager;
    private volatile boolean available = true;

    @Override
    public List<AnomalyScoreInfo> findByLivestockIdsAndPeriod(List<Long> livestockIds, Instant from, Instant to) {
        if (!available || livestockIds.isEmpty()) return List.of();
        try {
            var query = entityManager.createNativeQuery(
                "SELECT livestock_id, anomaly_score, anomaly_type, created_at " +
                "FROM anomaly_scores " +
                "WHERE livestock_id IN :ids AND created_at >= :from AND created_at <= :to");
            query.setParameter("ids", livestockIds);
            query.setParameter("from", from);
            query.setParameter("to", to);
            List<Object[]> rows = query.getResultList();
            return rows.stream().map(row -> new AnomalyScoreInfo(
                ((Number) row[0]).longValue(),
                (java.math.BigDecimal) row[1],
                (String) row[2],
                row[3] instanceof Instant i ? i : ((java.sql.Timestamp) row[3]).toInstant()
            )).toList();
        } catch (PersistenceException e) {
            available = false;
            log.warn("anomaly_scores table not available, evaluation will be empty: {}", e.getMessage());
            return List.of();
        }
    }
}
```

- [ ] **Step 3: 编译 + Commit**

---

## Task 6: 持久化层（原 Task 9 提前，评审 P0 #2 修复）

**Files:**
- Create: 2 JPA Entity + 2 Spring Data Repo + 2 Impl + 2 Mapper

- [ ] **Step 1: JPA Entities**

`SynthesisScenarioJpaEntity` — `target_livestock_ids` 用 Hibernate 6 `@JdbcTypeCode(SqlTypes.ARRAY)` 映射 PostgreSQL BIGINT[]。
`GroundTruthLabelJpaEntity` — 标准 `@Entity`。

- [ ] **Step 2: Spring Data Repositories**

```java
public interface SynthesisScenarioJpaRepository extends JpaRepository<SynthesisScenarioJpaEntity, Long> {
    List<SynthesisScenarioJpaEntity> findByStatus(String status);
}
public interface GroundTruthLabelJpaRepository extends JpaRepository<GroundTruthLabelJpaEntity, Long> {
    @Query("SELECT g FROM GroundTruthLabelJpaEntity g WHERE g.livestockId = :id " +
           "AND g.periodStart <= :to AND g.periodEnd >= :from")
    List<GroundTruthLabelJpaEntity> findByLivestockIdAndPeriodOverlap(
        @Param("id") Long id, @Param("from") Instant from, @Param("to") Instant to);
}
```

- [ ] **Step 3: JpaXxxRepositoryImpl implements domain repository（评审 P1 #4）**

Impl 类实现 **Task 4 的 domain 接口**，委托 Spring Data + Mapper 转换 domain <-> JPA。

- [ ] **Step 4: Mapper（SynthesisScenarioMapper / GroundTruthLabelMapper）**

- [ ] **Step 5: 编译 + Commit**

---

## Task 7: SynthesisService — 合成数据生成核心

**Files:**
- Create: `datagen/application/SynthesisService.java`
- Create: `datagen/application/SynthesisState.java`

> **评审 P1 #8 修复**：`generate()` **不加 @Transactional**。批量循环中每头牛的 ingest() 有自己的事务边界。GroundTruthLabel 写入走独立 service 方法（`@Transactional(propagation=REQUIRES_NEW)`）。

> **评审 P1 #7 修复**：SynthesisState 内存态重启丢失——声明为已知简化（设计文档 §8A）。重启后正在进行的异常注入中断，产生少量孤儿标签，EvaluationService 评估轻微拉低 recall。Phase C 做 DB 恢复。

> **评审 P2 #9 修复**：`selectAnomalyTargets` 明确为——仅在场景首次启动或活跃 label 过期时调用，不是每个周期。后续周期查 SynthesisState.activePattern 判断是否在异常期。

- [ ] **Step 1: SynthesisState（per-livestock 基线偏移 + 活跃异常追踪）**

```java
@Data
public class SynthesisState {
    private double tempBaselineOffset;
    private long motilityBaseline;
    private int batteryLevel;
    private int batteryVoltage;
    private AnomalyPattern activePattern;   // null = NORMAL
    private Instant anomalyStart;
    private Instant anomalyEnd;

    static SynthesisState create(Long livestockId) {
        var s = new SynthesisState();
        var rng = ThreadLocalRandom.current();
        s.tempBaselineOffset = rng.nextDouble(-0.3, 0.3);
        s.motilityBaseline = (long)(rng.nextDouble(2.5, 3.5) * 100000);
        s.batteryLevel = rng.nextInt(70, 101);
        s.batteryVoltage = rng.nextInt(3200, 3601);
        return s;
    }
}
```

- [ ] **Step 2: SynthesisService.generate() — 无 @Transactional（评审 P1 #8）**

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class SynthesisService {
    private final TelemetryIngestionPort ingestionPort;
    private final DeviceQueryPort deviceQueryPort;
    private final SynthesisScenarioRepository scenarioRepo;
    private final GroundTruthLabelService labelService;  // label 写入走独立事务

    private final ConcurrentHashMap<Long, SynthesisState> states = new ConcurrentHashMap<>();

    // generate() 不加 @Transactional（评审 P1 #8）
    public void generate(SynthesisScenario scenario) {
        List<ActiveInstallationInfo> installations = deviceQueryPort.findActiveInstallations();
        if (installations.isEmpty()) return;
        Instant now = Instant.now();
        if (!scenario.isActiveAt(now)) return;

        // selectAnomalyTargets 仅在需要时调用（评审 P2 #9）
        Set<Long> anomalyTargets = selectAnomalyTargetsIfNeeded(installations, scenario);

        for (ActiveInstallationInfo inst : installations) {
            SynthesisState state = states.computeIfAbsent(inst.livestockId(), SynthesisState::create);
            updateAnomalyState(state, inst.livestockId(), scenario, anomalyTargets, now);
            double intensity = calculateIntensity(state, now);
            Map<String, Object> readings = switch (inst.deviceType()) {
                case TRACKER -> generateTrackerReadings(state, scenario.getPattern(), intensity, now);
                case CAPSULE -> generateCapsuleReadings(state, scenario.getPattern(), intensity, now);
                default -> Map.of();
            };
            try {
                ingestionPort.ingest(inst.deviceId(), readings, now);
            } catch (Exception e) {
                log.warn("Failed to ingest synthetic data for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    // selectAnomalyTargetsIfNeeded: 首次启动或活跃 label 过期时选目标
    private Set<Long> selectAnomalyTargetsIfNeeded(List<ActiveInstallationInfo> insts, SynthesisScenario scenario) {
        // 若 scenario.getPattern() == NORMAL，返回空集
        // 否则，检查是否有任何活跃的 SYNTHETIC label（periodEnd > now）→ 有则返回已有的
        // 没有则按 penetrationRate 从全部 livestockId 中随机选子集
    }
}
```

- [ ] **Step 3: generateTrackerReadings / generateCapsuleReadings**

迁移自 `TelemetrySimulator` 的基线+噪声逻辑，按 intensity × pattern 调制。**输出格式与原 simulator 完全一致**（key 名、类型），保证 IoT ingest() 无感知。TRACKER readings 照常含 latitude/longitude（与原 TelemetrySimulator 行为一致）。
> **前置依赖**：GPS 生成逻辑迁移自 GPS 收敛设计（随机游走，非写死长沙坐标）。GPS 收敛必须先实施，见 `2026-06-26-gps-simulator-consolidation-design.md`。SynthesisState 需包含 `currentLat`/`currentLng` 随机游走状态（与 SimulationState 同构）。

- [ ] **Step 4: 编译 + Commit**

---

## Task 8: SynthesisRunner — 定时触发器

**Files:**
- Create: `datagen/application/SynthesisRunner.java`

- [ ] **Step 1: SynthesisRunner（@Scheduled + @ConditionalOnProperty matchIfMissing=true）**

- [ ] **Step 2: application.yml 配置切换**

```yaml
telemetry:
  simulator:
    enabled: ${TELEMETRY_SIMULATOR_ENABLED:false}  # 关闭，由 datagen 接管
    interval-ms: ${TELEMETRY_SIMULATOR_INTERVAL_MS:30000}
datagen:
  enabled: ${DATAGEN_ENABLED:true}
  interval-ms: ${DATAGEN_INTERVAL_MS:30000}
```

- [ ] **Step 3: 编译 + Commit**

---

## Task 9: GroundTruthLabelService — 标签 CRUD

**Files:**
- Create: `datagen/application/GroundTruthLabelService.java`

- [ ] **Step 1: GroundTruthLabelService**

注入 **domain repository 接口**（Task 4），不是 Spring Data。

```java
@Service
@RequiredArgsConstructor
public class GroundTruthLabelService {
    private final GroundTruthLabelRepository repository;

    // label 写入用独立事务（评审 P1 #8：与 ingest 解耦）
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public GroundTruthLabel saveLabel(GroundTruthLabel label) {
        return repository.save(label);
    }

    public List<GroundTruthLabel> findByLivestockAndPeriod(Long livestockId, Instant from, Instant to) {
        return repository.findByLivestockIdAndPeriodOverlap(livestockId, from, to);
    }

    // 为 Phase C 标注预留，Phase B 不建 UI
    public GroundTruthLabel createManualLabel(...) { ... }
}
```

- [ ] **Step 2: 编译 + Commit**

---

## Task 10: EvaluationService — 评估框架

**Files:**
- Create: `datagen/application/EvaluationService.java`
- Create: `datagen/application/dto/EvaluationReport.java`
- Create: `datagen/application/dto/MetricResult.java`

- [ ] **Step 1: DTO（EvaluationReport + MetricResult）**

- [ ] **Step 2: EvaluationService.evaluate(from, to, scoreThreshold)**

对比 GroundTruthLabel × AnomalyScore，按时间对齐，计算 per-pattern + overall confusion matrix（TP/FP/FN/TN → precision/recall/F1）。

- [ ] **Step 3: 编译 + Commit**

---

## Task 11: Admin API

**Files:**
- Create: `datagen/interfaces/admin/DataGenAdminController.java`
- Create: `datagen/application/dto/ScenarioDto.java`
- Create: `datagen/application/dto/CreateScenarioRequest.java`

> **评审 P2 #11 修复**：Controller 返回 DTO 而非领域实体，错误走 ApiException + ErrorCode。

- [ ] **Step 1: DTO 类（ScenarioDto / CreateScenarioRequest）**

- [ ] **Step 2: DataGenAdminController（返回 DTO，走 ApiException）**

```java
@RestController
@RequestMapping("/api/v1/admin/datagen")
@RequiredArgsConstructor
public class DataGenAdminController {
    // POST /scenarios, GET /scenarios, POST /scenarios/{id}/start|stop
    // GET /labels, GET /evaluation
    // 全部返回 DTO，不暴露领域实体
}
```

- [ ] **Step 3: 编译 + Commit**

---

## Task 12: TelemetrySimulator 迁移 + 清理

**Files:**
- Delete: `TelemetrySimulator.java`
- Modify: `application.yml`

- [ ] **Step 1: 确认无其他类引用 TelemetrySimulator**

Run: `rg "TelemetrySimulator" smart-livestock-server/src/ 2>/dev/null`


> **前置**：GPS 收敛设计已实施（GpsSimulator 已删除，application.yml 中 `gps.simulator` 段已移除）。Task 12 只处理 TelemetrySimulator 的删除 + `telemetry.simulator` 配置段清理。

- [ ] **Step 2: 删除 TelemetrySimulator.java**

- [ ] **Step 3: 编译 + 测试**

Run: `./gradlew compileJava compileTestJava -q 2>&1 | tail -20`

- [ ] **Step 4: Commit**

---

## Task 13: 全量验证

- [ ] **Step 1: 全量编译**

Run: `./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 2: datagen 单元测试**

Run: `./gradlew test --tests "*.datagen.*" 2>&1 | tail -20`

- [ ] **Step 3: 旧测试不破坏**

Run: `./gradlew test --tests "*.iot.*" 2>&1 | tail -20`

- [ ] **Step 4: 最终 Commit**

---

## Self-Review（评审修复验证）

| 评审问题 | 严重度 | 修复位置 | 状态 |
|---------|--------|---------|------|
| #2 Task 依赖顺序 | P0 | persistence（Task 6）提前到 service（Task 7）之前 | ✅ |
| #3 设计文档 §8 与路线图矛盾 | P1 | 设计文档已修复 | ✅ |
| #4 缺 domain repository 接口层 | P1 | Task 4 新增 domain repository 接口 | ✅ |
| #5 SynthesisScenario 应继承 AggregateRoot | P1 | Task 3 Step 1 | ✅ |
| #6 AnomalyScoreQueryPortImpl try-catch 反模式 | P1 | Task 5 Step 2（PersistenceException + 可用性标志） | ✅ |
| #7 内存状态重启丢失 | P1 | Task 7 已知简化声明 + 设计 §8A | ✅ |
| #8 事务传播边界未定义 | P1 | Task 7 generate() 去 @Transactional + Task 9 label 独立事务 | ✅ |
| #9 selectAnomalyTargets 算法未定义 | P2 | Task 7 Step 2 明确调用时机 | ✅ |
| #10 历史数据无标签 | P2 | Task 1 Step 1 注释 | ✅ |
| #11 Admin API 缺 DTO + i18n | P2 | Task 11 返回 DTO + ApiException | ✅ |
| #12 datagen 生产环境形态 | P2 | backlog，Phase B 接受现状 | ✅（记录） |

**Task 依赖链验证（编译顺序）：**

```
Task 1 (V38) → 无依赖
Task 2 (枚举) → 无依赖
Task 3 (模型) → Task 2
Task 4 (domain repo 接口) → Task 3
Task 5 (ACL 端口) → Task 3（DTO 引用 model）
Task 6 (持久化 impl) → Task 4（implements domain 接口）
Task 7 (SynthesisService) → Task 4, 5, 6（注入 domain repo + ACL + label service）
Task 8 (SynthesisRunner) → Task 7
Task 9 (GroundTruthLabelService) → Task 4, 6
Task 10 (EvaluationService) → Task 5, 9
Task 11 (Admin API) → Task 7, 9, 10
Task 12 (Simulator 删除 + GPS) → Task 7, 8
> **前置依赖**：GPS 收敛设计（`2026-06-26-gps-simulator-consolidation-design.md`）必须在 datagen-v1 之前实施。datagen 迁移的 TelemetrySimulator 已包含随机游走 GPS 逻辑（非原始写死坐标版本）。
Task 13 (全量验证) → 全部
```

每个 Task 编译时其依赖的 Task 已产出类型——无前向引用。

---

## 执行交接

Plan v2（评审修订版）完成并保存于 `docs/superpowers/plans/2026-06-26-datagen-v1-plan.md`。两种执行方式：

1. **Subagent-Driven（推荐）** — 每个 Task 派一个新 subagent，任务间评审，快速迭代。
2. **Inline Execution** — 本会话内用 executing-plans 批量执行，检查点评审。
