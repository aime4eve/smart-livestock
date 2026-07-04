import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:hkt_livestock_agentic/core/database/app_database.dart';

class TileStatus {
  final String regionName;
  final String status;
  final int? fileSize;
  final String? md5;
  TileStatus({required this.regionName, required this.status, this.fileSize, this.md5});
}

/// Simple cancel token for download cancellation.
class DownloadCancelToken {
  bool _cancelled = false;
  bool get isCancelled => _cancelled;
  void cancel() => _cancelled = true;
}

/// Metadata for a locally downloaded tile region.
class LocalTileMeta {
  final String regionName;
  final String fileName;
  final String filePath;
  final int fileSize;
  final String? md5;

  LocalTileMeta({
    required this.regionName,
    required this.fileName,
    required this.filePath,
    required this.fileSize,
    this.md5,
  });
}

class OfflineTileManager {
  final AppDatabase _db;
  final String _apiBaseUrl;
  final Map<String, String> _headers;

  AppDatabase get db => _db;

  OfflineTileManager(this._db, this._apiBaseUrl, this._headers);

  Future<List<TileStatus>> getTileStatus(int farmId) async {
    final uri = Uri.parse('$_apiBaseUrl/farms/$farmId/tile-status');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body);
    final data = body['data'];
    final regions = (data is Map ? data['regions'] : null) as List?;
    if (regions == null) return [];
    return regions.map((r) => TileStatus(
      regionName: r['regionName'] as String? ?? '',
      status: r['status'] as String? ?? 'unknown',
      fileSize: r['fileSize'] as int?,
      md5: r['md5'] as String?,
    )).toList();
  }

  /// Download a single region's mbtiles file using streaming (no OOM).
  /// [onProgress] reports 0.0-1.0 based on bytes received / total.
  /// Returns the local file path on success, null if cancelled.
  Future<String?> downloadRegion(
    int farmId,
    String regionName, {
    int? expectedFileSize,
    String? expectedMd5,
    void Function(double progress)? onProgress,
    DownloadCancelToken? cancelToken,
  }) async {
    final dir = await getApplicationSupportDirectory();
    final mbtilesDir = Directory(p.join(dir.path, 'mbtiles'));
    if (!mbtilesDir.existsSync()) mbtilesDir.createSync(recursive: true);

    final fileName = '$regionName.mbtiles';
    final targetPath = p.join(mbtilesDir.path, fileName);
    final tempPath = '$targetPath.download';

    // Skip if already downloaded and verified
    final existing = _db.getTileMetaByRegion(regionName);
    if (existing != null &&
        existing['status'] == 'ready' &&
        File(targetPath).existsSync()) {
      return targetPath;
    }

    final downloadUrl =
        '$_apiBaseUrl/farms/$farmId/offline-map?regionName=$regionName';
    final request = http.Request('GET', Uri.parse(downloadUrl));
    _headers.forEach((k, v) => request.headers[k] = v);

    final client = http.Client();
    final response = await client.send(request);

    if (response.statusCode != 200) {
      client.close();
      throw Exception('Download failed: ${response.statusCode}');
    }

    final total = response.contentLength ?? expectedFileSize ?? 0;
    final sink = File(tempPath).openWrite();
    int received = 0;
    final chunks = <List<int>>[];

    try {
      await for (final chunk in response.stream) {
        if (cancelToken?.isCancelled ?? false) {
          await sink.close();
          await File(tempPath).delete();
          client.close();
          return null;
        }
        sink.add(chunk);
        chunks.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call(received / total);
      }
    } finally {
      await sink.close();
      client.close();
    }

    // MD5 verification
    final localMd5 = md5.convert(chunks.expand((c) => c).toList()).toString();
    if (expectedMd5 != null && localMd5 != expectedMd5) {
      await File(tempPath).delete();
      throw Exception('MD5 mismatch for $regionName');
    }

    // Atomic rename
    if (File(targetPath).existsSync()) await File(targetPath).delete();
    await File(tempPath).rename(targetPath);

    _db.insertTileMeta(
      regionName: regionName,
      fileName: fileName,
      fileSize: received,
      md5: localMd5,
      filePath: targetPath,
      status: 'ready',
    );

    onProgress?.call(1.0);
    return targetPath;
  }

  /// Return all locally downloaded mbtiles file paths (for SmartTileProvider).
  List<String> getLocalMbtilesFiles() {
    return _db.getTileMetas()
        .where((m) => m['status'] == 'ready')
        .map((m) => m['file_path'] as String)
        .where((path) => File(path).existsSync())
        .toList();
  }

  /// Return metadata of all locally downloaded regions.
  List<LocalTileMeta> getLocalTiles() {
    return _db.getTileMetas()
        .where((m) => m['status'] == 'ready')
        .map((m) => LocalTileMeta(
              regionName: m['region_name'] as String,
              fileName: m['file_name'] as String,
              filePath: m['file_path'] as String,
              fileSize: m['file_size'] as int,
              md5: m['md5'] as String?,
            ))
        .where((m) => File(m.filePath).existsSync())
        .toList();
  }

  /// Batch download all ready regions for a farm (streaming, no OOM).
  Future<void> startForegroundDownload(
    int farmId, {
    void Function(double progress)? onProgress,
    void Function()? onComplete,
    void Function(String error)? onError,
    DownloadCancelToken? cancelToken,
  }) async {
    final statuses = await getTileStatus(farmId);
    if (statuses.isEmpty) {
      onComplete?.call();
      return;
    }

    int completed = 0;
    for (final status in statuses) {
      if (cancelToken?.isCancelled ?? false) break;
      try {
        final result = await downloadRegion(
          farmId,
          status.regionName,
          expectedFileSize: status.fileSize,
          expectedMd5: status.md5,
          onProgress: (p) => onProgress?.call(
              (completed + p) / statuses.length),
          cancelToken: cancelToken,
        );
        if (result != null) completed++;
        onProgress?.call(completed / statuses.length);
      } catch (e) {
        onError?.call('Download ${status.regionName} failed: $e');
      }
    }
    onComplete?.call();
  }

  Future<void> deleteLocalTiles(String regionName) async {
    final meta = _db.getTileMetaByRegion(regionName);
    if (meta != null) {
      final file = File(meta['file_path'] as String);
      if (await file.exists()) await file.delete();
      _db.rawDb.execute('DELETE FROM tile_metas WHERE region_name = ?', [regionName]);
    }
  }

  int getStorageUsedSync() => _db.getStorageUsed();

  List<Map<String, dynamic>> getTileMetasSync() => _db.getTileMetas();

  Future<int> getStorageUsed() async => _db.getStorageUsed();

  Future<void> pin(int farmId) async {
    final metas = _db.getTileMetas();
    for (final meta in metas) {
      final tileMetaId = meta['id'] as int;
      final rows = _db.rawDb.select(
        'SELECT id FROM farm_tile_pins WHERE farm_id = ? AND tile_meta_id = ?',
        [farmId, tileMetaId]);
      if (rows.isEmpty) {
        _db.rawDb.execute(
          'INSERT INTO farm_tile_pins (farm_id, tile_meta_id, pinned) VALUES (?, ?, 1)',
          [farmId, tileMetaId]);
      } else {
        _db.rawDb.execute(
          'UPDATE farm_tile_pins SET pinned = 1 WHERE farm_id = ? AND tile_meta_id = ?',
          [farmId, tileMetaId]);
      }
    }
  }

  Future<void> unpin(int farmId) async {
    _db.rawDb.execute(
      'UPDATE farm_tile_pins SET pinned = 0 WHERE farm_id = ?',
      [farmId]);
  }
}
