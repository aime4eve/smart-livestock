import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/revenue/data/revenue_api_repository.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  return const RevenueApiRepository();
});

class RevenueController extends AsyncNotifier<RevenueListViewData> {
  @override
  Future<RevenueListViewData> build() async {
    // Use app-scoped endpoint for owners
    return ref.read(revenueRepositoryProvider).getAppPeriods();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(revenueRepositoryProvider).getAppPeriods());
  }

  Future<RevenueDetailViewData> getPeriodDetail(String periodId) {
    return ref.read(revenueRepositoryProvider).getPeriodDetail(periodId);
  }

  Future<bool> confirmPeriod(String periodId) async {
    // Use app-scoped endpoint for owners
    final ok =
        await ref.read(revenueRepositoryProvider).confirmAsPartner(periodId);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> calculateRevenue({
    required String contractId,
    required String periodStart,
    required String periodEnd,
    required int grossAmountCents,
  }) async {
    return ref.read(revenueRepositoryProvider).calculateRevenue(
      contractId: contractId,
      periodStart: periodStart,
      periodEnd: periodEnd,
      grossAmountCents: grossAmountCents,
    );
  }

  Future<bool> recalculatePeriod(
      String periodId, int grossAmountCents) async {
    final ok = await ref
        .read(revenueRepositoryProvider)
        .recalculatePeriod(periodId, grossAmountCents);
    if (ok) await refresh();
    return ok;
  }
}

final revenueControllerProvider =
    AsyncNotifierProvider<RevenueController, RevenueListViewData>(
  RevenueController.new,
);
