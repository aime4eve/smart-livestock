# 牲畜信号同步架构 Plan v2

| 字段 | 内容 |
|---|---|
| 日期 | 2026-09-27 |
| 状态 | **草案，等待用户批准；未批准前不得编码** |
| 取代 | 2026-09-26 会话内版牲畜信号同步计划 |
| 评审回执 | [`2026-09-27-livestock-signal-sync-plan-review-response.md`](../reviews/2026-09-27-livestock-signal-sync-plan-review-response.md) |
| 首批页面 | 牲畜管理、牧场地图 |
| 实时数据 | 位置、瘤胃温度、瘤胃蠕动次数、健康、AI、围栏、设备、告警 |

## 1. 摘要

本方案建立一套统一的前端信号同步架构，而不是继续给单个页面增加 Timer。后端提供牲畜列表信号接口和牧场地图信号接口，把位置、瘤胃指标、健康、AI、围栏、设备、告警聚合为稳定契约；前端建立 Riverpod Signal Sync Center，所有相关页面只从 Signal Store 读取状态。

交付拆成四个可评审阶段：

| 阶段 | 目标 | 分支 |
|---|---|---|
| 1a | 后端版本号、快照表、Signal API 和集成测试 | `nix/livestock-signal-sync-p1a` |
| 1b | Flutter Signal Store、牲畜管理、牧场地图和旧数据源清理 | `nix/livestock-signal-sync-p1b` |
| 2 | 事务 Outbox 和可靠状态事件 | `nix/livestock-signal-sync-p2` |
| 3 | Flutter Web SSE spike、SSE 传输和轮询兜底 | `nix/livestock-signal-sync-p3` |

每个实施阶段都使用独立 worktree，从最新 `master` 创建。上一阶段获得批准并合并，或由用户明确同意 rebase 后，下一阶段才能开始。

## 2. 架构决策

1. **不引入 Spring Cloud。** 当前单体可以承载信号投影，事件广播继续复用现有 RocketMQ 基础设施。
2. **不用 WebHook 通知浏览器。** WebHook/MQ 只能作为外部平台到后端的接入方式。
3. **Signal API 是页面渲染的权威数据源。** SSE 只通知“哪些实体变化了”，前端收到通知后继续调用 Signal API 拉取权威状态。
4. **freshness 由后端计算。** 前端不得根据本机时间推断设备离线或位置过期。
5. **不伪造位置。** 没有定位的牲畜必须显示“无定位”，不能使用旧坐标、零坐标或估算坐标。
6. **Phase 1 轮询是正式兜底能力。** Phase 3 只替换传输层，不推翻状态模型。

## 3. 数据权威归属

| 信号 | Signal API 权威来源 | 过渡说明 |
|---|---|---|
| 当前位置 | `livestock_location_snapshots` | `livestock.last_latitude/last_longitude/last_position_at` 在 Phase 1 保留为旧投影，待旧地图路径退役后再删除。 |
| 瘤胃温度 | `health_snapshots.current_temp` 及新增 recorded-at/source 列 | `temperature_logs` 继续作为历史明细。 |
| 瘤胃蠕动 | `health_snapshots.current_motility` 及新增 recorded-at/source 列 | API 输出归一化后的 `TIMES_PER_MINUTE`，不输出底层累计计数。 |
| 规则/AI 健康状态 | ACTIVE 告警和 `health_snapshots` | ACTIVE 告警决定严重度，快照补充当前指标。 |
| AI 观察/告警 | 最新 `anomaly_scores` 和 ACTIVE AI 相关告警 | 分数未开单是 `OBSERVE`，已开单是 `ALERT`。 |
| 围栏状态 | ACTIVE 围栏告警加后端包含性判断 | 前端多边形包含性 fallback 删除。 |
| 围栏几何 | `fences.vertices` | geometry 变化使用独立 revision。 |
| 设备状态 | 设备 runtime 和 ACTIVE 设备告警 | 前端不推断 offline。 |
| 告警摘要 | `alerts` 和 `alert_read_status` | 未读数按当前用户计算。 |

## 4. Phase 1a：后端基础

### 4.1 迁移版本

使用当前尚未占用的版本号：

```text
V20260927090000__create_signal_sync_tables.sql
V20260927091000__create_signal_event_outbox.sql
```

Outbox 的表结构在本计划中定稿，但迁移文件在 Phase 2 才创建。

### 4.2 版本表和位置快照

`farm_signal_revisions` 使用三个计数器：

```sql
CREATE TABLE farm_signal_revisions (
    farm_id BIGINT PRIMARY KEY REFERENCES farms(id) ON DELETE CASCADE,
    status_revision BIGINT NOT NULL DEFAULT 0,
    position_revision BIGINT NOT NULL DEFAULT 0,
    fence_geometry_revision BIGINT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO farm_signal_revisions (farm_id)
SELECT id FROM farms
ON CONFLICT (farm_id) DO NOTHING;
```

`statusRevision` 覆盖健康、瘤胃指标、AI、围栏状态、设备、告警和牲畜资料变化。
`positionRevision` 单独覆盖最新位置变化。
`fenceGeometryRevision` 单独覆盖围栏几何变化，避免 geometry 大 payload 与普通状态同步耦合。

`livestock_location_snapshots` 只保存当前有效位置：

```sql
CREATE TABLE livestock_location_snapshots (
    livestock_id BIGINT PRIMARY KEY REFERENCES livestock(id) ON DELETE CASCADE,
    farm_id BIGINT NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    device_id BIGINT NOT NULL REFERENCES devices(id),
    latitude DOUBLE PRECISION NOT NULL,
    longitude DOUBLE PRECISION NOT NULL,
    accuracy DOUBLE PRECISION,
    recorded_at TIMESTAMPTZ NOT NULL,
    source VARCHAR(32) NOT NULL,
    position_revision BIGINT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_location_snapshot_source CHECK (
        source IN (
            'AGENTIC_PLATFORM', 'THINGSBOARD', 'DATAGEN',
            'HTTP', 'MANUAL_IMPORT'
        )
    )
);

CREATE INDEX idx_location_snapshot_farm_revision
    ON livestock_location_snapshots (farm_id, position_revision);
CREATE INDEX idx_location_snapshot_farm_livestock
    ON livestock_location_snapshots (farm_id, livestock_id);
```

位置写入必须满足：

- `latitude` 在 `-90..90`。
- `longitude` 在 `-180..180`。
- 不接受 `(0,0)`。
- 不接受比当前快照更旧的 `recordedAt`。
- 坐标和时间都未变化时不递增 `positionRevision`。

### 4.3 GPS 存量回填

`gps_logs` 没有 `livestock_id/farm_id`，必须通过当前 active installation 解析归属。为避免把设备历史安装期间的旧定位分配给当前牲畜，只回填当前安装开始之后的有效定位。

语义 SQL：

```sql
WITH active_installations AS (
    SELECT
        i.device_id,
        i.livestock_id,
        i.installed_at,
        l.farm_id
    FROM installations i
    JOIN livestock l ON l.id = i.livestock_id
    WHERE i.removed_at IS NULL
      AND l.deleted_at IS NULL
),
latest_valid_positions AS (
    SELECT DISTINCT ON (a.livestock_id)
        a.livestock_id,
        a.farm_id,
        a.device_id,
        g.latitude,
        g.longitude,
        g.accuracy,
        g.recorded_at,
        g.source
    FROM active_installations a
    JOIN gps_logs g ON g.device_id = a.device_id
    WHERE g.recorded_at >= a.installed_at
      AND g.source <> 'MANUAL_IMPORT'
      AND g.latitude BETWEEN -90 AND 90
      AND g.longitude BETWEEN -180 AND 180
      AND NOT (g.latitude = 0 AND g.longitude = 0)
    ORDER BY a.livestock_id, g.recorded_at DESC
)
INSERT INTO livestock_location_snapshots (
    livestock_id, farm_id, device_id, latitude, longitude,
    accuracy, recorded_at, source, position_revision
)
SELECT
    livestock_id, farm_id, device_id, latitude, longitude,
    accuracy, recorded_at, source, 0
FROM latest_valid_positions;
```

迁移必须在全新库和当前 dev/test 形状的存量库上都通过。

### 4.4 瘤胃指标列

扩展 `health_snapshots`：

```sql
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS current_temp_recorded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_temp_source VARCHAR(32),
    ADD COLUMN IF NOT EXISTS current_motility_recorded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_motility_source VARCHAR(32);
```

从最新 `temperature_logs` 和 `rumen_motility_logs` 回填 recorded-at/source。若原始 source 无法映射到五个合法枚举，则保存 `NULL`；API 对外也返回 `null`。不得引入 `DEVICE` 或 `UNKNOWN` 作为存储值。

### 4.5 后端模块

新增 ranch 侧 signal 模块：

```text
ranch/interfaces/SignalController.java
ranch/application/signal/SignalQueryService.java
ranch/application/signal/SignalRevisionService.java
ranch/application/signal/SignalLocationProjectionService.java
ranch/application/signal/SignalHealthMetricProjectionService.java
ranch/application/signal/dto/SignalDtos.java
ranch/infrastructure/signal/SignalRevisionJpaRepository.java
ranch/infrastructure/signal/SignalLocationSnapshotJpaRepository.java
```

跨上下文读取必须通过窄端口适配器，不得直接反向依赖其他上下文内部 repository。

### 4.6 API 契约

#### 4.6.1 牲畜列表信号

```http
GET /api/v1/farms/{farmId}/signals/livestock?livestockIds=1,2,3&cursor=128
```

`cursor` 是 `statusRevision`。

响应示例：

```json
{
  "farmId": 1,
  "statusRevision": 128,
  "changed": true,
  "items": [
    {
      "livestockId": 14,
      "revision": 128,
      "health": {
        "status": "CRITICAL",
        "activeAlertTypes": ["TEMPERATURE_ABNORMAL"],
        "metrics": {
          "rumenTemperature": {
            "value": 39.4,
            "unit": "CELSIUS",
            "status": "CRITICAL",
            "recordedAt": "2026-09-27T09:58:00Z",
            "ageSeconds": 42,
            "freshness": "FRESH",
            "source": "AGENTIC_PLATFORM"
          },
          "rumenMotility": {
            "value": 2.1,
            "unit": "TIMES_PER_MINUTE",
            "status": "NORMAL",
            "recordedAt": "2026-09-27T09:58:00Z",
            "ageSeconds": 42,
            "freshness": "FRESH",
            "source": "AGENTIC_PLATFORM"
          }
        }
      },
      "ai": {
        "status": "OBSERVE",
        "score": 0.62,
        "anomalyType": "circadian_disruption",
        "assessedAt": "2026-09-27T09:58:00Z"
      },
      "fence": {
        "status": "BREACH",
        "activeAlertTypes": ["FENCE_BREACH"]
      },
      "device": {
        "status": "FAULT",
        "faultTypes": ["DEVICE_OFFLINE"],
        "deviceCount": 2
      },
      "alerts": {
        "activeCount": 2,
        "unreadCount": 1
      }
    }
  ]
}
```

#### 4.6.2 牧场地图信号

```http
GET /api/v1/farms/{farmId}/signals/map?cursor=128:96:7&includeGeometry=false
```

`cursor` 是：

```text
statusRevision:positionRevision:fenceGeometryRevision
```

响应必须包含：

```json
{
  "farmId": 1,
  "statusRevision": 128,
  "positionRevision": 96,
  "fenceGeometryRevision": 7,
  "cursor": "128:96:7",
  "changed": true,
  "statusChanged": true,
  "positionChanged": true,
  "fenceGeometryChanged": false,
  "fences": [],
  "livestockSignals": [],
  "positionUpdates": []
}
```

规则：

- `includeGeometry=true` 返回完整 active fence geometry。
- `fenceGeometryChanged=true` 时，前端立即重新拉取完整地图快照。
- `positionUpdates` 只包含 `position_revision` 大于 cursor 中位置版本的牲畜。
- `statusChanged=true` 时返回当前请求范围内 active livestock 的状态和瘤胃指标。
- 软删除牲畜不出现在响应中。

### 4.7 请求限制与错误

| 输入 | 行为 |
|---|---|
| 未认证 | `401` |
| farm 不属于当前 tenant/user | `403` |
| `livestockIds` 缺失或为空 | `400 VALIDATION_ERROR` |
| `livestockIds` 超过 200 个 | `400 VALIDATION_ERROR` |
| 重复 livestock ID | 校验前去重 |
| 已删除牲畜 ID | 忽略，不报错，也不返回该项 |
| cursor 格式错误 | `400 VALIDATION_ERROR` |
| cursor 任一段大于当前值 | `409 SIGNAL_CURSOR_INVALID` |
| cursor 落后超过 replay window | `410 SIGNAL_CURSOR_TOO_OLD`，并返回 `resyncRequired=true` |
| map 牧场 active livestock 超过 1000 | v1 返回 `400 SIGNAL_MAP_TOO_LARGE`，不做隐式降级 |

replay window：

```text
SIGNAL_CURSOR_REPLAY_LIMIT=1000 revisions
SIGNAL_CURSOR_MAX_AGE=24h
```

### 4.8 statusRevision 写路径清单

后端先提供同一个事务内入口：

```java
SignalRevisionService.bumpStatus(farmId, SignalChangeSource source);
SignalRevisionService.bumpPosition(farmId, SignalChangeSource source);
SignalRevisionService.bumpFenceGeometry(farmId, SignalChangeSource source);
```

计数器必须使用原子 SQL，例如：

```sql
INSERT INTO farm_signal_revisions (farm_id, status_revision)
VALUES (:farmId, 1)
ON CONFLICT (farm_id) DO UPDATE
SET status_revision = farm_signal_revisions.status_revision + 1,
    updated_at = NOW()
RETURNING status_revision;
```

position 和 geometry 使用相同模式。禁止先查后写。

以下路径都必须在既有业务事务内调用 revision 服务。Phase 2 将调用点升级为“revision + Outbox”的同一个 change recorder。

| 变化源 | 事务入口 | revision |
|---|---|---|
| 告警创建、已读、忽略、自动解除 | `AlertApplicationService.createAlert`、`markRead`、`batchRead`、`dismiss`、`autoResolve`、`autoResolveByLivestockAndType` 及 legacy 委托方法 | status |
| 设备遥测告警 | `TelemetryIngestionService.detectDeviceAlerts` | status |
| 设备离线告警 | `DeviceOfflineAlertScheduler` 创建/解除路径 | status |
| 围栏告警/位置 | `GpsLogEventConsumer.onMessage` | 接受新定位时 status + position |
| 围栏 CRUD/geometry | `FenceApplicationService.createFence`、`updateFence`、`forceUpdateFence`、`deleteFence` | status；vertices 或 active 状态变化时再 bump geometry |
| 健康遥测快照 | `HealthApplicationService.processTelemetry` / `refreshSnapshot` | 温度、蠕动、指标时间、source 或状态变化时 status |
| 健康告警桥接 | `HealthAlertBridgeService.syncAlertsWithSnapshot` | status |
| AI 评估 | `HealthAnomalyService.assess`（`REQUIRES_NEW`） | status |
| 过期健康 reconcile | `StaleHealthAlertReconciler.reconcileFarm` | status |
| 疫情标记 | `HealthApplicationService.markDiseased`、`unmarkDiseased` | status |
| 牲畜 CRUD | `LivestockApplicationService.createLivestock`、`updateLivestock`、`deleteLivestock` | status |
| legacy 直接位置更新 | `LivestockApplicationService.updatePosition` | status + position |
| 安装/解绑 | `InstallationApplicationService.install`、`remove`、`removeById` | status；同时重算或清理受影响位置快照 |
| 设备 runtime/status | `TelemetryIngestionService.ingest`、`DeviceApplicationService.activateDevice`、`updateDevice`、`decommissionDevice`、`deleteDevice`、DeviceHub 同步路径 | status |
| 牧场创建 | `FarmApplicationService.createFarm` | 初始化三个 revision 为 0 |

每一行至少要有一个集成测试断言 revision 递增；同时要验证幂等操作或无变化操作不产生新的 `changed=true` payload。

### 4.9 GPS 快照事务边界

`GpsLogApplicationService.logGps()` 继续是 `gps_logs` 唯一写入口。

Signal 位置投影不在 `gps_logs` 写事务内，而是在 RocketMQ consumer 事务中完成：

```text
TelemetryIngestionService.ingest()
  -> gps_ingestion_tasks

GpsIngestionTaskScheduler / Processor
  -> gps_logs
  -> GpsLogUpdatedEvent
  -> RocketMQ gps-log-updated

GpsLogEventConsumer.onMessage()
  -> 解析 active installation 和 livestock
  -> 写 livestock_location_snapshots
  -> bump positionRevision
  -> 更新 livestock.last_* 旧投影
  -> 围栏判定/告警
```

consumer 内部顺序固定：

1. `MANUAL_IMPORT` 不参与 live 当前位置投影，直接返回。
2. 解析 active installation 和 live livestock。
3. 校验坐标和 `recordedAt`。
4. 忽略比当前快照旧的 fix。
5. 写新位置快照并 bump `positionRevision`。
6. 继续围栏判定；牧场没有围栏时也必须已经完成位置投影。

正常链路目标：`gps_logs` commit 到 Signal API 可见的额外延迟小于 1 秒。这是最终一致，不是同一个数据库事务。Phase 2 使用 Outbox 把投影事务内的变更通知持久化。

### 4.10 freshness

位置：

| 值 | 规则 |
|---|---|
| `FRESH` | `ageSeconds <= 120` |
| `DELAYED` | `120 < ageSeconds <= 600` |
| `STALE` | `ageSeconds > 600` |
| `MISSING` | 无快照 |

瘤胃指标：

| 值 | 规则 |
|---|---|
| `FRESH` | `ageSeconds <= 1800` |
| `DELAYED` | `1800 < ageSeconds <= 3600` |
| `STALE` | `ageSeconds > 3600` |
| `MISSING` | 无有效快照或值 |

`ageSeconds` 一律使用 `Duration.between(recordedAt, Instant.now())` 计算。不要调用 `toUtc()`，也不要重解释第三方时间。

指标状态映射：

| 快照状态 | API status |
|---|---|
| Temperature `NORMAL` | `NORMAL` |
| Temperature `ELEVATED` | `WATCH` |
| Temperature `FEVER` | `WATCH` |
| Temperature `CRITICAL` | `CRITICAL` |
| Motility `NORMAL` | `NORMAL` |
| Motility `LOW` | `WATCH` |
| Motility `ABNORMAL` | `CRITICAL` |

## 5. Phase 1a 测试

后端命令：

```bash
./gradlew compileJava
./gradlew test \
  --tests 'com.smartlivestock.ranch.signal.*' \
  --tests 'com.smartlivestock.ranch.application.*' \
  --tests 'com.smartlivestock.health.application.service.*' \
  --tests 'com.smartlivestock.integration.GpsAlertFlowTest'
```

必须覆盖：

1. 全新库 Flyway 成功。
2. 当前 dev/test 形状的存量库迁移和回填成功。
3. Signal API 覆盖 401/403/400/409/410 错误矩阵。
4. GPS 回填忽略 `MANUAL_IMPORT`、非法坐标、`(0,0)` 和当前安装之前的 fix。
5. GPS 投影在无围栏牧场仍然更新位置。
6. 旧 fix 不会覆盖较新位置快照。
7. 位置 freshness 由后端计算。
8. 瘤胃温度和蠕动返回 value、unit、status、timestamp、source、freshness。
9. 瘤胃指标变化 bump statusRevision；无变化不产生 `changed=true`。
10. AI 分数低于告警阈值返回 `OBSERVE`；ACTIVE AI 告警返回 `ALERT`。
11. 设备离线和低电量返回 `FAULT/OFFLINE`。
12. 后端围栏包含性判断与 ACTIVE 围栏告警优先级稳定。
13. unread count 按当前用户隔离。
14. cursor replay、非法 cursor、超前 cursor 符合错误矩阵。
15. 每条 revision 写路径都有递增断言。

## 6. Phase 1b：前端基础

### 6.1 Signal Sync Center

新增：

```text
lib/core/sync/signal_models.dart
lib/core/sync/signal_repository.dart
lib/core/sync/signal_store.dart
lib/core/sync/signal_scope.dart
lib/core/sync/signal_sync_controller.dart
lib/core/sync/signal_poller.dart
```

`SignalSyncController` 继承 `FarmScopedNotifier`，读取状态前先调用 `watchActiveFarmId()`。登录、登出、active farm 变化时必须 reset。

轮询策略：

```text
牲畜管理：每 3 秒 GET /signals/livestock
牧场地图：每 3 秒 GET /signals/map
失败：保留旧 state，标记 stale=true
后台：暂停轮询
回前台：立即刷新
无订阅者：停止轮询
```

Selectors：

```dart
livestockSignalsProvider(Set<String> livestockIds)
livestockSignalByIdProvider(String livestockId)
ranchMapSignalsProvider
ranchMapPositionsProvider
ranchMapGeometryProvider
signalTransportStatusProvider
```

### 6.2 牲畜管理 UI

每张牲畜卡展示独立信号，优先级：

1. CRITICAL 健康告警。
2. Fence breach。
3. Device fault/offline。
4. WARNING 健康告警。
5. AI observe。
6. 正常。

瘤胃温度和蠕动次数使用紧凑 metric chip，不能挤压主要严重度信号。缺失指标显示“暂无数据”；delayed 和 stale 必须有明确样式。

共享组件：

```text
lib/features/livestock/presentation/widgets/livestock_signal_summary.dart
```

稳定测试 Key：

```text
livestock-signal-{id}-health
livestock-signal-{id}-fence
livestock-signal-{id}-ai
livestock-signal-{id}-device
livestock-signal-{id}-rumen-temp
livestock-signal-{id}-rumen-motility
```

### 6.3 牧场地图 UI

- marker position 只来自 `ranchMapPositionsProvider`。
- marker color 和点击面板状态只来自 `ranchMapSignalsProvider`。
- fence geometry 来自 Signal map endpoint。

Phase 1b 删除：

- Ranch page 的 30 秒 Timer。
- 前端围栏包含性状态 fallback。
- `MapApiRepository.loadOverview()` 使用路径。

Phase 1b 过渡期，`/ranch-overview` 可以继续给底部面板列表供数，但不得再决定地图 marker position 或 fence status。

位置状态：

| 状态 | UI |
|---|---|
| Missing | “无定位 / No position”，不渲染坐标 |
| Delayed | marker 继续显示，但使用弱化 delay 提示 |
| Stale | 降低透明度，并明确显示 stale |

### 6.4 i18n

`app_zh.arb` 和 `app_en.arb` 同步新增：

```text
livestockSignalHealthNormal
livestockSignalHealthWatch
livestockSignalHealthCritical
livestockSignalAiObserve
livestockSignalAiAlert
livestockSignalFenceApproach
livestockSignalFenceBreach
livestockSignalDeviceOffline
livestockSignalDeviceFault
livestockSignalMoreCount
livestockMetricRumenTemperature
livestockMetricRumenMotility
livestockMetricNoData
livestockMetricDelayed
livestockMetricStale
mapSignalNoPosition
mapSignalDelayedPosition
mapSignalStalePosition
```

禁止硬编码中英文文案。

### 6.5 前端测试

```bash
flutter gen-l10n
flutter analyze
flutter test test/core/sync test/features/livestock test/features/ranch
```

必须覆盖：

1. model 解析错误 cursor，并保留 nullable metrics。
2. repository 发送正确 cursor 和参数。
3. 轮询失败保留旧 state 并标记 stale。
4. 切换牧场清空 store 并重建 scope。
5. 登出停止轮询并清空数据。
6. position-only update 移动 marker，不造成整页列表 churn。
7. 瘤胃 metric-only update 刷新卡片和 inspector。
8. Signal badge 优先级和 `+N` 稳定。
9. marker color 只受 Signal Store 影响。
10. 旧 Timer 和旧 fallback 代码消失。
11. 桌面和移动宽度无文本溢出、无 marker 遮挡。

## 7. 延迟口径

Phase 1 使用 3 秒轮询，而不是 5 秒，给后端和渲染留预算。

| 段 | 目标 |
|---|---|
| 业务状态 commit -> Signal API 可读 | P95 ≤ 1s |
| Signal API 可读 -> frontend store commit | 3 秒轮询下 P95 ≤ 2s |
| store commit -> widget 可见更新 | P95 ≤ 500ms |
| 本地/dev 端到端 | P95 ≤ 5s；P99 ≤ 7s |

Phase 1 不对外宣传“无条件最多 5 秒”。产品上的硬性 5 秒目标由 Phase 3 SSE 承接。

自动化验证：通过 API/fixture 写入已知变化，然后轮询测试 widget key，直到可见状态变化。采集 20 个样本，断言 P95 ≤ 5s。网络失败样本剔除但必须报告。

## 8. Phase 2：事务 Outbox

创建 `V20260927091000__create_signal_event_outbox.sql`：

```sql
CREATE TABLE signal_event_outbox (
    id BIGSERIAL PRIMARY KEY,
    farm_id BIGINT NOT NULL,
    event_type VARCHAR(80) NOT NULL,
    entity_type VARCHAR(40) NOT NULL,
    entity_id BIGINT NOT NULL,
    payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    retry_count INT NOT NULL DEFAULT 0,
    available_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    dispatched_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT chk_signal_event_outbox_status
        CHECK (status IN ('PENDING', 'DISPATCHED', 'FAILED'))
);

CREATE INDEX idx_signal_event_outbox_pending
    ON signal_event_outbox (available_at, id)
    WHERE status = 'PENDING';
CREATE INDEX idx_signal_event_outbox_farm
    ON signal_event_outbox (farm_id, id DESC);
```

事件类型：

```text
LIVESTOCK_POSITION_CHANGED
RUMEN_METRIC_CHANGED
ALERT_CHANGED
FENCE_SIGNAL_CHANGED
FENCE_GEOMETRY_CHANGED
HEALTH_SIGNAL_CHANGED
AI_ASSESSMENT_COMPLETED
DEVICE_SIGNAL_CHANGED
INSTALLATION_CHANGED
LIVESTOCK_CHANGED
```

Outbox payload 只标识“哪个牧场、哪个实体变化了”，不能作为页面权威状态重建数据。

dispatcher 必须使用 `FOR UPDATE SKIP LOCKED`、指数退避和 `FAILED` 终态。位置和瘤胃更新可以按牲畜合并，但权威状态必须从 Signal API 读取。

Phase 2 完成条件：

1. revision 和 Outbox 同事务写入。
2. dispatcher 的重试、退避、终态有测试。
3. 并发 dispatch 不重复消费。
4. Phase 1a 的每条 revision 路径都发出正确事件。
5. GPS 投影与 `gps_logs` 仍是最终一致；但 consumer 事务内的 revision 和 Outbox 保持原子。

## 9. Phase 3：SSE spike 与传输层

### 9.1 先做 Flutter Web spike

用 `package:web` 的浏览器 `EventSource` 做 spike，不使用 `dart:html`。

spike 必须证明：

1. one-time ticket 能建立连接。
2. signal event 和 heartbeat comment 都能接收。
3. 浏览器重连携带 `Last-Event-ID`。
4. 过期 ticket 能转成可恢复的客户端状态。
5. Chrome、Safari、Flutter Web debug 和 release 都可用。
6. 不引入 WASM 不兼容 API。

如果 spike 失败，Phase 3 保留安全的 2 秒 polling，直到新的传输方案获得批准。

### 9.2 后端 stream

```http
POST /api/v1/farms/{farmId}/signals/stream-ticket
GET /api/v1/farms/{farmId}/signals/stream?ticket=...&cursor=...
```

ticket：

- one-time。
- 30 秒有效。
- 绑定 user、tenant、farm。
- 使用或过期后清理。

stream：

- `text/event-stream`。
- 每 20 秒 heartbeat。
- 支持 `Last-Event-ID` replay，或明确返回 `reconnect`。
- 对 user/farm 设置连接上限。
- 登出或切换牧场关闭旧 stream。

event 示例：

```text
id: 128:96:7
event: signal-changed
data: {"farmId":1,"livestockIds":[14,15],"fenceIds":[3],"statusRevision":128,"positionRevision":96,"fenceGeometryRevision":7}
```

合并策略：

```text
最小合并窗口：1 秒
最大通知延迟：5 秒
```

### 9.3 前端传输

```text
默认：SSE
SSE 失败：3 秒 delta polling
持续失败：保留旧数据并显示 stale
切牧场/登出：关闭 stream 并 reset scope
回前台：先对账一次，再恢复 SSE 或 polling
```

Phase 3 完成条件：

1. SSE 能满足位置和瘤胃指标的 5 秒产品目标。
2. SSE 失败自动切换 polling。
3. SSE 恢复后停止 polling。
4. 多标签页同步。
5. 高频 GPS 不会造成请求风暴。

## 10. 发布流程

1. Phase 1a 通过全新库迁移和集成测试后合并。
2. 部署后端到 dev。
3. 使用种子账号 smoke Signal API。
4. Phase 1b 通过 analyze、测试和浏览器检查后合并。
5. 构建并部署 Flutter Web 到 dev。
6. 在 dev 数据上验证牲畜管理和牧场地图。
7. 完成集成测试后准备 PR 收口。
8. Phase 2 和 Phase 3 必须分别获得用户批准，并使用独立 worktree。

## 11. 非目标

* 不引入 Spring Cloud。
* 不使用浏览器 WebHook。
* Phase 1 不新增告警持久化 schema。
* Phase 1 不做实时曲线流；详情页继续使用现有 API。
* Phase 1 不删除 `livestock.last_*`。
* v1 map endpoint 不支持超过 1000 头 active livestock 的牧场；超出时显式报错，待视口分批方案另行设计。

## 12. 批准边界

本文档只是规划交付物。实施 1a、创建实施 worktree、迁移、API、前端、部署和提交，都必须在用户明确批准 Plan v2 后进行。
