import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/fence/data/fence_dto.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

const _fallbackCenter = LatLng(28.2458, 112.8519);

class FenceApiRepository implements FenceRepository {
  const FenceApiRepository();

  @override
  Future<List<FenceItem>> loadAll() async {
    final data = await ApiClient.instance.farmGet('/fences?pageSize=100');
    final itemsRaw = data['items'] ?? data['value'];
    if (itemsRaw is! List) return const [];
    final rows = itemsRaw.whereType<Map<String, dynamic>>().toList();
    final counts = livestockCountsByFenceIdRows([]);
    return fenceItemsFromApiMaps(rows, counts);
  }

  @override
  Future<FenceItem> loadDetail(String fenceId) async {
    final data = await ApiClient.instance.farmGet('/fences/$fenceId');
    return _fenceItemFromMap(data, 0, 0);
  }

  @override
  Future<FenceItem> create(Map<String, dynamic> body) async {
    final data = await ApiClient.instance.farmPost('/fences', body: body);
    return _fenceItemFromMap(data, 0, 0);
  }

  @override
  Future<FenceItem> update(String fenceId, Map<String, dynamic> body) async {
    final data =
        await ApiClient.instance.farmPut('/fences/$fenceId', body: body);
    return _fenceItemFromMap(data, 0, 0);
  }

  @override
  Future<void> delete(String fenceId) async {
    await ApiClient.instance.farmDelete('/fences/$fenceId');
  }

  FenceItem _fenceItemFromMap(
      Map<String, dynamic> raw, int colorIndex, int livestockCount) {
    // Handle vertices format: [{lng, lat}] from Spring Boot
    var points = coordinatesToLatLngPoints(raw['coordinates'] as List<dynamic>?);
    if (points.isEmpty) {
      final vertices = raw['vertices'] as List<dynamic>?;
      if (vertices != null) {
        points = [
          for (final v in vertices)
            if (v is Map<String, dynamic>)
              LatLng(
                (v['lat'] as num?)?.toDouble() ?? 0,
                (v['lng'] as num?)?.toDouble() ?? 0,
              ),
        ];
      }
    }
    final type = fenceTypeFromApiString(raw['type'] as String?);
    if (points.length < 3) {
      points = FenceItem.defaultPointsForType(type, _fallbackCenter);
    }
    final rawId = raw['id'];
    final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
    final name = raw['name'] as String? ?? '未命名';
    final alarmEnabled = raw['alarmEnabled'] as bool? ?? true;
    final active = raw['active'] as bool? ?? true;
    final colorValue = raw['color'] as int? ??
        FenceItem.defaultColors[colorIndex % FenceItem.defaultColors.length];
    return FenceItem(
      id: id,
      name: name,
      type: type,
      alarmEnabled: alarmEnabled,
      active: active,
      areaHectares: (raw['areaHectares'] as num?)?.toDouble() ?? 0,
      livestockCount: livestockCount,
      colorValue: colorValue,
      points: points,
    );
  }

  /// Placeholder: no livestock data fetched in loadAll context.
  Map<String, int> livestockCountsByFenceIdRows(List<dynamic> animals) {
    return const {};
  }
}
