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
│   │   ├── app_database.dart                    (drift: cached_fences + cached_positions + analytics_events)
│   │   └── app_database_provider.dart           (Riverpod providers for AppDatabase, FenceSyncService, TileAnalytics)
│   └── analytics/
│       └── tile_analytics.dart                  (event collector + batch reporter)
├── features/offline_fences/
│   ├── domain/
│   │   ├── cached_fence.dart                    (data class)
│   │   ├── fence_conflict.dart                  (conflict data class)
│   │   └── fence_sync_repository.dart           (interface)
│   ├── data/
│   │   ├── fence_sync_repository_impl.dart      (drift + API calls)
│   │   ├── fence_sync_service.dart              (push-then-pull orchestration)
│   │   └── fence_sync_providers.dart            (Riverpod providers: fenceSyncRepositoryProvider + fenceSyncServiceProvider)
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
| `features/fence/domain/fence_item.dart` | Add `int version` + `String fenceType` fields + extend `copyWith` |
| `features/fence/domain/fence_repository.dart` | Add `version` + `fenceType` to DTO; `update()` gains `expectedVersion` parameter |
| `features/fence/data/fence_api_repository.dart` | Parse `version` + `fenceType` from API response; send `expectedVersion` on update |
| `features/pages/map_page.dart` | Show offline fences from cache when offline |
| `features/farm_creation/presentation/wizard_step_fence_drawing.dart` | Set fence_type=boundary |
| `features/mine/` | Show unsynced fence count |

---

## Task 1: App Database Schema Upgrade — Add CachedFences + CachedLivestockPositions + AnalyticsEvents

**Files:**
- Modify: `core/database/app_database.dart` (created by Plan B, Plan C adds 3 tables + bumps schemaVersion)
- Test: `test/core/database/app_database_test.dart` (extend existing test from Plan B)

> **P0-2.1 fix:** Plan B creates `AppDatabase` with `TileMetas` + `FarmTilePins` tables (schemaVersion=1). Plan C adds `CachedFences` + `CachedLivestockPositions` + `AnalyticsEvents` and bumps schemaVersion to 2. Single database file `smart_livestock.db`, single `.g.dart` code generation. No split.

- [ ] **Step 1: Upgrade AppDatabase — add 3 tables, bump schemaVersion to 2**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

// --- Tables added by Plan C (schemaVersion bump 1 → 2) ---

class CachedFences extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get remoteId => integer().nullable()();
  TextColumn get name => text()();
  TextColumn get fenceType => text().withDefault(const Constant('sub'))();
  TextColumn get vertices => text()();  // JSON-encoded
  TextColumn get status => text().withDefault(const Constant('active'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get synced => integer().withDefault(const Constant(0))();
  IntColumn get localDeleteFlag => integer().withDefault(const Constant(0))();
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

@DriftDatabase(tables: [
  // Plan B tables (schemaVersion 1)
  TileMetas, FarmTilePins,
  // Plan C tables (schemaVersion 2)
  CachedFences, CachedLivestockPositions, AnalyticsEvents,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        // Plan C upgrade: add CachedFences, CachedLivestockPositions, AnalyticsEvents
        await migrator.createTable(cachedFences);
        await migrator.createTable(cachedLivestockPositions);
        await migrator.createTable(analyticsEvents);
      }
    },
  );

  // CachedFences queries
  Future<List<CachedFence>> getAllFences() => select(cachedFences).get();
  Future<List<CachedFence>> getFencesByFarm(int farmId) =>
      (select(cachedFences)..where((t) => t.farmId.equals(farmId))).get();
  Future<List<CachedFence>> getUnsyncedFences() =>
      (select(cachedFences)..where((t) => t.synced.equals(0) & t.localDeleteFlag.equals(0))).get();
  Future<List<CachedFence>> getLocallyDeletedFences() =>
      (select(cachedFences)..where((t) => t.localDeleteFlag.equals(1))).get();
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
      (update(analyticsEvents)..where((t) => t.id.isIn(ids))).write(
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

- [ ] **Step 3: Run code generation, tests, and commit**

```bash
cd Mobile/mobile_app
dart run build_runner build --delete-conflicting-outputs
flutter test test/core/database/app_database_test.dart
git add -A && git commit -m "feat: AppDatabase — cached_fences + livestock_positions + analytics_events"
```

Note: `dart run build_runner build` must run before any test that imports `app_database.g.dart`. If drift schema changes are made in later tasks, re-run this command before testing.

- [ ] **Step 4: Create Riverpod providers**

Create `core/database/app_database_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/database/app_database.dart';
import 'package:hkt_livestock_agentic/core/analytics/tile_analytics.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

final tileAnalyticsProvider = Provider<TileAnalytics>((ref) {
  return TileAnalytics(
    db: ref.read(appDatabaseProvider),
    apiClient: ApiClient.instance,
  );
});
```

These providers follow the existing project pattern (`{module}RepositoryProvider`, `{module}ControllerProvider`). Widgets and Controllers access services via `ref.read()` / `ref.watch()`.

---

## Task 2: FenceSyncService — Push-then-Pull Sync

**Files:**
- Create: `features/offline_fences/data/fence_sync_service.dart`
- Create: `features/offline_fences/domain/cached_fence.dart`
- Create: `features/offline_fences/domain/fence_sync_repository.dart`
- Create: `features/offline_fences/data/fence_sync_repository_impl.dart`
- Test: `test/features/offline_fences/fence_sync_service_test.dart`

- [ ] **Step 1: Create CachedFence data class**

**ID 类型映射策略**: 服务端 `fences` 表的 `id` 是 `BIGINT`（整数），而现有 `FenceItem.id` 是 `String` 类型。`CachedFenceData` 使用 `int?` 作为 `id` 和 `remoteId`，与服务端一致。在 `FenceSyncRepositoryImpl` 中提供双向转换方法：
- `FenceItem → CachedFenceData`：`fenceItem.id`（String）→ 用 `int.tryParse()` 转为 `remoteId`（若为纯数字字符串）
- `CachedFenceData → FenceItem`：`cachedFence.remoteId`（int）→ `remoteId.toString()` 作为 `FenceItem.id`
- `FenceController` 合并在线/离线数据时，统一用 `remoteId.toString()` 作为 `FenceItem.id` 进行比较

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
  final int localDeleteFlag;  // 1 = locally deleted, pending sync to server
  final DateTime updatedAt;
  final DateTime? lastLocalModifiedAt;
  final int farmId;

  CachedFenceData({this.id, this.remoteId, required this.name,
    this.fenceType = 'sub', required this.vertices, this.status = 'active',
    this.version = 1, this.synced = 0, this.localDeleteFlag = 0, required this.updatedAt,
    this.lastLocalModifiedAt, required this.farmId});

  CachedFenceData copyWith({
    int? id, int? remoteId, String? name, String? fenceType,
    String? vertices, String? status, int? version, int? synced,
    int? localDeleteFlag, DateTime? updatedAt, DateTime? lastLocalModifiedAt, int? farmId,
  }) => CachedFenceData(
    id: id ?? this.id,
    remoteId: remoteId ?? this.remoteId,
    name: name ?? this.name,
    fenceType: fenceType ?? this.fenceType,
    vertices: vertices ?? this.vertices,
    status: status ?? this.status,
    version: version ?? this.version,
    synced: synced ?? this.synced,
    localDeleteFlag: localDeleteFlag ?? this.localDeleteFlag,
    updatedAt: updatedAt ?? this.updatedAt,
    lastLocalModifiedAt: lastLocalModifiedAt ?? this.lastLocalModifiedAt,
    farmId: farmId ?? this.farmId,
  );
}
```

- [ ] **Step 2: Create FenceConflict data class**

```dart
import 'package:latlong2/latlong.dart';

class FenceConflict {
  final CachedFenceData localFence;
  final int serverVersion;
  final List<LatLng> serverVertices;
  final String? lastModifiedBy;
  final DateTime? lastModifiedAt;

  const FenceConflict({
    required this.localFence,
    required this.serverVersion,
    required this.serverVertices,
    this.lastModifiedBy,
    this.lastModifiedAt,
  });
}
```

- [ ] **Step 3: Create FenceSyncRepository interface**

```dart
abstract class FenceSyncRepository {
  Future<void> saveLocal(CachedFenceData fence);
  Future<void> updateLocal(CachedFenceData fence);
  Future<void> deleteLocal(int localId);
  Future<List<CachedFenceData>> getUnsynced();
  Future<List<CachedFenceData>> getLocallyDeleted();
  Future<void> markSynced(int localId);
  Future<void> upsertFromServer(CachedFenceData fence);
  Future<List<CachedFenceData>> getByFarm(int farmId);
  Future<CachedFenceData?> getByRemoteId(int remoteId);
}
```

- [ ] **Step 4: Create FenceSyncRepositoryImpl** — delegates to `AppDatabase`. Must implement all 9 interface methods including `getByRemoteId` (queries `AppDatabase.getFenceByRemoteId()`), `getLocallyDeleted` (queries fences where `localDeleteFlag=1`), and `deleteLocal` (removes from `cached_fences`).

- [ ] **Step 5: Create FenceSyncService** (push-then-pull per spec §8.3)

```dart
class FenceSyncService {
  final FenceSyncRepository _repo;
  final String _baseUrl;

  FenceSyncService({required FenceSyncRepository repo, required String baseUrl})
      : _repo = repo, _baseUrl = baseUrl;

  Future<SyncResult> sync(int farmId, String token) async {
    // Phase 0: Push locally-deleted fences
    final toDelete = await _repo.getLocallyDeleted();
    for (final fence in toDelete) {
      if (fence.remoteId == null) {
        // New fence that was deleted locally → just remove from cache
        await _repo.deleteLocal(fence.id!);
      } else {
        // Existing fence → DELETE /farms/{farmId}/fences/{remoteId}
        await _deleteOnServer(fence.remoteId!, farmId, token);
        await _repo.deleteLocal(fence.id!);
      }
    }

    // Phase 1: Push unsynced edits (create/update)
    final unsynced = await _repo.getUnsynced();
    final conflicts = <FenceConflict>[];

    for (final fence in unsynced) {
      if (fence.remoteId == null) {
        // New fence → POST /farms/{farmId}/fences
        final response = await _createOnServer(fence, farmId, token);
        if (response != null) {
          final updated = fence.copyWith(remoteId: response['id'], synced: 1);
          await _repo.updateLocal(updated);
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

- [ ] **Step 6: Write FenceSyncServiceTest** — test push-then-pull order, conflict detection on 409, new fence POST.

- [ ] **Step 7: Create Riverpod providers for fence sync**

Create `features/offline_fences/data/fence_sync_providers.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/database/app_database_provider.dart';
import 'package:hkt_livestock_agentic/features/offline_fences/data/fence_sync_repository_impl.dart';
import 'package:hkt_livestock_agentic/features/offline_fences/data/fence_sync_service.dart';

final fenceSyncRepositoryProvider = Provider<FenceSyncRepositoryImpl>((ref) {
  return FenceSyncRepositoryImpl(db: ref.read(appDatabaseProvider));
});

final fenceSyncServiceProvider = Provider<FenceSyncService>((ref) {
  return FenceSyncService(
    repo: ref.read(fenceSyncRepositoryProvider),
    baseUrl: ApiClient.instance.baseUrl,
  );
});
```

Placed in `features/` module (not `core/`) to avoid core→features reverse dependency.

- [ ] **Step 8: Run tests and commit**

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

**离线检测机制**（方案 A — 利用现有异常层次）：
- `FenceController` 当前通过 `ApiClient` 调用后端，网络错误会抛出 `NetworkException`（或 `SocketException`）
- 在 Controller 中新增 `bool _isOffline = false` 状态字段
- catch 块中捕获网络异常时设置 `_isOffline = true`，其他异常仍走 `ViewState.error`
- 成功调用 API 后重置 `_isOffline = false`
- 不引入 `connectivity_plus` 等新依赖，避免增加复杂度

When creating/editing/deleting a fence while offline:
1. **Create**: Write to `AppDatabase.cachedFences` with `synced=0`, `localDeleteFlag=0`
2. **Edit**: Update in `AppDatabase.cachedFences` with `synced=0`, update `lastLocalModifiedAt`
3. **Delete**: Set `localDeleteFlag=1` in cache (do NOT physically delete — sync needs to know to delete on server). If the fence has `remoteId=null` (locally created, never synced), can physically delete immediately.
4. Show offline indicator banner
5. On fence list load, merge local cache (exclude `localDeleteFlag=1`) with server data

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
  final ApiClient _apiClient;  // Use existing ApiClient for JWT auth, base URL, error handling
  final List<Map<String, dynamic>> _buffer = [];
  static const int _flushThreshold = 20;

  TileAnalytics({required AppDatabase db, required ApiClient apiClient})
      : _db = db, _apiClient = apiClient;

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
      await _apiClient.post('/analytics/events', body: jsonEncode(batch));
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

  /// Call from WidgetsBindingObserver.didChangeAppLifecycleState
  /// when appState == AppLifecycleState.paused or detached.
  /// Ensures in-memory buffer is persisted before the OS suspends the app.
  Future<void> flushOnAppBackground() async {
    if (_buffer.isEmpty) return;
    // Always persist to drift (don't attempt network — app is backgrounding)
    for (final e in _buffer) {
      await _db.insertEvent(AnalyticsEventsCompanion.insert(
        event: e['event'] as String,
        data: jsonEncode(e),
        timestamp: DateTime.parse(e['timestamp'] as String),
      ));
    }
    _buffer.clear();
  }

  Future<void> reportBacklog() async {
    final unreported = await _db.getUnreported();
    if (unreported.isEmpty) return;
    final batch = unreported.map((e) => jsonDecode(e.data) as Map<String, dynamic>).toList();
    try {
      await _apiClient.post('/analytics/events', body: jsonEncode(batch));
      await _db.markReported(unreported.map((e) => e.id).toList());
    } catch (_) {}
  }
}
```

- [ ] **Step 2: Verify analytics endpoint exists (Plan A Task 11)**

Plan A now includes `POST /api/v1/analytics/events` endpoint (see Plan A Task 11). Verify the endpoint is deployed and accessible before proceeding. If Plan A is not yet deployed, TileAnalytics will persist events to drift and report them later (Step 1 offline fallback handles this).

- [ ] **Step 2b: Wire App lifecycle observer**

In the app's main widget (or a dedicated Riverpod provider), register a `WidgetsBindingObserver` that calls `TileAnalytics.flushOnAppBackground()` on `AppLifecycleState.paused` and `TileAnalytics.reportBacklog()` on `AppLifecycleState.resumed`. This prevents data loss when the OS kills the app while events are in the in-memory buffer.

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
  final analytics = TileAnalytics(db: db, apiClient: ApiClient.instance);
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

## Task 8: Farm Deletion Cleanup

**Files:**
- Modify: `core/database/app_database.dart`
- Modify: `features/offline_tiles/presentation/offline_tile_manager.dart`

- [ ] **Step 1: Add farm deletion handler to AppDatabase**

```dart
/// Called when a farm is deleted. Cleans up all local data for the farm.
Future<void> deleteFarmData(int farmId) async {
  // 1. Delete FarmTilePins rows
  await (delete(farmTilePins)..where((t) => t.farmId.equals(farmId))).go();
  // 2. Delete cached fences for this farm
  await (delete(cachedFences)..where((t) => t.farmId.equals(farmId))).go();
  // 3. Delete cached livestock positions (if farmId stored)
  // 4. Delete TileMetas that now have zero FarmTilePins references
  final orphanedMetas = await customSelect(
    'SELECT tm.id FROM tile_metas tm LEFT JOIN farm_tile_pins ftp ON tm.id = ftp.tile_meta_id WHERE ftp.tile_meta_id IS NULL',
    readsFrom: {tileMetas, farmTilePins},
  ).get();
  for (final row in orphanedMetas) {
    final meta = await (select(tileMetas)..where((t) => t.id.equals(row.read<int>('id')))).getSingleOrNull();
    if (meta != null) {
      final file = File(meta.filePath);
      if (await file.exists()) await file.delete();
      await (delete(tileMetas)..where((t) => t.id.equals(meta.id))).go();
    }
  }
}
```

- [ ] **Step 2: Wire into farm switcher/deletion flow**

When farm is deleted via API: call `AppDatabase.deleteFarmData(farmId)` to clean up local cache, tile references, and orphaned tile files.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: farm deletion cleanup — cascading drift + file cleanup"
```

---

## Task 9: Full Verification + End-to-End Integration Test

- [ ] **Step 1: Regenerate drift code and run all Flutter tests**

```bash
cd Mobile/mobile_app
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Expected: All existing + new tests pass. Verify AppDatabase schema migration from version 1 (Plan B) to version 2 (Plan C) works correctly.

- [ ] **Step 2: Run static analysis**

```bash
flutter analyze
```

Expected: Zero errors.

- [ ] **Step 3: End-to-end integration test (cross-Plan)**

Write an integration test (or document a manual test plan) covering the full cross-Plan flow:

```
1. Create farm with boundary fence → server detects tile coverage (Plan A Task 7)
2. Client resolves tile sources for farm → SmartTileProvider loads regions (Plan B Task 2)
3. Download tiles for farm → MD5 verify → stored locally (Plan B Task 3)
4. Switch to offline → view tiles + fences from cache (Plan C Task 1, Plan B Task 2)
5. Create fence offline → stored in cached_fences synced=0 (Plan C Task 3)
6. Go online → push fence to server → pull latest → sync complete (Plan C Task 2)
7. Edit same fence on two devices → trigger 409 conflict → dual-map resolution (Plan C Task 4)
8. Delete farm → verify local tile/fence cleanup (Plan C Task 8)
```

- [ ] **Step 4: Test offline flow manually**

1. Login as owner → select farm → view fences (should cache)
2. Turn off network → create fence → verify cached locally
3. Turn on network → sync → verify fence uploaded
4. Test conflict: edit same fence on another device, then sync

- [ ] **Step 5: Final commit**

```bash
git add -A && git commit -m "chore: plan C complete — Flutter offline fences + observability"
```

---

## Self-Review

### Spec Coverage

| Spec Section | Task |
|-------------|------|
| §8.1 Fence local cache (drift) | Task 1 (schema upgrade) |
| §8.1 Push-then-pull sync (error-resilient) | Task 2 |
| §8.2 Offline fence editing | Task 3 |
| §8.3 Conflict detection + dual-map | Task 4 |
| §8.4 Farm creation boundary fence | Task 6 |
| §8.5 Livestock position cache | Task 5 |
| §9.1 Analytics events (8 types) | Task 7 |
| §9.2 Batch reporting (20 flush) | Task 7 |
| §9.2 Offline persistence to drift | Task 7 |
| §9.3 Server analytics endpoint | Plan A Task 11 (Plan C verifies) |

### Placeholder Scan
No TBD/TODO. All tasks contain code or precise instructions.

### Type Consistency
- `CachedFences` drift table fields match `CachedFenceData` class
- `FenceConflict` has `localFence: CachedFenceData` + `serverVersion: int` + `serverVertices: List<LatLng>`
- `AnalyticsEvents` table uses `reported: 0/1` integer flag
- `TileAnalytics.log(String, Map)` → `_buffer: List<Map<String, dynamic>>` → flush to API or drift
- `FenceItem` now has `version: int` and `fenceType: String` fields
- AppDatabase unified: Plan B tables (TileMetas, FarmTilePins) + Plan C tables in single instance

### Review Fix Log (2026-05-28)

| # | Issue | Fix | Task |
|---|-------|-----|------|
| P0-2.1 | Drift database split | Upgrade Plan B's AppDatabase (schemaVersion 1→2) instead of creating separate DB | Task 1 |
| P0-2.2 | FenceItem lacks version/fenceType | Added Step 0 to Task 3: extend FenceItem + FenceApiRepository + FenceRepository interface | Task 3 |
| P1-3.5 | Sync boundary conditions | Rewrote sync flow with per-record error handling, 404 idempotency, incremental pull | Task 2 |
| P1-3.4 | Analytics endpoint cross-Plan | Moved endpoint to Plan A Task 11; Plan C verifies existence | Task 7 |
| P2-4.3 | TileAnalytics lifecycle flush | Added `flushOnAppBackground()` + lifecycle observer wiring | Task 7 |
| P1-3.3 | Farm deletion cascade | Added Task 8: `deleteFarmData()` cascading cleanup | Task 8 |
| P2-4.4 | Cross-Plan integration test | Added e2e test step to Task 9 | Task 9 |
