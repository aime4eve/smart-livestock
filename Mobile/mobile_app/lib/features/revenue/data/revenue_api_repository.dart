import 'package:smart_livestock_demo/core/api/api_client.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

class RevenueApiRepository implements RevenueRepository {
  const RevenueApiRepository();

  @override
  Future<RevenueListViewData> getPeriods() async {
    final data = await ApiClient.instance.get('/admin/revenue/periods');
    final items = data['items'] as List<dynamic>? ?? [];
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
    final data =
        await ApiClient.instance.get('/admin/revenue/periods/$periodId');
    return RevenueDetailViewData(period: RevenuePeriod.fromJson(data));
  }

  @override
  Future<bool> confirmPeriod(String periodId) async {
    await ApiClient.instance
        .post('/admin/revenue/periods/$periodId/confirm');
    return true;
  }

  @override
  Future<bool> calculateRevenue({
    required String contractId,
    required String periodStart,
    required String periodEnd,
    required int grossAmountCents,
  }) async {
    await ApiClient.instance.post('/admin/revenue/calculate', body: {
      'contractId': contractId,
      'periodStart': periodStart,
      'periodEnd': periodEnd,
      'grossAmountCents': grossAmountCents,
    });
    return true;
  }

  @override
  Future<bool> recalculatePeriod(String periodId, int grossAmountCents) async {
    await ApiClient.instance
        .post('/admin/revenue/periods/$periodId/recalculate', body: {
      'grossAmountCents': grossAmountCents,
    });
    return true;
  }

  // App-scoped endpoints (CommerceController)

  @override
  Future<RevenueListViewData> getAppPeriods() async {
    final data = await ApiClient.instance.get('/revenue/periods');
    final items = data['items'] as List<dynamic>? ?? [];
    final periods = items
        .whereType<Map<String, dynamic>>()
        .map((m) => RevenuePeriod.fromJson(m))
        .toList();
    return RevenueListViewData(periods: periods, total: periods.length);
  }

  @override
  Future<bool> confirmAsPartner(String periodId) async {
    await ApiClient.instance.post('/revenue/periods/$periodId/confirm');
    return true;
  }
}
