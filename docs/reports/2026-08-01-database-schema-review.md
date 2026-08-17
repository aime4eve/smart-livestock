# 数据库表设计核查报告

> 日期：2026-08-01
> 范围：V1-V41 全部 Flyway 迁移（49 张表）、47 个 JPA 实体、代码中的枚举定义

---

## P0 — 会导致运行时错误的 bug

### 1. alerts 表 CHECK 约束丢失了两个告警类型

**问题**：代码中 AlertType 枚举包含 DEVICE_TAMPER 和 DEVICE_LOW_BATTERY，
TelemetryIngestionService 实际会写入这两种告警。但数据库约束在 V40 重建时
只保留了 8 种类型，把这两个丢掉了。

**影响迁移路径**：
- V2 初始约束：5 种类型
- V26 重建：7 种（新增 FENCE_APPROACH, ZONE_APPROACH，BEHAVIOR_ABNORMAL -> DIGESTIVE_ABNORMAL）
- phase3_device_extension (V20260709120000) 重建：10 种（新增 AI_ANOMALY, DEVICE_TAMPER, DEVICE_LOW_BATTERY）
- V40 重建：**8 种（丢失 DEVICE_TAMPER, DEVICE_LOW_BATTERY）**

V40 当前约束：
```sql
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH','FENCE_APPROACH','ZONE_APPROACH','TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL','ESTRUS','EPIDEMIC','AI_ANOMALY'));
```

**实际效果**：设备防拆或低电量告警写入时会抛 CheckViolationException。

**相关代码**：
- AlertType.java：枚举定义了全部 10 种类型
- TelemetryIngestionService.java：会创建 DEVICE_TAMPER 和 DEVICE_LOW_BATTERY 告警

**修复方案**：新增迁移补回两个值。
```sql
ALTER TABLE alerts DROP CONSTRAINT IF EXISTS chk_alerts_type;
ALTER TABLE alerts ADD CONSTRAINT chk_alerts_type CHECK (type IN (
    'FENCE_BREACH','FENCE_APPROACH','ZONE_APPROACH','TEMPERATURE_ABNORMAL',
    'DIGESTIVE_ABNORMAL','ESTRUS','EPIDEMIC','AI_ANOMALY',
    'DEVICE_TAMPER','DEVICE_LOW_BATTERY'));
```

---

## P1 — 影响查询性能或数据一致性

### 2. gps_logs 未做分区，是最大的未分区时序表

gps_logs 是数据量增长最快的表（每设备每 30 秒一条 GPS ping），但没有像
temperature_logs、rumen_motility_logs、activity_logs、device_telemetry_logs
那样按月分区。随数据积累，全表扫描和唯一约束检查都会越来越慢。

uq_gps_logs_device_recorded_at 唯一索引在分区化时需特殊处理
（必须包含分区键 recorded_at，当前已包含）。

**建议**：转为按月分区表。

### 3. api_call_logs 无分区、无保留策略

每 API 请求写一条，增长速度快。当前无分区、无 TTL 清理。

**建议**：分区或定期归档。

### 4. 分区表没有自动维护机制

所有分区表的预建分区只到 2026-08 或 2026-10：

| 表 | 预建分区截止 |
|---|---|
| temperature_logs | 2026-08 |
| rumen_motility_logs | 2026-08 |
| activity_logs | 2026-08 |
| device_telemetry_logs | 2026-10 |
| anomaly_scores | 仅 default |

之后的写入全部落入 _default 分区，查询性能退化。

**建议**：引入 pg_partman 或定时 partition creation job。

### 5. notifications 表缺少 user_id 索引

当前索引：
```sql
CREATE INDEX idx_notifications_tenant_unread ON notifications(tenant_id, is_read) WHERE is_read = FALSE;
```

通知中心通常按 user 查询，缺少 (user_id, is_read) 索引会导致用户级通知查询全表扫描。

### 6. alerts 表多个 FK 列缺索引

- alerts.livestock_id：无索引
- alerts.fence_id：无索引

alerts.farm_id 有索引，但按牲畜或围栏查告警时会全表扫描。

---

## P2 — 设计债，建议清理但不紧急

### 7. alerts 表保留了 4 个废弃列

acknowledged_by、acknowledged_at、handled_by、handled_at 在 V26 已被
alert_read_status 和 resolved_type/resolved_at 取代。

V26 注释："retained for backward compatibility during frontend migration window"。

JPA 实体仍在映射这 4 列。迁移窗口已过，建议后续清理。

### 8. devices 表 snr 和 last_gateway 列定义冲突

两个 phase3 迁移对同一列定义了不同类型：
- snr：V20260709120000 加 NUMERIC(4,1)，V20260709150000 加 DECIMAL(6,2)
- last_gateway：一处 VARCHAR(128)，一处 VARCHAR(100)

实际列类型取决于部署顺序（IF NOT EXISTS 保护先执行者）。

**建议**：统一类型定义。

### 9. fence_zones.farm_id 缺 FK 约束

```sql
CREATE TABLE fence_zones (
    ...
    fence_id BIGINT NOT NULL REFERENCES fences(id),
    farm_id  BIGINT NOT NULL,   -- 无 FK
    ...
);
```

可能导致孤儿引用。

### 10. anomaly_scores 分区键与业务查询键不一致

分区键是 created_at，但业务时间字段是 window_start / window_end。

按时间窗口查询时不带 created_at 过滤会跨分区扫描。

### 11. TIMESTAMP 与 TIMESTAMPTZ 类型不统一

V1/V2/V3 用 TIMESTAMP（无时区），V6 起改用 TIMESTAMPTZ。

同一张表内混用的情况：
- farms: created_at/updated_at 是 TIMESTAMP，deleted_at 是 TIMESTAMPTZ
- alerts: created_at/updated_at 是 TIMESTAMP，resolved_at 是 TIMESTAMPTZ
- gps_logs.recorded_at 是 TIMESTAMP，但它参与和 gps_quality_tests（TIMESTAMPTZ）的时间区间 JOIN

PostgreSQL 隐式转换可以工作，但跨表比较时可能产生微妙的时区偏移 bug。

---

## P3 — 观察项（当前可接受，但值得知晓）

- rtk_calibration_sessions 和 gps_quality_sessions 已在 V20260718140000 中
  DROP TABLE，清理干净，无残留。
- installations.livestock_id 无 FK 是文档化的跨上下文设计决策，可接受。
- revenue_periods 金额列用 INTEGER（分/cent），需确认单位约定在代码层一致。
- tile_generation_tasks 冗余坐标列是对 tile_regions 的有意反范式（任务独立性），
  可接受。

---

## 修复优先级

| 优先级 | 项目 | 工作量 | 建议时间 |
|--------|------|--------|----------|
| P0 立即修 | 补 alerts CHECK 约束的 DEVICE_TAMPER/DEVICE_LOW_BATTERY | 1 条迁移 | 本次 |
| P1 短期 | notifications 加 user_id 索引、alerts FK 列加索引 | 1 条迁移 | 下次部署 |
| P1 短期 | 分区自动维护（定时任务或 pg_partman） | 中等 | 近期 |
| P1 中期 | gps_logs 分区化 | 较大，需数据迁移 | 评估后 |
| P2 后续 | 清理 alerts 废弃列、统一类型、补 fence_zones FK | 清理迁移 | 技术债窗口 |
