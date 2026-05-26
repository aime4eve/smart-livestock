import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

const _fallbackCenter = LatLng(28.2458, 112.8519);

FenceType fenceTypeFromApiString(String? raw) {
  return switch (raw) {
    'rectangle' => FenceType.rectangle,
    'circle' => FenceType.circle,
    _ => FenceType.polygon,
  };
}

List<LatLng> coordinatesToLatLngPoints(List<dynamic>? raw) {
  if (raw == null) {
    return [];
  }
  final out = <LatLng>[];
  for (final c in raw) {
    if (c is List && c.length >= 2) {
      final lng = (c[0] as num).toDouble();
      final lat = (c[1] as num).toDouble();
      out.add(LatLng(lat, lng));
    }
  }
  return out;
}

FenceItem fenceItemFromJson(
  Map<String, dynamic> raw,
  int colorIndex,
  int livestockCount,
) {
  final rawId = raw['id'];
  final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
  final name = raw['name'] as String? ?? '未命名';
  final type = fenceTypeFromApiString(raw['type'] as String?);
  final alarmEnabled = raw['alarmEnabled'] as bool? ?? true;
  final active = raw['active'] as bool? ?? true;
  var points = coordinatesToLatLngPoints(raw['coordinates'] as List<dynamic>?);
  if (points.length < 3) {
    points = FenceItem.defaultPointsForType(type, _fallbackCenter);
  }
  final colorValue = raw['color'] as int? ??
      FenceItem.defaultColors[colorIndex % FenceItem.defaultColors.length];
  return FenceItem(
    id: id,
    name: name,
    type: type,
    alarmEnabled: alarmEnabled,
    active: active,
    areaHectares: 0,
    livestockCount: livestockCount,
    colorValue: colorValue,
    points: points,
  );
}

List<FenceItem> fenceItemsFromApiMaps(
  List<Map<String, dynamic>> rows,
  Map<String, int> livestockByFenceId,
) {
  final out = <FenceItem>[];
  for (var i = 0; i < rows.length; i++) {
    final r = rows[i];
    final rawFid = r['id'];
    final id = rawFid is int ? rawFid.toString() : (rawFid as String? ?? '');
    final count = livestockByFenceId[id] ?? 0;
    out.add(fenceItemFromJson(r, i, count));
  }
  return out;
}

Map<String, int> livestockCountsByFenceId(
  List<Map<String, dynamic>> animals,
) {
  final map = <String, int>{};
  for (final a in animals) {
    final rawFid = a['fenceId'];
    if (rawFid == null) continue;
    final fid = rawFid is int ? rawFid.toString() : (rawFid as String?);
    if (fid != null) {
      map[fid] = (map[fid] ?? 0) + 1;
    }
  }
  return map;
}
