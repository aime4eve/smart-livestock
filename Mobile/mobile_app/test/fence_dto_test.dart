import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:smart_livestock_demo/features/fence/data/fence_dto.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

void main() {
  test('coordinatesToLatLngPoints maps lng lat pairs to LatLng', () {
    final pts = coordinatesToLatLngPoints([
      [112.94, 28.234],
      [112.944, 28.2305],
    ]);
    expect(pts.length, 2);
    expect(pts[0], const LatLng(28.234, 112.94));
    expect(pts[1], const LatLng(28.2305, 112.944));
  });

  test('livestockCountsByFenceId aggregates fenceId', () {
    final m = livestockCountsByFenceId([
      {'fenceId': 'fence_a'},
      {'fenceId': 'fence_a'},
      {'fenceId': 'fence_b'},
    ]);
    expect(m['fence_a'], 2);
    expect(m['fence_b'], 1);
  });

  test('fenceItemFromJson builds FenceItem from API map', () {
    final item = fenceItemFromJson(
      {
        'id': 'fence_pasture_a',
        'name': '放牧A区',
        'type': 'polygon',
        'alarmEnabled': true,
        'status': 'active',
        'coordinates': [
          [112.94, 28.234],
          [112.944, 28.234],
          [112.944, 28.2305],
          [112.94, 28.2305],
        ],
      },
      0,
      12,
    );
    expect(item.id, 'fence_pasture_a');
    expect(item.livestockCount, 12);
    expect(item.points.length, 4);
    expect(item.type, FenceType.polygon);
  });
}
