import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

class RevenueApiRepository implements RevenueRepository {
  const RevenueApiRepository();

  @override
  Future<RevenueListViewData> getPeriods({String? partnerId}) async {
    final data = await ApiClient.instance.get('/admin/revenue/periods');
    final items = data['items'] as List? ?? [];
    final periods = items
        .whereType<Map<String, dynamic>>()
        .map((m) => RevenuePeriod.fromJson(m))
        .toList();
    return RevenueListViewData(
      periods: periods,
      total: data['total'] as int? ?? periods.length,
    );
  }

  @override
  Future<RevenueDetailViewData> getPeriodDetail(String periodId) async {
    final data = await ApiClient.instance.get('/admin/revenue/periods/$periodId');
    final period = RevenuePeriod.fromJson(data);
    final farmDetailsRaw = data['farmDetails'] as List? ?? [];
    final farmDetails = farmDetailsRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => RevenueFarmDetail.fromJson(m))
        .toList();
    return RevenueDetailViewData(
      period: period,
      totalDeviceFee: (data['totalDeviceFee'] as num?)?.toDouble() ?? 0.0,
      revenueShareRatio: (data['revenueShareRatio'] as num?)?.toDouble() ?? 0.0,
      platformConfirmed: data['confirmedByPlatform'] as bool? ?? false,
      partnerConfirmed: data['confirmedByPartner'] as bool? ?? false,
      calculatedAt: data['calculatedAt'] as String?,
      farmDetails: farmDetails,
    );
  }

  @override
  Future<bool> confirmPeriod(String periodId) async {
    await ApiClient.instance.post('/admin/revenue/periods/$periodId/confirm');
    return true;
  }

  @override
  Future<bool> calculateRevenue(String periodId) async {
    await ApiClient.instance.post('/admin/revenue/periods/$periodId/calculate');
    return true;
  }
}
