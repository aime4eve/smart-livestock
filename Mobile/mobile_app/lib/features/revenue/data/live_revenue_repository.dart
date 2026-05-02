import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/features/revenue/data/mock_revenue_repository.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

class LiveRevenueRepository implements RevenueRepository {
  LiveRevenueRepository();

  static final MockRevenueRepository _fallback = MockRevenueRepository();

  @override
  RevenueListViewData getPeriods({String? partnerId}) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getPeriods(partnerId: partnerId);
    }
    return _fallback.getPeriods(partnerId: partnerId);
  }

  @override
  RevenueDetailViewData getPeriodDetail(String periodId) {
    return _fallback.getPeriodDetail(periodId);
  }

  @override
  Future<bool> confirmPeriod(String periodId) async {
    return _fallback.confirmPeriod(periodId);
  }

  @override
  Future<bool> calculateRevenue(String periodId) async {
    return _fallback.calculateRevenue(periodId);
  }
}
