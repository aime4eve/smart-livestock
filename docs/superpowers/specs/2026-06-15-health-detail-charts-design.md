# 健康详情页订阅分级图表明细 — 设计规格

> 版本: 1.0 | 日期: 2026-06-15 | 状态: 待评审

## 1. 概述

在每只牲畜的健康数据详情展示页（发热 / 消化 / 发情 / 疫情接触追踪），按订阅服务等级（Tier）动态展示对应的明细图表。低等级用户看到图表区域被 `LockedOverlay` 遮罩并提示升级，高等级用户解锁更多图表和更深的数据时间窗口。

**门控策略：前后端双重**
- **后端**：Health API 注入 `SubscriptionQueryService`，按 Tier 的 `dataRetentionDays`（filter gate）截断时序数据深度，按 featureKey（lock gate）决定是否返回高级分析数据。防止越权获取。
- **前端**：Flutter 详情页读取 `subscriptionControllerProvider` 的 Tier + `FeatureFlags`，决定渲染哪些图表 / 是否套 `LockedOverlay`。

**交互原型**：`docs/mockups/health-detail-charts.html`（可切换 Basic/Standard/Premium/Enterprise 实时预览）

---

## 2. 订阅分级方案

### 2.1 Feature Gate 定义（前端 `FeatureFlags` 已有，后端需新增种子数据）

| Feature Key | Basic | Standard | Premium | Enterprise | 门控类型 | 说明 |
|---|---|---|---|---|---|---|
| `temperature_monitor` | ✅ | ✅ | ✅ | ✅ | none | 发热基础体温曲线（所有 Tier） |
| `peristaltic_monitor` | ✅ | ✅ | ✅ | ✅ | none | 消化基础蠕动曲线（所有 Tier） |
| `health_score` | ❌ | ✅ | ✅ | ✅ | lock | 发热持续时长分析 + 蠕动强度热力图（Standard+） |
| `estrus_detect` | ❌ | ❌ | ✅ | ✅ | lock | 发情评分趋势 + 活动量对比（Premium+） |
| `epidemic_alert` | ❌ | ❌ | ✅ | ✅ | lock | 疫情接触追踪（Premium+） |
| `data_retention_days` | 7 | 30 | 365 | 1095 | filter | 时序数据保留天数，决定图表 X 轴范围 |

> **注意**：当前后端 `feature_gates` 种子数据（V6）使用的是粗粒度 `health_monitoring` key。需新增 V31 迁移，为健康模块拆分出上述细粒度 feature key。

### 2.2 各详情页图表明细

**🌡️ 发热监测详情**（`FeverDetailPage`）
| 图表 | 数据源 | 最低 Tier | 说明 |
|------|--------|-----------|------|
| 体温趋势曲线 | `recent72h` (TemperatureReading[]) | Basic | X 轴范围 = `dataRetentionDays`；基线虚线参考 |
| 发热持续时长柱状图 | 新增 `dailyFeverHours` (DailyFeverHour[]) | Standard | 每日超阈值持续小时数，7 日柱状图 |

**🫃 消化健康详情**（`DigestiveDetailPage`）
| 图表 | 数据源 | 最低 Tier | 说明 |
|------|--------|-----------|------|
| 瘤胃蠕动频率曲线 | `recent24h` (MotilityReading[]) | Basic | X 轴范围 = `dataRetentionDays`；基线虚线参考 |
| 24h 蠕动强度热力图 | 新增 `intensityHeatmap` (IntensityCell[]) | Standard | 24 小时 × 强度色块网格 |

**💕 发情检测详情**（`EstrusDetailPage`）
| 图表 | 数据源 | 最低 Tier | 说明 |
|------|--------|-----------|------|
| 7日发情评分趋势 | `trend7d` (EstrusTrendPoint[]) | Premium | 0-100 评分曲线 + 配种阈值线 |
| 活动量对比柱状图 | 新增 `activityComparison` (ActivityComparisonData) | Premium | 近 3 日 vs 基线（步数/距离/活跃指数） |

**🦠 疫情接触追踪详情**（新增 `EpidemicContactPage`）
| 图表/区块 | 数据源 | 最低 Tier | 说明 |
|-----------|--------|-----------|------|
| 染病牲畜标记 | 新增 `POST /health/epidemic/mark` | Premium | 标记某牲畜为染病源 |
| 接触链拓扑图 | 新增 `contactNetwork` (ContactNode[]) | Premium | GPS 轨迹交叉分析网络图 |
| 密切接触者明细 | 新增 `contactsByWindow` | Premium | 按 24h/48h/72h 分组 + 三维风险评分 |

### 2.3 接触风险三维评分模型

```
风险总分 = 时间衰减分(满分40) + 接触距离分(满分35) + 持续时长分(满分25)
```

| 维度 | 满分 | 计分区间 |
|------|------|---------|
| **时间衰减** | 40 | ≤24h=40, 24-48h=25, 48-72h=12 |
| **接触距离** | 35 | <5m=35, 5-15m=25, 15-30m=15, >30m=5 |
| **持续时长** | 25 | >30min=25, 15-30min=18, 5-15min=10, <5min=3 |

**风险分级**：≥70 高风险（红）/ 40–69 中风险（黄）/ <40 低风险（绿）

时间窗口（24h/48h/72h）仅作为 UI 分组展示用；风险等级由三维评分独立计算。

---

## 3. 后端实现

### 3.1 种子数据现状与问题

**核心问题：现有种子数据时间戳已过期**

当前 `temperature_logs`、`activity_logs`、`estrus_scores`、`gps_logs` 的种子数据时间戳固定在 `2026-03-01 ~ 2026-04-08`（V21/V10 种子），距今（2026-06-15）已超过 2 个月。详情页查询使用 `now() - 72h` / `now() - 24h` 时间窗口，导致**图表数据为空**。

| 数据表 | 种子来源 | 种子时间 | 查询窗口 | 当前结果 |
|--------|---------|---------|---------|---------|
| `temperature_logs` | V21 | `2026-03-01 ~ 04-08` | `now() - 72h` | ❌ 空 |
| `rumen_motility_logs`（V21 主体） | V21 | `2026-03-01 ~ 04-08` | `now() - 24h` | ❌ 空 |
| `rumen_motility_logs`（V27 补丁） | V27 | `now() - 24h` | `now() - 24h` | ✅ 仅 SL-024/SL-036 |
| `activity_logs` | V21 | `2026-03-01 ~ 04-08` | `now() - 72h` | ❌ 空 |
| `estrus_scores` | V21 | `2026-04-06 ~ 04-08` | 最新优先 | ❌ 过期 |
| `gps_logs` | V10 | `last_position_at - 24h` = `04-07~08` | `now() - 72h` | ❌ 空 |
| `contact_traces` | V21 | `2026-04-08` | 无时间过滤 | ⚠️ 有数据但过期 |

**分区状态**：`temperature_logs` / `rumen_motility_logs` / `activity_logs` 分区表已覆盖 `2026-03 ~ 2026-08`（含 `default` 兜底），`now()` 数据会落入 `2026_06` 分区，无需新增分区。

### 3.2 V31 迁移 — 刷新近期时序种子数据

**目标**：为 demo 牲畜插入相对于 `now()` 的近期（72h 内 + 7d 内）时序数据，确保所有图表有数据可渲染。

**涉及牲畜**（复用已有 demo 数据角色）：

| 牲畜 | 场景 | 设备 ID | 种子行为 |
|------|------|---------|---------|
| SL-2024-048 | 发热 CRITICAL (40.5°C) | 62 (capsule) | 72h 温度日志，持续高温 40-41°C |
| SL-2024-012 | 发热 FEVER (40.2°C) | 53 (capsule) | 72h 温度日志，温度 39.5-40.5°C |
| SL-2024-024 | 消化 ABNORMAL | 56 (capsule) | V27 已有 24h 数据，补充 72h 强度热力图数据 |
| SL-2024-036 | 消化 LOW | 59 (capsule) | V27 已有 24h 数据，补充 72h |
| SL-2024-016 | 发情 score 92 | tracker+capsule | 7d 活动量日志 + estrus_scores 刷新时间 |
| SL-2024-032 | 发情 score 78 | tracker+capsule | 7d 活动量日志 + estrus_scores 刷新时间 |
| SL-2024-048 | 疫情染病源 | tracker | 标记染病 + 72h GPS 轨迹 + 接触链数据 |

```sql
-- ============================================================
-- V31: 刷新健康模块近期种子数据 + 细粒度 feature gate + 接触链扩展
-- ============================================================

-- ----------------------------------------------------------
-- Part 1: temperature_logs — 刷新异常牲畜近 72h 温度（now() 相对）
-- ----------------------------------------------------------
INSERT INTO temperature_logs (livestock_id, device_id, temperature, baseline_temp, recorded_at)
SELECT
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048' AND farm_id = 1),
    62,
    40.0 + random() * 1.0,  -- CRITICAL: 40.0-41.0°C
    38.50,
    ts
FROM (
    SELECT generate_series(now() - interval '72 hours', now(), '30 minutes'::interval) AS ts
) sub
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-048');

-- 同理为 SL-2024-012 插入 FEVER 级温度（39.5-40.5°C）
-- 同理为 SL-2024-003, SL-2024-017 插入 ELEVATED 级温度（38.8-39.6°C）
-- （完整 SQL 见实施阶段）

-- ----------------------------------------------------------
-- Part 2: rumen_motility_logs — 补充 72h 强度热力图所需数据
-- SL-2024-024 已有 V27 的 24h 数据，这里扩展到 72h + 确保每小时有 intensity 值
-- ----------------------------------------------------------
INSERT INTO rumen_motility_logs (livestock_id, device_id, frequency, intensity, recorded_at)
SELECT
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-024' AND farm_id = 1),
    56,
    0.8 + random() * 0.6,     -- 异常低频
    25.0 + random() * 15.0,   -- 异常低强度
    ts
FROM (
    SELECT generate_series(now() - interval '72 hours', now() - interval '24 hours', '30 minutes'::interval) AS ts
) sub
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-024');

-- ----------------------------------------------------------
-- Part 3: activity_logs — 刷新发情牲畜近 7d 活动量
-- ----------------------------------------------------------
INSERT INTO activity_logs (livestock_id, device_id, step_count, activity_index, distance_meters, recorded_at)
SELECT
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-016' AND farm_id = 1),
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls ON ls.id = inst.livestock_id
     WHERE ls.livestock_code = 'SL-2024-016' AND inst.removed_at IS NULL LIMIT 1),
    CASE
        WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 2500 + (random() * 1500)::int  -- 发情期高活动
        ELSE 100 + (random() * 300)::int
    END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 70.0 + random() * 30.0 ELSE 10.0 + random() * 20.0 END,
    CASE WHEN EXTRACT(HOUR FROM ts) BETWEEN 6 AND 20 THEN 1500.0 + random() * 1000.0 ELSE 20.0 + random() * 50.0 END,
    ts
FROM (
    SELECT generate_series(now() - interval '7 days', now(), '1 hour'::interval) AS ts
) sub
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-016');

-- ----------------------------------------------------------
-- Part 4: estrus_scores — 刷新发情评分时间到 now()
-- ----------------------------------------------------------
UPDATE estrus_scores SET scored_at = now()
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-016' AND farm_id = 1)
  AND score >= 90;

UPDATE estrus_scores SET scored_at = now() - interval '6 hours'
WHERE livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-032' AND farm_id = 1)
  AND score >= 70;

-- 为发情趋势补充 7 日历史评分
INSERT INTO estrus_scores (farm_id, livestock_id, score, step_increase_percent, temp_delta, distance_delta, scored_at)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-016' AND farm_id = 1),
    30 + (random() * 30)::int,
    (random() * 50)::int,
    random() * 0.2,
    random() * 100,
    d.dt
FROM (
    SELECT generate_series(now() - interval '7 days', now() - interval '1 day', '1 day'::interval) AS dt
) d
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-016');

-- ----------------------------------------------------------
-- Part 5: gps_logs — 刷新染病源 + 接触牲畜近 72h GPS 轨迹
-- ----------------------------------------------------------
-- 为 SL-2024-048（染病源）插入 72h 密集 GPS 轨迹（每小时）
INSERT INTO gps_logs (device_id, latitude, longitude, accuracy, recorded_at)
SELECT
    (SELECT inst.device_id FROM installations inst
     JOIN livestock ls ON ls.id = inst.livestock_id
     WHERE ls.livestock_code = 'SL-2024-048' AND inst.removed_at IS NULL LIMIT 1),
    28.2312 + (random() - 0.5) * 0.002,  -- 围绕牧场中心点
    112.9412 + (random() - 0.5) * 0.002,
    2.0 + random() * 3.0,
    ts
FROM (
    SELECT generate_series(now() - interval '72 hours', now(), '1 hour'::interval) AS ts
) sub;

-- 为近邻牲畜（SL-049, SL-050, SL-001~005）插入重叠区域 GPS 轨迹
-- 使接触链计算能检测到时空交叉
-- （完整 SQL 覆盖约 6 头牲畜，轨迹在 SL-048 附近 ±50m 范围内）

-- ----------------------------------------------------------
-- Part 6: contact_traces — 扩展字段 + 刷新接触时间
-- ----------------------------------------------------------
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS disease_type VARCHAR(50);
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS marked_at TIMESTAMP;
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS risk_score INT DEFAULT 0;
ALTER TABLE contact_traces ADD COLUMN IF NOT EXISTS risk_level VARCHAR(10) DEFAULT 'LOW';

-- 刷新已有接触记录时间为 now() 相对
UPDATE contact_traces SET last_contact_at = now() - interval '3 hours'
WHERE from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048');
UPDATE contact_traces SET last_contact_at = now() - interval '30 hours'
WHERE from_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-049')
  AND to_livestock_id = (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-050');

-- 新增覆盖 24h/48h/72h 三个窗口的接触链种子（染病源 SL-048）
-- 24h 窗口（高风险：近距离 + 长时间）
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at, disease_type, marked_at, risk_score, risk_level)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048'),
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-049'),
    3.0 + random() * 2.0, 45, now() - interval '3 hours',
    '口蹄疫疑似', now() - interval '2 hours', 82, 'HIGH'
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-049');

-- 48h 窗口（中风险）
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at, disease_type, marked_at, risk_score, risk_level)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048'),
    (SELECT id FROM livestock WHERE livestock_code = 'SL-002'),
    15.0 + random() * 5.0, 18, now() - interval '36 hours',
    '口蹄疫疑似', now() - interval '2 hours', 58, 'MEDIUM'
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-002');

-- 72h 窗口（低风险）
INSERT INTO contact_traces (farm_id, from_livestock_id, to_livestock_id, proximity_meters, contact_duration_minutes, last_contact_at, disease_type, marked_at, risk_score, risk_level)
SELECT 1,
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-048'),
    (SELECT id FROM livestock WHERE livestock_code = 'SL-2024-005'),
    45.0 + random() * 10.0, 5, now() - interval '60 hours',
    '口蹄疫疑似', now() - interval '2 hours', 28, 'LOW'
WHERE EXISTS (SELECT 1 FROM livestock WHERE livestock_code = 'SL-2024-005');

-- ----------------------------------------------------------
-- Part 7: feature_gates — 健康模块细粒度 feature gate
-- ----------------------------------------------------------
INSERT INTO feature_gates (tier, feature_key, gate_type, limit_value, retention_days, is_enabled) VALUES
    -- basic: 仅基础监测，数据保留 7 天
    ('basic', 'temperature_monitor', 'none', NULL, 7, TRUE),
    ('basic', 'peristaltic_monitor', 'none', NULL, 7, TRUE),
    ('basic', 'health_score', 'lock', NULL, NULL, FALSE),
    ('basic', 'estrus_detect', 'lock', NULL, NULL, FALSE),
    ('basic', 'epidemic_alert', 'lock', NULL, NULL, FALSE),
    -- standard: 解锁深度分析，数据保留 30 天
    ('standard', 'temperature_monitor', 'none', NULL, 30, TRUE),
    ('standard', 'peristaltic_monitor', 'none', NULL, 30, TRUE),
    ('standard', 'health_score', 'none', NULL, 30, TRUE),
    ('standard', 'estrus_detect', 'lock', NULL, NULL, FALSE),
    ('standard', 'epidemic_alert', 'lock', NULL, NULL, FALSE),
    -- premium: 解锁发情 + 疫情，数据保留 365 天
    ('premium', 'temperature_monitor', 'none', NULL, 365, TRUE),
    ('premium', 'peristaltic_monitor', 'none', NULL, 365, TRUE),
    ('premium', 'health_score', 'none', NULL, 365, TRUE),
    ('premium', 'estrus_detect', 'none', NULL, 365, TRUE),
    ('premium', 'epidemic_alert', 'none', NULL, 365, TRUE),
    -- enterprise: 全部解锁，数据保留 3 年
    ('enterprise', 'temperature_monitor', 'none', NULL, 1095, TRUE),
    ('enterprise', 'peristaltic_monitor', 'none', NULL, 1095, TRUE),
    ('enterprise', 'health_score', 'none', NULL, 1095, TRUE),
    ('enterprise', 'estrus_detect', 'none', NULL, 1095, TRUE),
    ('enterprise', 'epidemic_alert', 'none', NULL, 1095, TRUE);

-- ----------------------------------------------------------
-- Part 8: 更新 health_snapshots 时间戳
-- ----------------------------------------------------------
UPDATE health_snapshots SET last_assessed_at = now(), updated_at = now()
WHERE farm_id = 1;
```

**种子验证清单**（部署后执行）：
- `SELECT count(*) FROM temperature_logs WHERE recorded_at > now() - interval '72 hours'` → 应有 ~144 条/牲畜
- `SELECT count(*) FROM activity_logs WHERE recorded_at > now() - interval '7 days'` → 应有 ~168 条/牲畜
- `SELECT count(*) FROM estrus_scores WHERE scored_at > now() - interval '7 days'` → 应有 7+ 条
- `SELECT count(*) FROM contact_traces WHERE last_contact_at > now() - interval '72 hours'` → 应有 6+ 条覆盖三窗口
- `SELECT * FROM feature_gates WHERE feature_key = 'health_score'` → 应有 4 行（4 tier）

### 3.2 HealthApplicationService — 注入订阅门控

`HealthApplicationService` 新增 `SubscriptionQueryService` 依赖（通过 ACL port，避免 Health 直接依赖 Commerce）。

**新增 ACL port**：`HealthSubscriptionPort`（定义在 `health/domain/port/`）

```java
public interface HealthSubscriptionPort {
    /** 返回当前租户指定 featureKey 的 retentionDays（filter gate） */
    int getRetentionDays(String featureKey);
    /** 返回当前租户是否拥有指定 featureKey 的访问权（lock gate） */
    boolean hasFeature(String featureKey);
}
```

实现类 `HealthSubscriptionPortImpl`（放在 `shared/` 或 `identity/infrastructure/acl/`），注入 `SubscriptionQueryService` + `TenantContext.getCurrentTenant()`。

**门控点**：
- `getFeverDetail(farmId, livestockId)` — 按 `temperature_monitor` 的 retentionDays 截断 `recentLogs` 时间范围；若 `hasFeature("health_score")` 则填充 `dailyFeverHours`，否则返回空列表
- `getDigestiveDetail` — 同理按 `peristaltic_monitor` retentionDays 截断；`health_score` 控制 `intensityHeatmap`
- `getEstrusDetail` — 若无 `estrus_detect` feature 则返回空 trend7d + activityComparison
- `getEpidemicContactNetwork` — 若无 `epidemic_alert` feature 返回 403

### 3.3 新增 DTO（`HealthDtos.java`）

```java
// 发热持续时长
public record DailyFeverHour(String date, double hours) {}

// 蠕动强度热力图
public record IntensityCell(int hour, double intensity, boolean abnormal) {}

// 活动量对比
public record ActivityComparisonData(
    int recentSteps, int baselineSteps,
    double recentDistance, double baselineDistance,
    double recentActivityIndex, double baselineActivityIndex
) {}

// 疫情接触网络
public record ContactNode(
    String livestockId, String livestockCode,
    double proximityMeters, int contactDurationMinutes,
    Instant lastContactAt, int hoursAgo,
    int timeScore, int distanceScore, int durationScore,
    int totalRiskScore, String riskLevel // HIGH / MEDIUM / LOW
) {}

public record ContactNetworkResponse(
    String sourceLivestockId, String sourceLivestockCode,
    List<ContactNode> contacts
) {}
```

### 3.4 新增 API 端点

**FeverController / DigestiveController / EstrusController** — 现有 detail 端点返回体扩展新字段（向后兼容，新字段可为空列表）

**EpidemicController** — 新增端点：

| 方法 | 路径 | 说明 |
|------|------|------|
| `POST` | `/farms/{farmId}/health/epidemic/mark` | 标记染病牲畜，body: `{livestockId, diseaseType, markedAt}` |
| `DELETE` | `/farms/{farmId}/health/epidemic/mark/{livestockId}` | 取消染病标记 |
| `GET` | `/farms/{farmId}/health/epidemic/contacts/{livestockId}` | 获取接触链网络 + 三维风险评分 |

**接触链计算逻辑**（`EpidemicContactService`）：
1. 通过 `Installation` 查到染病牲畜的 `deviceId`
2. 查染病牲畜 72h 内的 `GpsLog` 轨迹点
3. 遍历同牧场其他牲畜的 GPS 轨迹，计算时空交叉（同时间窗口 ±10min 内距离 < 50m 的点对）
4. 聚合为每头牛的最近接触距离、累计持续时长、最近接触时间
5. 按三维模型计算 riskScore + riskLevel
6. 按 hoursAgo 分组到 24h/48h/72h 窗口

### 3.5 contact_traces 表扩展

现有 `contact_traces` 表缺少染病标记字段。V31 迁移新增：

```sql
ALTER TABLE contact_traces ADD COLUMN disease_type VARCHAR(50);
ALTER TABLE contact_traces ADD COLUMN marked_at TIMESTAMP;
ALTER TABLE contact_traces ADD COLUMN risk_score INT DEFAULT 0;
ALTER TABLE contact_traces ADD COLUMN risk_level VARCHAR(10) DEFAULT 'LOW';
```

---

## 4. 前端实现

### 4.1 数据模型扩展（`health_models.dart`）

新增模型类，与后端 DTO 对齐：

```dart
class DailyFeverHour { final String date; final double hours; ... }
class IntensityCell { final int hour; final double intensity; final bool abnormal; ... }
class ActivityComparisonData { final int recentSteps; ... }
class ContactNode { final String livestockId; ... final int totalRiskScore; final String riskLevel; ... }
class ContactNetworkResponse { final String sourceLivestockId; ... final List<ContactNode> contacts; ... }
```

扩展 `FeverDetailData` 增加 `dailyFeverHours` 字段；`DigestiveDetailData` 增加 `intensityHeatmap` 字段；`EstrusDetailData` 增加 `activityComparison` 字段。

### 4.2 详情页改造

每个详情页的 `build()` 方法中 `ref.watch(subscriptionControllerProvider)` 获取 Tier，然后用 `checkTierAccess(tier, featureKey)` 判断每个图表区块是否可见。

**通用模式**（伪代码）：
```dart
final subAsync = ref.watch(subscriptionControllerProvider);
final tier = subAsync.valueOrNull?.tier ?? SubscriptionTier.basic;

// 基础图表（所有 Tier 可见）
_buildTemperatureChart(detail),

// Standard+ 图表
if (checkTierAccess(tier, FeatureFlags.healthScore))
  _buildFeverDurationChart(detail.dailyFeverHours)
else
  _buildLockedChart(context, featureKey: 'health_score', minTier: 'standard'),
```

**新增 `_buildLockedChart` widget**：复用 `LockedOverlay` 组件，包裹占位图表区域，显示 🔒 图标 + "升级到 Standard/Premium" + 升级按钮（跳转订阅页）。

### 4.3 新增 EpidemicContactPage

路径：`/twin/epidemic/contacts/:livestockId`

页面结构：
1. 顶部：染病牲畜信息卡（编号 + 疾病类型 + 标记时间 + 取消标记按钮）
2. 接触链拓扑图（`CustomPaint` 或 `fl_chart ScatterChart` 绘制网络节点）
3. 密切接触者明细 — 按 24h/48h/72h 三段分组列表，每项显示三维评分分项 + 总分徽章 + 风险等级标签

### 4.4 路由 & 导航

- `app_router.dart` 新增 `twinEpidemicContactDetail` 路由
- `epidemic_page.dart` 顶部增加"标记染病"入口（选择牲畜 → 调 `POST /mark`）
- 染病牲畜列表项点击 → 跳转 `EpidemicContactPage`

### 4.5 前端 Tier 获取注意

`subscriptionControllerProvider` 是 tenant 级 FutureProvider，详情页 watch 它不会随牧场切换重建（符合预期——订阅是租户级的）。详情页自身的 health 数据 Controller 已继承 `FarmScopedAsyncNotifier`，牧场切换时正确刷新。

---

## 5. 测试计划

### 5.1 后端单元测试

| 测试类 | 覆盖范围 |
|--------|---------|
| `HealthSubscriptionPortImplTest` | retentionDays 解析正确性、hasFeature 判断 |
| `EpidemicContactServiceTest` | 三维风险评分计算、时间窗口分组、GPS 时空交叉算法 |
| `HealthApplicationServiceTelemetryTest`（扩展） | detail 方法按 Tier 截断数据深度 |

### 5.2 后端集成测试（部署后）

- Basic tenant 调 `/health/fever/{id}` → `dailyFeverHours` 为空列表
- Standard tenant 调 `/health/fever/{id}` → `dailyFeverHours` 有数据
- Basic tenant 调 `/health/epidemic/contacts/{id}` → 403
- Premium tenant 调 `/health/epidemic/contacts/{id}` → 返回接触链 + 评分

### 5.3 前端 Widget 测试

- `FeverDetailPage` — Basic Tier 不显示持续时长图表、显示 LockedOverlay
- `EpidemicContactPage` — 接触者按 24h/48h/72h 正确分组、风险评分正确着色
- `LockedOverlay` — 锁定状态显示升级提示 + 按钮

---

## 6. 实施顺序

| 步骤 | 内容 | 验证方式 |
|------|------|---------|
| 1 | **V31 种子数据迁移**（时序刷新 + 接触链 + feature gate + 表扩展） | SQL 语法检查 + 部署后 count 验证 |
| 2 | 后端 DTO 扩展 + HealthSubscriptionPort ACL | `./gradlew compileJava` 通过 |
| 3 | HealthApplicationService 门控逻辑（detail 方法按 Tier 截断） | 单元测试 |
| 4 | EpidemicContactService 接触链计算 + 三维评分 | 单元测试 |
| 5 | EpidemicController 新增端点 | 编译通过 |
| 6 | 前端 health_models.dart 扩展 | `flutter analyze` |
| 7 | 三个详情页改造 + LockedOverlay 集成 | Widget 测试 |
| 8 | 新增 EpidemicContactPage + 路由 | Widget 测试 |
| 9 | 编译验证（前后端） | `./gradlew compileJava` + `flutter build web` |
| 10 | 用户部署 → 集成测试 | 种子验证清单 + curl 验证 API + 浏览器验证 UI |

> **种子数据是第一步且必须先于功能开发**：图表功能依赖近期能查到的时序数据，若先开发功能再补种子数据，开发期间无法验证渲染效果。V31 迁移完成后应立即部署验证数据可见性，再进入功能编码。

---

## 7. 假设与约束

- 接触链分析依赖 GPS 轨迹数据密度：当前 GPS 模拟数据采样间隔约 30min，接触判定窗口设为 ±10min、距离阈值 50m。真实 LoRa 数据接入后（Phase 3）需校准参数。
- 三维评分权重（40/35/25）为初版经验值，可通过 `feature_gates` 表或配置文件后续调优，不影响接口契约。
- `health_monitoring`（V6 旧粗粒度 key）保留不动，新细粒度 key 共存，旧 key 不再被 Health 模块引用。
- 前端 `LockedOverlay` 组件已存在但未使用，本次首次集成。
- 接触链拓扑图在 Flutter 中使用 `CustomPaint` 自绘（节点 + 连线），不引入新图表库依赖。
