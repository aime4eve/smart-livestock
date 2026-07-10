# Flutter Offline Tiles Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Enable Flutter client to dynamically resolve tile sources per farm, download MBTiles for offline use, manage local storage with LRU eviction + pin protection, and provide a tile management UI.

**Architecture:** SmartTileProvider gains dynamic region resolution via `GET /farms/{id}/tile-source`. OfflineTileManager handles foreground/background download, MD5 verification, pin/unpin, and LRU eviction. New `offline_tiles` feature module follows existing domain/data/presentation pattern.

**Tech Stack:** Flutter + Riverpod + flutter_map + http + sqlite3 (MBTiles) + drift (meta) + workmanager + wakelock_plus

**Spec:** `docs/superpowers/specs/2026-05-27-offline-map-fence-integration-design.md` (§7)

**Depends on:** Plan A (backend tile APIs must be deployed)

---

## File Structure

### New Files

```
Mobile/mobile_app/lib/
├── core/map/
│   ├── tile_source_resolver.dart
│   └── smart_tile_provider.dart          (modify)
├── features/offline_tiles/
│   ├── domain/
│   │   ├── tile_meta.dart
│   │   ├── tile_status.dart                   (TileStatus enum + data for getTileStatus response)
│   │   ├── local_tile_info.dart               (LocalTileInfo data class for getLocalTiles response)
│   │   └── offline_tile_repository.dart       (interface with method signatures)
│   ├── data/
│   │   ├── app_database.dart              (drift — unified, see Plan C for additional tables)
│   │   ├── offline_tile_repository_impl.dart
│   │   └── tile_downloader.dart
│   └── presentation/
│       ├── offline_tile_controller.dart
│       ├── offline_tile_manager.dart
│       └── offline_tile_management_page.dart
└── app/app_route.dart                    (modify: add route)
```

> **Note:** Task 8 (API Key Management) incrementally improves the existing `api_authorization` module (`features/api_authorization/` + `features/admin/presentation/api_auth_page.dart`) instead of creating new files. No new files added for this task.

### Modified Files

| File | Change |
|------|--------|
| `core/map/smart_tile_provider.dart` | Accept dynamic tile source list per farm |
| `pubspec.yaml` | Add drift, workmanager, wakelock_plus, crypto, path_provider |
| `features/farm_switcher/` | On farm switch, update tile sources + auto-pin |
| `app/app_route.dart` | Add `/settings/offline-maps` route |
| `features/api_authorization/data/api_authorization_api_repository.dart` | Add `createApiKey()` raw key return + `deleteApiKey()` two-step |
| `features/admin/presentation/api_auth_page.dart` | Add create dialog with one-time key display + copy button + revoke→delete two-step |
| `features/mine/` | Add "离线地图管理" entry |

---

## Task 1: Add Dependencies + Drift Setup

**Files:**
- Modify: `pubspec.yaml`
- Create: `core/database/app_database.dart`
- Test: `test/core/database/app_database_test.dart`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

```yaml
dependencies:
  drift: ^2.18
  sqlite3_flutter_libs: ^0.5.42   # Upgrade from ^0.5.28 (spec §7.5)
  path_provider: ^2.1.0
  path: ^1.9.0
  workmanager: ^0.5.2
  wakelock_plus: ^1.2
  crypto: ^3.0.3                  # Used for MD5 verification of downloaded MBTiles (spec §7.2)

dev_dependencies:
  drift_dev: ^2.18
  build_runner: ^2.4
```

Run: `cd Mobile/mobile_app && flutter pub get`

- [ ] **Step 2: Create AppDatabase (unified drift database — Plan B creates with TileMetas + FarmTilePins, Plan C adds CachedFences/CachedLivestockPositions/AnalyticsEvents via schema upgrade)**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class TileMetas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get regionName => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get md5 => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get status => text().withDefault(const Constant('downloading'))();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  DateTimeColumn get regionGeneratedAt => dateTime().nullable()();
}

/// Pin relationship table — replaces comma-separated farmIds/pinnedFarmIds strings.
/// Each row = one farm referencing one tile region. Solves:
/// - Concurrent pin/unpin safety (row-level locking instead of string rewrite)
/// - Accurate farm→region queries (no LIKE '%3%' matching '13')
/// - Cascading delete on farm removal (DELETE WHERE farmId = ?)
class FarmTilePins extends Table {
  IntColumn get farmId => integer()();
  IntColumn get tileMetaId => integer()();
  IntColumn get pinned => integer().withDefault(const Constant(0))();
  @override
  Set<Column> get primaryKey => {farmId, tileMetaId};
}

/// Unified AppDatabase — Plan B creates with schemaVersion=1 (TileMetas + FarmTilePins).
/// Plan C upgrades to schemaVersion=2, adding CachedFences + CachedLivestockPositions + AnalyticsEvents.
@DriftDatabase(tables: [TileMetas, FarmTilePins])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;  // Plan C will bump to 2

  Future<List<TileMeta>> getAllMetas() => select(tileMetas).get();
  Future<TileMeta?> getByName(String name) =>
      (select(tileMetas)..where((t) => t.regionName.equals(name))).getSingleOrNull();
  Future<void> insertMeta(TileMetasCompanion entry) => into(tileMetas).insert(entry);
  Future<void> updateMeta(TileMeta entry) => update(tileMetas).replace(entry);
  Future<void> deleteMeta(String name) =>
      (delete(tileMetas)..where((t) => t.regionName.equals(name))).go();

  // Pin queries — use FarmTilePins instead of string parsing
  Future<List<TileMeta>> getUnpinnedOldestFirst() {
    // Select TileMetas that have NO pinned FarmTilePins rows
    final query = select(tileMetas)
      ..where((t) => t.id.isNotInQuery(
        selectOnly(farmTilePins)..addColumns([farmTilePins.tileMetaId])
          ..where(farmTilePins.pinned.equals(1))
      ))
      ..orderBy([(t) => OrderingTerm.asc(t.lastAccessedAt)]);
    return query.get();
  }

  Future<List<TileMeta>> getByFarmId(int farmId) {
    final query = select(tileMetas).join([
      innerJoin(farmTilePins, farmTilePins.tileMetaId.equalsExp(tileMetas.id))
    ])..where(farmTilePins.farmId.equals(farmId));
    return query.map((row) => row.readTable(tileMetas)).get();
  }

  Future<void> pinFarmTile(int farmId, int tileMetaId) =>
      into(farmTilePins).insertOnConflictUpdate(
        FarmTilePinsCompanion.insert(farmId: farmId, tileMetaId: tileMetaId, pinned: const Value(1)),
      );
  Future<void> unpinFarmTile(int farmId, int tileMetaId) =>
      (update(farmTilePins)..where((t) => t.farmId.equals(farmId) & t.tileMetaId.equals(tileMetaId)))
        .write(const FarmTilePinsCompanion(pinned: Value(0)));
  Future<bool> isFarmPinned(int farmId, int tileMetaId) async {
    final row = await (select(farmTilePins)..where((t) =>
      t.farmId.equals(farmId) & t.tileMetaId.equals(tileMetaId) & t.pinned.equals(1)
    )).getSingleOrNull();
    return row != null;
  }
  Future<void> removeFarmReferences(int farmId) =>
      (delete(farmTilePins)..where((t) => t.farmId.equals(farmId))).go();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(File('${dir.path}/smart_livestock.db'));
  });
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Write drift test**

```dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/database/app_database.dart';

void main() {
  late AppDatabase db;
  setUp(() { db = AppDatabase.forTesting(NativeDatabase.memory()); });
  tearDown(() async => await db.close());

  test('insert and query tile meta', () async {
    await db.insertMeta(TileMetasCompanion.insert(
      regionName: 'changsha', fileName: 'changsha.mbtiles',
      fileSize: 50000, filePath: '/data/changsha.mbtiles',
    ));
    final metas = await db.getAllMetas();
    expect(metas.length, 1);
    expect(metas.first.regionName, 'changsha');
    expect(metas.first.status, 'downloading');
  });

  test('getByName returns null for missing', () async {
    expect(await db.getByName('nonexistent'), isNull);
  });
}
```

- [ ] **Step 4: Run tests and commit**

```bash
flutter test test/core/database/app_database_test.dart
git add -A && git commit -m "feat: unified AppDatabase with TileMetas + FarmTilePins"
```

---

## Task 2: TileSourceResolver — Dynamic Region Resolution

**Files:**
- Create: `core/map/tile_source_resolver.dart`
- Modify: `core/map/smart_tile_provider.dart`
- Test: `test/core/map/tile_source_resolver_test.dart`

- [ ] **Step 1: Create TileSourceResolver**

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class TileSource {
  final String sourceName;
  final String tileUrl;
  TileSource({required this.sourceName, required this.tileUrl});
}

class TileSourceResolver {
  final String baseUrl;
  final AppDatabase _db;  // Unified database
  TileSourceResolver({required this.baseUrl, required AppDatabase db})
      : _db = db;

  Future<List<TileSource>> resolveForFarm(int farmId, String token) async {
    // Offline-resilient resolution: local-first strategy
    List<TileSource> onlineSources = [];

    // 1. Try online API
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/farms/$farmId/tile-source'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] as List;
        onlineSources = data.map((d) => TileSource(
          sourceName: d['sourceName'] as String,
          tileUrl: d['tileUrl'] as String,
        )).toList();
        // Cache successful response for offline fallback
        // Known optimization: persist online tile-source response to drift so that
        // offline resolution can use the full server response (not just downloaded MBTiles).
        // Current behavior: offline fallback relies on AppDatabase (downloaded MBTiles only).
        // This means farms with no downloaded tiles will show no offline sources — acceptable for V1.
      }
    } catch (_) {
      // Network error — proceed to offline fallback
    }

    if (onlineSources.isNotEmpty) return onlineSources;

    // 2. Offline fallback: use locally downloaded MBTiles files
    final localMetas = await _db.getByFarmId(farmId);
    return localMetas
        .where((m) => m.status == 'ready')
        .map((m) => TileSource(
          sourceName: m.regionName,
          tileUrl: 'file://${m.filePath}',  // Local MBTiles file
        )).toList();
  }
}
```

- [ ] **Step 2: Modify SmartTileProvider — Multi-MBTiles Architecture**

Read current `smart_tile_provider.dart`. The existing code has:
- Single `MBTilesTileProvider? mbtilesProvider`
- `_activeSource` enum (`selfHosted` / `mbtiles` / `fallback`)

**Refactor to multi-source architecture:**

```dart
// Before:
MBTilesTileProvider? mbtilesProvider;
_ActiveSource _activeSource = _ActiveSource.selfHosted;

// After:
List<MBTilesTileProvider> _mbtilesProviders = [];  // Multiple MBTiles files
List<String> _selfHostedUrls = [];                  // Multiple tileserver URLs
List<TileSource> _dynamicSources = [];              // From TileSourceResolver
```

**`getImage()` multi-MBTiles lookup — detailed implementation:**

```dart
// In SmartTileProvider, replace single mbtilesProvider with list:
List<MBTilesTileProvider> _mbtilesProviders = [];

@override
Future<TileImage> getImage(TileCoordinates coordinates, TileLayerOptions options) async {
  final xyz = Coords(coordinates.z, coordinates.x, coordinates.y);

  // 1. Try each local MBTiles provider (offline-first)
  for (final provider in _mbtilesProviders) {
    try {
      final bytes = provider.getTile(xyz);
      if (bytes != null) {
        _activeSource = _TileSource.mbtiles;
        onSourceChanged?.call();
        return TileImage.fromBytes(bytes);
      }
    } catch (_) { /* File missing or unreadable — try next */ }
  }

  // 2. Try self-hosted tileserver (online)
  for (final url in _selfHostedUrls) {
    try {
      final response = await http.get(Uri.parse(_buildUrl(url, xyz.z, xyz.x, xyz.y)));
      if (response.statusCode == 200) {
        _activeSource = _TileSource.selfHosted;
        onSourceChanged?.call();
        return TileImage.fromBytes(response.bodyBytes);
      }
    } catch (_) { /* Network error — try next URL */ }
  }

  // 3. Fall back to AMap/OSM
  _activeSource = _TileSource.fallback;
  onSourceChanged?.call();
  return _fallbackTileProvider.getImage(coordinates, options);
}
```

> **Note:** `MBTilesTileProvider.getTile()` already exists in `mbtiles_tile_provider.dart` and returns `Uint8List?` (null if tile not in file). No `hasTile()` method needed — `getTile` returning null means the tile is not in that MBTiles file. For cross-region farms, multiple MBTiles files are checked in sequence until one returns data.

Lookup order: Local MBTiles (fastest, offline) → Self-hosted tileserver → AMap/OSM fallback.

**`updateSources(List<TileSource> sources, List<String> localMbtilesPaths)` method:**
- Accepts resolved tile sources (from API) + local MBTiles file paths
- Rebuilds `_dynamicSources`, `_selfHostedUrls`, `_mbtilesProviders`
- Returns `void` — callers must trigger `TileLayer` rebuild via Riverpod state change

**TileLayer rebuild mechanism:**
- `SmartTileProvider` instance is held by a Riverpod `Provider<SmartTileProvider>`
- `updateSources()` is called after provider mutation
- Map page watches a `tileSourcesVersionProvider` (integer counter) that increments on `updateSources()`
- Widget rebuild picks up new `SmartTileProvider` instance → `TileLayer(tileProvider: ...)` gets new provider
- This ensures cached tiles are invalidated and fresh tiles are fetched

- [ ] **Step 3: Write test and commit**

```bash
flutter test test/core/map/tile_source_resolver_test.dart
git add -A && git commit -m "feat: TileSourceResolver + SmartTileProvider dynamic sources"
```

---

## Task 3: TileDownloader — Foreground Download + MD5 + Atomic Rename

**Files:**
- Create: `features/offline_tiles/data/tile_downloader.dart`
- Test: `test/features/offline_tiles/tile_downloader_test.dart`

- [ ] **Step 1: Create TileDownloader**

Implements the download flow from spec §7.2:
1. Download to `{regionName}.mbtiles.download` temp file
2. Track progress via stream
3. Verify MD5 on completion
4. On mismatch → delete temp, throw
5. On match → atomic rename to `{regionName}.mbtiles`

Uses `http` package `send()` for streaming with progress. Uses `crypto` package for MD5. Uses `path_provider` for storage directory.

**断点续传方案（第一版 — 简化实现）:**
- 下载前检查临时文件 `{regionName}.mbtiles.download` 是否已存在
- 如果存在且 size > 0：读取当前文件大小作为 offset，发送 `Range: bytes=$offset-` header
- 服务端需支持 Range 请求（Plan A 的 nginx/TileController 需配置 `accept-range` header）
- 如果服务端返回 200（不支持 Range）而非 206：删除临时文件，重新完整下载
- 下载进度 = `(已下载字节数 + 临时文件已有字节数) / 总字节数`
- 状态记录：仅在 temp 文件中隐式记录（文件存在 + 大小即进度），无需额外 drift 表或 `.download.meta` 文件
- **降级策略**：如果 Range 不可用，退化为完整下载（无断点续传）

- [ ] **Step 2: Write tests** — happy path creates file, MD5 mismatch deletes temp, canceled download cleans up.

- [ ] **Step 3: Run tests and commit**

```bash
flutter test test/features/offline_tiles/tile_downloader_test.dart
git add -A && git commit -m "feat: TileDownloader — foreground download + MD5 + atomic rename"
```

---

## Task 4: OfflineTileManager — Download + LRU + Pin/Unpin

**Files:**
- Create: `features/offline_tiles/presentation/offline_tile_manager.dart`
- Test: `test/features/offline_tiles/offline_tile_manager_test.dart`

- [ ] **Step 1: Create OfflineTileManager**

Singleton service implementing spec §7.2. **Method signatures must align exactly with spec §7.2:**

```dart
class OfflineTileManager {
  // Core query methods
  Future<TileStatus> getTileStatus(int farmId);           // GET /farms/{id}/tile-status
  Future<List<LocalTileInfo>> getLocalTiles();             // List all local tiles
  Future<int> getStorageUsed();                            // Sum of all tile file sizes

  // Download methods
  Future<void> startForegroundDownload(int farmId, {
    void Function(double progress)? onProgress,            // 0.0 → 1.0
    void Function()? onComplete,
    void Function(String error)? onError,
  });                                                      // Farm-driven: resolves all ready regions for farm, downloads sequentially, handles resume internally
  Future<void> enqueueBackgroundDownload(int farmId);      // workmanager task (first version: no-op on iOS due to 30s limit, delegates to foreground prompt)
  void cancelDownload(int farmId);                         // Cancel by farmId (not regionName)

  // Local management methods
  Future<void> deleteLocalTiles(String regionName);        // Remove file + meta (with ref-count check — see P1-10)
  Future<void> evictIfNeeded({int maxBytes = 1024 * 1024 * 1024});  // LRU on unpinned oldest-first, 1 GB default

  // Pin/Unpin
  Future<void> pin(int farmId);                            // Mark farm's tiles as pinned
  Future<void> unpin(int farmId);                          // Mark farm's tiles as unpinned
  Future<bool> isPinned(int farmId);                       // Check pin status

  // Reference counting
  Future<void> removeFarmReference(int farmId);            // Remove farm from ref-count, delete files only when no refs remain
}
```

**Pin/Unpin uses FarmTilePins relation table (defined in AppDatabase):**
- `pin(farmId)`: Find all TileMetas referenced by farmId via FarmTilePins → `INSERT OR UPDATE pinned=1`
- `unpin(farmId)`: `UPDATE farm_tile_pins SET pinned=0 WHERE farmId=?`
- `isPinned(farmId)`: Check if any FarmTilePins row exists with `farmId=? AND pinned=1`

**Reference counting via FarmTilePins (replaces comma-separated farmIds):**
1. `removeFarmReference(farmId)`:
   - `DELETE FROM farm_tile_pins WHERE farmId=?` (one SQL statement, no string parsing)
   - For each TileMeta that previously had this farmId: check if any FarmTilePins rows remain
   - If no FarmTilePins rows reference this TileMeta → no other farm uses this region → safe to delete file + meta
2. `deleteLocalTiles(regionName)`:
   - Get TileMeta by regionName
   - Check `SELECT COUNT(*) FROM farm_tile_pins WHERE tile_meta_id=?`
   - If count == 0 (or only the current farm) → delete file + meta + all FarmTilePins rows
   - If count > 0 → other farms still use this region → only remove current farm's FarmTilePins row, keep file

This avoids the LIKE '%3%' mismatch problem and concurrent string mutation issues.
```

**Key differences from earlier draft:**
- `downloadTile(farmId, regionName)` + `resumeDownload(regionName)` → merged into `startForegroundDownload(int farmId)` with progress callbacks. Resume logic handled internally by checking `.mbtiles.download` temp file existence and HTTP Range header.
- `cancelDownload(regionName)` → `cancelDownload(int farmId)` — cancel all downloads for a farm
- Added missing `getTileStatus(int farmId)`, `getLocalTiles()`, `enqueueBackgroundDownload(int farmId)`
- Added `removeFarmReference(int farmId)` for safe multi-farm cleanup
- `evictIfNeeded` now has explicit `maxBytes` default value (1 GB)

LRU eviction: query `getUnpinnedOldestFirst()`, delete files + meta until under limit. Skip regions referenced by pinned farms.

- [ ] **Step 2: Write tests** — pin/unpin, evict removes unpinned, evict skips pinned, removeFarmReference deletes file only when no refs remain, deleteLocalTiles checks ref-count before deleting.

- [ ] **Step 3: Run tests and commit**

```bash
flutter test test/features/offline_tiles/offline_tile_manager_test.dart
git add -A && git commit -m "feat: OfflineTileManager — download + LRU + pin/unpin"
```

---

## Task 5: OfflineTileController + Farm Switcher Integration

**Files:**
- Create: `features/offline_tiles/presentation/offline_tile_controller.dart`
- Modify: `features/farm_switcher/` — trigger tile source update on switch

- [ ] **Step 1: Create OfflineTileController**

Riverpod `Notifier<OfflineTileState>` with fields: `localTiles`, `currentFarmStatus`, `storageUsed`, `downloading`, `downloadProgress`. Methods: `loadLocalTiles()`, `startDownload(farmId)`, `cancelDownload()`, `deleteTile(regionName)`, `refreshStatus(farmId)`.

**网络策略（spec §7.2）:**
- 在 `startDownload()` 前检测当前网络类型
- WiFi：直接执行前台下载
- 移动网络：弹出底部确认横幅（BottomSheet）"当前使用移动网络，下载可能消耗较多流量。是否继续？" + [取消] [继续下载] 按钮
- 检测方式：使用 `http` 请求探测（不引入 `connectivity_plus`），或检查 `NetworkException` 层次结构
- 可选：在 MinePage 增加设置项"仅 WiFi 下载"（存储到 SharedPreferences）

- [ ] **Step 2: Wire farm switcher**

On farm switch: call `TileSourceResolver.resolveForFarm()` → `SmartTileProvider.updateSources()` + auto-pin new farm's tiles.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: OfflineTileController + farm switcher tile update"
```

---

## Task 6: Offline Tile Management Page

**Files:**
- Create: `features/offline_tiles/presentation/offline_tile_management_page.dart`
- Modify: `app/app_route.dart`
- Modify: `features/mine/` — add entry

- [ ] **Step 1: Create page** — Scaffold with AppBar "离线地图管理", storage bar, tile list with actions (download/pause/delete/pin), progress indicator. Follow existing page patterns (ConsumerWidget, AppColors, Key'd widgets).

- [ ] **Step 2: Add route** — `offlineMaps` → `/settings/offline-maps`

- [ ] **Step 3: Add "离线地图管理" entry** in MinePage settings list.

- [ ] **Step 4: Write widget test + commit**

```bash
flutter test test/features/offline_tiles/offline_tile_management_page_test.dart
git add -A && git commit -m "feat: offline tile management page"
```

---

## Task 7: Background Download (workmanager)

**Files:**
- Create: `features/offline_tiles/data/background_download_worker.dart`
- Modify: `lib/main.dart`

- [ ] **Step 1: Create callbackDispatcher** using `Workmanager().executeTask()` — handles `tile-download` task, downloads with `TileDownloader`, updates meta in `AppDatabase`.

- [ ] **Step 2: Initialize workmanager in main.dart**

- [ ] **Step 3: Add `enqueueBackgroundDownload`** to OfflineTileManager with WiFi + charging constraints.

> **iOS caveat:** `workmanager` on iOS uses `BGAppRefreshTask` which is best-effort — the system decides when (or whether) to execute it. iOS background download is **not guaranteed** to run. The foreground download flow (Task 3) is the primary user experience path; background download is a convenience enhancement for Android. On iOS, if background download cannot complete, the user will be prompted to re-open the app to continue downloading when WiFi is available.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: background tile download with workmanager"
```

---

## Task 8: API Key Management — Incremental Improvement

**Files:**
- Modify: `features/api_authorization/data/api_authorization_api_repository.dart`
- Modify: `features/admin/presentation/api_auth_page.dart` (and/or `features/mine/presentation/api_auth_page.dart`)

> **Context:** The codebase already has a complete `api_authorization` module with `ApiAuthorizationApiRepository` (calls `GET/POST/PUT /admin/api-keys`) and `ApiAuthPage` (list + create + status toggle). Routes `platformApiAuth` and `mineApiAuth` are already registered. This task **incrementally improves** the existing pages, not creates new ones.

- [ ] **Step 1: Enhance ApiAuthorizationApiRepository**

Add to existing repository:
- `createApiKey()` should return the raw `sk_live_...` key (already calls POST, but may not surface the one-time key)
- Add `deleteApiKey(String keyId)` — calls `DELETE /admin/api-keys/{keyId}` for permanent deletion (distinguish from `revokeApiKey` which only sets status=disabled)

- [ ] **Step 2: Improve ApiAuthPage UI**

Add to existing page (both admin and mine versions):
1. **Create dialog enhancement**: After successful creation, show a modal with the raw API key + "复制" copy button. Display warning: "此密钥仅显示一次，请妥善保存。" Dismiss button only enabled after copy.
2. **Two-step delete**: Currently only has enable/disable toggle. Add:
   - "吊销" button → calls `updateApiKeyStatus(keyId, 'disabled')` (sets inactive)
   - "删除" button (only shown for disabled keys) → calls `deleteApiKey(keyId)` (permanent removal)
   - Confirm dialog before permanent deletion
3. Keep using existing routes (`/admin/api-auth`, `/mine/api-auth`) — no new routes needed.

- [ ] **Step 3: Write test + commit**

```bash
flutter test test/features/api_authorization/
git add -A && git commit -m "feat: API Key management — one-time key display + two-step revoke/delete"
```

---

## Task 9: Tile Update Detection

**Files:**
- Modify: `features/offline_tiles/presentation/offline_tile_manager.dart`

- [ ] **Step 1: Add `checkForUpdates`** — compare local `regionGeneratedAt` with server `tile_regions.generatedAt`. WiFi on startup → show update snackbar.

- [ ] **Step 2: Commit**

```bash
git add -A && git commit -m "feat: tile update detection on WiFi startup"
```

---

## Task 10: Full Verification

- [ ] **Step 1: Run all tests** — `flutter test`
- [ ] **Step 2: Run static analysis** — `flutter analyze`
- [ ] **Step 3: Final commit**

```bash
git add -A && git commit -m "chore: plan B complete — Flutter offline tiles"
```

---

## Self-Review

### Spec Coverage

| §7 Section | Task |
|-----------|------|
| §7.1 Dynamic region resolution | Task 2 |
| §7.2 OfflineTileManager | Task 4 |
| §7.2 Foreground download + wakelock | Task 3 |
| §7.2 Background download + workmanager | Task 7 |
| §7.2 MD5 verify + atomic rename | Task 3 |
| §7.2 Pin/Unpin + LRU eviction | Task 4 |
| §7.3 Offline tile management page | Task 6 |
| §7.4 Tile update detection | Task 9 |
| §7.5 drift + sqlite3 | Task 1 |
| §4.2 API Key management UI | Task 8 |

### Review Fix Log (2026-05-28)

| # | Issue | Fix | Task |
|---|-------|-----|------|
| P0-2.1 | Drift database split | Merged into unified `AppDatabase` (Plan C adds tables via schema upgrade) | Task 1 |
| P1-3.1 | SmartTileProvider multi-region detail | Added full `getImage()` multi-MBTiles traversal code with per-file null check | Task 2 |
| P1-3.2 | Pin storage comma-separated strings | Replaced with `FarmTilePins` relation table in AppDatabase | Task 1, 4 |
| P2-4.2 | iOS background download limitation | Added best-effort caveat note to Task 7 Step 3 | Task 7 |
