import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';
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

    final items = cache.revenue;
    if (items.isEmpty) {
      return _fallback.getPeriods(partnerId: partnerId);
    }

    final all = items.map((e) => RevenuePeriod.fromJson(e)).toList();
    return RevenueListViewData(
      viewState: ViewState.normal,
      periods: all,
      total: all.length,
    );
  }

  @override
  RevenueDetailViewData getPeriodDetail(String periodId) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getPeriodDetail(periodId);
    }

    final raw = cache.revenue
        .whereType<Map<String, dynamic>>()
        .where((e) => e['id'] == periodId)
        .firstOrNull;

    if (raw == null) {
      return _fallback.getPeriodDetail(periodId);
    }

    final period = RevenuePeriod.fromJson(raw);
    final ratio =
        (raw['revenueShareRatio'] as num?)?.toDouble() ?? 0.15;
    final farmDetails = (raw['farmDetails'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map((f) {
          final deviceFee =
              (f['deviceFee'] as num?)?.toDouble() ?? 0.0;
          final livestock = f['livestockCount'] as int? ?? 0;
          return RevenueFarmDetail(
            farmName: f['farmName'] as String? ?? '',
            livestockCount: livestock,
            deviceUnitPrice: livestock > 0 ? deviceFee / livestock : 0.0,
            deviceFee: deviceFee,
            shareAmount: deviceFee * ratio,
          );
        })
            .toList() ??
        [];

    return RevenueDetailViewData(
      viewState: ViewState.normal,
      period: period,
      totalDeviceFee: period.totalRevenue,
      revenueShareRatio: ratio,
      platformConfirmed: raw['confirmedByPlatform'] == true,
      partnerConfirmed: raw['confirmedByPartner'] == true,
      calculatedAt: raw['createdAt'] as String?,
      farmDetails: farmDetails,
    );
  }

  @override
  Future<bool> confirmPeriod(String periodId) async {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.confirmPeriod(periodId);
    }
    final ok = await cache.confirmRevenuePeriodRemote('b2b_admin', periodId);
    if (ok) {
      await cache.refreshRevenuePeriods('b2b_admin');
    }
    return ok;
  }

  @override
  Future<bool> calculateRevenue(String periodId) async {
    return _fallback.calculateRevenue(periodId);
  }
}
