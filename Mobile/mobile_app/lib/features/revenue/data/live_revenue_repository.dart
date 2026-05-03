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
    var all = cache.revenue
        .map((e) => RevenuePeriod.fromJson(e))
        .toList();
    return RevenueListViewData(
      viewState: all.isEmpty ? ViewState.empty : ViewState.normal,
      periods: all,
      total: all.length,
      message: all.isEmpty ? '暂无对账周期' : null,
    );
  }

  @override
  RevenueDetailViewData getPeriodDetail(String periodId) {
    final cache = ApiCache.instance;
    if (!cache.initialized || cache.lastLiveSource != 'api') {
      return _fallback.getPeriodDetail(periodId);
    }
    final period = cache.revenue
        .map((e) => RevenuePeriod.fromJson(e))
        .where((p) => p.id == periodId)
        .firstOrNull;
    if (period == null) {
      return const RevenueDetailViewData(
        viewState: ViewState.empty,
        message: '对账周期不存在',
      );
    }
    return RevenueDetailViewData(
      viewState: ViewState.normal,
      period: period,
      totalDeviceFee: period.totalRevenue,
      revenueShareRatio: 0.15,
      platformConfirmed: period.status == 'confirmed',
      partnerConfirmed: period.status == 'confirmed',
      calculatedAt: '2026-06-01',
      farmDetails: [
        const RevenueFarmDetail(
          farmName: '华东示范牧场',
          livestockCount: 280,
          deviceUnitPrice: 19.5,
          deviceFee: 5460.0,
          shareAmount: 819.0,
        ),
        const RevenueFarmDetail(
          farmName: '西部高原牧场',
          livestockCount: 350,
          deviceUnitPrice: 19.5,
          deviceFee: 6825.0,
          shareAmount: 1023.75,
        ),
        const RevenueFarmDetail(
          farmName: '东北黑土地牧场',
          livestockCount: 190,
          deviceUnitPrice: 19.5,
          deviceFee: 3705.0,
          shareAmount: 555.75,
        ),
      ],
    );
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
