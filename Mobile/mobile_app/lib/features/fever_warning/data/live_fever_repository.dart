import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/fever_warning/data/mock_fever_repository.dart';
import 'package:smart_livestock_demo/features/fever_warning/domain/fever_repository.dart';

class LiveFeverRepository implements FeverRepository {
  const LiveFeverRepository();

  static const MockFeverRepository _fallback = MockFeverRepository();

  @override
  FeverViewData load([ViewState desiredState = ViewState.normal]) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.feverList.isEmpty) {
      return _fallback.load(desiredState);
    }
    final items = cache.feverList
        .map(_parseBaseline)
        .whereType<TemperatureBaseline>()
        .toList();
    return FeverViewData(
      viewState: desiredState,
      items: desiredState == ViewState.normal ? items : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无发热预警数据',
        ViewState.error => '发热数据加载失败',
        ViewState.forbidden => '无权限查看发热预警',
        ViewState.offline => '离线：展示已缓存体温数据',
        ViewState.normal => null,
      },
    );
  }

  @override
  TemperatureBaseline? loadDetail(String livestockId) {
    final cache = ApiCache.instance;
    for (final m in cache.feverList) {
      if (m['livestockId'] == livestockId) {
        final b = _parseBaseline(m);
        if (b != null && b.recent72h.isNotEmpty) return b;
      }
    }
    return _fallback.loadDetail(livestockId);
  }

  static TemperatureBaseline? _parseBaseline(Map<String, dynamic> m) {
    try {
      final id = m['livestockId'] as String;
      final recent = m['recent72h'] as List<dynamic>? ?? [];
      final records = <TemperatureRecord>[];
      for (final e in recent) {
        final r = e as Map<String, dynamic>;
        records.add(
          TemperatureRecord(
            livestockId: id,
            temperature: (r['temperature'] as num).toDouble(),
            timestamp: DateTime.parse(r['timestamp'] as String),
          ),
        );
      }
      return TemperatureBaseline(
        livestockId: id,
        baselineTemp: (m['baselineTemp'] as num).toDouble(),
        threshold: (m['threshold'] as num).toDouble(),
        recent72h: records,
        status: m['status'] as String,
        conclusion: m['conclusion'] as String?,
      );
    } catch (_) {
      return null;
    }
  }
}
