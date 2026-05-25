import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/revenue/data/revenue_api_repository.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  return const RevenueApiRepository();
});

class RevenueController extends AsyncNotifier<RevenueListViewData> {
  @override
  Future<RevenueListViewData> build() async {
    return ref.read(revenueRepositoryProvider).getPeriods();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(revenueRepositoryProvider).getPeriods());
  }

  Future<RevenueDetailViewData> getPeriodDetail(String periodId) {
    return ref.read(revenueRepositoryProvider).getPeriodDetail(periodId);
  }

  Future<bool> confirmPeriod(String periodId) async {
    final ok = await ref.read(revenueRepositoryProvider).confirmPeriod(periodId);
    if (ok) await refresh();
    return ok;
  }

  Future<bool> calculateRevenue(String periodId) async {
    return ref.read(revenueRepositoryProvider).calculateRevenue(periodId);
  }
}

final revenueControllerProvider =
    AsyncNotifierProvider<RevenueController, RevenueListViewData>(
  RevenueController.new,
);
