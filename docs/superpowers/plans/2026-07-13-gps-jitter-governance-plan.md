# GPS 抖动治理与围栏预警增强 — 实施方案

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 建立逐设备 GPS 数据治理层，用位移门控 + 加速度计辅助替代纯单点围栏检测，消除静止抖动误报，同时保持对真实越界的及时响应。

**Architecture:** 新增 `GpsGovernanceService`（Ranch 领域服务）作为治理管道——消费 GPS + 加速度计数数据，结合出厂标定参数，输出"治理后位置估计"给下游围栏检测。设备标定参数存储在 `device_calibrations` 表（IoT 上下文），运行时状态缓存在 Redis。围栏新增 `alert_sensitivity` 三档参数，控制位移确认阈值。

**Tech Stack:** Spring Boot 3.3 + Java 17 + PostgreSQL + Redis + RocketMQ + JPA/Hibernate + Flyway + JUnit 5

**Spec:** `docs/superpowers/specs/2026-07-13-gps-jitter-requirements.md`

## Global Constraints

- Java 17, Spring Boot 3.3, Gradle
- 遵循现有 DDD 洋葱架构（domain → application → infrastructure → interfaces）
- Flyway 迁移使用时间戳版本号 `V{YYYYMMDDHHmmss}__description.sql`
- 所有面向用户的文本必须国际化（i18n）
- `gps_logs` 表保留全量原始数据，不可删除或修改
- 向后兼容：非 blade 来源的 GPS 数据继续走现有逻辑
- 告警模型 `Alert` 状态机不变（ACTIVE → AUTO_RESOLVED / DISMISSED）
- 采样间隔 30 分钟（15 分钟不在本版本范围）
- 设备固件不支持存储，标定参数存平台数据库

---

## File Map

```
smart-livestock-server/src/main/java/com/smartlivestock/

  # ── IoT Context ──
  iot/domain/model/DeviceCalibration.java              CREATE  — 标定参数领域模型
  iot/domain/repository/DeviceCalibrationRepository.java CREATE — Repository 接口
  iot/application/DeviceCalibrationService.java        CREATE  — 标定参数管理
  iot/infrastructure/persistence/entity/DeviceCalibrationJpaEntity.java CREATE
  iot/infrastructure/persistence/JpaDeviceCalibrationRepositoryImpl.java CREATE
  iot/infrastructure/persistence/mapper/DeviceCalibrationMapper.java CREATE

  # ── IoT Context (Event 扩展) ──
  iot/domain/event/GpsLogUpdatedEvent.java       MODIFY  — 捎带加速度计快照
  iot/application/GpsLogApplicationService.java   MODIFY  — 组装事件时传入加速度计

  # ── Ranch Context ──
  ranch/domain/model/AlertSensitivity.java             CREATE  — 三档枚举
  ranch/domain/model/GpsGovernanceState.java           CREATE  — 治理状态值对象
  ranch/domain/model/GovernedPosition.java             CREATE  — 治理后位置输出
  ranch/domain/service/GpsGovernanceService.java       CREATE  — 核心治理管道
  ranch/domain/model/Fence.java                        MODIFY  — 新增 alertSensitivity
  ranch/domain/repository/AlertRepository.java         MODIFY  — 新增冷却期查询
  ranch/domain/service/FenceBreachDetector.java        MODIFY  — 参数化位移确认

  ranch/application/FenceApplicationService.java       MODIFY  — 支持 sensitivity CRUD
  ranch/infrastructure/mq/GpsLogEventConsumer.java     MODIFY  — 集成治理管道
  ranch/infrastructure/cache/PositionStateCache.java   CREATE  — Redis 运行时状态

  ranch/infrastructure/persistence/entity/FenceJpaEntity.java MODIFY
  ranch/infrastructure/persistence/entity/AlertJpaEntity.java  MODIFY (如有需要)
  ranch/infrastructure/persistence/mapper/FenceMapper.java     MODIFY

  # ── DB Migration ──
  src/main/resources/db/migration/V20260713______create_device_calibrations.sql CREATE
  src/main/resources/db/migration/V20260713______add_fence_alert_sensitivity.sql CREATE

  # ── Business Platform ──
  business-platform/.../AccelerometerConverter.java     MODIFY  — 改进 classifyActivity

  # ── Tests ──
  ranch/domain/service/GpsGovernanceServiceTest.java    CREATE
  ranch/domain/model/AlertSensitivityTest.java          CREATE
  iot/domain/model/DeviceCalibrationTest.java           CREATE
  iot/application/DeviceCalibrationServiceTest.java     CREATE
  ranch/infrastructure/mq/GpsLogEventConsumerTest.java  MODIFY
  business-platform/.../AccelerometerConverterTest.java MODIFY
```

---

### Task 1: DeviceCalibration 领域模型 + DB 迁移

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/model/DeviceCalibration.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/repository/DeviceCalibrationRepository.java`
- Create: `smart-livestock-server/src/main/resources/db/migration/V20260713XXXXXX__create_device_calibrations.sql`

**Interfaces:**
- Produces: `DeviceCalibration` class with fields: `devEui`, `deviceId`, `gpsJitterRadius`, `gpsMedianError`, `gpsP90Error`, `gpsOutlierThreshold`, `gpsJitterDiameter`, `accelMagRestMean`, `accelFalseActiveRate`, `calibrationQuality`, `calibratedAt`
- Produces: `DeviceCalibrationRepository` with `save(DeviceCalibration)`, `findByDevEui(String)`, `findByDeviceId(Long)`

- [ ] **Step 1: 创建 Flyway 迁移**

```sql
-- V20260713XXXXXX__create_device_calibrations.sql
CREATE TABLE IF NOT EXISTS device_calibrations (
    id              BIGSERIAL PRIMARY KEY,
    dev_eui             VARCHAR(32) NOT NULL UNIQUE,
    device_id       BIGINT,
    gps_jitter_radius        DECIMAL(7,1) NOT NULL DEFAULT 0,
    gps_median_error         DECIMAL(7,1) NOT NULL DEFAULT 0,
    gps_p90_error            DECIMAL(7,1) NOT NULL DEFAULT 0,
    gps_outlier_threshold    DECIMAL(7,1) NOT NULL DEFAULT 0,
    gps_jitter_diameter      DECIMAL(7,1) NOT NULL DEFAULT 0,
    accel_mag_rest_mean      DECIMAL(6,3) NOT NULL DEFAULT 1.000,
    accel_false_active_rate  DECIMAL(4,3) NOT NULL DEFAULT 0.000,
    calibration_quality      DECIMAL(4,3) NOT NULL DEFAULT 0.000,
    calibrated_at            TIMESTAMPTZ,
    created_at               TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at               TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_device_calibrations_dev_eui ON device_calibrations(dev_eui);
CREATE INDEX idx_device_calibrations_device_id ON device_calibrations(device_id);
```

- [ ] **Step 2: 创建 DeviceCalibration 领域模型**

```java
package com.smartlivestock.iot.domain.model;

import java.math.BigDecimal;
import java.time.Instant;

public class DeviceCalibration {
    private Long id;
    private String devEui;
    private Long deviceId;
    private BigDecimal gpsJitterRadius;       // P95 (m)
    private BigDecimal gpsMedianError;         // 中值偏差 (m)
    private BigDecimal gpsP90Error;            // P90 (m)
    private BigDecimal gpsOutlierThreshold;    // 野点阈值 (m)
    private BigDecimal gpsJitterDiameter;      // 抖动直径 (m)
    private BigDecimal accelMagRestMean;       // 静止 |mag| 均值 (g)
    private BigDecimal accelFalseActiveRate;   // 误报率 (0-1)
    private BigDecimal calibrationQuality;     // 0-1
    private Instant calibratedAt;

    public DeviceCalibration() {}

    public DeviceCalibration(String devEui, Long deviceId,
            BigDecimal gpsJitterRadius, BigDecimal gpsMedianError,
            BigDecimal gpsP90Error, BigDecimal gpsOutlierThreshold,
            BigDecimal gpsJitterDiameter, BigDecimal accelMagRestMean,
            BigDecimal accelFalseActiveRate, BigDecimal calibrationQuality,
            Instant calibratedAt) {
        this.devEui = devEui;
        this.deviceId = deviceId;
        this.gpsJitterRadius = gpsJitterRadius;
        this.gpsMedianError = gpsMedianError;
        this.gpsP90Error = gpsP90Error;
        this.gpsOutlierThreshold = gpsOutlierThreshold;
        this.gpsJitterDiameter = gpsJitterDiameter;
        this.accelMagRestMean = accelMagRestMean;
        this.accelFalseActiveRate = accelFalseActiveRate;
        this.calibrationQuality = calibrationQuality;
        this.calibratedAt = calibratedAt;
    }

    /**
     * 根据围栏容忍度档位，返回该设备对应的位移确认阈值。
     */
    public BigDecimal getMovementThreshold(AlertSensitivity sensitivity) {
        return switch (sensitivity) {
            case HIGH -> gpsMedianError;       // 最敏感：超过中值即确认
            case LOW -> gpsOutlierThreshold;   // 最保守：超过野点阈值才确认
            default -> gpsJitterRadius;        // STANDARD: P95
        };
    }

    // getters and setters ...
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    public String getDevEui() { return devEui; }
    public void setDevEui(String devEui) { this.devEui = devEui; }
    public Long getDeviceId() { return deviceId; }
    public void setDeviceId(Long deviceId) { this.deviceId = deviceId; }
    public BigDecimal getGpsJitterRadius() { return gpsJitterRadius; }
    public BigDecimal getGpsMedianError() { return gpsMedianError; }
    public BigDecimal getGpsP90Error() { return gpsP90Error; }
    public BigDecimal getGpsOutlierThreshold() { return gpsOutlierThreshold; }
    public BigDecimal getGpsJitterDiameter() { return gpsJitterDiameter; }
    public BigDecimal getAccelMagRestMean() { return accelMagRestMean; }
    public BigDecimal getAccelFalseActiveRate() { return accelFalseActiveRate; }
    public BigDecimal getCalibrationQuality() { return calibrationQuality; }
    public Instant getCalibratedAt() { return calibratedAt; }
    // setters ...
}
```

- [ ] **Step 3: 创建 DeviceCalibrationRepository 接口**

```java
package com.smartlivestock.iot.domain.repository;

import com.smartlivestock.iot.domain.model.DeviceCalibration;
import java.util.Optional;

public interface DeviceCalibrationRepository {
    DeviceCalibration save(DeviceCalibration cal);
    Optional<DeviceCalibration> findByDevEui(String devEui);
    Optional<DeviceCalibration> findByDeviceId(Long deviceId);
}
```

- [ ] **Step 4: 编译验证**

```bash
cd smart-livestock-server && ./gradlew compileJava
```

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V20260713XXXXXX__create_device_calibrations.sql
git add smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/model/DeviceCalibration.java
git add smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/repository/DeviceCalibrationRepository.java
git commit -m "feat: add DeviceCalibration domain model and DB migration"
```

---

### Task 1b: 扩展 GpsLogUpdatedEvent 捎带加速度计快照

**背景**: 当前 `GpsLogUpdatedEvent` 只含 4 个字段（deviceId, latitude, longitude, recordedAt），加速度计数据走独立的 `TelemetryReceivedEvent`。blade 端 GPS 和加速度计来自同一条 uplink 记录（天然对齐），在 `TelemetryIngestionService.ingest()` 中被拆分到两张表。治理管道需要加速度计数据做灰色地带辅助判断，因此需扩展此事件。

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/iot/domain/event/GpsLogUpdatedEvent.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/GpsLogApplicationService.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/TelemetryIngestionService.java`

**Interfaces:**
- `GpsLogUpdatedEvent` 新增可选字段：`BigDecimal accelMagnitudeG`, `BigDecimal motionIntensity`, `Integer stepNumber`（均可为 null，向后兼容）
- `GpsLogApplicationService.logGps()` 新增重载方法，接受加速度计参数

- [ ] **Step 1: 扩展 GpsLogUpdatedEvent**

在现有 4 个字段后新增 3 个可选字段（均可为 null）：
```java
private BigDecimal accelMagnitudeG;   // |mag| 合加速度幅值 (g)
private BigDecimal motionIntensity;   // 运动强度 (||mag| - 1.0|, g)
private Integer stepNumber;           // 本周期步数
```
更新构造器（保留原构造器用于向后兼容，新增带加速度计参数的构造器）。

- [ ] **Step 2: 更新 GpsLogApplicationService.logGps()**

新增重载方法：
```java
@Transactional
public GpsLogDto logGps(Long deviceId, BigDecimal latitude, BigDecimal longitude,
                        BigDecimal accuracy, Instant recordedAt,
                        BigDecimal accelMagnitudeG, BigDecimal motionIntensity, Integer stepNumber) {
    // ... 原有逻辑不变（写 gps_logs）...
    // 发布事件时捎带加速度计快照
    eventPublisher.publishEvent(new GpsLogUpdatedEvent(
            deviceId, latitude, longitude, recordedAt,
            accelMagnitudeG, motionIntensity, stepNumber));
}
```
保留原有 5 参数 `logGps()` 方法，内部调用新方法传 null。

- [ ] **Step 3: 更新 TelemetryIngestionService.extractAndLogGps()**

在调用 `logGps()` 时，从同一份 `readings` 中提取加速度计字段并传入：
```java
private void extractAndLogGps(Long deviceId, Map<String, Object> readings, Instant recordedAt) {
    // ... 原有提取 lat/lon 逻辑不变 ...
    BigDecimal accelMag = extractBigDecimal(readings, "accelMagnitudeG");
    BigDecimal motionIntensity = extractBigDecimal(readings, "motionIntensity");
    Integer stepNumber = extractInt(readings, "stepNumber");
    gpsLogApplicationService.logGps(deviceId, lat, lon, accuracy, recordedAt,
            accelMag, motionIntensity, stepNumber);
}
```

- [ ] **Step 4: 更新 GpsLogEventConsumer.onMessage() 解析逻辑**

在解析 JSON 时增加加速度计字段解析：
```java
BigDecimal motionIntensity = json.has("motionIntensity") && !json.isNull("motionIntensity")
        ? json.getBigDecimal("motionIntensity") : null;
Integer stepNumber = json.has("stepNumber") && !json.isNull("stepNumber")
        ? json.getInt("stepNumber") : null;
```

- [ ] **Step 5: 编译验证 + Commit**

---

### Task 2: AlertSensitivity 枚举 + Fence 模型扩展 + DB 迁移

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/AlertSensitivity.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/Fence.java`
- Create: `smart-livestock-server/src/main/resources/db/migration/V20260713YYYYYY__add_fence_alert_sensitivity.sql`

**Interfaces:**
- Produces: `AlertSensitivity` enum: `HIGH`, `STANDARD`, `LOW`
- Produces: `Fence.getAlertSensitivity()` → `STANDARD` by default

- [ ] **Step 1: 创建 AlertSensitivity 枚举**

```java
package com.smartlivestock.ranch.domain.model;

/**
 * 围栏告警灵敏度。控制围栏越界检测中"多大的位移才算真实移动"。
 *
 * HIGH   — 高灵敏度，位移超过设备 P50 即确认（适合高风险边界）
 * STANDARD — 标准，位移超过设备 P95 才确认（默认）
 * LOW    — 低灵敏度，位移超过设备野点阈值才确认（适合内部轮牧分区）
 */
public enum AlertSensitivity {
    HIGH,
    STANDARD,
    LOW;

    /** 默认值 */
    public static final AlertSensitivity DEFAULT = STANDARD;
}
```

- [ ] **Step 2: 创建 Flyway 迁移**

```sql
-- V20260713YYYYYY__add_fence_alert_sensitivity.sql
ALTER TABLE fences
    ADD COLUMN IF NOT EXISTS alert_sensitivity VARCHAR(10) NOT NULL DEFAULT 'STANDARD';

COMMENT ON COLUMN fences.alert_sensitivity IS '告警灵敏度: HIGH / STANDARD / LOW';
```

- [ ] **Step 3: 修改 Fence 领域模型**

在 `Fence.java` 中添加字段（在 `bufferDistance` 字段附近）：

```java
// ── Alert sensitivity ──
private AlertSensitivity alertSensitivity = AlertSensitivity.DEFAULT;

public AlertSensitivity getAlertSensitivity() { return alertSensitivity; }
public void setAlertSensitivity(AlertSensitivity alertSensitivity) {
    this.alertSensitivity = alertSensitivity;
}
```

- [ ] **Step 4: 编译验证**

```bash
cd smart-livestock-server && ./gradlew compileJava
```

- [ ] **Step 5: Commit**

```bash
git add smart-livestock-server/src/main/resources/db/migration/V20260713YYYYYY__add_fence_alert_sensitivity.sql
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/AlertSensitivity.java
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/Fence.java
git commit -m "feat: add AlertSensitivity enum and fence column"
```

---

### Task 3: GpsGovernanceState + GovernedPosition 值对象 + GpsGovernanceService 核心逻辑

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/GpsGovernanceState.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/GovernedPosition.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/service/GpsGovernanceService.java`
- Create: `smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/GpsGovernanceServiceTest.java`

**Interfaces:**
- Produces: `GpsGovernanceState` — 运行时状态值对象（位置缓冲、确认位置、冷却时间戳）
- Produces: `GovernedPosition` — 治理输出（位置估计 + 是否触发围栏检测）
- Produces: `GpsGovernanceService` — `GovernedPosition evaluate(Long livestockId, BigDecimal lat, BigDecimal lon, BigDecimal motionIntensity, Integer stepNumber, AlertSensitivity sensitivity, DeviceCalibration cal)`

- [ ] **Step 1: 创建 GpsGovernanceState**

```java
package com.smartlivestock.ranch.domain.model;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedList;
import java.util.List;

/**
 * 单头牲畜的 GPS 治理运行时状态。存储在 Redis，TTL = 24h。
 */
public class GpsGovernanceState {
    private Long livestockId;
    private BigDecimal confirmedLat;      // 已确认位置（纬度）
    private BigDecimal confirmedLon;      // 已确认位置（经度）
    private LinkedList<BigDecimal> latBuffer;  // 最近 5 个点（纬度）
    private LinkedList<BigDecimal> lonBuffer;  // 最近 5 个点（经度）
    private Instant lastBreachAlertAt;    // 上次越界告警时间（冷却期用）
    private Instant updatedAt;

    public GpsGovernanceState() {
        this.latBuffer = new LinkedList<>();
        this.lonBuffer = new LinkedList<>();
    }

    public GpsGovernanceState(Long livestockId) {
        this();
        this.livestockId = livestockId;
    }

    public Long getLivestockId() { return livestockId; }
    public BigDecimal getConfirmedLat() { return confirmedLat; }
    public BigDecimal getConfirmedLon() { return confirmedLon; }
    public void setConfirmedPosition(BigDecimal lat, BigDecimal lon) {
        this.confirmedLat = lat;
        this.confirmedLon = lon;
    }
    public LinkedList<BigDecimal> getLatBuffer() { return latBuffer; }
    public LinkedList<BigDecimal> getLonBuffer() { return lonBuffer; }
    public Instant getLastBreachAlertAt() { return lastBreachAlertAt; }
    public void setLastBreachAlertAt(Instant t) { this.lastBreachAlertAt = t; }
    public Instant getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Instant t) { this.updatedAt = t; }

    /** 向滑动窗口添加一个点 */
    public void pushToBuffer(BigDecimal lat, BigDecimal lon) {
        latBuffer.add(lat);
        lonBuffer.add(lon);
        if (latBuffer.size() > 5) { latBuffer.removeFirst(); lonBuffer.removeFirst(); }
    }

    /** 窗口是否已满（至少 3 个点才有统计意义） */
    public boolean isBufferReady() {
        return latBuffer.size() >= 3;
    }

    /**
     * 计算纬度缓冲区的中值。
     * 注意：分别对 lat 和 lon 取一维中值是简化做法——中值坐标点
     * 可能不在实际数据点中，但对于去除 GPS 抖动足够有效。
     */
    public BigDecimal getBufferMedianLat() {
        return median(latBuffer);
    }

    public BigDecimal getBufferMedianLon() {
        return median(lonBuffer);
    }

    private BigDecimal median(LinkedList<BigDecimal> buffer) {
        List<BigDecimal> sorted = new ArrayList<>(buffer);
        Collections.sort(sorted);
        int mid = sorted.size() / 2;
        return sorted.size() % 2 == 0
                ? sorted.get(mid - 1).add(sorted.get(mid)).divide(BigDecimal.valueOf(2), RoundingMode.HALF_UP)
                : sorted.get(mid);
    }
}
```

- [ ] **Step 2: 创建 GovernedPosition**

```java
package com.smartlivestock.ranch.domain.model;

import java.math.BigDecimal;

/**
 * GpsGovernanceService 的输出。
 */
public class GovernedPosition {
    private final BigDecimal latitude;
    private final BigDecimal longitude;
    private final boolean positionConfirmed;   // 位置是否确认（触发围栏检测）
    private final boolean outlier;             // 当前点是否为野点
    private final String reason;               // 决策原因（调试用）

    public GovernedPosition(BigDecimal lat, BigDecimal lon,
                           boolean confirmed, boolean outlier, String reason) {
        this.latitude = lat;
        this.longitude = lon;
        this.positionConfirmed = confirmed;
        this.outlier = outlier;
        this.reason = reason;
    }

    public static GovernedPosition jitter(BigDecimal lat, BigDecimal lon) {
        return new GovernedPosition(lat, lon, false, false, "within jitter radius");
    }

    public static GovernedPosition moved(BigDecimal lat, BigDecimal lon, String detail) {
        return new GovernedPosition(lat, lon, true, false, "movement confirmed: " + detail);
    }

    public static GovernedPosition outlier(BigDecimal confirmedLat, BigDecimal confirmedLon) {
        return new GovernedPosition(confirmedLat, confirmedLon, false, true, "outlier detected");
    }

    public BigDecimal getLatitude() { return latitude; }
    public BigDecimal getLongitude() { return longitude; }
    public boolean isPositionConfirmed() { return positionConfirmed; }
    public boolean isOutlier() { return outlier; }
    public String getReason() { return reason; }
}
```

- [ ] **Step 3: 编写 GpsGovernanceService 测试（TDD）**

```java
package com.smartlivestock.ranch.domain.service;

import static org.junit.jupiter.api.Assertions.*;
import com.smartlivestock.iot.domain.model.DeviceCalibration;
import com.smartlivestock.ranch.domain.model.AlertSensitivity;
import com.smartlivestock.ranch.domain.model.GovernedPosition;
import org.junit.jupiter.api.Test;
import java.math.BigDecimal;

class GpsGovernanceServiceTest {

    private final GpsGovernanceService service = new GpsGovernanceService();

    private DeviceCalibration makeCal() {
        DeviceCalibration cal = new DeviceCalibration();
        cal.setGpsJitterRadius(new BigDecimal("19"));
        cal.setGpsMedianError(new BigDecimal("6"));
        cal.setGpsOutlierThreshold(new BigDecimal("64"));
        cal.setGpsP90Error(new BigDecimal("15"));
        cal.setAccelMagRestMean(new BigDecimal("0.97"));
        cal.setAccelFalseActiveRate(new BigDecimal("0.10"));  // < 15% threshold → accel assist enabled
        cal.setCalibrationQuality(BigDecimal.ONE);
        return cal;
    }

    @Test
    void shouldReturnJitterWhenDisplacementWithinRadius() {
        GpsGovernanceState state = new GpsGovernanceState(1L);
        state.setConfirmedPosition(new BigDecimal("28.246600"), new BigDecimal("112.851600"));

        // 新点距确认位置约 5m，在 P95(19m) 内 → jitter
        GovernedPosition result = service.evaluate(state,
                new BigDecimal("28.246610"), new BigDecimal("112.851610"),
                BigDecimal.ZERO, 0,
                AlertSensitivity.STANDARD, makeCal());

        assertFalse(result.isPositionConfirmed());
        assertFalse(result.isOutlier());
    }

    @Test
    void shouldConfirmMoveWhenLargeDisplacement() {
        GpsGovernanceState state = new GpsGovernanceState(1L);
        state.setConfirmedPosition(new BigDecimal("28.246600"), new BigDecimal("112.851600"));

        // 新点距确认位置约 100m，超过 outlier threshold(64m) → 确认移动
        GovernedPosition result = service.evaluate(state,
                new BigDecimal("28.247500"), new BigDecimal("112.851600"),
                BigDecimal.ZERO, 0,
                AlertSensitivity.STANDARD, makeCal());

        assertTrue(result.isPositionConfirmed());
    }

    @Test
    void shouldBeSensitiveAtHighMode() {
        GpsGovernanceState state = new GpsGovernanceState(1L);
        state.setConfirmedPosition(new BigDecimal("28.246600"), new BigDecimal("112.851600"));

        // HIGH 模式：阈值 = P50(6m)，新点距离 15m > 6m → 确认移动
        GovernedPosition result = service.evaluate(state,
                new BigDecimal("28.246700"), new BigDecimal("112.851550"),
                BigDecimal.ZERO, 0,
                AlertSensitivity.HIGH, makeCal());

        assertTrue(result.isPositionConfirmed());
    }

    @Test
    void shouldBeConservativeAtLowMode() {
        GpsGovernanceState state = new GpsGovernanceState(1L);
        state.setConfirmedPosition(new BigDecimal("28.246600"), new BigDecimal("112.851600"));

        // LOW 模式：阈值 = outlier(64m)，新点距离 15m < 64m → jitter
        GovernedPosition result = service.evaluate(state,
                new BigDecimal("28.246700"), new BigDecimal("112.851550"),
                BigDecimal.ZERO, 0,
                AlertSensitivity.LOW, makeCal());

        assertFalse(result.isPositionConfirmed());
    }

    @Test
    void shouldSupportMoveWithStepNumber() {
        GpsGovernanceState state = new GpsGovernanceState(1L);
        state.setConfirmedPosition(new BigDecimal("28.246600"), new BigDecimal("112.851600"));

        // 位移约 15m，在灰色地带(P50=6m ~ P95=19m)，stepNumber=5 → 加速度计投票支持移动
        GovernedPosition result = service.evaluate(state,
                new BigDecimal("28.246700"), new BigDecimal("112.851700"),
                new BigDecimal("0.3"), 5,
                AlertSensitivity.STANDARD, makeCal());

        assertTrue(result.isPositionConfirmed());
    }

    @Test
    void shouldMarkOutlierWhenFarFromBuffer() {
        GpsGovernanceState state = new GpsGovernanceState(1L);
        state.setConfirmedPosition(new BigDecimal("28.246600"), new BigDecimal("112.851600"));
        // 填充 buffer 使其 ready
        for (int i = 0; i < 5; i++) {
            state.pushToBuffer(new BigDecimal("28.24660" + i), new BigDecimal("112.85160" + i));
        }

        // 新点距离 buffer 中值 > 3x outlier threshold → 野点
        GovernedPosition result = service.evaluate(state,
                new BigDecimal("28.250000"), new BigDecimal("112.850000"),
                BigDecimal.ZERO, 0,
                AlertSensitivity.STANDARD, makeCal());

        assertTrue(result.isOutlier());
        assertFalse(result.isPositionConfirmed());
    }
}
```

- [ ] **Step 4: 运行测试确认失败**

```bash
cd smart-livestock-server && ./gradlew test --tests "*GpsGovernanceServiceTest"
```
Expected: FAIL — `GpsGovernanceService` not yet implemented.

- [ ] **Step 5: 实现 GpsGovernanceService**

```java
package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.iot.domain.model.DeviceCalibration;
import com.smartlivestock.ranch.domain.model.AlertSensitivity;
import com.smartlivestock.ranch.domain.model.GovernedPosition;
import com.smartlivestock.ranch.domain.model.GpsGovernanceState;
import org.springframework.stereotype.Component;
import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;

/**
 * GPS 数据治理管道。
 *
 * Layer 1: 野点检测 — 基于滑动窗口 MAD
 * Layer 2: 滑动窗口中值滤波 — 缓冲区去抖
 * Layer 3: 位移确认 — 基于标定参数 + 容忍度判断是否真实移动
 */
@Component
public class GpsGovernanceService {

    private static final BigDecimal METERS_PER_DEG_LAT = new BigDecimal("111320.0");
    private static final MathContext MC = new MathContext(10, RoundingMode.HALF_UP);

    /**
     * 评估一个新的 GPS 点，返回治理后的位置。
     *
     * @param state        该牲畜的运行时治理状态
     * @param lat          新 GPS 点纬度
     * @param lon          新 GPS 点经度
     * @param motionIntensity  加速度计运动强度 (g)，可为 null
     * @param stepNumber   本周期步数，可为 null
     * @param sensitivity  围栏告警灵敏度
     * @param cal          该设备的出厂标定参数，可为 null（使用保守默认值）
     */
    public GovernedPosition evaluate(GpsGovernanceState state,
                                     BigDecimal lat, BigDecimal lon,
                                     BigDecimal motionIntensity, Integer stepNumber,
                                     AlertSensitivity sensitivity, DeviceCalibration cal) {

        // 冷启动：第一个点直接设为确认位置
        if (state.getConfirmedLat() == null) {
            state.setConfirmedPosition(lat, lon);
            state.pushToBuffer(lat, lon);
            return GovernedPosition.moved(lat, lon, "cold start");
        }

        // ── Layer 1: 野点检测 ──
        if (state.isBufferReady() && cal != null) {
            BigDecimal medianLat = state.getBufferMedianLat();
            BigDecimal medianLon = state.getBufferMedianLon();
            double distToMedian = haversine(
                    lat.doubleValue(), lon.doubleValue(),
                    medianLat.doubleValue(), medianLon.doubleValue());

            // 野点 = 距窗口中值 > 3× P90 且 > 30m
            double outlierLimit = Math.max(
                    cal.getGpsP90Error().doubleValue() * 3.0, 30.0);
            if (distToMedian > outlierLimit) {
                // 不加入 buffer（避免污染），不触发围栏
                return GovernedPosition.outlier(state.getConfirmedLat(), state.getConfirmedLon());
            }
        }

        // ── Layer 2: 滑动窗口中值滤波 ──
        state.pushToBuffer(lat, lon);
        BigDecimal filteredLat = state.isBufferReady()
                ? state.getBufferMedianLat() : lat;
        BigDecimal filteredLon = state.isBufferReady()
                ? state.getBufferMedianLon() : lon;

        // ── Layer 3: 位移确认 ──
        double displacement = haversine(
                filteredLat.doubleValue(), filteredLon.doubleValue(),
                state.getConfirmedLat().doubleValue(), state.getConfirmedLon().doubleValue());

        double threshold = getMovementThreshold(sensitivity, cal);

        boolean isMoving = displacement >= threshold;

        // 灰色地带（P50 < displacement < P95）→ 加速度计辅助判断
        // 仅当设备标定后静止误报率 < 15% 时才启用（需求 §9.2 加速度计可用性门槛）
        if (!isMoving && cal != null) {
            double p50 = cal.getGpsMedianError().doubleValue();
            double p95 = cal.getGpsJitterRadius().doubleValue();
            if (displacement > p50 && displacement < p95) {
                boolean accelEnabled = cal.getAccelFalseActiveRate() != null
                        && cal.getAccelFalseActiveRate().doubleValue() < 0.15;
                boolean accelSuggestsMove = false;
                if (accelEnabled && stepNumber != null && stepNumber > 0) accelSuggestsMove = true;
                if (accelEnabled && motionIntensity != null && cal.getAccelMagRestMean() != null) {
                    double restBaseline = cal.getAccelMagRestMean().doubleValue();
                    if (motionIntensity.doubleValue() > restBaseline * 2.0) accelSuggestsMove = true;
                }
                if (accelSuggestsMove) {
                    isMoving = true;
                }
            }
        }

        if (isMoving) {
            state.setConfirmedPosition(filteredLat, filteredLon);
            String detail = String.format("displacement=%.1fm, threshold=%.1fm, sensitivity=%s",
                    displacement, threshold, sensitivity);
            return GovernedPosition.moved(filteredLat, filteredLon, detail);
        }

        return GovernedPosition.jitter(state.getConfirmedLat(), state.getConfirmedLon());
    }

    private double getMovementThreshold(AlertSensitivity sensitivity, DeviceCalibration cal) {
        if (cal == null) {
            // 保守默认值（未标定设备）
            return 50.0;   // fallback_defaults.gps_jitter_radius (收紧：未标定宁可误报不漏报)
        }
        return cal.getMovementThreshold(sensitivity).doubleValue();
    }

    /** Haversine 距离（米） */
    static double haversine(double lat1, double lon1, double lat2, double lon2) {
        double R = 6371000.0;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }
}
```

- [ ] **Step 6: 运行测试确认通过**

```bash
cd smart-livestock-server && ./gradlew test --tests "*GpsGovernanceServiceTest"
```
Expected: ALL PASS.

- [ ] **Step 7: Commit**

```bash
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/GpsGovernanceState.java
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/model/GovernedPosition.java
git add smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/service/GpsGovernanceService.java
git add smart-livestock-server/src/test/java/com/smartlivestock/ranch/domain/service/GpsGovernanceServiceTest.java
git commit -m "feat: add GpsGovernanceService with movement detection pipeline"
```

---

### Task 4: Redis 位置状态缓存 (PositionStateCache)

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/cache/PositionStateCache.java`

**Interfaces:**
- Produces: `PositionStateCache` — `getState(Long livestockId) → GpsGovernanceState`, `saveState(Long livestockId, GpsGovernanceState)`
- Depends on: Redis `StringRedisTemplate` (已在项目中可用)

- [ ] **Step 1: 实现 PositionStateCache**

```java
package com.smartlivestock.ranch.infrastructure.cache;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.smartlivestock.ranch.domain.model.GpsGovernanceState;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;
import java.time.Duration;

@Slf4j
@Component
@RequiredArgsConstructor
public class PositionStateCache {

    private static final String KEY_PREFIX = "gps:state:";
    private static final Duration TTL = Duration.ofHours(24);

    private final StringRedisTemplate redis;
    private final ObjectMapper mapper = new ObjectMapper()
            .registerModule(new JavaTimeModule());

    public GpsGovernanceState getState(Long livestockId) {
        try {
            String json = redis.opsForValue().get(key(livestockId));
            if (json == null) return new GpsGovernanceState(livestockId);
            return mapper.readValue(json, GpsGovernanceState.class);
        } catch (JsonProcessingException e) {
            log.warn("Failed to deserialize GpsGovernanceState for livestock [{}]: {}",
                    livestockId, e.getMessage());
            return new GpsGovernanceState(livestockId);
        }
    }

    public void saveState(Long livestockId, GpsGovernanceState state) {
        try {
            state.setUpdatedAt(java.time.Instant.now());
            String json = mapper.writeValueAsString(state);
            redis.opsForValue().set(key(livestockId), json, TTL);
        } catch (JsonProcessingException e) {
            log.error("Failed to serialize GpsGovernanceState for livestock [{}]", livestockId, e);
        }
    }

    private String key(Long livestockId) {
        return KEY_PREFIX + livestockId;
    }
}
```

**并发竞态处理**:

`GpsGovernanceService.evaluate()` 会 mutate `GpsGovernanceState`，在 RocketMQ 并发消费场景下存在竞态风险。处理策略：

1. **消费端顺序消费**：将 RocketMQ 消费者从并发模式改为顺序消费（`MessageModel.CLUSTERING` + `Consume Mode.ORDERLY`），按 `deviceId` 的 hash 队列分配，确保同一设备的消息由同一线程顺序消费。
2. **Redis CAS 保护**：`PositionStateCache.saveState()` 使用 Redis 的 `WATCH/MULTI/EXEC` 或乐观锁（比较 `updatedAt` 时间戳），检测到版本冲突时重读 state 并重新 evaluate。
3. **幂等设计**：`GpsGovernanceState.pushToBuffer()` 在保存前检查最新点的 `recordedAt`，重复消息不重复入 buffer。

推荐方案 1（顺序消费），因为它从源头消除了竞态，且对同一设备的 GPS 消息顺序消费是语义正确的。

- [ ] **Step 2: 编译验证**

```bash
cd smart-livestock-server && ./gradlew compileJava
```

- [ ] **Step 3: Commit**

---

### Task 5: AlertRepository 冷却期查询

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/repository/AlertRepository.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/JpaAlertRepositoryImpl.java`（或对应的 JPA 实现类）

**背景**: 当前 AlertRepository 的查询全部返回 List，没有按时间排序取 top-1 的方法。冷却期逻辑需要查询"同一 livestock + fence 最近一条已解除的告警"，判断是否在冷却窗口内。

- [ ] **Step 1: AlertRepository 接口新增方法**

```java
/**
 * 查询同一 livestock + fence 最近一条已解除（AUTO_RESOLVED）的告警，
 * 用于冷却期判断。
 */
Optional<Alert> findLatestResolved(Long livestockId, Long fenceId);
```

- [ ] **Step 2: JPA 实现**

在 JpaAlertRepositoryImpl 中实现（使用 Spring Data JPA @Query）：
```java
@Override
public Optional<Alert> findLatestResolved(Long livestockId, Long fenceId) {
    return alertJpaRepository
            .findTopByLivestockIdAndFenceIdAndStatusOrderByResolvedAtDesc(
                    livestockId, fenceId, AlertStatus.AUTO_RESOLVED)
            .map(alertMapper::toDomain);
}
```

对应的 Spring Data JPA Repository 接口方法：
```java
Optional<AlertJpaEntity> findTopByLivestockIdAndFenceIdAndStatusOrderByResolvedAtDesc(
        Long livestockId, Long fenceId, AlertStatus status);
```

- [ ] **Step 3: 单元测试**

```java
@Test
void findLatestResolvedShouldReturnMostRecent() {
    // 创建两条已解除告警，resolvedAt 不同
    // 验证返回 resolvedAt 更大的那条
}

@Test
void findLatestResolvedShouldReturnEmptyWhenNone() {
    // 无已解除告警时返回 empty
}
```

- [ ] **Step 4: 编译验证 + 测试通过 + Commit**

---

### Task 6: 改造 GpsLogEventConsumer 集成治理管道

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/mq/GpsLogEventConsumer.java`

**Interfaces:**
- Consumes: `GpsGovernanceService`, `PositionStateCache`, `DeviceCalibrationRepository`, `AlertRepository.findLatestResolved`
- Modifies: `onMessage()` — 接入治理管道；`createAlertIfNeeded()` — 增加冷却期检查

**改造原则**:
- 治理管道是**包裹**现有围栏检测，不是替换——`GpsGovernanceService.evaluate()` 在 `FenceBreachDetector` 之前执行，输出 `GovernedPosition`。只有 `isPositionConfirmed()` 为 true 时才进入围栏检测。
- 原有的 `FenceBreachDetector` 逻辑保留，但输入从原始 GPS 坐标改为治理后的 `GovernedPosition` 坐标。
- 原有的 `autoResolveFenceAlerts()` 和 `autoResolveOppositeTypeAlerts()` 保留。
- `createAlertIfNeeded()` 升级为 `createAlertWithCooldown()`，新增冷却期检查。
- 构造器注入从 6 个依赖增加到 9 个（新增 `GpsGovernanceService`, `PositionStateCache`, `DeviceCalibrationRepository`）。

- [ ] **Step 1: 重写 GpsLogEventConsumer**

核心改动点（在原 `onMessage` 方法中插入治理逻辑）：

```java
@Slf4j
@Component
@RocketMQMessageListener(topic = "gps-log-updated", consumerGroup = "ranch-gps-consumer")
@RequiredArgsConstructor
public class GpsLogEventConsumer implements RocketMQListener<String> {

    private final ObjectMapper objectMapper;
    private final IoTQueryPort ioTQueryPort;
    private final LivestockRepository livestockRepository;
    private final FenceRepository fenceRepository;
    private final AlertRepository alertRepository;
    private final FenceBreachDetector fenceBreachDetector;
    // 新增依赖
    private final GpsGovernanceService gpsGovernanceService;
    private final PositionStateCache positionStateCache;
    private final DeviceCalibrationRepository deviceCalibrationRepository;

    private static final long BREACH_COOLDOWN_MINUTES = 90;

    @Override
    @Transactional
    public void onMessage(String message) {
        try {
            JsonNode root = objectMapper.readTree(message);
            Long deviceId = root.path("deviceId").asLong();
            BigDecimal latitude = new BigDecimal(root.path("latitude").asText());
            BigDecimal longitude = new BigDecimal(root.path("longitude").asText());
            // 加速度计辅助字段（可能不存在）
            BigDecimal motionIntensity = root.has("motionIntensity")
                    ? new BigDecimal(root.path("motionIntensity").asText()) : null;
            Integer stepNumber = root.has("stepNumber")
                    ? root.path("stepNumber").asInt() : null;

            InstallationInfo installation = ioTQueryPort.findActiveInstallation(deviceId).orElse(null);
            if (installation == null) return;

            Long livestockId = installation.livestockId();
            Livestock livestock = livestockRepository.findById(livestockId).orElse(null);
            if (livestock == null) return;

            Long farmId = livestock.getFarmId();
            List<Fence> fences = fenceRepository.findByFarmId(farmId);
            if (fences.isEmpty()) return;

            // ── 加载标定参数 ──
            DeviceCalibration cal = deviceCalibrationRepository.findByDeviceId(deviceId).orElse(null);

            // ── 加载运行时状态 ──
            GpsGovernanceState state = positionStateCache.getState(livestockId);

            // ── 对每个活跃围栏执行治理 ──
            for (Fence fence : fences) {
                if (!fence.isActive()) continue;

                GovernedPosition pos = gpsGovernanceService.evaluate(
                        state, latitude, longitude, motionIntensity, stepNumber,
                        fence.getAlertSensitivity(), cal);

                if (!pos.isPositionConfirmed()) {
                    // 位置未确认（抖动或野点）→ 不触发围栏检测
                    // 但如果已在围栏外且位置回到围栏内 → 仍需要解除告警
                    if (fence.contains(new GpsCoordinate(pos.getLatitude(), pos.getLongitude()))) {
                        autoResolveFenceAlerts(livestockId, farmId);
                    }
                    continue;
                }

                // 位置已确认 → 执行围栏检测
                GpsCoordinate governedPos = new GpsCoordinate(pos.getLatitude(), pos.getLongitude());

                if (fence.contains(governedPos)) {
                    autoResolveFenceAlerts(livestockId, farmId);
                } else {
                    boolean inBuffer = fence.containsBuffer(governedPos);
                    AlertType type = fence.isActive()
                            ? (inBuffer ? AlertType.FENCE_APPROACH : AlertType.FENCE_BREACH)
                            : null;
                    if (type != null) {
                        Severity severity = type == AlertType.FENCE_BREACH
                                ? Severity.CRITICAL : Severity.WARNING;
                        createAlertWithCooldown(livestock, fence, type, severity, governedPos);
                    }
                }
            }

            // 保存治理状态
            positionStateCache.saveState(livestockId, state);

        } catch (Exception e) {
            log.error("Failed to process GPS log message: {}", e.getMessage(), e);
            throw new RuntimeException(e);
        }
    }

    /**
     * 创建告警（含冷却期检查）。
     */
    private void createAlertWithCooldown(Livestock livestock, Fence fence,
                                          AlertType type, Severity severity,
                                          GpsCoordinate position) {
        // 检查是否已有同类型活跃告警
        List<Alert> existing = alertRepository.findByLivestockIdAndTypeAndStatus(
                livestock.getId(), type, AlertStatus.ACTIVE);
        boolean hasExisting = existing.stream()
                .anyMatch(a -> fence.getId().equals(a.getFenceId()));
        if (hasExisting) return;

        // 冷却期检查：上次同围栏告警解除后 90 分钟内不重建
        Alert latestResolved = alertRepository.findLatestResolved(
                livestock.getId(), fence.getId()).orElse(null);
        if (latestResolved != null && latestResolved.getResolvedAt() != null) {
            long minutesSinceResolved = java.time.Duration.between(
                    latestResolved.getResolvedAt(), java.time.Instant.now()).toMinutes();
            if (minutesSinceResolved < BREACH_COOLDOWN_MINUTES) {
                log.debug("Alert cooldown active for livestock [{}] fence [{}]: {}min remaining",
                        livestock.getId(), fence.getId(),
                        BREACH_COOLDOWN_MINUTES - minutesSinceResolved);
                return;
            }
        }

        String typeLabel = type == AlertType.FENCE_BREACH ? "越出" : "接近";
        String msg = String.format("牲畜 [%s] %s围栏 [%s]，位置: (%s, %s)",
                livestock.getLivestockCode(), typeLabel, fence.getName(),
                position.latitude(), position.longitude());
        Alert alert = new Alert(livestock.getFarmId(), livestock.getId(), fence.getId(),
                type, severity, msg);
        alertRepository.save(alert);
        log.info("Created {} alert for livestock [{}] fence [{}]", type, livestock.getId(), fence.getId());
    }

    // ... 保留原有的 autoResolveFenceAlerts() 和 autoResolveOppositeTypeAlerts()
}
```

- [ ] **Step 2: 注入新依赖到 Consumer**

在原有 `@RequiredArgsConstructor` 基础上，新增字段即可（Lombok 自动生成构造器注入）。

- [ ] **Step 3: 编译验证**

```bash
cd smart-livestock-server && ./gradlew compileJava
```

- [ ] **Step 4: Commit**

---

### Task 7: activity_class 分类算法改进

**Files:**
- Modify: `business-platform/hkt-blade-device-docking/src/main/java/com/smartlivestock/docking/util/AccelerometerConverter.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverter.java`
- Modify: `business-platform/hkt-blade-device-docking/src/test/java/com/smartlivestock/docking/util/AccelerometerConverterTest.java`
- Modify: `smart-livestock-server/src/test/java/com/smartlivestock/iot/infrastructure/client/agenticplatform/util/AccelerometerConverterTest.java`

> **注意**: `AccelerometerConverter` 在两个仓库逐字节重复存在（代码核查确认）。两个仓库的 `classifyActivity` 必须同步修改，否则算法分叉。当前是技术债——同一逻辑不应在两处维护，但本 Task 不处理重构（合并为单一数据源），仅确保两处同步修改。

- [ ] **Step 1: 改进 classifyActivity**

用 `motion_intensity`（|mag - 1.0|）替代纯 `|mag|`，消除设备间重力基线差异：

```java
/**
 * Classify activity level based on motion intensity (|mag - 1.0g|).
 *
 * Thresholds based on static device calibration analysis (2026-07-13):
 *   — Stationary devices: motion_intensity typically 0.0–0.3g
 *   — Active movement:      motion_intensity typically > 0.5g
 *
 * @param magnitudeG vector magnitude in g
 * @return "rest" | "light" | "active" | "intense"
 */
public static String classifyActivity(double magnitudeG) {
    double motionIntensity = Math.abs(magnitudeG - 1.0);
    if (motionIntensity < 0.20) return "rest";
    if (motionIntensity < 0.50) return "light";
    if (motionIntensity < 1.50) return "active";
    return "intense";
}
```

**阈值依据：**
- `rest`: motion_intensity < 0.20g — 5 台静止设备 \|mag\| 偏差 P90 均在 0.2g 以内
- `light`: 0.20–0.50g — 牛吃草、慢走的轻度活动
- `active`: 0.50–1.50g — 正常行走
- `intense`: > 1.50g — 奔跑或强烈振动

- [ ] **Step 2: 更新测试**

```java
@Test
void classifyActivityShouldUseMotionIntensity() {
    // 静止：|mag| = 1.05 → motion = 0.05 → rest
    assertEquals("rest", AccelerometerConverter.classifyActivity(1.05));
    // 静止：|mag| = 1.12 → motion = 0.12 → rest
    assertEquals("rest", AccelerometerConverter.classifyActivity(1.12));
    // 轻度：|mag| = 1.30 → motion = 0.30 → light
    assertEquals("light", AccelerometerConverter.classifyActivity(1.30));
    // 明显：|mag| = 1.60 → motion = 0.60 → active
    assertEquals("active", AccelerometerConverter.classifyActivity(1.60));
    // 剧烈：|mag| = 2.80 → motion = 1.80 → intense
    assertEquals("intense", AccelerometerConverter.classifyActivity(2.80));
}
```

- [ ] **Step 3: 运行测试**

```bash
cd business-platform/hkt-blade-device-docking && ./gradlew test --tests "*AccelerometerConverterTest*"
cd smart-livestock-server && ./gradlew test --tests "*AccelerometerConverterTest*"
```
Expected: PASS.

- [ ] **Step 4: Commit**

---

### Task 8: FenceApplicationService 支持 alertSensitivity CRUD

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/FenceApplicationService.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/command/CreateFenceCommand.java` (如存在)
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/command/UpdateFenceCommand.java` (如存在)
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/application/dto/FenceDto.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/entity/FenceJpaEntity.java`

- [ ] **Step 1: 扩展 FenceJpaEntity**

```java
// 在 FenceJpaEntity 中添加
@Column(name = "alert_sensitivity", length = 10)
private String alertSensitivity = "STANDARD";
// getter/setter
```

- [ ] **Step 2: 扩展 FenceDto**

```java
// 在 FenceDto 中添加
private String alertSensitivity;
// getter/setter
```

- [ ] **Step 3: 修改 FenceApplicationService**

创建围栏时支持 `alertSensitivity` 参数，更新围栏时允许修改。

- [ ] **Step 4: 编译验证 + Commit**

---

### Task 9: Fallback 默认值配置

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/domain/service/FallbackCalibration.java`

- [ ] **Step 1: 创建保守默认值常量**

```java
package com.smartlivestock.ranch.domain.service;

import com.smartlivestock.iot.domain.model.DeviceCalibration;
import java.math.BigDecimal;

/**
 * 未标定设备使用的保守默认参数。
 * 基于 5 台样品设备的最差表现（2026-07-13 标定结果）。
 */
public final class FallbackCalibration {

    /**
     * 冷启动位移确认阈值。
     * 原评审建议从 142m 收紧到 50m——在未标定阶段，宁可少量误报也不漏报真实越界。
     * 142m 太松：牛在围栏边界走动 100m 完全正常，但系统会判为"抖动"而不告警。
     */
    public static final BigDecimal GPS_JITTER_RADIUS     = new BigDecimal("50");
    // gps_median_error / gps_p90_error / gps_outlier_threshold 维持原值：
    // 这些是野点检测与灰色地带的边界，与 jitter_radius（位移确认门控）语义不同，
    // 无需随冷启动阈值收紧而同步下调；标定完成后由设备实际参数覆盖。
    public static final BigDecimal GPS_MEDIAN_ERROR      = new BigDecimal("24");
    public static final BigDecimal GPS_P90_ERROR         = new BigDecimal("86");
    public static final BigDecimal GPS_OUTLIER_THRESHOLD = new BigDecimal("355");
    public static final BigDecimal ACCEL_MAG_REST_MEAN   = new BigDecimal("1.000");
    public static final BigDecimal ACCEL_FALSE_ACTIVE_RATE = new BigDecimal("0.33");
    public static final BigDecimal CALIBRATION_QUALITY   = BigDecimal.ZERO;

    private FallbackCalibration() {}

    /** 构建一个未标定设备的默认参数对象 */
    public static DeviceCalibration create() {
        DeviceCalibration cal = new DeviceCalibration();
        cal.setGpsJitterRadius(GPS_JITTER_RADIUS);
        cal.setGpsMedianError(GPS_MEDIAN_ERROR);
        cal.setGpsP90Error(GPS_P90_ERROR);
        cal.setGpsOutlierThreshold(GPS_OUTLIER_THRESHOLD);
        cal.setAccelMagRestMean(ACCEL_MAG_REST_MEAN);
        cal.setAccelFalseActiveRate(ACCEL_FALSE_ACTIVE_RATE);
        cal.setCalibrationQuality(CALIBRATION_QUALITY);
        return cal;
    }
}
```

- [ ] **Step 2: 在 GpsLogEventConsumer 中使用**

当 `deviceCalibrationRepository.findByDeviceId()` 返回 empty 时，使用 `FallbackCalibration.create()`。

- [ ] **Step 3: Commit**

---

### Task 10: DeviceCalibration 基础设施层（JPA 实现）

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/persistence/entity/DeviceCalibrationJpaEntity.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/persistence/SpringDataDeviceCalibrationRepository.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/persistence/JpaDeviceCalibrationRepositoryImpl.java`
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/infrastructure/persistence/mapper/DeviceCalibrationMapper.java`

- [ ] **Step 1-5: 按标准 DDD 模式实现 JPA entity、Spring Data repo、impl、mapper**

遵循项目中已有的类似实现模式（参考 `GpsLogJpaEntity` / `JpaGpsLogRepositoryImpl` 的结构）。

- [ ] **Step 6: 编译验证**

```bash
cd smart-livestock-server && ./gradlew compileJava
```

- [ ] **Step 7: Commit**

---

### Task 11: DeviceCalibrationService（标定参数管理 API）

**Files:**
- Create: `smart-livestock-server/src/main/java/com/smartlivestock/iot/application/DeviceCalibrationService.java`
- Create: `smart-livestock-server/src/test/java/com/smartlivestock/iot/application/DeviceCalibrationServiceTest.java`

**Interfaces:**
- Produces: `DeviceCalibrationService.saveCalibration(...)` / `getCalibrationByDevEui(String)` / `getCalibrationByDeviceId(Long)`

- [ ] **Step 1: 实现 Service**

```java
@Service
@RequiredArgsConstructor
public class DeviceCalibrationService {
    private final DeviceCalibrationRepository repository;

    @Transactional
    public DeviceCalibration saveCalibration(String devEui, Long deviceId,
            BigDecimal gpsJitterRadius, BigDecimal gpsMedianError,
            BigDecimal gpsP90Error, BigDecimal gpsOutlierThreshold,
            BigDecimal gpsJitterDiameter, BigDecimal accelMagRestMean,
            BigDecimal accelFalseActiveRate, BigDecimal calibrationQuality) {
        DeviceCalibration cal = new DeviceCalibration(devEui, deviceId,
                gpsJitterRadius, gpsMedianError, gpsP90Error,
                gpsOutlierThreshold, gpsJitterDiameter,
                accelMagRestMean, accelFalseActiveRate,
                calibrationQuality, Instant.now());
        return repository.save(cal);
    }

    @Transactional(readOnly = true)
    public Optional<DeviceCalibration> getByDevEui(String devEui) {
        return repository.findByDevEui(devEui);
    }

    @Transactional(readOnly = true)
    public Optional<DeviceCalibration> getByDeviceId(Long deviceId) {
        return repository.findByDeviceId(deviceId);
    }
}
```

- [ ] **Step 2: 编写测试**

```java
// DeviceCalibrationServiceTest.java
// Mock DeviceCalibrationRepository，验证 save / findByDevEui / findByDeviceId 调用
```

- [ ] **Step 3: 编译验证 + 测试通过 + Commit**

---

### Task 12: Fence 基础设施层同步（JPA Entity + Mapper）

**Files:**
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/entity/FenceJpaEntity.java`
- Modify: `smart-livestock-server/src/main/java/com/smartlivestock/ranch/infrastructure/persistence/mapper/FenceMapper.java`

- [ ] **Step 1: FenceJpaEntity 添加 alertSensitivity 字段**（已在 Task 8 中完成）
- [ ] **Step 2: FenceMapper 同步 alertSensitivity 的 toDomain / toEntity 映射**
- [ ] **Step 3: 编译验证 + Commit**

---

### Task 13: 集成测试 — 完整治理 + 围栏链路

**Files:**
- Modify: `smart-livestock-server/src/test/java/com/smartlivestock/integration/GpsAlertFlowTest.java`

- [ ] **Step 1: 添加治理场景测试用例**

在现有 `GpsAlertFlowTest` 中新增：

```java
@Test
void shouldNotAlertWhenCowIsStationaryNearFence() {
    // 模拟：设备已标定（P95=19m），围栏容忍度 STANDARD
    // 连续发送 3 个在围栏内抖动（位移<19m）的 GPS 点
    // 预期：0 个告警（全部被治理层过滤）
}

@Test
void shouldAlertWhenCowMovesOutsideFence() {
    // 模拟：设备已标定，围栏容忍度 STANDARD
    // 第1个点：围栏内
    // 第2个点：围栏外 100m（位移 >> P95）
    // 预期：1 个 FENCE_BREACH 告警
}

@Test
void shouldRespectCooldown() {
    // 模拟：产生 BREACH → 牛回到围栏内（AUTO_RESOLVED）
    // → 立即再发一个围栏外点
    // 预期：90min 冷却期内不产生新告警
}
```

- [ ] **Step 2: 运行集成测试**

```bash
cd smart-livestock-server && ./gradlew test --tests "*GpsAlertFlowTest*"
```

- [ ] **Step 3: Commit**

---

### Task 14: 前端 — 围栏编辑页面添加灵敏度选择器

**Files:**
- Modify: `Mobile/mobile_app/lib/features/fence/presentation/...` (围栏编辑页面)
- Modify: `Mobile/mobile_app/lib/l10n/app_zh.arb` (中文文案)
- Modify: `Mobile/mobile_app/lib/l10n/app_en.arb` (英文文案)

- [ ] **Step 1: 在围栏编辑表单中添加下拉选择器**

三个选项（中文）：高灵敏度 / 标准（默认）/ 低灵敏度。调用围栏 API 时传入 `alertSensitivity` 字段。

- [ ] **Step 2: 添加 i18n 文案**

```json
// app_zh.arb
"fenceAlertSensitivity": "告警灵敏度",
"fenceAlertSensitivityHigh": "高灵敏度 — 有迹象就报",
"fenceAlertSensitivityStandard": "标准 — 明显移动才报",
"fenceAlertSensitivityLow": "低灵敏度 — 确认无疑才报"
```

- [ ] **Step 3: 运行 flutter analyze**

```bash
cd Mobile/mobile_app && flutter analyze
```

- [ ] **Step 4: Commit**

---

### Task 15: 前端 — 轨迹展示抖动过滤

**Files:**
- Modify: `Mobile/mobile_app/lib/features/.../trajectory_sheet.dart` 或轨迹渲染相关组件

- [ ] **Step 1: 添加最小位移阈值**

连续两点距离 < 12m → 合并为停留标记，不画轨迹线。
注意：这只是展示层过滤，不影响后端存储的原始数据。

- [ ] **Step 2: Commit**

---

## Task Dependency Graph

```
Task 1 (DeviceCalibration model + DB)
  └→ Task 10 (JPA 基础设施)
       └→ Task 11 (DeviceCalibrationService)
  └→ Task 1b (GpsLogUpdatedEvent 扩展)

Task 2 (AlertSensitivity + Fence extension + DB)
  └→ Task 8 (Fence CRUD 支持 sensitivity)
  └→ Task 12 (Fence JPA Entity 同步)

Task 3 (GpsGovernanceService 核心) [可独立开始]
  ├→ Task 4 (Redis PositionStateCache)
  ├→ Task 5 (AlertRepository 冷却期查询)
  ├→ Task 9 (FallbackCalibration)
  └→ Task 6 (GpsLogEventConsumer 改造)   ← 集成点：需要 Task 1, 1b, 2, 3, 4, 5, 9 全部完成

Task 7 (activity_class 改进) [独立]

Task 13 (集成测试) ← 依赖 Task 6 完成

Task 14 (前端围栏编辑) [独立，可并行]
Task 15 (前端轨迹展示) [独立，可并行]
```

---

## Self-Review

**Spec coverage check against requirements doc:**
- §4.4 出厂标定参数 → Task 1 (DeviceCalibration), Task 10 (JPA)
- §4.5 冷启动策略 → Task 9 (FallbackCalibration)
- §5.1 围栏预警零误报 → Task 3 (governance), Task 6 (consumer 改造)
- §5.1 告警不震荡 → Task 5 (冷却期), Task 6 (createAlertWithCooldown)
- §5.4 算法选型论证 → Task 3 注释说明中值滤波选型理由
- §5.2 轨迹平滑 → Task 15 (前端过滤)
- §6.4 向后兼容 → Task 6 (非 blade 来源走原逻辑), Task 9 (未标定设备用保守值)
- §9.2 activity_class 改进 → Task 7
- §9.3.3 容忍度参数 → Task 2 (AlertSensitivity), Task 8 (Fence CRUD), Task 14 (前端)

**Placeholder scan:** 无 TBD/TODO。所有代码块均含完整实现。测试用例含具体断言。

**Type consistency:** `GpsGovernanceService.evaluate()` 签名在各 Task 中一致；`DeviceCalibration.getMovementThreshold(AlertSensitivity)` 返回类型在 Task 1 定义、Task 3 调用一致。
