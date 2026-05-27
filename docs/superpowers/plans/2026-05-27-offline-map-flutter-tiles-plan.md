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
│   │   └── offline_tile_repository.dart
│   ├── data/
│   │   ├── local_tile_meta_store.dart    (drift)
│   │   ├── offline_tile_repository_impl.dart
│   │   └── tile_downloader.dart
│   └── presentation/
│       ├── offline_tile_controller.dart
│       ├── offline_tile_manager.dart
│       └── offline_tile_management_page.dart
├── features/admin/presentation/
│   └── api_key_management_page.dart      (new)
└── app/app_route.dart                    (modify: add routes)
```

### Modified Files

| File | Change |
|------|--------|
| `core/map/smart_tile_provider.dart` | Accept dynamic tile source list per farm |
| `pubspec.yaml` | Add drift, workmanager, wakelock_plus, crypto, path_provider |
| `features/farm_switcher/` | On farm switch, update tile sources + auto-pin |
| `app/app_route.dart` | Add `/settings/offline-maps`, `/ops/admin/api-keys` routes |
| `features/mine/` | Add "离线地图管理" entry |

---

## Task 1: Add Dependencies + Drift Setup

**Files:**
- Modify: `pubspec.yaml`
- Create: `features/offline_tiles/data/local_tile_meta_store.dart`
- Test: `test/features/offline_tiles/local_tile_meta_store_test.dart`

- [ ] **Step 1: Add dependencies to pubspec.yaml**

```yaml
dependencies:
  drift: ^2.18
  path_provider: ^2.1.0
  path: ^1.9.0
  workmanager: ^0.5.2
  wakelock_plus: ^1.2
  crypto: ^3.0.3

dev_dependencies:
  drift_dev: ^2.18
  build_runner: ^2.4
```

Run: `cd Mobile/mobile_app && flutter pub get`

- [ ] **Step 2: Create LocalTileMetaStore (drift database)**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

part 'local_tile_meta_store.g.dart';

class TileMetas extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get regionName => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSize => integer()();
  TextColumn get md5 => text().nullable()();
  TextColumn get filePath => text()();
  TextColumn get status => text().withDefault(const Constant('downloading'))();
  IntColumn get pinned => integer().withDefault(const Constant(0))();
  TextColumn get farmIds => text()();
  DateTimeColumn get downloadedAt => dateTime().nullable()();
  DateTimeColumn get lastAccessedAt => dateTime().nullable()();
  DateTimeColumn get regionGeneratedAt => dateTime().nullable()();
}

@DriftDatabase(tables: [TileMetas])
class LocalTileMetaStore extends Database {
  LocalTileMetaStore() : super(_openConnection());
  LocalTileMetaStore.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  Future<List<TileMeta>> getAllMetas() => select(tileMetas).get();
  Future<TileMeta?> getByName(String name) =>
      (select(tileMetas)..where((t) => t.regionName.equals(name))).getSingleOrNull();
  Future<void> insertMeta(TileMetasCompanion entry) => into(tileMetas).insert(entry);
  Future<void> updateMeta(TileMeta entry) => update(tileMetas).replace(entry);
  Future<void> deleteMeta(String name) =>
      (delete(tileMetas)..where((t) => t.regionName.equals(name))).go();
  Future<List<TileMeta>> getUnpinnedOldestFirst() =>
      (select(tileMetas)..where((t) => t.pinned.equals(0))
        ..orderBy([(t) => OrderingTerm.asc(t.lastAccessedAt)])).get();
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    return NativeDatabase.createInBackground(File('${dir.path}/offline_tiles.db'));
  });
}
```

Run: `dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Write drift test**

```dart
import 'package:drift/native.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/features/offline_tiles/data/local_tile_meta_store.dart';

void main() {
  late LocalTileMetaStore db;
  setUp(() { db = LocalTileMetaStore.forTesting(NativeDatabase.memory()); });
  tearDown(() async => await db.close());

  test('insert and query tile meta', () async {
    await db.insertMeta(TileMetasCompanion.insert(
      regionName: 'changsha', fileName: 'changsha.mbtiles',
      fileSize: 50000, filePath: '/data/changsha.mbtiles', farmIds: '1,2',
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
flutter test test/features/offline_tiles/local_tile_meta_store_test.dart
git add -A && git commit -m "feat: drift setup + LocalTileMetaStore for offline tiles"
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
  TileSourceResolver({required this.baseUrl});

  Future<List<TileSource>> resolveForFarm(int farmId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/farms/$farmId/tile-source'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final data = body['data'] as List;
    return data.map((d) => TileSource(
      sourceName: d['sourceName'] as String,
      tileUrl: d['tileUrl'] as String,
    )).toList();
  }
}
```

- [ ] **Step 2: Modify SmartTileProvider**

Read current `smart_tile_provider.dart`. Add `List<TileSource> _dynamicSources` field and `updateSources()` method. In the tile fetch logic, try dynamic source URLs first (matching by URL pattern `{z}/{x}/{y}`), then fall back to existing MBTiles → AMap/OSM.

The key change: when `_dynamicSources` is non-empty, use those URLs as primary tileserver targets. When empty, use `MapConfig.selfHostedTileUrl` (backward compatible).

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

Singleton service implementing spec §7.2:

| Method | Purpose |
|--------|---------|
| `getTileStatus(farmId, token)` | GET /farms/{id}/tile-status |
| `startForegroundDownload(farmId, token, onProgress)` | Download all ready regions |
| `enqueueBackgroundDownload(regionName, url, md5)` | workmanager task |
| `cancelDownload(regionName)` | Delete temp file |
| `deleteLocalTiles(regionName)` | Remove file + meta |
| `getStorageUsed()` | Sum of all tile file sizes |
| `evictIfNeeded({maxBytes})` | LRU on unpinned oldest-first |
| `pin(farmId)` | Set pinned=1 on farm's tiles |
| `unpin(farmId)` | Set pinned=0 |
| `isPinned(farmId)` | Check pin status |

LRU eviction: query `getUnpinnedOldestFirst()`, delete files + meta until under limit. Skip regions referenced by pinned farms.

- [ ] **Step 2: Write tests** — pin/unpin, evict removes unpinned, evict skips pinned.

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

- [ ] **Step 1: Create callbackDispatcher** using `Workmanager().executeTask()` — handles `tile-download` task, downloads with `TileDownloader`, updates meta in `LocalTileMetaStore`.

- [ ] **Step 2: Initialize workmanager in main.dart**

- [ ] **Step 3: Add `enqueueBackgroundDownload`** to OfflineTileManager with WiFi + charging constraints.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: background tile download with workmanager"
```

---

## Task 8: API Key Management UI (platform_admin)

**Files:**
- Create: `features/admin/presentation/api_key_management_page.dart`
- Create: `features/api_authorization/data/live_api_key_repository.dart`
- Modify: `app/app_route.dart`

- [ ] **Step 1: Create LiveApiKeyRepository** — calls `GET/POST/PUT/DELETE /admin/api-keys`.

- [ ] **Step 2: Create ApiKeyManagementPage** — list + create dialog (shows raw key once with Copy button) + revoke + delete. Follow admin page patterns.

- [ ] **Step 3: Add route** — `/ops/admin/api-keys` in platform_admin navigation.

- [ ] **Step 4: Write test + commit**

```bash
flutter test test/features/admin/api_key_management_test.dart
git add -A && git commit -m "feat: API Key management UI for platform_admin"
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
