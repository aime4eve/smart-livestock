import 'package:smart_livestock_demo/core/models/view_state.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

class MockRevenueRepository implements RevenueRepository {
  MockRevenueRepository();

  static final List<RevenuePeriod> _periods = [
    const RevenuePeriod(
      id: 'rev_001',
      periodLabel: '2026年1月',
      totalRevenue: 125000.00,
      platformShare: 87500.00,
      partnerShare: 37500.00,
      status: 'confirmed',
      confirmedAt: '2026-02-05T10:00:00+08:00',
    ),
    const RevenuePeriod(
      id: 'rev_002',
      periodLabel: '2026年2月',
      totalRevenue: 142000.00,
      platformShare: 99400.00,
      partnerShare: 42600.00,
      status: 'confirmed',
      confirmedAt: '2026-03-03T09:30:00+08:00',
    ),
    const RevenuePeriod(
      id: 'rev_003',
      periodLabel: '2026年3月',
      totalRevenue: 168000.00,
      platformShare: 117600.00,
      partnerShare: 50400.00,
      status: 'pending',
    ),
    const RevenuePeriod(
      id: 'rev_004',
      periodLabel: '2026年4月',
      totalRevenue: 193000.00,
      platformShare: 135100.00,
      partnerShare: 57900.00,
      status: 'pending',
    ),
  ];

  @override
  RevenueListViewData getPeriods({String? partnerId}) {
    return RevenueListViewData(
      viewState: _periods.isEmpty ? ViewState.empty : ViewState.normal,
      periods: _periods,
      total: _periods.length,
    );
  }

  @override
  RevenueDetailViewData getPeriodDetail(String periodId) {
    final period =
        _periods.where((p) => p.id == periodId).firstOrNull;
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
    final index = _periods.indexWhere((p) => p.id == periodId);
    if (index == -1) return false;
    _periods[index] = RevenuePeriod(
      id: _periods[index].id,
      periodLabel: _periods[index].periodLabel,
      totalRevenue: _periods[index].totalRevenue,
      platformShare: _periods[index].platformShare,
      partnerShare: _periods[index].partnerShare,
      status: 'confirmed',
      confirmedAt: DateTime.now().toIso8601String(),
    );
    return true;
  }

  @override
  Future<bool> calculateRevenue(String periodId) async {
    return true;
  }
}
