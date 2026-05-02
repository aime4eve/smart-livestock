import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/features/revenue/data/live_revenue_repository.dart';
import 'package:smart_livestock_demo/features/revenue/data/mock_revenue_repository.dart';
import 'package:smart_livestock_demo/features/revenue/domain/revenue_repository.dart';

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  switch (ref.watch(appModeProvider)) {
    case AppMode.mock:
      return MockRevenueRepository();
    case AppMode.live:
      return LiveRevenueRepository();
  }
});

class RevenueController extends Notifier<RevenueListViewData> {
  @override
  RevenueListViewData build() {
    return ref.read(revenueRepositoryProvider).getPeriods();
  }

  RevenueRepository get _repo => ref.read(revenueRepositoryProvider);

  void refresh() {
    state = _repo.getPeriods();
  }

  RevenueDetailViewData getPeriodDetail(String periodId) {
    return _repo.getPeriodDetail(periodId);
  }

  Future<bool> confirmPeriod(String periodId) async {
    final ok = await _repo.confirmPeriod(periodId);
    if (ok) refresh();
    return ok;
  }

  Future<bool> calculateRevenue(String periodId) async {
    return _repo.calculateRevenue(periodId);
  }
}

final revenueControllerProvider =
    NotifierProvider<RevenueController, RevenueListViewData>(
  RevenueController.new,
);
