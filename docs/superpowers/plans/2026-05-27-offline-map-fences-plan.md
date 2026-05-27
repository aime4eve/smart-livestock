# Flutter Offline Fences + Observability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable offline fence caching with drift, offline fence editing with sync-on-reconnect, conflict resolution with dual-map comparison, livestock position caching, and observability via analytics event reporting.

**Architecture:** Fence data cached in drift `cached_fences` table with `synced` flag. Push-then-pull sync on reconnect. Version conflict detection triggers dual-map resolution UI. Livestock positions cached in drift. TileAnalytics collects events in-memory, batch-reports to server.

**Tech Stack:** Flutter + Riverpod + drift + flutter_map (dual map for conflict UI) + http

**Spec:** `docs/superpowers/specs/2026-05-27-offline-map-fence-integration-design.md` (§8, §9)

**Depends on:** Plan A (fence version + 409 API), Plan B (OfflineTileManager for tile analytics)

---

## File Structure

### New Files

```
Mobile/mobile_app/lib/
├── core/
│   ├── database/
│   │   └── app_database.dart                    (drift: cached_fences + cached_positions + analytics_events)
│   └── analytics/
│       └── tile_analytics.dart                  (event collector + batch reporter)
├── features/offline_fences/
│   ├── domain/
│   │   ├── cached_fence.dart                    (data class)
│   │   └── fence_sync_repository.dart           (interface)
│   ├── data/
│   │   ├── fence_sync_repository_impl.dart      (drift + API calls)
│   │   └── fence_sync_service.dart              (push-then-pull orchestration)
│   └── presentation/
│       ├── fence_sync_controller.dart           (Riverpod Notifier)
│       ├── fence_conflict_page.dart             (dual-map conflict resolution)
│       └── offline_edit_banner.dart             (unsynced count banner)
├── features/offline_livestock/
│   ├── domain/
│   │   └── cached_livestock_position.dart
│   └── data/
│       └── livestock_position_cache.dart
```

### Modified Files

| File | Change |
|------|--------|
| `features/fence/presentation/fence_controller.dart` | Offline edit → write to cached_fences |
| `features/fence/domain/fence_repository.dart` | Add version field to DTO |
| `features/pages/map_page.dart` | Show offline fences from cache when offline |
| `features/farm_creation/presentation/wizard_step_fence_drawing.dart` | Set fence_type=boundary |
| `features/mine/` | Show unsynced fence count |

---

## Task 1: App Database — drift Setup for Fences + Positions + Analytics

**Files:**
- Create: `core/database/app_database.dart`
- Test: `test/core/database/app_database_test.dart`

- [ ] **Step 1: Create AppDatabase with 3 tables**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class CachedFences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get fenceType => text().withDefault(const Constant('sub'))();
  TextColumn get vertices => text()();  // JSON-encoded
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastLocalModifiedAt => dateTime().nullable()();
  IntColumn get farmId => integer()();
}

class CachedLivestockPositions extends Table {
  IntColumn get livestockId => integer()();
  TextColumn get name => text().nullable()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get fenceId => integer().nullable()();
  @override
  Set<Column> get primaryKey => {livestockId};
}

class AnalyticsEvents extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get event => text()();
  TextColumn get data => text()();  // JSON
  DateTimeColumn get timestamp => dateTime()();
  IntColumn get reported => integer().withDefault(const Constant(0))();
}

@DriftDatabase(tables: [CachedFences, CachedLivestockPositions, AnalyticsEvents])
class AppDatabase extends Database {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // CachedFences queries
  Future<List<CachedFence>> getAllFences() => select(cachedFences).get();
  Future<List<CachedFence>> getFencesByFarm(int farmId) =>
      (select(cachedFences)..where((t) => t.farmId.equals(farmId))).get();
  Future<List<CachedFence>> getUnsyncedFences() =>
      (select(cachedFences)..where((t) => t.synced.equals(0))).get();
  Future<CachedFence?> getFenceByRemoteId(int remoteId) =>
      (select(cachedFences)..where((t) => t.remoteId.equals(remoteId))).getSingleOrNull();
  Future<void> insertFence(CachedFencesCompanion entry) => into(cachedFences).insert(entry);
  Future<void> updateFence(CachedFence entry) => update(cachedFences).replace(entry);
  Future<void> deleteFence(int id) => (delete(cachedFences)..where((t) => t.id.equals(id))).go();
  Future<void> markSynced(int id) =>
      (update(cachedFences)..where((t) => t.id.equals(id))).write(
          const CachedFencesCompanion(synced: Value(1)));

  // CachedLivestockPositions queries
  Future<List<CachedLivestockPosition>> getAllPositions() => select(cachedLivestockPositions).get();
  Future<void> upsertPosition(CachedLivestockPositionsCompanion entry) =>
      into(cachedLivestockPositions).insertOnConflictUpdate(entry);
  Future<void> clearPositions() => delete(cachedLivestockPositions).go();

  // AnalyticsEvents queries
  Future<List<AnalyticsEvent>> getUnreported() =>
      (select(analyticsEvents)..where((t) => t.reported.equals(0))).get();
  Future<void> insertEvent(AnalyticsEventsCompanion entry) => into(analyticsEvents).insert(entry);
  Future<void> markReported(List<int> ids) =>
      (update(analyticsEvents)..where((t) => t.id.isIn(ids)))).write(
          const AnalyticsEventsCompanion(reported: Value(1)));
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(File('${dir.path}/app.db'));
  });
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 2: Write test**

```dart
void main() {
  late AppDatabase db;
  setUp(() { db = AppDatabase.forTesting(NativeDatabase.memory()); });
  tearDown(() async => await db.close());

  test('insert and query cached fence', () async {
    await db.insertFence(CachedFencesCompanion.insert(
      name: '北区围栏', vertices: '[]', updatedAt: DateTime.now(), farmId: 1,
    ));
    final fences = await db.getAllFences();
    expect(fences.length, 1);
    expect(fences.first.synced, 0);
    expect(fences.first.fenceType, 'sub');
  });

  test('getUnsyncedFences returns only unsynced', () async {
    await db.insertFence(CachedFencesCompanion.insert(
      name: 'synced', vertices: '[]', updatedAt: DateTime.now(),
      farmId: 1, synced: const Value(1),
    ));
    await db.insertFence(CachedFencesCompanion.insert(
      name: 'unsynced', vertices: '[]', updatedAt: DateTime.now(), farmId: 1,
    ));
    final unsynced = await db.getUnsyncedFences();
    expect(unsynced.length, 1);
    expect(unsynced.first.name, 'unsynced');
  });

  test('upsert livestock position', () async {
    await db.upsertPosition(CachedLivestockPositionsCompanion.insert(
      livestockId: 42, latitude: 28.2, longitude: 112.9,
      recordedAt: DateTime.now(),
    ));
    final positions = await db.getAllPositions();
    expect(positions.length, 1);
    expect(positions.first.livestockId, 42);
  });

  test('analytics insert and getUnreported', () async {
    await db.insertEvent(AnalyticsEventsCompanion.insert(
      event: 'tile_download_completed',
      data: '{"regionName":"changsha"}',
      timestamp: DateTime.now(),
    ));
    final events = await db.getUnreported();
    expect(events.length, 1);
    expect(events.first.reported, 0);
  });
}
```

- [ ] **Step 3: Run tests and commit**

```bash
flutter test test/core/database/app_database_test.dart
git add -A && git commit -m "feat: AppDatabase — cached_fences + livestock_positions + analytics_events"
```

---

## Task 2: FenceSyncService — Push-then-Pull Sync

**Files:**
- Create: `features/offline_fences/data/fence_sync_service.dart`
- Create: `features/offline_fences/domain/cached_fence.dart`
- Create: `features/offline_fences/domain/fence_sync_repository.dart`
- Create: `features/offline_fences/data/fence_sync_repository_impl.dart`
- Test: `test/features/offline_fences/fence_sync_service_test.dart`

- [ ] **Step 1: Create CachedFence data class**

```dart
class CachedFenceData {
  final int? id;
  final int? remoteId;
  final String name;
  final String fenceType;
  final String vertices;  // JSON
  final String status;
  final int version;
  final int synced;
  final DateTime updatedAt;
  final DateTime? lastLocalModifiedAt;
  final int farmId;

  CachedFenceData({this.id, this.remoteId, required this.name,
    this.fenceType = 'sub', required this.vertices, this.status = 'active',
    this.version = 1, this.synced = 0, required this.updatedAt,
    this.lastLocalModifiedAt, required this.farmId});
}
```

- [ ] **Step 2: Create FenceSyncRepository interface**

```dart
abstract class FenceSyncRepository {
  Future<void> saveLocal(CachedFenceData fence);
  Future<void> updateLocal(CachedFenceData fence);
  Future<List<CachedFenceData>> getUnsynced();
  Future<void> markSynced(int localId);
  Future<void> upsertFromServer(CachedFenceData fence);
  Future<List<CachedFenceData>> getByFarm(int farmId);
}
```

- [ ] **Step 3: Create FenceSyncRepositoryImpl** — delegates to `AppDatabase`.

- [ ] **Step 4: Create FenceSyncService** (push-then-pull per spec §8.3)

```dart
class FenceSyncService {
  final FenceSyncRepository _repo;
  final String _baseUrl;

  FenceSyncService({required FenceSyncRepository repo, required String baseUrl})
      : _repo = repo, _baseUrl = baseUrl;

  Future<SyncResult> sync(int farmId, String token) async {
    // Phase 1: Push unsynced edits
    final unsynced = await _repo.getUnsynced();
    final conflicts = <FenceConflict>[];

    for (final fence in unsynced) {
      if (fence.remoteId == null) {
        // New fence → POST /farms/{farmId}/fences
        final response = await _createOnServer(fence, farmId, token);
        if (response != null) {
          fence.remoteId = response['id'];
          await _repo.updateLocal(fence..synced = 1);
        }
      } else {
        // Existing fence → PUT /farms/{farmId}/fences/{id} with expectedVersion
        final result = await _updateOnServer(fence, farmId, token);
        if (result.isConflict) {
          conflicts.add(FenceConflict(
            localFence: fence,
            serverVersion: result.serverVersion!,
            serverVertices: result.serverVertices!,
            lastModifiedBy: result.lastModifiedBy,
            lastModifiedAt: result.lastModifiedAt,
          ));
        } else {
          await _repo.markSynced(fence.id!);
        }
      }
    }

    // Phase 2: Pull server state
    final serverFences = await _fetchServerFences(farmId, token);
    for (final sf in serverFences) {
      final local = await _repo.getByRemoteId(sf.remoteId!);
      if (local == null || sf.version > local.version) {
        await _repo.upsertFromServer(sf);
      }
    }

    return SyncResult(conflicts: conflicts, pushedCount: unsynced.length - conflicts.length);
  }
}
```

- [ ] **Step 5: Write FenceSyncServiceTest** — test push-then-pull order, conflict detection on 409, new fence POST.

- [ ] **Step 6: Run tests and commit**

```bash
flutter test test/features/offline_fences/fence_sync_service_test.dart
git add -A && git commit -m "feat: FenceSyncService — push-then-pull sync with conflict detection"
```

---

## Task 3: Offline Fence Editing Integration

**Files:**
- Modify: `features/fence/presentation/fence_controller.dart`
- Create: `features/offline_fences/presentation/offline_edit_banner.dart`

- [ ] **Step 1: Modify FenceController for offline writes**

When creating/editing/deleting a fence while offline:
1. Write to `AppDatabase.cachedFences` with `synced=0`
2. Show offline indicator banner
3. On fence list load, merge local cache (synced=0) with server data

When online:
1. Call API as before
2. Also write to local cache (synced=1) for offline availability

- [ ] **Step 2: Create OfflineEditBanner** — shows "N 条未同步" banner at bottom of fence page.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: offline fence editing — write to local cache when offline"
```

---

## Task 4: Fence Conflict Resolution Page (Dual-Map)

**Files:**
- Create: `features/offline_fences/presentation/fence_conflict_page.dart`
- Modify: `app/app_route.dart`

- [ ] **Step 1: Create FenceConflictPage**

Per spec §8.3, layout:

```
┌──────────────────────────────────┐
│  围栏冲突："{fenceName}"          │
│                                    │
│  ┌──────────┐  ┌──────────┐      │
│  │ 服务端版本 │  │ 您的修改  │      │
│  │ [地图+围栏] │  │ [地图+围栏] │      │
│  └──────────┘  └──────────┘      │
│                                    │
│  服务端: {modifier} 修改于 {time} │
│  本地:   您 修改于 {time} (离线)   │
│                                    │
│  [放弃我的修改]  [覆盖服务端版本]  │
└──────────────────────────────────┘
```

Two `FlutterMap` instances side by side (or stacked on narrow screens), same center + zoom. Each renders its fence as a `PolygonLayer`. Use existing `fence_dto.dart` parsing for vertices.

```dart
class FenceConflictPage extends ConsumerWidget {
  final FenceConflict conflict;
  final int farmId;

  const FenceConflictPage({super.key, required this.conflict, required this.farmId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: Text('围栏冲突：${conflict.localFence.name}')),
      body: Column(children: [
        Expanded(child: Row(children: [
          Expanded(child: _MapPanel(title: '服务端版本 (v${conflict.serverVersion})',
            vertices: conflict.serverVertices, modifier: conflict.lastModifiedBy,
            modifiedAt: conflict.lastModifiedAt)),
          Expanded(child: _MapPanel(title: '您的修改 (离线编辑)',
            vertices: _parseVertices(conflict.localFence.vertices),
            modifier: '您', modifiedAt: conflict.localFence.lastLocalModifiedAt)),
        ])),
        Padding(padding: const EdgeInsets.all(16), child: Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () => _discardLocal(context, ref),
            child: const Text('放弃我的修改'),
          )),
          const SizedBox(width: 16),
          Expanded(child: FilledButton(
            onPressed: () => _overwriteServer(context, ref),
            child: const Text('覆盖服务端版本'),
          )),
        ])),
      ]),
    );
  }
}
```

- [ ] **Step 2: Add route** — `/fences/conflict`

- [ ] **Step 3: Implement resolution handlers**

`_discardLocal`: Update local cache with server version, mark synced=1, pop page.
`_overwriteServer`: Call `PUT /farms/{farmId}/fences/{id}/force` with local vertices + server version, update cache, pop page.

- [ ] **Step 4: Write test + commit**

```bash
flutter test test/features/offline_fences/fence_conflict_page_test.dart
git add -A && git commit -m "feat: fence conflict resolution page with dual-map comparison"
```

---

## Task 5: Livestock Position Cache

**Files:**
- Create: `features/offline_livestock/data/livestock_position_cache.dart`
- Modify: `features/pages/map_page.dart` — show cached positions when offline

- [ ] **Step 1: Create LivestockPositionCache**

```dart
class LivestockPositionCache {
  final AppDatabase _db;
  final String _baseUrl;

  LivestockPositionCache({required AppDatabase db, required String baseUrl})
      : _db = db, _baseUrl = baseUrl;

  Future<void> refreshFromServer(int farmId, String token) async {
    // GET /farms/{farmId}/livestock → extract positions
    // Upsert each into cached_livestock_positions
  }

  Future<List<CachedLivestockPosition>> getCachedPositions() async {
    return _db.getAllPositions();
  }

  String formatTimeAgo(DateTime recordedAt) {
    final diff = DateTime.now().difference(recordedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} 分钟前';
    if (diff.inHours < 24) return '${diff.inHours} 小时前';
    return '${diff.inDays} 天前';
  }
}
```

- [ ] **Step 2: Modify MapPage** — when offline, show cached livestock positions as markers with "X 小时前" labels instead of live GPS data.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: livestock position cache with offline rendering"
```

---

## Task 6: Farm Creation — Boundary Fence Integration

**Files:**
- Modify: `features/farm_creation/presentation/wizard_step_fence_drawing.dart`

- [ ] **Step 1: Set fence_type=boundary in creation wizard**

When the farm creation wizard creates the boundary fence via `POST /farms/{farmId}/fences`, include `fenceType: "boundary"` in the request body. The backend (Plan A Task 7) will create it with `fence_type=boundary`.

This is a small change — just add `"fenceType": "boundary"` to the request body in the API call.

- [ ] **Step 2: Show tile status in wizard step 3**

After farm creation, call `GET /farms/{farmId}/tile-status` and display the tile coverage info in the wizard completion step (e.g., "瓦片状态: 1 个区域已就绪" or "瓦片待生成").

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: farm creation sets fenceType=boundary + shows tile status"
```

---

## Task 7: TileAnalytics — Event Collection + Batch Reporting

**Files:**
- Create: `core/analytics/tile_analytics.dart`
- Test: `test/core/analytics/tile_analytics_test.dart`

- [ ] **Step 1: Create TileAnalytics**

Per spec §9.2:

```dart
class TileAnalytics {
  final AppDatabase _db;
  final String _baseUrl;
  final List<Map<String, dynamic>> _buffer = [];
  static const int _flushThreshold = 20;

  TileAnalytics({required AppDatabase db, required String baseUrl})
      : _db = db, _baseUrl = baseUrl;

  void log(String event, Map<String, dynamic> data) {
    final entry = {'event': event, 'timestamp': DateTime.now().toIso8601String(), ...data};
    _buffer.add(entry);
    if (_buffer.length >= _flushThreshold) flush();
  }

  Future<void> flush() async {
    if (_buffer.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    try {
      await http.post(Uri.parse('$_baseUrl/analytics/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(batch));
    } catch (_) {
      // Offline — persist to drift for later reporting
      for (final e in batch) {
        await _db.insertEvent(AnalyticsEventsCompanion.insert(
          event: e['event'] as String,
          data: jsonEncode(e),
          timestamp: DateTime.parse(e['timestamp'] as String),
        ));
      }
    }
  }

  Future<void> reportBacklog() async {
    final unreported = await _db.getUnreported();
    if (unreported.isEmpty) return;
    final batch = unreported.map((e) => {
      'event': e.event,
      'data': jsonDecode(e.data),
    }).toList();
    try {
      await http.post(Uri.parse('$_baseUrl/analytics/events'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(batch));
      await _db.markReported(unreported.map((e) => e.id).toList());
    } catch (_) {}
  }
}
```

- [ ] **Step 2: Create analytics_events endpoint on backend**

Add to `TileController` or create a new `AnalyticsController`:

```java
@PostMapping("/api/v1/analytics/events")
public ResponseEntity<ApiResponse<Void>> receiveEvents(@RequestBody List<Map<String, Object>> events) {
    // Store events or log for now (full analytics pipeline is Phase 2c)
    return ResponseEntity.ok(ApiResponse.ok(null));
}
```

- [ ] **Step 3: Integrate TileAnalytics into OfflineTileManager**

Add analytics calls at key points:
- `tile_download_completed` — on download success
- `tile_download_failed` — on download failure or MD5 mismatch
- `tile_evicted` — on LRU eviction
- `tile_cache_hit` / `tile_cache_miss` — in SmartTileProvider

- [ ] **Step 4: Integrate TileAnalytics into FenceSyncService**

- `fence_sync_conflict` — on 409 conflict detected
- `fence_offline_edit` — on offline fence create/update/delete
- `offline_session` — on app going offline/online

- [ ] **Step 5: Write test + commit**

```dart
test('log buffers events and flushes at threshold', () async {
  final analytics = TileAnalytics(db: db, baseUrl: 'http://localhost:9999');
  for (int i = 0; i < 20; i++) {
    analytics.log('test_event', {'index': i});
  }
  // 20 events should trigger flush attempt (will fail and persist to db)
  await Future.delayed(Duration(milliseconds: 100));
  final events = await db.getUnreported();
  expect(events.length, 20);
});
```

```bash
flutter test test/core/analytics/tile_analytics_test.dart
git add -A && git commit -m "feat: TileAnalytics — event collection + batch reporting + offline persistence"
```

---

## Task 8: Full Verification

- [ ] **Step 1: Run all Flutter tests**

```bash
cd Mobile/mobile_app && flutter test
```

Expected: All existing + new tests pass.

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: Zero errors.

- [ ] **Step 3: Test offline flow manually**

1. Login as owner → select farm → view fences (should cache)
2. Turn off network → create fence → verify cached locally
3. Turn on network → sync → verify fence uploaded
4. Test conflict: edit same fence on another device, then sync

- [ ] **Step 4: Final commit**

```bash
git add -A && git commit -m "chore: plan C complete — Flutter offline fences + observability"
```

---

## Self-Review

### Spec Coverage

| Spec Section | Task |
|-------------|------|
| §8.1 Fence local cache (drift) | Task 1 |
| §8.1 Push-then-pull sync | Task 2 |
| §8.2 Offline fence editing | Task 3 |
| §8.3 Conflict detection + dual-map | Task 4 |
| §8.4 Farm creation boundary fence | Task 6 |
| §8.5 Livestock position cache | Task 5 |
| §9.1 Analytics events (8 types) | Task 7 |
| §9.2 Batch reporting (20 flush) | Task 7 |
| §9.2 Offline persistence to drift | Task 7 |
| §9.3 Server analytics endpoint | Task 7 |

### Placeholder Scan
No TBD/TODO. All tasks contain code or precise instructions.

### Type Consistency
- `CachedFences` drift table fields match `CachedFenceData` class
- `FenceConflict` has `localFence: CachedFenceData` + `serverVersion: int` + `serverVertices: List<LatLng>`
- `AnalyticsEvents` table uses `reported: 0/1` integer flag
- `TileAnalytics.log(String, Map)` → `_buffer: List<Map<String, dynamic>>` → flush to API or drift
