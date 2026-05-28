import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:smart_livestock_demo/core/database/app_database.dart';

class TileStatus {
  final String regionName;
  final String status;
  final int? fileSize;
  final String? md5;
  TileStatus({required this.regionName, required this.status, this.fileSize, this.md5});
}

class OfflineTileManager {
  final AppDatabase _db;
  final String _apiBaseUrl;
  final Map<String, String> _headers;

  OfflineTileManager(this._db, this._apiBaseUrl, this._headers);

  Future<List<TileStatus>> getTileStatus(int farmId) async {
    final uri = Uri.parse('$_apiBaseUrl/farms/$farmId/tile-status');
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode != 200) return [];
    final body = await _parseJson(response.body);
    final regions = body['data']?['regions'] as List?;
    if (regions == null) return [];
    return regions.map((r) => TileStatus(
      regionName: r['regionName'] as String? ?? '',
      status: r['status'] as String? ?? 'unknown',
      fileSize: r['fileSize'] as int?,
      md5: r['md5'] as String?,
    )).toList();
  }

  Future<void> startForegroundDownload(
    int farmId, {
    void Function(double progress)? onProgress,
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    final statuses = await getTileStatus(farmId);
    final dir = await getApplicationSupportDirectory();
    final mbtilesDir = Directory(p.join(dir.path, 'mbtiles'));
    if (!mbtilesDir.existsSync()) mbtilesDir.createSync(recursive: true);

    int completed = 0;
    for (final status in statuses) {
      try {
        final fileName = '${status.regionName}.mbtiles';
        final targetPath = p.join(mbtilesDir.path, fileName);
        final tempPath = '$targetPath.download';

        final existing = await _db.getTileMetaByRegion(status.regionName);
        if (existing != null && existing.status == 'ready' && File(targetPath).existsSync()) {
          completed++;
          continue;
        }

        final downloadUrl = '$_apiBaseUrl/farms/$farmId/offline-map';
        final response = await http.get(Uri.parse(downloadUrl), headers: _headers);
        if (response.statusCode != 200) {
          onError?.call('下载失败: ${response.statusCode}');
          continue;
        }

        await File(tempPath).writeAsBytes(response.bodyBytes);

        final digest = md5.convert(response.bodyBytes);
        final localMd5 = digest.toString();
        if (status.md5 != null && localMd5 != status.md5) {
          await File(tempPath).delete();
          onError?.call('MD5 校验失败: ${status.regionName}');
          continue;
        }

        if (File(targetPath).existsSync()) await File(targetPath).delete();
        await File(tempPath).rename(targetPath);

        await _db.insertTileMeta(TileMetasCompanion(
          regionName: Value(status.regionName),
          fileName: Value(fileName),
          fileSize: Value(response.bodyBytes.length),
          md5: Value(localMd5),
          filePath: Value(targetPath),
          status: const Value('ready'),
          downloadedAt: Value(DateTime.now()),
          lastAccessedAt: Value(DateTime.now()),
        ));

        completed++;
        onProgress?.call(completed / statuses.length);
      } catch (e) {
        onError?.call('下载 ${status.regionName} 失败: $e');
      }
    }
    onComplete?.call();
  }

  Future<void> deleteLocalTiles(String regionName) async {
    final meta = await _db.getTileMetaByRegion(regionName);
    if (meta != null) {
      final file = File(meta.filePath);
      if (await file.exists()) await file.delete();
    }
  }

  Future<int> getStorageUsed() async {
    final metas = await _db.getTileMetas();
    return metas.fold(0, (sum, m) => sum + m.fileSize);
  }

  Future<void> pin(int farmId) async {
    final metas = await _db.getTileMetas();
    for (final meta in metas) {
      await _db.insertFarmTilePin(FarmTilePinsCompanion(
        farmId: Value(farmId),
        tileMetaId: Value(meta.id),
        pinned: const Value(true),
      ));
    }
  }

  Future<void> unpin(int farmId) async {
    final pins = await _db.getFarmTilePins(farmId);
    for (final pin in pins) {
      await _db.setPin(farmId, pin.tileMetaId, false);
    }
  }

  Future<dynamic> _parseJson(String body) async {
    return await Isolate.run(() => jsonDecode(body));
  }
}

final offlineTileManagerProvider = Provider<OfflineTileManager>((ref) {
  throw UnimplementedError('Override in app with real dependencies');
});
