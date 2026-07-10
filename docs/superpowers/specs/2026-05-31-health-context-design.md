# MVP Phase 2b — Health 限界上下文设计规格

> 版本: 1.0 | 日期: 2026-05-31 | 状态: 待评审

## 1. 概述

Health 限界上下文负责牲畜健康数据的采集、存储、分析和预警，覆盖四个场景：

| 场景 | 数据源 | 核心分析 | 关联设备 |
|------|--------|---------|---------|
| 发热预警 | 瘤胃温度时序 | 基线偏移检测 + 异常报警 | CAPSULE |
| 消化管理 | 瘤胃蠕动频次/强度 | 蠕动异常检测 + 趋势分析 | CAPSULE |
| 发情识别 | 活动量+温度+位移 多维融合 | 发情评分 (0-100) | TRACKER + CAPSULE |
| 疫病防控 | 群体温度/活动聚合 | 群体异常率 + 接触追踪 | TRACKER + CAPSULE |

### 设计原则

- **延续现有架构**：DDD 洋葱架构（domain → application → infrastructure → interfaces），与 Commerce 保持一致
- **时序存储**：PostgreSQL 范围分区表（按月分区），不引入 TimescaleDB 新依赖
- **复用现有体系**：Alert 复用 Ranch 上下文的 alerts 表（type 已包含 TEMPERATURE_ABNORMAL / ESTRUS / EPIDEMIC）
- **前端模型对齐**：后端 API 响应结构与前端 `twin_models.dart` 已有模型对应

### 跨上下文依赖

```
IoT Context          Ranch Context           Health Context
─────────────        ──────────────          ──────────────
devices              livestock               temperature_logs
installations        alerts (复用)            rumen_motility_logs
                     fences                  activity_logs
                                             estrus_scores
                                             health_alerts (扩展alerts)
```

---

## 2. 数据库设计

### 2.1 V21 迁移 — 创建 Health 表

> 编号 V19（V18 已被 audit_logs 占用）

```sql
-- ============================================================
-- V20: Health Context — 时序数据表 + 发情评分 + 健康快照
-- ============================================================

-- ----------------------------------------------------------
-- 2.1.1 temperature_logs — 瘤胃温度时序（按月分区）
-- 数据源: CAPSULE 设备，采样间隔 ~30min
-- ----------------------------------------------------------
CREATE TABLE temperature_logs (
    id BIGSERIAL,
    livestock_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    temperature DECIMAL(5,2) NOT NULL,
    baseline_temp DECIMAL(5,2) NOT NULL DEFAULT 38.50,
    delta DECIMAL(5,2) GENERATED ALWAYS AS (temperature - baseline_temp) STORED,
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

-- 初始分区: 2026-03 ~ 2026-08（覆盖种子数据 + 未来几个月）
CREATE TABLE temperature_logs_2026_03 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE temperature_logs_2026_04 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE temperature_logs_2026_05 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE temperature_logs_2026_06 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE temperature_logs_2026_07 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE temperature_logs_2026_08 PARTITION OF temperature_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
-- 默认分区（捕获超出范围的意外数据）
CREATE TABLE temperature_logs_default PARTITION OF temperature_logs DEFAULT;

CREATE INDEX idx_temp_logs_livestock_time ON temperature_logs(livestock_id, recorded_at DESC);
CREATE INDEX idx_temp_logs_device_time ON temperature_logs(device_id, recorded_at DESC);
CREATE INDEX idx_temp_logs_delta ON temperature_logs(delta) WHERE delta > 1.0;

-- ----------------------------------------------------------
-- 2.1.2 rumen_motility_logs — 瘤胃蠕动时序（按月分区）
-- 数据源: CAPSULE 设备，采样间隔 ~30min
-- ----------------------------------------------------------
CREATE TABLE rumen_motility_logs (
    id BIGSERIAL,
    livestock_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    frequency DECIMAL(5,2) NOT NULL,      -- 蠕动频率（次/分钟）
    intensity DECIMAL(5,2) NOT NULL,       -- 蠕动强度（相对单位 0-100）
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE rumen_motility_logs_2026_03 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE rumen_motility_logs_2026_04 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE rumen_motility_logs_2026_05 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE rumen_motility_logs_2026_06 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE rumen_motility_logs_2026_07 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE rumen_motility_logs_2026_08 PARTITION OF rumen_motility_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE rumen_motility_logs_default PARTITION OF rumen_motility_logs DEFAULT;

CREATE INDEX idx_motility_logs_livestock_time ON rumen_motility_logs(livestock_id, recorded_at DESC);

-- ----------------------------------------------------------
-- 2.1.3 activity_logs — 活动量时序（按月分区）
-- 数据源: TRACKER (步数) + ACCELEROMETER (活动指数)
-- 采样间隔 ~1h
-- ----------------------------------------------------------
CREATE TABLE activity_logs (
    id BIGSERIAL,
    livestock_id BIGINT NOT NULL,
    device_id BIGINT NOT NULL,
    step_count INTEGER,                    -- GPS 追踪器计步
    activity_index DECIMAL(5,2),           -- 加速度计活动指数
    distance_meters DECIMAL(8,2),          -- 位移距离（米）
    recorded_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, recorded_at)
) PARTITION BY RANGE (recorded_at);

CREATE TABLE activity_logs_2026_03 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE activity_logs_2026_04 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE activity_logs_2026_05 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE activity_logs_2026_06 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE activity_logs_2026_07 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE activity_logs_2026_08 PARTITION OF activity_logs
    FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE activity_logs_default PARTITION OF activity_logs DEFAULT;

CREATE INDEX idx_activity_logs_livestock_time ON activity_logs(livestock_id, recorded_at DESC);

-- ----------------------------------------------------------
-- 2.1.4 estrus_scores — 发情评分快照（非时序，按事件存储）
-- 由分析引擎从 temperature_logs + activity_logs 综合计算
-- ----------------------------------------------------------
CREATE TABLE estrus_scores (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    livestock_id BIGINT NOT NULL,
    score INTEGER NOT NULL CONSTRAINT chk_estrus_score CHECK (score BETWEEN 0 AND 100),
    step_increase_percent INTEGER,         -- 步数增幅 (%)
    temp_delta DECIMAL(5,2),               -- 温度偏差
    distance_delta DECIMAL(5,2),           -- 位移偏差
    advice TEXT,                           -- AI 建议
    scored_at TIMESTAMP NOT NULL,          -- 评分时间点
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_estrus_farm_time ON estrus_scores(farm_id, scored_at DESC);
CREATE INDEX idx_estrus_livestock_time ON estrus_scores(livestock_id, scored_at DESC);
CREATE INDEX idx_estrus_high_score ON estrus_scores(score) WHERE score >= 70;

-- ----------------------------------------------------------
-- 2.1.5 health_snapshots — 健康快照（每头牲畜当前健康状态聚合）
-- 由定时任务刷新，避免实时聚合查询时序表
-- ----------------------------------------------------------
CREATE TABLE health_snapshots (
    id BIGSERIAL PRIMARY KEY,
    livestock_id BIGINT NOT NULL UNIQUE,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    baseline_temp DECIMAL(5,2) NOT NULL DEFAULT 38.50,
    current_temp DECIMAL(5,2),
    temp_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CONSTRAINT chk_temp_status CHECK (temp_status IN ('NORMAL', 'ELEVATED', 'FEVER', 'CRITICAL')),
    motility_baseline DECIMAL(5,2) DEFAULT 3.0,
    current_motility DECIMAL(5,2),
    motility_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CONSTRAINT chk_motility_status CHECK (motility_status IN ('NORMAL', 'LOW', 'ABNORMAL')),
    estrus_score INTEGER DEFAULT 0,
    activity_status VARCHAR(20) NOT NULL DEFAULT 'NORMAL'
        CONSTRAINT chk_activity_status CHECK (activity_status IN ('NORMAL', 'ELEVATED', 'LOW', 'ABNORMAL')),
    last_assessed_at TIMESTAMP,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_health_snap_farm ON health_snapshots(farm_id);
CREATE INDEX idx_health_snap_temp_status ON health_snapshots(temp_status);
CREATE INDEX idx_health_snap_motility_status ON health_snapshots(motility_status);

-- ----------------------------------------------------------
-- 2.1.6 contact_traces — 接触追踪记录
-- 基于 GPS 轨迹计算牲畜间的近距离接触
-- ----------------------------------------------------------
CREATE TABLE contact_traces (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL REFERENCES farms(id),
    from_livestock_id BIGINT NOT NULL,
    to_livestock_id BIGINT NOT NULL,
    proximity_meters DECIMAL(6,2) NOT NULL, -- 最近距离（米）
    contact_duration_minutes INTEGER NOT NULL DEFAULT 0,
    last_contact_at TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_contact_farm_time ON contact_traces(farm_id, last_contact_at DESC);
CREATE INDEX idx_contact_from ON contact_traces(from_livestock_id);
CREATE INDEX idx_contact_to ON contact_traces(to_livestock_id);
```

### 2.2 表设计说明

| 表 | 类型 | 数据量估算 | 分区策略 | 说明 |
|----|------|-----------|---------|------|
| `temperature_logs` | 时序 | ~17K/天（12胶囊×48采样） | 按月 RANGE | 瘤胃温度，核心数据 |
| `rumen_motility_logs` | 时序 | ~17K/天 | 按月 RANGE | 蠕动频率+强度 |
| `activity_logs` | 时序 | ~800/天（~32设备×24采样） | 按月 RANGE | 步数+活动指数+位移 |
| `estrus_scores` | 事件 | ~12/天（每胶囊牲畜1条） | 无 | 发情评分快照 |
| `health_snapshots` | 快照 | ~60条（每牲畜1条） | 无 | 当前健康状态聚合 |
| `contact_traces` | 事件 | ~数百/天 | 无 | 近距离接触对 |

**分区维护策略**：应用启动时检查并自动创建未来月份分区（HealthPartitionMaintenanceJob），保留 6 个月滚动窗口。

### 2.3 与现有数据的关系

```
temperature_logs.livestock_id  →  livestock.id (V9 seed, 无 FK)
temperature_logs.device_id     →  devices.id (V10 seed, 无 FK)
    ↳ 仅关联 CAPSULE 类型设备的 installations

rumen_motility_logs.livestock_id → livestock.id
rumen_motility_logs.device_id    → devices.id (CAPSULE)

activity_logs.livestock_id      → livestock.id
activity_logs.device_id         → devices.id (TRACKER / ACCELEROMETER)

estrus_scores.farm_id           → farms.id (FK)
estrus_scores.livestock_id      → livestock.id (无 FK)

health_snapshots.livestock_id   → livestock.id (UNIQUE, 无 FK)
health_snapshots.farm_id        → farms.id (FK)

contact_traces.farm_id          → farms.id (FK)
contact_traces.from/to_livestock_id → livestock.id (无 FK)
```

---

## 3. 种子数据设计

### 3.1 V21 迁移 — Health 种子数据

种子数据围绕已安装设备的牲畜生成：

- **12 头安装了胶囊的牲畜**：4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 48 → 生成温度 + 蠕动数据
- **32 头安装了 GPS 的牲畜**：生成活动量数据
- **健康快照**：为所有 50 头牲畜生成快照
- **发情评分**：为部分母牛生成评分
- **接触追踪**：基于同围栏牲畜生成

#### 3.1.1 种子数据策略

**时间范围**: 2026-03-01 ~ 2026-04-08（约 38 天）

**温度数据（12 头胶囊牲畜）**:
- 每头每 30 分钟 1 条 → 每天 48 条 → 38 天 × 12 头 ≈ 21,888 条
- 正常温度范围: 38.0~39.2°C，baseline 38.5°C
- 异常个体:
  - SL-2024-004 (livestock 4): 正常
  - SL-2024-008 (livestock 8): 正常
  - SL-2024-012 (livestock 12): 4月6日起持续高温 40.0~40.8°C
  - SL-2024-016 (livestock 16): 正常
  - SL-2024-020 (livestock 20): 正常
  - SL-2024-024 (livestock 24): 偶发低温 37.2°C（消化问题）
  - SL-2024-028 (livestock 28): 正常
  - SL-2024-032 (livestock 32): 正常
  - SL-2024-036 (livestock 36): 正常
  - SL-2024-040 (livestock 40): 正常
  - SL-2024-044 (livestock 44): 正常
  - SL-2024-048 (livestock 48): 隔离区，持续高温 40.5°C（严重）

**蠕动数据（12 头胶囊牲畜）**:
- 与温度同期，频率 1.5~4.5 次/分（正常），低于 1.5 为异常
- SL-2024-024: 4月5日起蠕动频率下降至 0.8~1.2

**活动量数据（32 头 GPS 牲畜）**:
- 每头每 1 小时 1 条 → 每天 24 条 → 38 天 × 32 头 ≈ 29,184 条
- 正常步数: 白天 800~2500/h，夜间 50~300/h
- 发情个体:
  - SL-2024-016 (母牛): 4月7日活动量暴增 300%
  - SL-2024-032 (母牛): 4月6日活动量暴增 250%

**发情评分**:
- SL-2024-016: 4月7日 score=92, 建议配种
- SL-2024-032: 4月6日 score=78, 观察中

**健康快照（50 头）**:
- 大部分 NORMAL
- SL-2024-012: temp_status=FEVER
- SL-2024-048: temp_status=CRITICAL
- SL-2024-024: motility_status=ABNORMAL
- SL-2024-003: health_status WARNING（已存在）
- SL-2024-017: health_status CRITICAL（已存在）

**接触追踪**:
- 同围栏内牲畜的近距离接触记录

### 3.2 V20 SQL 骨架

```sql
-- ============================================================
-- V21: Seed Health data — temperature, motility, activity, estrus, snapshots
-- References: livestock from V9, devices/installations from V10
-- ============================================================

-- Helper: 胶囊牲畜 ID 列表 (4,8,12,16,20,24,28,32,36,40,44,48)
-- 胶囊设备 ID: 51-62 (对应 livestock 4,8,12,...,48)

-- 1. temperature_logs: 为 12 头胶囊牲畜生成 38 天数据
-- 使用 generate_series + 随机噪声，特定个体注入异常
-- 总行数: ~21,888

-- 2. rumen_motility_logs: 同上 12 头，同期数据
-- 总行数: ~21,888

-- 3. activity_logs: 为 32 头 GPS 牲畜生成 38 天数据
-- 总行数: ~29,184

-- 4. estrus_scores: 2 条高评分记录
-- 总行数: 2

-- 5. health_snapshots: 50 条（每头牲畜）
-- 总行数: 50

-- 6. contact_traces: 同围栏内随机生成 ~30 条
-- 总行数: ~30
```

> 完整 SQL 将在实施阶段生成（数据量大，需要 PL/pgSQL 批量生成）。

---

## 4. 领域模型设计

### 4.1 包结构

```
com.smartlivestock.health/
├── domain/
│   ├── model/
│   │   ├── TemperatureLog.java
│   │   ├── RumenMotilityLog.java
│   │   ├── ActivityLog.java
│   │   ├── EstrusScore.java
│   │   ├── HealthSnapshot.java
│   │   ├── ContactTrace.java
│   │   ├── TemperatureBaseline.java      (值对象)
│   │   ├── MotilityBaseline.java         (值对象)
│   │   └── HealthStatus.java             (枚举)
│   ├── repository/
│   │   └── port/
│   │       ├── TemperatureLogRepository.java
│   │       ├── RumenMotilityLogRepository.java
│   │       ├── ActivityLogRepository.java
│   │       ├── EstrusScoreRepository.java
│   │       ├── HealthSnapshotRepository.java
│   │       └── ContactTraceRepository.java
│   └── service/
│       ├── FeverAnalysisService.java
│       ├── DigestiveAnalysisService.java
│       ├── EstrusAnalysisService.java
│       └── EpidemicAnalysisService.java
├── application/
│   ├── dto/
│   │   ├── TemperatureReadingDTO.java
│   │   ├── TemperatureBaselineDTO.java
│   │   ├── MotilityReadingDTO.java
│   │   ├── DigestiveHealthDTO.java
│   │   ├── EstrusScoreDTO.java
│   │   ├── HerdHealthMetricsDTO.java
│   │   ├── ContactTraceDTO.java
│   │   ├── HealthSnapshotDTO.java
│   │   ├── FeverListResponse.java
│   │   ├── DigestiveListResponse.java
│   │   ├── EstrusListResponse.java
│   │   └── EpidemicResponse.java
│   ├── service/
│   │   └── HealthApplicationService.java
│   ├── query/
│   │   └── HealthQueryService.java
│   └── job/
│       ├── HealthSnapshotRefreshJob.java
│       └── PartitionMaintenanceJob.java
├── infrastructure/
│   └── persistence/
│       ├── entity/
│       │   ├── TemperatureLogEntity.java
│       │   ├── RumenMotilityLogEntity.java
│       │   ├── ActivityLogEntity.java
│       │   ├── EstrusScoreEntity.java
│       │   ├── HealthSnapshotEntity.java
│       │   └── ContactTraceEntity.java
│       ├── mapper/
│       │   ├── TemperatureLogEntityMapper.java
│       │   ├── RumenMotilityLogEntityMapper.java
│       │   ├── ActivityLogEntityMapper.java
│       │   ├── EstrusScoreEntityMapper.java
│       │   ├── HealthSnapshotEntityMapper.java
│       │   └── ContactTraceEntityMapper.java
│       ├── repository/
│       │   ├── TemperatureLogRepositoryImpl.java
│       │   ├── RumenMotilityLogRepositoryImpl.java
│       │   ├── ActivityLogRepositoryImpl.java
│       │   ├── EstrusScoreRepositoryImpl.java
│       │   ├── HealthSnapshotRepositoryImpl.java
│       │   └── ContactTraceRepositoryImpl.java
│       └── jpa/
│           ├── TemperatureLogJpaRepository.java
│           ├── RumenMotilityLogJpaRepository.java
│           ├── ActivityLogJpaRepository.java
│           ├── EstrusScoreJpaRepository.java
│           ├── HealthSnapshotJpaRepository.java
│           └── ContactTraceJpaRepository.java
└── interfaces/
    └── app/
        ├── HealthController.java          (场景总览)
        ├── FeverController.java           (发热预警)
        ├── DigestiveController.java       (消化管理)
        ├── EstrusController.java          (发情识别)
        └── EpidemicController.java        (疫病防控)
```

### 4.2 领域模型

#### TemperatureLog (聚合根)
```java
@Entity
public class TemperatureLog {
    private Long id;
    private Long livestockId;
    private Long deviceId;
    private BigDecimal temperature;
    private BigDecimal baselineTemp;
    private BigDecimal delta;           // generated column
    private LocalDateTime recordedAt;
}
```

#### EstrusScore (聚合根)
```java
@Entity
public class EstrusScore {
    private Long id;
    private Long farmId;
    private Long livestockId;
    private Integer score;              // 0-100
    private Integer stepIncreasePercent;
    private BigDecimal tempDelta;
    private BigDecimal distanceDelta;
    private String advice;
    private LocalDateTime scoredAt;
}
```

#### HealthSnapshot (聚合根)
```java
@Entity
public class HealthSnapshot {
    private Long id;
    private Long livestockId;           // unique
    private Long farmId;
    private BigDecimal baselineTemp;
    private BigDecimal currentTemp;
    private TempStatus tempStatus;      // NORMAL, ELEVATED, FEVER, CRITICAL
    private BigDecimal motilityBaseline;
    private BigDecimal currentMotility;
    private MotilityStatus motilityStatus; // NORMAL, LOW, ABNORMAL
    private Integer estrusScore;
    private ActivityStatus activityStatus; // NORMAL, ELEVATED, LOW, ABNORMAL
    private LocalDateTime lastAssessedAt;
}
```

### 4.3 分析服务（领域服务）

#### FeverAnalysisService
- **输入**: livestock_id + 时间范围
- **逻辑**: 计算 baseline（近 7 天中位数），检测 delta > 1.0°C 持续 > 2h 的异常
- **输出**: TemperatureBaseline（baselineTemp, threshold, recent72h 时序, status）

#### DigestiveAnalysisService
- **输入**: livestock_id + 时间范围
- **逻辑**: 计算 motility baseline（近 7 天均值），检测频率低于阈值
- **输出**: DigestiveHealth（motilityBaseline, recent24h 时序, status, advice）

#### EstrusAnalysisService
- **输入**: livestock_id 或 farm_id + 日期
- **逻辑**: 多维评分（活动量增幅 40% + 温度微升 0.3°C + 位移增加）
- **输出**: EstrusScore（score 0-100, 各维度指标, advice）

#### EpidemicAnalysisService
- **输入**: farm_id
- **逻辑**: 群体温度聚合（均值/异常率）+ 活动量聚合 + 接触追踪
- **输出**: HerdHealthMetrics + List<ContactTrace>

---

## 5. API 契约

### 5.1 API 端点总览

| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/v1/health/overview` | 健康场景总览 | JWT |
| GET | `/api/v1/health/fever` | 发热预警列表 | JWT |
| GET | `/api/v1/health/fever/{livestockId}` | 个体温度详情（72h 时序） | JWT |
| GET | `/api/v1/health/digestive` | 消化管理列表 | JWT |
| GET | `/api/v1/health/digestive/{livestockId}` | 个体消化详情（24h 时序） | JWT |
| GET | `/api/v1/health/estrus` | 发情识别列表 | JWT |
| GET | `/api/v1/health/estrus/{livestockId}` | 个体发情详情（7d 趋势） | JWT |
| GET | `/api/v1/health/epidemic` | 疫病防控总览 | JWT |

所有接口遵循 Farm Scope（通过 `X-Farm-Id` header 或 activeFarm 上下文）。

### 5.2 请求/响应结构

#### GET /api/v1/health/overview
```json
{
  "code": 200,
  "data": {
    "stats": {
      "totalLivestock": 50,
      "healthyRate": 0.84,
      "alertCount": 5,
      "criticalCount": 2,
      "deviceOnlineRate": 0.92,
      "healthTrend": "稳定",
      "livestockTrend": "↑2"
    },
    "sceneSummary": {
      "fever": { "abnormalCount": 3, "criticalCount": 2 },
      "digestive": { "abnormalCount": 1, "watchCount": 2 },
      "estrus": { "highScoreCount": 2, "breedingAdvice": true },
      "epidemic": { "status": "正常", "abnormalRate": 0.06 }
    },
    "pendingTasks": [
      {
        "id": "task-1",
        "title": "SL-2024-048 体温危急",
        "subtitle": "体温 40.5°C，持续 48 小时",
        "routePath": "/twin/fever/48",
        "severity": "CRITICAL"
      }
    ]
  }
}
```

#### GET /api/v1/health/fever
```json
{
  "code": 200,
  "data": {
    "items": [
      {
        "livestockId": "12",
        "livestockCode": "SL-2024-012",
        "breed": "西门塔尔牛",
        "baselineTemp": 38.50,
        "currentTemp": 40.20,
        "delta": 1.70,
        "status": "FEVER",
        "conclusion": "体温持续偏高超过 48 小时，建议隔离观察"
      }
    ]
  }
}
```

#### GET /api/v1/health/fever/{livestockId}
```json
{
  "code": 200,
  "data": {
    "livestockId": "12",
    "livestockCode": "SL-2024-012",
    "baselineTemp": 38.50,
    "threshold": 39.50,
    "status": "FEVER",
    "conclusion": "体温持续偏高超过 48 小时，建议隔离观察",
    "recent72h": [
      { "temperature": 38.60, "timestamp": "2026-04-06T00:00:00" },
      { "temperature": 38.55, "timestamp": "2026-04-06T00:30:00" },
      { "temperature": 40.10, "timestamp": "2026-04-06T08:00:00" }
    ]
  }
}
```

#### GET /api/v1/health/digestive
```json
{
  "code": 200,
  "data": {
    "items": [
      {
        "livestockId": "24",
        "livestockCode": "SL-2024-024",
        "breed": "安格斯牛",
        "motilityBaseline": 3.20,
        "currentFrequency": 1.10,
        "status": "ABNORMAL",
        "advice": "蠕动频率显著偏低，建议检查饲料质量和饮水量"
      }
    ]
  }
}
```

#### GET /api/v1/health/digestive/{livestockId}
```json
{
  "code": 200,
  "data": {
    "livestockId": "24",
    "livestockCode": "SL-2024-024",
    "motilityBaseline": 3.20,
    "status": "ABNORMAL",
    "advice": "蠕动频率显著偏低，建议检查饲料质量和饮水量",
    "recent24h": [
      { "frequency": 1.20, "intensity": 35.0, "timestamp": "2026-04-08T00:00:00" },
      { "frequency": 1.10, "intensity": 32.0, "timestamp": "2026-04-08T00:30:00" }
    ]
  }
}
```

#### GET /api/v1/health/estrus
```json
{
  "code": 200,
  "data": {
    "items": [
      {
        "livestockId": "16",
        "livestockCode": "SL-2024-016",
        "breed": "西门塔尔牛",
        "gender": "FEMALE",
        "score": 92,
        "stepIncreasePercent": 310,
        "tempDelta": 0.35,
        "distanceDelta": 2800.0,
        "timestamp": "2026-04-07T14:00:00",
        "advice": "发情评分较高，建议 12 小时内安排配种"
      }
    ]
  }
}
```

#### GET /api/v1/health/estrus/{livestockId}
```json
{
  "code": 200,
  "data": {
    "livestockId": "16",
    "livestockCode": "SL-2024-016",
    "score": 92,
    "stepIncreasePercent": 310,
    "tempDelta": 0.35,
    "distanceDelta": 2800.0,
    "timestamp": "2026-04-07T14:00:00",
    "advice": "发情评分较高，建议 12 小时内安排配种",
    "trend7d": [
      { "score": 12, "timestamp": "2026-04-01T14:00:00" },
      { "score": 15, "timestamp": "2026-04-02T14:00:00" },
      { "score": 85, "timestamp": "2026-04-07T14:00:00" }
    ]
  }
}
```

#### GET /api/v1/health/epidemic
```json
{
  "code": 200,
  "data": {
    "metrics": {
      "avgTemperature": 38.82,
      "avgActivity": 1250.0,
      "abnormalRate": 0.06,
      "totalLivestock": 50,
      "abnormalCount": 3
    },
    "contacts": [
      {
        "fromId": "48",
        "fromCode": "SL-2024-048",
        "toId": "49",
        "toCode": "SL-2024-049",
        "proximity": 5.2,
        "lastContact": "2026-04-08T10:30:00"
      }
    ]
  }
}
```

### 5.3 Farm Scope 规则

- 所有 `/api/v1/health/**` 端点受 Farm Scope 约束
- `farm_id` 从 JWT 上下文中的 activeFarm 获取
- livestock 查询自动限定 `WHERE farm_id = ?`
- 管理端接口（后续可扩展 `/api/v1/admin/health/**`）

---

## 6. 前端页面设计

### 6.1 页面结构

```
/twin (数智孪生总览)
├── /twin/fever (发热预警列表)         → FeverWarningPage
│   └── /twin/fever/:livestockId (详情) → FeverDetailPage
├── /twin/digestive (消化管理列表)      → DigestivePage
│   └── /twin/digestive/:livestockId    → DigestiveDetailPage
├── /twin/estrus (发情识别列表)         → EstrusPage
│   └── /twin/estrus/:livestockId       → EstrusDetailPage
└── /twin/epidemic (疫病防控总览)       → EpidemicPage
```

路由已存在于 `app_route.dart`，页面文件已存在于 `features/pages/`（当前为 ComingSoon 占位）。

### 6.2 页面设计

#### 6.2.1 FeverWarningPage — 发热预警列表

**布局**: 顶部统计卡片 + 异常牲畜列表

```
┌──────────────────────────────┐
│  🌡️ 发热预警                    │
├──────────────────────────────┤
│  [异常 3头]  [危急 2头]  [正常 45头] │  ← 统计卡片行
├──────────────────────────────┤
│  🔴 SL-2024-048  40.5°C ▲+2.0   │  ← 按严重度排序
│     西门塔尔牛 · 隔离区 · 持续48h    │
│  ──────────────────────────── │
│  🔴 SL-2024-012  40.2°C ▲+1.7   │
│     西门塔尔牛 · 放牧A区 · 持续12h   │
│  ──────────────────────────── │
│  🟡 SL-2024-003  39.6°C ▲+1.1   │
│     西门塔尔牛 · 放牧A区 · 偶发      │
│  ──────────────────────────── │
│  ... 查看全部 (链接)              │
└──────────────────────────────┘
```

点击任一牲畜 → FeverDetailPage

#### 6.2.2 FeverDetailPage — 个体温度详情

**布局**: 基线信息卡 + 72h 温度曲线 + 异常判定

```
┌──────────────────────────────┐
│  ← SL-2024-048               │
├──────────────────────────────┤
│  当前温度    基线温度    偏差     │
│  40.5°C     38.5°C    +2.0°C  │  ← 数值卡片行
│  状态: 🔴 危急                   │
├──────────────────────────────┤
│  📈 72小时温度曲线               │
│  41°C ┤          ╭──╮          │
│  40°C ┤    ╭────╯  ╰──        │
│  39°C ┤───╯                     │
│  38°C ┤                        │
│       └───────────────────     │
│       4/5  4/6  4/7  4/8       │
├──────────────────────────────┤
│  📋 分析结论                    │
│  体温持续偏高超过 48 小时，       │
│  建议隔离观察并联系兽医。         │
└──────────────────────────────┘
```

温度曲线使用 fl_chart（项目已有依赖）。

#### 6.2.3 DigestivePage — 消化管理列表

```
┌──────────────────────────────┐
│  🍽️ 消化管理                    │
├──────────────────────────────┤
│  [异常 1头]  [观察 2头]  [正常 9头] │
├──────────────────────────────┤
│  🔴 SL-2024-024  蠕动 1.1次/分    │
│     安格斯牛 · 放牧A区 · ↓66%     │
│  ──────────────────────────── │
│  🟡 SL-2024-008  蠕动 2.0次/分    │
│     西门塔尔牛 · 放牧A区 · ↓25%    │
│  ...                           │
└──────────────────────────────┘
```

#### 6.2.4 DigestiveDetailPage — 个体消化详情

```
┌──────────────────────────────┐
│  ← SL-2024-024               │
├──────────────────────────────┤
│  当前频率    基线频率    状态     │
│  1.1次/分   3.2次/分   异常     │
├──────────────────────────────┤
│  📈 24小时蠕动曲线               │
│  5次 ┤                        │
│  3次 ┤ ─ ─ ─ ─ ─ (基线)       │
│  1次 ┤  ╭──╮                   │
│       └───────────────────     │
├──────────────────────────────┤
│  📋 建议                       │
│  蠕动频率显著偏低，建议检查       │
│  饲料质量和饮水量。              │
└──────────────────────────────┘
```

#### 6.2.5 EstrusPage — 发情识别列表

```
┌──────────────────────────────┐
│  💕 发情识别                    │
├──────────────────────────────┤
│  [高评分 2头]  [建议配种 ✓]       │
├──────────────────────────────┤
│  🟢 SL-2024-016  评分 92         │
│     西门塔尔牛 · ♀ · 步数+310%   │
│     💡 建议 12h 内配种            │
│  ──────────────────────────── │
│  🟡 SL-2024-032  评分 78         │
│     安格斯牛 · ♀ · 步数+250%     │
│     持续观察中                    │
│  ──────────────────────────── │
│  灰 SL-2024-004  评分 12         │
│     西门塔尔牛 · ♀ · 正常         │
│  ...                           │
└──────────────────────────────┘
```

仅显示母牛（gender=FEMALE）。

#### 6.2.6 EstrusDetailPage — 个体发情详情

```
┌──────────────────────────────┐
│  ← SL-2024-016               │
├──────────────────────────────┤
│  评分   步数增幅   温差   位移   │
│   92    +310%   +0.35  2.8km │
├──────────────────────────────┤
│  📈 7天评分趋势                 │
│  100 ┤              ╭─         │
│   80 ┤           ╭──╯          │
│   60 ┤        ╭──╯             │
│   20 ┤ ── ── ╯                  │
│       └───────────────────     │
│       4/1  4/3  4/5  4/7       │
├──────────────────────────────┤
│  💡 建议 12 小时内安排配种       │
└──────────────────────────────┘
```

#### 6.2.7 EpidemicPage — 疫病防控总览

```
┌──────────────────────────────┐
│  🛡️ 疫病防控                    │
├──────────────────────────────┤
│  群体健康指标                    │
│  ┌─────────┬─────────┬─────┐ │
│  │ 平均体温 │ 异常率   │ 异常数│ │
│  │ 38.82°C │  6.0%   │  3头 │ │
│  └─────────┴─────────┴─────┘ │
├──────────────────────────────┤
│  📍 接触追踪                    │
│  SL-2024-048 ↔ SL-2024-049    │
│     5.2m · 4月8日 10:30        │
│  SL-2024-048 ↔ SL-2024-050    │
│     8.1m · 4月8日 09:15        │
│  ...                           │
├──────────────────────────────┤
│  ⚠️ 风险提示                    │
│  隔离区有 2 头体温异常，接触      │
│  牲畜建议加测体温。              │
└──────────────────────────────┘
```

### 6.3 前端数据层改造

现有 Repository 接口从同步 `load()` 改为异步 API 调用：

```dart
// 改造前 (fever_repository.dart)
abstract class FeverRepository {
  FeverViewData load([ViewState desiredState = ViewState.normal]);
}

// 改造后
abstract class FeverRepository {
  Future<FeverListResponse> fetchFeverList(String farmId);
  Future<FeverDetailResponse> fetchFeverDetail(String farmId, String livestockId);
}
```

新增 `data/live/` 实现，通过 ApiClient 调用后端 `/api/v1/health/fever` 等端点。

---

## 7. 分析引擎规则

### 7.1 发热检测规则

| 条件 | temp_status | 说明 |
|------|-------------|------|
| delta < 1.0°C | NORMAL | 正常波动 |
| 1.0 ≤ delta < 1.5°C，持续 < 2h | ELEVATED | 轻微升高，观察 |
| delta ≥ 1.5°C 或持续 > 2h | FEVER | 发热，需关注 |
| delta ≥ 2.0°C 或 temp ≥ 41.0°C | CRITICAL | 危急，立即处理 |

### 7.2 消化异常规则

| 条件 | motility_status | 说明 |
|------|-----------------|------|
| frequency ≥ baseline × 0.7 | NORMAL | 正常 |
| baseline × 0.5 ≤ frequency < baseline × 0.7 | LOW | 偏低，观察 |
| frequency < baseline × 0.5 | ABNORMAL | 异常，需干预 |

### 7.3 发情评分规则

```
score = (step_score × 0.4) + (temp_score × 0.3) + (distance_score × 0.3)

step_score:
  步数增幅 < 50%  → 0~20
  50%~150%       → 20~60
  150%~300%      → 60~85
  > 300%         → 85~100

temp_score:
  delta < 0.2°C  → 0~10
  0.2~0.5°C     → 10~40
  > 0.5°C        → 40~60

distance_score:
  位移增量 < 500m  → 0~15
  500~2000m      → 15~50
  > 2000m        → 50~70
```

- score ≥ 70: 高概率发情，建议配种
- score 50~69: 可疑，继续观察
- score < 50: 未发情

### 7.4 疫病风险评估

```
群体异常率 = 异常牲畜数 / 总牲畜数
- < 5%: 正常
- 5%~15%: 关注
- > 15%: 警戒

接触追踪: GPS 轨迹中距离 < 10m 且持续时间 > 30min 的配对
```

---

## 8. 与前端 twin_models.dart 的映射

| 后端 DTO | 前端 Model | 映射关系 |
|----------|-----------|---------|
| FeverListResponse.items[] | List\<TemperatureBaseline\> | livestockId, baselineTemp, currentTemp(计算), delta, status, conclusion |
| FeverDetailResponse | TemperatureBaseline | + recent72h → List\<TemperatureRecord\> |
| DigestiveListResponse.items[] | List\<DigestiveHealth\> | livestockId, motilityBaseline, currentFrequency(计算), status, advice |
| DigestiveDetailResponse | DigestiveHealth | + recent24h → List\<MotilityRecord\> |
| EstrusListResponse.items[] | List\<EstrusScore\> | livestockId, score, stepIncreasePercent, tempDelta, distanceDelta, timestamp, advice |
| EstrusDetailResponse | EstrusScore | + trend7d → List\<EstrusTrendPoint\> |
| EpidemicResponse.metrics | HerdHealthMetrics | avgTemperature, avgActivity, abnormalRate, totalLivestock, abnormalCount |
| EpidemicResponse.contacts[] | List\<ContactTrace\> | fromId, toId, proximity, lastContact |

---

## 9. 非功能性要求

- **性能**: 72h 温度查询（~144 条）响应时间 < 200ms
- **数据保留**: 时序数据保留 12 个月，超出自动归档
- **分区维护**: 启动时自动创建未来 3 个月分区
- **Farm 隔离**: 所有查询强制 `WHERE farm_id = ?`
- **功能门控**: 发热预警/消化管理 — standard 及以上；发情识别/疫病防控 — premium 及以上

---

## 10. 实施分阶段

| 阶段 | 内容 | 依赖 |
|------|------|------|
| Task 1 | V21 迁移（6 张表 + 分区） | 无 |
| Task 2 | V20 种子数据（~73K 行时序） | Task 1 |
| Task 3 | Domain 层（6 Entity + 6 Repository port） | Task 1 |
| Task 4 | Infrastructure 层（JPA + Mapper + Repository impl） | Task 3 |
| Task 5 | Application 层（DTO + QueryService + AnalysisService） | Task 3, 4 |
| Task 6 | Interface 层（5 Controller） | Task 5 |
| Task 7 | API 契约测试（curl 脚本） | Task 6 |
| Task 8 | 前端 Repository 改造（同步→异步） | Task 7 |
| Task 9 | 前端 4 列表页 + 3 详情页实现 | Task 8 |
| Task 10 | 集成测试 + E2E 验证 | Task 9 |

