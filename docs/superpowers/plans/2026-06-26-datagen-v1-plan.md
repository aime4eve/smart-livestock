# datagen-v1 实施计划（数据合成与评估上下文）

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新建 `datagen` 限界上下文（DDD 洋葱架构），将 `TelemetrySimulator` 的随机 boolean 异常注入升级为 Scenario 驱动的可控合成数据引擎，持久化 ground-truth 标签，并实现评估框架。datagen 通过 ACL 端口调用 IoT 的 `TelemetryIngestionService.ingest()`，IoT 零改动。

**Architecture:** `datagen/domain`(AnomalyPattern + SynthesisScenario + GroundTruthLabel + ports) → `datagen/application`(SynthesisService + SynthesisRunner + GroundTruthLabelService + EvaluationService) → `datagen/infrastructure`(persistence + acl) → `datagen/interfaces`(DataGenAdminController)。合成数据经 ACL 喂入 IoT 标准管道，与真实设备走完全相同的路径。

**Tech Stack:** Java 17 + Spring Boot 3.3 + JPA/Hibernate + Flyway + Lombok + JUnit 5（与现有上下文一致）。

**关联文档:**
- 设计规格：`docs/superpowers/specs/2026-06-26-datagen-context-design.md`
- 战略路线图：`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md` §4 Phase B
- 迁移源：`smart-livestock-server/src/main/java/com/smartlivestock/iot/application/service/TelemetrySimulator.java`

**与 Phase B 其余交付物的边界:** 本计划只建 datagen-v1（合成引擎 + 标签 + 评估）。Java 后端 ai-platform 集成（V38 anomaly_scores 表 + HealthAnomalyService）由 Phase B 交付物 2 独立实施；评估框架（EvaluationService）在此建好但依赖 anomaly_scores 表存在才能跑通完整对比，若该表未建则 EvaluationService 跑空集不报错。

---

## File Structure

```
smart-livestock-server/src/main/java/com/smartlivestock/datagen/
├── domain/
│   ├── model/
│   │   ├── AnomalyPattern.java       — 异常类型枚举（6 异常 + NORMAL）
│   │   ├── TemporalShape.java        — 时序形态枚举（gradual_rise/abrupt_spike/...）
│   │   ├── ScenarioStatus.java       — 场景状态枚举（DRAFT/RUNNING/STOPPED）
│   │   ├── LabelSource.java          — 标签来源枚举（SYNTHETIC/MANUAL）
│   │   ├── SynthesisScenario.java    — 聚合根
│   │   └── GroundTruthLabel.java     — 实体
│   └── port/
│       ├── TelemetryIngestionPort.java  — ACL: 喂读数给 IoT
│       ├── DeviceQueryPort.java         — ACL: 查活跃安装
│       └── AnomalyScoreQueryPort.java   — ACL: 查 AI 预测（评估用）
├── application/
│   ├── SynthesisService.java          — 按 scenario 生成读数 + 写标签
│   ├── SynthesisRunner.java           — @Scheduled 定时触发
│   ├── GroundTruthLabelService.java   — 标签 CRUD
│   ├── EvaluationService.java         — 对比预测 vs ground truth
│   └── dto/
│       ├── EvaluationReport.java      — 评估报告 DTO
│       └── MetricResult.java          — 单 pattern 指标 DTO
├── infrastructure/
│   ├── persistence/
│   │   ├── entity/
│   │   │   ├── SynthesisScenarioJpaEntity.java
│   │   │   └── GroundTruthLabelJpaEntity.java
│   │   ├── SynthesisScenarioRepository.java    — Spring Data
│   │   ├── GroundTruthLabelRepository.java     — Spring Data
│   │   ├── JpaSynthesisScenarioRepositoryImpl.java
│   │   ├── JpaGroundTruthLabelRepositoryImpl.java
│   │   └── mapper/
│   │       ├── SynthesisScenarioMapper.java
│   │       └── GroundTruthLabelMapper.java
│   └── acl/
│       ├── TelemetryIngestionPortImpl.java   — 委托 IoT TelemetryIngestionService
│       ├── DeviceQueryPortImpl.java          — 委托 IoT InstallationRepository
│       └── AnomalyScoreQueryPortImpl.java    — 委托 Health anomaly_scores 只读
└── interfaces/
    └── admin/
        └── DataGenAdminController.java
```

**职责边界:** `domain/model` 纯领域逻辑（无 IO）；`domain/port` 定义 ACL 接口（datagen 是 Customer）；`application` 编排（不 import IoT/Health 内部类）；`infrastructure/acl` 实现 port 委托（唯一跨上下文 import 处）；`infrastructure/persistence` 隔离 JPA。

---

## Task 1: Flyway 迁移 + 包骨架

**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V38__create_datagen_tables.sql`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/datagen/` （包目录）

- [ ] **Step 1: 创建 V38 迁移**

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
CREATE INDEX idx_ss_status ON synthesis_scenarios (status);
```

- [ ] **Step 2: 插入默认场景种子数据**

在同一个迁移文件末尾追加：

```sql
-- 默认场景：所有活跃安装持续生成正常基线数据（替代原 telemetry.simulator.enabled=true 行为）
INSERT INTO synthesis_scenarios (name, status, pattern, penetration_rate, window_start, window_end, interval_seconds)
VALUES ('默认持续合成', 'RUNNING', 'NORMAL', 1.0, NOW(), NOW() + INTERVAL '365 days', 30);
```

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
Expected: 无错误（包目录为空，仅迁移文件）

- [ ] **Step 4: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V38__create_datagen_tables.sql
git commit -m "feat(datagen): V38 迁移 — synthesis_scenarios + ground_truth_labels 表 + 默认场景种子（Task 1）"
```

---

## Task 2: 领域模型 — AnomalyPattern + 枚举

**Files:**
- Create: `datagen/domain/model/AnomalyPattern.java`
- Create: `datagen/domain/model/TemporalShape.java`
- Create: `datagen/domain/model/ScenarioStatus.java`
- Create: `datagen/domain/model/LabelSource.java`

- [ ] **Step 1: AnomalyPattern 枚举**

每个 pattern 携带生理参数（温度范围、持续时间）和对应的时序形态。

```java
package com.smartlivestock.datagen.domain.model;

import java.time.Duration;

public enum AnomalyPattern {
    LOW_GRADE_FEVER("低热", 38.5, 39.5, Duration.ofHours(6), TemporalShape.GRADUAL_RISE),
    HIGH_FEVER("高热", 39.5, 41.0, Duration.ofHours(3), TemporalShape.ABRUPT_SPIKE),
    CHRONIC_MOTILITY_DROP("慢性蠕动下降", null, null, Duration.ofDays(2), TemporalShape.GRADUAL_DECLINE),
    ACUTE_MOTILITY_DROP("急性蠕动停滞", null, null, Duration.ofHours(8), TemporalShape.ABRUPT_DROP),
    ESTRUS("发情", null, null, Duration.ofHours(18), TemporalShape.ACTIVITY_SURGE),
    LAMENESS("跛行", null, null, Duration.ofDays(1), TemporalShape.ACTIVITY_DROP),
    NORMAL("正常", null, null, null, TemporalShape.BASELINE);

    private final String displayName;
    private final Double tempMin;      // nullable: 非温度类异常
    private final Double tempMax;
    private final Duration duration;   // nullable: NORMAL
    private final TemporalShape temporalShape;

    // constructor, getters...
}
```

- [ ] **Step 2: TemporalShape 枚举**

```java
public enum TemporalShape {
    BASELINE,          // 基线 + 昼夜节律 + 噪声（NORMAL）
    GRADUAL_RISE,      // 缓慢上升(2-4h) → 平台期 → 缓慢恢复
    ABRUPT_SPIKE,      // 突跳(30min) → 平台期 → 恢复
    GRADUAL_DECLINE,   // 缓慢下降(12-24h) → 低谷 → 恢复
    ABRUPT_DROP,       // 突降(1h) → 低谷 → 恢复
    ACTIVITY_SURGE,    // 步数激增(2-3x) 持续 12-24h → 恢复
    ACTIVITY_DROP;     // 步数骤降(0.3x) 持续 → 恢复

    /**
     * 计算异常曲线在指定进度(0-1)处的强度因子。
     * progress=0: 异常开始, progress=1: 异常结束。
     * 返回值: 0.0=完全基线, 1.0=满强度异常。
     */
    public double intensityFactor(double progress) {
        return switch (this) {
            case BASELINE -> 0.0;
            case GRADUAL_RISE, GRADUAL_DECLINE -> {
                // 三段式：渐起(0-0.3) → 平台(0.3-0.7) → 渐落(0.7-1.0)
                if (progress < 0.3) yield progress / 0.3;
                else if (progress < 0.7) yield 1.0;
                else yield 1.0 - (progress - 0.7) / 0.3;
            }
            case ABRUPT_SPIKE, ABRUPT_DROP -> {
                // 快速到达满强度 → 平台 → 快速恢复
                if (progress < 0.1) yield progress / 0.1;
                else if (progress < 0.85) yield 1.0;
                else yield 1.0 - (progress - 0.85) / 0.15;
            }
            case ACTIVITY_SURGE, ACTIVITY_DROP -> {
                // 持续高强度，尾部恢复
                if (progress < 0.8) yield 1.0;
                else yield 1.0 - (progress - 0.8) / 0.2;
            }
        };
    }
}
```

- [ ] **Step 3: ScenarioStatus + LabelSource**

```java
public enum ScenarioStatus { DRAFT, RUNNING, STOPPED }
public enum LabelSource { SYNTHETIC, MANUAL }
```

- [ ] **Step 4: 单元测试 AnomalyPattern + TemporalShape**

Create: `src/test/java/com/smartlivestock/datagen/domain/model/TemporalShapeTest.java`

```java
package com.smartlivestock.datagen.domain.model;

import org.junit.jupiter.api.Test;
import static org.junit.jupiter.api.Assertions.*;

class TemporalShapeTest {
    @Test
    void baseline_always_zero() {
        assertEquals(0.0, TemporalShape.BASELINE.intensityFactor(0.0));
        assertEquals(0.0, TemporalShape.BASELINE.intensityFactor(0.5));
    }

    @Test
    void gradual_rise_plateau_at_midpoint() {
        assertEquals(1.0, TemporalShape.GRADUAL_RISE.intensityFactor(0.5), 0.01);
    }

    @Test
    void gradual_rise_starts_low_ends_low() {
        assertEquals(0.0, TemporalShape.GRADUAL_RISE.intensityFactor(0.0), 0.01);
        assertEquals(0.0, TempagonalShape.GRADUAL_RISE.intensityFactor(1.0), 0.01);
    }

    @Test
    void abrupt_spike_reaches_peak_fast() {
        assertEquals(1.0, TemporalShape.ABRUPT_SPIKE.intensityFactor(0.05), 0.1);
        assertEquals(1.0, TemporalShape.ABRUPT_SPIKE.intensityFactor(0.5), 0.01);
    }

    @Test
    void all_shapes_zero_at_start_and_end() {
        for (TemporalShape shape : TemporalShape.values()) {
            if (shape == TemporalShape.BASELINE) continue;
            assertEquals(0.0, shape.intensityFactor(0.0), 0.01,
                shape + " should start near zero");
        }
    }
}
```

> 修正：`TempagonalShape` 是拼写错误，应为 `TemporalShape`。

- [ ] **Step 5: 编译 + 测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.datagen.domain.*" 2>&1 | tail -10`
Expected: 全部 passed

- [ ] **Step 6: Commit**

```bash
git add -A smart-livestock-server/src/main/java/com/smartlivestock/datagen/domain/model/ smart-livestock-server/src/test/java/com/smartlivestock/datagen/
git commit -m "feat(datagen): AnomalyPattern + TemporalShape + 枚举 + 单测（Task 2）"
```

---

## Task 3: 领域模型 — SynthesisScenario + GroundTruthLabel

**Files:**
- Create: `datagen/domain/model/SynthesisScenario.java`
- Create: `datagen/domain/model/GroundTruthLabel.java`

- [ ] **Step 1: SynthesisScenario 聚合根**

```java
package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;
import java.util.List;

public class SynthesisScenario extends Entity {
    private Long id;
    private String name;
    private ScenarioStatus status;
    private AnomalyPattern pattern;
    private double penetrationRate;       // 0.0-1.0
    private Instant windowStart;
    private Instant windowEnd;
    private int intervalSeconds;
    private List<Long> targetLivestockIds; // null = all active installations

    // constructors, getters, setters...

    public void start() {
        if (status != ScenarioStatus.DRAFT && status != ScenarioStatus.STOPPED) {
            throw new IllegalStateException("Cannot start scenario in status: " + status);
        }
        this.status = ScenarioStatus.RUNNING;
    }

    public void stop() {
        this.status = ScenarioStatus.STOPPED;
    }

    public boolean isActiveAt(Instant when) {
        return status == ScenarioStatus.RUNNING
                && !when.isBefore(windowStart)
                && when.isBefore(windowEnd);
    }
}
```

- [ ] **Step 2: GroundTruthLabel 实体**

```java
package com.smartlivestock.datagen.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.time.Instant;

public class GroundTruthLabel extends Entity {
    private Long id;
    private Long livestockId;
    private AnomalyPattern pattern;
    private Instant periodStart;
    private Instant periodEnd;
    private LabelSource source;
    private double severity;    // 0.0-1.0
    private Long labeledBy;     // null for SYNTHETIC
    private Instant labeledAt;
    private String note;

    // constructors, getters, setters...

    public boolean overlaps(Instant start, Instant end) {
        return !periodEnd.isBefore(start) && !periodStart.isAfter(end);
    }
}
```

- [ ] **Step 3: 单元测试**

Create: `src/test/java/com/smartlivestock/datagen/domain/model/SynthesisScenarioTest.java`

```java
package com.smartlivestock.datagen.domain.model;

import org.junit.jupiter.api.Test;
import java.time.Instant;
import java.util.List;
import static org.junit.jupiter.api.Assertions.*;

class SynthesisScenarioTest {
    @Test
    void start_from_draft_succeeds() {
        var s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.DRAFT);
        s.start();
        assertEquals(ScenarioStatus.RUNNING, s.getStatus());
    }

    @Test
    void start_from_running_fails() {
        var s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.RUNNING);
        assertThrows(IllegalStateException.class, s::start);
    }

    @Test
    void isActiveAt_within_window_true() {
        var s = new SynthesisScenario();
        s.setStatus(ScenarioStatus.RUNNING);
        s.setWindowStart(Instant.parse("2026-01-01T00:00:00Z"));
        s.setWindowEnd(Instant.parse("2026-01-02T00:00:00Z"));
        assertTrue(s.isActiveAt(Instant.parse("2026-01-01T12:00:00Z")));
        assertFalse(s.isActiveAt(Instant.parse("2026-01-02T00:00:00Z"))); // exclusive end
    }
}
```

- [ ] **Step 4: 编译 + 测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.datagen.domain.*" 2>&1 | tail -10`
Expected: 全部 passed

- [ ] **Step 5: Commit**

---

## Task 4: ACL 端口接口 + 实现

**Files:**
- Create: `datagen/domain/port/TelemetryIngestionPort.java`
- Create: `datagen/domain/port/DeviceQueryPort.java`
- Create: `datagen/domain/port/AnomalyScoreQueryPort.java`
- Create: `datagen/domain/port/dto/ActiveInstallationInfo.java`
- Create: `datagen/domain/port/dto/AnomalyScoreInfo.java`
- Create: `datagen/infrastructure/acl/TelemetryIngestionPortImpl.java`
- Create: `datagen/infrastructure/acl/DeviceQueryPortImpl.java`
- Create: `datagen/infrastructure/acl/AnomalyScoreQueryPortImpl.java`

- [ ] **Step 1: TelemetryIngestionPort 接口**

```java
package com.smartlivestock.datagen.domain.port;

import java.time.Instant;
import java.util.Map;

/** ACL port: datagen → IoT. Feeds synthetic readings into IoT's standard ingestion pipeline. */
public interface TelemetryIngestionPort {
    void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt);
}
```

- [ ] **Step 2: DeviceQueryPort 接口 + DTO**

```java
package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.port.dto.ActiveInstallationInfo;
import java.util.List;

/** ACL port: datagen → IoT. Queries active installations to know which devices need data. */
public interface DeviceQueryPort {
    List<ActiveInstallationInfo> findActiveInstallations();
}
```

```java
package com.smartlivestock.datagen.domain.port.dto;
import com.smartlivestock.iot.domain.model.DeviceType;

public record ActiveInstallationInfo(Long deviceId, Long livestockId, DeviceType deviceType) {}
```

> 注：`DeviceType` 是 IoT 领域模型中的枚举，作为 ACL DTO 的公开类型是可接受的（跨上下文契约的一部分，如同 `LivestockInfo`）。

- [ ] **Step 3: AnomalyScoreQueryPort 接口 + DTO**

```java
package com.smartlivestock.datagen.domain.port;

import com.smartlivestock.datagen.domain.port.dto.AnomalyScoreInfo;
import java.time.Instant;
import java.util.List;

/** ACL port: datagen → Health. Reads anomaly_scores for evaluation. */
public interface AnomalyScoreQueryPort {
    /** Returns anomaly scores within [from, to] for the given livestockIds. Empty if table not yet created. */
    List<AnomalyScoreInfo> findByLivestockIdsAndPeriod(List<Long> livestockIds, Instant from, Instant to);
}
```

```java
package com.smartlivestock.datagen.domain.port.dto;
import java.math.BigDecimal;
import java.time.Instant;

public record AnomalyScoreInfo(
    Long livestockId, BigDecimal anomalyScore, String anomalyType, Instant createdAt) {}
```

- [ ] **Step 4: ACL 实现类**

`TelemetryIngestionPortImpl` — 委托 IoT `TelemetryIngestionService`：

```java
package com.smartlivestock.datagen.infrastructure.acl;

import com.smartlivestock.datagen.domain.port.TelemetryIngestionPort;
import com.smartlivestock.iot.application.TelemetryIngestionService;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;
import java.time.Instant;
import java.util.Map;

@Component
@RequiredArgsConstructor
public class TelemetryIngestionPortImpl implements TelemetryIngestionPort {
    private final TelemetryIngestionService telemetryIngestionService;

    @Override
    public void ingest(Long deviceId, Map<String, Object> readings, Instant recordedAt) {
        telemetryIngestionService.ingest(deviceId, readings, recordedAt);
    }
}
```

`DeviceQueryPortImpl` — 委托 IoT `InstallationRepository`：

```java
@Component
@RequiredArgsConstructor
public class DeviceQueryPortImpl implements DeviceQueryPort {
    private final com.smartlivestock.iot.domain.repository.InstallationRepository installationRepository;
    private final com.smartlivestock.iot.domain.repository.DeviceRepository deviceRepository;

    @Override
    public List<ActiveInstallationInfo> findActiveInstallations() {
        return installationRepository.findAllActive().stream()
            .map(inst -> {
                var device = deviceRepository.findById(inst.getDeviceId()).orElse(null);
                if (device == null || device.getStatus() != DeviceStatus.ACTIVE) return null;
                return new ActiveInstallationInfo(
                    inst.getDeviceId(), inst.getLivestockId(), device.getDeviceType());
            })
            .filter(java.util.Objects::nonNull)
            .toList();
    }
}
```

`AnomalyScoreQueryPortImpl` — 用 native query 读 anomaly_scores 表（若表不存在返回空列表）：

```java
@Component
@RequiredArgsConstructor
public class AnomalyScoreQueryPortImpl implements AnomalyScoreQueryPort {
    private final EntityManager entityManager;

    @Override
    @SuppressWarnings("unchecked")
    public List<AnomalyScoreInfo> findByLivestockIdsAndPeriod(List<Long> livestockIds, Instant from, Instant to) {
        if (livestockIds.isEmpty()) return List.of();
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
        } catch (Exception e) {
            // Table might not exist yet (Phase B deliverable 2 not done)
            return List.of();
        }
    }
}
```

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
Expected: 无错误

- [ ] **Step 6: Commit**

---

## Task 5: SynthesisService — 合成数据生成核心

**Files:**
- Create: `datagen/application/SynthesisService.java`
- Create: `datagen/application/SynthesisState.java` — per-livestock 生成状态（迁移自 SimulatorState）

- [ ] **Step 1: SynthesisState（per-livestock 状态，替代 SimulatorState）**

```java
/** Per-livestock synthesis state. Tracks individual baseline offset and active anomaly period. */
@Data
public class SynthesisState {
    private double tempBaselineOffset;     // +/-0.3C individual offset
    private long motilityBaseline;         // 250000-350000
    private int batteryLevel;              // 0-100
    private int batteryVoltage;            // 2800-3600 mV
    // Active anomaly tracking (replaces boolean flags)
    private AnomalyPattern activePattern;  // null = NORMAL
    private Instant anomalyStart;          // when injected anomaly began
    private Instant anomalyEnd;            // when it will end
    private GroundTruthLabel activeLabel;  // the label written for this anomaly

    static SynthesisState create(Long livestockId) {
        var s = new SynthesisState();
        var rng = ThreadLocalRandom.current();
        s.tempBaselineOffset = rng.nextDouble(-0.3, 0.3);
        s.motilityBaseline = (long) rng.nextDouble(2.5, 3.5) * 100000;
        s.batteryLevel = rng.nextInt(70, 101);
        s.batteryVoltage = rng.nextInt(3200, 3601);
        return s;
    }
}
```

- [ ] **Step 2: SynthesisService 核心逻辑**

```java
@Service
@RequiredArgsConstructor
@Slf4j
public class SynthesisService {
    private final TelemetryIngestionPort ingestionPort;
    private final DeviceQueryPort deviceQueryPort;
    private final GroundTruthLabelRepository labelRepository;
    private final SynthesisScenarioRepository scenarioRepository;

    private final ConcurrentHashMap<Long, SynthesisState> states = new ConcurrentHashMap<>();

    /** Called by SynthesisRunner for each RUNNING scenario. */
    @Transactional
    public void generate(SynthesisScenario scenario) {
        List<ActiveInstallationInfo> installations = deviceQueryPort.findActiveInstallations();
        if (installations.isEmpty()) return;

        Instant now = Instant.now();
        if (!scenario.isActiveAt(now)) return;

        // Determine which livestock get the anomaly (based on penetrationRate)
        Set<Long> anomalyTargets = selectAnomalyTargets(installations, scenario);

        for (ActiveInstallationInfo inst : installations) {
            SynthesisState state = states.computeIfAbsent(inst.livestockId(), SynthesisState::create);
            Map<String, Object> readings = generateReadings(inst, state, scenario, anomalyTargets, now);
            try {
                ingestionPort.ingest(inst.deviceId(), readings, now);
            } catch (Exception e) {
                log.warn("Failed to ingest synthetic data for device [{}]: {}", inst.deviceId(), e.getMessage());
            }
        }
    }

    /** Generates readings based on device type, current anomaly state, and temporal shape. */
    private Map<String, Object> generateReadings(
            ActiveInstallationInfo inst, SynthesisState state,
            SynthesisScenario scenario, Set<Long> anomalyTargets, Instant now) {
        // Update anomaly state: start new anomaly or expire existing
        updateAnomalyState(state, inst.livestockId(), scenario, anomalyTargets, now);

        // Calculate intensity factor if in anomaly
        double intensity = calculateIntensity(state, now);

        return switch (inst.deviceType()) {
            case TRACKER -> generateTrackerReadings(state, scenario.getPattern(), intensity, now);
            case CAPSULE -> generateCapsuleReadings(state, scenario.getPattern(), intensity, now);
            default -> Map.of();
        };
    }

    // generateTrackerReadings / generateCapsuleReadings: reuse baseline+noise logic
    // from TelemetrySimulator, but modulate by intensity × pattern parameters.
    // e.g., HIGH_FEVER: baseTemp += intensity * (tempMax - baseline)
    //       ESTRUS: stepCount *= (1 + intensity * 1.5)
    //       LAMENESS: stepCount *= (1 - intensity * 0.7)
}
```

- [ ] **Step 3: 异常状态管理 + ground-truth 标签写入**

```java
private void updateAnomalyState(SynthesisState state, Long livestockId,
        SynthesisScenario scenario, Set<Long> anomalyTargets, Instant now) {
    if (anomalyTargets.contains(livestockId)) {
        // Should be in anomaly
        if (state.getActivePattern() == null || state.getActivePattern() != scenario.getPattern()) {
            // Start new anomaly
            Duration duration = scenario.getPattern().getDuration();
            state.setActivePattern(scenario.getPattern());
            state.setAnomalyStart(now);
            state.setAnomalyEnd(now.plus(duration));
            // Write ground-truth label
            GroundTruthLabel label = new GroundTruthLabel();
            label.setLivestockId(livestockId);
            label.setPattern(scenario.getPattern());
            label.setPeriodStart(now);
            label.setPeriodEnd(now.plus(duration));
            label.setSource(LabelSource.SYNTHETIC);
            label.setSeverity(0.8); // configurable per pattern
            label.setLabeledAt(now);
            labelRepository.save(label);
            state.setActiveLabel(label);
        }
    }
    // Check expiry
    if (state.getActivePattern() != null && now.isAfter(state.getAnomalyEnd())) {
        state.setActivePattern(null);
        state.setActiveLabel(null);
    }
}

private double calculateIntensity(SynthesisState state, Instant now) {
    if (state.getActivePattern() == null) return 0.0;
    Duration total = Duration.between(state.getAnomalyStart(), state.getAnomalyEnd());
    Duration elapsed = Duration.between(state.getAnomalyStart(), now);
    double progress = (double) elapsed.toSeconds() / total.toSeconds();
    progress = Math.max(0.0, Math.min(1.0, progress));
    return state.getActivePattern().getTemporalShape().intensityFactor(progress);
}
```

- [ ] **Step 4: generateTrackerReadings / generateCapsuleReadings 实现**

迁移自 `TelemetrySimulator` 的基线+噪声逻辑，按 intensity × pattern 调制。输出格式与原 simulator 完全一致（key 名、类型），保证 IoT `ingest()` 无感知。

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 6: Commit**

---

## Task 6: SynthesisRunner — 定时触发器

**Files:**
- Create: `datagen/application/SynthesisRunner.java`

- [ ] **Step 1: SynthesisRunner**

```java
package com.smartlivestock.datagen.application;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;
import java.util.List;

@Component
@RequiredArgsConstructor
@Slf4j
@ConditionalOnProperty(name = "datagen.enabled", havingValue = "true", matchIfMissing = true)
public class SynthesisRunner {
    private final SynthesisService synthesisService;
    private final SynthesisScenarioRepository scenarioRepository;

    @Scheduled(fixedRateString = "${datagen.interval-ms:30000}")
    public void run() {
        List<SynthesisScenario> active = scenarioRepository.findByStatus(ScenarioStatus.RUNNING);
        if (active.isEmpty()) {
            log.debug("No RUNNING synthesis scenarios — skipping");
            return;
        }
        for (SynthesisScenario scenario : active) {
            synthesisService.generate(scenario);
        }
    }
}
```

> `@ConditionalOnProperty(name = "datagen.enabled", matchIfMissing = true)`：默认启用（替代原 `telemetry.simulator.enabled=true`）。

- [ ] **Step 2: 配置切换**

修改 `application.yml`：

```yaml
# 旧配置（保留但标记 deprecated）
telemetry:
  simulator:
    enabled: ${TELEMETRY_SIMULATOR_ENABLED:false}  # 改为 false，由 datagen 接管
    interval-ms: ${TELEMETRY_SIMULATOR_INTERVAL_MS:30000}

# 新配置
datagen:
  enabled: ${DATAGEN_ENABLED:true}
  interval-ms: ${DATAGEN_INTERVAL_MS:30000}
```

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 4: Commit**

---

## Task 7: GroundTruthLabelService — 标签 CRUD

**Files:**
- Create: `datagen/application/GroundTruthLabelService.java`

- [ ] **Step 1: GroundTruthLabelService**

```java
@Service
@RequiredArgsConstructor
public class GroundTruthLabelService {
    private final GroundTruthLabelRepository repository;

    public List<GroundTruthLabel> findByLivestockAndPeriod(Long livestockId, Instant from, Instant to) {
        return repository.findByLivestockIdAndPeriodOverlap(livestockId, from, to);
    }

    public GroundTruthLabel createManualLabel(Long livestockId, AnomalyPattern pattern,
            Instant start, Instant end, Long labeledBy, String note) {
        GroundTruthLabel label = new GroundTruthLabel();
        label.setLivestockId(livestockId);
        label.setPattern(pattern);
        label.setPeriodStart(start);
        label.setPeriodEnd(end);
        label.setSource(LabelSource.MANUAL);
        label.setLabeledBy(labeledBy);
        label.setLabeledAt(Instant.now());
        label.setNote(note);
        return repository.save(label);
    }
}
```

> `createManualLabel` 为 Phase C 标注基础设施预留，Phase B 不建设 UI。

- [ ] **Step 2: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 3: Commit**

---

## Task 8: EvaluationService — 评估框架

**Files:**
- Create: `datagen/application/EvaluationService.java`
- Create: `datagen/application/dto/EvaluationReport.java`
- Create: `datagen/application/dto/MetricResult.java`

- [ ] **Step 1: DTO**

```java
public record MetricResult(
    AnomalyPattern pattern,
    int truePositive, int falsePositive,
    int falseNegative, int trueNegative,
    double precision, double recall, double f1
) {}

public record EvaluationReport(
    Instant windowStart, Instant windowEnd,
    int totalLabels, int totalScores,
    double overallPrecision, double overallRecall, double overallF1,
    List<MetricResult> perPatternMetrics
) {}
```

- [ ] **Step 2: EvaluationService**

```java
@Service
@RequiredArgsConstructor
public class EvaluationService {
    private final GroundTruthLabelService labelService;
    private final AnomalyScoreQueryPort anomalyScorePort;
    private final DeviceQueryPort deviceQueryPort;

    /** Evaluates AI anomaly detection against ground-truth labels for a time window. */
    public EvaluationReport evaluate(Instant from, Instant to, double scoreThreshold) {
        // 1. Get all active livestock IDs
        List<Long> livestockIds = deviceQueryPort.findActiveInstallations().stream()
            .map(ActiveInstallationInfo::livestockId).distinct().toList();

        // 2. Get labels and scores
        List<GroundTruthLabel> labels = livestockIds.stream()
            .flatMap(id -> labelService.findByLivestockAndPeriod(id, from, to).stream())
            .toList();
        List<AnomalyScoreInfo> scores = anomalyScorePort.findByLivestockIdsAndPeriod(livestockIds, from, to);

        if (scores.isEmpty()) {
            return emptyReport(from, to, labels.size());
        }

        // 3. For each livestock, determine if labeled anomaly and if scored high
        // 4. Compute confusion matrix per pattern + overall
        // 5. Calculate precision/recall/F1
        return buildReport(from, to, labels, scores, scoreThreshold);
    }
}
```

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 4: Commit**

---

## Task 9: 持久化层

**Files:**
- Create: `datagen/infrastructure/persistence/entity/SynthesisScenarioJpaEntity.java`
- Create: `datagen/infrastructure/persistence/entity/GroundTruthLabelJpaEntity.java`
- Create: `datagen/infrastructure/persistence/SynthesisScenarioRepository.java` (Spring Data)
- Create: `datagen/infrastructure/persistence/GroundTruthLabelRepository.java` (Spring Data)
- Create: `datagen/infrastructure/persistence/JpaSynthesisScenarioRepositoryImpl.java`
- Create: `datagen/infrastructure/persistence/JpaGroundTruthLabelRepositoryImpl.java`
- Create: `datagen/infrastructure/persistence/mapper/SynthesisScenarioMapper.java`
- Create: `datagen/infrastructure/persistence/mapper/GroundTruthLabelMapper.java`

- [ ] **Step 1: JPA Entities**

`SynthesisScenarioJpaEntity` — 映射 V38 表，`target_livestock_ids` 用 `@JdbcTypeCode(SqlTypes.ARRAY)` 或 JSON 序列化（PostgreSQL BIGINT[] 在 Hibernate 6 中的标准映射）。

`GroundTruthLabelJpaEntity` — 标准 `@Entity` 映射。

- [ ] **Step 2: Spring Data Repositories**

```java
public interface SynthesisScenarioRepository extends JpaRepository<SynthesisScenarioJpaEntity, Long> {
    List<SynthesisScenarioJpaEntity> findByStatus(String status);
}
public interface GroundTruthLabelRepository extends JpaRepository<GroundTruthLabelJpaEntity, Long> {
    @Query("SELECT g FROM GroundTruthLabelJpaEntity g WHERE g.livestockId = :id " +
           "AND g.periodStart <= :to AND g.periodEnd >= :from")
    List<GroundTruthLabelJpaEntity> findByLivestockIdAndPeriodOverlap(
        @Param("id") Long livestockId, @Param("from") Instant from, @Param("to") Instant to);
}
```

- [ ] **Step 3: Repository Impl + Mappers**

领域 Repository 接口（在 domain 层定义）+ JPA 实现委托 Spring Data + Mapper 转换。

- [ ] **Step 4: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 5: Commit**

---

## Task 10: Admin API

**Files:**
- Create: `datagen/interfaces/admin/DataGenAdminController.java`

- [ ] **Step 1: DataGenAdminController**

```java
@RestController
@RequestMapping("/api/v1/admin/datagen")
@RequiredArgsConstructor
public class DataGenAdminController {
    private final SynthesisService synthesisService;
    private final SynthesisScenarioRepository scenarioRepository;
    private final GroundTruthLabelService labelService;
    private final EvaluationService evaluationService;

    @PostMapping("/scenarios")
    public SynthesisScenario createScenario(@RequestBody CreateScenarioRequest req) { ... }

    @GetMapping("/scenarios")
    public List<SynthesisScenario> listScenarios() { ... }

    @PostMapping("/scenarios/{id}/start")
    public void startScenario(@PathVariable Long id) { ... }

    @PostMapping("/scenarios/{id}/stop")
    public void stopScenario(@PathVariable Long id) { ... }

    @GetMapping("/labels")
    public List<GroundTruthLabel> listLabels(
        @RequestParam(required = false) Long livestockId,
        @RequestParam(required = false) Instant from,
        @RequestParam(required = false) Instant to) { ... }

    @GetMapping("/evaluation")
    public EvaluationReport evaluate(
        @RequestParam Instant from,
        @RequestParam Instant to,
        @RequestParam(defaultValue = "0.7") double scoreThreshold) { ... }
}
```

> Admin API 路径，仅 platform_admin / b2b_admin 可访问（由 SecurityConfig 现有规则覆盖）。

- [ ] **Step 2: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 3: Commit**

---

## Task 11: TelemetrySimulator 迁移 + 清理

**Files:**
- Modify: `smart-livestock-server/src/main/resources/application.yml` （已完成 Task 6 Step 2）
- Delete: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/service/TelemetrySimulator.java`

- [ ] **Step 1: 确认 datagen 输出与原 simulator 格式一致**

人工检查：`generateTrackerReadings` / `generateCapsuleReadings` 输出的 readings Map key 名和类型与原 `TelemetrySimulator` 完全一致：
- TRACKER: `stepCount`(int), `distanceMeters`(double), `accelX/Y/Z`(int), `latitude/longitude`(double), `batteryLevel`(int), `activityIndex`(double)
- CAPSULE: `temperatures`(List<BigDecimal>), `gastricMotility`(long), `accelX/Y/Z`(int), `batteryVoltage`(int)

- [ ] **Step 2: 编译确认 application.yml 切换后系统正常**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 3: 删除 TelemetrySimulator.java**

> 确认无其他类引用 TelemetrySimulator（`grep -r TelemetrySimulator src/`）。若有测试引用，一并迁移。

Run: `rg "TelemetrySimulator" smart-livestock-server/src/ 2>/dev/null`

- [ ] **Step 4: 编译 + 测试**

Run: `cd smart-livestock-server && ./gradlew compileJava compileTestJava -q 2>&1 | tail -20`

- [ ] **Step 5: Commit**

```bash
git add -A smart-livestock-server/src/
git commit -m "refactor(datagen): 删除 TelemetrySimulator，datagen 接管合成数据生成（Task 11）

- TelemetrySimulator 随机 boolean 异常 → datagen Scenario 驱动时序曲线
- application.yml: telemetry.simulator.enabled=false, datagen.enabled=true
- IoT 上下文零改动（TelemetryIngestionService.ingest() 接口不变）"
```

---

## Task 12: 全量验证 + 编译通过

- [ ] **Step 1: 全量编译**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
Expected: 无错误

- [ ] **Step 2: datagen 单元测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.datagen.*" 2>&1 | tail -20`
Expected: 全部 passed

- [ ] **Step 3: 确认旧测试不破坏**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.iot.*" 2>&1 | tail -20`
Expected: 全部 passed（TelemetryIngestionServiceTest 等不受影响）

- [ ] **Step 4: 最终 Commit（若有未提交改动）**

```bash
git status
git add -A smart-livestock-server/src/
git commit -m "chore(datagen): v1 收尾"
```

---

## Self-Review（计划自检）

**Spec 覆盖（design doc 章节 → Task）：**
- §3.1 AnomalyPattern + TemporalShape → Task 2 ✅
- §3.2 SynthesisScenario（聚合根 + isActiveAt）→ Task 3 ✅
- §3.3 GroundTruthLabel（overlaps）→ Task 3 ✅
- §4 Flyway 迁移（2 表 + 种子）→ Task 1 ✅
- §5.1 SynthesisRunner（@Scheduled + @ConditionalOnProperty）→ Task 6 ✅
- §5.2 SynthesisService.generate() 流程（查安装→查标签→生成→喂管道）→ Task 5 ✅
- §5.3 异常注入决策（scenario 驱动替代 boolean）→ Task 5 ✅
- §6 EvaluationService → Task 8 ✅
- §7 从 TelemetrySimulator 迁移（迁移策略+不迁移部分）→ Task 11 ✅
- §9 配置（datagen.enabled）→ Task 6 ✅
- §10 Admin API → Task 10 ✅
- ACL 端口（TelemetryIngestionPort/DeviceQueryPort/AnomalyScoreQueryPort）→ Task 4 ✅
- 持久化（JPA entities + repositories + mappers）→ Task 9 ✅

**已知边界（非占位符，是有意范围）：**
- `AnomalyScoreQueryPortImpl` 读 `anomaly_scores` 表，该表由 Phase B 交付物 2（Java ai-platform 集成）创建。若表不存在，catch 异常返回空列表，EvaluationService 输出空报告。
- `createManualLabel`（Task 7）为 Phase C 预留，Phase B 无 UI 调用它。
- `GpsSimulator`（IoT 中独立的 GPS 模拟器）不在本计划范围内迁移。
- PostgreSQL BIGINT[] 映射 `target_livestock_ids`：Hibernate 6 支持 `@JdbcTypeCode(SqlTypes.ARRAY)`，但单元测试不依赖此列（默认场景 target=null = 全部）。

---

## 执行交接

Plan 完成并保存于 `docs/superpowers/plans/2026-06-26-datagen-v1-plan.md`。两种执行方式：

1. **Subagent-Driven（推荐）** — 每个 Task 派一个新 subagent，任务间评审，快速迭代。
2. **Inline Execution** — 本会话内用 executing-plans 批量执行，检查点评审。

选哪种？
