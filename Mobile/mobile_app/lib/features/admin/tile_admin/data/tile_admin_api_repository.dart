import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/admin/tile_admin/domain/tile_admin_models.dart';

class TileAdminApiRepository {
  const TileAdminApiRepository();

  Future<List<TileRegion>> listRegions() async {
    final data = await ApiClient.instance.get('/admin/tiles/regions');
    final items = (data['value'] ?? data['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(_parseRegion).toList();
  }

  Future<TileRegion> upsertRegion(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/tiles/regions', body: body);
    return _parseRegion(data);
  }

  Future<List<TileTask>> listTasks({String? status}) async {
    final path = status != null ? '/admin/tiles/tasks?status=$status' : '/admin/tiles/tasks';
    final data = await ApiClient.instance.get(path);
    final items = (data['value'] ?? data['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(_parseTask).toList();
  }

  Future<TileTask> createTask(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.post('/admin/tiles/tasks', body: body);
    return _parseTask(data);
  }

  Future<TileTask> updateTaskStatus(int id, Map<String, dynamic> body) async {
    final data = await ApiClient.instance.put('/admin/tiles/tasks/$id/status', body: body);
    return _parseTask(data);
  }

  Future<List<FarmTileStatus>> listFarmTasks() async {
    final data = await ApiClient.instance.get('/admin/tiles/farm-tasks');
    final items = (data['value'] ?? data['items'] ?? []) as List;
    return items.whereType<Map<String, dynamic>>().map(_parseFarmStatus).toList();
  }

  TileRegion _parseRegion(Map<String, dynamic> m) {
    return TileRegion(
      id: m['id'] as int,
      name: (m['name'] ?? '').toString(),
      minLon: (m['minLon'] as num?)?.toDouble() ?? 0.0,
      minLat: (m['minLat'] as num?)?.toDouble() ?? 0.0,
      maxLon: (m['maxLon'] as num?)?.toDouble() ?? 0.0,
      maxLat: (m['maxLat'] as num?)?.toDouble() ?? 0.0,
      minZoom: (m['minZoom'] as num?)?.toInt() ?? 11,
      maxZoom: (m['maxZoom'] as num?)?.toInt() ?? 15,
      fileName: m['fileName']?.toString(),
      fileSize: (m['fileSize'] as num?)?.toInt() ?? 0,
      status: m['status']?.toString(),
    );
  }

  TileTask _parseTask(Map<String, dynamic> m) {
    return TileTask(
      id: m['id'] as int,
      regionName: m['regionName']?.toString(),
      minLon: (m['minLon'] as num?)?.toDouble() ?? 0.0,
      minLat: (m['minLat'] as num?)?.toDouble() ?? 0.0,
      maxLon: (m['maxLon'] as num?)?.toDouble() ?? 0.0,
      maxLat: (m['maxLat'] as num?)?.toDouble() ?? 0.0,
      status: m['status']?.toString(),
      tileCount: (m['tileCount'] as num?)?.toInt() ?? 0,
      fileSizeMb: (m['fileSizeMb'] as num?)?.toDouble() ?? 0.0,
      errorMessage: m['errorMessage']?.toString(),
    );
  }

  FarmTileStatus _parseFarmStatus(Map<String, dynamic> m) {
    return FarmTileStatus(
      farmId: m['farmId'] as int,
      farmName: (m['farmName'] ?? '').toString(),
      tileStatus: m['tileStatus']?.toString(),
      regionName: m['regionName']?.toString(),
      lastDownloadAt: m['lastDownloadAt']?.toString(),
    );
  }
}
