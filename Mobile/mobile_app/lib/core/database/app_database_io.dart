import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

class AppDatabase {
  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  late final Database _db;
  late final String _dbPath;

  AppDatabase._() {
    _dbPath = _resolveDbPath();
    _db = sqlite3.open(_dbPath);
    _initSchema();
  }

  static Future<AppDatabase> createAsync() async {
    final dir = await getApplicationSupportDirectory();
    final dbDir = p.join(dir.path, 'smart_livestock');
    Directory(dbDir).createSync(recursive: true);
    final dbPath = p.join(dbDir, 'smart_livestock.db');
    _instance?.dispose();
    _instance = AppDatabase._fromPath(dbPath);
    return _instance!;
  }

  AppDatabase._fromPath(this._dbPath) {
    _db = sqlite3.open(_dbPath);
    _initSchema();
  }

  Database get rawDb => _db;

  String _resolveDbPath() {
    final dir = _ensureDir();
    return p.join(dir, 'smart_livestock.db');
  }

  void _initSchema() {
    final version = _db.select('PRAGMA user_version').first['user_version'] as int;
    if (version < 1) {
      _createSchemaV1();
      _db.execute('PRAGMA user_version = 1');
    }
  }

  void _createSchemaV1() {
    _db.execute('''
      CREATE TABLE IF NOT EXISTS tile_metas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        region_name TEXT NOT NULL,
        file_name TEXT NOT NULL,
        file_size INTEGER NOT NULL,
        md5 TEXT,
        file_path TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'downloading',
        downloaded_at TEXT,
        last_accessed_at TEXT,
        region_generated_at TEXT,
        UNIQUE(region_name)
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS farm_tile_pins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        farm_id INTEGER NOT NULL,
        tile_meta_id INTEGER NOT NULL REFERENCES tile_metas(id),
        pinned INTEGER NOT NULL DEFAULT 0
      )
    ''');
    _db.execute('''
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
    _db.execute('''
      CREATE TABLE IF NOT EXISTS cached_livestock_positions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        livestock_id INTEGER NOT NULL,
        name TEXT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        fence_id INTEGER,
        UNIQUE(livestock_id)
      )
    ''');
    _db.execute('''
      CREATE TABLE IF NOT EXISTS analytics_events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        event_type TEXT NOT NULL,
        payload TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')),
        reported INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  String _ensureDir() {
    final dir = p.join(
        _getApplicationSupportDirectorySync(), 'smart_livestock');
    Directory(dir).createSync(recursive: true);
    return dir;
  }

  String _getApplicationSupportDirectorySync() {
    if (Platform.isAndroid || Platform.isIOS) {
      final dir = p.join('/data', 'data', 'com.example.hkt_livestock_agentic', 'databases');
      Directory(dir).createSync(recursive: true);
      return dir;
    }
    return '${Platform.environment['HOME'] ?? '.'}/Library/Application Support';
  }

  // CachedFences queries
  List<Map<String, dynamic>> getCachedFencesByFarm(int farmId) {
    return _db.select('SELECT * FROM cached_fences WHERE farm_id = ?', [farmId])
        .map((r) => _rowToMap(r)).toList();
  }

  List<Map<String, dynamic>> getUnsyncedFences() {
    return _db.select('SELECT * FROM cached_fences WHERE synced = 0')
        .map((r) => _rowToMap(r)).toList();
  }

  Map<String, dynamic>? getCachedFenceByRemoteId(int remoteId) {
    final rows = _db.select('SELECT * FROM cached_fences WHERE remote_id = ?', [remoteId]);
    return rows.isEmpty ? null : _rowToMap(rows.first);
  }

  void insertCachedFence({
    int? remoteId,
    required int farmId,
    required String name,
    String fenceType = 'sub',
    required String vertices,
    String status = 'active',
    int version = 1,
    bool synced = false,
    bool localDeleteFlag = false,
    DateTime? lastLocalModifiedAt,
  }) {
    if (remoteId != null) {
      final existing = getCachedFenceByRemoteId(remoteId);
      if (existing != null) {
        _db.execute('''
          UPDATE cached_fences SET farm_id=?, name=?, fence_type=?, vertices=?, status=?, version=?, synced=?, local_delete_flag=?, updated_at=?, last_local_modified_at=?
          WHERE remote_id=?
        ''', [farmId, name, fenceType, vertices, status, version,
              synced ? 1 : 0, localDeleteFlag ? 1 : 0,
              DateTime.now().toIso8601String(),
              lastLocalModifiedAt?.toIso8601String(), remoteId]);
        return;
      }
    }
    _db.execute('''
      INSERT INTO cached_fences 
      (remote_id, farm_id, name, fence_type, vertices, status, version, synced, local_delete_flag, updated_at, last_local_modified_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [remoteId, farmId, name, fenceType, vertices, status, version,
          synced ? 1 : 0, localDeleteFlag ? 1 : 0,
          DateTime.now().toIso8601String(),
          lastLocalModifiedAt?.toIso8601String()]);
  }

  void markFenceSynced(int id) {
    _db.execute('UPDATE cached_fences SET synced = 1 WHERE id = ?', [id]);
  }

  void deleteCachedFence(int id) {
    _db.execute('DELETE FROM cached_fences WHERE id = ?', [id]);
  }

  void deleteCachedFencesByFarm(int farmId) {
    _db.execute('DELETE FROM cached_fences WHERE farm_id = ?', [farmId]);
  }

  // TileMetas queries
  List<Map<String, dynamic>> getTileMetas() {
    return _db.select('SELECT * FROM tile_metas').map((r) => _rowToMap(r)).toList();
  }

  Map<String, dynamic>? getTileMetaByRegion(String regionName) {
    final rows = _db.select('SELECT * FROM tile_metas WHERE region_name = ?', [regionName]);
    return rows.isEmpty ? null : _rowToMap(rows.first);
  }

  void insertTileMeta({
    required String regionName,
    required String fileName,
    required int fileSize,
    String? md5,
    required String filePath,
    String status = 'downloading',
  }) {
    final existing = getTileMetaByRegion(regionName);
    if (existing != null) {
      _db.execute('''
        UPDATE tile_metas SET file_name=?, file_size=?, md5=?, file_path=?, status=?, downloaded_at=?, last_accessed_at=?
        WHERE region_name=?
      ''', [fileName, fileSize, md5, filePath, status,
            DateTime.now().toIso8601String(), DateTime.now().toIso8601String(), regionName]);
      return;
    }
    _db.execute('''
      INSERT INTO tile_metas (region_name, file_name, file_size, md5, file_path, status, downloaded_at, last_accessed_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    ''', [regionName, fileName, fileSize, md5, filePath, status,
          DateTime.now().toIso8601String(), DateTime.now().toIso8601String()]);
  }

  int getStorageUsed() {
    final rows = _db.select('SELECT COALESCE(SUM(file_size), 0) as total FROM tile_metas');
    return rows.first['total'] as int;
  }

  // Analytics queries
  void insertAnalyticsEvent(String eventType, String payload) {
    _db.execute('INSERT INTO analytics_events (event_type, payload) VALUES (?, ?)',
        [eventType, payload]);
  }

  List<Map<String, dynamic>> getUnreportedEvents() {
    return _db.select('SELECT * FROM analytics_events WHERE reported = 0')
        .map((r) => _rowToMap(r)).toList();
  }

  void markEventsReported(List<int> ids) {
    if (ids.isEmpty) return;
    final placeholders = ids.map((_) => '?').join(',');
    _db.execute('UPDATE analytics_events SET reported = 1 WHERE id IN ($placeholders)', ids);
  }

  // Livestock position queries
  void upsertLivestockPosition({
    required int livestockId,
    String? name,
    required double latitude,
    required double longitude,
    required String recordedAt,
    int? fenceId,
  }) {
    _db.execute('''
      INSERT OR REPLACE INTO cached_livestock_positions (livestock_id, name, latitude, longitude, recorded_at, fence_id)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [livestockId, name, latitude, longitude, recordedAt, fenceId]);
  }

  List<Map<String, dynamic>> getLivestockPositions() {
    return _db.select('SELECT * FROM cached_livestock_positions').map((r) => _rowToMap(r)).toList();
  }

  Map<String, dynamic> _rowToMap(Row row) {
    return {for (final key in row.keys) key: row[key]};
  }

  void dispose() {
    _db.dispose();
    _instance = null;
  }
}
