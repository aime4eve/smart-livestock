# Phase B 交付物 2 实施计划 — Java 后端 ai-platform 集成

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 Phase A 的 ai-platform Python 服务从孤岛接入 Java 系统——`HealthApplicationService` 处理遥测后调用 ai-platform `/ai/health/analyze`，将检测结果写入 `anomaly_scores` + `health_snapshots` AI 列，超阈值时通过现有 `RanchCommandPort` 写 alerts。ai-platform 不可用时静默降级为纯规则引擎。

**Architecture:** `TelemetryEventConsumer`（不改）→ `HealthApplicationService.processTelemetry()`（尾部追加）→ `HealthAnomalyService.assess()`（Redis 去抖 + 调 `AnomalyScoreClient` + 写库/告警）→ `AnomalyScoreClient`（Spring RestClient → ai-platform HTTP）。ai-platform 不可用 → catch + log + skip，规则引擎照常运行。

**Tech Stack:** Java 17 + Spring Boot 3.3（RestClient 内置于 spring-boot-starter-web）+ JPA + Redis（已有 `RedisCacheService`）+ JUnit 5。

**关联文档:**
- Phase A 设计：`docs/superpowers/specs/2026-06-19-ai-health-anomaly-detection-design.md`（§3 数据流 / §6 持久化）
- 战略路线图：`docs/superpowers/specs/2026-06-19-ai-health-roadmap.md` §4 Phase B 交付物 2
- ai-platform API 契约：`smart-livestock-server/ai-platform/app/schemas.py`（`PredictRequest` / `PredictResponse` / `AnalyzeResponse`）

**前置条件:**
- ✅ ai-platform Python 服务已交付（Phase A，commit `79c5fd22`，端口 18000）
- ✅ datagen-v1 已交付（合成数据持续流入时序表）
- ✅ GPS 收敛设计已实施（`GpsSimulator` 已删除）
- ai-platform Docker 容器需运行（部署阶段验证，本计划仅编译验证）

**与 Phase B 其余交付物的边界:** 本计划只做 Java 后端集成。交付物 3（Flutter 双轨前端）独立成文。交付物 4（评估报告）由 datagen EvaluationService 已实现，依赖 anomaly_scores 表存在即可跑通。

---

## File Structure

```
smart-livestock-server/src/main/java/com/smartlivestock/health/
├── domain/
│   ├── model/
│   │   └── AnomalyScore.java                    — 领域实体（新增）
│   └── repository/
│       └── AnomalyScoreRepository.java          — 领域 repository 接口（新增）
├── application/
│   ├── service/
│   │   └── HealthAnomalyService.java            — AI 检测编排（新增 ★核心）
│   └── port/
│       └── AnomalyScoreClient.java              — HTTP 客户端接口（新增，port 定义）
├── infrastructure/
│   ├── persistence/
│   │   ├── entity/AnomalyScoreJpaEntity.java    — JPA 实体（新增）
│   │   ├── jpa/AnomalyScoreJpaRepository.java   — Spring Data（新增）
│   │   └── repository/AnomalyScoreRepositoryImpl.java  — 实现（新增）
│   └── client/
│       └── RestAnomalyScoreClient.java          — RestClient 实现 + 降级（新增）
└── interfaces/
    └── app/
        └── AnomalyController.java               — API 端点（新增）

改动文件:
├── ranch/domain/model/AlertType.java            — 加 AI_ANOMALY（改）
├── ranch/domain/model/Alert.java                — 加 source 字段（改）
├── ranch/infrastructure/persistence/entity/AlertJpaEntity.java — 加 source 列（改）
├── health/infrastructure/persistence/entity/HealthSnapshotJpaEntity.java — 加 AI 列（改）
├── health/infrastructure/persistence/mapper/HealthMapper.java — AI 字段映射（改）
├── health/domain/model/HealthSnapshot.java      — 加 AI 字段（改）
├── health/application/service/HealthApplicationService.java — 尾部追加 assess 调用（改）
├── health/domain/port/dto/AlertInfo.java        — 加 source 字段（改）
└── resources/application.yml                    — ai.platform 配置（改）

新建:
├── resources/db/migration/V40__add_ai_anomaly_integration.sql  — 迁移（新增）
└── docker-compose.yml                                           — app depends_on ai-platform（改）
```

**职责边界:** `AnomalyScoreClient`（port 接口）+ `RestAnomalyScoreClient`（实现）是唯一的跨进程 HTTP 边界。`HealthAnomalyService` 是应用服务，编排去抖→调用→写库，不直接发 HTTP。domain `AnomalyScore` 是纯领域实体，不感知 HTTP。

---

## Task 1: V40 迁移

**Files:**
- Create: `smart-livestock-server/src/main/resources/db/migration/V40__add_ai_anomaly_integration.sql`

- [ ] **Step 1: 创建迁移**

依据 Phase A design §6（三组变更合并到一个迁移）。

```sql
-- V40__add_ai_anomaly_integration.sql

-- §6.1: anomaly_scores 表（按月分区，对齐 health 时序表）
CREATE TABLE anomaly_scores (
    id BIGSERIAL,
    tenant_id BIGINT NOT NULL,
    farm_id BIGINT NOT NULL,
    livestock_id BIGINT NOT NULL,
    window_start TIMESTAMP NOT NULL,
    window_end TIMESTAMP NOT NULL,
    anomaly_score DECIMAL(4,3) NOT NULL,
    anomaly_type VARCHAR(32) NOT NULL,
    contributions JSONB,
    capability_used VARCHAR(32) NOT NULL,
    n_eff INTEGER,
    model_meta JSONB,
    label VARCHAR(16),
    labeled_by BIGINT,
    labeled_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, created_at)
) PARTITION BY RANGE (created_at);

CREATE INDEX idx_anomaly_livestock ON anomaly_scores (farm_id, livestock_id, created_at DESC);
CREATE INDEX idx_anomaly_unlabeled ON anomaly_scores (farm_id, anomaly_score DESC)
    WHERE label IS NULL;

-- §6.2: health_snapshots AI 列
ALTER TABLE health_snapshots ADD COLUMN IF NOT EXISTS ai_anomaly_score DECIMAL(4,3);
ALTER TABLE health_snapshots ADD COLUMN IF NOT EXISTS ai_anomaly_type  VARCHAR(32);
ALTER TABLE health_snapshots ADD COLUMN IF NOT EXISTS ai_assessed_at   TIMESTAMP;

-- §6.3: alerts source 列 + AI_ANOMALY type
ALTER TABLE alerts ADD COLUMN IF NOT EXISTS source VARCHAR(16) NOT NULL DEFAULT 'RULE';
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_source CHECK (source IN ('RULE','AI'));

-- 重建 type 约束（V26 当前 7 值，追加 AI_ANOMALY）
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH','FENCE_APPROACH','ZONE_APPROACH','TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL','ESTRUS','EPIDEMIC','AI_ANOMALY'));
```

- [ ] **Step 2: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
Expected: 无错误（迁移文件不影响编译）

- [ ] **Step 3: Commit**

---

## Task 2: anomaly_scores 领域模型 + 持久化层

**Files:**
- Create: `health/domain/model/AnomalyScore.java`
- Create: `health/domain/repository/AnomalyScoreRepository.java`
- Create: `health/infrastructure/persistence/entity/AnomalyScoreJpaEntity.java`
- Create: `health/infrastructure/persistence/jpa/AnomalyScoreJpaRepository.java`
- Create: `health/infrastructure/persistence/repository/AnomalyScoreRepositoryImpl.java`

- [ ] **Step 1: 领域实体 AnomalyScore**

```java
package com.smartlivestock.health.domain.model;

import com.smartlivestock.shared.domain.Entity;
import java.math.BigDecimal;
import java.time.Instant;
import java.util.Map;

/** AI anomaly detection result for a livestock within a detection window. */
public class AnomalyScore extends Entity {
    private Long id;
    private Long tenantId;
    private Long farmId;
    private Long livestockId;
    private Instant windowStart;
    private Instant windowEnd;
    private BigDecimal anomalyScore;    // 0.000 - 1.000
    private String anomalyType;         // normal / circadian_disruption / abrupt_change / multivariate
    private Map<String, Object> contributions;
    private String capabilityUsed;      // health_l1 / none
    private Integer nEff;
    private Map<String, Object> modelMeta;
    private Instant createdAt;

    // constructors, getters, setters...
}
```

- [ ] **Step 2: JPA Entity（分区表，注意 @PrePersist）**

```java
@Entity
@Table(name = "anomaly_scores")
public class AnomalyScoreJpaEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "tenant_id", nullable = false) private Long tenantId;
    @Column(name = "farm_id", nullable = false) private Long farmId;
    @Column(name = "livestock_id", nullable = false) private Long livestockId;
    @Column(name = "window_start", nullable = false) private Instant windowStart;
    @Column(name = "window_end", nullable = false) private Instant windowEnd;
    @Column(name = "anomaly_score", nullable = false, precision = 4, scale = 3) private BigDecimal anomalyScore;
    @Column(name = "anomaly_type", nullable = false, length = 32) private String anomalyType;
    @Column(name = "contributions", columnDefinition = "jsonb") private String contributions;
    @Column(name = "capability_used", nullable = false, length = 32) private String capabilityUsed;
    @Column(name = "n_eff") private Integer nEff;
    @Column(name = "model_meta", columnDefinition = "jsonb") private String modelMeta;
    @Column(name = "created_at", nullable = false) private Instant createdAt;

    @PrePersist
    protected void onCreate() { this.createdAt = Instant.now(); }

    // getters, setters...
}
```

- [ ] **Step 3: Spring Data Repository**

```java
public interface AnomalyScoreJpaRepository extends JpaRepository<AnomalyScoreJpaEntity, Long> {
    List<AnomalyScoreJpaEntity> findByFarmIdAndLivestockIdOrderByCreatedAtDesc(Long farmId, Long livestockId, Pageable pageable);
    Optional<AnomalyScoreJpaEntity> findFirstByFarmIdAndLivestockIdOrderByCreatedAtDesc(Long farmId, Long livestockId);
}
```

- [ ] **Step 4: Domain Repository 接口 + Impl**

```java
public interface AnomalyScoreRepository {
    AnomalyScore save(AnomalyScore score);
    Optional<AnomalyScore> findLatestByFarmIdAndLivestockId(Long farmId, Long livestockId);
    List<AnomalyScore> findByFarmIdAndLivestockId(Long farmId, Long livestockId, int limit);
}
```

Impl 委托 Spring Data JPA + 手动 JSONB ↔ Map 转换（用 ObjectMapper）。

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 6: Commit**

---

## Task 3: AnomalyScoreClient（HTTP 客户端 + 降级）

**Files:**
- Create: `health/application/port/AnomalyScoreClient.java`
- Create: `health/infrastructure/client/RestAnomalyScoreClient.java`

- [ ] **Step 1: Port 接口**

```java
package com.smartlivestock.health.application.port;

import java.util.List;

/** Port: Health → ai-platform (Python FastAPI). HTTP client with degradation. */
public interface AnomalyScoreClient {
    /** Analyze livestock health anomaly via ai-platform. Returns empty list if unavailable (degradation). */
    List<AnomalyPrediction> analyze(Long tenantId, Long farmId, List<Long> livestockIds, int windowHours);

    /** Single-record DTO mirroring ai-platform PredictResponse. */
    record AnomalyPrediction(
        Long livestockId, double anomalyScore, String anomalyType,
        double stlContribution, double cusumContribution, double jointContribution,
        String capabilityUsed, int nEff, String modelMetaJson
    ) {}
}
```

- [ ] **Step 2: RestAnomalyScoreClient 实现（RestClient + try-catch 降级）**

```java
package com.smartlivestock.health.infrastructure.client;

import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Slf4j
@Component
public class RestAnomalyScoreClient implements AnomalyScoreClient {

    private final RestClient restClient;
    private final ObjectMapper objectMapper;

    @Value("${ai.platform.url:http://localhost:18000}")
    private String baseUrl;

    @Value("${ai.platform.timeout-ms:5000}")
    private int timeoutMs;

    public RestAnomalyScoreClient(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
        this.restClient = RestClient.builder()
                .baseUrl(baseUrl)
                .build();
    }

    @Override
    public List<AnomalyPrediction> analyze(Long tenantId, Long farmId, List<Long> livestockIds, int windowHours) {
        if (livestockIds.isEmpty()) return List.of();
        try {
            Map<String, Object> body = Map.of(
                    "tenant_id", tenantId,
                    "farm_id", farmId,
                    "livestock_ids", livestockIds,
                    "window_hours", windowHours);

            JsonNode resp = restClient.post()
                    .uri("/ai/health/analyze")
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);

            return parseResults(resp);
        } catch (Exception e) {
            // Degradation: ai-platform unavailable → empty list, rule engine continues
            log.warn("ai-platform analyze failed (degrading to rule-only): {}", e.getMessage());
            return List.of();
        }
    }

    private List<AnomalyPrediction> parseResults(JsonNode resp) {
        List<AnomalyPrediction> results = new ArrayList<>();
        if (resp == null) return results;
        JsonNode arr = resp.path("results");
        if (!arr.isArray()) return results;
        for (JsonNode item : arr) {
            results.add(new AnomalyPrediction(
                    item.path("livestock_id").asLong(),
                    item.path("anomaly_score").asDouble(),
                    item.path("anomaly_type").asText("normal"),
                    item.path("contributions").path("stl").asDouble(0),
                    item.path("contributions").path("cusum").asDouble(0),
                    item.path("contributions").path("joint").asDouble(0),
                    item.path("capability_used").asText("none"),
                    item.path("n_eff").asInt(0),
                    item.path("model_meta").toString()));
        }
        return results;
    }
}
```

> **降级策略**：不引入 resilience4j。ai-platform 是内部服务，不可用时 catch Exception 返回空列表，`HealthAnomalyService` 检测到空结果直接 skip，规则引擎照常运行。简单有效，真实生产压测后如有需要再升级为 circuit breaker。

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 4: Commit**

---

## Task 4: HealthAnomalyService（核心编排）

**Files:**
- Create: `health/application/service/HealthAnomalyService.java`

- [ ] **Step 1: HealthAnomalyService**

```java
package com.smartlivestock.health.application.service;

import com.smartlivestock.health.application.port.AnomalyScoreClient;
import com.smartlivestock.health.application.port.AnomalyScoreClient.AnomalyPrediction;
import com.smartlivestock.health.domain.model.AnomalyScore;
import com.smartlivestock.health.domain.model.HealthSnapshot;
import com.smartlivestock.health.domain.port.RanchCommandPort;
import com.smartlivestock.health.domain.port.dto.AlertInfo;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import com.smartlivestock.health.domain.repository.HealthSnapshotRepository;
import com.smartlivestock.shared.cache.RedisCacheService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Duration;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AI anomaly detection orchestration (Phase A design §3.1 方案A).
 * Called from HealthApplicationService.processTelemetry() tail.
 * Dedup via Redis, calls ai-platform, writes anomaly_scores + health_snapshots AI columns,
 * raises AI alerts when score exceeds threshold.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class HealthAnomalyService {

    private final AnomalyScoreClient anomalyScoreClient;
    private final AnomalyScoreRepository anomalyScoreRepo;
    private final HealthSnapshotRepository snapshotRepo;
    private final RanchCommandPort ranchCommandPort;
    private final RedisCacheService redis;

    @Value("${ai.alert.threshold:0.7}")
    private double alertThreshold;

    @Value("${ai.dedup.ttl-minutes:60}")
    private int dedupTtlMinutes;

    private static final String DEDUP_KEY_PREFIX = "ai:dedup:";

    /**
     * Assess a single livestock's health anomaly via ai-platform.
     * Design §3.1: dedup per livestock (30-60min window).
     */
    @Transactional
    public void assess(Long tenantId, Long farmId, Long livestockId) {
        // 1. Dedup: skip if assessed recently
        String dedupKey = DEDUP_KEY_PREFIX + livestockId;
        if (redis.exists(dedupKey)) {
            log.debug("AI dedup skip for livestock [{}]", livestockId);
            return;
        }

        // 2. Call ai-platform (degrades to empty if unavailable)
        List<AnomalyPrediction> predictions = anomalyScoreClient.analyze(
                tenantId, farmId, List.of(livestockId), 24);
        if (predictions.isEmpty()) return;  // degradation

        AnomalyPrediction pred = predictions.get(0);
        if (pred.anomalyScore() < 0.001) return; // normal, skip persistence

        // 3. Write anomaly_scores
        AnomalyScore score = new AnomalyScore();
        score.setTenantId(tenantId);
        score.setFarmId(farmId);
        score.setLivestockId(livestockId);
        score.setWindowStart(Instant.now().minus(Duration.ofHours(24)));
        score.setWindowEnd(Instant.now());
        score.setAnomalyScore(BigDecimal.valueOf(pred.anomalyScore()).setScale(3, RoundingMode.HALF_UP));
        score.setAnomalyType(pred.anomalyType());
        Map<String, Object> contributions = new HashMap<>();
        contributions.put("stl", pred.stlContribution());
        contributions.put("cusum", pred.cusumContribution());
        contributions.put("joint", pred.jointContribution());
        score.setContributions(contributions);
        score.setCapabilityUsed(pred.capabilityUsed());
        score.setNEff(pred.nEff());
        anomalyScoreRepo.save(score);

        // 4. Update health_snapshots AI columns
        snapshotRepo.findByLivestockId(livestockId).ifPresent(snap -> {
            snap.setAiAnomalyScore(score.getAnomalyScore());
            snap.setAiAnomalyType(pred.anomalyType());
            snap.setAiAssessedAt(Instant.now());
            snapshotRepo.save(snap);
        });

        // 5. Raise AI alert if over threshold
        if (pred.anomalyScore() >= alertThreshold) {
            String alertType = mapAnomalyTypeToAlertType(pred.anomalyType());
            String severity = pred.anomalyScore() >= 0.85 ? "CRITICAL" : "WARNING";
            ranchCommandPort.createAlert(new AlertInfo(
                    farmId, livestockId, alertType, severity,
                    buildAlertMessage(pred), "AI"));
        }

        // 6. Set dedup key
        redis.set(dedupKey, "1", dedupTtlMinutes * 60L);
    }

    private String mapAnomalyTypeToAlertType(String anomalyType) {
        // Design §6.3: abrupt_change/circadian_disruption → TEMPERATURE_ABNORMAL, multivariate → AI_ANOMALY
        return switch (anomalyType) {
            case "abrupt_change", "circadian_disruption" -> "TEMPERATURE_ABNORMAL";
            case "multivariate" -> "AI_ANOMALY";
            default -> "AI_ANOMALY";
        };
    }

    private String buildAlertMessage(AnomalyPrediction pred) {
        return String.format("AI 异常检测: %s (score=%.3f, n_eff=%d)",
                pred.anomalyType(), pred.anomalyScore(), pred.nEff());
    }
}
```

> **AlertInfo 改动**：需加 `source` 字段（从 `"RULE"` 改为 `"AI"`）。见 Task 5。

- [ ] **Step 2: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 3: Commit**

---

## Task 5: 现有模型改动 — Alert/AlertInfo source + HealthSnapshot AI 列 + AlertType

**Files:**
- Modify: `ranch/domain/model/AlertType.java` — 加 `AI_ANOMALY`
- Modify: `ranch/domain/model/Alert.java` — 加 `source` 字段
- Modify: `ranch/infrastructure/persistence/entity/AlertJpaEntity.java` — 加 `source` 列映射
- Modify: `health/domain/port/dto/AlertInfo.java` — 加 `source` 字段
- Modify: `health/domain/model/HealthSnapshot.java` — 加 3 个 AI 字段
- Modify: `health/infrastructure/persistence/entity/HealthSnapshotJpaEntity.java` — 加 3 个 AI 列映射
- Modify: `health/infrastructure/persistence/mapper/HealthMapper.java` — AI 字段映射

- [ ] **Step 1: AlertType 加 AI_ANOMALY**

```java
public enum AlertType {
    FENCE_BREACH, FENCE_APPROACH, ZONE_APPROACH,
    TEMPERATURE_ABNORMAL, DIGESTIVE_ABNORMAL, ESTRUS, EPIDEMIC,
    AI_ANOMALY  // ← 新增
}
```

- [ ] **Step 2: Alert + AlertJpaEntity 加 source**

```java
// Alert.java
private String source = "RULE";  // RULE / AI
public String getSource() { return source; }
public void setSource(String source) { this.source = source; }
```

AlertJpaEntity 加 `@Column(name = "source", nullable = false) private String source = "RULE";` + getter/setter。AlertMapper 加 source 映射。

- [ ] **Step 3: AlertInfo 加 source**

```java
public record AlertInfo(Long farmId, Long livestockId, String alertType,
                         String severity, String message, String source) {
    // backward-compat: 旧调用方不传 source 时默认 RULE
    public AlertInfo(Long farmId, Long livestockId, String alertType,
                     String severity, String message) {
        this(farmId, livestockId, alertType, severity, message, "RULE");
    }
}
```

- [ ] **Step 4: HealthSnapshot + JpaEntity 加 AI 字段**

```java
// HealthSnapshot.java
private BigDecimal aiAnomalyScore;
private String aiAnomalyType;
private Instant aiAssessedAt;
// getters, setters...

// HealthSnapshotJpaEntity.java
@Column(name = "ai_anomaly_score", precision = 4, scale = 3) private BigDecimal aiAnomalyScore;
@Column(name = "ai_anomaly_type", length = 32) private String aiAnomalyType;
@Column(name = "ai_assessed_at") private Instant aiAssessedAt;
// getters, setters...
```

HealthMapper 加这 3 个字段的映射。

- [ ] **Step 5: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 6: Commit**

---

## Task 6: HealthApplicationService 接入

**Files:**
- Modify: `health/application/service/HealthApplicationService.java`

- [ ] **Step 1: 注入 HealthAnomalyService + processTelemetry 尾部追加调用**

在 `processTelemetry` 方法的 `refreshSnapshot` 调用之后追加：

```java
// 现有最后一行:
refreshSnapshot(livestockId, farmId, deviceType.name(), temperature, motilityFrequency);

// 追加: AI 异常检测（design §3.1 方案A，串行同流下游）
try {
    healthAnomalyService.assess(1L, farmId, livestockId);
} catch (Exception e) {
    log.warn("AI anomaly assessment failed for livestock [{}]: {}", livestockId, e.getMessage());
}
```

> **tenantId**：当前 `processTelemetry` 签名没有 tenantId 参数。Phase B 简化为传 `1L`（demo 租户）。多租户精确解析需要从 farm → tenant 查询，留待后续迭代。

- [ ] **Step 2: 在构造函数注入 HealthAnomalyService**

HealthApplicationService 已用 `@RequiredArgsConstructor`，只需加 `private final HealthAnomalyService healthAnomalyService;` 字段。

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 4: Commit**

---

## Task 7: API 端点

**Files:**
- Create: `health/interfaces/app/AnomalyController.java`

- [ ] **Step 1: AnomalyController**

```java
package com.smartlivestock.health.interfaces.app;

import com.smartlivestock.health.application.service.HealthApplicationService;
import com.smartlivestock.health.domain.repository.AnomalyScoreRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/v1/health/anomaly")
@RequiredArgsConstructor
public class AnomalyController {
    private final AnomalyScoreRepository anomalyScoreRepo;
    private final HealthSnapshotRepository snapshotRepo;

    /** Latest AI anomaly score for a livestock. */
    @GetMapping("/{livestockId}")
    public ResponseEntity<?> getLatestAnomaly(@PathVariable Long livestockId,
                                                @RequestParam(defaultValue = "1") Long farmId) {
        return anomalyScoreRepo.findLatestByFarmIdAndLivestockId(farmId, livestockId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.ok(Map.of("anomalyScore", 0.0, "anomalyType", "normal")));
    }

    /** History of AI anomaly scores for a livestock. */
    @GetMapping("/{livestockId}/history")
    public ResponseEntity<?> getAnomalyHistory(@PathVariable Long livestockId,
                                                 @RequestParam(defaultValue = "1") Long farmId,
                                                 @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(anomalyScoreRepo.findByFarmIdAndLivestockId(farmId, livestockId, limit));
    }
}
```

> Farm-scoped API，SecurityConfig 的 FarmScopeResolver 自动解析 activeFarmId。

- [ ] **Step 2: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 3: Commit**

---

## Task 8: 配置 + docker-compose

**Files:**
- Modify: `smart-livestock-server/src/main/resources/application.yml`
- Modify: `smart-livestock-server/docker-compose.yml`

- [ ] **Step 1: application.yml 加 ai 配置**

```yaml
ai:
  platform:
    url: ${AI_PLATFORM_URL:http://localhost:18000}
    timeout-ms: ${AI_PLATFORM_TIMEOUT_MS:5000}
  alert:
    threshold: ${AI_ALERT_THRESHOLD:0.7}
  dedup:
    ttl-minutes: ${AI_DEDUP_TTL_MINUTES:60}
```

- [ ] **Step 2: docker-compose app depends_on ai-platform**

```yaml
  app:
    # ... 现有配置 ...
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
      ai-platform:
        condition: service_healthy    # ← 新增：app 等 ai-platform 健康检查通过
```

> app 容器的 `AI_PLATFORM_URL` 需设为 `http://ai-platform:8000`（Docker 内部网络）。

- [ ] **Step 3: 编译验证**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`

- [ ] **Step 4: Commit**

---

## Task 9: 单元测试

**Files:**
- Create: `health/application/service/HealthAnomalyServiceTest.java`
- Create: `health/application/port/AnomalyScoreClientTest.java`（可选，mock client）

- [ ] **Step 1: HealthAnomalyServiceTest（mock client + repo）**

测试要点：
- ai-platform 返回高分 → 写 anomaly_scores + 更新 snapshot AI 列 + 发 AI alert
- ai-platform 返回空（降级）→ 不写任何东西，不 throw
- Redis dedup 命中 → skip 调用
- 分数低于 alertThreshold → 不发 alert

- [ ] **Step 2: 编译 + 测试**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.health.anomaly.*" 2>&1 | tail -20`
Expected: 全部 passed

- [ ] **Step 3: Commit**

---

## Task 10: 全量验证

> 本 Task 分两阶段。阶段 A（编译+单测）由 Agent 执行；阶段 B（端到端链路验证）由用户部署后执行，curl 验证两条链路的每一跳。

### 阶段 A：编译 + 单元测试（Agent 执行）

- [ ] **Step 1: 全量编译**

Run: `cd smart-livestock-server && ./gradlew compileJava -q 2>&1 | tail -5`
Expected: 无错误

- [ ] **Step 2: 测试编译通过**

Run: `cd smart-livestock-server && ./gradlew compileTestJava -q 2>&1 | tail -20`
Expected: 无错误

- [ ] **Step 3: datagen + health + iot 测试全通**

Run: `cd smart-livestock-server && ./gradlew test --tests "*.datagen.*" --tests "*.health.*" --tests "*.iot.*" 2>&1 | tail -20`
Expected: 全部 passed

- [ ] **Step 4: Commit 编译验证**

```bash
git add -A smart-livestock-server/src/
git commit -m "chore(phase-b): 交付物 2 编译验证通过"
```

### 阶段 B：端到端链路验证（用户部署后执行）

> **前置**：用户完成 `docker compose up -d` 全栈启动（postgres + redis + rocketmq + ai-platform + app），等待 datagen 生成至少 5 分钟数据。

**准备：获取 Token**

```bash
# 登录 owner 账号
TOKEN=$(curl -s http://localhost:18080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123"}' | python3 -c "import sys,json;print(json.load(sys.stdin)['data']['accessToken'])")
```

---

**链路 1：datagen → IoT → Health/Fence → 前端可查（动物位置 + 健康明细）**

验证数据从合成引擎流经 IoT 管道，最终在各业务上下文的 API 可查。

```
datagen SynthesisRunner
  → IoT: TelemetryIngestionService.ingest()
    ├── TRACKER readings (含 GPS lat/lng) → extractAndLogGps → gps_logs
    │     → MQ: gps-log-updated → Ranch: GpsLogEventConsumer → FenceBreachDetector → alerts
    └── CAPSULE readings (含 temperatures/gastricMotility)
          → MQ: telemetry-received → Health: TelemetryEventConsumer
            → HealthApplicationService.processTelemetry()
              → 写 temperature_logs / rumen_motility_logs / activity_logs
              → [新增] HealthAnomalyService.assess() → ai-platform
```

- [ ] **Step 5: 动物位置可查（GPS 数据流入）**

```bash
# 查 GPS 最新位置（datagen TRACKER 读数经 IoT 写 gps_logs）
curl -s http://localhost:18080/api/v1/devices/gps-logs/latest \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -20
```
Expected: 返回非空 GPS 列表，含 latitude/longitude（来自 datagen 随机游走）

- [ ] **Step 6: 地图 API 可查动物位置**

```bash
# MapController — 前端地图页消费的接口
curl -s "http://localhost:18080/api/v1/farms/1/map" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -30
```
Expected: 返回 livestock 列表含坐标（datagen GPS 数据经 IoT → gps_logs → MapController）

- [ ] **Step 7: 健康明细可查（体温/蠕动时序数据流入）**

```bash
# 发热预警列表（Health 从 temperature_logs 聚合）
curl -s "http://localhost:18080/api/v1/farms/1/health/fever" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -20

# 消化管理列表（Health 从 rumen_motility_logs 聚合）
curl -s "http://localhost:18080/api/v1/farms/1/health/digestive" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -20

# 健康概览（Health snapshots — 现在应含 AI 列）
curl -s "http://localhost:18080/api/v1/farms/1/health/overview" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -30
```
Expected: 返回非空数据列表，体温/蠕动数据来自 datagen CAPSULE 读数经 IoT → MQ → Health 入库

- [ ] **Step 8: 围栏告警可查（datagen FENCE_BREACH 场景触发）**

> 需先通过 Admin API 创建 FENCE_BREACH 场景并等待至少 2 分钟（围栏越界 GPS → FenceBreachDetector → alerts）。

```bash
# 创建围栏越界场景（admin API）
curl -s -X POST http://localhost:18080/api/v1/admin/datagen/scenarios \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"越界测试","pattern":"FENCE_BREACH","penetrationRate":0.3,"windowStart":"2026-01-01T00:00:00Z","windowEnd":"2027-01-01T00:00:00Z"}' \
  | python3 -m json.tool

# 等待 2 分钟后查告警
curl -s "http://localhost:18080/api/v1/farms/1/alerts" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool | head -30
```
Expected: alerts 含 type=FENCE_BREACH（datagen 围栏越界 GPS → IoT → MQ → Ranch FenceBreachDetector → alerts）

---

**链路 2：ai-platform → 前端可查（健康判断 + 围栏预警判断）**

验证 ai-platform 检测结果回到 Java 系统，经 API 可查。

```
HealthApplicationService.processTelemetry()
  → [新增] HealthAnomalyService.assess(farmId, livestockId)
    → Redis 去抖（60min TTL）
    → AnomalyScoreClient → ai-platform POST /ai/health/analyze
    → 写 anomaly_scores + health_snapshots.ai_*
    → 超阈值 → RanchCommandPort.createAlert(source=AI)
```

- [ ] **Step 9: AI 异常分数可查（anomaly_scores 写入成功）**

> 前置：datagen 已运行 ≥ 5 分钟（ai-platform 需要时序窗口数据）。ai-platform 需有 ≥ 30 个有效数据点（N_eff ≥ 30）才能走 Mahalanobis 档，否则走纯规则档返回低分。

```bash
# 查 AI 异常分数（Task 7 新增端点）
curl -s "http://localhost:18080/api/v1/health/anomaly/1" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
Expected: 返回 anomalyScore + anomalyType（来自 ai-platform 检测写入 anomaly_scores）

> 若返回 `{"anomalyScore": 0.0, "anomalyType": "normal"}`：
> - 检查 datagen 是否在运行（`docker compose logs app 2>&1 | grep "SynthesisService"`）
> - 检查 ai-platform 是否可达（`curl -s http://localhost:18000/ai/health/live`）
> - N_eff 可能不足 30（数据积累不够），等待 15 分钟后重试
> - 查日志确认是否有降级日志（`docker compose logs app 2>&1 | grep "ai-platform analyze failed"`）

- [ ] **Step 10: AI 异常历史可查**

```bash
curl -s "http://localhost:18080/api/v1/health/anomaly/1/history?limit=10" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
Expected: 返回历史 anomaly_scores 记录列表

- [ ] **Step 11: 健康概览含 AI 列（health_snapshots.ai_*）**

```bash
curl -s "http://localhost:18080/api/v1/farms/1/health/overview" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
Expected: 返回数据含 `aiAnomalyScore` / `aiAnomalyType` / `aiAssessedAt` 字段（非 null 表示 AI 检测已写入 snapshot）

- [ ] **Step 12: AI 告警可查（超阈值时 alerts source=AI）**

> 需 datagen 注入 HIGH_FEVER 场景并等待 anomaly_score 超 0.7 触发 AI alert。

```bash
# 创建高热注入场景
curl -s -X POST http://localhost:18080/api/v1/admin/datagen/scenarios \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"name":"高热注入","pattern":"HIGH_FEVER","penetrationRate":0.5,"windowStart":"2026-01-01T00:00:00Z","windowEnd":"2027-01-01T00:00:00Z"}' \
  | python3 -m json.tool

# 等待 10 分钟（去抖 60min + ai-platform 检测窗口），查 AI 告警
curl -s "http://localhost:18080/api/v1/farms/1/alerts" \
  -H "Authorization: Bearer $TOKEN" | python3 -c "
import sys, json
data = json.load(sys.stdin)
ai_alerts = [a for a in data.get('data', {}).get('items', data.get('data', [])) if a.get('source') == 'AI']
print(f'AI alerts: {len(ai_alerts)}')
for a in ai_alerts: print(json.dumps(a, indent=2, ensure_ascii=False))
"
```
Expected: alerts 含 source=AI 的记录（HealthAnomalyService 超阈值写 AI_ANOMALY 或 TEMPERATURE_ABNORMAL alert）

- [ ] **Step 13: datagen 评估报告可查（ground truth × 预测对比）**

```bash
# datagen EvaluationService 评估报告
curl -s "http://localhost:18080/api/v1/admin/datagen/evaluation?from=2026-06-26T00:00:00Z&to=2026-06-27T00:00:00Z" \
  -H "Authorization: Bearer $TOKEN" | python3 -m json.tool
```
Expected: 返回评估报告，含 HEALTH 维度（注入异常 × anomaly_scores 对比）+ FENCE 维度（注入越界 × alerts 对比）

---

**验证总结清单**

| # | 链路 | 验证点 | API | 期望 |
|---|------|--------|-----|------|
| 5 | 1 | GPS 数据流入 | GET /devices/gps-logs/latest | 非空坐标列表 |
| 6 | 1 | 动物位置（地图页） | GET /farms/{id}/map | livestock 含坐标 |
| 7 | 1 | 健康明细（体温/蠕动） | GET /farms/{id}/health/fever | 非空数据 |
| 8 | 1 | 围栏告警 | GET /farms/{id}/alerts | type=FENCE_BREACH |
| 9 | 2 | AI 异常分数 | GET /health/anomaly/{id} | anomalyScore + anomalyType |
| 10 | 2 | AI 异常历史 | GET /health/anomaly/{id}/history | 历史记录列表 |
| 11 | 2 | 健康概览含 AI 列 | GET /farms/{id}/health/overview | aiAnomalyScore 非 null |
| 12 | 2 | AI 告警 | GET /farms/{id}/alerts | source=AI 记录 |
| 13 | 跨链路 | 评估报告 | GET /admin/datagen/evaluation | HEALTH + FENCE 指标 |

> **失败排查路径**：
> - GPS 为空 → datagen 未运行 → 查 `docker compose logs app | grep Synthesis`
> - 健康数据为空 → MQ 消费失败 → 查 `docker compose logs app | grep TelemetryEventConsumer`
> - AI 分数为空 → ai-platform 不可达 → 查 `curl localhost:18000/ai/health/live` + app 日志降级信息
> - AI 告警无 → 数据积累不足 → N_eff < 30 或 score 未超 0.7，等待后重试
> - 评估报告空 → anomaly_scores 表为空 → 回到 Step 9 排查

---

## Self-Review（计划自检）

**Spec 覆盖（Phase A design 章节 → Task）：**
- §3.1 数据流（方案A 串行同流下游，去抖）→ Task 4 + Task 6 ✅
- §3.1 去抖（Redis key=ai:dedup:{livestock_id}, TTL 60min）→ Task 4 ✅
- §6.1 anomaly_scores 表（分区 + 索引 + label 预留）→ Task 1 + Task 2 ✅
- §6.2 health_snapshots AI 列（3 列）→ Task 1 + Task 5 ✅
- §6.3 alerts source 列 + AI_ANOMALY type → Task 1 + Task 5 ✅
- §9 部署（application.yml ai.platform.url, timeout, docker depends_on）→ Task 8 ✅
- §9.1 ai-platform 直连 PG 只读（Phase A 已实现，本计划不碰）→ 无需改动 ✅
- 降级（ai-platform 不可用 → catch + skip）→ Task 3 ✅

**已知简化（非占位符，是有意范围）：**
- tenantId 传 1L（demo 租户），多租户精确解析留后续迭代。
- 不引入 resilience4j，用 try-catch 降级。ai-platform 是内部服务，简单有效；真实压测后如有需要再升级。
- anomaly_scores 分区表的 DEFAULT 分区未创建（Flyway 分区策略需要按月创建，当前用单分区或动态分区管理工具，与现有 health 时序表分区策略对齐——需在实施时确认现有分区管理方式）。
- anomaly_scores.contributions/model_meta 用 String 存 JSONB（与现有项目 JSONB 处理方式对齐），读取时用 ObjectMapper 解析。

**与 #64 的关系：** GPS 事务解耦（#64）改 IoT→Ranch 事件拓扑，与本计划（Health 扩展）无上下文重叠，可并行。

---

## 执行交接

Plan 完成并保存于 `docs/superpowers/plans/2026-06-26-phase-b-deliverable-2-java-integration-plan.md`。
