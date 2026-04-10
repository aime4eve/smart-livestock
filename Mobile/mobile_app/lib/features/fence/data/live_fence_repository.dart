import 'package:smart_livestock_demo/features/fence/data/mock_fence_repository.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_repository.dart';

class LiveFenceRepository implements FenceRepository {
  const LiveFenceRepository();

  static const MockFenceRepository _fallback = MockFenceRepository();

  @override
  List<FenceItem> loadAll() {
    return _fallback.loadAll();
  }
}
