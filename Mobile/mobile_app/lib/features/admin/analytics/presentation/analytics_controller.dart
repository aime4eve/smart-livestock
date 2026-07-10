import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/analytics/data/analytics_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/analytics/domain/analytics_models.dart';

final analyticsRepositoryProvider = Provider<AnalyticsApiRepository>(
  (_) => const AnalyticsApiRepository(),
);

class AnalyticsData {
  const AnalyticsData({required this.overview, required this.trend});
  final UsageOverview overview;
  final List<UsageTrendPoint> trend;
}

class AnalyticsController extends AsyncNotifier<AnalyticsData> {
  @override
  Future<AnalyticsData> build() async {
    final now = DateTime.now();
    final from = now.subtract(const Duration(days: 7));
    return _load(from, now);
  }

  Future<AnalyticsData> _load(DateTime from, DateTime to) async {
    final repo = ref.read(analyticsRepositoryProvider);
    final results = await Future.wait([
      repo.getOverview(from, to),
      repo.getTrend(from, to),
    ]);
    return AnalyticsData(overview: results[0] as UsageOverview, trend: results[1] as List<UsageTrendPoint>);
  }

  Future<void> refresh(DateTime from, DateTime to) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _load(from, to));
  }
}

final analyticsControllerProvider =
    AsyncNotifierProvider<AnalyticsController, AnalyticsData>(
  AnalyticsController.new,
);
