import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/data/twin_seed.dart';
import 'package:smart_livestock_demo/core/models/twin_models.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/twin_overview/data/mock_twin_overview_repository.dart';
import 'package:smart_livestock_demo/features/twin_overview/domain/twin_overview_repository.dart';

class LiveTwinOverviewRepository implements TwinOverviewRepository {
  const LiveTwinOverviewRepository();

  static const MockTwinOverviewRepository _fallback = MockTwinOverviewRepository();

  @override
  TwinOverviewViewData load([ViewState desiredState = ViewState.normal]) {
    final cache = ApiCache.instance;
    final raw = cache.twinOverview;
    if (!cache.initialized || raw == null) {
      return _fallback.load(desiredState);
    }

    final statsMap = raw['stats'] as Map<String, dynamic>?;
    final sceneMap = raw['sceneSummary'] as Map<String, dynamic>?;
    if (statsMap == null || sceneMap == null) {
      return _fallback.load(desiredState);
    }

    final banner = raw['pastureBanner'] as Map<String, dynamic>?;
    final pastureHeadline = (banner?['headline'] as String?)?.trim().isNotEmpty == true
        ? banner!['headline'] as String
        : TwinSeed.overviewPastureHeadline;
    final pastureDetail = (banner?['detail'] as String?)?.trim().isNotEmpty == true
        ? banner!['detail'] as String
        : TwinSeed.overviewPastureDetail;

    final fever = sceneMap['fever'] as Map<String, dynamic>?;
    final digestive = sceneMap['digestive'] as Map<String, dynamic>?;
    final estrus = sceneMap['estrus'] as Map<String, dynamic>?;
    final epidemic = sceneMap['epidemic'] as Map<String, dynamic>?;

    final stats = TwinOverviewStats(
      totalLivestock: (statsMap['totalLivestock'] as num?)?.toInt() ?? 0,
      healthyRate: (statsMap['healthyRate'] as num?)?.toDouble() ?? 0,
      alertCount: (statsMap['alertCount'] as num?)?.toInt() ?? 0,
      criticalCount: (statsMap['criticalCount'] as num?)?.toInt() ?? 0,
      deviceOnlineRate: (statsMap['deviceOnlineRate'] as num?)?.toDouble() ?? 0,
      livestockCaption: statsMap['livestockCaption'] as String? ?? '',
      alertCaption: statsMap['alertCaption'] as String? ?? '',
      healthCaption: statsMap['healthCaption'] as String? ?? '',
      deviceCaption: statsMap['deviceCaption'] as String? ?? '',
      healthTrend: statsMap['healthTrend'] as String? ?? '',
      livestockTrend: statsMap['livestockTrend'] as String? ?? '',
    );

    final sceneSummary = TwinSceneSummary(
      fever: SceneSummaryFever(
        abnormalCount: (fever?['abnormalCount'] as num?)?.toInt() ?? 0,
        criticalCount: (fever?['criticalCount'] as num?)?.toInt() ?? 0,
      ),
      digestive: SceneSummaryDigestive(
        abnormalCount: (digestive?['abnormalCount'] as num?)?.toInt() ?? 0,
        watchCount: (digestive?['watchCount'] as num?)?.toInt() ?? 0,
      ),
      estrus: SceneSummaryEstrus(
        highScoreCount: (estrus?['highScoreCount'] as num?)?.toInt() ?? 0,
        breedingAdvice: estrus?['breedingAdvice'] as bool? ?? false,
      ),
      epidemic: SceneSummaryEpidemic(
        status: epidemic?['status'] as String? ?? 'normal',
        abnormalRate: (epidemic?['abnormalRate'] as num?)?.toDouble() ?? 0.0,
      ),
    );

    final tasksRaw = raw['pendingTasks'] as List<dynamic>?;
    final pendingTasks = <TwinPendingTask>[];
    if (tasksRaw != null) {
      for (final e in tasksRaw) {
        final m = e as Map<String, dynamic>;
        final rawTaskId = m['id'];
        pendingTasks.add(
          TwinPendingTask(
            id: rawTaskId is int ? rawTaskId.toString() : (rawTaskId as String? ?? ''),
            title: m['title'] as String? ?? '',
            subtitle: m['subtitle'] as String? ?? '',
            routePath: m['routePath'] as String? ?? '',
            severity: m['severity'] as String? ?? 'info',
          ),
        );
      }
    }

    return TwinOverviewViewData(
      viewState: desiredState,
      stats: stats,
      sceneSummary: sceneSummary,
      pendingTasks: pendingTasks,
      pastureHeadline: desiredState == ViewState.normal ? pastureHeadline : null,
      pastureDetail: desiredState == ViewState.normal ? pastureDetail : null,
      message: switch (desiredState) {
        ViewState.loading => '加载中',
        ViewState.empty => '暂无孪生数据',
        ViewState.error => '孪生数据加载失败',
        ViewState.forbidden => '当前角色仅可查看授权范围内的孪生信息',
        ViewState.offline => '离线数据：展示最近一次同步时间',
        ViewState.normal => null,
      },
    );
  }
}
