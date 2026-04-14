import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/features/fence/data/fence_dto.dart';
import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class LiveFenceRepository implements FenceRepository {
  const LiveFenceRepository();

  static const MockFenceRepository _fallback = MockFenceRepository();

  @override
  List<FenceItem> loadAll() {
    final cache = ApiCache.instance;
    if (!cache.initialized) {
      return _fallback.loadAll();
    }
    final rows = cache.fences;
    if (rows.isEmpty) {
      return _fallback.loadAll();
    }
    final counts = livestockCountsByFenceId(cache.animals);
    return fenceItemsFromApiMaps(
      rows.map((e) => Map<String, dynamic>.from(e)).toList(),
      counts,
    );
  }
}
