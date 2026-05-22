import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/estrus/data/mock_estrus_repository.dart';
import 'package:smart_livestock_demo/features/estrus/domain/estrus_repository.dart';

class LiveEstrusRepository implements EstrusRepository {
  const LiveEstrusRepository();

  static const MockEstrusRepository _fallback = MockEstrusRepository();

  @override
  EstrusViewData load([ViewState desiredState = ViewState.normal]) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.estrusList.isEmpty) {
      return _fallback.load(desiredState);
    }
    final items =
        cache.estrusList.map(_parseScore).whereType<EstrusScore>().toList();
    return EstrusViewData(
      viewState: desiredState,
      items: desiredState == ViewState.normal ? items : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无发情识别数据',
        ViewState.error => '发情数据加载失败',
        ViewState.forbidden => '无权限查看发情数据',
        ViewState.offline => '离线：展示已缓存评分',
        ViewState.normal => null,
      },
    );
  }

  @override
  EstrusScore? loadDetail(String livestockId) {
    final cache = ApiCache.instance;
    for (final m in cache.estrusList) {
      if (m['livestockId'] == livestockId) {
        final s = _parseScore(m);
        if (s == null) continue;
        if (s.trend7d.isNotEmpty) return s;
        return _fallback.loadDetail(livestockId) ?? s;
      }
    }
    return _fallback.loadDetail(livestockId);
  }

  static EstrusScore? _parseScore(Map<String, dynamic> m) {
    try {
      final rawId = m['livestockId'];
      final id = rawId is int ? rawId.toString() : (rawId as String? ?? '');
      final trendRaw = m['trend7d'] as List<dynamic>? ?? [];
      final trend7d = trendRaw.map((e) {
        final t = e as Map<String, dynamic>;
        return EstrusTrendPoint(
          score: (t['score'] as num?)?.toDouble() ?? 0.0,
          timestamp: DateTime.tryParse(t['timestamp'] as String? ?? '') ?? DateTime.now(),
        );
      }).toList();
      return EstrusScore(
        livestockId: id,
        score: (m['score'] as num?)?.toInt() ?? 0,
        stepIncreasePercent: (m['stepIncreasePercent'] as num?)?.toInt() ?? 0,
        tempDelta: (m['tempDelta'] as num?)?.toDouble() ?? 0.0,
        distanceDelta: (m['distanceDelta'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ?? DateTime.now(),
        advice: m['advice'] as String?,
        trend7d: trend7d,
      );
    } catch (_) {
      return null;
    }
  }
}
