import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class MockFenceRepository implements FenceRepository {
  const MockFenceRepository();

  @override
  List<FenceItem> loadAll() {
    return DemoSeed.fencePolygons.map((fp) {
      final count =
          DemoSeed.livestock.where((l) => l.fenceId == fp.id).length;
      return FenceItem(
        id: fp.id,
        name: fp.name,
        type: _parseType(fp.type),
        alarmEnabled: fp.alarmEnabled,
        active: fp.active,
        areaHectares: fp.areaHectares,
        livestockCount: count,
        colorValue: fp.colorValue,
        points: fp.points,
      );
    }).toList();
  }

  static FenceType _parseType(String type) {
    return switch (type) {
      'rectangle' => FenceType.rectangle,
      'circle' => FenceType.circle,
      _ => FenceType.polygon,
    };
  }
}
