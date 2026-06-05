import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

abstract class FenceRepository {
  Future<List<FenceItem>> loadAll();
  Future<FenceItem> loadDetail(String fenceId);
  Future<FenceItem> create(Map<String, dynamic> body);
  Future<FenceItem> update(String fenceId, Map<String, dynamic> body);
  Future<void> delete(String fenceId);
  Future<FenceItem> forceUpdate(String fenceId, Map<String, dynamic> body);
}
