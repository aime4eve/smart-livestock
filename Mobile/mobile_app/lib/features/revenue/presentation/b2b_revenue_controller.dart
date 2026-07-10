import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/revenue/domain/revenue_repository.dart';
import 'package:hkt_livestock_agentic/features/revenue/presentation/revenue_controller.dart';

class B2bRevenueController extends AsyncNotifier<RevenueListViewData> {
  @override
  Future<RevenueListViewData> build() async {
    return ref.read(revenueRepositoryProvider).getAppPeriods();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
        () => ref.read(revenueRepositoryProvider).getAppPeriods());
  }

  Future<bool> confirmAsPartner(String periodId) async {
    final ok = await ref
        .read(revenueRepositoryProvider)
        .confirmAsPartner(periodId);
    if (ok) await refresh();
    return ok;
  }

  RevenuePeriod? findPeriod(String id) {
    final periods = state.value?.periods;
    if (periods == null) return null;
    for (final p in periods) {
      if (p.id == id) return p;
    }
    return null;
  }
}

final b2bRevenueControllerProvider =
    AsyncNotifierProvider<B2bRevenueController, RevenueListViewData>(
  B2bRevenueController.new,
);
