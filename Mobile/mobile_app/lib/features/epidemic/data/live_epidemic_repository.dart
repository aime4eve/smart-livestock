import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/epidemic/data/mock_epidemic_repository.dart';
import 'package:smart_livestock_demo/features/epidemic/domain/epidemic_repository.dart';

class LiveEpidemicRepository implements EpidemicRepository {
  const LiveEpidemicRepository();

  static const MockEpidemicRepository _fallback = MockEpidemicRepository();

  @override
  EpidemicViewData load([ViewState desiredState = ViewState.normal]) {
    final cache = ApiCache.instance;
    final summary = cache.epidemicSummary;
    if (!cache.initialized || summary == null) {
      return _fallback.load(desiredState);
    }

    final metrics = HerdHealthMetrics(
      avgTemperature: (summary['avgTemperature'] as num?)?.toDouble() ?? 0.0,
      avgActivity: (summary['avgActivity'] as num?)?.toDouble() ?? 0.0,
      abnormalRate: (summary['abnormalRate'] as num?)?.toDouble() ?? 0.0,
      totalLivestock: (summary['totalLivestock'] as num?)?.toInt() ?? 0,
      abnormalCount: (summary['abnormalCount'] as num?)?.toInt() ?? 0,
    );

    final contacts = <ContactTrace>[];
    for (final c in cache.epidemicContacts) {
      try {
        final rawFromId = c['fromId'];
        final rawToId = c['toId'];
        contacts.add(
          ContactTrace(
            fromId: rawFromId is int ? rawFromId.toString() : (rawFromId as String? ?? ''),
            toId: rawToId is int ? rawToId.toString() : (rawToId as String? ?? ''),
            lastContact: DateTime.tryParse(c['lastContact'] as String? ?? '') ?? DateTime.now(),
            proximity: (c['proximity'] as num?)?.toDouble() ?? 0.0,
          ),
        );
      } catch (_) {
        // Skip malformed contact records
      }
    }

    return EpidemicViewData(
      viewState: desiredState,
      metrics: desiredState == ViewState.normal ? metrics : null,
      contacts: desiredState == ViewState.normal ? contacts : const [],
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无疫病防控数据',
        ViewState.error => '疫病数据加载失败',
        ViewState.forbidden => '无权限查看疫病数据',
        ViewState.offline => '离线：展示已缓存群体指标',
        ViewState.normal => null,
      },
    );
  }
}
