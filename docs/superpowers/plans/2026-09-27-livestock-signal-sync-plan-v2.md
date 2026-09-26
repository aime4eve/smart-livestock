# Livestock Signal Sync Architecture — Plan v2

| Field | Value |
|---|---|
| Date | 2026-09-27 |
| Status | **Draft pending user approval; coding must not start** |
| Supersedes | Conversation-only plan dated 2026-09-26 |
| Review response | [`2026-09-27-livestock-signal-sync-plan-review-response.md`](../reviews/2026-09-27-livestock-signal-sync-plan-review-response.md) |
| Primary surfaces | Livestock Management, Ranch Map |
| Live data | Position, rumen temperature, rumen motility, health, AI, fence, device, alerts |

## 1. Summary

Build one authoritative frontend signal synchronization architecture instead of adding page-specific timers. The backend exposes livestock-level and map-level Signal APIs. The frontend owns a Riverpod Signal Sync Center that subscribes to scoped deltas and merges position, rumen metrics, health, AI, fence, device, and alert signals into one store.

The architecture is delivered in four reviewable stages:

| Stage | Purpose | Branch |
|---|---|---|
| 1a | Backend revisions, snapshots, Signal APIs, integration tests | `nix/livestock-signal-sync-p1a` |
| 1b | Flutter Signal Store, Livestock Management, Ranch Map, old-source cleanup | `nix/livestock-signal-sync-p1b` |
| 2 | Transactional Outbox and reliable event capture | `nix/livestock-signal-sync-p2` |
| 3 | Flutter Web SSE spike, SSE transport, polling fallback | `nix/livestock-signal-sync-p3` |

Each implementation stage starts in its own worktree from the latest `master`. A stage may begin only after the previous stage is approved and merged or explicitly rebased by the user.

## 2. Architecture Decisions

1. **Do not introduce Spring Cloud.** The current monolith can expose a signal projection and use its existing RocketMQ infrastructure.
2. **Do not use WebHook to notify browsers.** WebHook/MQ is acceptable only from external platforms to the backend.
3. **The Signal API is authoritative for page rendering.** SSE events only say “something changed”; the frontend fetches authoritative data from Signal APIs.
4. **The backend computes freshness.** The frontend never infers offline state or stale location solely from wall-clock time.
5. **No synthetic positions.** Missing positions remain missing.
6. **Phase 1 polling is a valid product fallback**, not a throwaway prototype. Phase 3 only changes transport.

## 3. Authoritative Data Ownership

| Signal | Authoritative source for Signal API | Transition note |
|---|---|---|
| Current position | `livestock_location_snapshots` | `livestock.last_latitude/last_longitude/last_position_at` remains a legacy projection in Phase 1. Do not drop it until old map paths are retired. |
| Rumen temperature | `health_snapshots.current_temp` plus new recorded-at/source columns | Existing `temperature_logs` remains history. |
| Rumen motility | `health_snapshots.current_motility` plus new recorded-at/source columns | API exposes normalized `TIMES_PER_MINUTE`, never a raw cumulative counter. |
| Rule/AI health status | ACTIVE alerts plus `health_snapshots` | ACTIVE alerts win for severity, snapshots fill metric state. |
| AI observation/alert | Latest `anomaly_scores` plus ACTIVE `AI_ANOMALY`/temperature-family alert | Score alone is `OBSERVE`; active alert is `ALERT`. |
| Fence state | ACTIVE fence alerts plus server-side containment check | Frontend containment fallback is removed. |
| Fence geometry | `fences.vertices` | Geometry changes bump a dedicated revision. |
| Device state | Device runtime plus ACTIVE device alerts | Frontend does not derive offline state. |
| Alert summary | `alerts` and `alert_read_status` | Counts are per current user. |

## 4. Phase 1a — Backend Foundation

### 4.1 Migrations

Use these currently unused IDs:

```text
V20260927090000__create_signal_sync_tables.sql
V20260927091000__create_signal_event_outbox.sql
```

The Outbox migration is designed in this document but created only in Phase 2.

### 4.2 Revision and location tables

`farm_signal_revisions` has three counters:

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

`livestock_location_snapshots` stores only the current non-manual location:

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

Position rows are valid only when latitude is between `-90..90`, longitude is between `-180..180`, and the fix is not `(0,0)`.

### 4.3 GPS backfill

Backfill through the current active installation only. A historical GPS row is assigned to the animal currently installed on that device only if the fix occurred after that installation began. This avoids assigning an old position from a previous animal.

Use this semantic SQL:

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

The migration must pass on a clean database and on a database containing the current dev/test shape.

### 4.4 Health metric columns

Extend `health_snapshots`:

```sql
ALTER TABLE health_snapshots
    ADD COLUMN IF NOT EXISTS current_temp_recorded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_temp_source VARCHAR(32),
    ADD COLUMN IF NOT EXISTS current_motility_recorded_at TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS current_motility_source VARCHAR(32);
```

Backfill each metric from the latest matching telemetry row. If the raw source cannot be mapped to one of the five source values, store `NULL`; do not invent `DEVICE` or `UNKNOWN` database values.

### 4.5 Signal module

Create a ranch-side signal module:

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

Cross-context reads are adapted through narrow ports rather than importing another context’s repository directly.

### 4.6 Signal APIs

#### Livestock list signal

```http
GET /api/v1/farms/{farmId}/signals/livestock?livestockIds=1,2,3&cursor=128
```

`cursor` is `statusRevision`.

Response:

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

#### Map signal

```http
GET /api/v1/farms/{farmId}/signals/map?cursor=128:96:7&includeGeometry=false
```

`cursor` is `statusRevision:positionRevision:fenceGeometryRevision`.

The response contains:

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

Rules:

* `includeGeometry=true` returns complete active fence geometry.
* `fenceGeometryChanged=true` tells the client to immediately fetch a full map snapshot.
* `positionUpdates` contains only rows whose `position_revision` is greater than the cursor’s position revision.
* `livestockSignals` contains current status for requested active livestock when status changed.
* No field is returned for soft-deleted livestock.

### 4.7 API limits and errors

| Input | Behavior |
|---|---|
| Missing token | `401` |
| Farm not owned by tenant/user | `403` |
| Missing/empty `livestockIds` | `400 VALIDATION_ERROR` |
| More than 200 livestock IDs | `400 VALIDATION_ERROR` |
| Duplicate livestock IDs | Deduplicate before validation and query |
| Deleted livestock ID | Ignore; do not return an item and do not fail |
| Malformed cursor | `400 VALIDATION_ERROR` |
| Cursor component greater than current | `409 SIGNAL_CURSOR_INVALID` |
| Cursor older than replay window | `410 SIGNAL_CURSOR_TOO_OLD` with `resyncRequired=true` |
| Map farm has more than 1,000 active livestock | `400 SIGNAL_MAP_TOO_LARGE` in v1 |

Replay window:

```text
SIGNAL_CURSOR_REPLAY_LIMIT=1000 revisions
SIGNAL_CURSOR_MAX_AGE=24h
```

### 4.8 Status revision write paths

Introduce one transactional entry point:

```java
SignalRevisionService.bumpStatus(farmId, SignalChangeSource source)
SignalRevisionService.bumpPosition(farmId, SignalChangeSource source)
SignalRevisionService.bumpFenceGeometry(farmId, SignalChangeSource source)
```

Each method performs an atomic update:

```sql
INSERT INTO farm_signal_revisions (farm_id, status_revision)
VALUES (:farmId, 1)
ON CONFLICT (farm_id) DO UPDATE
SET status_revision = farm_signal_revisions.status_revision + 1,
    updated_at = NOW()
RETURNING status_revision;
```

The same pattern applies to position and geometry counters. There is no read-then-write.

Every path below must call the revision service inside its existing write transaction. Phase 2 replaces the direct call with a change recorder that writes revision and Outbox atomically.

| Change source | Entry point / transaction | Revision |
|---|---|---|
| Alert create/read/dismiss/auto-resolve | `AlertApplicationService.createAlert`, `markRead`, `batchRead`, `dismiss`, `autoResolve`, `autoResolveByLivestockAndType`, legacy delegates | status |
| Device telemetry alert | `TelemetryIngestionService.detectDeviceAlerts` | status |
| Device offline alert | `DeviceOfflineAlertScheduler` create/resolve path | status |
| Fence alert / location | `GpsLogEventConsumer.onMessage` | status + position when the fix is accepted |
| Fence CRUD/geometry | `FenceApplicationService.createFence`, `updateFence`, `forceUpdateFence`, `deleteFence` | status; geometry only when vertices/active state change |
| Health telemetry snapshot | `HealthApplicationService.processTelemetry` / `refreshSnapshot` | status when current temp, motility, metric timestamp, metric source, or status changes |
| Health alert bridge | `HealthAlertBridgeService.syncAlertsWithSnapshot` | status |
| AI assessment | `HealthAnomalyService.assess` (`REQUIRES_NEW`) | status |
| Stale health reconcile | `StaleHealthAlertReconciler.reconcileFarm` | status |
| Epidemic marking | `HealthApplicationService.markDiseased`, `unmarkDiseased` | status |
| Livestock CRUD | `LivestockApplicationService.createLivestock`, `updateLivestock`, `deleteLivestock` | status |
| Legacy direct position update | `LivestockApplicationService.updatePosition` | status + position |
| Installation | `InstallationApplicationService.install`, `remove`, `removeById` | status; clear/reproject affected location snapshot |
| Device runtime/status | `TelemetryIngestionService.ingest`, `DeviceApplicationService.activateDevice`, `updateDevice`, `decommissionDevice`, `deleteDevice`, DeviceHub sync paths | status |
| Farm creation | `FarmApplicationService.createFarm` | initialize all counters at zero |

Each row requires at least one integration test asserting that the relevant revision increases and a second assertion that an unchanged/idempotent operation does not produce a new API payload.

### 4.9 GPS projection transaction boundary

`GpsLogApplicationService.logGps()` remains the only writer for `gps_logs`.

The Signal projection is not in that database transaction. It is projected in `GpsLogEventConsumer.onMessage()` after resolving active installation and livestock:

```text
TelemetryIngestionService.ingest()
  -> gps_ingestion_tasks

GpsIngestionTaskScheduler / Processor
  -> gps_logs
  -> GpsLogUpdatedEvent
  -> RocketMQ gps-log-updated

GpsLogEventConsumer.onMessage()
  -> resolve active installation and livestock
  -> project livestock_location_snapshots
  -> bump positionRevision
  -> update livestock.last_* legacy projection
  -> fence detection / alerts
```

Order inside the consumer is mandatory:

1. Reject `MANUAL_IMPORT` for live current-position projection.
2. Resolve active installation and live livestock.
3. Validate coordinates and `recordedAt`.
4. Ignore fixes older than the current snapshot.
5. Project the new snapshot and bump `positionRevision`.
6. Continue fence detection, including the no-fence path.

Normal-latency target from `gps_logs` commit to Signal API visibility is under 1 second. This is eventual consistency, not the same database transaction. Phase 2’s Outbox makes the notification durable inside the projection transaction.

### 4.10 Freshness

Location:

| Value | Rule |
|---|---|
| `FRESH` | `ageSeconds <= 120` |
| `DELAYED` | `120 < ageSeconds <= 600` |
| `STALE` | `ageSeconds > 600` |
| `MISSING` | No snapshot |

Rumen metrics:

| Value | Rule |
|---|---|
| `FRESH` | `ageSeconds <= 1800` |
| `DELAYED` | `1800 < ageSeconds <= 3600` |
| `STALE` | `ageSeconds > 3600` |
| `MISSING` | No valid snapshot/value |

`ageSeconds` is calculated with `Duration.between(recordedAt, Instant.now())`. Do not call `toUtc()` or reinterpret third-party local timestamps.

Metric status mapping:

| Raw snapshot | API status |
|---|---|
| Temperature `NORMAL` | `NORMAL` |
| Temperature `ELEVATED` | `WATCH` |
| Temperature `FEVER` | `WATCH` |
| Temperature `CRITICAL` | `CRITICAL` |
| Motility `NORMAL` | `NORMAL` |
| Motility `LOW` | `WATCH` |
| Motility `ABNORMAL` | `CRITICAL` |

## 5. Phase 1a Tests

### Backend test gates

```bash
./gradlew compileJava
./gradlew test \
  --tests 'com.smartlivestock.ranch.signal.*' \
  --tests 'com.smartlivestock.ranch.application.*' \
  --tests 'com.smartlivestock.health.application.service.*' \
  --tests 'com.smartlivestock.integration.GpsAlertFlowTest'
```

Required scenarios:

1. Clean-database Flyway run succeeds.
2. Existing-database migration and backfill succeed.
3. Signal API returns 401/403/400/409/410 for the error matrix.
4. GPS backfill ignores manual import, invalid coordinates, `(0,0)`, and fixes predating current installation.
5. GPS projection updates no-fence farms.
6. GPS projection rejects stale fixes and preserves the newer snapshot.
7. Position freshness is calculated server-side.
8. Rumen temperature and motility are returned with value, unit, status, timestamp, source, and freshness.
9. Rumen metric changes bump statusRevision; unchanged metrics do not produce a changed payload.
10. AI score below alert threshold yields `OBSERVE`; active AI alert yields `ALERT`.
11. Device offline and low battery yield `FAULT/OFFLINE`.
12. Fence containment and ACTIVE fence alerts produce the same status priority server-side.
13. Unread counts are isolated by user.
14. Cursor replay, invalid cursor, and ahead-cursor behavior match the error matrix.
15. Every revision write path has a revision assertion.

## 6. Phase 1b — Frontend Foundation

### 6.1 Signal Sync Center

Create:

```text
lib/core/sync/signal_models.dart
lib/core/sync/signal_repository.dart
lib/core/sync/signal_store.dart
lib/core/sync/signal_scope.dart
lib/core/sync/signal_sync_controller.dart
lib/core/sync/signal_poller.dart
```

`SignalSyncController` extends `FarmScopedNotifier` and calls `watchActiveFarmId()` before reading state. It must be reset on login, logout, and active farm change.

Polling policy:

```text
livestock page: GET /signals/livestock every 3 seconds
ranch map:      GET /signals/map every 3 seconds
failure:        retain old state, set stale=true
background:     pause polling
foreground:     refresh immediately
no subscriber:  stop polling
```

Selectors:

```dart
livestockSignalsProvider(Set<String> livestockIds)
livestockSignalByIdProvider(String livestockId)
ranchMapSignalsProvider
ranchMapPositionsProvider
ranchMapGeometryProvider
signalTransportStatusProvider
```

### 6.2 Livestock Management UI

Each card shows independently typed signals:

1. CRITICAL health alert.
2. Fence breach.
3. Device fault/offline.
4. WARNING health alert.
5. AI observe.
6. Normal.

Rumen temperature and motility are compact metric chips. They must not displace the primary severity signals. Missing metrics show “暂无数据 / No data”; delayed and stale metrics use explicit styles.

Shared component:

```text
lib/features/livestock/presentation/widgets/livestock_signal_summary.dart
```

Stable keys:

```text
livestock-signal-{id}-health
livestock-signal-{id}-fence
livestock-signal-{id}-ai
livestock-signal-{id}-device
livestock-signal-{id}-rumen-temp
livestock-signal-{id}-rumen-motility
```

### 6.3 Ranch Map UI

Marker positions come only from `ranchMapPositionsProvider`.
Marker colors and inspector data come only from `ranchMapSignalsProvider`.
Fence geometry comes from the Signal map endpoint.

Remove:

* Ranch page’s 30-second Timer.
* Frontend fence-containment status fallback.
* `MapApiRepository.loadOverview()` usage.

During Phase 1b, `/ranch-overview` may continue to feed sheet lists, but it must no longer determine map marker position or fence status.

No-position and stale-position states:

| State | UI |
|---|---|
| Missing | “无定位 / No position”; no marker coordinate |
| Delayed | marker remains visible with subdued delay treatment |
| Stale | reduced opacity and explicit stale treatment |

### 6.4 i18n

Add synchronized keys to `app_zh.arb` and `app_en.arb`:

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

No UI string may be hardcoded.

### 6.5 Frontend tests

```bash
flutter gen-l10n
flutter analyze
flutter test test/core/sync test/features/livestock test/features/ranch
```

Required widget/controller scenarios:

1. Model parsing rejects malformed cursor and preserves nullable metrics.
2. Repository sends correct cursor and request parameters.
3. Polling failure retains old store state and marks stale.
4. Farm switch clears store and rebuilds scope.
5. Logout stops polling and clears data.
6. Position-only updates move a marker without full-list churn.
7. Rumen metric-only updates refresh cards and inspector.
8. Signal badge priority and `+N` behavior are stable.
9. Map marker colors match Signal Store, not RanchOverview.
10. Old Timer/fallback code is absent.
11. Desktop and mobile layouts have no text overflow or marker overlap.

## 7. Measured Latency Contract

Phase 1 uses a 3-second poll, not 5 seconds, to leave backend/render budget.

| Segment | Target |
|---|---|
| Business state committed -> Signal API readable | P95 ≤ 1s |
| Signal API readable -> frontend store committed | P95 ≤ 2s on 3s polling |
| Store committed -> visible widget update | P95 ≤ 500ms |
| End-to-end local/dev update | P95 ≤ 5s; P99 ≤ 7s |

“最多 5 秒” is not advertised as an unconditional network-independent maximum in Phase 1. Phase 3 SSE is required for the product’s hard real-time target.

Automated latency validation: persist a known change through API/test fixture, then poll the rendered test widget key until it changes. Run 20 samples and assert P95 ≤ 5s. Network failures are excluded but reported.

## 8. Phase 2 — Transactional Outbox

Create `V20260927091000__create_signal_event_outbox.sql`:

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

Event types:

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

The Outbox payload identifies the changed entity only; it does not become authoritative page state.

The dispatcher uses `FOR UPDATE SKIP LOCKED`, exponential retry, and a `FAILED` terminal state. Position and rumen updates may be coalesced per livestock, but the authoritative snapshot is never reconstructed from Outbox payloads.

Phase 2 gates:

1. Revision and Outbox write atomically.
2. Dispatcher retry/terminal behavior is tested.
3. Concurrent dispatch does not duplicate events.
4. Every Phase 1a revision path emits the correct event.
5. GPS projection remains eventual consistency after `gps_logs`, but revision and Outbox are atomic within the consumer transaction.

## 9. Phase 3 — SSE Spike and Transport

### 9.1 Spike before implementation

Create a disposable Flutter Web spike using `package:web` browser `EventSource`; do not use `dart:html`.

The spike must prove:

1. One-time ticket in the URL connects successfully.
2. Signal events and heartbeat comments are received.
3. Browser reconnect supplies `Last-Event-ID`.
4. Expired ticket returns a recoverable client state.
5. Chrome, Safari, Flutter Web debug, and Flutter Web release all work.
6. No WASM-incompatible API is introduced.

If the spike fails, Phase 3 remains in secure 2-second polling until a new transport design is approved.

### 9.2 Backend stream

```http
POST /api/v1/farms/{farmId}/signals/stream-ticket
GET /api/v1/farms/{farmId}/signals/stream?ticket=...&cursor=...
```

Ticket rules:

* One-time use.
* 30-second lifetime.
* Bound to user, tenant, and farm.
* Cleanup on expiry/use.

Stream rules:

* `text/event-stream`.
* 20-second heartbeat.
* `Last-Event-ID` replay or explicit `reconnect`.
* Per-user and per-farm connection caps.
* Logout/farm switch closes old streams.

Event:

```text
id: 128:96:7
event: signal-changed
data: {"farmId":1,"livestockIds":[14,15],"fenceIds":[3],"statusRevision":128,"positionRevision":96,"fenceGeometryRevision":7}
```

Coalescing:

```text
minimum merge window: 1s
maximum notification delay: 5s
```

### 9.3 Frontend transport

```text
default: SSE
SSE failure: 3-second delta polling
extended failure: retain old data and show stale
farm switch/logout: close stream and reset scope
foreground: reconcile once, then restore preferred transport
```

Phase 3 gates:

1. SSE updates map position within the measured 5-second product target.
2. SSE updates rumen metrics in both pages.
3. Polling fallback activates without losing old state.
4. SSE recovery stops polling.
5. Multi-tab updates work.
6. High-frequency GPS does not create a request storm.

## 10. Rollout

1. Merge Phase 1a after clean-database and integration tests pass.
2. Deploy backend to dev.
3. Smoke Signal APIs with seed accounts.
4. Merge Phase 1b after analyze/tests/browser checks pass.
5. Build and deploy Flutter Web to dev.
6. Verify Livestock Management and Ranch Map against dev data.
7. Complete integration testing before preparing a PR.
8. Phase 2 and Phase 3 require separate user approval and separate worktrees.

## 11. Non-Goals

* No Spring Cloud introduction.
* No browser WebHook.
* No new alert persistence schema in Phase 1.
* No real-time chart streaming in Phase 1; detail pages continue using their existing APIs.
* No dropping `livestock.last_*` in Phase 1.
* No farms larger than 1,000 active livestock on the v1 map endpoint; they receive an explicit unsupported error until viewport batching is designed.

## 12. Approval Boundary

This document is a planning deliverable only. Implementation, worktree creation for 1a, migrations, APIs, frontend changes, deployment, and commits require explicit user approval of Plan v2.
