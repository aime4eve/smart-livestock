import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/digestive/data/mock_digestive_repository.dart';
import 'package:smart_livestock_demo/features/digestive/domain/digestive_repository.dart';

class LiveDigestiveRepository implements DigestiveRepository {
  const LiveDigestiveRepository();

  static const MockDigestiveRepository _fallback = MockDigestiveRepository();

  @override
  DigestiveViewData load([ViewState desiredState = ViewState.normal]) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.digestiveList.isEmpty) {
      return _fallback.load(desiredState);
    }
    final items = cache.digestiveList
        .map(_parseHealth)
        .whereType<DigestiveHealth>()
        .toList();
    return DigestiveViewData(
      viewState: desiredState,
      items: desiredState == ViewState.normal ? items : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无消化管理数据',
        ViewState.error => '消化数据加载失败',
        ViewState.forbidden => '无权限查看消化数据',
        ViewState.offline => '离线：展示已缓存蠕动数据',
        ViewState.normal => null,
      },
    );
  }

  @override
  DigestiveHealth? loadDetail(String livestockId) {
    final cache = ApiCache.instance;
    for (final m in cache.digestiveList) {
      if (m['livestockId'] == livestockId) {
        final h = _parseHealth(m);
        if (h != null && h.recent24h.isNotEmpty) return h;
      }
    }
    return _fallback.loadDetail(livestockId);
  }

  static DigestiveHealth? _parseHealth(Map<String, dynamic> m) {
    try {
      final id = m['livestockId'] as String;
      final recent = m['recent24h'] as List<dynamic>? ?? [];
      final records = recent.map((e) {
        final r = e as Map<String, dynamic>;
        return MotilityRecord(
          livestockId: id,
          frequency: (r['frequency'] as num).toDouble(),
          intensity: (r['intensity'] as num).toDouble(),
          timestamp: DateTime.parse(r['timestamp'] as String),
        );
      }).toList();
      return DigestiveHealth(
        livestockId: id,
        motilityBaseline: (m['motilityBaseline'] as num).toDouble(),
        status: m['status'] as String,
        advice: m['advice'] as String?,
        recent24h: records,
      );
    } catch (_) {
      return null;
    }
  }
}
