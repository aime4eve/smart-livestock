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
      avgTemperature: (summary['avgTemperature'] as num).toDouble(),
      avgActivity: (summary['avgActivity'] as num).toDouble(),
      abnormalRate: (summary['abnormalRate'] as num).toDouble(),
      totalLivestock: (summary['totalLivestock'] as num).toInt(),
      abnormalCount: (summary['abnormalCount'] as num).toInt(),
    );

    final contacts = <ContactTrace>[];
    for (final c in cache.epidemicContacts) {
      contacts.add(
        ContactTrace(
          fromId: c['fromId'] as String,
          toId: c['toId'] as String,
          lastContact: DateTime.parse(c['lastContact'] as String),
          proximity: (c['proximity'] as num).toDouble(),
        ),
      );
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
