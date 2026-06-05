import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_livestock_demo/features/admin/feature_gate/data/feature_gate_api_repository.dart';
import 'package:smart_livestock_demo/features/admin/feature_gate/domain/feature_gate_models.dart';

final featureGateRepositoryProvider = Provider<FeatureGateApiRepository>(
  (_) => const FeatureGateApiRepository(),
);

class FeatureGateController extends AsyncNotifier<List<FeatureGateEntry>> {
  @override
  Future<List<FeatureGateEntry>> build() async {
    return ref.read(featureGateRepositoryProvider).loadAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(featureGateRepositoryProvider).loadAll());
  }

  Future<void> updateGate(int id, {int? limitValue, int? retentionDays, bool? isEnabled}) async {
    await ref.read(featureGateRepositoryProvider).update(
      id, limitValue: limitValue, retentionDays: retentionDays, isEnabled: isEnabled,
    );
    ref.invalidateSelf();
  }
}

final featureGateControllerProvider =
    AsyncNotifierProvider<FeatureGateController, List<FeatureGateEntry>>(
  FeatureGateController.new,
);
