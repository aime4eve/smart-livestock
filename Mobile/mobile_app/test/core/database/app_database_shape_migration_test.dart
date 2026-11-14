// NIX-410: real-SQLite upgrade test for the offline cache shape column.
//
// Exercises AppDatabase._initSchema against actual database files (not
// mocks of the schema logic):
//   1. a v1 leftover database (cached_fences WITHOUT shape,
//      user_version=1) must be upgraded in place — shape column added
//      with the 'polygon' default stamped onto existing rows;
//   2. a fresh database must be created directly at v2 WITHOUT hitting
//      the ALTER branch twice (column-presence guard).
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';
import 'package:hkt_livestock_agentic/core/database/app_database_io.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('nix410-db-test');
    Directory(p.join(tempDir.path, 'smart_livestock')).createSync(recursive: true);
    dbPath = p.join(tempDir.path, 'smart_livestock', 'smart_livestock.db');
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((call) async {
      if (call.method == 'getApplicationSupportDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  tearDown(() {
    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler(null);
    tempDir.deleteSync(recursive: true);
  });

  /// Creates the v1 schema exactly as _createSchemaV1 did before NIX-410
  /// (cached_fences carries fence_type but NO shape column) and plants a
  /// legacy row so the upgrade path has real data to stamp.
  void createLegacyV1Database() {
    final db = sqlite3.open(dbPath);
    db.execute('''
      CREATE TABLE IF NOT EXISTS cached_fences (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        remote_id INTEGER,
        farm_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        fence_type TEXT NOT NULL DEFAULT 'sub',
        vertices TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        version INTEGER NOT NULL DEFAULT 1,
        synced INTEGER NOT NULL DEFAULT 0,
        local_delete_flag INTEGER NOT NULL DEFAULT 0,
        updated_at TEXT NOT NULL,
        last_local_modified_at TEXT,
        UNIQUE(remote_id)
      )
    ''');
    db.execute('PRAGMA user_version = 1');
    db.execute('''
      INSERT INTO cached_fences
        (remote_id, farm_id, name, fence_type, vertices, status, version, synced, updated_at)
      VALUES (22, 1, '存量围栏', 'sub', '[]', 'active', 1, 1, '2026-11-13T00:00:00.000')
    ''');
    db.dispose();
  }

  bool hasShapeColumn(Database db) {
    final cols = db.select('PRAGMA table_info(cached_fences)');
    return cols.any((c) => c['name'] == 'shape');
  }

  test('v1 存量库升级：shape 列补齐 + 版本推进 v2 + 存量行缺省 polygon', () async {
    createLegacyV1Database();

    // Sanity: the legacy file really lacks the column before the upgrade.
    final before = sqlite3.open(dbPath);
    expect(hasShapeColumn(before), isFalse);
    before.dispose();

    final db = await AppDatabase.createAsync();

    final raw = db.rawDb;
    // Column added in place.
    expect(hasShapeColumn(raw), isTrue);
    // Version pushed to 2 exactly once.
    expect(
      raw.select('PRAGMA user_version').first['user_version'],
      2,
    );
    // Legacy row stamped with the polygon default and still readable.
    final legacy = raw
        .select("SELECT name, fence_type, shape FROM cached_fences WHERE remote_id = 22");
    expect(legacy, hasLength(1));
    expect(legacy.first['name'], '存量围栏');
    expect(legacy.first['fence_type'], 'sub');
    expect(legacy.first['shape'], 'polygon');

    // New writes carry the shape through insert/update round-trips.
    db.insertCachedFence(
      remoteId: 23,
      farmId: 1,
      name: '升级后写入',
      fenceType: 'sub',
      shape: 'rectangle',
      vertices: '[]',
      synced: true,
    );
    final written = raw
        .select("SELECT shape FROM cached_fences WHERE remote_id = 23");
    expect(written.first['shape'], 'rectangle');

    // Update path overwrites shape without duplicating the column.
    db.insertCachedFence(
      remoteId: 23,
      farmId: 1,
      name: '升级后写入',
      fenceType: 'sub',
      shape: 'circle',
      vertices: '[]',
      synced: true,
    );
    final updated = raw
        .select("SELECT shape FROM cached_fences WHERE remote_id = 23");
    expect(updated.first['shape'], 'circle');
    expect(
      raw.select("SELECT COUNT(*) AS n FROM cached_fences WHERE remote_id = 23").first['n'],
      1,
    );

    db.dispose();
  });

  test('全新库直接建 v2：shape 列在位且 ALTER 守卫不重复执行', () async {
    // No pre-existing file — createAsync runs _createSchemaV1 (v2 DDL with
    // shape) then the version<2 branch whose presence guard must skip.
    final db = await AppDatabase.createAsync();

    final raw = db.rawDb;
    expect(hasShapeColumn(raw), isTrue);
    expect(
      raw.select('PRAGMA user_version').first['user_version'],
      2,
    );
    // The v1→v2 ALTER branch is guarded by column presence; a fresh v1
    // schema already carries the column, so the DB must hold exactly one
    // shape column definition (a double ALTER would throw before this
    // assertion ever ran — this also pins the guard's purpose explicitly).
    final shapeCols = raw
        .select("PRAGMA table_info(cached_fences)")
        .where((c) => c['name'] == 'shape')
        .length;
    expect(shapeCols, 1);

    db.dispose();
  });
}
